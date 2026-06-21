import 'package:flutter_test/flutter_test.dart';

// ─── Fake Firestore ──────────────────────────────────────────────────

class _FakeFirestoreDoc {
  Map<String, dynamic>? data;
  bool deleted = false;

  void set(Map<String, dynamic> newData) {
    data = Map<String, dynamic>.from(newData);
    deleted = false;
  }

  void delete() {
    deleted = true;
    data = null;
  }
}

class _FakeFirestoreCollection {
  final Map<String, _FakeFirestoreDoc> _docs = {};

  _FakeFirestoreDoc doc(String id) {
    _docs.putIfAbsent(id, () => _FakeFirestoreDoc());
    return _docs[id]!;
  }
}

class _FakeFirestore {
  final Map<String, _FakeFirestoreCollection> _collections = {};

  _FakeFirestoreCollection collection(String name) {
    _collections.putIfAbsent(name, () => _FakeFirestoreCollection());
    return _collections[name]!;
  }
}

// ─── Testable controller mirroring save/unsave logic ─────────────────

class _FakeSavedJobsController {
  final _FakeFirestore firestore;
  final String? uid;
  final List<String> navigationHistory = [];
  final Set<String> savedJobIds = {};

  _FakeSavedJobsController({
    required this.firestore,
    this.uid,
  });

  bool isJobSaved(String jobId) => savedJobIds.contains(jobId);

  Future<void> toggleSaveJob(String jobId) async {
    if (uid == null) return;

    final docId = '${uid}_$jobId';
    final ref = firestore.collection('savedJobs').doc(docId);

    if (isJobSaved(jobId)) {
      ref.delete();
      savedJobIds.remove(jobId);
    } else {
      ref.set({'seekerId': uid, 'jobId': jobId, 'savedAt': 'now'});
      savedJobIds.add(jobId);
    }
  }
}

// ─── Tests ───────────────────────────────────────────────────────────

void main() {
  group('Save Job', () {
    test('creates a savedJobs document when saving a job', () async {
      final firestore = _FakeFirestore();
      final controller = _FakeSavedJobsController(
        firestore: firestore,
        uid: 'user-1',
      );

      await controller.toggleSaveJob('job-42');

      final doc = firestore.collection('savedJobs').doc('user-1_job-42');
      expect(doc.data, isNotNull);
      expect(doc.data!['jobId'], 'job-42');
      expect(doc.data!['seekerId'], 'user-1');
    });

    test('isJobSaved returns true after saving', () async {
      final firestore = _FakeFirestore();
      final controller = _FakeSavedJobsController(
        firestore: firestore,
        uid: 'user-1',
      );

      await controller.toggleSaveJob('job-42');

      expect(controller.isJobSaved('job-42'), isTrue);
    });
  });

  group('Unsave Job', () {
    test('deletes the savedJobs document when unsaving', () async {
      final firestore = _FakeFirestore();
      final controller = _FakeSavedJobsController(
        firestore: firestore,
        uid: 'user-1',
      );

      await controller.toggleSaveJob('job-42');
      await controller.toggleSaveJob('job-42');

      final doc = firestore.collection('savedJobs').doc('user-1_job-42');
      expect(doc.deleted, isTrue);
      expect(doc.data, isNull);
    });

    test('isJobSaved returns false after unsaving', () async {
      final firestore = _FakeFirestore();
      final controller = _FakeSavedJobsController(
        firestore: firestore,
        uid: 'user-1',
      );

      await controller.toggleSaveJob('job-42');
      await controller.toggleSaveJob('job-42');

      expect(controller.isJobSaved('job-42'), isFalse);
    });
  });

  group('Multiple Operations', () {
    test('saves and unsaves multiple jobs independently', () async {
      final firestore = _FakeFirestore();
      final controller = _FakeSavedJobsController(
        firestore: firestore,
        uid: 'user-1',
      );

      await controller.toggleSaveJob('job-1');
      await controller.toggleSaveJob('job-2');
      await controller.toggleSaveJob('job-3');

      expect(controller.isJobSaved('job-1'), isTrue);
      expect(controller.isJobSaved('job-2'), isTrue);
      expect(controller.isJobSaved('job-3'), isTrue);

      await controller.toggleSaveJob('job-2');

      expect(controller.isJobSaved('job-1'), isTrue);
      expect(controller.isJobSaved('job-2'), isFalse);
      expect(controller.isJobSaved('job-3'), isTrue);
    });

    test('re-saving an unshared job creates the document again', () async {
      final firestore = _FakeFirestore();
      final controller = _FakeSavedJobsController(
        firestore: firestore,
        uid: 'user-1',
      );

      await controller.toggleSaveJob('job-1');
      await controller.toggleSaveJob('job-1');
      await controller.toggleSaveJob('job-1');

      final doc = firestore.collection('savedJobs').doc('user-1_job-1');
      expect(doc.data, isNotNull);
      expect(doc.data!['jobId'], 'job-1');
      expect(controller.isJobSaved('job-1'), isTrue);
    });
  });

  group('Null UID', () {
    test('does nothing when uid is null', () async {
      final firestore = _FakeFirestore();
      final controller = _FakeSavedJobsController(
        firestore: firestore,
        uid: null,
      );

      await controller.toggleSaveJob('job-42');

      final doc = firestore.collection('savedJobs').doc('null_job-42');
      expect(doc.data, isNull);
    });
  });
}
