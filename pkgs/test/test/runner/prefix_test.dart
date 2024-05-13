// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_core/src/util/prefix.dart';

void main() {
  test('testSuiteImportPrefix value is "test"', () {
    expect(
      testSuiteImportPrefix,
      'test',
      reason: 'testSuiteImportPrefix must be equal to the String "test". Dart '
          'DevTools depends on logic that searches for a prefix named "test" '
          'to find the URI of the Dart library under test.',
    );
  });
}
