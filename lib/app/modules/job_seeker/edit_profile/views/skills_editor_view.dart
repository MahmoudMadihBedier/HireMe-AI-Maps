import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hire_me/app/modules/job_seeker/edit_profile/controllers/edit_profile_controller.dart';

class SkillsEditorView extends GetView<EditProfileController> {
  const SkillsEditorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.skillCtrl,
                    decoration: InputDecoration(
                      hintText: 'Add a skill...',
                      prefixIcon: const Icon(Icons.add_rounded,
                          color: Color(0xFF1A3794)),
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
                        borderSide:
                            const BorderSide(color: Color(0xFF1A3794), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    onChanged: controller.filterSuggestions,
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty) {
                        controller.addSkill(v.trim());
                        controller.skillCtrl.clear();
                        controller.filterSuggestions('');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final text = controller.skillCtrl.text.trim();
                      if (text.isNotEmpty) {
                        controller.addSkill(text);
                        controller.skillCtrl.clear();
                        controller.filterSuggestions('');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A3794),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Add',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Obx(
              () => controller.filteredSuggestions.isNotEmpty
                  ? ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 160),
                      child: ListView.builder(
                        itemCount: controller.filteredSuggestions.length,
                        itemBuilder: (context, index) {
                          final s = controller.filteredSuggestions[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.lightbulb_outline,
                                size: 18, color: Color(0xFF1A3794)),
                            title: Text(s, style: const TextStyle(fontSize: 14)),
                            onTap: () {
                              controller.addSkill(s);
                              controller.skillCtrl.clear();
                              controller.filterSuggestions('');
                            },
                          );
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            Obx(
              () => controller.skills.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Text(
                          'No skills added yet.\nType a skill above and tap Add.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF8A8A9A), fontSize: 14),
                        ),
                      ),
                    )
                  : Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: controller.skills.asMap().entries.map(
                            (e) => Chip(
                              label: Text(
                                e.value,
                                style: const TextStyle(
                                  color: Color(0xFF1A3794),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              backgroundColor: const Color(0xFFE8EDF9),
                              deleteIcon: const Icon(Icons.close,
                                  size: 16, color: Color(0xFF1A3794)),
                              onDeleted: () => controller.removeSkill(e.key),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 8),
                            ),
                          ).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
