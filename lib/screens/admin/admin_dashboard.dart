import 'package:flutter/material.dart';
import '../../services/admin_api.dart';
import 'proff_verification.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _loading = true;

  int _totalUsers         = 0;
  int _totalProfessionals = 0;
  int _totalJournals      = 0;
  int _pendingApprovals   = 0;
  int _activeMoodStreak   = 0;
  int _activeChats        = 0;
  int _totalMessages      = 0;

  // Mood distribution
  List<Map<String, dynamic>> _moodDistribution = [];
  double _moodOverallAvg = 0;
  int    _moodTotalLogs  = 0;
  String _moodMostCommon = '';

  List<Map<String, dynamic>> _crisisAlerts         = [];
  List<Map<String, dynamic>> _pendingProfessionals = [];

  final _api = AdminApi();

  @override
  void initState() { super.initState(); _loadAll(); }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait([
      _loadSystemStats(),
      _loadDashboardMetrics(),
      _loadMoodData(),
      _loadCrisisAlerts(),
      _loadPendingProfessionals(),
    ]);
    setState(() => _loading = false);
  }

  Future<void> _loadSystemStats() async {
    try {
      final s = await _api.getStats();
      setState(() {
        _totalUsers         = (s["total_users"]         as num?)?.toInt() ?? 0;
        _totalProfessionals = (s["total_professionals"] as num?)?.toInt() ?? 0;
        _pendingApprovals   = (s["pending_approvals"]   as num?)?.toInt() ?? 0;
        _totalJournals      = (s["total_journals"]      as num?)?.toInt() ?? 0;
      });
    } catch (e) { debugPrint("getStats: $e"); }
  }

  Future<void> _loadDashboardMetrics() async {
    try {
      final s = await _api.getDashboardStats();
      setState(() {
        _activeMoodStreak = (s["active_streak_count"] as num?)?.toInt() ?? 0;
        _activeChats      = (s["active_chats"]        as num?)?.toInt() ?? 0;
        _totalMessages    = (s["total_messages"]      as num?)?.toInt() ?? 0;
        if (s["total_journals"] != null)
          _totalJournals  = (s["total_journals"] as num).toInt();
      });
    } catch (e) { debugPrint("getDashboardStats: $e"); }
  }

  Future<void> _loadMoodData() async {
    try {
      final s = await _api.getMoodSummary();
      setState(() {
        _moodOverallAvg  = (s["overall_avg_mood"]  as num?)?.toDouble() ?? 0;
        _moodTotalLogs   = (s["total_logs"]         as num?)?.toInt()   ?? 0;
        _moodMostCommon  = s["most_common_mood"]?.toString() ?? '';
        _moodDistribution = List<Map<String, dynamic>>.from(s["distribution"] ?? []);
      });
    } catch (e) { debugPrint("getMoodSummary: $e"); }
  }

  Future<void> _loadCrisisAlerts() async {
    try {
      final alerts = await _api.getCrisisAlerts(resolved: false, limit: 3);
      setState(() => _crisisAlerts = alerts);
    } catch (e) { debugPrint("getCrisisAlerts: $e"); }
  }

  Future<void> _loadPendingProfessionals() async {
    try {
      final all = await _api.getAdminProfessionals();
      setState(() {
        _pendingProfessionals = all
            .where((p) => p["is_approved"] == false && p["disabled"] != true)
            .toList();
        _pendingApprovals = _pendingProfessionals.length;
      });
    } catch (e) { debugPrint("getPendingProfessionals: $e"); }
  }

  Future<void> _approveProfessional(String id, bool approve) async {
    try {
      await _api.approveProfessional(id, approve);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(approve ? '✓ Professional approved' : 'Professional rejected'),
        backgroundColor: approve ? Colors.green : Colors.red,
      ));
      await _loadPendingProfessionals();
      await _loadSystemStats();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _openVerificationPage(Map<String, dynamic> prof) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => DoctorVerificationPage(
        doctor: prof,
        onStatusChanged: () async {
          await _loadPendingProfessionals();
          await _loadSystemStats();
        },
      ),
    ));
  }

  Future<void> _resolveAlert(String alertId) async {
    try {
      await _api.resolveAlert(alertId);
      await _loadCrisisAlerts();
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

  Color _moodLabelColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'great': return const Color(0xFF00C853);
      case 'happy': return const Color(0xFF69F0AE);
      case 'calm':  return const Color(0xFFFFD740);
      case 'okay':  return const Color(0xFFFF6D00);
      case 'sad':   return const Color(0xFFD50000);
      default:      return Colors.grey;
    }
  }

  Color _moodAvgColor(double avg) {
    if (avg >= 4.5) return const Color(0xFF00C853);
    if (avg >= 3.5) return const Color(0xFF69F0AE);
    if (avg >= 2.5) return const Color.fromARGB(255, 149, 118, 6);
    if (avg >= 1.5) return const Color(0xFFFF6D00);
    return const Color(0xFFD50000);
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────
  Widget _header() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('System Overview',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text('ADMIN CONTROL PANEL',
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

  // ── TOP METRICS ─────────────────────────────────────────────────────────────
  Widget _topMetrics() => Row(children: [
    Expanded(child: _metricCard(
      title: 'Total Users', value: _totalUsers.toString(),
      badge: '$_pendingApprovals pending', icon: Icons.people_alt_outlined,
      color: const Color(0xFFEFF4FF),
      badgeColor: _pendingApprovals > 0 ? Colors.orange.withOpacity(0.15) : Colors.white,
      badgeTextColor: _pendingApprovals > 0 ? Colors.orange : Colors.grey,
    )),
    const SizedBox(width: 12),
    Expanded(child: _metricCard(
      title: 'Professionals', value: _totalProfessionals.toString(),
      badge: 'Verified', icon: Icons.verified_user_outlined,
      color: const Color(0xFFEFF4FF),
      badgeColor: Colors.white, badgeTextColor: Colors.grey,
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
        Icon(icon, color: Colors.blue),
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
      Text(title, style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    ]),
  );


  // ── PROFESSIONAL APPROVALS ─────────────────────────────────────────────────
  Widget _professionalApprovals() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F7FF),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: _pendingProfessionals.isNotEmpty
            ? Colors.blue.withOpacity(0.3) : Colors.transparent,
        width: 1.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.badge_outlined, color: Colors.blue, size: 22),
        const SizedBox(width: 10),
        const Expanded(child: Text('Professional Approvals',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
        if (_pendingProfessionals.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Text('${_pendingProfessionals.length} pending',
                style: const TextStyle(
                    color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _openApprovalsModal,
            child: const Text('VIEW ALL',
                style: TextStyle(color: Colors.blue, fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ]),
      const SizedBox(height: 4),
      const Text('Review and approve new professional registrations',
          style: TextStyle(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 14),
      if (_pendingProfessionals.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: Text('No pending approvals 🎉',
              style: TextStyle(color: Colors.grey))),
        )
      else
        ..._pendingProfessionals.take(2).map((p) => _professionalCard(p)),
    ]),
  );

  Widget _professionalCard(Map<String, dynamic> prof) {
    final name  = prof["user_name"]?.toString()  ?? 'Unknown';
    final email = prof["user_email"]?.toString() ?? '';
    final role  = prof["professional_role"]?.toString()
               ?? prof["specialty"]?.toString() ?? 'Professional';
    final id    = prof["_id"]?.toString()
               ?? prof["user_id"]?.toString() ?? '';
    final regNo = prof["medical_registration_number"]?.toString() ?? '';
    final date  = _timeAgo(prof["created_at"]);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            Text(email, style: const TextStyle(color: Colors.grey, fontSize: 12),
                overflow: TextOverflow.ellipsis),
            if (regNo.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.badge_outlined, size: 11, color: Colors.grey),
                const SizedBox(width: 3),
                Text('Reg: $regNo',
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ]),
            ],
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(role, style: const TextStyle(
                  color: Colors.indigo, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 4),
            Text(date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(flex: 2, child: GestureDetector(
            onTap: () => _openVerificationPage(prof),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withOpacity(0.25)),
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.open_in_new, size: 14, color: Colors.blue),
                SizedBox(width: 5),
                Text('View Details', style: TextStyle(
                    color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ),
          )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _approveProfessional(id, false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.red),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _approveProfessional(id, true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.withOpacity(0.25)),
              ),
              child: const Icon(Icons.check, size: 16, color: Colors.green),
            ),
          ),
        ]),
      ]),
    );
  }

  void _openApprovalsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ApprovalsModal(
        api: _api,
        onChanged: () async {
          await _loadPendingProfessionals();
          await _loadSystemStats();
        },
        onViewDetails: _openVerificationPage,
      ),
    );
  }

  // ── MOOD DISTRIBUTION ──────────────────────────────────────────────────────
  Widget _moodAnalytics() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFEFFAF5),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('User Mood Trends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Based on $_moodTotalLogs total logs',
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ])),
        if (_moodOverallAvg > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _moodAvgColor(_moodOverallAvg).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.trending_up, size: 14, color: _moodAvgColor(_moodOverallAvg)),
              const SizedBox(width: 4),
              Text('Avg ${_moodOverallAvg.toStringAsFixed(1)}/5',
                  style: TextStyle(
                      color: _moodAvgColor(_moodOverallAvg),
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          ),
        ],
      ]),

      if (_moodMostCommon.isNotEmpty) ...[
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.emoji_emotions_outlined, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text('Most common: ${_capitalize(_moodMostCommon)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
      ],

      const SizedBox(height: 20),

      if (_moodDistribution.isEmpty)
        const Center(child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text('No mood data yet', style: TextStyle(color: Colors.grey)),
        ))
      else
        ..._moodDistribution.map((d) {
          final mood  = d['mood']?.toString()       ?? '';
          final pct   = (d['pct']       as num?)?.toDouble() ?? 0;
          final count = (d['count']     as num?)?.toInt()    ?? 0;
          final avg   = (d['avg_score'] as num?)?.toDouble() ?? 0;
          final color = _moodLabelColor(mood);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(_capitalize(mood),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const Spacer(),
                Text('$count  •  avg ${avg.toStringAsFixed(1)}  •  ${pct.toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  backgroundColor: color.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 10,
                ),
              ),
            ]),
          );
        }),
    ]),
  );

  // ── CRISIS / EMERGENCY LOG ─────────────────────────────────────────────────
  Widget _emergencyLog() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: const Color(0xFFFFF4EC), borderRadius: BorderRadius.circular(20)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Text('Crisis Detected on Platform',
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
          onTap: _openEmergencyModal,
          child: const Text('VIEW ALL',
              style: TextStyle(color: Colors.orange, fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 4),
      const Text('Users who triggered a mental health crisis alert',
          style: TextStyle(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 14),
      if (_crisisAlerts.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: Text('No open crisis alerts 🎉',
              style: TextStyle(color: Colors.grey))),
        )
      else
        ..._crisisAlerts.map((a) => _crisisItem(a)),
    ]),
  );

  Widget _crisisItem(Map<String, dynamic> alert) {
    final name    = alert["user_name"]?.toString()  ?? 'Unknown User';
    final email   = alert["user_email"]?.toString() ?? '';
    final message = alert["message"]?.toString();
    final time    = _timeAgo(alert["created_at"]);
    final id      = alert["_id"]?.toString();
    final msgLow  = (message ?? '').toLowerCase();
    final isHigh  = msgLow.contains('suicid') || msgLow.contains('self-harm') ||
                    msgLow.contains('hurt')   || msgLow.contains('die');
    final sc = isHigh ? Colors.red : Colors.orange;
    final sl = isHigh ? 'HIGH RISK' : 'ALERT';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sc.withOpacity(0.25), width: 1)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 18, backgroundColor: sc.withOpacity(0.12),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(color: sc, fontWeight: FontWeight.bold))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            if (email.isNotEmpty)
              Text(email, style: const TextStyle(color: Colors.grey, fontSize: 11),
                  overflow: TextOverflow.ellipsis),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                  color: sc.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Text(sl, style: TextStyle(
                  color: sc, fontSize: 10, fontWeight: FontWeight.w800,
                  letterSpacing: 0.5)),
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
                  border: Border.all(color: sc.withOpacity(0.3), width: 1)),
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

  void _openEmergencyModal() => showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _EmergencyLogModal(api: _api, onResolved: _loadCrisisAlerts),
  );

  // ── BOTTOM STATS ───────────────────────────────────────────────────────────
  Widget _bottomStats() => Column(children: [
    Row(children: [
      Expanded(child: _StatCard(label: 'ACTIVE MOOD STREAK', value: _activeMoodStreak.toString())),
      const SizedBox(width: 12),
      Expanded(child: _StatCard(label: 'TOTAL JOURNALS', value: _totalJournals.toString())),
    ]),
    const SizedBox(height: 12),
    Row(children: [
      Expanded(child: _StatCard(label: 'ACTIVE CHATS', value: _activeChats.toString())),
      const SizedBox(width: 12),
      Expanded(child: _StatCard(label: 'TOTAL MESSAGES', value: _totalMessages.toString())),
    ]),
  ]);

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
                  _professionalApprovals(),
                  const SizedBox(height: 20),
                  _moodAnalytics(),
                  const SizedBox(height: 20),
                  _emergencyLog(),
                  const SizedBox(height: 20),
                  _bottomStats(),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
    ),
  );
}

