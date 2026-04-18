import 'package:flutter_test/flutter_test.dart';
import 'package:yu_ni_player_example/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const YuNiPlayerExampleApp());
    expect(find.text('YuNiPlayer 功能验证'), findsOneWidget);
  });
}
