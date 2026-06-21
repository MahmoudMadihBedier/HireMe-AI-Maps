import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hire_me/app/services/notification_service.dart';

import '../dashboard/models/job_model.dart';

mixin DistanceMixin on GetxController {
  Rx<Position?> get userPosition =>
      Get.find<NotificationService>().userPosition;
  final jobDistances = RxMap<String, double?>();

  Future<double?> getDistanceToCompany(String companyId) async {
    if (userPosition.value == null) return null;
    if (jobDistances.containsKey(companyId)) return jobDistances[companyId];
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('companies')
              .doc(companyId)
              .get();
      if (!doc.exists) {
        jobDistances[companyId] = null;
        return null;
      }
      final data = doc.data();
      final lat = data?['latitude'];
      final lng = data?['longitude'];
      if (lat == null || lng == null) {
        jobDistances[companyId] = null;
        return null;
      }
      final distance = Geolocator.distanceBetween(
        userPosition.value!.latitude,
        userPosition.value!.longitude,
        (lat as num).toDouble(),
        (lng as num).toDouble(),
      );
      final km = double.parse((distance / 1000).toStringAsFixed(1));
      jobDistances[companyId] = km;
      return km;
    } catch (_) {
      jobDistances[companyId] = null;
      return null;
    }
  }

  Future<void> updateJobDistancesFrom(Iterable<JobModel> jobs) async {
    final companyIds = jobs.map((j) => j.companyId).toSet();
    for (final id in companyIds) {
      await getDistanceToCompany(id);
    }
  }
}
