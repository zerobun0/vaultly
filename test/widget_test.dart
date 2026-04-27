import 'package:flutter_test/flutter_test.dart';

import 'package:vaultly/app.dart';

void main() {
  testWidgets('renders the Vaultly shell', (WidgetTester tester) async {
    await tester.pumpWidget(const VaultlyApp());

    expect(find.text('Vaultly'), findsOneWidget);
  });
}
