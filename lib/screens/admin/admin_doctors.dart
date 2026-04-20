import 'package:flutter/material.dart';
import '../../services/admin_api.dart';
import 'proff_verification.dart';

class AdminDoctorsPage extends StatefulWidget {
  const AdminDoctorsPage({super.key});
  @override
  State<AdminDoctorsPage> createState() => _AdminDoctorsPageState();
}

class _AdminDoctorsPageState extends State<AdminDoctorsPage>
    with SingleTickerProviderStateMixin {
  final _api = AdminApi();
  late final TabController _tabs = TabController(length: 2, vsync: this);
  bool _loading = true;
  List<Map<String, dynamic>> _all = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _api.getAdminProfessionals();
      if (mounted) setState(() => _all = list);
    } catch (e) { debugPrint('doctors: $e'); }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _pending =>
    _all.where((p) => p['is_approved'] != true && p['disabled'] != true).toList();
  List<Map<String, dynamic>> get _approved =>
    _all.where((p) => p['is_approved'] == true).toList();

  Future<void> _act(String id, bool approve) async {
    try {
      await _api.approveProfessional(id, approve);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(approve ? '✓ Doctor approved' : 'Doctor rejected'),
        backgroundColor: approve ? Colors.green : Colors.red,
      ));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _openDetails(Map<String, dynamic> prof) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => DoctorVerificationPage(
        doctor: prof,
        onStatusChanged: _load,
      ),
    ));
  }

  String _timeAgo(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      final d = DateTime.now().difference(dt);
      if (d.inDays > 30) return '${(d.inDays / 30).floor()}mo ago';
      if (d.inDays > 0) return '${d.inDays}d ago';
      return 'Today';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FC),
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text('Doctors', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
      actions: [
        IconButton(icon: const Icon(Icons.refresh, color: Colors.grey), onPressed: _load),
      ],
      bottom: TabBar(
        controller: _tabs,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.blue,
        tabs: [
          Tab(text: 'Pending (${_pending.length})'),
          Tab(text: 'Approved (${_approved.length})'),
        ],
      ),
    ),
    body: _loading
      ? const Center(child: CircularProgressIndicator())
      : TabBarView(
          controller: _tabs,
          children: [
            _DocList(
              docs: _pending,
              onRefresh: _load,
              onAct: _act,
              onDetails: _openDetails,
              timeAgo: _timeAgo,
              isPending: true,
            ),
            _DocList(
              docs: _approved,
              onRefresh: _load,
              onAct: _act,
              onDetails: _openDetails,
              timeAgo: _timeAgo,
              isPending: false,
            ),
          ],
        ),
  );
}

class _DocList extends StatelessWidget {
  final List<Map<String, dynamic>> docs;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String, bool) onAct;
  final void Function(Map<String, dynamic>) onDetails;
  final String Function(dynamic) timeAgo;
  final bool isPending;

  const _DocList({
    required this.docs, required this.onRefresh, required this.onAct,
    required this.onDetails, required this.timeAgo, required this.isPending,
  });

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) return Center(
      child: Text(isPending ? 'No pending doctors 🎉' : 'No approved doctors yet',
        style: const TextStyle(color: Colors.grey)),
    );

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: docs.length,
        itemBuilder: (_, i) {
          final p = docs[i];
          final id    = p['user_id']?.toString() ?? p['_id']?.toString() ?? '';
          final name  = p['user_name']?.toString() ?? 'Unknown';
          final email = p['user_email']?.toString() ?? '';
          final role  = p['professional_role']?.toString() ?? p['specialty']?.toString() ?? 'Professional';
          final regNo = p['medical_registration_number']?.toString() ?? '';
          final date  = timeAgo(p['created_at']);
          final approved = p['is_approved'] == true;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isPending ? Border.all(color: Colors.blue.withOpacity(0.15)) : null,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: approved
                    ? Colors.green.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: approved ? Colors.green : Colors.blue,
                      fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(email, style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis),
                  if (regNo.isNotEmpty) Row(children: [
                    const Icon(Icons.badge_outlined, size: 11, color: Colors.grey),
                    const SizedBox(width: 3),
                    Text('Reg: $regNo', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ]),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                    child: Text(role, style: const TextStyle(color: Colors.indigo, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 4),
                  if (approved)
                    const Icon(Icons.verified, color: Colors.green, size: 18)
                  else
                    Text(date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ]),
              ]),
              if (isPending) ...[
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () => onDetails(p),
                      child: _actionBtn('View Details', Icons.open_in_new, Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => onAct(id, false),
                    child: _iconBtn(Icons.close, Colors.red),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => onAct(id, true),
                    child: _iconBtn(Icons.check, Colors.green),
                  ),
                ]),
              ] else ...[
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onDetails(p),
                      child: _actionBtn('View Profile', Icons.open_in_new, Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onAct(id, false),
                      child: _actionBtn('Revoke', Icons.remove_circle_outline, Colors.red),
                    ),
                  ),
                ]),
              ],
            ]),
          );
        },
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 9),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    ]),
  );

  Widget _iconBtn(IconData icon, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Icon(icon, size: 16, color: color),
  );
}