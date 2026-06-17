import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hire_me/core/utils/app_color.dart';

class CompanyMapController extends GetxController {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final selectedLocation = Rx<LatLng?>(null);
  final cameraPosition = LatLng(31.9, 35.2).obs;
  final isLoading = false.obs;
  GoogleMapController? mapController;

  bool get hasSelection => selectedLocation.value != null;

  @override
  void onInit() {
    super.onInit();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final user = _auth.currentUser;

    // Priority 1: device current position → camera
    try {
      final status = await Geolocator.requestPermission();
      if (status == LocationPermission.always ||
          status == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition();
        cameraPosition.value = LatLng(position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint('Get current location error: $e');
    }

    // Priority 2: saved location from Firestore → marker only, no camera move
    if (user != null) {
      try {
        final doc = await _firestore
            .collection('companies')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final lat = data['latitude'];
          final lng = data['longitude'];
          if (lat != null && lng != null) {
            selectedLocation.value = LatLng(
              (lat as num).toDouble(),
              (lng as num).toDouble(),
            );
          }
        }
      } catch (e) {
        debugPrint('Load existing location error: $e');
      }
    }
  }

  void onMapTap(LatLng position) {
    if (selectedLocation.value == null) {
      selectedLocation.value = position;
    }
  }

  void resetLocation() {
    selectedLocation.value = null;
  }

  Future<void> saveLocation() async {
    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar(
        'Error',
        'Please login first',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final location = selectedLocation.value;
    if (location == null) return;

    isLoading.value = true;
    try {
      await _firestore.collection('companies').doc(user.uid).set({
        'latitude': location.latitude,
        'longitude': location.longitude,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Get.snackbar(
        'Success',
        'Location saved successfully',
        backgroundColor: AppColor.ksuccess,
        colorText: Colors.white,
      );
      Get.back();
    } catch (e) {
      debugPrint('Save location error: $e');
      Get.snackbar(
        'Error',
        'Failed to save location',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
