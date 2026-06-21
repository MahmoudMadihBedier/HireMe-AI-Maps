# Testing Guide

## Running Tests

```bash
flutter test                          # All tests
flutter test test/<file>.dart         # Single file
flutter test --no-pub                 # Skip pub get (matches CI)
```

CI runs `flutter test --no-pub`. Always pass `--no-pub` to match CI.

## Conventions

- **Manual fakes only** — no mockito, no mocktail. Write fake classes that mirror the controller's dependencies.
- **No Firebase/Supabase init** needed in tests.
- Call `Get.reset()` in `tearDown` (and `setUp` if it registers GetX controllers).
- Test types must be `public` (no `_` prefix) if used in top-level function signatures, otherwise lint complains.

All tests live in `test/` — there are no subdirectories.

## Pattern

Replicate the controller logic in a top-level function or a lightweight fake class. Keep fakes minimal:

```dart
class FakeJob {
  final String title;
  final String location;
  FakeJob({required this.title, required this.location});
}

List<FakeJob> applyFilters(List<FakeJob> jobs, String query) {
  if (query.isEmpty) return jobs;
  return jobs.where((j) => j.title.contains(query)).toList();
}

void main() {
  group('applyFilters', () {
    test('returns all jobs when query is empty', () {
      final jobs = [FakeJob(title: 'Dev', location: 'Remote')];
      expect(applyFilters(jobs, ''), jobs);
    });
  });
}
```

For Firestore-dependent tests, create a simple fake document store:

```dart
class FakeFirestoreDoc {
  Map<String, dynamic>? data;
  bool deleted = false;
  void set(Map<String, dynamic> newData) {
    data = Map.from(newData); deleted = false;
  }
  void delete() { deleted = true; data = null; }
}

class FakeFirestoreCollection {
  final Map<String, FakeFirestoreDoc> _docs = {};
  FakeFirestoreDoc doc(String id) => _docs.putIfAbsent(id, () => FakeFirestoreDoc());
}

class FakeFirestore {
  final Map<String, FakeFirestoreCollection> _collections = {};
  FakeFirestoreCollection collection(String name) =>
      _collections.putIfAbsent(name, () => FakeFirestoreCollection());
}
```

Pass the fake into a testable controller mirror:

```dart
class FakeSavedJobsController {
  final FakeFirestore firestore;
  final String? uid;
  final Set<String> savedJobIds = {};
  ...
}
```

## Existing Tests

| File | Coverage |
|------|----------|
| `test/widget_test.dart` | Placeholder only |
| `test/auth_login_controller_test.dart` | Login validation, Firebase error messages |
| `test/job_seeker_dashboard_controller_test.dart` | Dashboard filters (mainField, jobType, workMode), search (title, company, field, location, description, case-insensitive), combined filters |
| `test/application_review_controller_test.dart` | Accept/reject application, Firestore merge writes, RTDB chat creation, auto-message, navigation, edge cases |
| `test/profile_controller_test.dart` | FCM token cleanup (delete from role doc + users doc, merge writes), role collection selection, sign-out sequence, edge cases |
| `test/company_dashboard_controller_test.dart` | Notification badge count, stream error handling, subscription lifecycle |
| `test/saved_jobs_test.dart` | Save/unsave toggle, document creation/deletion, multiple jobs, null UID |
| `test/notification_badge_test.dart` | Badge count, snapshot updates, stream error resets |
| `test/fcm_routing_test.dart` | FCM data type routing (application_update, new_application, chat_message), role-aware navigation, self-message skip |
| `test/password_reset_test.dart` | Request reset (valid/invalid email), reset password (validation, navigation), login with new password |
| `test/role_guard_middleware_test.dart` | Auth guard, role validation, route blocking by role |

## What Not to Test

- Pure UI rendering (pixel-perfect widget tests) — not worth the maintenance.
- Third-party SDK initialization (Firebase, Supabase).
- Google Maps callbacks.

## Code Review Checklist

- [ ] Fakes are used, no mockito/mocktail.
- [ ] `Get.reset()` called in `tearDown`.
- [ ] No real Firebase/Supabase imports in test files.
- [ ] Test names describe behaviour, not implementation.
