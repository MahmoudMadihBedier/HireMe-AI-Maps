import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hire_me/core/utils/app_color.dart';

class CompanyMapController extends GetxController {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final isEditMode = false.obs;
  final companyName = ''.obs;
  final selectedLocation = Rx<LatLng?>(null);
  final savedLocation = Rx<LatLng?>(null);
  final cameraPosition = LatLng(31.9, 35.2).obs;
  final isLoading = false.obs;
  GoogleMapController? mapController;
  Position? _devicePosition;

  @override
  void onInit() {
    super.onInit();
    _initLocation();
  }

  Future<void> _initLocation() async {
    debugPrint('_initLocation start');
    final user = _auth.currentUser;

    try {
      final status = await Geolocator.requestPermission();
      if (status == LocationPermission.always ||
          status == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition();
        _devicePosition = position;
        debugPrint(
            'Device position: ${position.latitude}, ${position.longitude}');
        cameraPosition.value = LatLng(position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint('Get current location error: $e');
    }

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
            final latDouble = (lat as num).toDouble();
            final lngDouble = (lng as num).toDouble();
            savedLocation.value = LatLng(latDouble, lngDouble);
            companyName.value =
                data['companyName']?.toString() ?? data['name']?.toString() ?? '';
            debugPrint('Saved location from Firestore: $lat, $lng');
          } else {
            debugPrint('Saved location from Firestore: No saved location');
          }
        } else {
          debugPrint('Saved location from Firestore: No saved location');
        }
      } catch (e) {
        debugPrint('Load saved location error: $e');
        debugPrint('Saved location from Firestore: No saved location');
      }
    }

    if (_devicePosition != null && mapController != null) {
      await mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_devicePosition!.latitude, _devicePosition!.longitude),
          14,
        ),
      );
      debugPrint('animateCamera called');
    }
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (_devicePosition != null) {
      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_devicePosition!.latitude, _devicePosition!.longitude),
          14,
        ),
      );
      debugPrint('animateCamera called');
    }
  }

  void onMapTap(LatLng position) {
    if (!isEditMode.value) return;
    selectedLocation.value = position;
    debugPrint('onMapTap: ${position.latitude}, ${position.longitude}');
  }

  void enterEditMode() {
    isEditMode.value = true;
    debugPrint('enterEditMode called');
  }

  void cancelEdit() {
    isEditMode.value = false;
    selectedLocation.value = null;
    debugPrint('cancelEdit called');
  }

  void resetLocation() {
    selectedLocation.value = null;
  }

  Future<String> _getLocationName(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return [
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((s) => s != null && s.isNotEmpty).join(', ');
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
    return '$lat, $lng';
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

    debugPrint(
        'saveLocation called with: ${location.latitude}, ${location.longitude}');

    isLoading.value = true;
    try {
      final name = await _getLocationName(location.latitude, location.longitude);
      await _firestore.collection('companies').doc(user.uid).set({
        'latitude': location.latitude,
        'longitude': location.longitude,
        'location': name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      savedLocation.value = location;
      selectedLocation.value = null;
      isEditMode.value = false;
      debugPrint('saveLocation success');

      Get.snackbar(
        'Success',
        'Location saved successfully',
        backgroundColor: AppColor.ksuccess,
        colorText: Colors.white,
      );
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
