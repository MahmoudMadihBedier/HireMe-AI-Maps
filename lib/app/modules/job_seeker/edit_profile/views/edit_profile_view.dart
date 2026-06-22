import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hire_me/app/modules/job_seeker/edit_profile/controllers/edit_profile_controller.dart';
import 'package:hire_me/app/modules/job_seeker/edit_profile/views/skills_editor_view.dart';
import 'package:hire_me/app/routes/app_pages.dart';
import 'package:hire_me/core/utils/app_color.dart';

class EditProfileView extends GetView<EditProfileController> {
  EditProfileView({super.key});

  final _initialTab =
      (Get.arguments is Map ? (Get.arguments as Map)['tab'] : null) as int?;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.background,
        title: const Text('Edit Profile'),
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return DefaultTabController(
          initialIndex: _initialTab ?? 0,
          length: 6,
          child: Column(
            children: [
              const TabBar(
                isScrollable: true,
                labelColor: Color(0xFF1A3794),
                unselectedLabelColor: Color(0xFF8A8A9A),
                indicatorColor: Color(0xFF1A3794),
                indicatorSize: TabBarIndicatorSize.label,
                labelPadding: EdgeInsets.symmetric(horizontal: 12),
                tabs: [
                  Tab(text: 'Basic Info'),
                  Tab(text: 'Experience'),
                  Tab(text: 'Education'),
                  Tab(text: 'Skills'),
                  Tab(text: 'Languages'),
                  Tab(text: 'Links'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildBasicInfoTab(),
                    _buildExperienceTab(),
                    _buildEducationTab(),
                    SkillsEditorView(),
                    _buildLanguagesTab(),
                    _buildLinksTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildField(controller.nameCtrl, 'Full Name', Icons.person_outline),
          const SizedBox(height: 14),
          _buildField(
            controller.titleCtrl,
            'Professional Title',
            Icons.work_outline,
          ),
          const SizedBox(height: 14),
          _buildField(
            controller.locationCtrl,
            'Location',
            Icons.location_on_outlined,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: controller.aboutCtrl,
            minLines: 3,
            maxLines: null,
            maxLength: 500,
            onChanged: (v) => controller.aboutCharCount.value = v.length,
            decoration: InputDecoration(
              labelText: 'About',
              hintText: 'Tell us about yourself...',
              prefixIcon: const Icon(
                Icons.description_outlined,
                color: Color(0xFF1A3794),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF1A3794),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: Obx(
              () => ElevatedButton(
                onPressed: controller.isSaving.value
                    ? null
                    : controller.saveBasicInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3794),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: controller.isSaving.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1A3794)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A3794), width: 2),
        ),
      ),
    );
  }

  Widget _buildExperienceTab() {
    return Obx(
      () => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...controller.experiences.asMap().entries.map(
            (e) => _buildListItem(
              title: e.value.position,
              subtitle:
                  '${e.value.company}  •  ${e.value.startDate} - ${e.value.isCurrent ? 'Present' : e.value.endDate}',
              icon: Icons.work_outline_rounded,
              onEdit: () => Get.toNamed(
                Routes.experienceForm,
                arguments: {'index': e.key, 'experience': e.value},
              ),
              onDelete: () => controller.deleteExperience(e.key),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Get.toNamed(Routes.experienceForm),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: Color(0xFF1A3794)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.add, color: Color(0xFF1A3794)),
            label: const Text(
              'Add Experience',
              style: TextStyle(color: Color(0xFF1A3794)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationTab() {
    return Obx(
      () => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...controller.educations.asMap().entries.map(
            (e) => _buildListItem(
              title: e.value.school,
              subtitle:
                  '${e.value.degree}  •  ${e.value.startYear} - ${e.value.isCurrent ? 'Present' : e.value.endYear}',
              icon: Icons.school_outlined,
              onEdit: () => Get.toNamed(
                Routes.educationForm,
                arguments: {'index': e.key, 'education': e.value},
              ),
              onDelete: () => controller.deleteEducation(e.key),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Get.toNamed(Routes.educationForm),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: Color(0xFF1A3794)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.add, color: Color(0xFF1A3794)),
            label: const Text(
              'Add Education',
              style: TextStyle(color: Color(0xFF1A3794)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagesTab() {
    return Obx(
      () => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...controller.languages.asMap().entries.map(
            (e) => _buildListItem(
              title: e.value.name,
              subtitle: e.value.level,
              icon: Icons.language_rounded,
              onEdit: () => Get.toNamed(
                Routes.languageForm,
                arguments: {'index': e.key, 'language': e.value},
              ),
              onDelete: () => controller.deleteLanguage(e.key),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Get.toNamed(Routes.languageForm),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: Color(0xFF1A3794)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.add, color: Color(0xFF1A3794)),
            label: const Text(
              'Add Language',
              style: TextStyle(color: Color(0xFF1A3794)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinksTab() {
    return Obx(
      () => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...controller.links.asMap().entries.map(
            (e) => _buildListItem(
              title: e.value.type,
              subtitle: e.value.url,
              icon: Icons.link_rounded,
              onEdit: () => Get.toNamed(
                Routes.linkForm,
                arguments: {'index': e.key, 'link': e.value},
              ),
              onDelete: () => controller.deleteLink(e.key),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Get.toNamed(Routes.linkForm),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: Color(0xFF1A3794)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.add, color: Color(0xFF1A3794)),
            label: const Text(
              'Add Link',
              style: TextStyle(color: Color(0xFF1A3794)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EDF9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF1A3794), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF8A8A9A),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              size: 18,
              color: Color(0xFF8A8A9A),
            ),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              size: 18,
              color: Color(0xFFEF4444),
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
