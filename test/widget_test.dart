import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/main.dart';

void main() {
  testWidgets('Particle Dance app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const ParticleDanceApp());
    expect(find.text('PARTICLE DANCE'), findsOneWidget);
  });
}
