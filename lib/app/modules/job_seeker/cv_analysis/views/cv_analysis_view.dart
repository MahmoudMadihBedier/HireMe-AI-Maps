import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/utils/app_color.dart';
import '../controllers/cv_analysis_controller.dart';
import '../models/cv_analysis_result.dart';

class CvAnalysisView extends GetView<CvAnalysisController> {
  const CvAnalysisView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        backgroundColor: AppColor.kblue,
        foregroundColor: AppColor.kwhite,
        title: const Text('CV Analysis'),
        elevation: 0,
      ),
      body: Obx(() {
        debugPrint('isLoading: ${controller.isLoading.value}, isUploading: ${controller.isUploading.value}, error: ${controller.errorMessage.value}, result: ${controller.result.value}');
        if (controller.isLoading.value || controller.isUploading.value) {
          return _buildUploadingIndicator(
            controller.isUploading.value ? 'Uploading CV...' : 'Analyzing...',
          );
        }
        if (controller.errorMessage.value.isNotEmpty) {
          return _buildError();
        }
        if (controller.result.value != null) {
          return _buildResult(controller.result.value!);
        }
        return _buildUploadPrompt();
      }),
    );
  }

  Widget _buildUploadPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColor.kblue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.upload_file_rounded,
                size: 48,
                color: AppColor.kblue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Upload Your CV',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Upload your CV in PDF format to get a detailed analysis and match score for this job.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColor.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 220,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: controller.pickAndUploadCV,
                icon: const Icon(Icons.cloud_upload_outlined, size: 22),
                label: const Text(
                  'Upload CV to Analyze',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.kblue,
                  foregroundColor: AppColor.kwhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadingIndicator(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColor.kblue),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColor.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: controller.pickAndUploadCV,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.kblue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(CvAnalysisResult result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _matchScoreCard(result.matchPercentage),
          const SizedBox(height: 24),
          _sectionList(
            title: 'Strengths ✅',
            items: result.strengths,
            color: AppColor.ksuccess,
          ),
          const SizedBox(height: 20),
          _sectionList(
            title: 'Weaknesses ❌',
            items: result.weaknesses,
            color: AppColor.kdanger,
          ),
          const SizedBox(height: 20),
          _sectionList(
            title: 'Suggestions 💡',
            items: result.suggestions,
            color: AppColor.kblue,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _matchScoreCard(int percentage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColor.kshadow,
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Match Score',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColor.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percentage.toDouble()),
            duration: const Duration(milliseconds: 1000),
            builder: (context, value, _) {
              return SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: value / 100,
                        strokeWidth: 10,
                        backgroundColor: AppColor.greyVeryLight,
                        valueColor: AlwaysStoppedAnimation(
                          _scoreColor(percentage),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${value.round()}%',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: _scoreColor(percentage),
                          ),
                        ),
                        Text(
                          _scoreLabel(percentage),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColor.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _scoreColor(int percentage) {
    if (percentage >= 70) return AppColor.ksuccess;
    if (percentage >= 40) return Colors.orange;
    return AppColor.kdanger;
  }

  String _scoreLabel(int percentage) {
    if (percentage >= 70) return 'Great Match';
    if (percentage >= 40) return 'Good Match';
    return 'Low Match';
  }

  Widget _sectionList({
    required String title,
    required List<String> items,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColor.kshadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColor.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No items',
                style: TextStyle(
                  color: AppColor.greyLight,
                  fontSize: 13,
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) => _chip(item, color)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
