import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

// ─── Fake QueryDocumentSnapshot ──────────────────────────────────────

class _FakeQueryDocumentSnapshot {
  final String id;

  _FakeQueryDocumentSnapshot({required this.id});
}

// ─── Fake QuerySnapshot ──────────────────────────────────────────────

class _FakeQuerySnapshot {
  final List<_FakeQueryDocumentSnapshot> docs;

  _FakeQuerySnapshot({required this.docs});
}

// ─── Testable controller mirroring JobSeekerDashboardController
//      notification badge logic ────────────────────────────────────────

class _FakeNotificationBadgeController {
  final badgeCount = 0.obs;

  /// Simulates the Firestore snapshot listener callback from
  /// JobSeekerDashboardController.listenToNotificationBadge():
  ///   .map((snap) => snap.docs.length)
  ///   .listen(
  ///     (count) => notificationBadgeCount.value = count,
  ///     onError: (_) => notificationBadgeCount.value = 0,
  ///   );
  void onBadgeSnapshot(_FakeQuerySnapshot snapshot) {
    badgeCount.value = snapshot.docs.length;
  }

  /// Simulates the stream error callback
  void onBadgeError(Object error) {
    badgeCount.value = 0;
  }
}

// ─── Tests ───────────────────────────────────────────────────────────

void main() {
  late _FakeNotificationBadgeController controller;

  setUp(() {
    controller = _FakeNotificationBadgeController();
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('Initial state', () {
    test('badgeCount should start at 0', () {
      expect(controller.badgeCount.value, 0);
    });
  });

  group('Snapshot updates', () {
    test('should update badgeCount when snapshot has unread notifications',
        () {
      final snapshot = _FakeQuerySnapshot(
        docs: [
          _FakeQueryDocumentSnapshot(id: 'notif-1'),
        ],
      );

      controller.onBadgeSnapshot(snapshot);

      expect(controller.badgeCount.value, 1);
    });

    test('should update badgeCount with multiple unread notifications',
        () {
      final snapshot = _FakeQuerySnapshot(
        docs: [
          _FakeQueryDocumentSnapshot(id: 'notif-1'),
          _FakeQueryDocumentSnapshot(id: 'notif-2'),
          _FakeQueryDocumentSnapshot(id: 'notif-3'),
        ],
      );

      controller.onBadgeSnapshot(snapshot);

      expect(controller.badgeCount.value, 3);
    });

    test('should reset badgeCount to 0 when all notifications are read',
        () {
      controller.badgeCount.value = 3;

      final snapshot = _FakeQuerySnapshot(docs: []);

      controller.onBadgeSnapshot(snapshot);

      expect(controller.badgeCount.value, 0);
    });
  });

  group('Error handling', () {
    test('should reset badgeCount to 0 on stream error', () {
      controller.badgeCount.value = 5;

      controller.onBadgeError(Exception('stream error'));

      expect(controller.badgeCount.value, 0);
    });

    test('badgeCount stays at 0 on error when already 0', () {
      controller.onBadgeError(Exception('stream error'));

      expect(controller.badgeCount.value, 0);
    });
  });
}
