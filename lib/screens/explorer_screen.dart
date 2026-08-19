import 'package:flutter/material.dart';
import '../models/plant_model.dart';
import '../services/localization_service.dart';
import '../services/rag_service.dart';
import '../widgets/neu_widgets.dart';

class ExplorerScreen extends StatefulWidget {
  final RagService ragService;
  final Function(String) onSelectPlantForChat;
  final Function(String)? onSelectPlantForClinical;

  const ExplorerScreen({
    super.key,
    required this.ragService,
    required this.onSelectPlantForChat,
    this.onSelectPlantForClinical,
  });

  @override
  State<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends State<ExplorerScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final LocalizationService _loc = LocalizationService();
  String _searchQuery = "";
  final Set<String> _expandedPlantNames = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final allPlants = widget.ragService.plants;
    final primary = NeuTheme.primaryColor(context);
    final onSurf = NeuTheme.onSurface(context);
    final subtle = NeuTheme.subtleText(context);
    final isBn = _loc.isBangla;

    final filteredPlants = allPlants.where((p) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final bnName = _loc.getPlantDisplayName(p.localName).toLowerCase();
      return p.localName.toLowerCase().contains(q) ||
          bnName.contains(q) ||
          p.scientificName.toLowerCase().contains(q) ||
          p.commonEnglishName.toLowerCase().contains(q) ||
          p.primaryIndications.toLowerCase().contains(q) ||
          p.activePhytochemicals.toLowerCase().contains(q);
    }).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth >= 800 ? 2 : 1;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          children: [
            // ── Search Bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: NeuInsetContainer(
                borderRadius: 20,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: isBn
                        ? "প্রজাতির নাম, রোগ নিরাময়, রাসায়নিক খুঁজুন..."
                        : "Search species, indication, phytochemical...",
                    hintStyle: TextStyle(color: subtle, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: primary, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: subtle, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = "");
                            },
                          )
                        : null,
                    border: InputBorder.none,
                  ),
                  style: TextStyle(color: onSurf, fontSize: 14),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
              ),
            ),

            // ── Count Banner ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isBn
                        ? "মোট ${allPlants.length}টির মধ্যে ${filteredPlants.length}টি প্রজাতি প্রদর্শিত"
                        : "Showing ${filteredPlants.length} of ${allPlants.length} species",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: primary),
                  ),
                  Icon(Icons.dataset, size: 18, color: subtle),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // ── Responsive Plant Cards ──
            Expanded(
              child: crossAxisCount == 1
                  ? ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredPlants.length,
                      itemBuilder: (context, idx) => _buildPlantCard(filteredPlants[idx], isBn),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 470,
                      ),
                      itemCount: filteredPlants.length,
                      itemBuilder: (context, idx) => _buildPlantGridCard(filteredPlants[idx], isBn),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Single Column Expandable Card (Mobile) ──

  Widget _buildPlantCard(PlantRecord plant, bool isBn) {
    final primary = NeuTheme.primaryColor(context);
    final onSurf = NeuTheme.onSurface(context);
    final subtle = NeuTheme.subtleText(context);
    final bool isExpanded = _expandedPlantNames.contains(plant.localName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: NeuContainer(
        borderRadius: 22,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clickable Header Tile
            InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedPlantNames.remove(plant.localName);
                  } else {
                    _expandedPlantNames.add(plant.localName);
                  }
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  // Unified Plant Icon (🌿 for ALL items)
                  NeuContainer(
                    borderRadius: 14,
                    padding: const EdgeInsets.all(8),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                    child: const Text(
                      "🌿",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Plant Local & Scientific Names
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _loc.getPlantDisplayName(plant.localName),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: onSurf,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (plant.isHighRisk)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                margin: const EdgeInsets.only(left: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade900.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isBn ? "⚠️ সতর্কতা" : "⚠️ Caution",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${plant.scientificName} • ${plant.commonEnglishName}",
                          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: subtle),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Chevron indicator
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: subtle,
                    size: 22,
                  ),
                ],
              ),
            ),

            // Expanded Details Section
            if (isExpanded) ...[
              Divider(height: 24, color: NeuTheme.shadowDark(context).withValues(alpha: 0.2)),
              _buildDetailRow(isBn ? "গোত্র" : "Family", plant.family),
              _buildDetailRow(isBn ? "আবাস" : "Growth Habit", plant.growthHabit),
              _buildDetailRow(isBn ? "চেনার উপায়" : "Key Visuals", plant.keyVisualIdentifiers),
              _buildDetailRow(isBn ? "রাসায়নিক" : "Phytochemicals", plant.activePhytochemicals),
              _buildDetailRow(isBn ? "রোগ নিরাময়" : "Indications", plant.primaryIndications),
              _buildDetailRow(isBn ? "প্রস্তুতি" : "Preparation", plant.traditionalPreparationMethods),
              _buildDetailRow(isBn ? "মাত্রা" : "Standard Dosage", plant.standardDosage),
              _buildDetailRow(isBn ? "অনুপান" : "Anupana", plant.safeVehicle),
              _buildDetailRow(isBn ? "বিষাক্ততা" : "Toxicity", plant.toxicityProfile, isWarning: plant.isHighRisk),
              _buildDetailRow(isBn ? "ব্যবহার নিষেধ" : "Contraindications", plant.contraindications),
              _buildDetailRow(isBn ? "পার্শ্বপ্রতিক্রিয়া" : "Adverse Reactions", plant.adverseReactions),
              const SizedBox(height: 14),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: NeuButton(
                      onPressed: () => widget.onSelectPlantForChat(plant.localName),
                      borderRadius: 14,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 16, color: primary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              isBn ? "RAG চ্যাট" : "Ask RAG",
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: onSurf),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.onSelectPlantForClinical != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: NeuButton(
                        onPressed: () => widget.onSelectPlantForClinical!(plant.localName),
                        borderRadius: 14,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calculate_outlined, size: 16, color: primary),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                isBn ? "মাত্রা ক্যালকুলেটর" : "Dose Calc",
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: onSurf),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Grid Card (Desktop / Tablet) ──

  Widget _buildPlantGridCard(PlantRecord plant, bool isBn) {
    final primary = NeuTheme.primaryColor(context);
    final onSurf = NeuTheme.onSurface(context);
    final subtle = NeuTheme.subtleText(context);

    return NeuContainer(
      borderRadius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Unified Plant Icon (🌿 for ALL items)
              NeuContainer(
                borderRadius: 14,
                padding: const EdgeInsets.all(8),
                blurRadius: 4,
                offset: const Offset(2, 2),
                child: const Text(
                  "🌿",
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _loc.getPlantDisplayName(plant.localName),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: onSurf),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (plant.isHighRisk)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade900.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isBn ? "⚠️ সতর্কতা" : "⚠️ Caution",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      "${plant.scientificName} • ${plant.commonEnglishName}",
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: subtle),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: 20, color: NeuTheme.shadowDark(context).withValues(alpha: 0.15)),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(isBn ? "গোত্র" : "Family", plant.family),
                  _buildDetailRow(isBn ? "রোগ নিরাময়" : "Indications", plant.primaryIndications),
                  _buildDetailRow(isBn ? "রাসায়নিক" : "Phytochemicals", plant.activePhytochemicals),
                  _buildDetailRow(isBn ? "মাত্রা ও প্রস্তুত" : "Preparation",
                      "${plant.traditionalPreparationMethods} (${plant.standardDosage})"),
                  _buildDetailRow(isBn ? "নিরাপত্তা" : "Toxicity", plant.toxicityProfile,
                      isWarning: plant.isHighRisk),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: NeuButton(
                  onPressed: () => widget.onSelectPlantForChat(plant.localName),
                  borderRadius: 14,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 15, color: primary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isBn ? "RAG চ্যাট" : "Ask RAG",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: onSurf),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.onSelectPlantForClinical != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: NeuButton(
                    onPressed: () => widget.onSelectPlantForClinical!(plant.localName),
                    borderRadius: 14,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calculate_outlined, size: 15, color: primary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            isBn ? "মাত্রা" : "Dosage",
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: onSurf),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isWarning = false}) {
    if (value.isEmpty) return const SizedBox();
    final primary = NeuTheme.primaryColor(context);
    final onSurf = NeuTheme.onSurface(context);
    final warningColor = NeuTheme.isDark(context) ? Colors.redAccent.shade100 : Colors.red.shade800;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: isWarning ? warningColor : onSurf,
            fontSize: 13,
            height: 1.35,
          ),
          children: [
            TextSpan(
              text: "$label: ",
              style: TextStyle(fontWeight: FontWeight.bold, color: primary),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
