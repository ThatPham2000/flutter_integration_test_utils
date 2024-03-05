import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

class CustomFinderException implements Exception {
  const CustomFinderException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thrown when some methods fail to complete within the allowed time.
class CustomTimeoutException extends TimeoutException {
  CustomTimeoutException({
    required this.finder,
    required String message,
    required Duration duration,
  }) : super(message, duration);

  final Finder finder;
}

/// Thrown when custom finder did not find anything in the allowed time and
/// timed out.
class WaitUntilExistsTimeoutException extends CustomTimeoutException {
  WaitUntilExistsTimeoutException({
    required super.finder,
    required super.duration,
  }) : super(message: 'Finder "$finder" did not find any widgets');
}

/// Indicates that custom finder did not find anything in the allowed time and
/// timed out.
class WaitUntilVisibleTimeoutException extends CustomTimeoutException {
  WaitUntilVisibleTimeoutException({
    required super.finder,
    required super.duration,
  }) : super(
          message:
              'Finder "$finder" did not find any visible (i.e. hit-testable) widgets',
        );
}
