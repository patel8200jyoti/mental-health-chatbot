import 'package:flutter/material.dart';
import '../../services/chat_api_service.dart';
import '../../utils/profile_doodle.dart';

// ── Journal Entry Detail Screen ───────────────────────────────────────────────

class JournalEntryDetailScreen extends StatelessWidget {
  final String dateLabel;
  final String content;
  final String aiReflection;
  final String moodDetected;

  const JournalEntryDetailScreen({
    super.key,
    required this.dateLabel,
    required this.content,
    this.aiReflection = '',
    this.moodDetected = '',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        elevation:       0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Journal Entry',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateLabel,
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: Container(
                padding:    const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:        const Color(0xFFD6EBFF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Entry content ─────────────────────────────────
                      Text(
                        content,
                        style: const TextStyle(
                            fontSize: 16, height: 1.5, color: Colors.black87),
                      ),

                      // ── AI Reflection ─────────────────────────────────
                      if (aiReflection.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(children: const [
                          Icon(Icons.auto_awesome,
                              color: Color(0xFF4FBFA5), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'AI Reflection',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4FBFA5)),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        Text(
                          aiReflection,
                          style: const TextStyle(
                              fontSize: 14, height: 1.5, color: Colors.black54),
                        ),
                      ],

                      // ── Detected mood chip ────────────────────────────
                      if (moodDetected.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(children: [
                          const Text('Detected mood: ',
                              style: TextStyle(color: Colors.grey)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color:        const Color(0xFFB2F1E8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              moodDetected,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ]),
                      ],

                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Journal List Screen ───────────────────────────────────────────────────────

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});
  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _api = AppApi();

  List<Map<String, dynamic>> _journals  = [];
  bool                        _isLoading = true;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchJournals();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _fetchJournals() async {
    try {
      final data = await _api.getJournals();
      if (mounted) setState(() { _journals = data; _isLoading = false; });
    } catch (e) {
      debugPrint('Failed to fetch journals: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Resolves the journal ID robustly across different API response shapes.
  String _journalId(Map<String, dynamic> entry) =>
      entry['journal_id']?.toString() ??
      entry['_id']?.toString()        ??
      entry['id']?.toString()         ?? '';

  // ── Add / Edit sheet ──────────────────────────────────────────────────────

  void _openEntrySheet({Map<String, dynamic>? existing}) {
    final controller = TextEditingController(
        text: existing?['content']?.toString() ?? '');

    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      // Use the builder's context so MediaQuery reflects the sheet's insets
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          left:   20,
          right:  20,
          top:    20,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [

          // Drag handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
                color:        Colors.grey[300],
                borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(height: 16),

          Text(
            existing == null ? 'New Entry' : 'Edit Entry',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: controller,
            maxLines:   6,
            autofocus:  true,
            decoration: InputDecoration(
              hintText:  "What's on your mind today?",
              filled:    true,
              fillColor: const Color(0xFFD6EBFF),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:   BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7ADFD1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(sheetCtx);
                try {
                  if (existing == null) {
                    await _api.addJournal(text);
                  } else {
                    final id = _journalId(existing);
                    if (id.isEmpty) {
                      debugPrint(
                          '⚠️ Could not resolve journal ID. Keys: '
                          '${existing.keys.toList()}');
                    }
                    await _api.updateJournal(id, text);
                  }
                  await _fetchJournals();
                } catch (e) {
                  debugPrint('Failed to save journal: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content:         Text('Failed to save entry.'),
                        backgroundColor: Colors.red));
                  }
                }
              },
              child: Text(
                existing == null ? 'Save Entry' : 'Update Entry',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 20),

        ]),
      ),
    );
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(Map<String, dynamic> entry) async {
    final id = _journalId(entry);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title:   const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) await _deleteJournal(id);
  }

  Future<void> _deleteJournal(String id) async {
    try {
      await _api.deleteJournal(id);
      await _fetchJournals();
    } catch (e) {
      debugPrint('Failed to delete journal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:         Text('Failed to delete entry.'),
            backgroundColor: Colors.red));
      }
    }
  }

  // ── Detail navigation ─────────────────────────────────────────────────────

  void _openDetail(Map<String, dynamic> entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JournalEntryDetailScreen(
          dateLabel:    _formatDate(entry['created_at']?.toString()),
          content:      entry['content']?.toString()       ?? '',
          aiReflection: entry['ai_reflection']?.toString() ?? '',
          moodDetected: entry['mood_detected']?.toString() ?? '',
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month]} ${dt.day}, ${dt.year}';
    } catch (_) { return raw; }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const ProfileDoodleIcon(size: 40,filled: true),
          onPressed: () => Navigator.pushNamed(context, '/profile'),
        ),
        actions:  [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () => Navigator.pushNamed(context, "/chat"),
              icon: const CircleAvatar(
                backgroundColor: Colors.teal,
                child: Icon(Icons.spa, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7ADFD1),
        onPressed:       () => _openEntrySheet(),
        child:           const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ────────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'My Journal',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'Reflect on your thoughts and feelings.',
              style: TextStyle(color: Colors.grey),
            ),
          ),

