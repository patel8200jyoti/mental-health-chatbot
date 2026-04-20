import 'package:flutter/material.dart';
import '../../services/professional_api.dart';
import 'proff_dash.dart' show PatientDetailPage;

// ─────────────────────────────────────────────────────────────────────────────
// PATIENTS PAGE
// ─────────────────────────────────────────────────────────────────────────────

class ProfPatientsPage extends StatefulWidget {
  const ProfPatientsPage({super.key});
  @override
  State<ProfPatientsPage> createState() => _ProfPatientsPageState();
}

class _ProfPatientsPageState extends State<ProfPatientsPage>
    with SingleTickerProviderStateMixin {
  final _api = ProfessionalApi();
  late final TabController _tabs = TabController(length: 2, vsync: this);
  bool _loading = true;
  String _search = '';

  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _pending  = [];

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    await Future.wait([_loadPatients(), _loadPending()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadPatients() async {
    try {
      final list = await _api.getPatients();
      if (mounted) setState(() => _patients = list);
    } catch (e) { debugPrint('patients: $e'); }
  }

  Future<void> _loadPending() async {
    try {
      final list = await _api.getPendingRequests();
      if (mounted) setState(() => _pending = list);
    } catch (e) { debugPrint('pending: $e'); }
  }

  Future<void> _respond(String userId, bool accept) async {
    try {
      await _api.respondToRequest(userId, accept);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(accept ? '✓ Patient accepted' : 'Request declined'),
        backgroundColor: accept ? Colors.green : Colors.red));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _remove(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Patient'),
        content: const Text('Are you sure you want to unlink this patient?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.removePatient(userId);
      await _loadPatients();
    } catch (e) { debugPrint('remove: $e'); }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _patients;
    final q = _search.toLowerCase();
    return _patients.where((p) =>
      (p['user_name']  ?? '').toLowerCase().contains(q) ||
      (p['user_email'] ?? '').toLowerCase().contains(q)
    ).toList();
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
      final dt = DateTime.parse(raw.toString()).toLocal();
      final d = DateTime.now().difference(dt);
      if (d.inDays > 30) return '${(d.inDays / 30).floor()}mo ago';
      if (d.inDays > 0)  return '${d.inDays}d ago';
      return 'Today';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FC),
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text('Patients',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
      actions: [
        IconButton(icon: const Icon(Icons.refresh, color: Colors.grey), onPressed: _load),
      ],
      bottom: TabBar(
        controller: _tabs,
        labelColor: Colors.indigo,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.indigo,
        tabs: [
          Tab(text: 'Linked (${_patients.length})'),
          Tab(text: 'Pending (${_pending.length})'),
        ],
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(controller: _tabs, children: [
            _linkedTab(),
            _pendingTab(),
          ]),
  );

  Widget _linkedTab() => Column(children: [
    Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        decoration: InputDecoration(
          hintText: 'Search patients…',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
        ),
      ),
    ),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        _chip('Total: ${_patients.length}', Colors.indigo),
        const SizedBox(width: 8),
        _chip('Mood: ${_patients.where((p) => p["allow_mood"] == true).length}', Colors.teal),
        const SizedBox(width: 8),
        _chip('Journal: ${_patients.where((p) => p["allow_journal"] == true).length}', Colors.purple),
      ]),
    ),
    const SizedBox(height: 12),
    Expanded(
      child: _filtered.isEmpty
          ? const Center(child: Text('No linked patients yet',
              style: TextStyle(color: Colors.grey)))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final p = _filtered[i];
                  final name    = p['user_name']?.toString()  ?? 'Unknown';
                  final email   = p['user_email']?.toString() ?? '';
                  final uid     = p['user_id']?.toString()    ?? '';
                  final mood    = p['latest_mood']?.toString();
                  final allowM  = p['allow_mood'] == true;
                  final allowJ  = p['allow_journal'] == true;
                  final linked  = _timeAgo(p['linked_at']);

                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => PatientDetailPage(
                            userId: uid, userName: name))),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.indigo.withOpacity(0.1),
                          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                  color: Colors.indigo, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(name, style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                          Text(email, style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(children: [
                            if (allowM) ...[
                              _permChip('Mood', Colors.teal),
                              const SizedBox(width: 4),
                            ],
                            if (allowJ) _permChip('Journal', Colors.purple),
                            const Spacer(),
                            Text('Linked $linked',
                                style: const TextStyle(color: Colors.grey, fontSize: 10)),
                          ]),
                        ])),
                        const SizedBox(width: 8),
                        if (mood != null) Column(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                                color: _moodColor(mood).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(_capitalize(mood), style: TextStyle(
                                color: _moodColor(mood),
                                fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(height: 2),
                          const Text('mood', style: TextStyle(
                              color: Colors.grey, fontSize: 9)),
                        ]),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.grey, size: 18),
                          onSelected: (v) {
                            if (v == 'view') {
                              Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => PatientDetailPage(
                                      userId: uid, userName: name)));
                            } else if (v == 'remove') {
                              _remove(uid);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'view',
                                child: Row(children: [
                                  Icon(Icons.open_in_new, size: 16),
                                  SizedBox(width: 8),
                                  Text('View Details'),
                                ])),
                            const PopupMenuItem(value: 'remove',
                                child: Row(children: [
                                  Icon(Icons.person_remove_outlined,
                                      size: 16, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Remove', style: TextStyle(color: Colors.red)),
                                ])),
                          ],
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
    ),
  ]);

  Widget _pendingTab() => RefreshIndicator(
    onRefresh: _load,
    child: _pending.isEmpty
        ? const Center(child: Text('No pending requests 🎉',
            style: TextStyle(color: Colors.grey)))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _pending.length,
            itemBuilder: (_, i) {
              final p    = _pending[i];
              final name  = p['user_name']?.toString()  ?? 'Unknown';
              final email = p['user_email']?.toString() ?? '';
              final uid   = p['user_id']?.toString()    ?? '';
              final msg   = p['message']?.toString()    ?? '';
              final time  = _timeAgo(p['requested_at']);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                              color: Colors.orange, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(email, style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ])),
                    Text(time, style: const TextStyle(
                        color: Colors.grey, fontSize: 11)),
                  ]),
                  if (msg.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFFF9F0),
                          borderRadius: BorderRadius.circular(10)),
                      child: Text('"$msg"',
                          style: const TextStyle(
                              fontSize: 13, fontStyle: FontStyle.italic)),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: GestureDetector(
                      onTap: () => _respond(uid, false),
                      child: _actionBtn('Decline', Icons.close, Colors.red),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: GestureDetector(
                      onTap: () => _respond(uid, true),
                      child: _actionBtn('Accept', Icons.check, Colors.green),
                    )),
                  ]),
                ]),
              );
            },
          ),
  );

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
        color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
    child: Text(label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );

  Widget _permChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
        color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
  );

  Widget _actionBtn(String label, IconData icon, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(
          color: color, fontWeight: FontWeight.w600, fontSize: 13)),
    ]),
  );
}