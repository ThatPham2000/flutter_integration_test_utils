import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_integration_test_utils/flutter_integration_test_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Main Test nè', (tester) async {
    final $ = CustomTester(tester: tester, config: const GlobalTesterConfig());
    await $.pumpWidgetAndSettle(const MyApp());

    for (int i = 1; i <= 10; i++) {
      await $(Icons.add).tap();
    }

    await $('100').waitUntilVisible();
  });
}
