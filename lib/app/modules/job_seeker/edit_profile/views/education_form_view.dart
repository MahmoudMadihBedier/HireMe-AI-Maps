import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hire_me/app/modules/job_seeker/edit_profile/controllers/edit_profile_controller.dart';
import 'package:hire_me/app/modules/job_seeker/profile/models/user_model.dart';
import 'package:hire_me/core/utils/app_color.dart';

class EducationFormView extends StatefulWidget {
  const EducationFormView({super.key});

  @override
  State<EducationFormView> createState() => _EducationFormViewState();
}

class _EducationFormViewState extends State<EducationFormView> {
  final _formKey = GlobalKey<FormState>();
  final _institutionCtrl = TextEditingController();
  final _degreeCtrl = TextEditingController();
  final _fieldCtrl = TextEditingController();
  final _startYearCtrl = TextEditingController();
  final _endYearCtrl = TextEditingController();
  bool _isCurrent = false;

  int? _editIndex;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      _editIndex = args['index'] as int?;
      final edu = args['education'] as EducationModel?;
      if (edu != null) {
        _institutionCtrl.text = edu.school;
        _degreeCtrl.text = edu.degree;
        _fieldCtrl.text = edu.field;
        _startYearCtrl.text = edu.startYear;
        _endYearCtrl.text = edu.endYear;
        _isCurrent = edu.isCurrent;
      }
    }
  }

  @override
  void dispose() {
    _institutionCtrl.dispose();
    _degreeCtrl.dispose();
    _fieldCtrl.dispose();
    _startYearCtrl.dispose();
    _endYearCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final edu = EducationModel(
      school: _institutionCtrl.text.trim(),
      degree: _degreeCtrl.text.trim(),
      field: _fieldCtrl.text.trim(),
      startYear: _startYearCtrl.text.trim(),
      endYear: _isCurrent ? '' : _endYearCtrl.text.trim(),
      isCurrent: _isCurrent,
    );

    final ctrl = Get.find<EditProfileController>();
    if (_editIndex != null) {
      ctrl.updateEducation(_editIndex!, edu);
    } else {
      ctrl.addEducation(edu);
    }
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(_editIndex != null ? 'Edit Education' : 'Add Education'),
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
            _buildField(
              controller: _institutionCtrl,
              label: 'Institution',
              hint: 'e.g. Cairo University',
              icon: Icons.school_outlined,
              validator: (v) =>
                  v?.trim().isEmpty == true ? 'Institution is required' : null,
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _degreeCtrl,
              label: 'Degree',
              hint: 'e.g. Bachelor\'s',
              icon: Icons.workspace_premium_outlined,
              validator: (v) =>
                  v?.trim().isEmpty == true ? 'Degree is required' : null,
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _fieldCtrl,
              label: 'Field of Study',
              hint: 'e.g. Computer Science',
              icon: Icons.science_outlined,
              validator: (v) =>
                  v?.trim().isEmpty == true ? 'Field of study is required' : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _startYearCtrl,
                    label: 'Start Year',
                    hint: 'e.g. 2020',
                    icon: Icons.calendar_today_rounded,
                    validator: (v) =>
                        v?.trim().isEmpty == true ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildField(
                    controller: _endYearCtrl,
                    label: 'End Year',
                    hint: _isCurrent ? 'Present' : 'e.g. 2024',
                    icon: Icons.calendar_today_rounded,
                    enabled: !_isCurrent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _isCurrent,
              onChanged: (v) {
                setState(() {
                  _isCurrent = v ?? false;
                  if (_isCurrent) _endYearCtrl.clear();
                });
              },
              title: const Text(
                'I currently study here',
                style: TextStyle(fontSize: 14),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFF1A3794),
              contentPadding: EdgeInsets.zero,
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1A3794)),
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF5F5F5),
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
}
