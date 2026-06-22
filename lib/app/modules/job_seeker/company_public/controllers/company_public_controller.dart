import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:hire_me/app/modules/job_seeker/dashboard/models/job_model.dart';

class CompanyPublicController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final isLoading = true.obs;
  final errorMessage = ''.obs;

  final companyName = ''.obs;
  final email = ''.obs;
  final phone = ''.obs;
  final website = ''.obs;
  final description = ''.obs;
  final logoUrl = ''.obs;
  final location = ''.obs;
  final latitude = 0.0.obs;
  final longitude = 0.0.obs;

  final jobs = <JobModel>[].obs;
  final totalJobs = 0.obs;

  final String companyId;

  CompanyPublicController({required this.companyId});

  @override
  void onInit() {
    super.onInit();
    loadCompany();
    listenToJobs();
  }

  Future<void> loadCompany() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final doc = await _firestore.collection('companies').doc(companyId).get();

      if (!doc.exists || doc.data() == null) {
        errorMessage.value = 'Company not found';
        return;
      }

      final data = doc.data()!;
      companyName.value = data['companyName']?.toString() ?? 'Company';
      email.value = data['email']?.toString() ?? '';
      phone.value = data['phone']?.toString() ?? '';
      website.value = data['website']?.toString() ?? '';
      description.value = data['description']?.toString() ?? '';
      logoUrl.value = data['logoUrl']?.toString() ?? '';
      location.value = data['location']?.toString() ?? '';

      final lat = data['latitude'];
      final lng = data['longitude'];
      if (lat != null) latitude.value = (lat as num).toDouble();
      if (lng != null) longitude.value = (lng as num).toDouble();
    } catch (e) {
      errorMessage.value = 'Failed to load company profile';
    } finally {
      isLoading.value = false;
    }
  }

  void listenToJobs() {
    _firestore
        .collection('jobs')
        .where('companyId', isEqualTo: companyId)
        .where('isDeleted', isEqualTo: false)
        .where('status', isEqualTo: 'Open')
        .snapshots()
        .listen(
      (snapshot) {
        jobs.value = snapshot.docs
            .map((doc) => JobModel.fromMap(doc.id, doc.data()))
            .where((j) => j.isActive && !j.isDeletedJob)
            .toList();
        totalJobs.value = jobs.length;
      },
      onError: (_) {
        Get.snackbar('Error', 'Failed to load jobs',
            snackPosition: SnackPosition.BOTTOM);
      },
    );
  }

  Set<Marker> get markers {
    if (latitude.value == 0 && longitude.value == 0) return {};
    return {
      Marker(
        markerId: const MarkerId('company'),
        position: LatLng(latitude.value, longitude.value),
        infoWindow: InfoWindow(title: companyName.value),
      ),
    };
  }
}
