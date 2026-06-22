import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hire_me/app/modules/job_seeker/edit_profile/controllers/edit_profile_controller.dart';
import 'package:hire_me/app/modules/job_seeker/profile/models/user_model.dart';
import 'package:hire_me/core/utils/app_color.dart';

class LinkFormView extends StatefulWidget {
  const LinkFormView({super.key});

  @override
  State<LinkFormView> createState() => _LinkFormViewState();
}

class _LinkFormViewState extends State<LinkFormView> {
  final _formKey = GlobalKey<FormState>();
  final _urlCtrl = TextEditingController();
  String _selectedType = 'LinkedIn';
  int? _editIndex;

  final _types = ['LinkedIn', 'GitHub', 'Portfolio', 'Other'];

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      _editIndex = args['index'] as int?;
      final link = args['link'] as LinkModel?;
      if (link != null) {
        _selectedType = link.type;
        _urlCtrl.text = link.url;
      }
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final link = LinkModel(
      type: _selectedType,
      url: _urlCtrl.text.trim(),
    );

    final ctrl = Get.find<EditProfileController>();
    if (_editIndex != null) {
      ctrl.updateLink(_editIndex!, link);
    } else {
      ctrl.addLink(link);
    }
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(_editIndex != null ? 'Edit Link' : 'Add Link'),
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
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: InputDecoration(
                labelText: 'Link Type',
                prefixIcon:
                    const Icon(Icons.label_outline, color: Color(0xFF1A3794)),
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
              items: _types.map((t) {
                return DropdownMenuItem(value: t, child: Text(t));
              }).toList(),
              onChanged: (v) {
                setState(() => _selectedType = v ?? 'Other');
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _urlCtrl,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: 'URL',
                hintText: 'https://...',
                prefixIcon:
                    const Icon(Icons.link_rounded, color: Color(0xFF1A3794)),
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
              validator: (v) {
                if (v?.trim().isEmpty == true) return 'URL is required';
                final uri = Uri.tryParse(v!.trim());
                if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
                  return 'Enter a valid URL (e.g. https://github.com/username)';
                }
                return null;
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
