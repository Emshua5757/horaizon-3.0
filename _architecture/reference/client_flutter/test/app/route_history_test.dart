import 'package:flutter_test/flutter_test.dart';
import 'package:client_flutter/app/route_history.dart';

void main() {
  group('BoundedRouteHistory Tests', () {
    test('Initial empty state should correctly report boundaries', () {
      final history = BoundedRouteHistory();

      // The 'expect' function is how we mathematically assert conditions.
      // We provide a 'reason' to make failure logs extremely clear.
      expect(
        history.isEmpty,
        isTrue,
        reason: 'A new history stack must be empty',
      );
      expect(
        history.canGoBack,
        isFalse,
        reason: 'Cannot go back on an empty stack',
      );
      expect(
        history.canGoForward,
        isFalse,
        reason: 'Cannot go forward on an empty stack',
      );
    });

    test('O(1) Memory bound stress test with 15 routes', () {
      final history = BoundedRouteHistory();

      for (int i = 1; i <= 15; i++) {
        history.addRoute("Page $i");
      }
      int backSteps = 0;
      while (history.canGoBack) {
        history.moveBack();
        backSteps++;
      }
      expect(
        backSteps,
        9,
        reason:
            "With a limit of 10, sitting on the 10th node means we can only step back 9 times",
      );
    });
  });

  group('Dynamic Max Count Edge Cases', () {
    test('Case 1: User at the newest route, trims only from the past (head)', () {
      final history = BoundedRouteHistory();
      for (int i = 1; i <= 10; i++) {
        history.addRoute("Page $i");
      }

      // Shrink limit to 5 while standing on Node 10
      history.updateMaxCount(5);

      expect(
        history.canGoForward,
        isFalse,
        reason: 'User should still be at the newest node',
      );

      int backSteps = 0;
      while (history.canGoBack) {
        history.moveBack();
        backSteps++;
      }
      expect(
        backSteps,
        4,
        reason:
            'Total 5 nodes left (Nodes 6-10). Sitting on the 5th means exactly 4 steps back.',
      );
    });

    test('Case 2: User in the middle, dual-trim from head and tail', () {
      final history = BoundedRouteHistory();
      for (int i = 1; i <= 10; i++) {
        history.addRoute("Page $i");
      }

      // Move back 4 times. User is now standing on Node 6.
      for (int i = 0; i < 4; i++) {
        history.moveBack();
      }

      // Shrink limit to 3.
      // Phase 1 drops Nodes 1-5 (stops because it hits Node 6).
      // Phase 2 drops Nodes 10 and 9 to reach the target size of 3.
      // Remaining nodes should be 6, 7, 8.
      history.updateMaxCount(3);

      expect(
        history.canGoBack,
        isFalse,
        reason: 'Node 6 should have become the new absolute head.',
      );

      int forwardSteps = 0;
      while (history.canGoForward) {
        history.moveForward();
        forwardSteps++;
      }
      expect(
        forwardSteps,
        2,
        reason:
            'With a limit of 3, sitting on the head means exactly 2 steps forward.',
      );
    });

    test(
      'Case 3: User at the very beginning (head), trims only from the future (tail)',
      () {
        final history = BoundedRouteHistory();
        for (int i = 1; i <= 10; i++) {
          history.addRoute("Page $i");
        }

        // Move all the way back to Node 1
        while (history.canGoBack) {
          history.moveBack();
        }

        // Shrink limit to 4.
        // Phase 1 safely skips. Phase 2 drops 10, 9, 8, 7, 6, 5.
        // Remaining: 1, 2, 3, 4.
        history.updateMaxCount(4);

        expect(
          history.canGoBack,
          isFalse,
          reason: 'User should still be at the head.',
        );

        int forwardSteps = 0;
        while (history.canGoForward) {
          history.moveForward();
          forwardSteps++;
        }
        expect(
          forwardSteps,
          3,
          reason:
              'Sitting on Node 1 with 4 total nodes leaves exactly 3 steps forward.',
        );
      },
    );

    test('Case 4: jumpToNewest O(1) optimization check', () {
      final history = BoundedRouteHistory();
      for (int i = 1; i <= 10; i++) {
        history.addRoute("Page $i");
      }

      // Move all the way back to Node 1
      while (history.canGoBack) {
        history.moveBack();
      }

      // Fire the new engine feature
      history.jumpToNewest();

      expect(
        history.canGoForward,
        isFalse,
        reason: 'Should instantly snap to the tail',
      );

      int backSteps = 0;
      while (history.canGoBack) {
        history.moveBack();
        backSteps++;
      }
      expect(
        backSteps,
        9,
        reason: 'Full history should be intact behind the jumped node',
      );
    });
  });
}
