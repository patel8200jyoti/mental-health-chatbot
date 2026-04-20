import 'package:flutter/material.dart';
import 'package:mindease/utils/profile_doodle.dart';
import '../../services/chat_api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Bar data model

class _Bar {
  final String xLabel;
  final double score;
  final bool   current;
  const _Bar(this.xLabel, this.score, {this.current = false});
}

class _GraphPainter extends CustomPainter {
  final List<_Bar> bars;
  const _GraphPainter(this.bars);

  static const _teal     = Color(0xFF4FBFA5);
  static const _mint     = Color(0xFFB2F1E8);
  static const _grid     = Color(0xFFEAEFF4);
  static const _baseline = Color(0xFFDDE3E9);
  //static const _text = Color.fromARGB(255, 24, 22, 22)E3E9);

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width;
    final H = size.height;
    final n = bars.length;
    if (n == 0) return;

    final gp = Paint()..strokeWidth = 1;
    gp.color = _baseline;
    canvas.drawLine(Offset(0, H), Offset(W, H), gp);
    gp.color = _grid;
    for (final pct in [0.25, 0.50, 0.75, 1.00]) {
      canvas.drawLine(Offset(0, H - pct * H), Offset(W, H - pct * H), gp);
    }

    final slotW  = W / n;
    final padX   = slotW * 0.15;
    final barW   = slotW - padX * 2;
    final radius = Radius.circular(barW * 0.22);
    final bp     = Paint();

