import 'package:flutter/material.dart';
import '../../services/professional_api.dart';
import 'proff_patients.dart';
import 'proff_crisis.dart';

class ProfDashboard extends StatefulWidget {
  const ProfDashboard({super.key});
  @override
  State<ProfDashboard> createState() => _ProfDashboardState();
}

class _ProfDashboardState extends State<ProfDashboard> {
  final _api = ProfessionalApi();
  bool _loading = true;

  int _totalPatients   = 0;
  int _pendingRequests = 0;
  int _openCrisis      = 0;
  int _streakCount     = 0;
  int _totalJournals   = 0;

  List<Map<String, dynamic>> _recentPatients = [];
  List<Map<String, dynamic>> _crisisAlerts   = [];
  List<Map<String, dynamic>> _pendingList    = [];

  @override
  void initState() { super.initState(); _loadAll(); }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait([
      _loadStats(),
      _loadRecentPatients(),
      _loadCrisis(),
      _loadPending(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadStats() async {
    try {
      final s = await _api.getDashboardStats();
      if (mounted) setState(() {
        _totalPatients   = (s['total_patients']   as num?)?.toInt() ?? 0;
        _pendingRequests = (s['pending_requests'] as num?)?.toInt() ?? 0;
        _openCrisis      = (s['open_crisis']      as num?)?.toInt() ?? 0;
        _streakCount     = (s['streak_count']     as num?)?.toInt() ?? 0;
        _totalJournals   = (s['total_journals']   as num?)?.toInt() ?? 0;
      });
    } catch (e) { debugPrint('stats: $e'); }
  }

  Future<void> _loadRecentPatients() async {
    try {
      final list = await _api.getPatients();
      if (mounted) setState(() => _recentPatients = list.take(3).toList());
    } catch (e) { debugPrint('patients: $e'); }
  }

  Future<void> _loadCrisis() async {
    try {
      final list = await _api.getCrisisAlerts(resolved: false);
      if (mounted) setState(() => _crisisAlerts = list.take(3).toList());
    } catch (e) { debugPrint('crisis: $e'); }
  }

  Future<void> _loadPending() async {
    try {
      final list = await _api.getPendingRequests();
      if (mounted) setState(() => _pendingList = list.take(3).toList());
    } catch (e) { debugPrint('pending: $e'); }
  }

  Future<void> _respond(String userId, bool accept) async {
    try {
      await _api.respondToRequest(userId, accept);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(accept ? '✓ Patient accepted' : 'Request declined'),
        backgroundColor: accept ? Colors.green : Colors.red,
      ));
      await Future.wait([_loadStats(), _loadPending(), _loadRecentPatients()]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _resolveAlert(String id) async {
    try {
      await _api.resolveAlert(id);
      await Future.wait([_loadStats(), _loadCrisis()]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Alert resolved ✓'), backgroundColor: Colors.green));
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
      return '${diff.inDays}d ago';
    } catch (_) { return ''; }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Color _moodColor(String? mood) {
    switch ((mood ?? '').toLowerCase()) {
      case 'great': return const Color(0xFF00C853);
      case 'happy': return const Color(0xFF69F0AE);
      case 'calm':  return const Color(0xFFFFD740);
      case 'okay':  return const Color(0xFFFF6D00);
      case 'sad':   return const Color(0xFFD50000);
      default:      return Colors.grey;
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FC),
    body: SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _header(),
                  const SizedBox(height: 20),
                  _topMetrics(),
                  const SizedBox(height: 16),
                  _systemHealth(),
                  const SizedBox(height: 20),
                  if (_pendingList.isNotEmpty) ...[
                    _pendingRequests_(),
                    const SizedBox(height: 20),
                  ],
                  _recentPatientsSection(),
                  const SizedBox(height: 20),
                  _crisisSection(),
                  const SizedBox(height: 20),
                  _bottomStats(),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
    ),
  );

  // ── HEADER ─────────────────────────────────────────────────────────────────
  Widget _header() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('My Dashboard',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text('PROFESSIONAL PORTAL',
            style: TextStyle(fontSize: 12, color: Colors.grey, letterSpacing: 1.2)),
      ]),
      GestureDetector(
        onTap: _loadAll,
        child: const CircleAvatar(
          radius: 22, backgroundColor: Color(0xFFE6EBF2),
          child: Icon(Icons.refresh, color: Colors.grey, size: 20)),
      ),
    ],
  );

  // ── TOP METRICS ────────────────────────────────────────────────────────────
  Widget _topMetrics() => Row(children: [
    Expanded(child: _metricCard(
      title: 'My Patients', value: _totalPatients.toString(),
      badge: _pendingRequests > 0 ? '$_pendingRequests pending' : 'All linked',
      icon: Icons.people_alt_outlined,
      color: const Color(0xFFEFF4FF),
      badgeColor: _pendingRequests > 0 ? Colors.orange.withOpacity(0.15) : Colors.white,
      badgeTextColor: _pendingRequests > 0 ? Colors.orange : Colors.grey,
    )),
    const SizedBox(width: 12),
    Expanded(child: _metricCard(
      title: 'Crisis Alerts', value: _openCrisis.toString(),
      badge: _openCrisis > 0 ? 'Needs attention' : 'All clear',
      icon: Icons.warning_amber_rounded,
      color: _openCrisis > 0 ? const Color(0xFFFFF4EC) : const Color(0xFFEFF4FF),
      badgeColor: _openCrisis > 0 ? Colors.red.withOpacity(0.12) : Colors.white,
      badgeTextColor: _openCrisis > 0 ? Colors.red : Colors.grey,
    )),
  ]);

  Widget _metricCard({
    required String title, required String value, required String badge,
    required IconData icon, required Color color,
    Color? badgeColor, Color? badgeTextColor,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: Colors.indigo),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: badgeColor ?? Colors.white,
              borderRadius: BorderRadius.circular(12)),
          child: Text(badge, style: TextStyle(
              fontSize: 11, color: badgeTextColor ?? Colors.grey,
              fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 12),
      Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    ]),
  );

