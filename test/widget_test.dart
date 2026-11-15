import 'package:flutter_test/flutter_test.dart';
import 'package:obratek_app/main.dart';

void main() {
  testWidgets('Obratek muestra la pantalla de acceso', (tester) async {
    await tester.pumpWidget(const ObratekApp());
    expect(find.text('Bienvenido a Obratek'), findsOneWidget);
  });
}
