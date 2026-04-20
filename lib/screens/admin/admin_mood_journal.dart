import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/admin_api.dart';

class AdminMoodJournalPage extends StatefulWidget {
  const AdminMoodJournalPage({super.key});
  @override
  State<AdminMoodJournalPage> createState() => _AdminMoodJournalPageState();
}

class _AdminMoodJournalPageState extends State<AdminMoodJournalPage>
    with SingleTickerProviderStateMixin {
  final _api = AdminApi();
  late final TabController _tabCtrl = TabController(length: 2, vsync: this);

  bool _loading = true;

  double _overallAvg  = 0;
  int    _totalLogs   = 0;
  int    _usersToday  = 0;
  String _mostCommon  = '';
  List<Map<String, dynamic>> _distribution = [];

  int    _totalJournals = 0;
  double _avgSentiment  = 0;
  int    _positiveCount = 0;
  int    _neutralCount  = 0;
  int    _negativeCount = 0;
  List<Map<String, dynamic>> _journalTrend = [];
  List<Map<String, dynamic>> _topMoods     = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    await Future.wait([_loadMoodSummary(), _loadJournalStats()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadMoodSummary() async {
    try {
      final s = await _api.getMoodSummary();
      if (mounted) setState(() {
        _overallAvg   = (s['overall_avg_mood']  as num?)?.toDouble() ?? 0;
        _totalLogs    = (s['total_logs']         as num?)?.toInt()   ?? 0;
        _usersToday   = (s['users_logged_today'] as num?)?.toInt()   ?? 0;
        _mostCommon   = s['most_common_mood']?.toString() ?? '';
        _distribution = List<Map<String, dynamic>>.from(s['distribution'] ?? []);
      });
    } catch (e) { debugPrint('mood summary: $e'); }
  }

  Future<void> _loadJournalStats() async {
    try {
      final s = await _api.getJournalStats();
      if (mounted) setState(() {
        _totalJournals = (s['total_journals'] as num?)?.toInt()    ?? 0;
        _avgSentiment  = (s['avg_sentiment']  as num?)?.toDouble() ?? 0;
        _positiveCount = (s['positive_count'] as num?)?.toInt()    ?? 0;
        _neutralCount  = (s['neutral_count']  as num?)?.toInt()    ?? 0;
        _negativeCount = (s['negative_count'] as num?)?.toInt()    ?? 0;
        _journalTrend  = List<Map<String, dynamic>>.from(s['trend_last_30']      ?? []);
        _topMoods      = List<Map<String, dynamic>>.from(s['top_moods_detected'] ?? []);
      });
    } catch (e) { debugPrint('journal stats: $e'); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FC),
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text('Analytics',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
      actions: [
        IconButton(icon: const Icon(Icons.refresh, color: Colors.grey), onPressed: _load),
      ],
      bottom: TabBar(
        controller: _tabCtrl,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.blue,
        tabs: const [Tab(text: 'Mood'), Tab(text: 'Journals')],
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(controller: _tabCtrl, children: [_moodTab(), _journalTab()]),
  );

  // ── MOOD TAB ───────────────────────────────────────────────────────────────

  Widget _moodTab() => RefreshIndicator(
    onRefresh: _load,
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Row(children: [
          Expanded(child: _SummaryCard(
            label: 'Avg Mood Score', value: _overallAvg.toStringAsFixed(1),
            sub: 'out of 5', icon: Icons.sentiment_satisfied_alt,
            color: _moodColor(_overallAvg),
          )),
          const SizedBox(width: 12),
          Expanded(child: _SummaryCard(
            label: 'Most Common',
            value: _mostCommon.isEmpty ? '—' : _capitalize(_mostCommon),
            sub: 'mood overall', icon: Icons.emoji_emotions_outlined,
            color: Colors.purple,
          )),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _SummaryCard(
            label: 'Total Logs', value: _totalLogs.toString(),
            sub: 'all time', icon: Icons.bar_chart, color: Colors.blue,
          )),
          const SizedBox(width: 12),
          Expanded(child: _SummaryCard(
            label: 'Logged Today', value: _usersToday.toString(),
            sub: 'users', icon: Icons.today, color: Colors.teal,
          )),
        ]),

        const SizedBox(height: 24),

        // ── Mood Distribution ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Mood Distribution',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Based on $_totalLogs total mood logs',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 20),
            if (_distribution.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No mood data yet', style: TextStyle(color: Colors.grey)),
              ))
            else
              ..._distribution.map((d) => _distRow(d)),
          ]),
        ),

        const SizedBox(height: 24),
      ]),
    ),
  );

  Widget _distRow(Map<String, dynamic> d) {
    final mood  = d['mood']?.toString()      ?? '';
    final pct   = (d['pct']       as num?)?.toDouble() ?? 0;
    final count = (d['count']     as num?)?.toInt()    ?? 0;
    final avg   = (d['avg_score'] as num?)?.toDouble() ?? 0;
    final color = _moodLabelColor(mood);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 10, height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(_capitalize(mood),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
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
  }

  // ── JOURNAL TAB ────────────────────────────────────────────────────────────

  Widget _journalTab() => RefreshIndicator(
    onRefresh: _load,
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Row(children: [
          Expanded(child: _SummaryCard(
            label: 'Total Journals', value: _totalJournals.toString(),
            sub: 'all time', icon: Icons.menu_book, color: Colors.indigo,
          )),
          const SizedBox(width: 12),
          Expanded(child: _SummaryCard(
            label: 'Avg Sentiment', value: _avgSentiment.toStringAsFixed(2),
            sub: _avgSentiment > 0 ? 'positive' : _avgSentiment < 0 ? 'negative' : 'neutral',
            icon: Icons.psychology_outlined,
            color: _avgSentiment > 0 ? Colors.green : _avgSentiment < 0 ? Colors.red : Colors.grey,
          )),
        ]),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Sentiment Breakdown',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Based on $_totalJournals journal entries',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            _sentimentBar('Positive', _positiveCount, Colors.green),
            const SizedBox(height: 10),
            _sentimentBar('Neutral',  _neutralCount,  Colors.blue),
            const SizedBox(height: 10),
            _sentimentBar('Negative', _negativeCount, Colors.red),
          ]),
        ),

        const SizedBox(height: 24),

        if (_journalTrend.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Journal Activity — Last 30 Days',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(height: 160, child: _JournalLineChart(trend: _journalTrend)),
            ]),
          ),

        const SizedBox(height: 24),

        if (_topMoods.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Top Detected Moods in Journals',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ..._topMoods.map((m) {
                final mood  = m['mood']?.toString()     ?? '';
                final count = (m['count'] as num?)?.toInt() ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(mood, style: const TextStyle(
                          color: Colors.indigo, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    const Spacer(),
                    Text('$count entries',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ]),
                );
              }),
            ]),
          ),

        const SizedBox(height: 24),
      ]),
    ),
  );

  Widget _sentimentBar(String label, int count, Color color) {
    final total = _positiveCount + _neutralCount + _negativeCount;
    final pct   = total > 0 ? count / total : 0.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text('$count  (${(pct * 100).toStringAsFixed(0)}%)',
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ]),
      const SizedBox(height: 5),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: pct,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 8,
        ),
      ),
    ]);
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Color _moodColor(double avg) {
    if (avg >= 4.5) return const Color(0xFF00C853);
    if (avg >= 3.5) return const Color(0xFF69F0AE);
    if (avg >= 2.5) return const Color(0xFFFFD740);
    if (avg >= 1.5) return const Color(0xFFFF6D00);
    return const Color(0xFFD50000);
  }

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
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.sub,
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
        Text(sub,   style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
      ])),
    ]),
  );
}

class _JournalLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> trend;
  const _JournalLineChart({required this.trend});

  @override
  Widget build(BuildContext context) {
    final spots = trend.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), (e.value['count'] as num).toDouble()))
        .toList();
    final maxY = trend.isEmpty ? 5.0
        : trend.map((t) => (t['count'] as num).toDouble()).reduce((a, b) => a > b ? a : b) + 1;

    return LineChart(LineChartData(
      minY: 0, maxY: maxY,
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true, drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: Colors.grey.withOpacity(0.12), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 28,
          getTitlesWidget: (val, _) => Text(val.toInt().toString(),
              style: const TextStyle(fontSize: 9, color: Colors.grey)),
        )),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 20, interval: 7,
          getTitlesWidget: (val, _) {
            final idx = val.toInt();
            if (idx < 0 || idx >= trend.length) return const SizedBox.shrink();
            final parts = (trend[idx]['date']?.toString() ?? '').split('-');
            if (parts.length < 3) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${parts[2]}/${parts[1]}',
                  style: const TextStyle(fontSize: 8, color: Colors.grey)));
          },
        )),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots, isCurved: true, color: Colors.indigo, barWidth: 2.5,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: Colors.indigo.withOpacity(0.08)),
        ),
      ],
    ));
  }
}