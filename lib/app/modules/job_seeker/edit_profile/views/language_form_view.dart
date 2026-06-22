import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hire_me/app/modules/job_seeker/edit_profile/controllers/edit_profile_controller.dart';
import 'package:hire_me/app/modules/job_seeker/profile/models/user_model.dart';
import 'package:hire_me/core/utils/app_color.dart';

class LanguageFormView extends StatefulWidget {
  const LanguageFormView({super.key});

  @override
  State<LanguageFormView> createState() => _LanguageFormViewState();
}

class _LanguageFormViewState extends State<LanguageFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String _selectedLevel = 'Beginner';
  int? _editIndex;

  final _levels = ['Beginner', 'Intermediate', 'Fluent', 'Native'];

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      _editIndex = args['index'] as int?;
      final lang = args['language'] as LanguageModel?;
      if (lang != null) {
        _nameCtrl.text = lang.name;
        _selectedLevel = lang.level;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final lang = LanguageModel(
      name: _nameCtrl.text.trim(),
      level: _selectedLevel,
    );

    final ctrl = Get.find<EditProfileController>();
    if (_editIndex != null) {
      ctrl.updateLanguage(_editIndex!, lang);
    } else {
      ctrl.addLanguage(lang);
    }
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(_editIndex != null ? 'Edit Language' : 'Add Language'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Language',
                hintText: 'e.g. English, Arabic',
                prefixIcon: const Icon(Icons.language_rounded,
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
              ),
              validator: (v) =>
                  v?.trim().isEmpty == true ? 'Language name is required' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _selectedLevel,
              decoration: InputDecoration(
                labelText: 'Proficiency Level',
                prefixIcon: const Icon(Icons.signal_cellular_alt_rounded,
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
              ),
              items: _levels.map((l) {
                return DropdownMenuItem(value: l, child: Text(l));
              }).toList(),
              onChanged: (v) {
                setState(() => _selectedLevel = v ?? 'Beginner');
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3794),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
