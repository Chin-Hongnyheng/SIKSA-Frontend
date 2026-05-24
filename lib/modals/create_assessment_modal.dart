import 'package:flutter/material.dart';
import '../widgets/center_toast.dart';

class CreateAssessmentModal extends StatefulWidget {
  final Future<void> Function(String courseCode, String assessmentName)
  onCreate;

  const CreateAssessmentModal({super.key, required this.onCreate});

  @override
  State<CreateAssessmentModal> createState() => _CreateAssessmentModalState();
}

class _CreateAssessmentModalState extends State<CreateAssessmentModal> {
  final TextEditingController courseController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  bool isSubmitting = false;

  @override
  void dispose() {
    courseController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final course = courseController.text.trim();
    final name = nameController.text.trim();

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
      await widget.onCreate(course, name);
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
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Assessment Name',
                hintText: 'e.g. Midterm Quiz',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submit,
                child: isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create Assessment'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
