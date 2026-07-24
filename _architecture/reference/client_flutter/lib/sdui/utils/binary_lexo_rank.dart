import 'dart:typed_data';
import 'dart:math';

/// A highly optimized binary fractional indexing algorithm (LexoRank)
/// for zero-collision, O(1) database write reordering.
class BinaryLexoRank {
  /// Returns a byte array strictly between [a] and [b].
  /// Requires [a] < [b] lexicographically.
  static Uint8List between(Uint8List a, Uint8List b) {
    int maxLen = max(a.length, b.length);
    List<int> result = [];

    for (int i = 0; i < maxLen; i++) {
      int byteA = i < a.length ? a[i] : 0;
      int byteB = i < b.length ? b[i] : 0;

      if (byteA == byteB) {
        result.add(byteA);
        continue;
      }

      int diff = byteB - byteA;

      if (diff > 1) {
        // Comfortable gap. Find the integer midpoint.
        result.add(byteA + (diff ~/ 2));
        break; // Stop here, we found the midpoint
      } else {
        // Collision (diff == 1). We cannot fit an integer here.
        // We append byteA, which guarantees result < b.
        result.add(byteA);

        // Now cascade down `a` to ensure result > a.
        int j = i + 1;
        while (true) {
          int nextA = j < a.length ? a[j] : 0;
          if (nextA < 254) {
            // Find a midpoint between nextA and 255.
            result.add(nextA + ((255 - nextA) ~/ 2));
            break;
          } else if (nextA == 254) {
            result.add(255);
            break;
          } else {
            // nextA == 255. We maxed out. Append 255 and cascade to next byte.
            result.add(255);
            j++;
          }
        }
        break; // Done with the entire between() function
      }
    }
    return Uint8List.fromList(result);
  }

  /// Returns a byte array strictly before [b].
  static Uint8List before(Uint8List b) {
    if (b.isEmpty) return Uint8List.fromList([128]);
    List<int> result = [];
    
    for (int i = 0; i < b.length; i++) {
      int byteB = b[i];
      if (byteB > 1) {
        result.add(byteB ~/ 2);
        return Uint8List.fromList(result);
      } else if (byteB == 1) {
        result.add(0);
        result.add(128); // Cascade halfway down
        return Uint8List.fromList(result);
      } else {
        // byteB == 0
        result.add(0);
      }
    }
    
    // Theoretical limit (e.g. b was [0,0,0]). Should never be reached in a normal Zeno paradox prepend.
    throw Exception("LexoRank: Cannot prepend before absolute zero blob.");
  }

  /// Returns a byte array strictly after [a].
  static Uint8List after(Uint8List a) {
    if (a.isEmpty) return Uint8List.fromList([128]);
    List<int> result = [];
    
    for (int i = 0; i < a.length; i++) {
      int byteA = a[i];
      if (byteA < 254) {
        result.add(byteA + ((255 - byteA) ~/ 2));
        return Uint8List.fromList(result);
      } else if (byteA == 254) {
        result.add(255);
        return Uint8List.fromList(result);
      } else {
        result.add(255);
      }
    }
    
    // If we exhausted `a` and it was all 255s (e.g. [255, 255]), append 128.
    result.add(128);
    return Uint8List.fromList(result);
  }
}
