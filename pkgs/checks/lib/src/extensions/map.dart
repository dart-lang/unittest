// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:checks/context.dart';

import '../collection_equality.dart';
import 'core.dart';

extension MapChecks<K, V> on Subject<Map<K, V>> {
  Subject<Iterable<MapEntry<K, V>>> get haveEntries =>
      have((m) => m.entries, 'entries');
  Subject<Iterable<K>> get haveKeys => have((m) => m.keys, 'keys');
  Subject<Iterable<V>> get haveValues => have((m) => m.values, 'values');
  Subject<int> get haveLength => have((m) => m.length, 'length');
  Subject<V> operator [](K key) {
    final keyString = literal(key).join(r'\n');
    return context.nest('contains a value for $keyString', (actual) {
      if (!actual.containsKey(key)) {
        return Extracted.rejection(
            which: ['does not contain the key $keyString']);
      }
      return Extracted.value(actual[key] as V);
    });
  }

  void beEmpty() {
    context.expect(() => const ['is empty'], (actual) {
      if (actual.isEmpty) return null;
      return Rejection(which: ['is not empty']);
    });
  }

  void beNotEmpty() {
    context.expect(() => const ['is not empty'], (actual) {
      if (actual.isNotEmpty) return null;
      return Rejection(which: ['is not empty']);
    });
  }

  /// Expects that the map contains [key] according to [Map.containsKey].
  void containKey(K key) {
    final keyString = literal(key).join(r'\n');
    context.expect(() => ['contains key $keyString'], (actual) {
      if (actual.containsKey(key)) return null;
      return Rejection(which: ['does not contain key $keyString']);
    });
  }

  /// Expects that the map contains some key such that [keyCondition] is
  /// satisfied.
  void containKeyWhich(Condition<K> keyCondition) {
    context.expect(() {
      final conditionDescription = describe(keyCondition);
      assert(conditionDescription.isNotEmpty);
      return [
        'contains a key that:',
        ...conditionDescription,
      ];
    }, (actual) {
      if (actual.isEmpty) return Rejection(actual: ['an empty map']);
      for (var k in actual.keys) {
        if (softCheck(k, keyCondition) == null) return null;
      }
      return Rejection(which: ['Contains no matching key']);
    });
  }

  /// Expects that the map contains [value] according to [Map.containsValue].
  void containValue(V value) {
    final valueString = literal(value).join(r'\n');
    context.expect(() => ['contains value $valueString'], (actual) {
      if (actual.containsValue(value)) return null;
      return Rejection(which: ['does not contain value $valueString']);
    });
  }

  /// Expects that the map contains some value such that [valueCondition] is
  /// satisfied.
  void containValueWhich(Condition<V> valueCondition) {
    context.expect(() {
      final conditionDescription = describe(valueCondition);
      assert(conditionDescription.isNotEmpty);
      return [
        'contains a value that:',
        ...conditionDescription,
      ];
    }, (actual) {
      if (actual.isEmpty) return Rejection(actual: ['an empty map']);
      for (var v in actual.values) {
        if (softCheck(v, valueCondition) == null) return null;
      }
      return Rejection(which: ['Contains no matching value']);
    });
  }

  /// Expects that the map contains entries that are deeply equal to the entries
  /// of [expected].
  ///
  /// {@macro deep_collection_equals}
  void deeplyEqual(Map<Object?, Object?> expected) => context
          .expect(() => prefixFirst('is deeply equal to ', literal(expected)),
              (actual) {
        final which = deepCollectionEquals(actual, expected);
        if (which == null) return null;
        return Rejection(which: which);
      });
}