// ─── Approvals Modal ─────────────────────────────────────────────────────────

class _ApprovalsModal extends StatefulWidget {
  final AdminApi api;
  final VoidCallback onChanged;
  final void Function(Map<String, dynamic>) onViewDetails;

  const _ApprovalsModal({
    required this.api,
    required this.onChanged,
    required this.onViewDetails,
  });

  @override
  State<_ApprovalsModal> createState() => _ApprovalsModalState();
}

class _ApprovalsModalState extends State<_ApprovalsModal> {
  bool _loading     = true;
  bool _showApproved = false;
  List<Map<String, dynamic>> _list = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final all = await widget.api.getAdminProfessionals();
      setState(() {
        _list = _showApproved
            ? all.where((p) => p["is_approved"] == true).toList()
            : all.where((p) =>
                p["is_approved"] == false && p["disabled"] != true).toList();
      });
    } catch (e) { debugPrint("approvals modal: $e"); }
    setState(() => _loading = false);
  }

  Future<void> _act(String id, bool approve) async {
    try {
      await widget.api.approveProfessional(id, approve);
      widget.onChanged();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(approve ? '✓ Approved' : 'Rejected'),
        backgroundColor: approve ? Colors.green : Colors.red));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false, initialChildSize: 0.8, maxChildSize: 0.95,
    builder: (_, ctrl) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(
          margin: const EdgeInsets.only(top: 12, bottom: 16),
          width: 40, height: 4,
          decoration: BoxDecoration(
              color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
        )),
        Row(children: [
          const Text('Professional Requests',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          GestureDetector(
            onTap: () { setState(() => _showApproved = !_showApproved); _load(); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _showApproved
                    ? Colors.green.withOpacity(0.12)
                    : Colors.blue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12)),
              child: Text(
                _showApproved ? '✓ Approved' : '⏳ Pending',
                style: TextStyle(
                    color: _showApproved ? Colors.green : Colors.blue,
                    fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _list.isEmpty
                  ? Center(child: Text(
                      _showApproved ? 'No approved professionals yet.' : 'No pending requests 🎉',
                      style: const TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      controller: ctrl,
                      itemCount: _list.length,
                      itemBuilder: (_, i) {
                        final p        = _list[i];
                        final id       = p["_id"]?.toString() ?? p["user_id"]?.toString() ?? '';
                        final name     = p["user_name"]?.toString()  ?? 'Unknown';
                        final email    = p["user_email"]?.toString() ?? '';
                        final role     = p["professional_role"]?.toString()
                                      ?? p["specialty"]?.toString() ?? 'Professional';
                        final regNo    = p["medical_registration_number"]?.toString() ?? '';
                        final approved = p["is_approved"] == true;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.blue.withOpacity(0.1))),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.blue.withOpacity(0.1),
                                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                        color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                Text(email, style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    overflow: TextOverflow.ellipsis),
                                if (regNo.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text('Reg: $regNo',
                                      style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                ],
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6)),
                                  child: Text(role, style: const TextStyle(
                                      color: Colors.indigo, fontSize: 10, fontWeight: FontWeight.w600)),
                                ),
                              ])),
                              if (approved)
                                const Icon(Icons.verified, color: Colors.green, size: 22),
                            ]),
                            if (!approved) ...[
                              const SizedBox(height: 12),
                              Row(children: [
                                Expanded(flex: 2, child: GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    widget.onViewDetails(p);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.07),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.blue.withOpacity(0.2))),
                                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                      Icon(Icons.open_in_new, size: 13, color: Colors.blue),
                                      SizedBox(width: 4),
                                      Text('Details', style: TextStyle(
                                          color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 12)),
                                    ]),
                                  ),
                                )),
                                const SizedBox(width: 8),
                                Expanded(child: GestureDetector(
                                  onTap: () => _act(id, false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.red.withOpacity(0.2))),
                                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                      Icon(Icons.close, size: 14, color: Colors.red),
                                      SizedBox(width: 3),
                                      Text('Reject', style: TextStyle(
                                          color: Colors.red, fontWeight: FontWeight.w600, fontSize: 12)),
                                    ]),
                                  ),
                                )),
                                const SizedBox(width: 8),
                                Expanded(child: GestureDetector(
                                  onTap: () => _act(id, true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.green.withOpacity(0.25))),
                                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                      Icon(Icons.check, size: 14, color: Colors.green),
                                      SizedBox(width: 3),
                                      Text('Approve', style: TextStyle(
                                          color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12)),
                                    ]),
                                  ),
                                )),
                              ]),
                            ],
                          ]),
                        );
                      },
                    ),
        ),
      ]),
    ),
  );
}

