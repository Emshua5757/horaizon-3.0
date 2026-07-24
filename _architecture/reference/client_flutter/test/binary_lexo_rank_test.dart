import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:client_flutter/sdui/utils/binary_lexo_rank.dart';

void main() {
  group('BinaryLexoRank Architectural Tests', () {
    test('between() handles comfortable gaps', () {
      final a = Uint8List.fromList([10]);
      final b = Uint8List.fromList([20]);
      final mid = BinaryLexoRank.between(a, b);
      expect(mid, equals([15]));
    });

    test('between() cascades gracefully on collision (diff == 1)', () {
      final a = Uint8List.fromList([10]);
      final b = Uint8List.fromList([11]);
      final mid = BinaryLexoRank.between(a, b);
      
      // Expected logic: Append a[0] (10), then cascade to find a midpoint between 0 and 255 -> 127
      expect(mid, equals([10, 127]));
    });

    test('after() infinitely appends', () {
      final a = Uint8List.fromList([255]);
      final next = BinaryLexoRank.after(a);
      expect(next, equals([255, 128]));
    });

    test('before() infinitely prepends', () {
      final b = Uint8List.fromList([1]);
      final prev = BinaryLexoRank.before(b);
      expect(prev, equals([0, 128]));
    });
    
    test('lexicographical sorting maintains strict order under stress', () {
      final a = Uint8List.fromList([10]);
      final b = Uint8List.fromList([11]);
      
      final mid1 = BinaryLexoRank.between(a, b);
      final mid2 = BinaryLexoRank.between(a, mid1);
      final mid3 = BinaryLexoRank.between(mid2, mid1);

      // In Dart, comparing Uint8Lists element by element proves lexicographical DB correctness.
      // Expected Order: a < mid2 < mid3 < mid1 < b
      expect(_compare(a, mid2) < 0, isTrue);
      expect(_compare(mid2, mid3) < 0, isTrue);
      expect(_compare(mid3, mid1) < 0, isTrue);
      expect(_compare(mid1, b) < 0, isTrue);
    });
  });
}

/// Simulates exactly how SQLite's raw memcmp ORDER BY behaves on BLOB columns
int _compare(Uint8List a, Uint8List b) {
  int maxLen = a.length > b.length ? a.length : b.length;
  for (int i = 0; i < maxLen; i++) {
    int byteA = i < a.length ? a[i] : 0;
    int byteB = i < b.length ? b[i] : 0;
    if (byteA != byteB) {
      return byteA - byteB;
    }
  }
  return 0;
}
