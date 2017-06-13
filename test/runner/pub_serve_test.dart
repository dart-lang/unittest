// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn("vm")
@Tags(const ["pub"])

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

import 'package:test/src/util/exit_codes.dart' as exit_codes;
import 'package:test/test.dart';

import '../io.dart';

/// The `--pub-serve` argument for the test process, based on [pubServePort].
String get _pubServeArg => '--pub-serve=$pubServePort';

void main() {
  setUp(() async {
    await d
        .file(
            "pubspec.yaml",
            """
name: myapp
dependencies:
  barback: any
  test: {path: ${p.current}}
transformers:
- myapp:
    \$include: test/**_test.dart
- test/pub_serve:
    \$include: test/**_test.dart
""")
        .create();

    await d.dir("test", [
      d.file(
          "my_test.dart",
          """
import 'package:test/test.dart';

void main() {
  test("test", () => expect(true, isTrue));
}
""")
    ]).create();

    await d.dir("lib", [
      d.file(
          "myapp.dart",
          """
import 'package:barback/barback.dart';

class MyTransformer extends Transformer {
  final allowedExtensions = '.dart';

  MyTransformer.asPlugin();

  Future apply(Transform transform) async {
    var contents = await transform.primaryInput.readAsString();
    transform.addOutput(new Asset.fromString(
        transform.primaryInput.id,
        contents.replaceAll("isFalse", "isTrue")));
  }
}
""")
    ]).create();

    await (await runPub(['get'])).shouldExit(0);
  });

  group("with transformed tests", () {
    setUp(() async {
      // Give the test a failing assertion that the transformer will convert to
      // a passing assertion.
      await d
          .file(
              "test/my_test.dart",
              """
import 'package:test/test.dart';

void main() {
  test("test", () => expect(true, isFalse));
}
""")
          .create();
    });

    test("runs those tests in the VM", () async {
      var pub = await runPubServe();
      var test = await runTest([_pubServeArg]);
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
      await pub.kill();
    });

    testWithCompiler("runs those tests on Chrome", (compiler) async {
      var pub = await runPubServe(args: ['--web-compiler', compiler]);
      var test = await runTest([_pubServeArg, '-p', 'chrome']);
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
      await pub.kill();
    }, tags: 'chrome');

    test("runs those tests on content shell", () async {
      var pub = await runPubServe();
      var test = await runTest([_pubServeArg, '-p', 'content-shell']);
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
      await pub.kill();
    }, tags: 'content-shell');

    test(
        "gracefully handles pub serve running on the wrong directory for "
        "VM tests", () async {
      await d.dir("web").create();

      var pub = await runPubServe(args: ['web']);
      var test = await runTest([_pubServeArg]);
      expect(
          test.stdout,
          containsInOrder([
            '-1: loading ${p.join("test", "my_test.dart")} [E]',
            'Failed to load "${p.join("test", "my_test.dart")}":',
            '404 Not Found',
            'Make sure "pub serve" is serving the test/ directory.'
          ]));
      await test.shouldExit(1);

      await pub.kill();
    });

    group(
        "gracefully handles pub serve running on the wrong directory for "
        "browser tests", () {
      testWithCompiler("when run on Chrome", (compiler) async {
        await d.dir("web").create();

        var pub = await runPubServe(args: ['web', '--web-compiler', compiler]);
        var test = await runTest([_pubServeArg, '-p', 'chrome']);
        expect(
            test.stdout,
            containsInOrder([
              '-1: compiling ${p.join("test", "my_test.dart")} [E]',
              'Failed to load "${p.join("test", "my_test.dart")}":',
              '404 Not Found',
              'Make sure "pub serve" is serving the test/ directory.'
            ]));
        await test.shouldExit(1);

        await pub.kill();
      }, tags: 'chrome');

      test("when run on content shell", () async {
        await d.dir("web").create();

        var pub = await runPubServe(args: ['web']);
        var test = await runTest([_pubServeArg, '-p', 'content-shell']);
        expect(
            test.stdout,
            containsInOrder([
              '-1: loading ${p.join("test", "my_test.dart")} [E]',
              'Failed to load "${p.join("test", "my_test.dart")}":',
              '404 Not Found',
              'Make sure "pub serve" is serving the test/ directory.'
            ]));
        await test.shouldExit(1);

        await pub.kill();
      }, tags: 'content-shell');
    });

    test("gracefully handles unconfigured transformers", () async {
      await d
          .file(
              "pubspec.yaml",
              """
name: myapp
dependencies:
  barback: any
  test: {path: ${p.current}}
""")
          .create();

      var pub = await runPubServe();
      var test = await runTest([_pubServeArg]);
      await expectStderrEquals(
          test,
          '''
When using --pub-serve, you must include the "test/pub_serve" transformer in
your pubspec:

transformers:
- test/pub_serve:
    \$include: test/**_test.dart
''');
      await test.shouldExit(exit_codes.data);

      await pub.kill();
    });
  });

  group("uses a custom HTML file", () {
    setUp(() async {
      await d.dir("test", [
        d.file(
            "test.dart",
            """
import 'dart:html';

import 'package:test/test.dart';

void main() {
  test("failure", () {
    expect(document.query('#foo'), isNull);
  });
}
"""),
        d.file(
            "test.html",
            """
<html>
<head>
  <link rel='x-dart-test' href='test.dart'>
  <script src="packages/test/dart.js"></script>
</head>
<body>
  <div id="foo"></div>
</body>
""")
      ]).create();
    });

    testWithCompiler("on Chrome", (compiler) async {
      var pub = await runPubServe(args: ['--web-compiler', compiler]);
      var test = await runTest([_pubServeArg, '-p', 'chrome']);
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
      await pub.kill();
    }, tags: 'chrome');

    test("on content shell", () async {
      var pub = await runPubServe();
      var test = await runTest([_pubServeArg, '-p', 'content-shell']);
      expect(test.stdout, emitsThrough(contains('+1: All tests passed!')));
      await test.shouldExit(0);
      await pub.kill();
    }, tags: 'content-shell');
  });

  group("with a failing test", () {
    setUp(() async {
      await d
          .file(
              "test/my_test.dart",
              """
import 'dart:html';

import 'package:test/test.dart';

void main() {
  test("failure", () => throw 'oh no');
}
""")
          .create();
    });

    test("dartifies stack traces for JS-compiled tests by default", () async {
      var pub = await runPubServe();
      var test =
          await runTest([_pubServeArg, '-p', 'chrome', '--verbose-trace']);
      expect(
          test.stdout,
          containsInOrder(
              [" main.<fn>", "package:test", "dart:async/zone.dart"]));
      await test.shouldExit(1);
      pub.kill();
    }, tags: 'chrome');

    test("doesn't dartify stack traces for JS-compiled tests with --js-trace",
        () async {
      var pub = await runPubServe();
      var test = await runTest(
          [_pubServeArg, '-p', 'chrome', '--js-trace', '--verbose-trace']);

      expect(test.stdoutStream(), neverEmits(endsWith(" main.<fn>")));
      expect(test.stdoutStream(), neverEmits(contains("package:test")));
      expect(test.stdoutStream(), neverEmits(contains("dart:async/zone.dart")));
      expect(test.stdout, emitsThrough(contains("-1: Some tests failed.")));
      await test.shouldExit(1);

      await pub.kill();
    }, tags: 'chrome');
  });

  test("gracefully handles pub serve not running for VM tests", () async {
    var test = await runTest(['--pub-serve=54321']);
    expect(
        test.stdout,
        containsInOrder([
          '-1: loading ${p.join("test", "my_test.dart")} [E]',
          'Failed to load "${p.join("test", "my_test.dart")}":',
          'Error getting http://localhost:54321/my_test.dart.vm_test.dart: '
              'Connection refused',
          'Make sure "pub serve" is running.'
        ]));
    await test.shouldExit(1);
  });

  test("gracefully handles pub serve not running for browser tests", () async {
    var test = await runTest(['--pub-serve=54321', '-p', 'chrome']);
    var message = Platform.isWindows
        ? 'The remote computer refused the network connection.'
        : 'Connection refused (errno ';

    expect(
        test.stdout,
        containsInOrder([
          '-1: compiling ${p.join("test", "my_test.dart")} [E]',
          'Failed to load "${p.join("test", "my_test.dart")}":',
          'Error getting http://localhost:54321/my_test.dart.browser_test.dart.js'
              '.map: $message',
          'Make sure "pub serve" is running.'
        ]));
    await test.shouldExit(1);
  }, tags: 'chrome');

  test("gracefully handles a test file not being in test/", () async {
    new File(p.join(d.sandbox, 'test/my_test.dart'))
        .copySync(p.join(d.sandbox, 'my_test.dart'));

    var test = await runTest(['--pub-serve=54321', 'my_test.dart']);
    expect(
        test.stdout,
        containsInOrder([
          '-1: loading my_test.dart [E]',
          'Failed to load "my_test.dart": When using "pub serve", all test files '
              'must be in test/.'
        ]));
    await test.shouldExit(1);
  });
}

/// The list of supported compilers for the current [Platform.version].
final Iterable<String> _compilers = () {
  var compilers = ['dart2js'];
  var sdkVersion = new Version.parse(
      Platform.version.substring(0, Platform.version.indexOf(' ')));
  var minDartDevcVersion = new Version(1, 24, 0);
  if (sdkVersion >= minDartDevcVersion) {
    compilers.add('dartdevc');
  }
  return compilers;
}();

/// Runs the test described by [testFn] once for each supported compiler on the
/// current [Platform.version], passing that compiler as the first argument.
void testWithCompiler(String name, testFn(String compiler), {tags}) {
  for (var compiler in _compilers) {
    test("$name with $compiler", () => testFn(compiler), tags: tags);
  }
}
