import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ehsan_pathways/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: EhsanPathwaysApp()),
    );
    // Verify the app launches
    expect(find.text('Ehsan Pathways'), findsAny);
  });
}