    for (int i = 0; i < n; i++) {
      final bar  = bars[i];
      final frac = ((bar.score - 2) / 4).clamp(0.0, 1.0);
      final barH = (frac * H).clamp(3.0, H);
      final left = i * slotW + padX;
      bp.color   = bar.current ? _teal : _mint;
      canvas.drawRRect(
        RRect.fromLTRBAndCorners(
          left, H - barH, left + barW, H,
          topLeft: radius, topRight: radius,
        ),
        bp,
      );
    }
  }

  @override
  bool shouldRepaint(_GraphPainter old) {
    if (old.bars.length != bars.length) return true;
    for (int i = 0; i < bars.length; i++) {
      if (old.bars[i].score   != bars[i].score)   return true;
      if (old.bars[i].current != bars[i].current) return true;
    }
    return false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});
  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  final _api = AppApi();

  String? _selectedMood;
  bool    _userHasTapped = false;

  // ── Other state ────────────────────────────────────────────────────────────
  int     _tabIndex     = 0;
  bool    _isSubmitting = false;
  bool    _isLoading    = true;
  int     _streak       = 0;

  List<Map<String, dynamic>> _daily   = [];
  List<Map<String, dynamic>> _weekly  = [];
  List<Map<String, dynamic>> _monthly = [];

  // ── Constants ──────────────────────────────────────────────────────────────
  static const _moods = [
    {'label': 'Sad',   'emoji': '😔'},
    {'label': 'Okay',  'emoji': '😐'},
    {'label': 'Calm',  'emoji': '😌'},
    {'label': 'Happy', 'emoji': '😊'},
    {'label': 'Great', 'emoji': '😁'},
  ];

  static const _yLabels   = ['Sad', 'Okay', 'Calm', 'Happy', 'Great'];
  static const _monthAbbr = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May',
    'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const _scoreToLabel = {2: 'Sad', 3: 'Okay', 4: 'Calm', 5: 'Happy', 6: 'Great'};
  static const _labelToScore = {'sad': 2, 'okay': 3, 'calm': 4, 'happy': 5, 'great': 6};

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  // ── Initial load: shows spinner, reads today's saved mood from API ─────────
  Future<void> _initialLoad() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _api.getMoodStats().catchError((_) => <String, dynamic>{}),
        _api.getStreak().catchError((_) => 0),
        _api.getWeekMood().catchError((_) => <Map<String, dynamic>>[]),
      ]);

      final stats  = results[0] as Map<String, dynamic>;
      final streak = results[1] as int;
      final week   = results[2] as List<Map<String, dynamic>>;

      // Find today's saved mood — only used if user hasn't tapped yet
      String? savedTodayMood;
      if (!_userHasTapped) {
        final todayStr = _isoDate(DateTime.now());
        for (final m in week) {
          // mood_date can be "2026-02-26T00:00:00" or "2026-02-26"
          final raw = (m['mood_date'] as String? ?? '');
          final d   = raw.contains('T') ? raw.split('T').first : raw;
          if (d == todayStr) {
            final moodStr = (m['user_mood'] as String? ?? '').toLowerCase().trim();
            if (moodStr.isNotEmpty) {
              savedTodayMood = _cap(moodStr);
            }
            break;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _daily   = _castList(stats['daily']);
        _weekly  = _castList(stats['weekly']);
        _monthly = _castList(stats['monthly']);
        _streak  = streak;
        // Only pre-fill from API if user hasn't made a choice this session
        if (!_userHasTapped) _selectedMood = savedTodayMood;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Mood initial load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Silent background refresh — NEVER touches _selectedMood ───────────────
  Future<void> _silentRefresh() async {
    try {
      final results = await Future.wait([
        _api.getMoodStats().catchError((_) => <String, dynamic>{}),
        _api.getStreak().catchError((_) => 0),
      ]);

      final stats  = results[0] as Map<String, dynamic>;
      final streak = results[1] as int;

      if (!mounted) return;
      setState(() {
        _daily   = _castList(stats['daily']);
        _weekly  = _castList(stats['weekly']);
        _monthly = _castList(stats['monthly']);
        _streak  = streak;
        // ✅ _selectedMood is deliberately NOT touched here
      });
    } catch (e) {
      debugPrint('Silent refresh error: $e');
    }
  }

  // ── Mood submission ────────────────────────────────────────────────────────
  Future<void> _onMoodSelected(String mood) async {
    if (_isSubmitting) return;

    // Update UI immediately — lock the selection
    setState(() {
      _selectedMood  = mood;
      _userHasTapped = true;   // ← prevents any future API call from overriding
      _isSubmitting  = true;
    });

    try {
      await _api.addMood(mood);
      // Refresh graph + streak silently (no spinner, no _selectedMood change)
      await _silentRefresh();
    } catch (e) {
      debugPrint('Failed to save mood: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:         Text('Failed to save mood. Try again.'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _isoDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  List<Map<String, dynamic>> _castList(dynamic raw) =>
      raw is List ? List<Map<String, dynamic>>.from(raw) : [];

  double _toD(dynamic v) => v is num ? v.toDouble() : 0.0;

  int _isoWeek(DateTime dt) {
    final jan4    = DateTime(dt.year, 1, 4);
    final startW1 = jan4.subtract(Duration(days: jan4.weekday - 1));
    final diff    = dt.difference(startW1).inDays;
    if (diff < 0) return _isoWeek(DateTime(dt.year - 1, 12, 28));
    return (diff / 7).floor() + 1;
  }

  // ── Bar builders ───────────────────────────────────────────────────────────
  List<_Bar> get _dayBars {
    final todayStr = _isoDate(DateTime.now());
    return _daily.map((d) {
      final dateStr = d['date'] as String? ?? '';
      final dt      = DateTime.tryParse(dateStr) ?? DateTime.now();
      return _Bar(
        '${_monthAbbr[dt.month]} ${dt.day}',
        _toD(d['avg_score']),
        current: dateStr == todayStr,
      );
    }).toList();
  }

  List<_Bar> get _weekBars {
    final now = DateTime.now();
    return _weekly.map((w) {
      final wk = (w['week'] as num).toInt();
      final yr = (w['year'] as num).toInt();
      return _Bar('Wk $wk', _toD(w['avg_score']),
          current: yr == now.year && wk == _isoWeek(now));
    }).toList();
  }

  List<_Bar> get _monthBars {
    final now = DateTime.now();
    return _monthly.map((m) {
      final mon = (m['month'] as num).toInt();
      final yr  = (m['year']  as num).toInt();
      return _Bar(_monthAbbr[mon], _toD(m['avg_score']),
          current: yr == now.year && mon == now.month);
    }).toList();
  }

  List<_Bar> get _bars {
    switch (_tabIndex) {
      case 0:  return _dayBars;
      case 1:  return _weekBars;
      default: return _monthBars;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4FBFA5)))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 22),
                  _buildMoodPicker(),
                  const SizedBox(height: 28),
                  _buildGraphCard(),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: IconButton(
      icon:      const ProfileDoodleIcon(size: 40, filled: true),
      onPressed: () => Navigator.pushNamed(context, '/profile'),
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 12),
        child: IconButton(
          onPressed: () => Navigator.pushNamed(context, '/chat'),
          icon: const CircleAvatar(
            backgroundColor: Colors.teal,
            child: Icon(Icons.spa, color: Colors.white),
          ),
        ),
      ),
    ],
  );

  Widget _buildHeader() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text('Your Journey',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF4FF),
          borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          const Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
          const SizedBox(width: 6),
          Text('$_streak Day Streak',
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      ),
    ],
  );

  Widget _buildMoodPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('HOW ARE YOU FEELING?',
            style: TextStyle(
                fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _moods.map((m) {
            final label      = m['label']!;
            final isSelected = _selectedMood == label;
            return GestureDetector(
              onTap: _isSubmitting ? null : () => _onMoodSelected(label),
              child: Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color:  isSelected ? const Color(0xFFE6FAF7) : Colors.white,
                    shape:  BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF4FBFA5)
                          : const Color(0xFFE5E7EB),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0xFF4FBFA5).withOpacity(0.25)
                            : Colors.black.withOpacity(0.04),
                        blurRadius: isSelected ? 10 : 4,
                        offset:     const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(m['emoji']!, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(height: 7),
                Text(label, style: TextStyle(
                  fontSize:   12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  color: isSelected
                      ? const Color(0xFF4FBFA5)
                      : const Color(0xFF6B7280),
                )),
              ]),
            );
          }).toList(),
        ),
        if (_isSubmitting)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Center(child: SizedBox(
              height: 14, width: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF4FBFA5)),
            )),
          ),
      ],
    );
  }

  Widget _buildGraphCard() {
    final bars = _bars;
    double avg = bars.isEmpty
        ? 0
        : bars.map((b) => b.score).reduce((a, b) => a + b) / bars.length;
    final avgLabel = avg == 0   ? 'No data yet'
        : avg >= 5.5 ? 'Great'
        : avg >= 4.5 ? 'Happy'
        : avg >= 3.5 ? 'Calm'
        : avg >= 2.5 ? 'Okay'
        : 'Sad';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x1A7ADFD1), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('AVERAGE MOOD',
                  style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 0.5)),
              const SizedBox(height: 3),
              Text(avgLabel,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                      color: Color(0xFF111827))),
            ]),
            _buildTabSelector(),
          ],
        ),
        const SizedBox(height: 18),
        if (bars.isEmpty)
          const SizedBox(
            height: 160,
            child: Center(child: Text('Log your mood to see trends',
                style: TextStyle(color: Colors.grey))),
          )
        else
          _buildGraph(bars),
      ]),
    );
  }

  Widget _buildTabSelector() {
    const tabs = ['Day', 'Week', 'Month'];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final on = _tabIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _tabIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color:        on ? const Color(0xFF4FBFA5) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(tabs[i], style: TextStyle(
                fontSize:   12,
                fontWeight: on ? FontWeight.w600 : FontWeight.normal,
                color:      on ? Colors.white : Colors.grey,
              )),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGraph(List<_Bar> bars) {
    const double topPad   = 10;
    const double xAxisH   = 20;
    const double barAreaH = 150;
    const double totalH   = topPad + barAreaH + xAxisH;

    return SizedBox(
      height: totalH,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 36,
          child: Stack(
            children: List.generate(5, (i) {
              final fraction             = i / 4.0;
              final bottomFromStackBottom = xAxisH + fraction * barAreaH - 5;
              return Positioned(
                right: 4, bottom: bottomFromStackBottom,
                child: Text(_yLabels[i],
                    style: const TextStyle(fontSize: 9, color: Color.fromARGB(255, 34, 35, 35), height: 1)),
              );
            }),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(child: Column(children: [
          const SizedBox(height: topPad),
          SizedBox(
            height: barAreaH,
            child: CustomPaint(
              painter: _GraphPainter(bars),
              child: const SizedBox.expand(),
            ),
          ),
          SizedBox(
            height: xAxisH,
            child: Row(
              children: bars.map((bar) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(bar.xLabel,
                    textAlign: TextAlign.center,
                    overflow:  TextOverflow.visible,
                    style: TextStyle(
                      fontSize:   8.0,
                      color:      bar.current
                          ?  Colors.teal
                          : const Color(0xFF4FBFA5),
                      fontWeight: bar.current
                          ? FontWeight.w700
                          : FontWeight.normal,
                    )),
                ),
              )).toList(),
            ),
          ),
        ])),
      ]),
    );
  }

  Widget _buildBottomNav() {
    const current = 0;
    const icons   = [Icons.sentiment_satisfied_alt, Icons.menu_book,
                     Icons.grid_view, Icons.local_hospital];
    const labels  = ['Mood', 'Journal', 'Toolkit', 'Doctors'];
    const routes  = ['/mood', '/journal', '/toolkit', '/doctor'];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: BottomNavigationBar(
        type:                 BottomNavigationBarType.fixed,
        currentIndex:         current,
        backgroundColor:      Colors.transparent,
        elevation:            0,
        selectedItemColor:    Colors.black,
        unselectedItemColor:  Colors.grey,
        showUnselectedLabels: true,
        onTap: (i) {
          if (i == current) return;
          Navigator.pushReplacementNamed(context, routes[i]);
        },
        items: List.generate(4, (i) => BottomNavigationBarItem(
          label: labels[i],
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:  i == current ? Colors.teal : Colors.transparent,
              shape:  BoxShape.circle,
            ),
            child: Icon(icons[i],
                color: i == current ? Colors.white : Colors.grey),
          ),
        )),
      ),
    );
  }
}