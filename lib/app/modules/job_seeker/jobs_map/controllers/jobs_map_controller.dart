import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:hire_me/app/modules/job_seeker/dashboard/models/job_model.dart';
import 'package:hire_me/app/modules/job_seeker/shared/distance_mixin.dart';
import 'package:hire_me/app/routes/app_pages.dart';

class JobsMapController extends GetxController with DistanceMixin {
  final isLoading = true.obs;
  final jobs = <JobModel>[].obs;
  final companyLocations = <String, LatLng>{}.obs;
  final hasLocationPermission = false.obs;
  final companiesWithNoLocation = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _requestLocationPermission();
    _fetchJobs();
  }

  Future<void> _requestLocationPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        userPosition.value = await Geolocator.getCurrentPosition();
        hasLocationPermission.value = true;
      }
    } catch (_) {
      hasLocationPermission.value = false;
    }
  }

  Future<void> _fetchJobs() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('jobs')
          .where('status', isEqualTo: 'Open')
          .get();

      final result = snapshot.docs
          .map((doc) => JobModel.fromMap(doc.id, doc.data()))
          .where((job) => !job.isDeleted)
          .toList();

      jobs.value = result;

      await Future.wait(
        result.map((job) => _fetchCompanyLocation(job.companyId)),
      );
    } catch (_) {
      Get.snackbar('Error', 'Failed to load jobs');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchCompanyLocation(String companyId) async {
    if (companyLocations.containsKey(companyId)) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .get();
      if (!doc.exists) return;
      final data = doc.data();
      final lat = data?['latitude'];
      final lng = data?['longitude'];
      if (lat == null || lng == null) return;
      companyLocations[companyId] = LatLng(
        (lat as num).toDouble(),
        (lng as num).toDouble(),
      );
    } catch (_) {}
  }

  Set<Marker> get markers {
    final result = <Marker>{};
    var skipped = 0;
    for (final job in jobs) {
      final location = companyLocations[job.companyId];
      if (location == null) {
        skipped++;
        continue;
      }
      final jobId = job.id;
      result.add(
        Marker(
          markerId: MarkerId(jobId),
          position: location,
          infoWindow: InfoWindow(
            title: job.title,
            snippet: job.companyName,
            onTap: () => _navigateToJob(jobId),
          ),
        ),
      );
    }
    companiesWithNoLocation.value = skipped;
    return result;
  }

  void _navigateToJob(String jobId) {
    final job = jobs.firstWhereOrNull((j) => j.id == jobId);
    if (job != null) {
      Get.toNamed(Routes.jobSeekerJobDetails, arguments: job);
    }
  }
}
