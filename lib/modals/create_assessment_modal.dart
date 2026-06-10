import 'package:flutter/material.dart';
import '../widgets/center_toast.dart';
import '../core/theme/app_colors.dart';

typedef CreateAssessmentCallback =
    Future<void> Function(
      String courseCode,
      String assessmentName,
      String guide,
    );

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

  @override
  void dispose() {
    courseController.dispose();
    nameController.dispose();
    guideController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final course = courseController.text.trim();
    final name = nameController.text.trim();
    final guide = guideController.text.trim();

    if (course.isEmpty || name.isEmpty) {
      await CenterToast.show(
        context,
        message: 'Please fill all fields',
        icon: Icons.error,
        color: Colors.red,
      );
      return;
    }

    setState(() => isSubmitting = true);
    try {
      await widget.onCreate(course, name, guide);
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
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: courseController,
              decoration: const InputDecoration(
                labelText: 'Course Code',
                hintText: 'e.g. CS101',
                hintStyle: TextStyle(color: AppColors.caption),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Assessment Type / Name',
                hintText: 'e.g. Lecture, Lab, Midterm, Final',
                hintStyle: TextStyle(color: AppColors.caption),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: guideController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Guide / Details',
                hintText: 'e.g. Add instructions, scope, due notes, or details',
                hintStyle: TextStyle(color: AppColors.caption),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
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
                    : const Icon(Icons.add),
                label: const Text('Create Assessment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
