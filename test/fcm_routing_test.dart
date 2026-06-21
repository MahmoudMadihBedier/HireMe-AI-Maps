import 'package:flutter_test/flutter_test.dart';

// ─── Navigation history recorder ─────────────────────────────────────

class _FakeNavigator {
  final List<String> namedRoutes = [];
  String? lastRoute;
  dynamic lastArgs;

  void toNamed(String route, {dynamic arguments}) {
    namedRoutes.add(route);
    lastRoute = route;
    lastArgs = arguments;
  }
}

// ─── Testable notification routing logic ──────────────────────────────

class _FakeNotificationRouter {
  final _FakeNavigator navigator;
  final String? currentUid;
  final String? userRole;

  _FakeNotificationRouter({
    required this.navigator,
    this.currentUid,
    this.userRole,
  });

  void navigateFromData(Map<String, dynamic> data) {
    final type = data['type'];

    switch (type) {
      case 'application_update':
        navigator.toNamed('/job-seeker/notifications');
        break;
      case 'new_application':
        navigator.toNamed('/application-list');
        break;
      case 'chat_message':
        final chatId = data['chatId'] as String?;
        final senderId = data['senderId'] as String?;
        if (chatId == null || senderId == null) break;
        if (currentUid == null || currentUid == senderId) break;
        if (userRole == 'jobSeeker') {
          navigator.toNamed('/job-seeker/chat-details', arguments: chatId);
        } else if (userRole == 'company') {
          navigator.toNamed('/company/chat-details', arguments: chatId);
        }
        break;
    }
  }
}

// ─── Tests ───────────────────────────────────────────────────────────

void main() {
  group('FCM Routing', () {
    test('routes application_update to job seeker notifications', () {
      final navigator = _FakeNavigator();
      final router = _FakeNotificationRouter(navigator: navigator);

      router.navigateFromData({'type': 'application_update'});

      expect(navigator.lastRoute, '/job-seeker/notifications');
    });

    test('routes new_application to application list', () {
      final navigator = _FakeNavigator();
      final router = _FakeNotificationRouter(navigator: navigator);

      router.navigateFromData({'type': 'new_application'});

      expect(navigator.lastRoute, '/application-list');
    });

    test('routes chat_message to job seeker chat details', () {
      final navigator = _FakeNavigator();
      final router = _FakeNotificationRouter(
        navigator: navigator,
        currentUid: 'seeker-1',
        userRole: 'jobSeeker',
      );

      router.navigateFromData({
        'type': 'chat_message',
        'chatId': 'chat-123',
        'senderId': 'company-1',
      });

      expect(navigator.lastRoute, '/job-seeker/chat-details');
      expect(navigator.lastArgs, 'chat-123');
    });

    test('routes chat_message to company chat details for company role',
        () {
      final navigator = _FakeNavigator();
      final router = _FakeNotificationRouter(
        navigator: navigator,
        currentUid: 'company-1',
        userRole: 'company',
      );

      router.navigateFromData({
        'type': 'chat_message',
        'chatId': 'chat-456',
        'senderId': 'seeker-1',
      });

      expect(navigator.lastRoute, '/company/chat-details');
      expect(navigator.lastArgs, 'chat-456');
    });

    test('does not route chat_message when uid matches senderId', () {
      final navigator = _FakeNavigator();
      final router = _FakeNotificationRouter(
        navigator: navigator,
        currentUid: 'user-1',
        userRole: 'jobSeeker',
      );

      router.navigateFromData({
        'type': 'chat_message',
        'chatId': 'chat-123',
        'senderId': 'user-1',
      });

      expect(navigator.lastRoute, isNull);
    });

    test('does not route chat_message when chatId is missing', () {
      final navigator = _FakeNavigator();
      final router = _FakeNotificationRouter(
        navigator: navigator,
        currentUid: 'seeker-1',
        userRole: 'jobSeeker',
      );

      router.navigateFromData({
        'type': 'chat_message',
        'senderId': 'company-1',
      });

      expect(navigator.lastRoute, isNull);
    });
  });
}
