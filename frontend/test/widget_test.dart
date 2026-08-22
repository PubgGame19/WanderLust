import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanderlust_ai/main.dart';

void main() {
  testWidgets('WanderlustApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: WanderlustApp(hasSeenOnboarding: true),
      ),
    );
    expect(find.byType(WanderlustApp), findsOneWidget);
  });
}
