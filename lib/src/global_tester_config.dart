import 'package:flutter_integration_test_utils/src/custom_tester.dart';

class GlobalTesterConfig {
  const GlobalTesterConfig({
    this.existsTimeout = const Duration(seconds: 10),
    this.visibleTimeout = const Duration(seconds: 10),
    this.settleTimeout = const Duration(seconds: 10),
    this.settlePolicy = SettlePolicy.trySettle,
    this.dragDuration = const Duration(milliseconds: 100),
    this.settleBetweenScrollsTimeout = const Duration(seconds: 5),
  });

  /// Time after which [CustomFinder.waitUntilExists] fails if it doesn't find
  /// an existing widget.
  ///
  /// If a widget exists, it doesn't mean that it is visible.
  ///
  /// On the other hand, if a widget is visible, then it always exists.
  final Duration existsTimeout;

  /// Time after which [CustomFinder.waitUntilVisible] fails if it doesn't find
  /// a visible widget.
  ///
  /// [CustomFinder.waitUntilVisible] is used internally by methods such as
  /// [CustomFinder.tap] and [CustomFinder.enterText].
  final Duration visibleTimeout;

  /// Time after which [CustomTester.pumpAndSettle] fails.
  ///
  /// [CustomFinder.waitUntilVisible] is used internally by methods such as
  /// [CustomFinder.tap] and [CustomFinder.enterText] (unless disabled by
  /// [settlePolicy]).
  final Duration settleTimeout;

  /// Defines which pump method should be called after actions such as
  /// [CustomTester.tap], [CustomTester.enterText], and [CustomFinder.scrollTo].
  ///
  /// See [SettlePolicy] for more information.
  final SettlePolicy settlePolicy;

  /// Time that it takes to perform drag gesture in scrolling methods,
  /// such as [CustomTester.scrollUntilVisible].
  final Duration dragDuration;

  /// Timeout used to settle in between drag gestures in scrolling methods,
  /// such as [CustomTester.scrollUntilVisible] (unless disabled by
  /// [settlePolicy]).
  final Duration settleBetweenScrollsTimeout;

  /// Creates a copy of this config but with the given fields replaced with the
  /// new values.
  GlobalTesterConfig copyWith({
    Duration? existsTimeout,
    Duration? visibleTimeout,
    Duration? settleTimeout,
    SettlePolicy? settlePolicy,
    Duration? dragDuration,
  }) {
    return GlobalTesterConfig(
      existsTimeout: existsTimeout ?? this.existsTimeout,
      visibleTimeout: visibleTimeout ?? this.visibleTimeout,
      settleTimeout: settleTimeout ?? this.settleTimeout,
      settlePolicy: settlePolicy ?? this.settlePolicy,
      dragDuration: dragDuration ?? this.dragDuration,
    );
  }
}
