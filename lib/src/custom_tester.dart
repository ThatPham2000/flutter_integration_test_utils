import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_integration_test_utils/src/custom_finder.dart';
import 'package:flutter_integration_test_utils/src/exception.dart';
import 'package:flutter_integration_test_utils/src/global_tester_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// Default amount to drag by when scrolling.
const defaultScrollDelta = 64.0;

/// Default maximum number of drags during scrolling.
const defaultScrollMaxIteration = 15;

class CustomTester {
  const CustomTester({required this.tester, required this.config});

  final GlobalTesterConfig config;
  final WidgetTester tester;

  CustomFinder call(dynamic matching) {
    return CustomFinder.resolve(
      matching: matching,
      tester: this,
      parentFinder: null,
    );
  }

  Future<void> pumpWidget(
    Widget widget, [
    Duration? duration,
    EnginePhase phase = EnginePhase.sendSemanticsUpdate,
  ]) =>
      tester.pumpWidget(widget, duration, phase);

  Future<void> pump([
    Duration? duration,
    EnginePhase phase = EnginePhase.sendSemanticsUpdate,
  ]) =>
      tester.pump(duration, phase);

  Future<void> pumpAndSettle({
    Duration duration = const Duration(milliseconds: 100),
    EnginePhase phase = EnginePhase.sendSemanticsUpdate,
    Duration? timeout,
  }) =>
      tester.pumpAndSettle(
        duration,
        phase,
        timeout ?? config.settleTimeout,
      );

  Future<void> pumpAndTrySettle({
    Duration duration = const Duration(milliseconds: 100),
    EnginePhase phase = EnginePhase.sendSemanticsUpdate,
    Duration? timeout,
  }) async {
    try {
      await tester.pumpAndSettle(
        duration,
        phase,
        timeout ?? config.settleTimeout,
      );
      // ignore: avoid_catching_errors
    } on FlutterError catch (err) {
      if (err.message == 'pumpAndSettle timed out') {
        // This is fine. This method ignores pumpAndSettle timeouts on purpose
      } else {
        rethrow;
      }
    }
  }

  /// Pumps [widget] and then calls [WidgetTester.pumpAndSettle].
  ///
  /// This is a convenience method combining [WidgetTester.pumpWidget] and
  /// [WidgetTester.pumpAndSettle].
  Future<void> pumpWidgetAndSettle(
    Widget widget, {
    Duration? duration,
    EnginePhase phase = EnginePhase.sendSemanticsUpdate,
    Duration? timeout,
  }) async {
    await tester.pumpWidget(widget, duration, phase);
    await _performPump(
      settlePolicy: SettlePolicy.settle,
      settleTimeout: timeout,
    );
  }

  /// Waits until this finder finds at least 1 visible widget and then taps on
  /// it.
  ///
  /// Example:
  /// ```dart
  /// // taps on the first widget having Key('createAccount')
  /// await $(#createAccount).tap();
  /// ```
  ///
  /// If the finder finds more than 1 widget, you can choose which one to tap
  /// on:
  ///
  /// ```dart
  /// // taps on the third TextButton widget
  /// await $(TextButton).at(2).tap();
  /// ```
  ///
  /// This method automatically calls [WidgetTester.pumpAndSettle] after
  /// tapping. If you want to disable this behavior, set [settlePolicy] to
  /// [SettlePolicy.noSettle].
  ///
  /// See also:
  ///  - [CustomFinder.waitUntilVisible], which is used to wait for the widget
  ///    to appear
  ///  - [WidgetController.tap]
  Future<void> tap(
    Finder finder, {
    SettlePolicy? settlePolicy,
    Duration? visibleTimeout,
    Duration? settleTimeout,
  }) {
    return TestAsyncUtils.guard(() async {
      final resolvedFinder = await waitUntilVisible(
        finder,
        timeout: visibleTimeout,
      );
      await tester.tap(resolvedFinder.first);
      await _performPump(
        settlePolicy: settlePolicy,
        settleTimeout: settleTimeout,
      );
    });
  }

