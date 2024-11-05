import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_integration_test_utils/src/custom_tester.dart';
import 'package:flutter_integration_test_utils/src/exception.dart';
import 'package:flutter_integration_test_utils/src/extension.dart';
import 'package:flutter_test/flutter_test.dart';

@visibleForTesting
Finder createFinder(dynamic matching) {
  if (matching is Type) {
    return find.byType(matching);
  }

  if (matching is Key) {
    return find.byKey(matching);
  }

  if (matching is Symbol) {
    return find.byKey(Key(matching.name));
  }

  if (matching is String) {
    return find.text(matching, findRichText: true);
  }

  if (matching is Pattern) {
    return find.textContaining(matching, findRichText: true);
  }

  if (matching is IconData) {
    return find.byIcon(matching);
  }

  if (matching is CustomFinder) {
    return matching.finder;
  }

  if (matching is Finder) {
    return matching;
  }

  if (matching is Widget) {
    return find.byWidget(matching);
  }

  throw ArgumentError(
    'Argument of type ${matching.runtimeType} is not supported. '
    'Supported types: Type, Key, Symbol, String, Pattern, IconData, '
    'CustomFinder, Finder, Widget',
  );
}

class CustomFinder implements MatchFinder {
  CustomFinder({required this.finder, required this.tester});

  factory CustomFinder.resolve({
    required dynamic matching,
    required Finder? parentFinder,
    required CustomTester tester,
  }) {
    final finder = createFinder(matching);

    if (parentFinder != null) {
      return CustomFinder(
        tester: tester,
        finder: find.descendant(
          of: parentFinder,
          matching: finder,
        ),
      );
    }

    return CustomFinder(
      tester: tester,
      finder: finder,
    );
  }

  final Finder finder;
  final CustomTester tester;

  Future<void> tap({
    SettlePolicy? settlePolicy,
    Duration? visibleTimeout,
    Duration? settleTimeout,
  }) async {
    await tester.tap(
      this,
      settlePolicy: settlePolicy,
      visibleTimeout: visibleTimeout,
      settleTimeout: settleTimeout,
    );
  }

  Future<void> longPress({
    SettlePolicy? settlePolicy,
    Duration? visibleTimeout,
    Duration? settleTimeout,
  }) async {
    await tester.longPress(
      this,
      settlePolicy: settlePolicy,
      visibleTimeout: visibleTimeout,
      settleTimeout: settleTimeout,
    );
  }

  Future<void> enterText(
    String text, {
    SettlePolicy? settlePolicy,
    Duration? visibleTimeout,
    Duration? settleTimeout,
  }) async {
    await tester.enterText(
      this,
      text,
      settlePolicy: settlePolicy,
      visibleTimeout: visibleTimeout,
      settleTimeout: settleTimeout,
    );
  }

  Future<CustomFinder> scrollTo({
    Finder? view,
    double step = defaultScrollDelta,
    AxisDirection? scrollDirection,
    int maxScrolls = defaultScrollMaxIteration,
    Duration? settleBetweenScrollsTimeout,
    Duration? dragDuration,
    SettlePolicy? settlePolicy,
  }) {
    return tester.scrollUntilVisible(
      finder: finder,
      view: view,
      delta: step,
      scrollDirection: scrollDirection,
      maxScrolls: maxScrolls,
      settleBetweenScrollsTimeout: settleBetweenScrollsTimeout,
      settlePolicy: settlePolicy,
      dragDuration: dragDuration,
    );
  }

  Future<CustomFinder> waitUntilExists({Duration? timeout}) {
    return tester.waitUntilExists(this, timeout: timeout);
  }

  Future<CustomFinder> waitUntilVisible({Duration? timeout}) {
    return tester.waitUntilVisible(this, timeout: timeout);
  }

  CustomFinder which<T extends Widget>(bool Function(T widget) predicate) {
    return CustomFinder(
      finder: find.descendant(
        matchRoot: true,
        of: this,
        matching: find.byWidgetPredicate((widget) {
          if (widget is! T) {
            return false;
          }
          final foundWidgets = evaluate().map(
            (e) => e.widget,
          );
          if (!foundWidgets.contains(widget)) {
            return false;
          }
          return predicate(widget);
        }),
      ),
      tester: tester,
    );
  }

