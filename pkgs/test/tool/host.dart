// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library test.host;

import 'dart:async';
import 'dart:convert';

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;
import 'package:stack_trace/stack_trace.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/src/runner/browser/dom.dart' as dom;

/// A class that exposes the test API to JS.
///
/// These are exposed so that tools like IDEs can interact with them via remote
/// debugging.
@JS()
@anonymous
@staticInterop
class _JSApi {
  external factory _JSApi(
      {void Function() resume, void Function() restartCurrent});
}

extension _JSApiExtension on _JSApi {
  /// Causes the test runner to resume running, as though the user had clicked
  /// the "play" button.
  // ignore: unused_element
  external Function get resume;

  /// Causes the test runner to restart the current test once it finishes
  /// running.
  // ignore: unused_element
  external Function get restartCurrent;
}

/// Sets the top-level `dartTest` object so that it's visible to JS.
@JS('dartTest')
external set _jsApi(_JSApi api);

/// The iframes created for each loaded test suite, indexed by the suite id.
final _iframes = <int, dom.HTMLIFrameElement>{};

/// Subscriptions created for each loaded test suite, indexed by the suite id.
final _subscriptions = <int, StreamSubscription<void>>{};
final _domSubscriptions = <int, dom.Subscription>{};

/// The URL for the current page.
final _currentUrl = Uri.parse(dom.window.location.href);

/// Code that runs in the browser and loads test suites at the server's behest.
///
/// One instance of this runs for each browser. When the server tells it to load
/// a test, it starts an iframe pointing at that test's code; from then on, it
/// just relays messages between the two.
///
/// The browser uses two layers of [MultiChannel]s when communicating with the
/// server:
///
///                                       server
///                                         │
///                                    (WebSocket)
///                                         │
///                    ┏━ host.html ━━━━━━━━┿━━━━━━━━━━━━━━━━━┓
///                    ┃                    │                 ┃
///                    ┃    ┌──────┬───MultiChannel─────┐     ┃
///                    ┃    │      │      │      │      │     ┃
///                    ┃   host  suite  suite  suite  suite   ┃
///                    ┃           │      │      │      │     ┃
///                    ┗━━━━━━━━━━━┿━━━━━━┿━━━━━━┿━━━━━━┿━━━━━┛
///                                │      │      │      │
///                                │     ...    ...    ...
///                                │
///                         (MessageChannel)
///                                │
///      ┏━ suite.html (in iframe) ┿━━━━━━━━━━━━━━━━━━━━━━━━━━┓
///      ┃                         │                          ┃
///      ┃         ┌──────────MultiChannel┬─────────┐         ┃
///      ┃         │          │     │     │         │         ┃
///      ┃   RemoteListener  test  test  test  running test   ┃
///      ┃                                                    ┃
///      ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
///
/// The host (this code) has a [MultiChannel] that splits the WebSocket
/// connection with the server. One connection is used for the host itself to
/// receive messages like "load a suite at this URL", and the rest are
/// connected to each test suite's iframe via a [MessageChannel].
///
/// Each iframe runs a `RemoteListener` which creates its own [MultiChannel] on
/// top of the [MessageChannel] connection. One connection is used for
/// the `RemoteListener`, which sends messages like "here are all the tests in
/// this suite". The rest are used for each test, receiving messages like
/// "start running". A new connection is also created whenever a test begins
/// running to send status messages about its progress.
///
/// It's of particular note that the suite's [MultiChannel] connection uses the
/// host's purely as a transport layer; neither is aware that the other is also
/// using [MultiChannel]. This is necessary, since the host doesn't share memory
/// with the suites and thus can't share its [MultiChannel] with them, but it
/// does mean that the server needs to be sure to nest its [MultiChannel]s at
/// the same place the client does.
void main() {
  if (_currentUrl.queryParameters['debug'] == 'true') {
    dom.document.body!.classList.add('debug');
  }

  runZonedGuarded(() {
    var serverChannel = _connectToServer();
    serverChannel.stream.listen((message) {
      if (message['command'] == 'loadSuite') {
        var suiteChannel =
            serverChannel.virtualChannel((message['channel'] as num).toInt());
        var iframeChannel = _connectToIframe(
            message['url'] as String, (message['id'] as num).toInt());
        suiteChannel.pipe(iframeChannel);
      } else if (message['command'] == 'displayPause') {
        dom.document.body!.classList.add('paused');
      } else if (message['command'] == 'resume') {
        dom.document.body!.classList.remove('paused');
      } else {
        assert(message['command'] == 'closeSuite');
        _iframes.remove(message['id'])!.remove();
        _subscriptions.remove(message['id'])?.cancel();
        _domSubscriptions.remove(message['id'])?.cancel();
      }
    });

    // Send periodic pings to the test runner so it can know when the browser is
    // paused for debugging.
    Timer.periodic(Duration(seconds: 1),
        (_) => serverChannel.sink.add({'command': 'ping'}));

    var play = dom.document.querySelector('#play');
    play!.addEventListener('click', allowInterop((_) {
      if (!dom.document.body!.classList.contains('paused')) return;
      dom.document.body!.classList.remove('paused');
      serverChannel.sink.add({'command': 'resume'});
    }));

    _jsApi = _JSApi(resume: allowInterop(() {
      if (!dom.document.body!.classList.contains('paused')) return;
      dom.document.body!.classList.remove('paused');
      serverChannel.sink.add({'command': 'resume'});
    }), restartCurrent: allowInterop(() {
      serverChannel.sink.add({'command': 'restart'});
    }));
  }, (error, stackTrace) {
    print('$error\n${Trace.from(stackTrace).terse}');
  });
}

