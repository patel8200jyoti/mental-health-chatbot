import 'package:flutter/material.dart';
import '../../services/chat_api_service.dart';

class MyDoctorPage extends StatefulWidget {
  final String professionalId;
  final String professionalName;

  const MyDoctorPage({
    super.key,
    required this.professionalId,
    required this.professionalName,
  });

  @override
  State<MyDoctorPage> createState() => _MyDoctorPageState();
}

class _MyDoctorPageState extends State<MyDoctorPage>
    with SingleTickerProviderStateMixin {
  final AppApi _api = AppApi();
  late final TabController _tabs = TabController(length: 4, vsync: this);
  bool _loading = true;

  static const _teal     = Color(0xFF6ECFBA);
  static const _tealDark = Color(0xFF4DB8A8);

  Map<String, dynamic> _profProfile  = {};
  Map<String, dynamic> _linkInfo     = {};
  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _notes    = [];   // notes professional has shared
  List<Map<String, dynamic>> _messages = [];   // in-portal messages

  // Privacy toggles
  
  bool _allowMood    = false;
  bool _allowJournal = false;
  bool _saving       = false;

  // New session / message state
  final _msgCtrl      = TextEditingController();
  bool _sendingMsg    = false;

  @override
  void initState() { super.initState(); _loadAll(); }

  @override
  void dispose() {
    _tabs.dispose(); _msgCtrl.dispose(); super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait([
      _loadProfProfile(),
      _loadLinkInfo(),
      _loadSessions(),
      _loadMessages(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadProfProfile() async {
    try {
      final p = await _api.getProfProfile(widget.professionalId);
      if (mounted) setState(() => _profProfile = p);
    } catch (e) { debugPrint('prof profile: $e'); }
  }

  Future<void> _loadLinkInfo() async {
    try {
      final l = await _api.getMyLinkWith(widget.professionalId);
      if (mounted) setState(() {
        _linkInfo     = l;
        _allowMood    = l['allow_mood']    == true;
        _allowJournal = l['allow_journal'] == true;
      });
    } catch (e) { debugPrint('link info: $e'); }
  }

  Future<void> _loadSessions() async {
    try {
      final s = await _api.getSessions(widget.professionalId);
      if (mounted) setState(() => _sessions = s);
    } catch (e) { debugPrint('sessions: $e'); }
  }

  Future<void> _loadMessages() async {
    try {
      final m = await _api.getPortalMessages(widget.professionalId);
      if (mounted) setState(() => _messages = m);
    } catch (e) { debugPrint('messages: $e'); }
  }

  Future<void> _savePermissions() async {
    setState(() => _saving = true);
    try {
      await _api.updateLinkPermissions(
        widget.professionalId,
        allowMood: _allowMood,
        allowJournal: _allowJournal,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Permissions updated ✓'),
          backgroundColor: _teal));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _requestSession(DateTime dt, String type, String note) async {
    try {
      await _api.requestSession(
          widget.professionalId, dt.toIso8601String(), type, note);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Session requested ✓'), backgroundColor: _teal));
      await _loadSessions();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sendingMsg = true);
    try {
      await _api.sendPortalMessage(widget.professionalId, text);
      _msgCtrl.clear();
      await _loadMessages();
    } catch (e) { debugPrint('send msg: $e'); }
    if (mounted) setState(() => _sendingMsg = false);
  }

  Future<void> _unlinkDoctor() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Unlink Doctor'),
        content: const Text(
            'This will remove your connection and revoke all shared data access. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unlink', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.unlinkProfessional(widget.professionalId);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  String _timeAgo(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt   = DateTime.parse(raw.toString()).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours   < 24) return '${diff.inHours}h ago';
      if (diff.inDays    <  7) return '${diff.inDays}d ago';
      return '${(diff.inDays / 7).floor()}w ago';
    } catch (_) { return ''; }
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      const months = ['','Jan','Feb','Mar','Apr','May','Jun',
          'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[dt.month]} ${dt.day}, ${dt.year}  '
             '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return raw.toString(); }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F8FF),
    body: NestedScrollView(
      headerSliverBuilder: (_, __) => [_sliverHeader()],
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : Column(children: [
              _tabBar(),
              Expanded(child: TabBarView(controller: _tabs, children: [
                _overviewTab(),
                _sessionsTab(),
                _messagesTab(),
                _privacyTab(),
              ])),
            ]),
    ),
  );

  Widget _sliverHeader() => SliverAppBar(
    expandedHeight: 200,
    pinned: true,
    backgroundColor: Colors.white,
    iconTheme: const IconThemeData(color: Colors.white),
    flexibleSpace: FlexibleSpaceBar(
      background: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6ECFBA), Color(0xFF4A9F90)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: Colors.white.withOpacity(0.25),
              child: Text(
                widget.professionalName.isNotEmpty
                    ? widget.professionalName[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, children: [
              Text(widget.professionalName,
                  style: const TextStyle(color: Colors.white,
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text(
                _profProfile['specialty']?.toString() ?? 'Mental Health Professional',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Row(children: [
                _headerChip(Icons.verified, 'Verified'),
                const SizedBox(width: 8),
                if (_profProfile['experience_years'] != null)
                  _headerChip(Icons.work_outline,
                      '${_profProfile['experience_years']}y exp'),
              ]),
            ])),
          ]),
        )),
      ),
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.link_off, color: Colors.white),
        tooltip: 'Unlink doctor',
        onPressed: _unlinkDoctor,
      ),
    ],
  );

  Widget _headerChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: Colors.white),
      const SizedBox(width: 3),
      Text(label, style: const TextStyle(
          color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _tabBar() => Container(
    color: Colors.white,
    child: TabBar(
      controller: _tabs,
      labelColor: _teal,
      unselectedLabelColor: Colors.grey,
      indicatorColor: _teal,
      indicatorWeight: 2.5,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      tabs: const [
        Tab(text: 'Overview'),
        Tab(text: 'Sessions'),
        Tab(text: 'Messages'),
        Tab(text: 'Privacy'),
      ],
    ),
  );

  // ── OVERVIEW TAB ──────────────────────────────────────────────────────────

  Widget _overviewTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Status card
      _card(child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: _teal.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.link, color: _teal, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Active Connection',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 2),
            Text(
              _linkInfo['accepted_at'] != null
                  ? 'Linked on ${_formatDate(_linkInfo['accepted_at'])}'
                  : 'Linked successfully',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              CircleAvatar(radius: 4, backgroundColor: Colors.green),
              SizedBox(width: 5),
              Text('Active', style: TextStyle(
                  color: Colors.green, fontSize: 11,
                  fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      ])),

      const SizedBox(height: 14),

      // Doctor details
      _card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Professional Details',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        _detailRow(Icons.medical_services_outlined,
            'Specialty', _profProfile['specialty']?.toString() ?? '—'),
        _detailRow(Icons.badge_outlined,
            'Registration No',
            _profProfile['medical_registration_number']?.toString() ?? '—'),
        _detailRow(Icons.school_outlined,
            'Qualifications',
            _profProfile['educational_qualifications']?.toString() ?? '—'),
        _detailRow(Icons.account_balance_outlined,
            'Medical Council',
            _profProfile['state_medical_council']?.toString() ?? '—'),
        _detailRow(Icons.calendar_today_outlined,
            'Registered',
            _profProfile['year_of_registration']?.toString() ?? '—'),
        if (_profProfile['experience_years'] != null)
          _detailRow(Icons.work_history_outlined,
              'Experience', '${_profProfile['experience_years']} years'),
      ])),

      const SizedBox(height: 14),

      // Quick stats
      Row(children: [
        Expanded(child: _miniStat(
          '${_sessions.length}', 'Sessions', Icons.calendar_month, Colors.indigo)),
        const SizedBox(width: 12),
        Expanded(child: _miniStat(
          '${_messages.length}', 'Messages', Icons.chat_bubble_outline, _teal)),
        const SizedBox(width: 12),
        Expanded(child: _miniStat(
          _allowMood ? 'On' : 'Off', 'Mood Share',
          Icons.mood, _allowMood ? Colors.green : Colors.grey)),
      ]),

      const SizedBox(height: 14),

      // What doctor can see
      _card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('What your doctor can see',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('You control this in the Privacy tab',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 14),
        _visibilityRow('Your Mood Logs', _allowMood, _teal,
            'Mood history and daily check-ins'),
        const SizedBox(height: 10),
        _visibilityRow('Your Journal Entries', _allowJournal, Colors.purple,
            'Private journal entries you\'ve written'),
        const SizedBox(height: 10),
        _visibilityRow('Crisis Alerts', true, Colors.red,
            'Always shared for your safety', alwaysOn: true),
      ])),

      const SizedBox(height: 24),
    ]),
  );

  Widget _detailRow(IconData icon, String label, String value) {
    if (value == '—' || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 10),
        SizedBox(width: 110, child: Text(label, style: const TextStyle(
            color: Colors.grey, fontSize: 12))),
        Expanded(child: Text(value, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  Widget _visibilityRow(String title, bool on, Color color,
      String subtitle, {bool alwaysOn = false}) =>
      Row(children: [
        Icon(on ? Icons.visibility : Icons.visibility_off,
            color: on ? color : Colors.grey[300], size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600)),
          Text(subtitle, style: const TextStyle(
              color: Colors.grey, fontSize: 11)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
              color: on ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8)),
          child: Text(
            alwaysOn ? 'Always' : (on ? 'Visible' : 'Hidden'),
            style: TextStyle(
                color: on ? color : Colors.grey,
                fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ]);

  Widget _miniStat(String value, String label,
      IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 6)],
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(
              color: Colors.grey, fontSize: 10),
              textAlign: TextAlign.center),
        ]),
      );

  // ── SESSIONS TAB ──────────────────────────────────────────────────────────

  Widget _sessionsTab() => Column(children: [
    Expanded(
      child: _sessions.isEmpty
          ? _emptyState(Icons.calendar_today_outlined,
              'No sessions yet',
              'Request a session with your doctor below.')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sessions.length,
              itemBuilder: (_, i) => _sessionCard(_sessions[i]),
            ),
    ),
    _requestSessionBar(),
  ]);

  Widget _sessionCard(Map<String, dynamic> s) {
    final type      = s['session_type']?.toString() ?? 'Consultation';
    final status    = s['status']?.toString()       ?? 'pending';
    final dateRaw   = s['session_date'];
    final note      = s['note']?.toString()         ?? '';
    final date      = dateRaw != null ? _formatDate(dateRaw) : '—';

    Color sc; String sl;
    switch (status) {
      case 'confirmed': sc = Colors.green;  sl = 'Confirmed'; break;
      case 'rejected':  sc = Colors.red;    sl = 'Declined';  break;
      case 'completed': sc = Colors.indigo; sl = 'Completed'; break;
      default:          sc = Colors.orange; sl = 'Pending';
    }

    IconData typeIcon;
    switch (type.toLowerCase()) {
      case 'video':    typeIcon = Icons.videocam_outlined;     break;
      case 'audio':    typeIcon = Icons.phone_outlined;        break;
      case 'in-person': typeIcon = Icons.person_pin_outlined;  break;
      default:          typeIcon = Icons.calendar_month;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sc.withOpacity(0.2)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: _teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(typeIcon, color: _teal, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(type, style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14)),
            Text(date, style: const TextStyle(
                color: Colors.grey, fontSize: 12)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: sc.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Text(sl, style: TextStyle(
                color: sc, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        if (note.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: const Color(0xFFF5F8FF),
                borderRadius: BorderRadius.circular(10)),
            child: Text(note, style: const TextStyle(
                color: Colors.black87, fontSize: 13)),
          ),
        ],
      ]),
    );
  }

  Widget _requestSessionBar() => Container(
    color: Colors.white,
    padding: const EdgeInsets.all(16),
    child: SafeArea(
      top: false,
      child: GestureDetector(
        onTap: _showSessionSheet,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [_teal, _tealDark],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
                color: _teal.withOpacity(0.3),
                blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add_circle_outline, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Request a Session', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold,
                fontSize: 15)),
          ]),
        ),
      ),
    ),
  );

  void _showSessionSheet() {
    String selectedType = 'Consultation';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              top: 24, left: 20, right: 20),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4)),
            )),
            const SizedBox(height: 20),
            const Text('Request a Session',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Session type
            const Text('Session Type',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Row(children: ['Consultation', 'Follow-up', 'Video', 'Audio']
                .map((t) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setS(() => selectedType = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: selectedType == t
                            ? _teal : const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(t, style: TextStyle(
                          color: selectedType == t
                              ? Colors.white : Colors.grey[700],
                          fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                )).toList()),
            const SizedBox(height: 16),

            // Date picker
            const Text('Preferred Date & Time',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)));
                if (d == null) return;
                final t = await showTimePicker(
                    context: ctx, initialTime: TimeOfDay.now());
                if (t == null) return;
                setS(() => selectedDate = DateTime(
                    d.year, d.month, d.day, t.hour, t.minute));
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: const Color(0xFFF5F8FF),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  const Icon(Icons.calendar_month, color: _teal, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
                    '  ${selectedDate.hour.toString().padLeft(2,'0')}:'
                    '${selectedDate.minute.toString().padLeft(2,'0')}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // Note
            const Text('Note for doctor (optional)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe what you\'d like to discuss…',
                filled: true, fillColor: const Color(0xFFF5F8FF),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _requestSession(selectedDate, selectedType, noteCtrl.text.trim());
                },
                child: const Text('Send Request', style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold,
                    fontSize: 15)),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  // ── MESSAGES TAB ──────────────────────────────────────────────────────────

  Widget _messagesTab() => Column(children: [
    Expanded(
      child: _messages.isEmpty
          ? _emptyState(Icons.chat_bubble_outline,
              'No messages yet',
              'Send a message to your doctor below.')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m       = _messages[_messages.length - 1 - i];
                final isMe    = m['sender'] == 'user';
                final text    = m['text']?.toString() ?? '';
                final time    = _timeAgo(m['created_at']);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: isMe
                        ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isMe) ...[
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: _teal.withOpacity(0.12),
                          child: Text(
                            widget.professionalName.isNotEmpty
                                ? widget.professionalName[0].toUpperCase()
                                : '?',
                            style: TextStyle(color: _teal,
                                fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7),
                          decoration: BoxDecoration(
                            color: isMe ? _teal : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft:     const Radius.circular(16),
                              topRight:    const Radius.circular(16),
                              bottomLeft:  Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                            boxShadow: [BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4)],
                          ),
                          child: Text(text, style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              fontSize: 13)),
                        ),
                        const SizedBox(height: 3),
                        Text(time, style: const TextStyle(
                            color: Colors.grey, fontSize: 10)),
                      ])),
                    ],
                  ),
                );
              },
            ),
    ),
    _messageInput(),
  ]);

  Widget _messageInput() => Container(
    color: Colors.white,
    padding: EdgeInsets.only(
        left: 16, right: 16, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12),
    child: Row(children: [
      Expanded(child: TextField(
        controller: _msgCtrl,
        maxLines: 3, minLines: 1,
        decoration: InputDecoration(
          hintText: 'Message your doctor…',
          filled: true, fillColor: const Color(0xFFF5F8FF),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
        ),
      )),
      const SizedBox(width: 10),
      GestureDetector(
        onTap: _sendingMsg ? null : _sendMessage,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: _teal, shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                  color: _teal.withOpacity(0.3), blurRadius: 8)]),
          child: _sendingMsg
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send, color: Colors.white, size: 18),
        ),
      ),
    ]),
  );

  // ── PRIVACY TAB ───────────────────────────────────────────────────────────

  Widget _privacyTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Info banner
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: _teal.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _teal.withOpacity(0.2))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline, color: _teal, size: 20),
          const SizedBox(width: 12),
          const Expanded(child: Text(
            'You are always in control. These settings decide what your doctor can '
            'see. You can change them at any time. Crisis alerts are always shared '
            'for your safety.',
            style: TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
          )),
        ]),
      ),

      const SizedBox(height: 20),

      // Toggle cards
      _permToggleCard(
        icon: Icons.mood,
        color: Colors.teal,
        title: 'Mood Data',
        subtitle: 'Share your daily mood check-ins and mood history with your doctor.',
        value: _allowMood,
        onChanged: (v) => setState(() => _allowMood = v),
      ),

      const SizedBox(height: 12),

      _permToggleCard(
        icon: Icons.menu_book,
        color: Colors.purple,
        title: 'Journal Entries',
        subtitle: 'Allow your doctor to read your journal entries to better understand your mental state.',
        value: _allowJournal,
        onChanged: (v) => setState(() => _allowJournal = v),
      ),

      const SizedBox(height: 12),

      // Crisis - always on
      _card(child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.warning_amber_rounded,
              color: Colors.red, size: 20),
        ),
        const SizedBox(width: 14),
        const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Crisis Alerts', style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 14)),
          SizedBox(height: 2),
          Text('Always shared with your linked professional for your safety.',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10)),
          child: const Text('Always On', style: TextStyle(
              color: Colors.red, fontSize: 11,
              fontWeight: FontWeight.w700)),
        ),
      ])),

      const SizedBox(height: 24),

      // Save button
      SizedBox(width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _teal, elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _saving ? null : _savePermissions,
          child: _saving
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Save Privacy Settings', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ),
      ),

      const SizedBox(height: 16),

      // Danger zone
      _card(child: Column(children: [
        const Row(children: [
          Icon(Icons.warning_outlined, color: Colors.red, size: 18),
          SizedBox(width: 8),
          Text('Danger Zone', style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.red)),
        ]),
        const SizedBox(height: 10),
        const Text(
          'Unlinking removes the doctor\'s access to all your data and cancels any pending sessions.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _unlinkDoctor,
            icon: const Icon(Icons.link_off, color: Colors.red, size: 16),
            label: const Text('Unlink Doctor',
                style: TextStyle(color: Colors.red,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ])),

      const SizedBox(height: 32),
    ]),
  );

  Widget _permToggleCard({
    required IconData icon, required Color color,
    required String title, required String subtitle,
    required bool value, required ValueChanged<bool> onChanged,
  }) => _card(child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(
            color: Colors.grey, fontSize: 12, height: 1.4)),
      ])),
      const SizedBox(width: 8),
      Switch(
        value: value,
        onChanged: onChanged,
        activeColor: _teal,
      ),
    ],
  ));

  // ── HELPERS ───────────────────────────────────────────────────────────────

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: child,
  );

  Widget _emptyState(IconData icon, String title, String subtitle) =>
      Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center),
        ]),
      ));
}