          // ── List / states ─────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _journals.isEmpty
                    ? _buildEmptyState()
                    : _buildList(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(1),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No entries yet.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Tap + to write your first entry.',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  // ── Journal list ──────────────────────────────────────────────────────────

  Widget _buildList() {
    return ListView.builder(
      padding:   const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _journals.length,
      itemBuilder: (_, i) {
        final entry   = _journals[i];
        final content = entry['content']?.toString()       ?? '';
        final date    = _formatDate(entry['created_at']?.toString());
        final mood    = entry['mood_detected']?.toString() ?? '';

        return GestureDetector(
          onTap: () => _openDetail(entry),
          child: Container(
            margin:  const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:        const Color(0xFFD6EBFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Top row: date + mood chip + actions ──────────────
                Row(children: [
                  Text(
                    date,
                    style: const TextStyle(
                        fontSize:   12,
                        color:      Colors.grey,
                        fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  if (mood.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color:        Colors.white,
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        mood,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.teal),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    icon:        const Icon(Icons.edit,
                        size: 18, color: Colors.grey),
                    padding:     EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed:   () => _openEntrySheet(existing: entry),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon:        Icon(Icons.delete_outline,
                        size: 18, color: Colors.red.shade300),
                    padding:     const EdgeInsets.all(0),
                    constraints: const BoxConstraints(),
                    onPressed:   () => _confirmDelete(entry),
                  ),
                ]),
                const SizedBox(height: 10),

                // ── Content preview ──────────────────────────────────
                Text(
                  content.length > 120
                      ? '${content.substring(0, 120)}…'
                      : content,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),

              ],
            ),
          ),
        );
      },
    );
  }

  // ── Bottom nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav(int current) {
    const icons  = [
      Icons.sentiment_satisfied_alt,
      Icons.menu_book,
      Icons.grid_view,
      Icons.local_hospital,
    ];
    const labels = ['Mood', 'Journal', 'Toolkit', 'Doctors'];
    const routes = ['/mood', '/journal', '/toolkit', '/doctor'];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft:  Radius.circular(20),
            topRight: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: BottomNavigationBar(
        type:                 BottomNavigationBarType.fixed,
        currentIndex:         current,
        backgroundColor:      Colors.transparent,
        elevation:            0,
        selectedItemColor:    const Color.fromARGB(255, 0, 0, 0),
        unselectedItemColor:  Colors.grey,
        showUnselectedLabels: true,
        onTap: (i) {
          if (i == current) return;
          Navigator.pushReplacementNamed(context, routes[i]);
        },
        items: List.generate(
          4,
          (i) => BottomNavigationBarItem(
            label: labels[i],
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: i == current
                    ?const Color.fromARGB(255, 0, 150, 136)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icons[i],
                color: i == current ? Colors.white : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}