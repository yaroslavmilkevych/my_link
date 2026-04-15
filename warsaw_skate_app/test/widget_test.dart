import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:warsaw_skate_app/src/app.dart';

void main() {
  testWidgets('renders Warsaw skate planner shell', (WidgetTester tester) async {
    await tester.pumpWidget(const WarsawSkateApp());
    await tester.pump();

    expect(
      find.byIcon(Icons.filter_alt_outlined),
      findsOneWidget,
    );
    expect(
      find.byIcon(Icons.add),
      findsOneWidget,
    );
  });
}
