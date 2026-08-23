import 'package:flutter_test/flutter_test.dart';
import 'package:playergo/app.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const PlayerGoApp());
    expect(find.text('PlayerGo'), findsOneWidget);
  });
}
