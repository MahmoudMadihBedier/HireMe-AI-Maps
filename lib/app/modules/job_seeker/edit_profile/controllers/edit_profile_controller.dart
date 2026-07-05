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

  final nameCtrl = TextEditingController();
  final titleCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final aboutCtrl = TextEditingController();
  final aboutCharCount = 0.obs;

  final experiences = <ExperienceModel>[].obs;
  final educations = <EducationModel>[].obs;
  final languages = <LanguageModel>[].obs;
  final links = <LinkModel>[].obs;
  final skills = <String>[].obs;

  final skillCtrl = TextEditingController();
  final skillSuggestions = <String>[].obs;
  final filteredSuggestions = <String>[].obs;

  final List<String> predefinedSkills = [
    'Flutter',
    'Dart',
    'Firebase',
    'Supabase',
    'GetX',
    'React',
    'Node.js',
    'TypeScript',
    'JavaScript',
    'Python',
    'Java',
    'Kotlin',
    'Swift',
    'Go',
    'Rust',
    'SQL',
    'MongoDB',
    'PostgreSQL',
    'Redis',
    'Docker',
    'Kubernetes',
    'AWS',
    'GCP',
    'Azure',
    'CI/CD',
    'Git',
    'REST API',
    'GraphQL',
    'WebSockets',
    'Agile',
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
    final normalizedQuery = query.trim().toLowerCase();
    filteredSuggestions.value = skillSuggestions
        .where(
          (skill) =>
              !skills.contains(skill) &&
              (normalizedQuery.isEmpty ||
                  skill.toLowerCase().contains(normalizedQuery)),
        )
        .toList();
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        _showError('Please login first');
        return;
      }

      final doc = await _firestore.collection('jobSeekers').doc(uid).get();
      final data = doc.data();
      if (data == null) return;

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

      filterSuggestions('');
    } catch (e) {
      _showError('Failed to load profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveBasicInfo() async {
    final data = {
      'name': nameCtrl.text.trim(),
      'title': titleCtrl.text.trim(),
      'location': locationCtrl.text.trim(),
      'about': aboutCtrl.text.trim(),
    };

    await _saveFields(data, successMessage: 'Profile updated');
  }

  Future<void> addExperience(ExperienceModel exp) async {
    await _saveExperiences([...experiences, exp]);
  }

  Future<void> updateExperience(int index, ExperienceModel exp) async {
    if (!_isValidIndex(index, experiences.length)) return;
    final updated = [...experiences];
    updated[index] = exp;
    await _saveExperiences(updated);
  }

  Future<void> deleteExperience(int index) async {
    if (!_isValidIndex(index, experiences.length)) return;
    final updated = [...experiences]..removeAt(index);
    await _saveExperiences(updated);
  }

  Future<void> _saveExperiences(List<ExperienceModel> list) async {
    await _saveFields({'experience': list.map((e) => e.toMap()).toList()});
    experiences.value = list;
  }

  Future<void> addEducation(EducationModel edu) async {
    await _saveEducations([...educations, edu]);
  }

  Future<void> updateEducation(int index, EducationModel edu) async {
    if (!_isValidIndex(index, educations.length)) return;
    final updated = [...educations];
    updated[index] = edu;
    await _saveEducations(updated);
  }

  Future<void> deleteEducation(int index) async {
    if (!_isValidIndex(index, educations.length)) return;
    final updated = [...educations]..removeAt(index);
    await _saveEducations(updated);
  }

  Future<void> _saveEducations(List<EducationModel> list) async {
    await _saveFields({'education': list.map((e) => e.toMap()).toList()});
    educations.value = list;
  }

  Future<void> addSkill(String skill) async {
    final normalizedSkill = skill.trim();
    if (normalizedSkill.isEmpty || skills.contains(normalizedSkill)) return;
    await _saveSkills([...skills, normalizedSkill]);
  }

  Future<void> removeSkill(int index) async {
    if (!_isValidIndex(index, skills.length)) return;
    final updated = [...skills]..removeAt(index);
    await _saveSkills(updated);
  }

  Future<void> _saveSkills(List<String> list) async {
    await _saveFields({'skills': list});
    skills.value = list;
    filterSuggestions('');
  }

  Future<void> addLanguage(LanguageModel lang) async {
    await _saveLanguages([...languages, lang]);
  }

  Future<void> updateLanguage(int index, LanguageModel lang) async {
    if (!_isValidIndex(index, languages.length)) return;
    final updated = [...languages];
    updated[index] = lang;
    await _saveLanguages(updated);
  }

  Future<void> deleteLanguage(int index) async {
    if (!_isValidIndex(index, languages.length)) return;
    final updated = [...languages]..removeAt(index);
    await _saveLanguages(updated);
  }

  Future<void> _saveLanguages(List<LanguageModel> list) async {
    await _saveFields({'languages': list.map((e) => e.toMap()).toList()});
    languages.value = list;
  }

  Future<void> addLink(LinkModel link) async {
    await _saveLinks([...links, link]);
  }

  Future<void> updateLink(int index, LinkModel link) async {
    if (!_isValidIndex(index, links.length)) return;
    final updated = [...links];
    updated[index] = link;
    await _saveLinks(updated);
  }

  Future<void> deleteLink(int index) async {
    if (!_isValidIndex(index, links.length)) return;
    final updated = [...links]..removeAt(index);
    await _saveLinks(updated);
  }

  Future<void> _saveLinks(List<LinkModel> list) async {
    await _saveFields({'links': list.map((e) => e.toMap()).toList()});
    links.value = list;
  }

  Future<void> _saveFields(
    Map<String, dynamic> data, {
    String? successMessage,
  }) async {
    isSaving.value = true;
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        _showError('Please login first');
        return;
      }

      await _firestore
          .collection('jobSeekers')
          .doc(uid)
          .set(data, SetOptions(merge: true));
      await _firestore
          .collection('users')
          .doc(uid)
          .set(data, SetOptions(merge: true));

      if (Get.isRegistered<ProfileController>()) {
        await Get.find<ProfileController>().loadProfile();
      }

      if (successMessage != null) {
        _showSuccess(successMessage);
      }
    } catch (e) {
      _showError('Failed to save: $e');
    } finally {
      isSaving.value = false;
    }
  }

  bool _isValidIndex(int index, int length) {
    final isValid = index >= 0 && index < length;
    if (!isValid) {
      _showError('Could not update this item. Please reopen the editor.');
    }
    return isValid;
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
