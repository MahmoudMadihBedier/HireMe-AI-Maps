import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hire_me/app/modules/job_seeker/edit_profile/controllers/edit_profile_controller.dart';
import 'package:hire_me/app/modules/job_seeker/profile/models/user_model.dart';
import 'package:hire_me/core/utils/app_color.dart';

class ExperienceFormView extends StatefulWidget {
  const ExperienceFormView({super.key});

  @override
  State<ExperienceFormView> createState() => _ExperienceFormViewState();
}

class _ExperienceFormViewState extends State<ExperienceFormView> {
  final _formKey = GlobalKey<FormState>();
  final _companyCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isCurrent = false;

  int? _editIndex;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      _editIndex = args['index'] as int?;
      final exp = args['experience'] as ExperienceModel?;
      if (exp != null) {
        _companyCtrl.text = exp.company;
        _positionCtrl.text = exp.position;
        _startDateCtrl.text = exp.startDate;
        _endDateCtrl.text = exp.endDate;
        _descCtrl.text = exp.description;
        _isCurrent = exp.isCurrent;
      }
    }
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    _positionCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1A3794),
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      ctrl.text =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final exp = ExperienceModel(
      company: _companyCtrl.text.trim(),
      position: _positionCtrl.text.trim(),
      startDate: _startDateCtrl.text.trim(),
      endDate: _isCurrent ? '' : _endDateCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      isCurrent: _isCurrent,
    );

    final ctrl = Get.find<EditProfileController>();
    if (_editIndex != null) {
      ctrl.updateExperience(_editIndex!, exp);
    } else {
      ctrl.addExperience(exp);
    }
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(_editIndex != null ? 'Edit Experience' : 'Add Experience'),
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
              controller: _companyCtrl,
              label: 'Company Name',
              hint: 'e.g. Google',
              icon: Icons.business_rounded,
              validator: (v) =>
                  v?.trim().isEmpty == true ? 'Company name is required' : null,
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _positionCtrl,
              label: 'Position',
              hint: 'e.g. Senior Flutter Developer',
              icon: Icons.work_outline_rounded,
              validator: (v) =>
                  v?.trim().isEmpty == true ? 'Position is required' : null,
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _startDateCtrl,
              label: 'Start Date',
              hint: 'Tap to select',
              icon: Icons.calendar_today_rounded,
              readOnly: true,
              onTap: () => _pickDate(_startDateCtrl),
              validator: (v) =>
                  v?.trim().isEmpty == true ? 'Start date is required' : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _endDateCtrl,
                    label: 'End Date',
                    hint: _isCurrent ? 'Present' : 'Tap to select',
                    icon: Icons.calendar_today_rounded,
                    readOnly: true,
                    enabled: !_isCurrent,
                    onTap: _isCurrent ? null : () => _pickDate(_endDateCtrl),
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
                  if (_isCurrent) _endDateCtrl.clear();
                });
              },
              title: const Text(
                'I currently work here',
                style: TextStyle(fontSize: 14),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFF1A3794),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 14),
            _buildField(
              controller: _descCtrl,
              label: 'Description',
              hint: 'Describe your responsibilities...',
              icon: Icons.description_outlined,
              maxLines: 4,
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
    bool readOnly = false,
    bool enabled = true,
    VoidCallback? onTap,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      enabled: enabled,
      maxLines: maxLines,
      onTap: onTap,
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
