import 'package:flutter/material.dart';
import '../../services/professional_api.dart';
import 'proff_dash.dart' show PatientDetailPage;


// ─────────────────────────────────────────────────────────────────────────────
// CRISIS PAGE
// ─────────────────────────────────────────────────────────────────────────────

class ProfCrisisPage extends StatefulWidget {
  const ProfCrisisPage({super.key});
  @override
  State<ProfCrisisPage> createState() => _ProfCrisisPageState();
}

class _ProfCrisisPageState extends State<ProfCrisisPage> {
  final _api = ProfessionalApi();
  bool _loading      = true;
  bool _showResolved = false;
  List<Map<String, dynamic>> _alerts = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _api.getCrisisAlerts(resolved: _showResolved);
      if (mounted) setState(() => _alerts = list);
    } catch (e) { debugPrint('crisis: $e'); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _resolve(String id) async {
    try {
      await _api.resolveAlert(id);
      await _load();
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

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FC),
    appBar: AppBar(
      backgroundColor: Colors.white, elevation: 0,
      title: const Text('Crisis Alerts',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
      actions: [
        GestureDetector(
          onTap: () { setState(() => _showResolved = !_showResolved); _load(); },
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _showResolved
                  ? Colors.green.withOpacity(0.12)
                  : Colors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _showResolved ? '✓ Resolved' : '⚠ Open',
              style: TextStyle(
                  color: _showResolved ? Colors.green : Colors.orange,
                  fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey), onPressed: _load),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: _alerts.isEmpty
                ? Center(child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(_showResolved ? Icons.check_circle_outline
                          : Icons.shield_outlined,
                          size: 56, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(_showResolved ? 'No resolved alerts yet'
                          : 'No open crisis alerts 🎉',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 16)),
                    ]),
                  ))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _alerts.length,
                    itemBuilder: (_, i) {
                      final a       = _alerts[i];
                      final id      = a['_id']?.toString();
                      final name    = a['user_name']?.toString()  ?? 'Unknown';
                      final email   = a['user_email']?.toString() ?? '';
                      final message = a['message']?.toString();
                      final time    = _timeAgo(a['created_at']);
                      final resolved = a['resolved'] == true;
                      final msgLow  = (message ?? '').toLowerCase();
                      final isHigh  = msgLow.contains('suicid') ||
                          msgLow.contains('self-harm') ||
                          msgLow.contains('hurt') || msgLow.contains('die');
                      final sc = isHigh ? Colors.red : Colors.orange;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: resolved
                                  ? Colors.grey.withOpacity(0.15)
                                  : sc.withOpacity(0.3)),
                          boxShadow: [BoxShadow(
                              color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                        ),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: sc.withOpacity(0.12),
                              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                      color: sc, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(name, style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                              Text(email, style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                                  overflow: TextOverflow.ellipsis),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: resolved
                                        ? Colors.green.withOpacity(0.1)
                                        : sc.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  resolved ? 'RESOLVED'
                                      : isHigh ? 'HIGH RISK' : 'ALERT',
                                  style: TextStyle(
                                      color: resolved ? Colors.green : sc,
                                      fontSize: 10, fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(time, style: const TextStyle(
                                  color: Colors.grey, fontSize: 11)),
                            ]),
                          ]),
                          if (message != null && message.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFFFF9F5),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Row(children: [
                                Icon(Icons.chat_bubble_outline,
                                    size: 13, color: Colors.grey[400]),
                                const SizedBox(width: 8),
                                Expanded(child: Text('"$message"',
                                    style: const TextStyle(
                                        fontSize: 13, fontStyle: FontStyle.italic,
                                        color: Colors.black87),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis)),
                              ]),
                            ),
                          ],
                          if (!resolved && id != null) ...[
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(child: GestureDetector(
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) =>
                                        PatientDetailPage(
                                            userId: a['user_id'] ?? '',
                                            userName: name))),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.indigo.withOpacity(0.2)),
                                  ),
                                  child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                    Icon(Icons.person_outline,
                                        size: 14, color: Colors.indigo),
                                    SizedBox(width: 5),
                                    Text('View Patient', style: TextStyle(
                                        color: Colors.indigo,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                  ]),
                                ),
                              )),
                              const SizedBox(width: 8),
                              Expanded(child: GestureDetector(
                                onTap: () => _resolve(id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.green.withOpacity(0.25)),
                                  ),
                                  child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                    Icon(Icons.check, size: 14, color: Colors.green),
                                    SizedBox(width: 5),
                                    Text('Resolve', style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
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
  );
}