  /// Waits until this finder finds at least 1 visible widget and then makes
  /// long press gesture on it.
  ///
  /// Example:
  /// ```dart
  /// // long presses on the first widget having Key('createAccount')
  /// await $(#createAccount).longPress();
  /// ```
  ///
  /// If the finder finds more than 1 widget, you can choose which one to make
  /// long press on:
  ///
  /// ```dart
  /// // long presses on the third TextButton widget
  /// await $(TextButton).at(2).longPress();
  /// ```
  ///
  /// After long press gesture this method automatically calls
  /// [WidgetTester.pumpAndSettle]. If you want to disable this behavior,
  /// set [settlePolicy] to [SettlePolicy.noSettle].
  ///
  /// See also:
  ///  - [CustomFinder.waitUntilVisible], which is used to wait for the widget
  ///    to appear
  ///  - [WidgetController.longPress]
  Future<void> longPress(
    Finder finder, {
    SettlePolicy? settlePolicy,
    Duration? visibleTimeout,
    Duration? settleTimeout,
  }) {
    return TestAsyncUtils.guard(() async {
      final resolvedFinder = await waitUntilVisible(
        finder,
        timeout: visibleTimeout,
      );
      await tester.longPress(resolvedFinder.first);
      await _performPump(
        settlePolicy: settlePolicy,
        settleTimeout: settleTimeout,
      );
    });
  }

  /// Waits until [finder] finds at least 1 visible widget and then enters text
  /// into it.
  ///
  /// Example:
  /// ```dart
  /// // enters text into the first widget having Key('email')
  /// await $(#email).enterText(user@example.com);
  /// ```
  ///
  /// If the finder finds more than 1 widget, you can choose which one to enter
  /// text into:
  ///
  /// ```dart
  /// // enters text into the third TextField widget
  /// await $(TextField).at(2).enterText('Code ought to be lean');
  /// ```
  ///
  /// This method automatically calls [WidgetTester.pumpAndSettle] after
  /// entering text. If you want to disable this behavior, set [settlePolicy] to
  /// [SettlePolicy.noSettle].
  ///
  /// See also:
  ///  - [CustomFinder.waitUntilVisible], which is used to wait for the widget
  ///    to appear
  ///  - [WidgetTester.enterText]
  Future<void> enterText(
    Finder finder,
    String text, {
    SettlePolicy? settlePolicy,
    Duration? visibleTimeout,
    Duration? settleTimeout,
  }) {
    if (!kIsWeb) {
      // Fix for enterText() not working in release mode on real iOS devices.
      // See https://github.com/flutter/flutter/pull/89703
      // Also a fix for enterText() not being able to interact with the same
      // textfield 2 times in the same test.
      // See https://github.com/flutter/flutter/issues/134604
      tester.testTextInput.register();
    }

    return TestAsyncUtils.guard(() async {
      final resolvedFinder = await waitUntilVisible(
        finder,
        timeout: visibleTimeout,
      );
      await tester.enterText(resolvedFinder.first, text);
      await _performPump(
        settlePolicy: settlePolicy,
        settleTimeout: settleTimeout,
      );
    });
  }

  /// Waits until this finder finds at least one widget.
  ///
  /// Throws a [WaitUntilVisibleTimeoutException] if no widgets  found.
  ///
  /// Timeout is globally set by [CustomTester.config.visibleTimeout]. If you
  /// want to override this global setting, set [timeout].
  Future<CustomFinder> waitUntilExists(
    CustomFinder finder, {
    Duration? timeout,
  }) {
    return TestAsyncUtils.guard(() async {
      final duration = timeout ?? config.existsTimeout;
      final end = tester.binding.clock.now().add(duration);

      while (finder.evaluate().isEmpty) {
        final now = tester.binding.clock.now();
        if (now.isAfter(end)) {
          throw WaitUntilExistsTimeoutException(
            finder: finder,
            duration: duration,
          );
        }

        await tester.pump(const Duration(milliseconds: 100));
      }

      return finder;
    });
  }

