import 'package:flutter/material.dart';
import '../../services/chat_api_service.dart';
import '../../utils/profile_doodle.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

// Simple message model — avoids all Map type inference issues
class _Msg {
  final String role;
  final String message;
  final bool crisisDetected;
  _Msg({
    required this.role,
    required this.message,
    this.crisisDetected = false,
  });
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputController  = TextEditingController();
  final _scrollController = ScrollController();
  final _api              = AppApi();

  bool    _isBotTyping      = false;
  bool    _isLoadingHistory = true;
  String? _activeChatId;

  final List<_Msg>              _messages = [];
  List<Map<String, dynamic>>    _chatList = [];

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> _init() async {
    await _loadChatList();

    // Pick the first existing chat, or create one if none exist
    _activeChatId ??=
        _chatList.isNotEmpty ? _chatList.first["chat_id"] : null;

    if (_activeChatId == null) {
      final newChatId = await _api.createChat();
      await _api.saveChatId(newChatId);
      await _loadChatList();
      _activeChatId = newChatId;
    }

    if (_activeChatId != null) await _loadHistory(_activeChatId!);

    if (mounted) setState(() => _isLoadingHistory = false);
  }

  // ── Chat list ─────────────────────────────────────────────────────────────

  Future<void> _loadChatList() async {
    try {
      final list = await _api.getChats();
      if (mounted) setState(() => _chatList = list);
    } catch (e) {
      debugPrint("Failed to load chat list: $e");
    }
  }

  // ── Message history ───────────────────────────────────────────────────────

  Future<void> _loadHistory(String chatId) async {
    try {
      final msgs   = await _api.getMessages(chatId);
      final parsed = _parseMsgs(msgs);
      if (mounted)
        setState(() {
          _messages.clear();
          _messages.addAll(parsed);
        });
    } catch (e) {
      debugPrint("Failed to load history: $e");
    }
  }

  List<_Msg> _parseMsgs(List<Map<String, dynamic>> raw) =>
      raw.map((m) => _Msg(
            role:          m["role"]?.toString() ?? "assistant",
            message:       m["message"]?.toString() ?? "",
            crisisDetected: m["crisis_detected"] == true,
          )).toList();

  // ── Send message ──────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isBotTyping || _activeChatId == null) return;

    setState(() {
      _messages.add(_Msg(role: "user", message: text));
      _inputController.clear();
      _isBotTyping = true;
    });
    _scrollToBottom();

