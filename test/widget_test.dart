// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// TODO: Replace 'fashion' below with your actual package name from pubspec.yaml
// and 'MyApp' with your actual root widget class name (e.g. FashionApp).
import 'package:fashion/main.dart';

void main() {
  testWidgets('App builds and renders without crashing', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Just let the widget tree settle - no assumptions about counters
    // or specific text, since this app is not the default counter demo.
    await tester.pumpAndSettle();

    // Basic sanity check: MaterialApp should be present in the tree.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
