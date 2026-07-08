// Basic smoke test for the Just The Crumbs app shell.
//
// Firebase is initialized in main(), which requires platform channels not
// available under `flutter test`. This test just verifies a widget tree
// builds; integration testing happens on-device.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MaterialApp builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('🥐 Just The Crumbs'))),
    );
    expect(find.text('🥐 Just The Crumbs'), findsOneWidget);
  });
}