  // ── SYSTEM HEALTH ──────────────────────────────────────────────────────────
  Widget _systemHealth() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(16)),
    child: Row(children: const [
      CircleAvatar(radius: 6, backgroundColor: Colors.green),
      SizedBox(width: 10),
      Expanded(child: Text('CONNECTED TO PLATFORM',
          style: TextStyle(fontWeight: FontWeight.w600))),
      Text('Verified Professional', style: TextStyle(color: Colors.grey, fontSize: 12)),
    ]),
  );

  // ── PENDING REQUESTS ───────────────────────────────────────────────────────
  Widget _pendingRequests_() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8F0),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.person_add_outlined, color: Colors.orange, size: 22),
        const SizedBox(width: 10),
        const Expanded(child: Text('Patient Requests',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Text('${_pendingList.length} pending',
              style: const TextStyle(
                  color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ]),
      const SizedBox(height: 4),
      const Text('Patients who requested to link with you',
          style: TextStyle(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 14),
      ..._pendingList.map((p) => _pendingCard(p)),
    ]),
  );

  Widget _pendingCard(Map<String, dynamic> p) {
    final name  = p['user_name']?.toString()  ?? 'Unknown';
    final email = p['user_email']?.toString() ?? '';
    final uid   = p['user_id']?.toString()    ?? '';
    final time  = _timeAgo(p['requested_at']);
    final msg   = p['message']?.toString()    ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.orange.withOpacity(0.1),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            Text(email, style: const TextStyle(color: Colors.grey, fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ])),
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ]),
        if (msg.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: const Color(0xFFFFF9F0),
                borderRadius: BorderRadius.circular(8)),
            child: Text('"$msg"',
                style: const TextStyle(
                    color: Colors.black87, fontSize: 12,
                    fontStyle: FontStyle.italic)),
          ),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: GestureDetector(
            onTap: () => _respond(uid, false),
            child: _actionBtn('Decline', Icons.close, Colors.red),
          )),
          const SizedBox(width: 8),
          Expanded(child: GestureDetector(
            onTap: () => _respond(uid, true),
            child: _actionBtn('Accept', Icons.check, Colors.green),
          )),
        ]),
      ]),
    );
  }

  // ── RECENT PATIENTS ────────────────────────────────────────────────────────
  Widget _recentPatientsSection() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF), borderRadius: BorderRadius.circular(20)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.people_alt_outlined, color: Colors.indigo, size: 22),
        const SizedBox(width: 10),
        const Expanded(child: Text('Recent Patients',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
        GestureDetector(
          onTap: () {
            // Switch to patients tab via shell — use a callback if needed
          },
          child: const Text('VIEW ALL',
              style: TextStyle(color: Colors.indigo, fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 14),
      if (_recentPatients.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: Text('No patients linked yet',
              style: TextStyle(color: Colors.grey))),
        )
      else
        ..._recentPatients.map((p) => _patientCard(p)),
    ]),
  );

  Widget _patientCard(Map<String, dynamic> p) {
    final name       = p['user_name']?.toString()  ?? 'Unknown';
    final email      = p['user_email']?.toString() ?? '';
    final uid        = p['user_id']?.toString()    ?? '';
    final latestMood = p['latest_mood']?.toString();
    final allowMood  = p['allow_mood'] == true;
    final allowJrnl  = p['allow_journal'] == true;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => PatientDetailPage(userId: uid, userName: name))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.indigo.withOpacity(0.1),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            Text(email, style: const TextStyle(color: Colors.grey, fontSize: 12),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              if (allowMood) _permChip('Mood', Colors.teal),
              if (allowMood) const SizedBox(width: 4),
              if (allowJrnl) _permChip('Journal', Colors.purple),
            ]),
          ])),
          if (latestMood != null)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: _moodColor(latestMood).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(_capitalize(latestMood),
                    style: TextStyle(
                        color: _moodColor(latestMood),
                        fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 2),
              const Text('latest mood', style: TextStyle(color: Colors.grey, fontSize: 10)),
            ]),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
        ]),
      ),
    );
  }

  Widget _permChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
        color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
  );

  // ── CRISIS ─────────────────────────────────────────────────────────────────
  Widget _crisisSection() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: const Color(0xFFFFF4EC), borderRadius: BorderRadius.circular(20)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Text('Crisis Alerts',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
        if (_crisisAlerts.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Text('${_crisisAlerts.length} open',
                style: const TextStyle(
                    color: Colors.red, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {},
          child: const Text('VIEW ALL',
              style: TextStyle(color: Colors.orange, fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 4),
      const Text('Crisis alerts from your linked patients',
          style: TextStyle(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 14),
      if (_crisisAlerts.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: Text('No open alerts 🎉',
              style: TextStyle(color: Colors.grey))),
        )
      else
        ..._crisisAlerts.map((a) => _crisisItem(a)),
    ]),
  );

  Widget _crisisItem(Map<String, dynamic> alert) {
    final name    = alert['user_name']?.toString()  ?? 'Unknown';
    final email   = alert['user_email']?.toString() ?? '';
    final message = alert['message']?.toString();
    final time    = _timeAgo(alert['created_at']);
    final id      = alert['_id']?.toString();
    final msgLow  = (message ?? '').toLowerCase();
    final isHigh  = msgLow.contains('suicid') || msgLow.contains('self-harm') ||
                    msgLow.contains('hurt')   || msgLow.contains('die');
    final sc = isHigh ? Colors.red : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sc.withOpacity(0.25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 18, backgroundColor: sc.withOpacity(0.12),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(color: sc, fontWeight: FontWeight.bold))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            if (email.isNotEmpty)
              Text(email, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                  color: sc.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Text(isHigh ? 'HIGH RISK' : 'ALERT',
                  style: TextStyle(
                      color: sc, fontSize: 10,
                      fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ),
            const SizedBox(height: 4),
            Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
        ]),
        if (message != null && message.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: const Color(0xFFFFF9F5),
                borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(Icons.chat_bubble_outline, size: 13, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Expanded(child: Text('"$message"',
                  style: const TextStyle(color: Colors.black87, fontSize: 12,
                      fontStyle: FontStyle.italic),
                  maxLines: 2, overflow: TextOverflow.ellipsis)),
            ]),
          ),
        ],
        if (id != null) ...[
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => _resolveAlert(id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: sc.withOpacity(0.10), borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sc.withOpacity(0.3))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check, size: 13, color: sc),
                  const SizedBox(width: 4),
                  Text('Mark Resolved', style: TextStyle(
                      color: sc, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  // ── BOTTOM STATS ───────────────────────────────────────────────────────────
  Widget _bottomStats() => Row(children: [
    Expanded(child: _StatCard(label: 'MOOD STREAKS', value: _streakCount.toString())),
    const SizedBox(width: 12),
    Expanded(child: _StatCard(label: 'SHARED JOURNALS', value: _totalJournals.toString())),
  ]);

  Widget _actionBtn(String label, IconData icon, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 9),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(
          color: color, fontWeight: FontWeight.w600, fontSize: 13)),
    ]),
  );
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  const _StatCard({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(
          fontSize: 11, color: Colors.grey, letterSpacing: 0.6)),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    ]),
  );
}

