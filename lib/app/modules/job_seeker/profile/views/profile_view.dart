import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hire_me/app/modules/job_seeker/profile/models/user_model.dart';
import 'package:hire_me/app/routes/app_pages.dart';
import 'package:hire_me/core/utils/app_color.dart';

import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(color: AppColor.kblue),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileCard(),
                const SizedBox(height: 6),
                _buildAboutCard(),
                const SizedBox(height: 6),
                _buildExperienceCard(),
                const SizedBox(height: 6),
                _buildEducationCard(),
                const SizedBox(height: 6),
                _buildSkillsCard(),
                const SizedBox(height: 6),
                _buildLanguagesCard(),
                const SizedBox(height: 6),
                _buildLinksCard(),
                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFFE0E0E0)),
                TextButton(
                  onPressed: controller.logout,
                  child: const Text(
                    'Logout',
                    style: TextStyle(color: Color(0xFFEF4444), fontSize: 14),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Obx(
                    () => Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB0BEC5),
                        image: controller.coverImage.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(
                                  '${controller.coverImage}?t=${controller.coverCacheBust.value}',
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: controller.isUploadingCover.value
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: controller.pickAndUploadCover,
                                  child: _cameraIconButton(),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),

                Positioned(
                  top: 70,
                  left: 16,
                  child: SizedBox(
                    width: 110,
                    height: 110,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: controller.pickAndUploadImage,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: controller.isUploadingImage.value
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF1A3794),
                                    ),
                                  )
                                : CircleAvatar(
                                    radius: 48,
                                    backgroundColor: const Color(0xFFE8EDF9),
                                    backgroundImage:
                                        controller.userImage.isNotEmpty
                                        ? NetworkImage(
                                            '${controller.userImage}?t=${controller.imageCacheBust.value}',
                                          )
                                        : null,
                                    child: controller.userImage.isEmpty
                                        ? const Icon(
                                            Icons.person_rounded,
                                            size: 38,
                                            color: Color(0xFF1A3794),
                                          )
                                        : null,
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 0,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: controller.pickAndUploadImage,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A3794),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Obx(
                      () => Text(
                        controller.userName.isEmpty
                            ? 'Your Name'
                            : controller.userName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => Get.toNamed(Routes.editProfile),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Color(0xFF8A8A9A),
                      ),
                    ),
                  ],
                ),

                Obx(
                  () => controller.userTitle.isEmpty
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            controller.userTitle,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8A8A9A),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return _sectionCard(
      title: 'About',
      icon: Icons.person_outline_rounded,
      child: Obx(
        () => controller.userAbout.isEmpty
            ? _emptyState('No about information added yet. Tap Edit to add.')
            : Text(
                controller.userAbout,
                style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A2E)),
              ),
      ),
    );
  }

  Widget _buildExperienceCard() {
    return _sectionCard(
      title: 'Experience',
      icon: Icons.calendar_today_outlined,
      child: Obx(
        () => controller.experience.isEmpty
            ? _emptyState('No experience added yet. Tap Edit Profile to add.')
            : Column(
                children: [
                  ...controller.experience.asMap().entries.map(
                    (e) => _experienceItem(e.value),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEducationCard() {
    return _sectionCard(
      title: 'Education',
      icon: Icons.school_outlined,
      child: Obx(
        () => controller.education.isEmpty
            ? _emptyState('No education added yet. Tap Edit Profile to add.')
            : Column(
                children: [
                  ...controller.education.asMap().entries.map(
                    (e) => _educationItem(e.value),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSkillsCard() {
    return _sectionCard(
      title: 'Skills',
      icon: Icons.description_outlined,
      child: Obx(
        () => controller.skills.isEmpty
            ? _emptyState('No skills added yet. Tap Edit Profile to add.')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: controller.skills
                        .map((skill) => _skillChip(skill))
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
      ),
    );
  }

  Widget _buildLanguagesCard() {
    return _sectionCard(
      title: 'Languages',
      icon: Icons.language_rounded,
      child: Obx(
        () => controller.languages.isEmpty
            ? _emptyState('No languages added yet. Tap Edit Profile to add.')
            : Column(
                children: [...controller.languages.map((e) => _languageItem(e))],
              ),
      ),
    );
  }

  Widget _buildLinksCard() {
    return _sectionCard(
      title: 'Links',
      icon: Icons.link_rounded,
      child: Obx(
        () => controller.links.isEmpty
            ? _emptyState('No links added yet. Tap Edit Profile to add.')
            : Column(children: [...controller.links.map((e) => _linkItem(e))]),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColor.kblue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _educationItem(EducationModel e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBox(Icons.school_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.school,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  '${e.degree} · ${e.field}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8A8A9A),
                  ),
                ),
                Text(
                  '${e.startYear} - ${e.endYear}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A8A9A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _experienceItem(ExperienceModel e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBox(Icons.work_outline_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.position,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  e.company,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8A8A9A),
                  ),
                ),
                Text(
                  '${e.startDate} - ${e.endDate}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A8A9A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageItem(LanguageModel e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _iconBox(Icons.language_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  e.level,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8A8A9A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkItem(LinkModel e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _iconBox(_linkIcon(e.type)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.type,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  e.url,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1A3794),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _linkIcon(String type) {
    switch (type) {
      case 'GitHub':
        return Icons.code_rounded;
      case 'LinkedIn':
        return Icons.work_outline_rounded;
      case 'Portfolio':
        return Icons.web_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  Widget _skillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDF9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        skill,
        style: TextStyle(
          fontSize: 13,
          color: AppColor.kblue,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDF9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: AppColor.kblue, size: 22),
    );
  }

  Widget _cameraIconButton() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.camera_alt_outlined, size: 18, color: AppColor.kblue),
    );
  }

  Widget _emptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message,
        style: const TextStyle(fontSize: 13, color: Color(0xFF8A8A9A)),
      ),
    );
  }
}
