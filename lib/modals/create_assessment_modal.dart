// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/center_toast.dart';
import '../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Callback & Constants
// ─────────────────────────────────────────────────────────────────────────────

typedef CreateAssessmentCallback =
    Future<void> Function(
      String courseCode,
      String assessmentName,
      String guide, {
      String? icon,
      String? color,
      String? imageBase64,
    });

const List<Map<String, dynamic>> kAssessmentIcons = [
  {'key': 'lab', 'icon': Icons.science_outlined, 'label': 'Lab'},
  {'key': 'midterm', 'icon': Icons.edit_note_rounded, 'label': 'Midterm'},
  {'key': 'quiz', 'icon': Icons.quiz_outlined, 'label': 'Quiz'},
  {'key': 'final', 'icon': Icons.school_outlined, 'label': 'Final'},
  {
    'key': 'assignment',
    'icon': Icons.assignment_outlined,
    'label': 'Assignment',
  },
  {'key': 'project', 'icon': Icons.folder_outlined, 'label': 'Project'},
  {
    'key': 'presentation',
    'icon': Icons.present_to_all_outlined,
    'label': 'Presentation',
  },
];

/// Curated color palette for assessment cards.
const List<Color> kAssessmentColors = [
  Color(0xFF1E6B2D), // Forest Green (default/primary)
  Color(0xFF2563EB), // Royal Blue
  Color(0xFF7C3AED), // Purple
  Color(0xFFDC2626), // Red
  Color(0xFFEA580C), // Orange
  Color(0xFFCA8A04), // Gold
  Color(0xFF0891B2), // Teal
  Color(0xFF64748B), // Slate
];

/// Returns the [IconData] for a given icon key, or a default icon.
IconData assessmentIconFromKey(String? key) {
  if (key == null || key.isEmpty) return Icons.description_outlined;
  final match = kAssessmentIcons.where((e) => e['key'] == key);
  if (match.isEmpty) return Icons.description_outlined;
  return match.first['icon'] as IconData;
}

/// Parses a hex color string (e.g. '#1E6B2D') into a [Color].
Color assessmentColorFromHex(String? hex) {
  if (hex == null || hex.isEmpty) return AppColors.primary;
  try {
    final cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  } catch (_) {
    return AppColors.primary;
  }
}

/// Converts a [Color] to a hex string (e.g. '#1E6B2D').
String colorToHex(Color color) {
  return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Create Assessment Modal
// ─────────────────────────────────────────────────────────────────────────────

class CreateAssessmentModal extends StatefulWidget {
  final CreateAssessmentCallback onCreate;

  const CreateAssessmentModal({super.key, required this.onCreate});

  @override
  State<CreateAssessmentModal> createState() => _CreateAssessmentModalState();
}

class _CreateAssessmentModalState extends State<CreateAssessmentModal> {
  final TextEditingController courseController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController guideController = TextEditingController();
  bool isSubmitting = false;

  String _selectedIcon = 'lab';
  Color _selectedColor = kAssessmentColors.first;
  String? _imageBase64;

  @override
  void dispose() {
    courseController.dispose();
    nameController.dispose();
    guideController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _imageBase64 = base64Encode(bytes));
  }

  Future<void> _submit() async {
    final course = courseController.text.trim();
    final name = nameController.text.trim();
    final guide = guideController.text.trim();

    if (course.isEmpty || name.isEmpty) {
      await CenterToast.show(
        context,
        message: 'Please fill course code and assessment name',
        icon: Icons.error,
        color: Colors.red,
      );
      return;
    }

    setState(() => isSubmitting = true);
    try {
      await widget.onCreate(
        course,
        name,
        guide,
        icon: _selectedIcon,
        color: colorToHex(_selectedColor),
        imageBase64: _imageBase64,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      await CenterToast.show(
        context,
        message: e.toString(),
        icon: Icons.error,
        color: Colors.red,
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle ──
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ── Title ──
              const Text(
                'Create Assessment',
                style: TextStyle(
                  color: Color(0xFF1B3B22),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Add a new lab, quiz or exam.',
                style: TextStyle(
                  color: Color(0xFF607064),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),

              // ── Icon Picker ──
              _SectionLabel(label: 'Choose Icon'),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: kAssessmentIcons.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = kAssessmentIcons[index];
                    final isSelected = _selectedIcon == item['key'];
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedIcon = item['key'] as String),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.15)
                                  : const Color(0xFFF3F5F4),
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: AppColors.primary,
                                      width: 2.2,
                                    )
                                  : null,
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              size: 22,
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFF77887D),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item['label'] as String,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFF8A9B90),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // ── Color Picker ──
              _SectionLabel(label: 'Choose Color'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: kAssessmentColors.map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Course Code ──
              _SectionLabel(label: 'Course Code'),
              const SizedBox(height: 6),
              TextField(
                controller: courseController,
                decoration: _inputDecoration(
                  hint: 'e.g. CS101',
                  icon: Icons.class_outlined,
                ),
              ),
              const SizedBox(height: 14),

              // ── Assessment Name ──
              _SectionLabel(label: 'Assessment Name'),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                decoration: _inputDecoration(
                  hint: 'e.g. Lab, Midterm, Final',
                  icon: Icons.label_outline_rounded,
                ),
              ),
              const SizedBox(height: 14),

              // ── Guide ──
              _SectionLabel(label: 'Guide / Instruction'),
              const SizedBox(height: 6),
              TextField(
                controller: guideController,
                minLines: 3,
                maxLines: 6,
                decoration: _inputDecoration(
                  hint:
                      'Add instructions, scope, due notes…\nSupports **bold**, *italic*, lists',
                  icon: Icons.notes_rounded,
                  alignTop: true,
                ),
              ),
              const SizedBox(height: 14),

              // ── Image Upload ──
              _SectionLabel(label: 'Attach Image (optional)'),
              const SizedBox(height: 6),
              if (_imageBase64 != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        base64Decode(_imageBase64!),
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => setState(() => _imageBase64 = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFCDD5CF),
                        style: BorderStyle.solid,
                        width: 1.5,
                      ),
                      color: const Color(0xFFF8FAF8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          color: AppColors.primary,
                          size: 30,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap to upload image',
                          style: TextStyle(
                            color: const Color(0xFF77887D),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 22),

              // ── Submit Button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isSubmitting ? null : _submit,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_rounded),
                  label: const Text('Create Assessment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    bool alignTop = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.caption, fontSize: 13.5),
      prefixIcon: Padding(
        padding: EdgeInsets.only(top: alignTop ? 12 : 0),
        child: Icon(icon, size: 20, color: const Color(0xFF98A49C)),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAF8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5ECE7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5ECE7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      alignLabelWithHint: alignTop,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF3A5240),
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
