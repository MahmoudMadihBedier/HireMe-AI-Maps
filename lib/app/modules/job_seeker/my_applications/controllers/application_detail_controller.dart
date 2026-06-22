import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ApplicationDetailController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final isLoading = true.obs;
  final isWithdrawing = false.obs;

  final appData = Rxn<Map<String, dynamic>>();
  final String applicationId;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _appSub;

  ApplicationDetailController({required this.applicationId});

  @override
  void onInit() {
    super.onInit();
    _listenToApplication();
  }

  void _listenToApplication() {
    isLoading.value = true;
    _appSub = _firestore
        .collection('applications')
        .doc(applicationId)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()!;
          data['id'] = snapshot.id;
          appData.value = data;
        }
        isLoading.value = false;
      },
      onError: (_) {
        isLoading.value = false;
        Get.snackbar('Error', 'Failed to load application',
            snackPosition: SnackPosition.BOTTOM);
      },
    );
  }

  String get status {
    final s = appData.value?['status'] as String? ?? 'pending';
    return formatStatus(s);
  }

  String get rawStatus => (appData.value?['status'] as String? ?? 'pending').toLowerCase();

  bool canWithdraw() {
    final s = rawStatus;
    return s == 'pending' || s == 'under_review';
  }

  Future<void> withdrawApplication() async {
    if (!canWithdraw()) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Withdraw Application'),
        content: const Text(
          'Are you sure you want to withdraw this application? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    isWithdrawing.value = true;
    try {
      await _firestore.collection('applications').doc(applicationId).set({
        'status': 'Withdrawn',
        'withdrawnAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Get.snackbar('Withdrawn', 'Application withdrawn successfully',
          snackPosition: SnackPosition.BOTTOM);

      await Future.delayed(const Duration(milliseconds: 500));
      Get.back();
    } catch (e) {
      Get.snackbar('Error', 'Failed to withdraw application',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isWithdrawing.value = false;
    }
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return const Color(0xFF22C55E);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'under_review':
        return const Color(0xFF3B82F6);
      case 'withdrawn':
        return const Color(0xFF8A8A9A);
      default:
        return const Color(0xFF8A8A9A);
    }
  }

  String formatStatus(String value) {
    if (value.isEmpty) return 'Pending';
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  String formatDate(Timestamp? ts) {
    if (ts == null) return '';
    final date = ts.toDate();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  void onClose() {
    _appSub?.cancel();
    super.onClose();
  }
}
