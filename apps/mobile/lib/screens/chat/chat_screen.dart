import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "../../core/theme/colors.dart";
import "../../core/theme/typography.dart";
import "../../models/case_model.dart";
import "../../services/groq_service.dart";
import "../../services/supabase_service.dart";
import "../../widgets/glass_input.dart";
import "../../widgets/suggestion_chip.dart";

const _kSuggestions = [
  "What are my court fees?",
  "How to issue notice?",
  "Draft Legal Notice",
  "Explore Settlement",
  "Find Lawyer",
];

class ChatScreen extends StatefulWidget {
  final CaseModel caseModel;
  final String userId;
  final VoidCallback onBack;

  const ChatScreen({super.key, required this.caseModel, required this.userId, required this.onBack});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatMessage {
  final String role;
  final String content;
  _ChatMessage(this.role, this.content);
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scrollController = ScrollController();
  List<_ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await SupabaseService.instance.listMessages(widget.caseModel.id);
    setState(() {
      _messages = rows.map((r) => _ChatMessage(r["role"] as String, r["content"] as String)).toList();
      _loading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
      _messages.add(_ChatMessage("user", text.trim()));
      _input.clear();
    });
    _scrollToBottom();
    try {
      await SupabaseService.instance.addMessage(widget.caseModel.id, widget.userId, "user", text.trim());
      final history = _messages.map((m) => {"role": m.role, "content": m.content}).toList();
      final reply = await GroqService.instance.chatWithAgent(widget.caseModel.rawDescription, history);
      await SupabaseService.instance.addMessage(widget.caseModel.id, widget.userId, "assistant", reply);
      setState(() => _messages.add(_ChatMessage("assistant", reply)));
      _scrollToBottom();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 20, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white, size: 20),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Chat with Agent", style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 20)),
                    Text(widget.caseModel.title, style: AppTypography.caption),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 24),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) => _bubble(_messages[i], i),
                  ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
            ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _kSuggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => SuggestionChip(
                label: _kSuggestions[i],
                disabled: _sending,
                onTap: () => _send(_kSuggestions[i]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Row(
              children: [
                IconButton(onPressed: null, icon: Icon(Icons.attach_file_rounded, color: AppColors.hintText.withOpacity(0.6))),
                Expanded(
                  child: GlassInput(
                    hint: "Type a message…",
                    controller: _input,
                    suffix: IconButton(
                      onPressed: null,
                      icon: Icon(Icons.mic_none_rounded, color: AppColors.hintText.withOpacity(0.6)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _send(_input.text),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.black87, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(_ChatMessage m, int index) {
    final isUser = m.role == "user";
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? AppColors.chatBubbleUser : AppColors.chatBubbleAi,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(m.content, style: const TextStyle(color: AppColors.white, fontSize: 15, height: 1.5)),
      ),
    ).animate(delay: Duration(milliseconds: 30 * (index % 6))).fadeIn(duration: const Duration(milliseconds: 250)).slideY(begin: 0.08, end: 0);
  }
}
