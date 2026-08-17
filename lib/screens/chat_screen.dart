import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/rag_service.dart';

class ChatScreen extends StatefulWidget {
  final RagService ragService;
  final String? activePlant;

  const ChatScreen({
    super.key,
    required this.ragService,
    this.activePlant,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isGenerating = false;
  late String _selectedPlantFocus;

  @override
  void initState() {
    super.initState();
    _selectedPlantFocus = widget.activePlant ?? "🌐 All 16 Medicinal Plants";
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activePlant != null &&
        widget.activePlant != oldWidget.activePlant) {
      setState(() {
        _selectedPlantFocus = widget.activePlant!;
      });
    }
  }

  void _sendMessage([String? customPrompt]) async {
    final text = customPrompt ?? _textController.text.trim();
    if (text.isEmpty || _isGenerating) return;

    _textController.clear();

    setState(() {
      _messages.add({"role": "user", "content": text});
      _isGenerating = true;
    });

    _scrollToBottom();

    final response = await widget.ragService.answerRagChat(
      userQuery: text,
      chatHistory: _messages,
      activePlant: _selectedPlantFocus,
    );

    if (mounted) {
      setState(() {
        _messages.add({"role": "assistant", "content": response});
        _isGenerating = false;
      });
      _scrollToBottom();
    }
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

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plantOptions = ["🌐 All 16 Medicinal Plants"] +
        widget.ragService.plants.map((p) => p.localName).toList();

    return Column(
      children: [
        // Top Active Plant Selector & Controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: plantOptions.contains(_selectedPlantFocus)
                        ? _selectedPlantFocus
                        : plantOptions.first,
                    isExpanded: true,
                    items: plantOptions.map((opt) {
                      return DropdownMenuItem(
                        value: opt,
                        child: Text(
                          "🎯 Focus: $opt",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedPlantFocus = val);
                      }
                    },
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: "Clear History",
                onPressed: _messages.isNotEmpty ? _clearChat : null,
              ),
            ],
          ),
        ),

        // Quick Prompt Chips
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              _buildChip("What are primary indications?", theme),
              _buildChip("Safety & contraindications?", theme),
              _buildChip("Standard dosage & anupana?", theme),
              _buildChip("Active phytochemicals?", theme),
            ],
          ),
        ),

        // Chat Message List
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.forum_outlined,
                        size: 64,
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Ask any question about medicinal plants",
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Grounded in Medicinal Plants.csv knowledge base",
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, idx) {
                    final msg = _messages[idx];
                    final isUser = msg["role"] == "user";
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        mainAxisAlignment: isUser
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isUser) ...[
                            CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              child: const Text("🌿"),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                                  bottomRight: Radius.circular(isUser ? 4 : 16),
                                ),
                              ),
                              child: isUser
                                  ? SelectableText(
                                      msg["content"] ?? "",
                                      style: TextStyle(
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    )
                                  : MarkdownBody(
                                      data: msg["content"] ?? "",
                                      selectable: true,
                                      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                                        p: theme.textTheme.bodyMedium?.copyWith(
                                          height: 1.5,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                        h1: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                        h2: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                        h3: theme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                        strong: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                        listBullet: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Non-overflowing RAG Answer Loading Bar
        if (_isGenerating)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Searching RAG knowledge base & generating answer...",
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

        // Input Field Bar
        Container(
          padding: const EdgeInsets.all(12),
          color: theme.colorScheme.surface,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: "Type a question about $_selectedPlantFocus...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _isGenerating ? null : () => _sendMessage(),
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: () => _sendMessage(label),
        backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
      ),
    );
  }
}
