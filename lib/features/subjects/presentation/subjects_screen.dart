import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'subjects_provider.dart';
import '../domain/subject.dart';
import '../../../core/constants/app_colors.dart';

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsState = ref.watch(subjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
      ),
      body: subjectsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (subjects) {
          if (subjects.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return _buildSubjectCard(context, ref, subject);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSubjectDialog(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'No subjects yet.',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first subject to start planning.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, WidgetRef ref, Subject subject) {
    final color = Color(int.parse(subject.accentColor.replaceAll('#', '0xFF')));
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(subject.icon, style: const TextStyle(fontSize: 24)),
          ),
        ),
        title: Text(
          subject.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: subject.isActive ? null : TextDecoration.lineThrough,
            color: subject.isActive ? AppColors.textPrimary : AppColors.textDisabled,
          ),
        ),
        subtitle: subject.description != null && subject.description!.isNotEmpty
            ? Text(subject.description!, style: const TextStyle(color: AppColors.textSecondary))
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            _showSubjectOptions(context, ref, subject);
          },
        ),
      ),
    );
  }

  void _showSubjectOptions(BuildContext context, WidgetRef ref, Subject subject) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _showSubjectDialog(context, ref, subject: subject);
                },
              ),
              ListTile(
                leading: Icon(subject.isActive ? Icons.archive : Icons.unarchive),
                title: Text(subject.isActive ? 'Archive' : 'Restore'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(subjectsProvider.notifier).updateSubject(
                        subject.copyWith(
                          isActive: !subject.isActive,
                          updatedAt: DateTime.now(),
                        ),
                      );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text('Delete', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, ref, subject);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSubjectDialog(BuildContext context, WidgetRef ref, {Subject? subject}) {
    final nameController = TextEditingController(text: subject?.name);
    final descController = TextEditingController(text: subject?.description);
    String selectedIcon = subject?.icon ?? '📚';
    String selectedColor = subject?.accentColor ?? '#6366F1';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(subject == null ? 'New Subject' : 'Edit Subject'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description (optional)'),
                    ),
                    // In a real app, you'd add color and icon pickers here.
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    
                    final now = DateTime.now();
                    if (subject == null) {
                      final newSubject = Subject(
                        id: const Uuid().v4(),
                        name: name,
                        description: descController.text,
                        icon: selectedIcon,
                        accentColor: selectedColor,
                        createdAt: now,
                        updatedAt: now,
                      );
                      ref.read(subjectsProvider.notifier).addSubject(newSubject);
                    } else {
                      final updated = subject.copyWith(
                        name: name,
                        description: descController.text,
                        updatedAt: now,
                      );
                      ref.read(subjectsProvider.notifier).updateSubject(updated);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Subject subject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject?'),
        content: Text('Are you sure you want to permanently delete "${subject.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(subjectsProvider.notifier).deleteSubject(subject.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
