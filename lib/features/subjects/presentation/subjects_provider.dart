import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/subject.dart';
import '../data/subject_repository.dart';

final subjectsProvider = AsyncNotifierProvider<SubjectsNotifier, List<Subject>>(SubjectsNotifier.new);

class SubjectsNotifier extends AsyncNotifier<List<Subject>> {
  @override
  Future<List<Subject>> build() async {
    final repository = ref.watch(subjectRepositoryProvider);
    return repository.getAllSubjects();
  }

  Future<void> addSubject(Subject subject) async {
    final repository = ref.read(subjectRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.addSubject(subject);
      return repository.getAllSubjects();
    });
  }

  Future<void> updateSubject(Subject subject) async {
    final repository = ref.read(subjectRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.updateSubject(subject);
      return repository.getAllSubjects();
    });
  }

  Future<void> archiveSubject(String id) async {
    final repository = ref.read(subjectRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.archiveSubject(id);
      return repository.getAllSubjects();
    });
  }

  Future<void> deleteSubject(String id) async {
    final repository = ref.read(subjectRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.deleteSubject(id);
      return repository.getAllSubjects();
    });
  }
}