  /// Waits until [finder] finds at least one visible widget.
  ///
  /// Throws a [WaitUntilVisibleTimeoutException] if more time than specified by
  /// the timeout passed and no widgets were found.
  ///
  /// Timeout is globally set by [CustomTester.config.visibleTimeout]. If you
  /// want to override this global setting, set [timeout].
  Future<CustomFinder> waitUntilVisible(
    Finder finder, {
    Duration? timeout,
  }) {
    return TestAsyncUtils.guard(() async {
      final duration = timeout ?? config.visibleTimeout;
      final end = tester.binding.clock.now().add(duration);
      final hitTestableFinder = finder.hitTestable();
      while (hitTestableFinder.evaluate().isEmpty) {
        final now = tester.binding.clock.now();
        if (now.isAfter(end)) {
          throw WaitUntilVisibleTimeoutException(
            finder: finder,
            duration: duration,
          );
        }

        await tester.pump(const Duration(milliseconds: 100));
      }

      return CustomFinder(finder: hitTestableFinder, tester: this);
    });
  }

  /// Repeatedly drags [view] by [moveStep] until [finder] finds at least one
  /// existing widget.
  ///
  /// Between each drag, calls [pump], [pumpAndSettle] or [pumpAndTrySettle],
  /// depending on chosen [settlePolicy].
  ///
  /// This is a reimplementation of [WidgetController.dragUntilVisible] that
  /// differs from the original in the following ways:
  ///
  ///  * scrolls until until [finder] finds at least one *existing* widget
  ///
  ///  * waits until [view] is visible
  ///
  ///  * if the [view] finder finds more than 1 widget, it scrolls the first one
  ///    instead of throwing a [StateError]
  ///
  ///  * if the [finder] finder finds more than 1 widget, it scrolls to the
  ///    first one instead of throwing a [StateError]
  ///
  ///  * can drag any widget, not only a [Scrollable]
  ///
  ///  * performed drag is slower (it takes some time to performe dragging
  ///    gesture, half a second by default)
  ///
  ///  * you can configure, which version of pumping is performed between
  ///    each drag gesture ([pump], [pumpAndSettle] or [pumpAndTrySettle]),
  ///
  ///  * timeouts and durations, if null, are controlled by values in
  ///    [CustomTester.config].
  ///
  /// See also:
  ///  * [CustomTester.config.settlePolicy], which controls the default settle
  ///     behavior
  ///  * [CustomTester.dragUntilVisible], which scrolls to visible widget,
  ///    not only existing one.
  Future<CustomFinder> dragUntilExists({
    required Finder finder,
    required Finder view,
    required Offset moveStep,
    int maxIteration = defaultScrollMaxIteration,
    Duration? settleBetweenScrollsTimeout,
    Duration? dragDuration,
    SettlePolicy? settlePolicy,
  }) {
    return TestAsyncUtils.guard(() async {
      var viewPatrolFinder = CustomFinder(finder: view, tester: this);
      await viewPatrolFinder.waitUntilVisible();
      viewPatrolFinder = viewPatrolFinder.hitTestable().first;
      dragDuration ??= config.dragDuration;
      settleBetweenScrollsTimeout ??= config.settleBetweenScrollsTimeout;

      var iterationsLeft = maxIteration;
      while (iterationsLeft > 0 && finder.evaluate().isEmpty) {
        await tester.timedDrag(
          viewPatrolFinder,
          moveStep,
          dragDuration!,
        );
        await _performPump(
          settlePolicy: settlePolicy,
          settleTimeout: settleBetweenScrollsTimeout,
        );
        iterationsLeft -= 1;
      }

      if (iterationsLeft <= 0) {
        throw WaitUntilExistsTimeoutException(
          finder: finder,
          // TODO: set reasonable duration or create new exception for this case
          duration: settleBetweenScrollsTimeout!,
        );
      }

      return CustomFinder(finder: finder, tester: this);
    });
  }

