import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/weekly_plan.dart';
import '../domain/planned_task.dart';
import '../domain/weekly_plan_distributor.dart';
import '../data/planner_repository.dart';
import '../../subjects/domain/subject.dart';

final plannerProvider = AsyncNotifierProvider<PlannerNotifier, WeeklyPlanState>(PlannerNotifier.new);

class WeeklyPlanState {
  final WeeklyPlan? plan;
  final Map<int, List<PlannedTask>> tasksByDayNumber; // 1 to 7

  WeeklyPlanState({
    this.plan, 
    this.tasksByDayNumber = const {}
  });
}

class PlannerNotifier extends AsyncNotifier<WeeklyPlanState> {
  @override
  Future<WeeklyPlanState> build() async {
    return _loadPlan();
  }

  Future<WeeklyPlanState> _loadPlan() async {
    final repository = ref.watch(plannerRepositoryProvider);
    final plan = await repository.getActivePlan();
    if (plan == null) {
      return WeeklyPlanState();
    }

    final tasks = await repository.getTasksForPlan(plan.id);
    
    final Map<int, List<PlannedTask>> tasksByDayNumber = {};
    for (var task in tasks) {
      if (!tasksByDayNumber.containsKey(task.dayNumber)) {
        tasksByDayNumber[task.dayNumber] = [];
      }
      tasksByDayNumber[task.dayNumber]!.add(task);
    }

    return WeeklyPlanState(plan: plan, tasksByDayNumber: tasksByDayNumber);
  }

  Future<void> addManualTask(Subject subject, int dayNumber) async {
    final repository = ref.read(plannerRepositoryProvider);
    WeeklyPlan? currentPlan = state.value?.plan;
    
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      
      if (currentPlan == null) {
        final now = DateTime.now();
        currentPlan = WeeklyPlan(
          id: const Uuid().v4(),
          cycleStartDate: DateTime(now.year, now.month, now.day),
          createdAt: now,
          updatedAt: now,
        );
        await repository.createPlan(currentPlan!);
      }

      final existingTasks = await repository.getTasksForDayNumber(dayNumber);
      final nextOrder = existingTasks.length;

      final task = PlannedTask(
        id: const Uuid().v4(),
        planId: currentPlan!.id,
        subjectId: subject.id,
        dayNumber: dayNumber,
        displayOrder: nextOrder,
      );

      await repository.addTasks([task]);
      return _loadPlan();
    });
  }

  Future<void> autoDistribute(List<Subject> subjects, int subjectsPerDay) async {
    final repository = ref.read(plannerRepositoryProvider);
    WeeklyPlan? currentPlan = state.value?.plan;
    
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (currentPlan == null) {
        final now = DateTime.now();
        currentPlan = WeeklyPlan(
          id: const Uuid().v4(),
          cycleStartDate: DateTime(now.year, now.month, now.day),
          createdAt: now,
          updatedAt: now,
        );
        await repository.createPlan(currentPlan!);
      }

      final tasks = WeeklyPlanDistributor.distribute(currentPlan!, subjects, subjectsPerDay);
      await repository.addTasks(tasks);
      
      return _loadPlan();
    });
  }

  Future<void> moveTask(PlannedTask task, int newDayNumber, int newIndex) async {
    final repository = ref.read(plannerRepositoryProvider);
    
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final updatedTask = task.copyWith(
        dayNumber: newDayNumber,
        displayOrder: newIndex,
      );
      await repository.updateTask(updatedTask);
      return _loadPlan();
    });
  }
  
  Future<void> deleteTask(String taskId) async {
    final repository = ref.read(plannerRepositoryProvider);
    
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.deleteTask(taskId);
      return _loadPlan();
    });
  }
  
  Future<void> clearPlan() async {
    final repository = ref.read(plannerRepositoryProvider);
    final currentPlan = state.value?.plan;
    
    if (currentPlan != null) {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() async {
        final tasks = await repository.getTasksForPlan(currentPlan.id);
        for(var task in tasks) {
           await repository.deleteTask(task.id);
        }
        return _loadPlan();
      });
    }
  }
}
