import 'package:flutter_test/flutter_test.dart';
import 'package:moodora/app.dart';
import 'package:moodora/core/constants/app_constants.dart';

void main() {
  testWidgets('Moodora smoke test initializes app', (WidgetTester tester) async {
    await tester.pumpWidget(const MoodoraApp());

    // Verify app brand is present
    expect(find.text(AppConstants.appName), findsWidgets);
  });
}
