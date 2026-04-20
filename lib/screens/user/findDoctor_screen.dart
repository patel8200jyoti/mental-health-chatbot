import 'package:flutter/material.dart';
import '../../services/chat_api_service.dart';
import 'my_doctor_page.dart';
import '../../utils/profile_doodle.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class FindProfessionalScreen extends StatefulWidget {
  const FindProfessionalScreen({super.key});
  @override
  State<FindProfessionalScreen> createState() => _FindProfessionalScreenState();
}

class _FindProfessionalScreenState extends State<FindProfessionalScreen> {
  static const _teal = Color(0xFF6ECFBA);

  final AppApi _api = AppApi();

  bool   _loading = true;
  String _search  = '';
  String _filter  = 'All';

  List<Map<String, dynamic>> _professionals = [];
  List<Map<String, dynamic>> _myLinks       = []; // status == 'accepted'
  List<Map<String, dynamic>> _pendingLinks  = []; // status == 'pending'

  // Optimistic local sets so UI updates instantly before API round-trip
  final Set<String> _optimisticPending   = {};
  final Set<String> _optimisticCancelled = {};

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Parallel fetch — professionals + link state
      final results = await Future.wait([
        _api.getProfessionals(),
        _api.getMyLinks(),
      ]);
      if (!mounted) return;