    try {
      debugPrint("📤 Sending to chat: $_activeChatId");
      final reply   = await _api.sendMessage(_activeChatId!, text);
      final botText = reply["response"]?.toString() ?? "";
      final isCrisis = reply["crisis_detected"] == true;

      setState(() {
        _isBotTyping = false;
        _messages.add(
          _Msg(role: "assistant", message: botText, crisisDetected: isCrisis),
        );
      });
    } catch (e) {
      debugPrint("❌ Send error: $e");
      setState(() {
        _isBotTyping = false;
        _messages.add(
          _Msg(
            role:    "assistant",
            message: "Something went wrong. Please try again.",
          ),
        );
      });
    }
    _scrollToBottom();
  }

  // ── New chat ──────────────────────────────────────────────────────────────

  Future<void> _startNewChat() async {
    Navigator.pop(context); // close drawer
    setState(() {
      _isLoadingHistory = true;
      _messages.clear();
    });

    try {
      final newChatId = await _api.createChat();
      await _api.saveChatId(newChatId);
      await _loadChatList();
      await _openChat(newChatId);
    } catch (e) {
      debugPrint("Failed to start new chat: $e");
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  // ── Open chat ─────────────────────────────────────────────────────────────

  Future<void> _openChat(String chatId) async {
    if (!mounted) return;

    setState(() {
      _activeChatId     = chatId;
      _isLoadingHistory = true;
      _messages.clear();
    });

    try {
      debugPrint("📂 Opening chat: $chatId");
      final msgs   = await _api.getMessages(chatId);
      debugPrint("📥 Messages received: ${msgs.length}");
      final parsed = _parseMsgs(msgs);
      if (mounted) setState(() => _messages.addAll(parsed));
    } catch (e) {
      debugPrint("Failed to load messages: $e");
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }

    _scrollToBottom();
  }

  // ── Delete chat ───────────────────────────────────────────────────────────

  Future<void> _deleteChat(String chatId) async {
    try {
      await _api.deleteChat(chatId);
      await _loadChatList();

      // If deleted chat was active, switch to next available or clear
      if (_activeChatId == chatId) {
        if (_chatList.isNotEmpty) {
          await _openChat(_chatList.first["chat_id"]);
        } else {
          setState(() {
            _activeChatId = null;
            _messages.clear();
          });
        }
      }
    } catch (e) {
      debugPrint("Failed to delete chat: $e");
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve:    Curves.easeOut,
        );
      }
    });
  }

  /// Returns a human-friendly label for a raw ISO date string.
  String _formatDate(String rawDate) {
    try {
      final dt   = DateTime.parse(rawDate).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inDays == 0) return "Today";
      if (diff.inDays == 1) return "Yesterday";
      if (diff.inDays < 7)  return "${diff.inDays} days ago";
      return "${dt.day.toString().padLeft(2, '0')}/"
             "${dt.month.toString().padLeft(2, '0')}/"
             "${dt.year}";
    } catch (_) {
      return "";
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation:       0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const ProfileDoodleIcon(size: 40,filled: true),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
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
      body: Column(
        children: [

          // ── Date label ─────────────────────────────────────────────────
          const SizedBox(height: 8),
          Text(
            "TODAY",
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),

          // ── Message list ───────────────────────────────────────────────
          Expanded(
            child: _isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding:    const EdgeInsets.symmetric(horizontal: 16),
                        itemCount:
                            _messages.length + (_isBotTyping ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i < _messages.length)
                            return _buildBubble(_messages[i]);
                          return _buildTypingIndicator();
                        },
                      ),
          ),

          // ── Input area ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Nav shortcuts
              Row(children: [
                _navButton('/mood',    "Mood",    Icons.sentiment_satisfied_alt),
                _navButton('/journal', "Journal", Icons.menu_book),
                _navButton('/toolkit', "Toolkit", Icons.grid_view_rounded),
                _navButton('/doctor',  "Doctor",  Icons.local_hospital),
              ]),
              const SizedBox(height: 10),
              // Text input + send
              Row(children: [
                Expanded(
                  child: TextField(
                    controller:  _inputController,
                    onSubmitted: (_) => _sendMessage(),
                    maxLines:    null,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText:  "Tell me what's on your mind…",
                      filled:    true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:   BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color:        const Color(0xFF7ADFD1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.arrow_upward),
                  ),
                ),
              ]),
            ]),
          ),

        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            "Start a conversation",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // ── Typing indicator ──────────────────────────────────────────────────────

  Widget _buildTypingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(8),
      child: Text(
        "Bot is typing…",
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }

  // ── Message bubble ────────────────────────────────────────────────────────

  Widget _buildBubble(_Msg msg) {
    final isUser = msg.role == "user";
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin:  const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: msg.crisisDetected
              ? Colors.red.shade50
              : isUser
                  ? const Color(0xFFD6F5E4)
                  : const Color(0xFFD6EBFF),
          borderRadius: BorderRadius.circular(16),
          border: msg.crisisDetected
              ? Border.all(color: Colors.red.shade200)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.crisisDetected)
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.red, size: 16),
                  SizedBox(width: 4),
                  Text(
                    "Crisis support included",
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ]),
              ),
            Text(msg.message),
          ],
        ),
      ),
    );
  }

  // ── Drawer ────────────────────────────────────────────────────────────────

  Widget _buildDrawer() {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(children: [

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "MindEase AI",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                CloseButton(),
              ],
            ),
          ),

          // New Chat button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startNewChat,
                icon:  const Icon(Icons.add, size: 18),
                label: const Text("New Chat"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB2F1E8),
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "RECENT CHATS",
                style: TextStyle(
                  fontSize:    12,
                  color:       Colors.grey[600],
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Chat list
          Expanded(
            child: _chatList.isEmpty
                ? Center(
                    child: Text(
                      "No chats yet",
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  )
                : ListView.builder(
                    itemCount: _chatList.length,
                    itemBuilder: (_, i) {
                      final chat     = _chatList[i];
                      final id       = chat["chat_id"]?.toString() ?? "";
                      final title    = chat["chat_title"]?.toString() ?? "Chat";
                      final dateStr  = _formatDate(
                          chat["created_at"]?.toString() ?? "");
                      final isActive = id == _activeChatId;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          tileColor: isActive
                              ? const Color(0xFFB2F1E8)
                              : const Color(0xFFEAF4FF),
                          leading: Icon(
                            Icons.chat_bubble_outline,
                            size:  18,
                            color: isActive ? Colors.teal : Colors.grey,
                          ),
                          title: Text(
                            title,
                            maxLines:  1,
                            overflow:  TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: dateStr.isNotEmpty
                              ? Text(
                                  dateStr,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500]),
                                )
                              : null,
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline,
                                size: 18,
                                color: Colors.red.shade300),
                            onPressed: () => _confirmDeleteChat(id),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _openChat(id);
                          },
                        ),
                      );
                    },
                  ),
          ),

          // Profile footer
          InkWell(
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              child: Row(children: const [
                CircleAvatar(
                  radius:          20,
                  backgroundColor: Colors.grey,
                  child:  ProfileDoodleIcon(size: 40,filled: true),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("My Profile",
                        style:
                            TextStyle(fontWeight: FontWeight.bold)),
                    Text("View & edit",
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ]),
            ),
          ),

        ]),
      ),
    );
  }

  // ── Delete confirmation dialog ────────────────────────────────────────────

  Future<void> _confirmDeleteChat(String chatId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title:   const Text("Delete chat?"),
        content: const Text(
            "This will permanently delete this chat and all its messages."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) _deleteChat(chatId);
  }

  // ── Nav button ────────────────────────────────────────────────────────────

  Widget _navButton(String route, String label, IconData icon) {
    return Expanded(
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin:  const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: const Color(0xFF7ADFD1)),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}