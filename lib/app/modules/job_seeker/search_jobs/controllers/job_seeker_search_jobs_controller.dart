import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hire_me/app/modules/job_seeker/dashboard/models/job_model.dart';
import 'package:hire_me/app/modules/job_seeker/shared/distance_mixin.dart';
import 'package:hire_me/app/services/notification_service.dart';

class JobSeekerSearchJobsController extends GetxController with DistanceMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController searchController = TextEditingController();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _jobsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _savedJobsSubscription;

  final allJobs = <JobModel>[].obs;
  final searchResults = <JobModel>[].obs;
  final savedJobIds = <String>{}.obs;

  final isLoading = true.obs;
  final searchQuery = ''.obs;

  final sortByDistance = false.obs;

  final salaryMin = ''.obs;
  final salaryMax = ''.obs;

  final displayCount = 20.obs;
  static const int pageSize = 20;

  @override
  void onInit() {
    super.onInit();
    listenToOpenJobs();
    listenToSavedJobs();
    _watchLocation();
  }

  void _watchLocation() {
    ever(Get.find<NotificationService>().userPosition, (_) {
      if (userPosition.value != null) {
        updateJobDistancesFrom(allJobs);
        applySearch();
      }
    });
  }

  void listenToOpenJobs() {
    isLoading.value = true;

    _jobsSubscription = _firestore
        .collection('jobs')
        .where('status', isEqualTo: 'Open')
        .snapshots()
        .listen(
          (snapshot) {
            final jobs = snapshot.docs
                .map((doc) => JobModel.fromMap(doc.id, doc.data()))
                .toList();

            jobs.sort((a, b) {
              final aDate = a.createdAt?.toDate();
              final bDate = b.createdAt?.toDate();

              if (aDate == null && bDate == null) return 0;
              if (aDate == null) return 1;
              if (bDate == null) return -1;

              return bDate.compareTo(aDate);
            });

            allJobs.value = jobs;
            applySearch();
            updateJobDistancesFrom(allJobs);

            isLoading.value = false;
          },
          onError: (_) {
            isLoading.value = false;
            if (_auth.currentUser == null) return;
            Get.snackbar('Error', 'Failed to load jobs');
          },
        );
  }

  void listenToSavedJobs() {
    final uid = _auth.currentUser?.uid;

    if (uid == null) return;

    _savedJobsSubscription = _firestore
        .collection('savedJobs')
        .where('seekerId', isEqualTo: uid)
        .snapshots()
        .listen(
          (snapshot) {
            final ids = snapshot.docs
                .map((doc) => doc.data()['jobId']?.toString() ?? '')
                .where((id) => id.isNotEmpty)
                .toSet();

            savedJobIds.clear();
            savedJobIds.addAll(ids);
          },
          onError: (_) {
            if (_auth.currentUser == null) return;
            Get.snackbar('Error', 'Failed to load saved jobs');
          },
        );
  }

  void onSearchChanged(String value) {
    searchQuery.value = value.trim();
    applySearch();
  }

  void toggleSortByDistance() {
    sortByDistance.value = !sortByDistance.value;
    applySearch();
  }

  void setSalaryMin(String value) {
    salaryMin.value = value.trim();
    applySearch();
  }

  void setSalaryMax(String value) {
    salaryMax.value = value.trim();
    applySearch();
  }

  void loadMore() {
    displayCount.value += pageSize;
  }

  void applySearch() {
    final query = searchQuery.value.toLowerCase();

    Iterable<JobModel> results;

    if (query.isEmpty) {
      results = allJobs.toList();
    } else {
      results = allJobs.where((job) {
        return job.title.toLowerCase().contains(query) ||
            job.companyName.toLowerCase().contains(query) ||
            job.mainFieldName.toLowerCase().contains(query) ||
            job.location.toLowerCase().contains(query) ||
            job.jobType.toLowerCase().contains(query) ||
            job.workMode.toLowerCase().contains(query) ||
            job.description.toLowerCase().contains(query) ||
            job.requirements.toLowerCase().contains(query);
      });
    }

    if (salaryMin.value.isNotEmpty || salaryMax.value.isNotEmpty) {
      final minVal = num.tryParse(salaryMin.value);
      final maxVal = num.tryParse(salaryMax.value);

      results = results.where((job) {
        if (minVal != null && maxVal != null) {
          return (job.minSalary ?? 0) <= maxVal &&
              (job.maxSalary ?? double.infinity) >= minVal;
        }
        if (minVal != null) {
          return (job.maxSalary ?? double.infinity) >= minVal;
        }
        if (maxVal != null) {
          return (job.minSalary ?? 0) <= maxVal;
        }
        return true;
      });
    }

    if (sortByDistance.value && userPosition.value != null) {
      results = results.toList()
        ..sort((a, b) {
          final distA = jobDistances[a.companyId] ?? double.infinity;
          final distB = jobDistances[b.companyId] ?? double.infinity;
          return distA.compareTo(distB);
        });
    }

    searchResults.value = results.toList();
    displayCount.value = pageSize;
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    salaryMin.value = '';
    salaryMax.value = '';
    displayCount.value = pageSize;
    searchResults.value = allJobs;
  }

  bool isJobSaved(String jobId) {
    return savedJobIds.contains(jobId);
  }

  Future<void> toggleSaveJob(String jobId) async {
    try {
      final uid = _auth.currentUser?.uid;

      if (uid == null) {
        Get.snackbar('Login Required', 'Please login to save jobs');
        return;
      }

      final docId = '${uid}_$jobId';
      final savedJobRef = _firestore.collection('savedJobs').doc(docId);

      if (isJobSaved(jobId)) {
        await savedJobRef.delete();
      } else {
        await savedJobRef.set({
          'seekerId': uid,
          'jobId': jobId,
          'savedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      Get.snackbar('Error', 'Failed to update saved job');
    }
  }

  Future<void> refreshSearch() async {
    applySearch();
  }

  @override
  void onClose() {
    _jobsSubscription?.cancel();
    _savedJobsSubscription?.cancel();
    searchController.dispose();
    super.onClose();
  }
}