      final links = results[1] as List<Map<String, dynamic>>;
      setState(() {
        _professionals = results[0] as List<Map<String, dynamic>>;
        _myLinks       = links.where((l) => l['status'] == 'accepted').toList();
        _pendingLinks  = links.where((l) => l['status'] == 'pending').toList();
        // Clear optimistic state once real data arrives
        _optimisticPending.clear();
        _optimisticCancelled.clear();
      });
    } catch (e) {
      debugPrint('_load error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load professionals')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _request(String profId) async {
    setState(() => _optimisticPending.add(profId));
    try {
      await _api.requestProfessional(profId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:         Text('Request sent! Waiting for doctor to accept.'),
        backgroundColor: _teal,
      ));
      await _load();
    } catch (e) {
      setState(() => _optimisticPending.remove(profId)); // revert
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not connect: $e'),
              backgroundColor: Colors.red));
    }
  }

  Future<void> _cancelRequest(String profId) async {
    setState(() {
      _optimisticCancelled.add(profId);
      _optimisticPending.remove(profId);
    });
    try {
      await _api.cancelRequest(profId);
      await _load();
    } catch (e) {
      setState(() => _optimisticCancelled.remove(profId)); // revert
      debugPrint('cancel error: $e');
    }
  }

  // ── Link status ───────────────────────────────────────────────────────────

  /// Returns 'linked' | 'pending' | 'none'
  String _linkStatus(String profId) {
    if (_optimisticCancelled.contains(profId)) return 'none';

    if (_myLinks.any((l) =>
            l['professional_id'] == profId ||
            l['professional_user_id'] == profId))
      return 'linked';

    if (_optimisticPending.contains(profId)) return 'pending';

    if (_pendingLinks.any((l) =>
            l['professional_id'] == profId ||
            l['professional_user_id'] == profId))
      return 'pending';

    return 'none';
  }

  // ── Filtering ─────────────────────────────────────────────────────────────

  /// Specialty chips built dynamically from real API data.
  List<String> get _specialties {
    final s = _professionals
        .map((p) => p['specialty']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...s];
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _professionals;
    if (_filter != 'All')
      list = list.where((p) => p['specialty'] == _filter).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((p) =>
          (p['full_name']?.toString() ?? '').toLowerCase().contains(q) ||
          (p['specialty']?.toString() ?? '').toLowerCase().contains(q)).toList();
    }
    return list;
  }

  // ── Rating sheet (preserved from old design) ──────────────────────────────

  void _showRatingSheet(Map<String, dynamic> prof) {
    final name          = prof['full_name']?.toString() ?? 'Professional';
    double currentRating = (prof['rating'] as num?)?.toDouble() ?? 5.0;

    showModalBottomSheet(
      context:         context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [

            // Drag handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color:        Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),

            Text(
              'Rate $name',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Star picker
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => GestureDetector(
                onTap: () => setModal(() => currentRating = i + 1.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < currentRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size:  36,
                  ),
                ),
              )),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Submit Rating',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),

          ]),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation:       0,
        leading: IconButton(
          icon: const ProfileDoodleIcon(size: 40,filled: true),
          onPressed: () => Navigator.pushNamed(context, '/profile'),
        ),
        actions: [
           Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () => Navigator.pushNamed(context, "/chat"),
              icon: const CircleAvatar(
                backgroundColor: Colors.teal,
                child: Icon(Icons.spa, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : RefreshIndicator(
              color:     _teal,
              onRefresh: _load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [

                  // ── Top controls ─────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // Linked professionals banner
                          if (_myLinks.isNotEmpty) ...[
                            _buildLinkedBanner(),
                            const SizedBox(height: 16),
                          ],

                          // Search bar
                          _buildSearchBar(),
                          const SizedBox(height: 12),

                          // Specialty chips
                          _buildSpecialtyChips(),
                          const SizedBox(height: 16),

                        ],
                      ),
                    ),
                  ),

                  // ── Professional list ─────────────────────────────────
                  _filtered.isEmpty
                      ? SliverFillRemaining(child: _buildEmptyState())
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) {
                                final prof   = _filtered[i];
                                final profId = prof['user_id']?.toString() ?? '';
                                final status = _linkStatus(profId);
                                return _ProfCard(
                                  prof:     prof,
                                  status:   status,
                                  teal:     _teal,
                                  onRequest: () => _request(profId),
                                  onCancel:  () => _cancelRequest(profId),
                                  onRate:    () => _showRatingSheet(prof),
                                  onOpen: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MyDoctorPage(
                                        professionalId:   profId,
                                        professionalName:
                                            prof['full_name']?.toString() ?? '',
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: _filtered.length,
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  // ── Bottom nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    const currentIndex = 3;
    const icons  = [
      Icons.sentiment_satisfied_alt,
      Icons.menu_book,
      Icons.grid_view,
      Icons.local_hospital,
    ];
    const labels = ['Mood', 'Journal', 'Toolkit', 'Doctors'];
    const routes = ['/mood', '/journal', '/toolkit', '/doctor'];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft:  Radius.circular(20),
            topRight: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: BottomNavigationBar(
        type:                 BottomNavigationBarType.fixed,
        currentIndex:         currentIndex,
        backgroundColor:      Colors.transparent,
        elevation:            0,
        selectedItemColor:    const Color.fromARGB(255, 0, 0, 0),
        unselectedItemColor:  Colors.grey,
        showUnselectedLabels: true,
        onTap: (i) {
          if (i == currentIndex) return;
          Navigator.pushReplacementNamed(context, routes[i]);
        },
        items: List.generate(
          4,
          (i) => BottomNavigationBarItem(
            label: labels[i],
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: i == currentIndex
                    ? const Color.fromARGB(255, 0, 150, 136)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(icons[i],
                  color: i == currentIndex ? Colors.white : Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  // ── Linked banner ─────────────────────────────────────────────────────────

  Widget _buildLinkedBanner() {
    return GestureDetector(
      onTap: () {
        if (_myLinks.isEmpty) return;
        final l = _myLinks.first;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MyDoctorPage(
              professionalId:
                  l['professional_id'] ?? l['professional_user_id'] ?? '',
              professionalName: l['professional_name'] ?? 'My Doctor',
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6ECFBA), Color(0xFF4DB8A8)],
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color:      _teal.withOpacity(0.3),
                blurRadius: 12,
                offset:     const Offset(0, 4)),
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color:  Colors.white.withOpacity(0.2),
                shape:  BoxShape.circle),
            child: const Icon(Icons.verified_user,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_myLinks.length} Linked Professional'
                  '${_myLinks.length > 1 ? "s" : ""}',
                  style: const TextStyle(
                      color:      Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize:   15),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Tap to open your health portal',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white),
        ]),
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (v) => setState(() => _search = v),
      decoration: InputDecoration(
        hintText:  'Search by name or specialty…',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled:    true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:   BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ── Specialty chips ───────────────────────────────────────────────────────

  Widget _buildSpecialtyChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount:        _specialties.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s      = _specialties[i];
          final active = _filter == s;
          return GestureDetector(
            onTap: () => setState(() => _filter = s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? _teal : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: active ? _teal : Colors.grey.shade200),
              ),
              child: Text(
                s,
                style: TextStyle(
                  color:      active ? Colors.white : Colors.grey[600],
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text('No professionals found',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// ── Gender Avatar ─────────────────────────────────────────────────────────────

class _GenderAvatar extends StatelessWidget {
  final String  name;
  final String? gender;
  final double  radius;
  final Color   teal;

  const _GenderAvatar({
    required this.name,
    required this.gender,
    required this.radius,
    required this.teal,
  });

  @override
  Widget build(BuildContext context) {
    final g        = gender?.toLowerCase() ?? '';
    final isFemale = g.contains('f');
    final isMale   = g.contains('m') && !isFemale;

    final bgColor = isFemale
        ? const Color(0xFFFFE4F0)
        : isMale
            ? const Color(0xFFE4F0FF)
            : teal.withOpacity(0.12);

    return CircleAvatar(
      radius:          radius,
      backgroundColor: bgColor,
      child: isMale
          ? _MaleDoodle(radius: radius, color: const Color(0xFF4A90D9))
          : isFemale
              ? _FemaleDoodle(
                  radius: radius, color: const Color(0xFFE05C8A))
              : Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                      color:      teal,
                      fontWeight: FontWeight.bold,
                      fontSize:   radius * 0.8),
                ),
    );
  }
}

// Male doodle ──────────────────────────────────────────────────────────────────

class _MaleDoodle extends StatelessWidget {
  final double radius;
  final Color  color;
  const _MaleDoodle({required this.radius, required this.color});
  @override
  Widget build(BuildContext context) => CustomPaint(
      size:    Size(radius * 1.4, radius * 1.4),
      painter: _MalePainter(color: color));
}

class _MalePainter extends CustomPainter {
  final Color color;
  const _MalePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color..style = PaintingStyle.fill;
    final cx   = size.width / 2;

    // Head
    canvas.drawCircle(
        Offset(cx, size.height * 0.28), size.width * 0.22, fill);

    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            cx - size.width * 0.22, size.height * 0.52,
            size.width * 0.44, size.height * 0.38),
        Radius.circular(size.width * 0.12),
      ),
      fill,
    );

    // Collar V
    final collar = Paint()
      ..color       = Colors.white.withOpacity(0.8)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap   = StrokeCap.round;
    final path = Path()
      ..moveTo(cx - size.width * 0.08, size.height * 0.52)
      ..lineTo(cx, size.height * 0.62)
      ..lineTo(cx + size.width * 0.08, size.height * 0.52);
    canvas.drawPath(path, collar);

    // Stethoscope
    final stet = Paint()
      ..color       = Colors.white.withOpacity(0.75)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.065
      ..strokeCap   = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(cx, size.height * 0.70),
          width:  size.width  * 0.30,
          height: size.height * 0.22),
      3.14, 3.14, false, stet,
    );
    canvas.drawCircle(
        Offset(cx, size.height * 0.81),
        size.width * 0.055,
        Paint()..color = Colors.white.withOpacity(0.75));
  }

  @override
  bool shouldRepaint(_) => false;
}

// Female doodle ────────────────────────────────────────────────────────────────

class _FemaleDoodle extends StatelessWidget {
  final double radius;
  final Color  color;
  const _FemaleDoodle({required this.radius, required this.color});
  @override
  Widget build(BuildContext context) => CustomPaint(
      size:    Size(radius * 1.4, radius * 1.4),
      painter: _FemalePainter(color: color));
}

class _FemalePainter extends CustomPainter {
  final Color color;
  const _FemalePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color..style = PaintingStyle.fill;
    final cx   = size.width / 2;

    // Head
    canvas.drawCircle(
        Offset(cx, size.height * 0.27), size.width * 0.22, fill);

    // Hair bun
    canvas.drawCircle(
        Offset(cx, size.height * 0.08),
        size.width * 0.10,
        Paint()..color = color.withOpacity(0.7));

    // Dress
    final body = Path()
      ..moveTo(cx - size.width * 0.16, size.height * 0.50)
      ..lineTo(cx - size.width * 0.28, size.height * 0.90)
      ..lineTo(cx + size.width * 0.28, size.height * 0.90)
      ..lineTo(cx + size.width * 0.16, size.height * 0.50)
      ..close();
    canvas.drawPath(body, fill);

    // Medical cross
    final cross = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, size.height * 0.68),
            width:  size.width  * 0.09,
            height: size.height * 0.22),
        Radius.circular(size.width * 0.03),
      ),
      cross,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, size.height * 0.68),
            width:  size.width  * 0.22,
            height: size.height * 0.09),
        Radius.circular(size.width * 0.03),
      ),
      cross,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Professional Card ─────────────────────────────────────────────────────────

