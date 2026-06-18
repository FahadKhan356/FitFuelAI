import 'package:flutter_test/flutter_test.dart';
import 'package:fitfuel_ai/app.dart';

void main() {
  testWidgets('App renders splash screen', (tester) async {
    await tester.pumpWidget(const FitFuelApp());
    expect(find.text('FITFUEL AI'), findsOneWidget);
  });
}