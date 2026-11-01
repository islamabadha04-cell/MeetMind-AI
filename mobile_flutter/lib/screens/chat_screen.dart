import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/colors.dart';
import '../core/localization/language_provider.dart';
import '../core/services/meeting_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String timestamp;
  final String? model;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.model,
  });
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Hello! I am your MeetMind AI Meeting Assistant. Ask me anything about your past discussions, action items, financial decisions, or team roadmaps.',
      isUser: false,
      timestamp: 'Just now',
      model: 'Gemini 2.5 Flash',
    ),
  ];
  final _textController = TextEditingController();
  bool _isSending = false;
  String _selectedProvider = 'gemini'; // 'gemini' or 'ollama'

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final query = _textController.text.trim();
    if (query.isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(
        text: query,
        isUser: true,
        timestamp: DateTime.now().toString().substring(11, 16),
      ));
      _isSending = true;
    });

    try {
      final reply = await MeetingService.askAiChat(
        message: query,
        provider: _selectedProvider,
      );

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: reply,
            isUser: false,
            timestamp: DateTime.now().toString().substring(11, 16),
            model: _selectedProvider == 'ollama' ? 'Ollama Cloud (glm-5.3-flash)' : 'Gemini 2.5 Flash',
          ));
          _isSending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: 'I encountered an issue processing your query: $e',
            isUser: false,
            timestamp: DateTime.now().toString().substring(11, 16),
          ));
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final isUrdu = lang == AppLanguage.urdu;

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.get('nav_ask_ai', lang)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedProvider,
                  icon: const Icon(Icons.tune, size: 18),
                  items: const [
                    DropdownMenuItem(value: 'gemini', child: Text('✨ Gemini (Default)', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: 'ollama', child: Text('🦙 Ollama Cloud', style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedProvider = val);
                  },
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Provider Indicator Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: AppColors.primary.withValues(alpha: 0.08),
              child: Row(
                children: [
                  Icon(
                    _selectedProvider == 'ollama' ? Icons.cloud_queue : Icons.auto_awesome,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedProvider == 'ollama'
                        ? 'Active Engine: Ollama Cloud (glm-5.3-flash) • Server Grounded'
                        : 'Active Engine: Google Gemini 2.5 Flash • Multi-Source RAG',
                    style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // Chat Messages List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final msg = _messages[i];
                  return Align(
                    alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                      decoration: BoxDecoration(
                        gradient: msg.isUser ? AppColors.buttonGradient : null,
                        color: msg.isUser ? null : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: msg.isUser ? null : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (msg.model != null) ...[
                            Text(
                              msg.model!,
                              style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            msg.text,
                            style: TextStyle(
                              color: msg.isUser ? Colors.white : null,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              msg.timestamp,
                              style: TextStyle(
                                fontSize: 10,
                                color: msg.isUser ? Colors.white70 : Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_isSending)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('Synthesizing meeting memories...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),

            // Input Bar
            Container(
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).cardColor,
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'Ask about meetings, decisions, or tasks...',
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _isSending ? null : _sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
