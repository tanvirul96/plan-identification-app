import 'package:flutter_test/flutter_test.dart';
import 'package:plant_identification/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PlantIdentificationApp());
    expect(find.textContaining('Medicinal Plant'), findsWidgets);
  });
}
