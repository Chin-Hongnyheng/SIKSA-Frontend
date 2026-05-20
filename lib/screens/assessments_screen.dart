import 'package:flutter/material.dart';
import '../graphql/graphql_service.dart';
import '../widgets/center_toast.dart';
import '../widgets/loading.dart';
import '../modals/create_assessment_modal.dart';

class AssessmentsScreen extends StatefulWidget {
  const AssessmentsScreen({super.key});

  @override
  State<AssessmentsScreen> createState() => _AssessmentsScreenState();
}

class _AssessmentsScreenState extends State<AssessmentsScreen> {
  final GraphQLService graphqlService = GraphQLService();
  bool isLoading = true;
  List<Map<String, dynamic>> assessments = [];
  String? role;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = await graphqlService.me();
      role = user['role'] as String?;
    } catch (_) {
      role = null;
    }

    try {
      final list = await graphqlService.getAllMyAssessments();
      if (!mounted) return;
      setState(() {
        assessments = list;
      });
    } catch (e) {
      await CenterToast.show(
        context,
        message: e.toString(),
        icon: Icons.error,
        color: Colors.red,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _openCreateModal() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateAssessmentModal(
        onCreate: (course, name) async {
          LoadingOverlay.show(context);
          try {
            await graphqlService.createAssessment(
              courseCode: course,
              assessmentName: name,
            );
            await CenterToast.show(
              context,
              message: 'Assessment created',
              icon: Icons.check_circle,
              color: Colors.green,
            );
            await fetchData();
          } catch (e) {
            await CenterToast.show(
              context,
              message: e.toString(),
              icon: Icons.error,
              color: Colors.red,
            );
          } finally {
            LoadingOverlay.hide();
          }
        },
      ),
    );
  }

  Future<void> _deleteAssessment(
    String courseCode,
    String assessmentName,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete assessment'),
            content: Text('Delete "$assessmentName" for $courseCode?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    LoadingOverlay.show(context);
    try {
      await graphqlService.deleteAssessment(
        courseCode: courseCode,
        assessmentName: assessmentName,
      );
      await CenterToast.show(
        context,
        message: 'Assessment deleted',
        icon: Icons.check_circle,
        color: Colors.green,
      );
      await fetchData();
    } catch (e) {
      await CenterToast.show(
        context,
        message: e.toString(),
        icon: Icons.error,
        color: Colors.red,
      );
    } finally {
      LoadingOverlay.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = role == 'Teacher' || role == 'Admin';

    return Scaffold(
      appBar: AppBar(title: const Text('My Assessments')),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: _openCreateModal,
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : assessments.isEmpty
            ? const Center(child: Text('No assessments found'))
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemBuilder: (ctx, i) {
                  final a = assessments[i];
                  final createdAt = a['createdAt']?.toString() ?? '';
                  return ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    title: Text(a['assessmentName'] ?? ''),
                    subtitle: Text(
                      '${a['courseCode'] ?? ''} • ${createdAt.split('T').first}',
                    ),
                    trailing: canManage
                        ? IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _deleteAssessment(
                              a['courseCode'] ?? '',
                              a['assessmentName'] ?? '',
                            ),
                          )
                        : null,
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: assessments.length,
              ),
      ),
    );
  }
}
