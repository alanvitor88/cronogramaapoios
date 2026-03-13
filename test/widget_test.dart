import 'package:flutter_test/flutter_test.dart';
import 'package:apoio_crono/main.dart';

void main() {
  testWidgets('App carrega sem erros', (WidgetTester tester) async {
    await tester.pumpWidget(const ApoioCronoApp());
    expect(find.text('Apoio Crono'), findsOneWidget);
  });
}
