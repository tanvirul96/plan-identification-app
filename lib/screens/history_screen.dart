import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/scan_record.dart';
import '../services/history_service.dart';
import '../services/localization_service.dart';
import '../widgets/neu_widgets.dart';

class HistoryScreen extends StatefulWidget {
  final Function(String plantName)? onSelectPlantForChat;

  const HistoryScreen({
    super.key,
    this.onSelectPlantForChat,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with AutomaticKeepAliveClientMixin {
  final HistoryService _historyService = HistoryService();
  final LocalizationService _loc = LocalizationService();
  bool _onlyBookmarks = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _historyService.loadScans();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final primary = NeuTheme.primaryColor(context);
    final onSurf = NeuTheme.onSurface(context);
    final isBn = _loc.isBangla;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          children: [
            // Top Filter & Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Filter: All vs Bookmarks
                      Expanded(
                        child: Row(
                          children: [
                            _buildFilterTab(
                              title: isBn ? "সকল স্ক্যান" : "All Scans",
                              isSelected: !_onlyBookmarks,
                              onTap: () => setState(() => _onlyBookmarks = false),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterTab(
                              title: isBn ? "⭐ সংরক্ষিত" : "⭐ Bookmarks",
                              isSelected: _onlyBookmarks,
                              onTap: () => setState(() => _onlyBookmarks = true),
                            ),
                          ],
                        ),
                      ),
                      if (_historyService.scansNotifier.value.isNotEmpty)
                        NeuIconButton(
                          icon: Icons.delete_sweep,
                          iconColor: Colors.redAccent,
                          tooltip: isBn ? "সব মুছুন" : "Clear All History",
                          size: 38,
                          onPressed: () => _confirmClearAll(context, isBn),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Search Field
                  NeuInsetContainer(
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: isBn ? "স্ক্যান করা প্রজাতি খুঁজুন..." : "Filter scans by species name...",
                        hintStyle: TextStyle(fontSize: 12, color: NeuTheme.subtleText(context)),
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search, size: 18, color: primary),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = "");
                                },
                              )
                            : null,
                      ),
                      style: TextStyle(fontSize: 13, color: onSurf),
                      onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                    ),
                  ),
                ],
              ),
            ),

            // Scan List View
            Expanded(
              child: ValueListenableBuilder<List<ScanRecord>>(
                valueListenable: _historyService.scansNotifier,
                builder: (context, scans, _) {
                  var filtered = scans;
                  if (_onlyBookmarks) {
                    filtered = filtered.where((s) => s.isBookmarked).toList();
                  }
                  if (_searchQuery.isNotEmpty) {
                    filtered = filtered
                        .where((s) =>
                            s.plantName.toLowerCase().contains(_searchQuery) ||
                            _loc.getPlantDisplayName(s.plantName).toLowerCase().contains(_searchQuery))
                        .toList();
                  }

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _onlyBookmarks ? Icons.bookmark_border : Icons.history,
                              size: 54,
                              color: primary.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _onlyBookmarks
                                  ? (isBn ? "কোনো সংরক্ষিত স্ক্যান নেই" : "No Bookmarked Scans Yet")
                                  : (isBn ? "কোনো স্ক্যানের ইতিহাস নেই" : "No Scan History Yet"),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: onSurf),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isBn
                                  ? "শনাক্তকরণ ট্যাবে পাতার ছবি তুলে স্ক্যান করুন।"
                                  : "Identify leaves to build your clinical botanical history.",
                              style: TextStyle(fontSize: 12, color: NeuTheme.subtleText(context)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final scan = filtered[idx];
                      return _buildScanCard(scan, isBn, primary, onSurf);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final primary = NeuTheme.primaryColor(context);
    return GestureDetector(
      onTap: onTap,
      child: NeuContainer(
        isPressed: isSelected,
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        blurRadius: 4,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? primary : NeuTheme.onSurface(context),
          ),
        ),
      ),
    );
  }

  Widget _buildScanCard(ScanRecord scan, bool isBn, Color primary, Color onSurf) {
    final formattedDate = "${scan.timestamp.year}-${scan.timestamp.month.toString().padLeft(2, '0')}-${scan.timestamp.day.toString().padLeft(2, '0')} ${scan.timestamp.hour.toString().padLeft(2, '0')}:${scan.timestamp.minute.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: NeuContainer(
        borderRadius: 20,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 65,
                height: 65,
                color: primary.withValues(alpha: 0.1),
                child: scan.imageBase64 != null && scan.imageBase64!.isNotEmpty
                    ? Image.memory(
                        base64Decode(scan.imageBase64!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.eco, size: 28, color: Colors.green),
                      )
                    : const Icon(Icons.eco, size: 28, color: Colors.green),
              ),
            ),
            const SizedBox(width: 14),

            // Scan Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _loc.getPlantDisplayName(scan.plantName),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: onSurf,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      NeuContainer(
                        isPressed: true,
                        borderRadius: 10,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        blurRadius: 2,
                        child: Text(
                          "${scan.confidence.toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${scan.modelName} • $formattedDate",
                    style: TextStyle(
                      fontSize: 11,
                      color: NeuTheme.subtleText(context),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Actions: Bookmark & Chat
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _historyService.toggleBookmark(scan.id),
                        child: Row(
                          children: [
                            Icon(
                              scan.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              size: 16,
                              color: scan.isBookmarked ? Colors.amber.shade700 : NeuTheme.subtleText(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              scan.isBookmarked ? (isBn ? "সংরক্ষিত" : "Saved") : (isBn ? "সংরক্ষণ" : "Save"),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: scan.isBookmarked ? Colors.amber.shade800 : NeuTheme.subtleText(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (widget.onSelectPlantForChat != null)
                        GestureDetector(
                          onTap: () => widget.onSelectPlantForChat!(scan.plantName),
                          child: Row(
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 15, color: primary),
                              const SizedBox(width: 4),
                              Text(
                                isBn ? "চ্যাট করুন" : "Ask RAG",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16),
                        color: Colors.redAccent.shade200,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _historyService.deleteScan(scan.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearAll(BuildContext context, bool isBn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeuTheme.surfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isBn ? "ইতিহাস মুছবেন?" : "Clear All History?"),
        content: Text(
          isBn
              ? "আপনি কি সমস্ত স্ক্যানের ইতিহাস মুছে ফেলতে চান?"
              : "Are you sure you want to permanently delete all scan records?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isBn ? "বাতিল" : "Cancel"),
          ),
          TextButton(
            onPressed: () {
              _historyService.clearAll();
              Navigator.of(ctx).pop();
            },
            child: Text(isBn ? "মুছে ফেলুন" : "Delete", style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
