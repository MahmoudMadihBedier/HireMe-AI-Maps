import 'package:flutter_test/flutter_test.dart';

// ─── Fake Storage Service ─────────────────────────────────────────────

class _FakeStorage {
  String? userRole;
  bool isLoggedIn = false;
  bool clearAuthSessionCalled = false;

  static String? normalizeRole(String? role) {
    switch (role?.trim().toLowerCase()) {
      case 'company':
        return 'company';
      case 'job_seeker':
      case 'jobseeker':
      case 'job seeker':
        return 'jobSeeker';
      default:
        return null;
    }
  }

  void clearAuthSession() {
    clearAuthSessionCalled = true;
  }
}

// ─── Testable redirect logic mirroring RoleGuardMiddleware.redirect() ─

class _FakeRouteGuard {
  final _FakeStorage storage;
  final String? currentUid;

  _FakeRouteGuard({
    required this.storage,
    this.currentUid,
  });

  String? redirect(String requiredRole) {
    if (currentUid == null || !storage.isLoggedIn) {
      return '/login';
    }

    final role = _FakeStorage.normalizeRole(storage.userRole);
    if (role == null) {
      storage.clearAuthSession();
      return '/login';
    }

    if (role != requiredRole) {
      return role == 'company' ? '/company-main-wrapper' : '/main-wrapper';
    }

    return null;
  }
}

// ─── Tests ───────────────────────────────────────────────────────────

void main() {
  group('Auth guard', () {
    test('redirects to login when no user is logged in', () {
      final storage = _FakeStorage();
      final guard = _FakeRouteGuard(storage: storage, currentUid: null);

      final result = guard.redirect('jobSeeker');

      expect(result, '/login');
    });

    test('redirects to login when isLoggedIn is false', () {
      final storage = _FakeStorage()..userRole = 'jobSeeker';
      final guard = _FakeRouteGuard(
        storage: storage,
        currentUid: 'user-1',
      );

      final result = guard.redirect('jobSeeker');

      expect(result, '/login');
    });
  });

  group('Role validation', () {
    test('redirects to login when user has no role', () {
      final storage = _FakeStorage()
        ..isLoggedIn = true
        ..userRole = null;
      final guard = _FakeRouteGuard(
        storage: storage,
        currentUid: 'user-1',
      );

      final result = guard.redirect('jobSeeker');

      expect(result, '/login');
    });

    test('clears auth session when role is invalid', () {
      final storage = _FakeStorage()
        ..isLoggedIn = true
        ..userRole = null;
      final guard = _FakeRouteGuard(
        storage: storage,
        currentUid: 'user-1',
      );

      guard.redirect('jobSeeker');

      expect(storage.clearAuthSessionCalled, isTrue);
    });
  });

  group('Job seeker blocked from company routes', () {
    test('redirects job seeker to main-wrapper when accessing company route',
        () {
      final storage = _FakeStorage()
        ..isLoggedIn = true
        ..userRole = 'jobSeeker';
      final guard = _FakeRouteGuard(
        storage: storage,
        currentUid: 'seeker-1',
      );

      final result = guard.redirect('company');

      expect(result, '/main-wrapper');
    });

    test('allows job seeker on jobSeeker routes', () {
      final storage = _FakeStorage()
        ..isLoggedIn = true
        ..userRole = 'jobSeeker';
      final guard = _FakeRouteGuard(
        storage: storage,
        currentUid: 'seeker-1',
      );

      final result = guard.redirect('jobSeeker');

      expect(result, isNull);
    });
  });

  group('Company blocked from job seeker routes', () {
    test('redirects company to company-main-wrapper when accessing job seeker route',
        () {
      final storage = _FakeStorage()
        ..isLoggedIn = true
        ..userRole = 'company';
      final guard = _FakeRouteGuard(
        storage: storage,
        currentUid: 'company-1',
      );

      final result = guard.redirect('jobSeeker');

      expect(result, '/company-main-wrapper');
    });

    test('allows company on company routes', () {
      final storage = _FakeStorage()
        ..isLoggedIn = true
        ..userRole = 'company';
      final guard = _FakeRouteGuard(
        storage: storage,
        currentUid: 'company-1',
      );

      final result = guard.redirect('company');

      expect(result, isNull);
    });
  });
}
