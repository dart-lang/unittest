// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The prefix for the test suite import in generated test runner files.
///
/// DO NOT CHANGE THE VALUE OF THIS STRING. Dart DevTools depends on logic that
/// searches for a prefix named 'test' to find the URI of the Dart library under
/// test. The 'test' prefix matches the prefix generated by Flutter tool.
const testSuiteImportPrefix = 'test';
