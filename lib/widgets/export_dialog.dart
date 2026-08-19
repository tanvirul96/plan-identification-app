import 'package:flutter/material.dart';
import '../services/export_service.dart';
import '../services/localization_service.dart';
import 'neu_widgets.dart';

class ExportDialog extends StatelessWidget {
  final String title;
  final String plantName;
  final String content;

  const ExportDialog({
    super.key,
    required this.title,
    required this.plantName,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService();
    final isBn = loc.isBangla;
    final primary = NeuTheme.primaryColor(context);
    final onSurf = NeuTheme.onSurface(context);

    final formattedText = ExportService.formatForSharing(
      title: title,
      plantName: plantName,
      content: content,
    );

    return Dialog(
      backgroundColor: NeuTheme.surfaceColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.share, color: primary, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      isBn ? "রিপোর্ট এক্সপোর্ট ও শেয়ার" : "Export Clinical Report",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: onSurf,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Formatted Preview
            Expanded(
              child: NeuInsetContainer(
                borderRadius: 16,
                padding: const EdgeInsets.all(14),
                child: SingleChildScrollView(
                  child: SelectableText(
                    formattedText,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      height: 1.45,
                      color: onSurf,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Copy to Clipboard Action
            NeuButton(
              onPressed: () async {
                await ExportService.copyToClipboard(formattedText);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.green.shade800,
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            isBn
                                ? "ক্লিপবোর্ডে কপি করা হয়েছে!"
                                : "Report copied to clipboard!",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.copy, size: 18, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    isBn ? "ক্লিপবোর্ডে কপি করুন" : "Copy to Clipboard",
                    style: TextStyle(fontWeight: FontWeight.bold, color: onSurf),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
