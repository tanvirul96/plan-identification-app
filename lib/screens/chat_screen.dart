import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/localization_service.dart';
import '../services/rag_service.dart';
import '../widgets/botanical_loader.dart';
import '../widgets/export_dialog.dart';
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
  final LocalizationService _loc = LocalizationService();

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

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _exportChat() {
    if (_messages.isEmpty) return;
    final buffer = StringBuffer();
    for (var m in _messages) {
      final role = m['role'] == 'user' ? '👤 User' : '🌿 RAG Assistant';
      buffer.writeln('### $role:');
      buffer.writeln('${m['content']}\n');
    }

    showDialog(
      context: context,
      builder: (ctx) => ExportDialog(
        title: "RAG Clinical Consultation Transcript",
        plantName: _selectedPlantFocus,
        content: buffer.toString(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 800;
    final primary = NeuTheme.primaryColor(context);
    final onSurf = NeuTheme.onSurface(context);
    final subtle = NeuTheme.subtleText(context);
    final isBn = _loc.isBangla;

    final plantOptions = ["🌐 All 16 Medicinal Plants"] +
        widget.ragService.plants.map((p) => p.localName).toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Column(
          children: [
            // ── Top Bar: Plant Selector & Actions ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: NeuInsetContainer(
                borderRadius: 18,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.filter_alt_outlined, color: primary, size: 20),
                    const SizedBox(width: 8),
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
                            final label = opt == "🌐 All 16 Medicinal Plants"
                                ? (isBn ? "🌐 সকল ১৬টি ঔষধি উদ্ভিদ" : "🌐 All 16 Medicinal Plants")
                                : _loc.getPlantDisplayName(opt);
                            return DropdownMenuItem(
                              value: opt,
                              child: Text(label, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedPlantFocus = val);
                          },
                        ),
                      ),
                    ),
                    if (_messages.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      NeuIconButton(
                        icon: Icons.share,
                        size: 34,
                        iconColor: primary,
                        tooltip: isBn ? "চ্যাট এক্সপোর্ট" : "Export Transcript",
                        onPressed: _exportChat,
                      ),
                      const SizedBox(width: 4),
                      NeuIconButton(
                        icon: Icons.delete_outline,
                        onPressed: _clearChat,
                        size: 34,
                        iconColor: Colors.redAccent,
                        tooltip: isBn ? "ইতিহাস মুছুন" : "Clear History",
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Quick Prompt Chips ──
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                children: [
                  _buildNeuChip(isBn ? "প্রধান ব্যবহার ও রোগ নিরাময় কী?" : "What are primary indications?"),
                  _buildNeuChip(isBn ? "নিরাপত্তা ও পার্শ্বপ্রতিক্রিয়া?" : "Safety & contraindications?"),
                  _buildNeuChip(isBn ? "সঠিক মাত্রা ও অনুপান?" : "Standard dosage & anupana?"),
                  _buildNeuChip(isBn ? "সক্রিয় ফাইটোকেমিক্যালস?" : "Active phytochemicals?"),
                ],
              ),
            ),

            // ── Chat Message List ──
            Expanded(
              child: _messages.isEmpty && !_isGenerating
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            NeuContainer(
                              borderRadius: 40,
                              padding: const EdgeInsets.all(24),
                              blurRadius: 20,
                              child: Icon(Icons.forum_outlined, size: 44, color: primary.withAlpha(140)),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isBn ? "ভেষজ উদ্ভিদ সম্পর্কে যেকোনো প্রশ্ন করুন" : "Ask about medicinal plants",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: primary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isBn
                                  ? "১০০% লোকাল ভেক্টর ডাটাবেস ও এআই দ্বারা সমর্থিত"
                                  : "Grounded in verified botanical & pharmacological vector database",
                              style: TextStyle(fontSize: 12, color: subtle),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length + (_isGenerating ? 1 : 0),
                      itemBuilder: (context, idx) {
                        // Dynamic Assistant Response Loading Card
                        if (idx == _messages.length && _isGenerating) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                NeuContainer(
                                  borderRadius: 16,
                                  padding: const EdgeInsets.all(8),
                                  blurRadius: 6,
                                  offset: const Offset(2, 2),
                                  child: const Text("🌿", style: TextStyle(fontSize: 16)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: BotanicalThinkingCard(
                                    statusText: isBn
                                        ? "ভেক্টর নলেজবেস ও এআই দ্বারা উত্তর তৈরি হচ্ছে..."
                                        : "Searching RAG vector knowledge base & generating response...",
                                    isBangla: isBn,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final msg = _messages[idx];
                        final isUser = msg["role"] == "user";
                        final maxBubbleWidth = isWide
                            ? 680.0
                            : math.max(160.0, screenWidth - (isUser ? 60.0 : 96.0));

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14.0),
                          child: Row(
                            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isUser) ...[
                                NeuContainer(
                                  borderRadius: 16,
                                  padding: const EdgeInsets.all(8),
                                  blurRadius: 6,
                                  offset: const Offset(2, 2),
                                  child: const Text("🌿", style: TextStyle(fontSize: 16)),
                                ),
                                const SizedBox(width: 10),
                              ],
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                                child: NeuContainer(
                                  isPressed: isUser,
                                  borderRadius: 18,
                                  padding: const EdgeInsets.all(14),
                                  blurRadius: isUser ? 6 : 12,
                                  offset: const Offset(3, 3),
                                  color: isUser
                                      ? primary.withAlpha(28)
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
                                            h1: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: primary),
                                            h2: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primary),
                                            h3: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primary),
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

            // ── Input Field ──
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: NeuInsetContainer(
                        borderRadius: 22,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        child: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: isBn
                                ? "${_loc.getPlantDisplayName(_selectedPlantFocus)} সম্পর্কে প্রশ্ন লিখুন..."
                                : "Ask about $_selectedPlantFocus...",
                            hintStyle: TextStyle(color: subtle, fontSize: 13),
                            border: InputBorder.none,
                          ),
                          style: TextStyle(color: onSurf, fontSize: 14),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    NeuIconButton(
                      icon: Icons.send,
                      onPressed: _isGenerating ? null : () => _sendMessage(),
                      iconColor: _isGenerating ? subtle : primary,
                      size: 44,
                      tooltip: isBn ? "পাঠান" : "Send",
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

  Widget _buildNeuChip(String label) {
    final primary = NeuTheme.primaryColor(context);
    final onSurf = NeuTheme.onSurface(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () => _sendMessage(label),
        child: NeuContainer(
          borderRadius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          blurRadius: 6,
          offset: const Offset(2, 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt, size: 14, color: primary),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: onSurf),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
