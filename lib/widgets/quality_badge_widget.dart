import 'package:flutter/material.dart';
import '../services/image_quality_service.dart';
import '../services/localization_service.dart';
import 'neu_widgets.dart';

class QualityBadgeWidget extends StatelessWidget {
  final QualityAssessment assessment;
  final VoidCallback? onRetake;
  final VoidCallback? onCrop;

  const QualityBadgeWidget({
    super.key,
    required this.assessment,
    this.onRetake,
    this.onCrop,
  });

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService();
    final isBn = loc.isBangla;

    Color badgeColor;
    IconData icon;

    switch (assessment.tier) {
      case QualityTier.excellent:
        badgeColor = const Color(0xFF2E7D32);
        icon = Icons.verified;
        break;
      case QualityTier.good:
        badgeColor = const Color(0xFF43A047);
        icon = Icons.check_circle_outline;
        break;
      case QualityTier.fair:
        badgeColor = Colors.orange.shade700;
        icon = Icons.info_outline;
        break;
      case QualityTier.poor:
        badgeColor = Colors.red.shade700;
        icon = Icons.warning_amber_rounded;
        break;
    }

    final suggestions =
        isBn ? assessment.suggestionsBn : assessment.suggestionsEn;

    return NeuContainer(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: badgeColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isBn ? assessment.statusBn : assessment.statusEn,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: badgeColor,
                  ),
                ),
              ),
              NeuContainer(
                isPressed: true,
                borderRadius: 12,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                blurRadius: 4,
                child: Text(
                  "${assessment.score}/100",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...suggestions.map((s) => Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("• ",
                          style: TextStyle(
                              color: badgeColor, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          s,
                          style: TextStyle(
                            fontSize: 11,
                            color: NeuTheme.subtleText(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
