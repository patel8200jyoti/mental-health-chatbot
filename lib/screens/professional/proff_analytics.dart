import 'package:flutter/material.dart';
import '../../services/professional_api.dart';


// ─────────────────────────────────────────────────────────────────────────────
// ANALYTICS PAGE (Mood distribution across all patients)
// ─────────────────────────────────────────────────────────────────────────────

class ProfAnalyticsPage extends StatefulWidget {
  const ProfAnalyticsPage({super.key});
  @override
  State<ProfAnalyticsPage> createState() => _ProfAnalyticsPageState();
}

class _ProfAnalyticsPageState extends State<ProfAnalyticsPage> {
  final _api = ProfessionalApi();
  bool _loading = true;

  int    _totalPatients  = 0;
  int    _openCrisis     = 0;
  int    _streakCount    = 0;
  int    _totalJournals  = 0;

  // Aggregated mood distribution across all patients
  final Map<String, int> _moodCounts = {};
  int _totalMoods = 0;

  List<Map<String, dynamic>> _patients = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats    = await _api.getDashboardStats();
      final patients = await _api.getPatients();

      if (!mounted) return;

      // Aggregate mood distribution from all patients with mood permission
      final counts = <String, int>{};
      int total = 0;
      for (final p in patients) {
        if (p['allow_mood'] != true) continue;
        try {
          final moods = await _api.getPatientMoods(p['user_id'].toString());
          for (final m in moods) {
            final mood = (m['mood'] ?? '').toString().toLowerCase();
            if (mood.isNotEmpty) {
              counts[mood] = (counts[mood] ?? 0) + 1;
              total++;
            }
          }
        } catch (_) {}
      }

      setState(() {
        _totalPatients = (stats['total_patients'] as num?)?.toInt() ?? 0;
        _openCrisis    = (stats['open_crisis']    as num?)?.toInt() ?? 0;
        _streakCount   = (stats['streak_count']   as num?)?.toInt() ?? 0;
        _totalJournals = (stats['total_journals'] as num?)?.toInt() ?? 0;
        _patients      = patients;
        _moodCounts.clear();
        _moodCounts.addAll(counts);
        _totalMoods = total;
      });
    } catch (e) { debugPrint('analytics: $e'); }
    if (mounted) setState(() => _loading = false);
  }

  Color _moodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'great': return const Color(0xFF00C853);
      case 'happy': return const Color(0xFF69F0AE);
      case 'calm':  return const Color(0xFFFFD740);
      case 'okay':  return const Color(0xFFFF6D00);
      case 'sad':   return const Color(0xFFD50000);
      default:      return Colors.grey;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FC),
    appBar: AppBar(
      backgroundColor: Colors.white, elevation: 0,
      title: const Text('Analytics',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
      actions: [
        IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey), onPressed: _load),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Summary cards
                Row(children: [
                  Expanded(child: _SummaryCard(
                    label: 'Total Patients', value: _totalPatients.toString(),
                    icon: Icons.people_alt_outlined, color: Colors.indigo,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _SummaryCard(
                    label: 'Open Crisis', value: _openCrisis.toString(),
                    icon: Icons.warning_amber_rounded,
                    color: _openCrisis > 0 ? Colors.red : Colors.green,
                  )),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _SummaryCard(
                    label: 'Mood Streaks', value: _streakCount.toString(),
                    icon: Icons.local_fire_department, color: Colors.orange,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _SummaryCard(
                    label: 'Shared Journals', value: _totalJournals.toString(),
                    icon: Icons.menu_book, color: Colors.purple,
                  )),
                ]),

                const SizedBox(height: 24),

                // Mood distribution
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Patient Mood Distribution',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Aggregated from $_totalMoods mood logs across all patients',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 20),
                    if (_totalMoods == 0)
                      const Center(child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No mood data with permission yet',
                            style: TextStyle(color: Colors.grey)),
                      ))
                    else
                      ...['great', 'happy', 'calm', 'okay', 'sad']
                          .where((k) => _moodCounts.containsKey(k))
                          .map((mood) {
                        final count = _moodCounts[mood] ?? 0;
                        final pct   = _totalMoods > 0 ? count / _totalMoods : 0.0;
                        final color = _moodColor(mood);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Row(children: [
                              Container(width: 10, height: 10,
                                  decoration: BoxDecoration(
                                      color: color, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text(_capitalize(mood),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 14)),
                              const Spacer(),
                              Text('$count logs  •  ${(pct * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 11)),
                            ]),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: pct,
                                backgroundColor: color.withOpacity(0.12),
                                valueColor: AlwaysStoppedAnimation(color),
                                minHeight: 10,
                              ),
                            ),
                          ]),
                        );
                      }),
                  ]),
                ),

                const SizedBox(height: 24),

                // Per-patient permission summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Patient Data Permissions',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('What each patient has shared with you',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 16),
                    if (_patients.isEmpty)
                      const Center(child: Text('No patients linked',
                          style: TextStyle(color: Colors.grey)))
                    else
                      ..._patients.map((p) {
                        final name   = p['user_name']?.toString() ?? 'Unknown';
                        final allowM = p['allow_mood'] == true;
                        final allowJ = p['allow_journal'] == true;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.indigo.withOpacity(0.1),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                    color: Colors.indigo,
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(name,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w500))),
                            _permBadge('Mood', allowM, Colors.teal),
                            const SizedBox(width: 6),
                            _permBadge('Journal', allowJ, Colors.purple),
                          ]),
                        );
                      }),
                  ]),
                ),

                const SizedBox(height: 24),
              ]),
            ),
          ),
  );

  Widget _permBadge(String label, bool allowed, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: allowed ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(
        color: allowed ? color : Colors.grey[400],
        fontSize: 10, fontWeight: FontWeight.w600)),
  );
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SummaryCard({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ])),
    ]),
  );
}