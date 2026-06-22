import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hire_me/app/modules/job_seeker/profile/controllers/profile_controller.dart';
import 'package:hire_me/app/modules/job_seeker/profile/models/user_model.dart';

class EditProfileController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final isLoading = false.obs;
  final isSaving = false.obs;

  // Basic Info controllers
  final nameCtrl = TextEditingController();
  final titleCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final aboutCtrl = TextEditingController();
  final aboutCharCount = 0.obs;

  // Experience
  final experiences = <ExperienceModel>[].obs;

  // Education
  final educations = <EducationModel>[].obs;

  // Languages
  final languages = <LanguageModel>[].obs;

  // Links
  final links = <LinkModel>[].obs;

  // Skills
  final skills = <String>[].obs;
  final skillCtrl = TextEditingController();
  final skillSuggestions = <String>[].obs;
  final filteredSuggestions = <String>[].obs;

  final List<String> predefinedSkills = [
    'Flutter', 'Dart', 'Firebase', 'Supabase', 'GetX',
    'React', 'Node.js', 'TypeScript', 'JavaScript', 'Python',
    'Java', 'Kotlin', 'Swift', 'Go', 'Rust',
    'SQL', 'MongoDB', 'PostgreSQL', 'Redis', 'Docker',
    'Kubernetes', 'AWS', 'GCP', 'Azure', 'CI/CD',
    'Git', 'REST API', 'GraphQL', 'WebSockets', 'Agile',
  ];

  @override
  void onInit() {
    super.onInit();
    _initSuggestions();
    loadProfile();
  }

  void _initSuggestions() {
    skillSuggestions.value = predefinedSkills;
    filteredSuggestions.value = predefinedSkills;
  }

  void filterSuggestions(String query) {
    if (query.isEmpty) {
      filteredSuggestions.value = skillSuggestions
          .where((s) => !skills.contains(s))
          .toList();
    } else {
      filteredSuggestions.value = skillSuggestions
          .where((s) =>
              s.toLowerCase().contains(query.toLowerCase()) &&
              !skills.contains(s))
          .toList();
    }
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    try {
      final uid = _auth.currentUser!.uid;
      final doc = await _firestore.collection('jobSeekers').doc(uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        nameCtrl.text = data['name'] ?? '';
        titleCtrl.text = data['title'] ?? '';
        locationCtrl.text = data['location'] ?? '';
        aboutCtrl.text = data['about'] ?? '';
        aboutCharCount.value = aboutCtrl.text.length;

        experiences.value = (data['experience'] as List<dynamic>? ?? [])
            .map((e) => ExperienceModel.fromMap(e as Map<String, dynamic>))
            .toList();

        educations.value = (data['education'] as List<dynamic>? ?? [])
            .map((e) => EducationModel.fromMap(e as Map<String, dynamic>))
            .toList();

        skills.value = List<String>.from(data['skills'] ?? []);

        languages.value = (data['languages'] as List<dynamic>? ?? [])
            .map((e) => LanguageModel.fromMap(e as Map<String, dynamic>))
            .toList();

        links.value = (data['links'] as List<dynamic>? ?? [])
            .map((e) => LinkModel.fromMap(e as Map<String, dynamic>))
            .toList();
      }
      filterSuggestions('');
    } catch (_) {
      Get.snackbar('Error', 'Failed to load profile',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveBasicInfo() async {
    isSaving.value = true;
    try {
      final uid = _auth.currentUser!.uid;
      final data = {
        'name': nameCtrl.text.trim(),
        'title': titleCtrl.text.trim(),
        'location': locationCtrl.text.trim(),
        'about': aboutCtrl.text.trim(),
      };
      await _firestore.collection('jobSeekers').doc(uid).set(
        data,
        SetOptions(merge: true),
      );
      await _firestore.collection('users').doc(uid).set(
        data,
        SetOptions(merge: true),
      );

      final profileCtrl = Get.find<ProfileController>();
      await profileCtrl.loadProfile();
      Get.snackbar('Success', 'Profile updated',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to save: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> addExperience(ExperienceModel exp) async {
    final updated = [...experiences, exp];
    await _saveExperiences(updated);
  }

  Future<void> updateExperience(int index, ExperienceModel exp) async {
    final updated = [...experiences];
    updated[index] = exp;
    await _saveExperiences(updated);
  }

  Future<void> deleteExperience(int index) async {
    final updated = [...experiences]..removeAt(index);
    await _saveExperiences(updated);
  }

  Future<void> _saveExperiences(List<ExperienceModel> list) async {
    await _saveFields(
      'experience',
      list.map((e) => e.toMap()).toList(),
    );
    experiences.value = list;
  }

  Future<void> addEducation(EducationModel edu) async {
    final updated = [...educations, edu];
    await _saveEducations(updated);
  }

  Future<void> updateEducation(int index, EducationModel edu) async {
    final updated = [...educations];
    updated[index] = edu;
    await _saveEducations(updated);
  }

  Future<void> deleteEducation(int index) async {
    final updated = [...educations]..removeAt(index);
    await _saveEducations(updated);
  }

  Future<void> _saveEducations(List<EducationModel> list) async {
    await _saveFields(
      'education',
      list.map((e) => e.toMap()).toList(),
    );
    educations.value = list;
  }

  Future<void> addSkill(String skill) async {
    if (skill.trim().isEmpty) return;
    if (skills.contains(skill.trim())) return;
    final updated = [...skills, skill.trim()];
    await _saveSkills(updated);
  }

  Future<void> removeSkill(int index) async {
    final updated = [...skills]..removeAt(index);
    await _saveSkills(updated);
  }

  Future<void> _saveSkills(List<String> list) async {
    await _saveFields('skills', list);
    skills.value = list;
    filterSuggestions('');
  }

  // ── Languages CRUD ─────────────────────────────────────
  Future<void> addLanguage(LanguageModel lang) async {
    final updated = [...languages, lang];
    await _saveLanguages(updated);
  }

  Future<void> updateLanguage(int index, LanguageModel lang) async {
    final updated = [...languages];
    updated[index] = lang;
    await _saveLanguages(updated);
  }

  Future<void> deleteLanguage(int index) async {
    final updated = [...languages]..removeAt(index);
    await _saveLanguages(updated);
  }

  Future<void> _saveLanguages(List<LanguageModel> list) async {
    await _saveFields(
      'languages',
      list.map((e) => e.toMap()).toList(),
    );
    languages.value = list;
  }

  // ── Links CRUD ─────────────────────────────────────────
  Future<void> addLink(LinkModel link) async {
    final updated = [...links, link];
    await _saveLinks(updated);
  }

  Future<void> updateLink(int index, LinkModel link) async {
    final updated = [...links];
    updated[index] = link;
    await _saveLinks(updated);
  }

  Future<void> deleteLink(int index) async {
    final updated = [...links]..removeAt(index);
    await _saveLinks(updated);
  }

  Future<void> _saveLinks(List<LinkModel> list) async {
    await _saveFields(
      'links',
      list.map((e) => e.toMap()).toList(),
    );
    links.value = list;
  }

  Future<void> _saveFields(String field, dynamic value) async {
    isSaving.value = true;
    try {
      final uid = _auth.currentUser!.uid;
      await _firestore.collection('jobSeekers').doc(uid).set({
        field: value,
      }, SetOptions(merge: true));
      await _firestore.collection('users').doc(uid).set({
        field: value,
      }, SetOptions(merge: true));

      final profileCtrl = Get.find<ProfileController>();
      await profileCtrl.loadProfile();
    } catch (e) {
      Get.snackbar('Error', 'Failed to save: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    titleCtrl.dispose();
    locationCtrl.dispose();
    aboutCtrl.dispose();
    skillCtrl.dispose();
    super.onClose();
  }
}
