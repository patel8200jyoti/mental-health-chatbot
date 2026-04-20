import 'package:flutter/material.dart';
import '../../services/chat_api_service.dart';
import '../../utils/profile_doodle.dart';

// ── App-wide palette (matches mood / journal / chat screens) ──────────────────
const _teal = Color(0xFF7ADFD1);
const _tealDark = Color(0xFF4FBFA5);
const _bg = Color(0xFFF4F8FB);
const _textDark = Color(0xFF111827);
const _textMid = Color(0xFF374151);
const _textGrey = Color(0xFF6B7280);
const _green1 = Color(0xFF34D399);
const _green2 = Color(0xFF10B981);

// ── Toolkit list screen ───────────────────────────────────────────────────────

class ToolkitScreen extends StatefulWidget {
  const ToolkitScreen({super.key});
  @override
  State<ToolkitScreen> createState() => _ToolkitScreenState();
}

class _ToolkitScreenState extends State<ToolkitScreen> {
  final AppApi _api = AppApi();

  Map<String, dynamic> _groupedTools = {};
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTools();
  }

  Future<void> _fetchTools() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final data = await _api.getGroupedTools();
      if (mounted)
        setState(() {
          _groupedTools = Map<String, dynamic>.from(data);
          _loading = false;
        });
    } catch (e) {
      debugPrint('Toolkit load error: $e');
      if (mounted)
        setState(() {
          _loading = false;
          _errorMessage = 'Failed to load. Tap to retry.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _teal))
            : _errorMessage != null
            ? _buildError()
            : _buildContent(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
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
  );

  Widget _buildError() => Center(
    child: GestureDetector(
      onTap: _fetchTools,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          const Text(
            'Tap to retry',
            style: TextStyle(color: _green2, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );

  Widget _buildContent() => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Wellness Toolkit',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Nurture your mind with daily practices.',
          style: TextStyle(fontSize: 14, color: _textGrey),
        ),
        const SizedBox(height: 30),
        if (_groupedTools.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text(
                'No categories available.',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _groupedTools.keys.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (_, i) {
              final cat = _groupedTools.keys.elementAt(i);
              return _CategoryCard(
                category: cat,
                api: _api,
                tools: List.from(_groupedTools[cat] ?? []),
              );
            },
          ),
        const SizedBox(height: 80),
      ],
    ),
  );

  Widget _buildBottomNav() {
    const currentIndex = 2;
    const icons = [
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
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color.fromARGB(255, 0, 0, 0),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: (i) {
          if (i == currentIndex) return;
          Navigator.pushReplacementNamed(context, routes[i]);
        },
        items: List.generate(
          4,
          (i) => BottomNavigationBarItem(
            label: labels[i],
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: i == currentIndex
                    ? const Color.fromARGB(255, 0, 150, 136)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icons[i],
                color: i == currentIndex ? Colors.white : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Category card ─────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final String category;
  final AppApi api;
  final List tools;
  const _CategoryCard({
    required this.category,
    required this.api,
    required this.tools,
  });

  static IconData iconFor(String c) {
    switch (c) {
      case 'breathing':
        return Icons.air;
      case 'grounding':
        return Icons.sentiment_very_satisfied;
      case 'quotes':
        return Icons.format_quote;
      case 'cbt':
        return Icons.psychology;
      case 'dbt':
        return Icons.self_improvement;
      case 'self_compassion':
        return Icons.favorite;
      default:
        return Icons.extension;
    }
  }

  static String nameFor(String c) {
    switch (c) {
      case 'breathing':
        return 'Breathing';
      case 'grounding':
        return 'Grounding';
      case 'quotes':
        return 'Daily Quotes';
      case 'cbt':
        return 'CBT Toolkit';
      case 'dbt':
        return 'DBT Toolkit';
      case 'self_compassion':
        return 'Self Compassion';
      default:
        return c.isNotEmpty ? c[0].toUpperCase() + c.substring(1) : c;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CategoryToolsScreen(category: category, tools: tools, api: api),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF1F5F9),
              ),
              child: Icon(
                iconFor(category),
                size: 26,
                color: const Color(0xFF4B5563),
              ),
            ),
            Text(
              nameFor(category),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_green1, _green2]),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: Text(
                  'Start',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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

// ── Category tools screen ─────────────────────────────────────────────────────

class CategoryToolsScreen extends StatelessWidget {
  final String category;
  final List tools;
  final AppApi api;
  const CategoryToolsScreen({
    super.key,
    required this.category,
    required this.tools,
    required this.api,
  });

  String _toolId(Map<String, dynamic> t) =>
      t['id']?.toString() ??
      t['_id']?.toString() ??
      t['tool_id']?.toString() ??
      '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _CategoryCard.nameFor(category),
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: _textDark),
      ),
      body: tools.isEmpty
          ? Center(
              child: Text(
                'No tools available.',
                style: TextStyle(color: Colors.grey[400]),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
              itemCount: tools.length,
              itemBuilder: (_, i) {
                final tool = Map<String, dynamic>.from(tools[i] as Map);
                return _ToolTile(tool: tool, toolId: _toolId(tool), api: api);
              },
            ),
    );
  }
}

// ── Tool tile (stateful: stores the future once, expands cleanly) ─────────────

class _ToolTile extends StatefulWidget {
  final Map<String, dynamic> tool;
  final String toolId;
  final AppApi api;
  const _ToolTile({
    required this.tool,
    required this.toolId,
    required this.api,
  });

  @override
  State<_ToolTile> createState() => _ToolTileState();
}

class _ToolTileState extends State<_ToolTile> {
  Future<Map<String, dynamic>>? _future;
  bool _expanded = false;

  void _onExpand(bool open) {
    setState(() => _expanded = open);
    // Fire the API call exactly once, on first open
    if (open && _future == null && widget.toolId.isNotEmpty) {
      setState(() => _future = widget.api.getToolById(widget.toolId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: _expanded ? Border.all(color: _teal.withOpacity(0.45)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        // Remove the default ExpansionTile divider lines
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          childrenPadding: EdgeInsets.zero,
          onExpansionChanged: _onExpand,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _teal.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _CategoryCard.iconFor(widget.tool['category']?.toString() ?? ''),
              size: 20,
              color: _tealDark,
            ),
          ),
          title: Text(
            widget.tool['title']?.toString() ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: _textDark,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              widget.tool['description']?.toString() ?? '',
              style: const TextStyle(
                fontSize: 12,
                color: _textGrey,
                height: 1.3,
              ),
            ),
          ),
          trailing: AnimatedRotation(
            turns: _expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.keyboard_arrow_down, color: _tealDark),
          ),
          children: [
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            _buildBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    // No ID — can't load detail
    if (widget.toolId.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(18),
        child: Text(
          'Details unavailable.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    // Future not started yet (tile just opened, setState hasn't propagated)
    if (_future == null) return const SizedBox.shrink();

    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: CircularProgressIndicator(color: _teal, strokeWidth: 2),
            ),
          );
        }
        if (snap.hasError || !snap.hasData) {
          debugPrint('Tool detail error: ${snap.error}');
          // Fall back to summary fields so the tile isn't empty
          return Padding(
            padding: const EdgeInsets.all(18),
            child: _ToolDetail(data: widget.tool),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(18),
          child: _ToolDetail(data: snap.data!),
        );
      },
    );
  }
}

// ── Tool detail renderer ──────────────────────────────────────────────────────
// All rendering helpers live HERE so they have access to the data map.

class _ToolDetail extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ToolDetail({required this.data});

  @override
  Widget build(BuildContext context) {
    final w = <Widget>[];

    // ── Explanation ───────────────────────────────────────────────────────
    final explanation = data['explanation']?.toString() ?? '';
    if (explanation.isNotEmpty) {
      w.add(_infoBox(explanation));
      w.add(const SizedBox(height: 14));
    }

    // ── Steps ─────────────────────────────────────────────────────────────
    if (data['steps'] is List) {
      for (final s in data['steps'] as List) {
        if (s is! Map) continue;
        final sense = s['sense']?.toString();
        final num = s['step']?.toString();
        final secs = s['duration_seconds'];
        w.add(
          _stepRow(
            badge: sense ?? (num != null ? '$num.' : '•'),
            instruction: s['instruction']?.toString() ?? '',
            duration: secs != null ? '${secs}s' : null,
          ),
        );
      }
      w.add(const SizedBox(height: 4));
    }

    // ── Quotes ────────────────────────────────────────────────────────────
    if (data['quotes'] is List) {
      for (final q in data['quotes'] as List) {
        if (q is! Map) continue;
        w.add(
          _quoteCard(
            q['text']?.toString() ?? '',
            q['author']?.toString() ?? '',
          ),
        );
      }
    }

    // ── CBT: Distortions ──────────────────────────────────────────────────
    if (data['distortions'] is List) {
      for (final d in data['distortions'] as List) {
        if (d is! Map) continue;
        w.add(_distortionCard(d));
      }
    }

    // ── CBT: Thought Record template ──────────────────────────────────────
    if (data['template'] is List) {
      for (final f in data['template'] as List) {
        if (f is! Map) continue;
        w.add(
          _fieldPrompt(
            label: f['label']?.toString() ?? '',
            prompt: f['prompt']?.toString() ?? '',
          ),
        );
      }
    }

    // ── CBT: Behavioural Activation ───────────────────────────────────────
    if (data['activity_categories'] is List) {
      w.add(_sectionLabel('Activity Ideas'));
      for (final cat in data['activity_categories'] as List) {
        if (cat is! Map) continue;
        final examples = cat['examples'];
        if (examples is List) {
          w.add(
            _chipGroup(
              cat['category']?.toString() ?? '',
              examples.map((e) => e.toString()).toList(),
            ),
          );
        }
      }
    }

    // ── DBT: Skills (TIPP letter blocks + Interpersonal named skills) ──────
    if (data['skills'] is List) {
      for (final skill in data['skills'] as List) {
        if (skill is! Map) continue;

        // TIPP — has 'letter' key
        if (skill['letter'] != null) {
          final howTo = skill['how_to'];
          w.add(
            _letterBlock(
              letter: skill['letter']?.toString() ?? '',
              title: skill['skill']?.toString() ?? '',
              description: skill['description']?.toString() ?? '',
              howTo: howTo is List
                  ? howTo.map((e) => e.toString()).toList()
                  : [],
            ),
          );
        }

        // Interpersonal (DEAR MAN / FAST) — has 'name' + 'steps'
        if (skill['name'] != null && skill['steps'] is List) {
          w.add(_sectionLabel(skill['name']?.toString() ?? ''));
          for (final step in skill['steps'] as List) {
            if (step is! Map) continue;
            final letter = step['letter']?.toString() ?? '';
            final sName = step['skill']?.toString() ?? '';
            final example = step['example']?.toString() ?? '';
            w.add(
              _stepRow(
                badge: letter.isNotEmpty ? letter : '•',
                instruction: sName.isNotEmpty ? '$sName: $example' : example,
              ),
            );
          }
          w.add(const SizedBox(height: 10));
        }
      }
    }

    // ── DBT: Emotion wheel ────────────────────────────────────────────────
    if (data['emotion_wheel'] is List) {
      w.add(_sectionLabel('Emotion Wheel'));
      for (final e in data['emotion_wheel'] as List) {
        if (e is! Map) continue;
        final secondary = e['secondary'];
        if (secondary is List) {
          w.add(
            _chipGroup(
              e['primary']?.toString() ?? '',
              secondary.map((s) => s.toString()).toList(),
            ),
          );
        }
      }
    }

    // ── Radical Acceptance: resistances + rebuttals ───────────────────────
    if (data['common_resistances'] is List) {
      w.add(_sectionLabel('Common Resistances'));
      final resistances = data['common_resistances'] as List;
      final rebuttals = data['rebuttals'] is List
          ? data['rebuttals'] as List
          : <dynamic>[];
      for (int i = 0; i < resistances.length; i++) {
        w.add(
          _resistanceRow(
            resistance: resistances[i].toString(),
            rebuttal: i < rebuttals.length ? rebuttals[i].toString() : '',
          ),
        );
      }
    }

    // ── Self-compassion scripts ───────────────────────────────────────────
    if (data['scripts'] is List) {
      for (final s in data['scripts'] as List) {
        if (s is! Map) continue;
        w.add(
          _scriptCard(
            moment: s['moment']?.toString() ?? '',
            script: s['script']?.toString() ?? '',
          ),
        );
      }
    }

    // ── Inner critic example ──────────────────────────────────────────────
    if (data['example'] is Map) {
      final ex = data['example'] as Map;
      w.add(_sectionLabel('Example'));
      w.add(
        _twoPartCard(
          topLabel: '🔴 Inner Critic',
          topText: ex['critic']?.toString() ?? '',
          bottomLabel: '💚 Compassionate Response',
          bottomText: ex['compassionate_response']?.toString() ?? '',
        ),
      );
      w.add(const SizedBox(height: 8));
    }

    // ── Affirmations ──────────────────────────────────────────────────────
    if (data['affirmations'] is List) {
      w.add(_sectionLabel('Affirmations'));
      for (final a in data['affirmations'] as List) {
        w.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✦  ',
                  style: TextStyle(color: _tealDark, fontSize: 13),
                ),
                Expanded(
                  child: Text(
                    a.toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: _textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // ── Tip ───────────────────────────────────────────────────────────────
    final tip = data['tip']?.toString() ?? '';
    if (tip.isNotEmpty) {
      w.add(const SizedBox(height: 6));
      w.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFEEFAF8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _teal.withOpacity(0.35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline, size: 15, color: _tealDark),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  tip,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textMid,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (w.isEmpty) {
      w.add(
        Text(
          'No content available.',
          style: TextStyle(color: Colors.grey[400]),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: w);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _infoBox(String text) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFEEFAF8),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _teal.withOpacity(0.3)),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, height: 1.5, color: _textMid),
    ),
  );

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 6),
    child: Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: _textMid,
      ),
    ),
  );

  Widget _stepRow({
    required String badge,
    required String instruction,
    String? duration,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 1),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: _teal.withOpacity(0.18),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _tealDark,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                instruction,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: _textDark,
                ),
              ),
              if (duration != null)
                Text(
                  duration,
                  style: const TextStyle(fontSize: 11, color: _textGrey),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _quoteCard(String text, String author) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFEEFAF8),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _teal.withOpacity(0.3)),
    ),
    child: Text(
      '"$text"${author.isNotEmpty ? "\n— $author" : ""}',
      style: const TextStyle(
        fontStyle: FontStyle.italic,
        fontSize: 13,
        height: 1.5,
        color: _textMid,
      ),
    ),
  );

  Widget _distortionCard(Map d) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFB),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          d['name']?.toString() ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          d['description']?.toString() ?? '',
          style: const TextStyle(fontSize: 12, color: _textGrey),
        ),
        if (d['example'] != null) ...[
          const SizedBox(height: 4),
          Text(
            'e.g. "${d['example']}"',
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _fieldPrompt({required String label, required String prompt}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: _textMid,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              prompt,
              style: const TextStyle(
                fontSize: 12,
                color: _textGrey,
                height: 1.4,
              ),
            ),
          ],
        ),
      );

  Widget _chipGroup(String header, List<String> items) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(
              header,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textMid,
              ),
            ),
          ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items
              .map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _teal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 11, color: _tealDark),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );

  Widget _letterBlock({
    required String letter,
    required String title,
    required String description,
    required List<String> howTo,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFEEFAF8),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _teal.withOpacity(0.35)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: _tealDark,
              child: Text(
                letter,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: _textDark,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 11, color: _textGrey),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (howTo.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...howTo.map(
            (h) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '→  ',
                    style: TextStyle(
                      color: _tealDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      h,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: _textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _scriptCard({required String moment, required String script}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEEFAF8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _teal.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              moment,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: _tealDark,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              script,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: _textDark,
              ),
            ),
          ],
        ),
      );

  Widget _twoPartCard({
    required String topLabel,
    required String topText,
    required String bottomLabel,
    required String bottomText,
  }) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF7F7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                topText,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: _textDark,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFFEEFAF8),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(11)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bottomLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: _tealDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                bottomText,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: _textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _resistanceRow({
    required String resistance,
    required String rebuttal,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '✗  ',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: Text(
                resistance,
                style: const TextStyle(fontSize: 13, color: _textMid),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '✓  ',
              style: TextStyle(color: _tealDark, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Text(
                rebuttal,
                style: const TextStyle(
                  fontSize: 12,
                  color: _textGrey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}