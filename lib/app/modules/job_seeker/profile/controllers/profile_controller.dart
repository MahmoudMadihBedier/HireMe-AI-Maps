import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hire_me/app/modules/job_seeker/profile/models/user_model.dart';
import 'package:hire_me/app/routes/app_pages.dart';
import 'package:hire_me/app/services/storage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileController extends GetxController {
  // ── State ─────────────────────────────────────────────
  final userModel = Rxn<UserModel>();
  final isLoading = false.obs;
  final isUploadingImage = false.obs;
  final isUploadingCover = false.obs;
  final imageCacheBust = 0.obs;
  final coverCacheBust = 0.obs;

  // ── Firebase + Supabase ───────────────────────────────
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  // ── Getters ───────────────────────────────────────────
  String get userName => userModel.value?.name ?? '';
  String get userTitle => userModel.value?.title ?? '';
  String get userLocation => userModel.value?.location ?? '';
  String get userAbout => userModel.value?.about ?? '';
  String get userImage => userModel.value?.profileImage ?? '';
  String get coverImage => userModel.value?.coverImage ?? '';
  List<EducationModel> get education => userModel.value?.education ?? [];
  List<ExperienceModel> get experience => userModel.value?.experience ?? [];
  List<String> get skills => userModel.value?.skills ?? [];
  List<LanguageModel> get languages => userModel.value?.languages ?? [];
  List<LinkModel> get links => userModel.value?.links ?? [];

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  // ── Load Profile ──────────────────────────────────────
  Future<void> loadProfile() async {
    isLoading.value = true;
    try {
      final uid = _auth.currentUser!.uid;
      final doc = await _firestore.collection('jobSeekers').doc(uid).get();

      if (doc.exists) {
        userModel.value = UserModel.fromMap(doc.data()!);

        if (userModel.value?.name.isEmpty ?? true) {
          final userDoc = await _firestore.collection('users').doc(uid).get();
          final name = userDoc.data()?['name'] ?? '';
          if (name.isNotEmpty) {
            await _updateField('name', name);
            userModel.value = userModel.value?.copyWith(name: name);
          }
        }
      } else {
        final userDoc = await _firestore.collection('users').doc(uid).get();
        final name = userDoc.data()?['name'] ?? '';
        final newUser = UserModel(
          uid: uid,
          email: _auth.currentUser?.email ?? '',
          role: AppUserRole.jobSeeker.value,
          name: name,
        );
        await _firestore.collection('jobSeekers').doc(uid).set(newUser.toMap());
        userModel.value = newUser;
      }
    } catch (e) {
      _showError('Failed to load profile');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Upload Profile Image ──────────────────────────────
  Future<void> pickAndUploadImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;

    isUploadingImage.value = true;
    try {
      final uid = _auth.currentUser!.uid;
      final fileName = 'profile_$uid.jpg';
      await _supabase.storage
          .from('profile-images')
          .upload(
            fileName,
            File(picked.path),
            fileOptions: const FileOptions(upsert: true),
          );
      final imageUrl = _supabase.storage
          .from('profile-images')
          .getPublicUrl(fileName);
      await _updateField('profileImage', imageUrl);
      userModel.value = userModel.value?.copyWith(profileImage: imageUrl);
      imageCacheBust.value = DateTime.now().millisecondsSinceEpoch;
      _showSuccess('Profile photo updated!');
    } catch (e) {
      _showError('Failed to upload photo: $e');
    } finally {
      isUploadingImage.value = false;
    }
  }

  // ── Upload Cover Image ────────────────────────────────
  Future<void> pickAndUploadCover() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;

    isUploadingCover.value = true;
    try {
      final uid = _auth.currentUser!.uid;
      final fileName = 'cover_$uid.jpg';
      await _supabase.storage
          .from('profile-images')
          .upload(
            fileName,
            File(picked.path),
            fileOptions: const FileOptions(upsert: true),
          );
      final coverUrl = _supabase.storage
          .from('profile-images')
          .getPublicUrl(fileName);
      await _updateField('coverImage', coverUrl);
      userModel.value = userModel.value?.copyWith(coverImage: coverUrl);
      coverCacheBust.value = DateTime.now().millisecondsSinceEpoch;
      _showSuccess('Cover photo updated!');
    } catch (e) {
      _showError('Failed to upload cover: $e');
    } finally {
      isUploadingCover.value = false;
    }
  }

  // ── Logout ────────────────────────────────────────────
  Future<void> logout() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      final role = StorageService.to.userRole;
      final roleCollection = role == AppUserRole.company.value
          ? 'companies'
          : 'jobSeekers';
      await _firestore.collection(roleCollection).doc(uid).set({
        'fcmToken': FieldValue.delete(),
      }, SetOptions(merge: true));
      await _firestore.collection('users').doc(uid).set({
        'fcmToken': FieldValue.delete(),
      }, SetOptions(merge: true));
      await FirebaseMessaging.instance.deleteToken();
    }
    await StorageService.to.clearAuthSession();
    await _auth.signOut();
    Get.offAllNamed(Routes.authLogin);
  }

  Future<void> _syncProfileWithApplications(Map<String, dynamic> data) async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) return;

    final snapshot = await _firestore
        .collection('applications')
        .where('seekerId', isEqualTo: uid)
        .get();

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.set(doc.reference, data, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> _updateField(String field, dynamic value) async {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      _showError('Please login first');
      return;
    }

    await _firestore.collection('jobSeekers').doc(uid).set({
      field: value,
    }, SetOptions(merge: true));

    await _firestore.collection('users').doc(uid).set({
      field: value,
    }, SetOptions(merge: true));

    final fieldsToSync = {'name', 'title', 'location', 'profileImage', 'about'};

    if (fieldsToSync.contains(field)) {
      final appField = <String, dynamic>{};

      if (field == 'name') {
        appField['applicantName'] = value;
        appField['seekerName'] = value;
        appField['name'] = value;
      }

      if (field == 'title') {
        appField['applicantTitle'] = value;
        appField['title'] = value;
      }

      if (field == 'location') {
        appField['applicantLocation'] = value;
        appField['location'] = value;
      }

      if (field == 'profileImage') {
        appField['applicantImage'] = value;
        appField['profileImage'] = value;
        appField['imageUrl'] = value;
        appField['avatarUrl'] = value;
      }

      if (field == 'about') {
        appField['applicantAbout'] = value;
        appField['about'] = value;
      }

      if (appField.isNotEmpty) {
        appField['applicantUpdatedAt'] = FieldValue.serverTimestamp();
        await _syncProfileWithApplications(appField);
      }
    }
  }

  void _showError(String msg) => Get.snackbar(
    'Error',
    msg,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: const Color(0xFFEF4444),
    colorText: Colors.white,
    margin: const EdgeInsets.all(16),
    borderRadius: 12,
  );

  void _showSuccess(String msg) => Get.snackbar(
    'Success',
    msg,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: const Color(0xFF22C55E),
    colorText: Colors.white,
    margin: const EdgeInsets.all(16),
    borderRadius: 12,
  );
}