  /// Repeatedly drags [view] by [moveStep] until [finder] finds at least one
  /// visible widget.
  ///
  /// Between each drag, calls [pump], [pumpAndSettle] or [pumpAndTrySettle],
  /// depending on chosen [settlePolicy].
  ///
  /// This is a reimplementation of [WidgetController.dragUntilVisible] that
  /// differs from the original in the following ways:
  ///
  ///  * waits until [view] is visible
  ///
  ///  * if the [view] finder finds more than 1 widget, it scrolls the first one
  ///    instead of throwing a [StateError]
  ///
  ///  * if the [finder] finder finds more than 1 widget, it scrolls to the
  ///    first one instead of throwing a [StateError]
  ///
  ///  * can drag any widget, not only a [Scrollable]
  ///
  ///  * performed drag is slower (it takes some time to perform dragging
  ///    gesture, half a second by default)
  ///
  ///  * you can configure, which version of pumping is performed between
  ///    each drag gesture ([pump], [pumpAndSettle] or [pumpAndTrySettle])
  ///
  ///  * timeouts and durations, if null, are controlled by values in
  ///    [CustomTester.config].
  ///
  /// See also:
  ///  * [CustomTester.dragUntilExists], which scrolls to existing widget,
  ///    not a visible one.
  Future<CustomFinder> dragUntilVisible({
    required Finder finder,
    required Finder view,
    required Offset moveStep,
    int maxIteration = defaultScrollMaxIteration,
    Duration? settleBetweenScrollsTimeout,
    Duration? dragDuration,
    SettlePolicy? settlePolicy,
  }) {
    return TestAsyncUtils.guard(() async {
      var viewPatrolFinder = CustomFinder(finder: view, tester: this);
      await viewPatrolFinder.waitUntilVisible();
      viewPatrolFinder = viewPatrolFinder.hitTestable().first;
      dragDuration ??= config.dragDuration;
      settleBetweenScrollsTimeout ??= config.settleBetweenScrollsTimeout;

      var iterationsLeft = maxIteration;
      while (iterationsLeft > 0 && finder.hitTestable().evaluate().isEmpty) {
        await tester.timedDrag(
          viewPatrolFinder,
          moveStep,
          dragDuration!,
        );
        await _performPump(
          settlePolicy: settlePolicy,
          settleTimeout: settleBetweenScrollsTimeout,
        );
        iterationsLeft -= 1;
      }

      if (iterationsLeft <= 0) {
        throw WaitUntilVisibleTimeoutException(
          finder: finder.hitTestable(),
          // TODO: set reasonable duration or create new exception for this case
          duration: settleBetweenScrollsTimeout!,
        );
      }

      return CustomFinder(finder: finder.hitTestable().first, tester: this);
    });
  }

  /// Scrolls [view] in its scrolling direction until this finders finds
  /// at least one existing widget.
  ///
  /// If [view] is null, it defaults to the first found [Scrollable].
  ///
  /// See also:
  ///  - [CustomTester.scrollUntilVisible].
  Future<CustomFinder> scrollUntilExists({
    required Finder finder,
    Finder? view,
    double delta = defaultScrollDelta,
    AxisDirection? scrollDirection,
    int maxScrolls = defaultScrollMaxIteration,
    Duration? settleBetweenScrollsTimeout,
    Duration? dragDuration,
    SettlePolicy? settlePolicy,
  }) async {
    assert(maxScrolls > 0, 'maxScrolls must be positive number');
    view ??= find.byType(Scrollable);

    final scrollablePatrolFinder = await CustomFinder(
      finder: view,
      tester: this,
    ).waitUntilVisible();
    AxisDirection direction;
    if (scrollDirection == null) {
      if (view.evaluate().first.widget is Scrollable) {
        direction = tester.firstWidget<Scrollable>(view).axisDirection;
      } else {
        direction = AxisDirection.down;
      }
    } else {
      direction = scrollDirection;
    }

    return TestAsyncUtils.guard<CustomFinder>(() async {
      final moveStep = switch (direction) {
        AxisDirection.up => Offset(0, delta),
        AxisDirection.down => Offset(0, -delta),
        AxisDirection.left => Offset(delta, 0),
        AxisDirection.right => Offset(-delta, 0),
      };

      final resolvedFinder = await dragUntilExists(
        finder: finder,
        view: scrollablePatrolFinder.first,
        moveStep: moveStep,
        maxIteration: maxScrolls,
        settleBetweenScrollsTimeout: settleBetweenScrollsTimeout,
        dragDuration: dragDuration,
        settlePolicy: settlePolicy,
      );

      return resolvedFinder;
    });
  }

