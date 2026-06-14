import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cv_analysis_result.dart';

class CvAnalysisController extends GetxController {
  final String jobDescription;

  final isLoading = false.obs;
  final isUploading = false.obs;
  final result = Rxn<CvAnalysisResult>();
  final errorMessage = ''.obs;
  final cvFileName = ''.obs;
  final cvFilePath = ''.obs;

  final _auth = FirebaseAuth.instance;
  final _supabase = Supabase.instance.client;

  CvAnalysisController({
    required this.jobDescription,
  });

  Future<void> pickAndUploadCV() async {
    try {
      final pickResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (pickResult == null || pickResult.files.isEmpty) return;

      cvFileName.value = pickResult.files.single.name;
      cvFilePath.value = pickResult.files.single.path ?? '';

      final file = File(cvFilePath.value);
      if (!file.existsSync()) {
        errorMessage.value = 'CV file not found. Please try again.';
        return;
      }

      final uid = _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        errorMessage.value = 'Please login first.';
        return;
      }

      isUploading.value = true;
      errorMessage.value = '';

      final fileName =
          '${uid}_${DateTime.now().millisecondsSinceEpoch}_${cvFileName.value}';

      await _supabase.storage.from('cv').upload(fileName, file);

      final cvUrl = _supabase.storage.from('cv').getPublicUrl(fileName);

      await analyzeCV(cvUrl);
    } catch (e) {
      debugPrint('pickAndUploadCV error: $e');
      errorMessage.value = 'Failed to upload CV. Please try again.';
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> analyzeCV(String cvUrl) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('analyzeCv');
      final response = await callable.call({
        'cvUrl': cvUrl,
        'jobDescription': jobDescription,
      });

      result.value = CvAnalysisResult.fromMap(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('analyzeCV error: $e');
      final actualMessage = e is FirebaseFunctionsException
          ? (e.message ?? 'Failed to analyze CV. Please try again.')
          : 'Failed to analyze CV. Please try again.';
      errorMessage.value = actualMessage;
      debugPrint('errorMessage set to: ${errorMessage.value}');
    } finally {
      isLoading.value = false;
    }
  }
}
