import 'package:flutter/material.dart';
import '../services/rag_service.dart';

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

class _ExplorerScreenState extends State<ExplorerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allPlants = widget.ragService.plants;

    final filteredPlants = allPlants.where((p) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.localName.toLowerCase().contains(q) ||
          p.scientificName.toLowerCase().contains(q) ||
          p.commonEnglishName.toLowerCase().contains(q) ||
          p.primaryIndications.toLowerCase().contains(q) ||
          p.activePhytochemicals.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // Search Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search name, indication, chemical...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = "");
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              filled: true,
            ),
            onChanged: (val) {
              setState(() => _searchQuery = val.trim());
            },
          ),
        ),

        // Count Banner
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Showing ${filteredPlants.length} of ${allPlants.length} species",
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.dataset, size: 18),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // List View of Dossiers
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredPlants.length,
            itemBuilder: (context, idx) {
              final plant = filteredPlants[idx];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: plant.isHighRisk
                        ? Colors.red.withValues(alpha: 0.2)
                        : theme.colorScheme.primaryContainer,
                    child: Text(
                      plant.isHighRisk ? "🌿" : "🌿",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  title: Text(
                    plant.localName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    "${plant.scientificName} • ${plant.commonEnglishName}",
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(context, "Family", plant.family),
                          _buildDetailRow(context, "Growth Habit", plant.growthHabit),
                          _buildDetailRow(
                              context, "Key Visuals", plant.keyVisualIdentifiers),
                          _buildDetailRow(
                              context, "Phytochemicals", plant.activePhytochemicals),
                          _buildDetailRow(
                              context, "Primary Indications", plant.primaryIndications),
                          _buildDetailRow(
                              context, "Preparation", plant.traditionalPreparationMethods),
                          _buildDetailRow(context, "Standard Dosage", plant.standardDosage),
                          _buildDetailRow(
                              context, "Safe Vehicle (Anupana)", plant.safeVehicle),
                          _buildDetailRow(context, "Toxicity Profile", plant.toxicityProfile,
                              isWarning: plant.isHighRisk),
                          _buildDetailRow(
                              context, "Contraindications", plant.contraindications),
                          _buildDetailRow(
                              context, "Adverse Reactions", plant.adverseReactions),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              widget.onSelectPlantForChat(plant.localName);
                            },
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: Text("Ask RAG Chat About ${plant.localName}"),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(42),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value,
      {bool isWarning = false}) {
    if (value.isEmpty) return const SizedBox();
    final theme = Theme.of(context);
    final defaultColor = theme.colorScheme.onSurface;
    final warningColor = theme.brightness == Brightness.dark
        ? Colors.redAccent.shade100
        : Colors.red.shade800;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: isWarning ? warningColor : defaultColor,
            fontSize: 13,
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: "$label: ",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