// ─── Patient Detail Page ──────────────────────────────────────────────────────
class PatientDetailPage extends StatefulWidget {
  final String userId;
  final String userName;
  const PatientDetailPage({super.key, required this.userId, required this.userName});
  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage>
    with SingleTickerProviderStateMixin {
  final _api = ProfessionalApi();
  late final TabController _tabs = TabController(length: 3, vsync: this);
  bool _loading = true;

  Map<String, dynamic> _profile  = {};
  List<Map<String, dynamic>> _moods    = [];
  List<Map<String, dynamic>> _journals = [];
  List<Map<String, dynamic>> _notes    = [];
  final _noteCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _tabs.dispose(); _noteCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    await Future.wait([
      _loadProfile(),
      _loadNotes(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadProfile() async {
    try {
      final p = await _api.getPatientProfile(widget.userId);
      if (mounted) setState(() => _profile = p);
      if (p['allow_mood'] == true)   await _loadMoods();
      if (p['allow_journal'] == true) await _loadJournals();
    } catch (e) { debugPrint('profile: $e'); }
  }

  Future<void> _loadMoods() async {
    try {
      final m = await _api.getPatientMoods(widget.userId);
      if (mounted) setState(() => _moods = m);
    } catch (e) { debugPrint('moods: $e'); }
  }

  Future<void> _loadJournals() async {
    try {
      final j = await _api.getPatientJournals(widget.userId);
      if (mounted) setState(() => _journals = j);
    } catch (e) { debugPrint('journals: $e'); }
  }

  Future<void> _loadNotes() async {
    try {
      final n = await _api.getNotes(widget.userId);
      if (mounted) setState(() => _notes = n);
    } catch (e) { debugPrint('notes: $e'); }
  }

  Future<void> _addNote() async {
    final text = _noteCtrl.text.trim();
    if (text.isEmpty) return;
    try {
      await _api.addNote(widget.userId, text);
      _noteCtrl.clear();
      await _loadNotes();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteNote(String noteId) async {
    try {
      await _api.deleteNote(widget.userId, noteId);
      await _loadNotes();
    } catch (e) { debugPrint('delete note: $e'); }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Color _moodColor(String? mood) {
    switch ((mood ?? '').toLowerCase()) {
      case 'great': return const Color(0xFF00C853);
      case 'happy': return const Color(0xFF69F0AE);
      case 'calm':  return const Color(0xFFFFD740);
      case 'okay':  return const Color(0xFFFF6D00);
      case 'sad':   return const Color(0xFFD50000);
      default:      return Colors.grey;
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

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FC),
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(widget.userName,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
      iconTheme: const IconThemeData(color: Colors.black),
      bottom: TabBar(
        controller: _tabs,
        labelColor: Colors.indigo,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.indigo,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Mood & Journal'),
          Tab(text: 'My Notes'),
        ],
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabs,
            children: [_overviewTab(), _moodJournalTab(), _notesTab()],
          ),
  );

  // ── OVERVIEW TAB ──────────────────────────────────────────────────────────
  Widget _overviewTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Profile card
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
        ),
        child: Column(children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.indigo.withOpacity(0.1),
            child: Text(
              (_profile['user_name'] ?? '?').toString().isNotEmpty
                  ? (_profile['user_name'] as String)[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Colors.indigo, fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Text(_profile['user_name']?.toString() ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(_profile['user_email']?.toString() ?? '',
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (_profile['user_gender']?.toString().isNotEmpty == true) ...[
              _infoChip(Icons.person_outline, _profile['user_gender'].toString()),
              const SizedBox(width: 8),
            ],
            if (_profile['user_dob']?.toString().isNotEmpty == true &&
                _profile['user_dob'] != 'None')
              _infoChip(Icons.cake_outlined, _profile['user_dob'].toString()),
          ]),
        ]),
      ),

      const SizedBox(height: 16),

      // Stats row
      Row(children: [
        Expanded(child: _miniStatCard(
          label: 'Total Mood Logs',
          value: _profile['total_moods']?.toString() ?? '0',
          icon: Icons.mood, color: Colors.teal,
        )),
        const SizedBox(width: 12),
        Expanded(child: _miniStatCard(
          label: 'Total Journals',
          value: _profile['total_journals']?.toString() ?? '0',
          icon: Icons.menu_book, color: Colors.purple,
        )),
        const SizedBox(width: 12),
        Expanded(child: _miniStatCard(
          label: 'Mood Streak',
          value: _profile['mood_streak']?.toString() ?? '0',
          icon: Icons.local_fire_department, color: Colors.orange,
        )),
      ]),

      const SizedBox(height: 16),

      // Permissions
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Data Sharing Permissions',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Set by the patient in their profile',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 14),
          _permRow('Mood Data', _profile['allow_mood'] == true, Colors.teal),
          const SizedBox(height: 8),
          _permRow('Journal Entries', _profile['allow_journal'] == true, Colors.purple),
        ]),
      ),

      const SizedBox(height: 16),

      // Mood distribution
      if ((_profile['mood_distribution'] as List?)?.isNotEmpty == true) ...[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Mood Distribution',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Based on ${_profile['total_moods'] ?? 0} logs',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 14),
            ...(_profile['mood_distribution'] as List).map((d) {
              final mood  = d['mood']?.toString()     ?? '';
              final count = (d['count'] as num?)?.toInt() ?? 0;
              final total = (_profile['total_moods'] as num?)?.toInt() ?? 1;
              final pct   = total > 0 ? count / total : 0.0;
              final color = _moodColor(mood);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 10, height: 10,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(_capitalize(mood),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const Spacer(),
                    Text('$count  •  ${(pct * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ]),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: color.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 8,
                    ),
                  ),
                ]),
              );
            }),
          ]),
        ),
      ],

      const SizedBox(height: 24),
    ]),
  );

  Widget _infoChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: Colors.grey),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    ]),
  );

  Widget _miniStatCard({
    required String label, required String value,
    required IconData icon, required Color color,
  }) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
    ),
    child: Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10),
          textAlign: TextAlign.center),
    ]),
  );

  Widget _permRow(String label, bool allowed, Color color) => Row(children: [
    Icon(allowed ? Icons.check_circle : Icons.cancel_outlined,
        color: allowed ? color : Colors.grey[300], size: 20),
    const SizedBox(width: 10),
    Expanded(child: Text(label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: allowed ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8)),
      child: Text(allowed ? 'Shared' : 'Private',
          style: TextStyle(
              color: allowed ? color : Colors.grey,
              fontSize: 11, fontWeight: FontWeight.w600)),
    ),
  ]);

  // ── MOOD & JOURNAL TAB ─────────────────────────────────────────────────────
  Widget _moodJournalTab() => DefaultTabController(
    length: 2,
    child: Column(children: [
      Container(
        color: Colors.white,
        child: TabBar(
          labelColor: Colors.indigo,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.indigo,
          tabs: [
            Tab(text: _profile['allow_mood'] == true ? 'Mood Logs' : 'Mood (Locked)'),
            Tab(text: _profile['allow_journal'] == true ? 'Journals' : 'Journal (Locked)'),
          ],
        ),
      ),
      Expanded(child: TabBarView(children: [_moodTab(), _journalTab()])),
    ]),
  );

  Widget _moodTab() {
    final allowed = _profile['allow_mood'] == true;
    if (!allowed) return _lockedView('Mood Data',
        'This patient has not shared their mood logs with you.');
    if (_moods.isEmpty) return const Center(
        child: Text('No mood logs yet', style: TextStyle(color: Colors.grey)));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _moods.length,
      itemBuilder: (_, i) {
        final m     = _moods[i];
        final mood  = m['mood']?.toString()       ?? '';
        final score = (m['mood_score'] as num?)?.toInt() ?? 0;
        final note  = m['note']?.toString()       ?? '';
        final date  = m['date']?.toString()       ?? '';
        final color = _moodColor(mood);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Center(child: Text(
                mood.isNotEmpty ? mood[0].toUpperCase() : '?',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_capitalize(mood),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              if (note.isNotEmpty)
                Text(note, style: const TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$score/5', style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ]),
          ]),
        );
      },
    );
  }

  Widget _journalTab() {
    final allowed = _profile['allow_journal'] == true;
    if (!allowed) return _lockedView('Journal Entries',
        'This patient has not shared their journal entries with you.');
    if (_journals.isEmpty) return const Center(
        child: Text('No journal entries yet', style: TextStyle(color: Colors.grey)));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _journals.length,
      itemBuilder: (_, i) {
        final j         = _journals[i];
        final title     = j['title']?.toString()   ?? 'Untitled';
        final content   = j['content']?.toString() ?? '';
        final sentiment = (j['sentiment'] as num?)?.toDouble() ?? 0;
        final moods     = List<String>.from(j['moods'] ?? []);
        final time      = _timeAgo(j['created_at']);
        final sc        = sentiment > 0.1 ? Colors.green
                        : sentiment < -0.1 ? Colors.red : Colors.blue;
        final sl        = sentiment > 0.1 ? 'Positive'
                        : sentiment < -0.1 ? 'Negative' : 'Neutral';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(sl, style: TextStyle(
                    color: sc, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 6),
            Text(content, style: const TextStyle(color: Colors.grey, fontSize: 13),
                maxLines: 3, overflow: TextOverflow.ellipsis),
            if (moods.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 6, children: moods.take(4).map((m) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(m, style: const TextStyle(
                    color: Colors.indigo, fontSize: 11)),
              )).toList()),
            ],
            const SizedBox(height: 8),
            Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
        );
      },
    );
  }

  Widget _lockedView(String feature, String reason) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
        const SizedBox(height: 16),
        Text(feature, style: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Text(reason, style: const TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        const Text('Patient can toggle this in their Profile → Privacy Settings.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center),
      ]),
    ),
  );

  // ── NOTES TAB ──────────────────────────────────────────────────────────────
  Widget _notesTab() => Column(children: [
    // Add note input
    Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Expanded(child: TextField(
          controller: _noteCtrl,
          maxLines: 2,
          minLines: 1,
          decoration: InputDecoration(
            hintText: 'Add a clinical note…',
            filled: true, fillColor: const Color(0xFFF5F7FA),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        )),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _addNote,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.indigo, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.send, color: Colors.white, size: 18),
          ),
        ),
      ]),
    ),
    Expanded(
      child: _notes.isEmpty
          ? const Center(child: Text('No notes yet. Add your first note above.',
              style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notes.length,
              itemBuilder: (_, i) {
                final n    = _notes[i];
                final text = n['note']?.toString()       ?? '';
                final time = _timeAgo(n['created_at']);
                final id   = n['_id']?.toString()        ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const CircleAvatar(
                      radius: 14, backgroundColor: Color(0xFFEEF2FF),
                      child: Icon(Icons.note_outlined,
                          color: Colors.indigo, size: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(text, style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(time, style: const TextStyle(
                          color: Colors.grey, fontSize: 11)),
                    ])),
                    GestureDetector(
                      onTap: () => _deleteNote(id),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.grey, size: 18),
                    ),
                  ]),
                );
              },
            ),
    ),
  ]);
}