// ─── Emergency Log Modal ──────────────────────────────────────────────────────

class _EmergencyLogModal extends StatefulWidget {
  final AdminApi api;
  final VoidCallback onResolved;
  const _EmergencyLogModal({required this.api, required this.onResolved});

  @override
  State<_EmergencyLogModal> createState() => _EmergencyLogModalState();
}

class _EmergencyLogModalState extends State<_EmergencyLogModal> {
  bool _showResolved = false;
  bool _loading      = true;
  List<Map<String, dynamic>> _alerts = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await widget.api.getCrisisAlerts(resolved: _showResolved, limit: 50);
      setState(() => _alerts = data);
    } catch (e) { debugPrint("modal load: $e"); }
    setState(() => _loading = false);
  }

  Future<void> _resolve(String id) async {
    try {
      await widget.api.resolveAlert(id);
      widget.onResolved();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  String _ago(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt   = DateTime.parse(raw.toString()).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours   < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false, initialChildSize: 0.75, maxChildSize: 0.95,
    builder: (_, ctrl) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(
          margin: const EdgeInsets.only(top: 12, bottom: 16),
          width: 40, height: 4,
          decoration: BoxDecoration(
              color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
        )),
        Row(children: [
          const Text('Emergency Log',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          GestureDetector(
            onTap: () { setState(() => _showResolved = !_showResolved); _load(); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _showResolved
                    ? Colors.green.withOpacity(0.15)
                    : Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12)),
              child: Text(
                _showResolved ? '✓ Resolved' : '⚠ Open',
                style: TextStyle(
                    color: _showResolved ? Colors.green : Colors.orange,
                    fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _alerts.isEmpty
                  ? Center(child: Text(
                      _showResolved ? 'No resolved alerts.' : 'No open alerts 🎉',
                      style: const TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      controller: ctrl,
                      itemCount: _alerts.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final a        = _alerts[i];
                        final id       = a["_id"]?.toString();
                        final resolved = a["resolved"] == true;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFFFF4EC),
                            child: Icon(
                              resolved ? Icons.check_circle : Icons.warning_amber_rounded,
                              color: resolved ? Colors.green : Colors.orange)),
                          title: Text(a["user_name"]?.toString() ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(a["message"]?.toString() ?? 'Crisis alert',
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(a["user_email"]?.toString() ?? '',
                                style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ]),
                          isThreeLine: true,
                          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(_ago(a["created_at"]),
                                style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            if (!resolved && id != null) ...[
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => _resolve(id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8)),
                                  child: const Text('Resolve', style: TextStyle(
                                      color: Colors.orange, fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ]),
                        );
                      },
                    ),
        ),
      ]),
    ),
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