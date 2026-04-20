import 'package:flutter/material.dart';
import '../../services/admin_api.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});
  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _api = AdminApi();
  bool _loading = true;
  List<Map<String, dynamic>> _users = [];
  String _search = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _api.getUsers();
      if (mounted) setState(() => _users = list);
    } catch (e) { debugPrint('users: $e'); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggle(String userId, bool currentlyDisabled) async {
    try {
      await _api.toggleUser(userId, !currentlyDisabled);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _users;
    final q = _search.toLowerCase();
    return _users.where((u) =>
      (u['user_name'] ?? '').toLowerCase().contains(q) ||
      (u['user_email'] ?? '').toLowerCase().contains(q)
    ).toList();
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
      title: const Text('Users', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
      actions: [
        IconButton(icon: const Icon(Icons.refresh, color: Colors.grey), onPressed: _load),
      ],
    ),
    body: Column(children: [
      // Search bar
      Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          onChanged: (v) => setState(() => _search = v),
          decoration: InputDecoration(
            hintText: 'Search users…',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      // Summary chips
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          _chip('Total: ${_users.length}', Colors.blue),
          const SizedBox(width: 8),
          _chip('Active: ${_users.where((u) => u['disabled'] != true).length}', Colors.green),
          const SizedBox(width: 8),
          _chip('Disabled: ${_users.where((u) => u['disabled'] == true).length}', Colors.red),
        ]),
      ),
      const SizedBox(height: 12),
      // List
      Expanded(
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _filtered.isEmpty
            ? const Center(child: Text('No users found', style: TextStyle(color: Colors.grey)))
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final u = _filtered[i];
                    final disabled = u['disabled'] == true;
                    final name = u['user_name']?.toString() ?? 'Unknown';
                    final email = u['user_email']?.toString() ?? '';
                    final gender = u['user_gender']?.toString() ?? '';
                    final joined = _timeAgo(u['created_at']);
                    final uid = u['user_id']?.toString() ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: disabled
                          ? Border.all(color: Colors.red.shade100)
                          : null,
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: disabled
                            ? Colors.grey.withOpacity(0.15)
                            : Colors.blue.withOpacity(0.1),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: disabled ? Colors.grey : Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(name,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                  overflow: TextOverflow.ellipsis),
                              ),
                              if (disabled)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8)),
                                  child: const Text('Disabled',
                                    style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w700)),
                                ),
                            ]),
                            Text(email,
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                              overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Row(children: [
                              if (gender.isNotEmpty) ...[
                                Icon(Icons.person_outline, size: 11, color: Colors.grey[400]),
                                const SizedBox(width: 2),
                                Text(gender, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                const SizedBox(width: 8),
                              ],
                              Icon(Icons.calendar_today_outlined, size: 11, color: Colors.grey[400]),
                              const SizedBox(width: 2),
                              Text('Joined $joined', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ]),
                          ],
                        )),
                        const SizedBox(width: 8),
                        // Enable / Disable toggle
                        GestureDetector(
                          onTap: () => _toggle(uid, disabled),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: disabled
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: disabled
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.red.withOpacity(0.2)),
                            ),
                            child: Text(
                              disabled ? 'Enable' : 'Disable',
                              style: TextStyle(
                                color: disabled ? Colors.green : Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ]),
                    );
                  },
                ),
              ),
      ),
    ]),
  );

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
  );
}