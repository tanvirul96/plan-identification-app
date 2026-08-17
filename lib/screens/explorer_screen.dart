import 'package:flutter/material.dart';
import '../models/plant_model.dart';
import '../services/rag_service.dart';
import '../widgets/neu_widgets.dart';

class ExplorerScreen extends StatefulWidget {
  final RagService ragService;
  final Function(String) onSelectPlantForChat;

  const ExplorerScreen({
    super.key,
    required this.ragService,
    required this.onSelectPlantForChat,
  });

  @override
  State<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends State<ExplorerScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final allPlants = widget.ragService.plants;
    final primary = NeuTheme.primaryColor(context);
    final onSurf = NeuTheme.onSurface(context);
    final subtle = NeuTheme.subtleText(context);

    final filteredPlants = allPlants.where((p) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.localName.toLowerCase().contains(q) ||
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
                    hintText: "Search species, indication, phytochemical...",
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
                    "Showing ${filteredPlants.length} of ${allPlants.length} species",
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
                      itemBuilder: (context, idx) => _buildPlantCard(filteredPlants[idx]),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 440,
                      ),
                      itemCount: filteredPlants.length,
                      itemBuilder: (context, idx) => _buildPlantGridCard(filteredPlants[idx]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Single Column Expandable Card (Mobile) ──

  Widget _buildPlantCard(PlantRecord plant) {
    final primary = NeuTheme.primaryColor(context);
    final onSurf = NeuTheme.onSurface(context);
    final subtle = NeuTheme.subtleText(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: NeuContainer(
        borderRadius: 22,
        padding: EdgeInsets.zero,
        child: Material(
          type: MaterialType.transparency,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            leading: NeuContainer(
              borderRadius: 16,
              padding: const EdgeInsets.all(8),
              blurRadius: 6,
              offset: const Offset(2, 2),
              child: Text(
                plant.isHighRisk ? "⚠️" : "🌿",
                style: const TextStyle(fontSize: 16),
              ),
            ),
            title: Text(
              plant.localName,
              style: TextStyle(fontWeight: FontWeight.w700, color: onSurf, fontSize: 15),
            ),
            subtitle: Text(
              "${plant.scientificName} • ${plant.commonEnglishName}",
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: subtle),
            ),
            children: [
              _buildDetailRow("Family", plant.family),
              _buildDetailRow("Growth Habit", plant.growthHabit),
              _buildDetailRow("Key Visuals", plant.keyVisualIdentifiers),
              _buildDetailRow("Phytochemicals", plant.activePhytochemicals),
              _buildDetailRow("Indications", plant.primaryIndications),
              _buildDetailRow("Preparation", plant.traditionalPreparationMethods),
              _buildDetailRow("Standard Dosage", plant.standardDosage),
              _buildDetailRow("Anupana", plant.safeVehicle),
              _buildDetailRow("Toxicity", plant.toxicityProfile, isWarning: plant.isHighRisk),
              _buildDetailRow("Contraindications", plant.contraindications),
              _buildDetailRow("Adverse Reactions", plant.adverseReactions),
              const SizedBox(height: 14),
              NeuButton(
                onPressed: () => widget.onSelectPlantForChat(plant.localName),
                borderRadius: 14,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 16, color: primary),
                    const SizedBox(width: 8),
                    Text(
                      "Chat About ${plant.localName}",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: onSurf),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  // ── Grid Card (Desktop / Tablet) ──

  Widget _buildPlantGridCard(PlantRecord plant) {
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
              NeuContainer(
                borderRadius: 14,
                padding: const EdgeInsets.all(8),
                blurRadius: 6,
                offset: const Offset(2, 2),
                child: Text(
                  plant.isHighRisk ? "⚠️" : "🌿",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.localName,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: onSurf),
                      overflow: TextOverflow.ellipsis,
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
                  _buildDetailRow("Family", plant.family),
                  _buildDetailRow("Indications", plant.primaryIndications),
                  _buildDetailRow("Phytochemicals", plant.activePhytochemicals),
                  _buildDetailRow("Preparation", "${plant.traditionalPreparationMethods} (${plant.standardDosage})"),
                  _buildDetailRow("Toxicity", plant.toxicityProfile, isWarning: plant.isHighRisk),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          NeuButton(
            onPressed: () => widget.onSelectPlantForChat(plant.localName),
            borderRadius: 14,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 16, color: primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    "Chat About ${plant.localName}",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: onSurf),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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
