// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../../utils.dart';

void main() {
  group('[throwsArgumentError]', () {
    test('passes when a ArgumentError is thrown', () {
      expect(() => throw ArgumentError(''), throwsArgumentError);
    });

    test('fails when a non-ArgumentError is thrown', () async {
      var liveTest = await runTestBody(() {
        expect(() => throw Exception(), throwsArgumentError);
      });

      expectTestFailed(liveTest,
          startsWith("Expected: throws <Instance of 'ArgumentError'>"));
    });
  });

  group('[throwsConcurrentModificationError]', () {
    test('passes when a ConcurrentModificationError is thrown', () {
      expect(() => throw ConcurrentModificationError(''),
          throwsConcurrentModificationError);
    });

    test('fails when a non-ConcurrentModificationError is thrown', () async {
      var liveTest = await runTestBody(() {
        expect(() => throw Exception(), throwsConcurrentModificationError);
      });

      expectTestFailed(
          liveTest,
          startsWith(
              "Expected: throws <Instance of 'ConcurrentModificationError'>"));
    });
  });

  group('[throwsCyclicInitializationError]', () {
    test('passes when a CyclicInitializationError is thrown', () {
      // ignore: deprecated_member_use
      expect(() => _CyclicInitializationFailure().x,
          throwsCyclicInitializationError);
    });

    test('fails when a non-CyclicInitializationError is thrown', () async {
      var liveTest = await runTestBody(() {
        expect(() => throw Exception(), throwsCyclicInitializationError);
      });

      expectTestFailed(
          liveTest,
          startsWith(
              "Expected: throws <Instance of 'CyclicInitializationError'>"));
    });
  });

  group('[throwsException]', () {
    test('passes when a Exception is thrown', () {
      expect(() => throw Exception(''), throwsException);
    });

    test('fails when a non-Exception is thrown', () async {
      var liveTest = await runTestBody(() {
        expect(() => throw 'oh no', throwsException);
      });

      expectTestFailed(
          liveTest, startsWith("Expected: throws <Instance of 'Exception'>"));
    });
  });

  group('[throwsFormatException]', () {
    test('passes when a FormatException is thrown', () {
      expect(() => throw FormatException(''), throwsFormatException);
    });

    test('fails when a non-FormatException is thrown', () async {
      var liveTest = await runTestBody(() {
        expect(() => throw Exception(), throwsFormatException);
      });

      expectTestFailed(liveTest,
          startsWith("Expected: throws <Instance of 'FormatException'>"));
    });
  });

  group('[throwsNoSuchMethodError]', () {
    test('passes when a NoSuchMethodError is thrown', () {
      expect(() {
        (1 as dynamic).notAMethodOnInt();
      }, throwsNoSuchMethodError);
    });

    test('fails when a non-NoSuchMethodError is thrown', () async {
      var liveTest = await runTestBody(() {
        expect(() => throw Exception(), throwsNoSuchMethodError);
      });

      expectTestFailed(liveTest,
          startsWith("Expected: throws <Instance of 'NoSuchMethodError'>"));
    });
  });

  group('[throwsRangeError]', () {
    test('passes when a RangeError is thrown', () {
      expect(() => throw RangeError(''), throwsRangeError);
    });

    test('fails when a non-RangeError is thrown', () async {
      var liveTest = await runTestBody(() {
        expect(() => throw Exception(), throwsRangeError);
      });

      expectTestFailed(
          liveTest, startsWith("Expected: throws <Instance of 'RangeError'>"));
    });
  });

  group('[throwsStateError]', () {
    test('passes when a StateError is thrown', () {
      expect(() => throw StateError(''), throwsStateError);
    });

    test('fails when a non-StateError is thrown', () async {
      var liveTest = await runTestBody(() {
        expect(() => throw Exception(), throwsStateError);
      });

      expectTestFailed(
          liveTest, startsWith("Expected: throws <Instance of 'StateError'>"));
    });
  });

  group('[throwsUnimplementedError]', () {
    test('passes when a UnimplementedError is thrown', () {
      expect(() => throw UnimplementedError(''), throwsUnimplementedError);
    });

    test('fails when a non-UnimplementedError is thrown', () async {
      var liveTest = await runTestBody(() {
        expect(() => throw Exception(), throwsUnimplementedError);
      });

      expectTestFailed(liveTest,
          startsWith("Expected: throws <Instance of 'UnimplementedError'>"));
    });
  });

  group('[throwsUnsupportedError]', () {
    test('passes when a UnsupportedError is thrown', () {
      expect(() => throw UnsupportedError(''), throwsUnsupportedError);
    });

    test('fails when a non-UnsupportedError is thrown', () async {
      var liveTest = await runTestBody(() {
        expect(() => throw Exception(), throwsUnsupportedError);
      });

      expectTestFailed(liveTest,
          startsWith("Expected: throws <Instance of 'UnsupportedError'>"));
    });
  });
}

class _CyclicInitializationFailure {
  late int x = y;
  late int y = x;
}