class _ProfCard extends StatelessWidget {
  final Map<String, dynamic> prof;
  final String        status;   // 'none' | 'pending' | 'linked'
  final Color         teal;
  final VoidCallback  onRequest;
  final VoidCallback  onCancel;
  final VoidCallback  onRate;   // ← rating sheet from old design
  final VoidCallback  onOpen;

  const _ProfCard({
    required this.prof,
    required this.status,
    required this.teal,
    required this.onRequest,
    required this.onCancel,
    required this.onRate,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final name      = prof['full_name']?.toString() ?? 'Unknown';
    final specialty = prof['specialty']?.toString() ?? 'Professional';
    final expYears  = (prof['experience_years'] as num?)?.toInt() ?? 0;
    final rating    = (prof['rating'] as num?)?.toDouble() ?? 0.0;
    final isOnline  = prof['is_online'] == true;
    final gender    = prof['user_gender']?.toString();

    return Container(
      margin:  const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: status == 'linked'
            ? Border.all(color: teal.withOpacity(0.5), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset:     const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Top row: avatar + info ───────────────────────────────────
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Avatar with online dot
            Stack(children: [
              _GenderAvatar(
                  name: name, gender: gender, radius: 28, teal: teal),
              if (isOnline)
                Positioned(
                  bottom: 1, right: 1,
                  child: Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                        color:  Colors.green,
                        shape:  BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2)),
                  ),
                ),
            ]),
            const SizedBox(width: 14),

            // Info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                    // Status badge
                    if (status == 'linked')
                      _badge('Linked', Icons.verified, teal,
                          teal.withOpacity(0.1))
                    else if (status == 'pending')
                      _badge('Requested', Icons.hourglass_top_rounded,
                          Colors.orange, Colors.orange.withOpacity(0.1)),
                  ]),
                  const SizedBox(height: 3),

                  Text(specialty,
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 6),

                  Row(children: [
                    // Experience
                    if (expYears > 0) ...[
                      Icon(Icons.work_outline,
                          size: 13, color: Colors.grey[400]),
                      const SizedBox(width: 3),
                      Text('$expYears yrs exp',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11)),
                      const SizedBox(width: 10),
                    ],
                    // Online status
                    Icon(
                      isOnline ? Icons.circle : Icons.circle_outlined,
                      size:  8,
                      color: isOnline ? Colors.green : Colors.grey[300],
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isOnline ? 'Online now' : 'Offline',
                      style: TextStyle(
                          color:    isOnline ? Colors.green : Colors.grey,
                          fontSize: 11),
                    ),
                    const Spacer(),
                    // Rating tap target (from old design)
                    if (rating > 0)
                      GestureDetector(
                        onTap: onRate,
                        child: Row(children: [
                          const Icon(Icons.star,
                              color: Colors.amber, size: 13),
                          const SizedBox(width: 2),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize:   12,
                                fontWeight: FontWeight.w600,
                                color:      Colors.black87),
                          ),
                        ]),
                      ),
                  ]),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 14),

          // ── Action buttons ───────────────────────────────────────────
          Row(children: [
            if (status == 'linked') ...[
              Expanded(
                  child: _btn('Open Portal', Icons.open_in_new, teal, onOpen)),
            ] else if (status == 'pending') ...[
              Expanded(
                child: _btn('Pending…', Icons.hourglass_empty,
                    Colors.orange, null,
                    outlined: true),
              ),
              const SizedBox(width: 8),
              _iconBtn(Icons.close, Colors.red, onCancel),
            ] else ...[
              Expanded(
                child: _btn(
                    'Request', Icons.person_add_outlined, teal, onRequest),
              ),
            ],
          ]),
        ],
      ),
    );
  }

  // ── Card helpers ──────────────────────────────────────────────────────────

  Widget _badge(String label, IconData icon, Color color, Color bg) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  color:      color,
                  fontSize:   10,
                  fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _btn(
    String    label,
    IconData  icon,
    Color     color,
    VoidCallback? onTap, {
    bool outlined = false,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: outlined
                ? Colors.transparent
                : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                    color:      color,
                    fontWeight: FontWeight.w600,
                    fontSize:   13),
              ),
            ],
          ),
        ),
      );

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              color:        color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: color.withOpacity(0.2))),
          child: Icon(icon, size: 16, color: color),
        ),
      );
}