// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: deprecated_member_use_from_same_package

export 'matcher.dart';

export 'src/expect/expect.dart' show ErrorFormatter, expect, expectLater, fail;
export 'src/expect/expect_async.dart'
    show
        Func0,
        Func1,
        Func2,
        Func3,
        Func4,
        Func5,
        Func6,
        expectAsync,
        expectAsync0,
        expectAsync1,
        expectAsync2,
        expectAsync3,
        expectAsync4,
        expectAsync5,
        expectAsync6,
        expectAsyncUntil0,
        expectAsyncUntil1,
        expectAsyncUntil2,
        expectAsyncUntil3,
        expectAsyncUntil4,
        expectAsyncUntil5,
        expectAsyncUntil6;
export 'src/expect/future_matchers.dart'
    show completes, completion, doesNotComplete;
export 'src/expect/never_called.dart' show neverCalled;
export 'src/expect/prints_matcher.dart' show prints;
export 'src/expect/stream_matcher.dart' show StreamMatcher;
export 'src/expect/stream_matchers.dart'
    show
        emits,
        emitsAnyOf,
        emitsDone,
        emitsError,
        emitsInAnyOrder,
        emitsInOrder,
        emitsThrough,
        mayEmit,
        mayEmitMultiple,
        neverEmits;
export 'src/expect/throws_matcher.dart' show Throws, throws, throwsA;
export 'src/expect/throws_matchers.dart'
    show
        throwsArgumentError,
        throwsConcurrentModificationError,
        throwsCyclicInitializationError,
        throwsException,
        throwsFormatException,
        throwsNoSuchMethodError,
        throwsNullThrownError,
        throwsRangeError,
        throwsStateError,
        throwsUnimplementedError,
        throwsUnsupportedError;
