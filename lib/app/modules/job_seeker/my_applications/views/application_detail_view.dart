import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hire_me/app/routes/app_pages.dart';
import 'package:hire_me/core/utils/app_color.dart';

import '../controllers/application_detail_controller.dart';

class ApplicationDetailView extends GetView<ApplicationDetailController> {
  const ApplicationDetailView({super.key});

  static const _bg = Color(0xFFF5F7FF);
  static const _textDark = Color(0xFF1A1A2E);
  static const _textGrey = Color(0xFF8A8A9A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: AppColor.kblue,
        elevation: 0,
        title: const Text(
          'Application Details',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: AppColor.kblue),
          );
        }

        final data = controller.appData.value;
        if (data == null) {
          return const Center(
            child: Text('Application not found', style: TextStyle(color: _textGrey)),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            children: [
              _buildHeader(data),
              const SizedBox(height: 16),
              _buildStatusCard(data),
              const SizedBox(height: 16),
              _buildTimelineCard(data),
              const SizedBox(height: 16),
              _buildCvCard(data),
              if (controller.canWithdraw()) ...[
                const SizedBox(height: 16),
                _buildWithdrawButton(),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    final iconUrl = (data['subFieldIconUrl'] as String? ?? '').isNotEmpty
        ? data['subFieldIconUrl'] as String
        : data['mainFieldIconUrl'] as String? ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColor.kblue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: iconUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: iconUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Icon(
                        Icons.work_outline_rounded,
                        color: AppColor.kblue,
                        size: 28,
                      ),
                    )
                  : Icon(Icons.work_outline_rounded, color: AppColor.kblue, size: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['jobTitle'] as String? ?? 'Job Title',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data['companyName'] as String? ?? 'Company',
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(Map<String, dynamic> data) {
    final status = data['status'] as String? ?? 'pending';
    final color = controller.statusColor(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              status == 'accepted'
                  ? Icons.check_circle_outline
                  : status == 'rejected'
                      ? Icons.cancel_outlined
                      : status == 'withdrawn'
                          ? Icons.remove_circle_outline
                          : Icons.hourglass_bottom_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status',
                  style: TextStyle(fontSize: 11, color: _textGrey, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  controller.formatStatus(status),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              controller.formatDate(data['createdAt'] as Timestamp?),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(Map<String, dynamic> data) {
    final status = (data['status'] as String? ?? '').toLowerCase();
    final createdAt = data['createdAt'] as Timestamp?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Timeline',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textDark),
          ),
          const SizedBox(height: 16),
          _timelineItem(
            icon: Icons.check_circle_rounded,
            label: 'Applied',
            date: controller.formatDate(createdAt),
            isComplete: true,
          ),
          _timelineConnector(isComplete: status != 'pending'),
          _timelineItem(
            icon: status == 'pending' ? Icons.hourglass_empty_rounded : Icons.check_circle_rounded,
            label: 'Under Review',
            date: status != 'pending' ? 'In progress' : '',
            isComplete: status != 'pending',
          ),
          _timelineConnector(isComplete: status == 'accepted' || status == 'rejected'),
          _timelineItem(
            icon: status == 'accepted'
                ? Icons.check_circle_rounded
                : status == 'rejected'
                    ? Icons.cancel_rounded
                    : Icons.radio_button_unchecked_rounded,
            label: status == 'accepted'
                ? 'Accepted'
                : status == 'rejected'
                    ? 'Rejected'
                    : 'Decision',
            date: '',
            isComplete: status == 'accepted' || status == 'rejected',
            color: status == 'accepted'
                ? const Color(0xFF22C55E)
                : status == 'rejected'
                    ? const Color(0xFFEF4444)
                    : null,
          ),
        ],
      ),
    );
  }

  Widget _timelineItem({
    required IconData icon,
    required String label,
    required String date,
    required bool isComplete,
    Color? color,
  }) {
    final c = color ?? (isComplete ? const Color(0xFF22C55E) : const Color(0xFFD1D5DB));
    return Row(
      children: [
        Icon(icon, size: 22, color: c),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isComplete ? _textDark : _textGrey,
            ),
          ),
        ),
        if (date.isNotEmpty)
          Text(
            date,
            style: TextStyle(fontSize: 11, color: _textGrey),
          ),
      ],
    );
  }

  Widget _timelineConnector({required bool isComplete}) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Container(
        height: 24,
        width: 2,
        color: isComplete ? const Color(0xFF22C55E) : const Color(0xFFD1D5DB),
      ),
    );
  }

  Widget _buildCvCard(Map<String, dynamic> data) {
    final cvUrl = data['cvUrl'] as String? ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_outlined, size: 18, color: _textDark),
              SizedBox(width: 8),
              Text(
                'CV / Resume',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textDark),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () {
                if (cvUrl.isNotEmpty) {
                  Get.toNamed(Routes.pdfViewer, arguments: cvUrl);
                }
              },
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
              label: const Text('View CV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.kblue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Obx(
        () => ElevatedButton.icon(
          onPressed: controller.isWithdrawing.value ? null : controller.withdrawApplication,
          icon: controller.isWithdrawing.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.remove_circle_outline, size: 20),
          label: Text(
            controller.isWithdrawing.value ? 'Withdrawing...' : 'Withdraw Application',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