  /// Scrolls [view] in [scrollDirection] until this finders finds
  /// at least one existing widget.
  ///
  /// If [view] is null, it defaults to the first found [Scrollable].
  ///
  /// This is a reimplementation of [WidgetController.scrollUntilVisible] that
  /// doesn't throw when [finder] finds more than one widget.
  ///
  /// See also:
  ///  - [CustomTester.scrollUntilExists].
  Future<CustomFinder> scrollUntilVisible({
    required Finder finder,
    Finder? view,
    double delta = defaultScrollDelta,
    AxisDirection? scrollDirection,
    int maxScrolls = defaultScrollMaxIteration,
    Duration? settleBetweenScrollsTimeout,
    Duration? dragDuration,
    SettlePolicy? settlePolicy,
  }) async {
    assert(maxScrolls > 0, 'maxScrolls must be positive number');

    view ??= find.byType(Scrollable);
    final scrollablePatrolFinder = await CustomFinder(
      finder: view,
      tester: this,
    ).waitUntilVisible();
    AxisDirection direction;
    if (scrollDirection == null) {
      if (view.evaluate().first.widget is Scrollable) {
        direction = tester.firstWidget<Scrollable>(view).axisDirection;
      } else {
        direction = AxisDirection.down;
      }
    } else {
      direction = scrollDirection;
    }

    return TestAsyncUtils.guard<CustomFinder>(() async {
      Offset moveStep;
      switch (direction) {
        case AxisDirection.up:
          moveStep = Offset(0, delta);
        case AxisDirection.down:
          moveStep = Offset(0, -delta);
        case AxisDirection.left:
          moveStep = Offset(delta, 0);
        case AxisDirection.right:
          moveStep = Offset(-delta, 0);
      }

      final resolvedFinder = await dragUntilVisible(
        finder: finder,
        view: scrollablePatrolFinder.first,
        moveStep: moveStep,
        maxIteration: maxScrolls,
        settleBetweenScrollsTimeout: settleBetweenScrollsTimeout,
        dragDuration: dragDuration,
        settlePolicy: settlePolicy,
      );

      return resolvedFinder;
    });
  }

  Future<void> _performPump({
    required SettlePolicy? settlePolicy,
    required Duration? settleTimeout,
  }) async {
    final settle = settlePolicy ?? config.settlePolicy;
    final timeout = settleTimeout ?? config.settleTimeout;
    if (settle == SettlePolicy.trySettle) {
      await pumpAndTrySettle(
        timeout: timeout,
      );
    } else if (settle == SettlePolicy.settle) {
      await pumpAndSettle(
        timeout: timeout,
      );
    } else {
      await tester.pump();
    }
  }
}

/// Specifies how methods such as [CustomTester.tap] or [CustomTester.enterText] perform pumping, i.e. rendering new frames.
///
/// It's useful when dealing with situations involving finite and infinite animations.
enum SettlePolicy {
  /// [CustomTester.pump] is used when pumping.
  ///
  /// This renders a single frame. If some animations are currently in progress, they will move forward by a single frame.
  noSettle,

  /// [CustomTester.pumpAndSettle] is used when pumping.
  ///
  /// This keeps on rendering new frames until there are no frames pending or timeout is reached. Throws a [FlutterError] if timeout has been reached.
  settle,

  /// [CustomTester.pumpAndTrySettle] is used when pumping.
  ///
  /// This keeps on rendering new frames until there are no frames pending or timeout is reached. Doesn't throw an exception if timeout has been reached.
  trySettle,
}
