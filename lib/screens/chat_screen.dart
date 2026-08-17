import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/rag_service.dart';
import '../widgets/neu_widgets.dart';

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

class _ChatScreenState extends State<ChatScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isGenerating = false;
  late String _selectedPlantFocus;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedPlantFocus = widget.activePlant ?? "🌐 All 16 Medicinal Plants";
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activePlant != null && widget.activePlant != oldWidget.activePlant) {
      setState(() => _selectedPlantFocus = widget.activePlant!);
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

  void _clearChat() => setState(() => _messages.clear());

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isWide = MediaQuery.of(context).size.width >= 800;
    final primary = NeuTheme.primaryColor(context);
    final onSurf = NeuTheme.onSurface(context);
    final subtle = NeuTheme.subtleText(context);
    final plantOptions = ["🌐 All 16 Medicinal Plants"] +
        widget.ragService.plants.map((p) => p.localName).toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Column(
          children: [
            // ── Top Bar: Plant Selector ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: NeuInsetContainer(
                borderRadius: 18,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.filter_alt_outlined, color: primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: plantOptions.contains(_selectedPlantFocus)
                              ? _selectedPlantFocus
                              : plantOptions.first,
                          isExpanded: true,
                          dropdownColor: NeuTheme.surfaceColor(context),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: onSurf,
                          ),
                          items: plantOptions.map((opt) {
                            return DropdownMenuItem(
                              value: opt,
                              child: Text(opt, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedPlantFocus = val);
                          },
                        ),
                      ),
                    ),
                    NeuIconButton(
                      icon: Icons.delete_outline,
                      onPressed: _messages.isNotEmpty ? _clearChat : null,
                      size: 38,
                      iconColor: _messages.isNotEmpty ? Colors.redAccent : subtle,
                      tooltip: "Clear History",
                    ),
                  ],
                ),
              ),
            ),

            // ── Quick Prompt Chips ──
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  _buildNeuChip("What are primary indications?"),
                  _buildNeuChip("Safety & contraindications?"),
                  _buildNeuChip("Standard dosage & anupana?"),
                  _buildNeuChip("Active phytochemicals?"),
                ],
              ),
            ),

            // ── Chat Message List ──
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            NeuContainer(
                              borderRadius: 40,
                              padding: const EdgeInsets.all(24),
                              blurRadius: 20,
                              child: Icon(Icons.forum_outlined, size: 48, color: primary.withValues(alpha: 0.5)),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Ask about medicinal plants",
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: primary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Grounded in verified botanical & pharmacological knowledge base",
                              style: TextStyle(fontSize: 13, color: subtle),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
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
                          padding: const EdgeInsets.only(bottom: 14.0),
                          child: Row(
                            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isUser) ...[
                                NeuContainer(
                                  borderRadius: 20,
                                  padding: const EdgeInsets.all(8),
                                  blurRadius: 6,
                                  offset: const Offset(2, 2),
                                  child: const Text("🌿", style: TextStyle(fontSize: 16)),
                                ),
                                const SizedBox(width: 10),
                              ],
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isWide ? 680 : MediaQuery.of(context).size.width * 0.78,
                                ),
                                child: NeuContainer(
                                  isPressed: isUser,
                                  borderRadius: 18,
                                  padding: const EdgeInsets.all(14),
                                  blurRadius: isUser ? 8 : 14,
                                  offset: const Offset(4, 4),
                                  color: isUser
                                      ? NeuTheme.primaryColor(context).withValues(alpha: 0.12)
                                      : null,
                                  child: isUser
                                      ? SelectableText(
                                          msg["content"] ?? "",
                                          style: TextStyle(color: onSurf, fontSize: 14),
                                        )
                                      : MarkdownBody(
                                          data: msg["content"] ?? "",
                                          selectable: true,
                                          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                                            p: TextStyle(height: 1.5, fontSize: 14, color: onSurf),
                                            h1: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primary),
                                            h2: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primary),
                                            h3: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primary),
                                            strong: TextStyle(fontWeight: FontWeight.bold, color: onSurf),
                                            listBullet: TextStyle(fontWeight: FontWeight.bold, color: primary),
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

            // ── Loading Indicator ──
            if (_isGenerating)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: NeuInsetContainer(
                  borderRadius: 14,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: primary)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Searching RAG knowledge base...",
                          style: TextStyle(fontSize: 12, color: subtle),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Input Field ──
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: NeuInsetContainer(
                      borderRadius: 22,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: "Ask about $_selectedPlantFocus...",
                          hintStyle: TextStyle(color: subtle, fontSize: 13),
                          border: InputBorder.none,
                        ),
                        style: TextStyle(color: onSurf, fontSize: 14),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  NeuIconButton(
                    icon: Icons.send,
                    onPressed: _isGenerating ? null : () => _sendMessage(),
                    iconColor: _isGenerating ? subtle : primary,
                    size: 48,
                    tooltip: "Send",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeuChip(String label) {
    final primary = NeuTheme.primaryColor(context);
    final onSurf = NeuTheme.onSurface(context);

    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: GestureDetector(
        onTap: () => _sendMessage(label),
        child: NeuContainer(
          borderRadius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          blurRadius: 8,
          offset: const Offset(3, 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt, size: 14, color: primary),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: onSurf)),
            ],
          ),
        ),
      ),
    );
  }
}