  String? get text {
    final elements = finder.evaluate();

    if (elements.isEmpty) {
      throw CustomFinderException('Finder "${toString()}" found no widgets');
    }

    final firstWidget = elements.first.widget;

    if (firstWidget is Text) {
      return firstWidget.data;
    }

    if (firstWidget is RichText) {
      return (firstWidget.text as TextSpan).toPlainText();
    }

    throw CustomFinderException(
      'The first ${firstWidget.runtimeType} widget resolved by this finder '
      'is not a Text or RichText widget',
    );
  }

  CustomFinder $(dynamic matching) {
    return CustomFinder.resolve(
      matching: matching,
      tester: tester,
      parentFinder: this,
    );
  }

  /// Returns [CustomFinder] that this method was called on and which contains
  /// [matching] as a descendant.
  CustomFinder containing(dynamic matching) {
    return CustomFinder(
      tester: tester,
      finder: find.ancestor(
        of: createFinder(matching),
        matching: finder,
      ),
    );
  }

  /// Returns true if this finder finds at least 1 widget.
  bool get exists => evaluate().isNotEmpty;

  /// Returns true if this finder finds at least 1 visible widget.
  bool get visible {
    final isVisible = hitTestable().evaluate().isNotEmpty;
    if (isVisible == true) {
      assert(
        exists == true,
        'visible returned true, but exists returned false',
      );
    }

    return isVisible;
  }

  @override
  FinderResult<Element> evaluate() => finder.evaluate();

  @override
  CustomFinder get first {
    // TODO: Throw a better error (https://github.com/leancodepl/patrol/issues/548)
    return CustomFinder(tester: tester, finder: finder.first);
  }

  @override
  CustomFinder get last {
    // TODO: Throw a better error (https://github.com/leancodepl/patrol/issues/548)
    return CustomFinder(
      tester: tester,
      finder: finder.last,
    );
  }

  @override
  CustomFinder at(int index) {
    // TODO: Throw a better error (https://github.com/leancodepl/patrol/issues/548)
    return CustomFinder(
      tester: tester,
      finder: finder.at(index),
    );
  }

  @override
  bool matches(Element candidate) {
    return (finder as MatchFinder).matches(candidate);
  }

  @override
  CustomFinder hitTestable({Alignment at = Alignment.center}) {
    return CustomFinder(finder: finder.hitTestable(at: at), tester: tester);
  }

  @override
  Iterable<Element> get allCandidates => finder.allCandidates;

  @override
  String toString({bool describeSelf = false}) {
    // return finder.toString(describeSelf: describeSelf);
    return finder.toString();
  }

  @override
  bool get skipOffstage => finder.skipOffstage;

  @override
  Iterable<Element> apply(Iterable<Element> candidates) {
    // ignore: deprecated_member_use
    return finder.apply(candidates);
  }

  @override
  // ignore: deprecated_member_use
  String get description => finder.description;

  @override
  // ignore: deprecated_member_use
  bool precache() => finder.precache();

  @override
  String describeMatch(Plurality plurality) => finder.describeMatch(plurality);

  @override
  Iterable<Element> findInCandidates(Iterable<Element> candidates) {
    return finder.findInCandidates(candidates);
  }

  @override
  FinderResult<Element> get found => finder.found;

  @override
  bool get hasFound => finder.hasFound;

  @override
  void reset() => finder.reset();

  @override
  void runCached(VoidCallback run) => finder.runCached(run);

  @override
  bool tryEvaluate() => finder.tryEvaluate();
}

/// Useful methods that make chained finders more readable.
extension ActionCombiner on Future<CustomFinder> {
  Future<void> tap({
    SettlePolicy? settlePolicy,
    Duration? visibleTimeout,
    Duration? settleTimeout,
  }) async {
    await (await this).tap(
      settlePolicy: settlePolicy,
      visibleTimeout: visibleTimeout,
      settleTimeout: settleTimeout,
    );
  }

  Future<void> enterText(
    String text, {
    SettlePolicy? settlePolicy,
    Duration? visibleTimeout,
    Duration? settleTimeout,
  }) async {
    await (await this).enterText(
      text,
      settlePolicy: settlePolicy,
      visibleTimeout: visibleTimeout,
      settleTimeout: settleTimeout,
    );
  }
}