/// Creates a [MultiChannel] connection to the server, using a [WebSocket] as
/// the underlying protocol.
MultiChannel<dynamic> _connectToServer() {
  // The `managerUrl` query parameter contains the WebSocket URL of the remote
  // [BrowserManager] with which this communicates.
  var webSocket =
      dom.createWebSocket(_currentUrl.queryParameters['managerUrl']!);

  var controller = StreamChannelController(sync: true);
  webSocket.addEventListener('message', allowInterop((message) {
    controller.local.sink
        .add(jsonDecode((message as dom.MessageEvent).data as String));
  }));

  controller.local.stream
      .listen((message) => webSocket.send(jsonEncode(message)));

  return MultiChannel(controller.foreign);
}

/// Creates an iframe with `src` [url] and establishes a connection to it using
/// a [MessageChannel].
///
/// [id] identifies the suite loaded in this iframe.
StreamChannel<dynamic> _connectToIframe(String url, int id) {
  var iframe = dom.createHTMLIFrameElement();
  _iframes[id] = iframe;
  iframe.src = url;
  dom.document.body!.appendChild(iframe);

  var controller = StreamChannelController(sync: true);

  late dom.Subscription windowSubscription;
  windowSubscription =
      dom.Subscription(dom.window, 'message', allowInterop((dom.Event event) {
    // A message on the Window can theoretically come from any website. It's
    // very unlikely that a malicious site would care about hacking someone's
    // unit tests, let alone be able to find the test server while it's
    // running, but it's good practice to check the origin anyway.
    var message = event as dom.MessageEvent;
    if (message.origin != dom.window.location.origin) return;
    // Disambiguate between frames for different test suites.
    // Depending on the source type, the `location.href` may be missing.
    var location = js_util.getProperty(message.source, 'location') as Object?;
    if (location == null) return;
    if (js_util.getProperty(location, 'href') != iframe.src) return;

    message.stopPropagation();
    windowSubscription.cancel();

    if (message.data['ready'] == true) {
      // This message indicates that the iframe is actively listening for
      // events, so the message channel's second port can now be transferred.
      var channel = dom.createMessageChannel();
      assert(!_domSubscriptions.containsKey(id));
      _domSubscriptions[id] = dom.Subscription(channel.port1, 'message',
          allowInterop((dom.Event event) {
        controller.local.sink.add((event as dom.MessageEvent).data['data']);
      }));

      assert(!_subscriptions.containsKey(id));
      _subscriptions[id] =
          controller.local.stream.listen(channel.port1.postMessage);
      channel
        ..port2.start()
        ..port1.start();
      // TODO(#1758): This is a work around for a crash in package:build.
      js_util.callMethod(
          js_util.getProperty(iframe, 'contentWindow'), 'postMessage', [
        'port',
        dom.window.location.origin,
        [channel.port2]
      ]);
    } else if (message.data['exception'] == true) {
      // This message from `dart.js` indicates that an exception occurred
      // loading the test.
      controller.local.sink.add(message.data['data']);
    }
  }));

  return controller.foreign;
}
