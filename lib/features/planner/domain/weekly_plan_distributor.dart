import 'package:uuid/uuid.dart';
import '../domain/weekly_plan.dart';
import '../domain/planned_task.dart';
import '../../subjects/domain/subject.dart';

class WeeklyPlanDistributor {
  /// Distributes a list of subjects across a week starting from [weekStartDate].
  /// [subjectsPerDay] defines how many subjects to assign each day.
  /// Ensure all subjects are assigned. If the total number of subjects is not a multiple
  /// of 7, the remaining days will have fewer subjects.
  static List<PlannedTask> distribute(
    WeeklyPlan plan,
    List<Subject> subjects,
    int subjectsPerDay,
  ) {
    if (subjects.isEmpty) return [];

    final List<PlannedTask> tasks = [];
    final uuid = const Uuid();
    
    int subjectIndex = 0;
    
    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      final currentDayNumber = dayIndex + 1; // 1 to 7
      
      for (int i = 0; i < subjectsPerDay; i++) {
        if (subjectIndex >= subjects.length) {
          break;
        }
        
        final subject = subjects[subjectIndex];
        tasks.add(
          PlannedTask(
            id: uuid.v4(),
            planId: plan.id,
            subjectId: subject.id,
            dayNumber: currentDayNumber,
            displayOrder: i,
          )
        );
        
        subjectIndex++;
      }
      
      if (subjectIndex >= subjects.length) {
        break;
      }
    }
    
    if (subjectIndex < subjects.length) {
      int dayIndex = 0;
      while (subjectIndex < subjects.length) {
        final currentDayNumber = dayIndex + 1;
        final subject = subjects[subjectIndex];
        
        final dayTasks = tasks.where((t) => t.dayNumber == currentDayNumber).toList();
        final maxOrder = dayTasks.isEmpty ? 0 : dayTasks.map((e) => e.displayOrder).reduce((a, b) => a > b ? a : b) + 1;
        
        tasks.add(
          PlannedTask(
            id: uuid.v4(),
            planId: plan.id,
            subjectId: subject.id,
            dayNumber: currentDayNumber,
            displayOrder: maxOrder,
          )
        );
        
        subjectIndex++;
        dayIndex = (dayIndex + 1) % 7;
      }
    }

    return tasks;
  }
}
