import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import 'activity_provider.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityState = ref.watch(activityProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
      ),
      body: activityState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStreakCards(data),
            const SizedBox(height: 24),
            _buildHeatmapSection(data),
            const SizedBox(height: 24),
            _buildMonthlyBreakdown(data),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCards(ActivityData data) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department,
            iconColor: AppColors.accent,
            label: 'Current Streak',
            value: '${data.currentStreak}',
            unit: 'days',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.emoji_events,
            iconColor: AppColors.secondary,
            label: 'Longest Streak',
            value: '${data.longestStreak}',
            unit: 'days',
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmapSection(ActivityData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Study Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${data.totalActiveDays} days · ${data.totalSessions} sessions',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ActivityHeatmap(activityMap: data.activityMap),
        const SizedBox(height: 12),
        _buildHeatmapLegend(),
      ],
    );
  }

  Widget _buildHeatmapLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text('Less', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(width: 4),
        _legendBox(AppColors.heatLevel0),
        _legendBox(AppColors.heatLevel1),
        _legendBox(AppColors.heatLevel2),
        _legendBox(AppColors.heatLevel3),
        _legendBox(AppColors.heatLevel4),
        _legendBox(AppColors.heatLevel5),
        const SizedBox(width: 4),
        const Text('More', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _legendBox(Color color) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// Monthly breakdown — derived directly from activityMap so it updates when activityProvider refreshes
  Widget _buildMonthlyBreakdown(ActivityData data) {
    final now = DateTime.now();
    // Current month + previous 3 months = 4 months
    final months = List.generate(4, (i) => DateTime(now.year, now.month - i, 1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monthly Breakdown',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...months.map((month) {
          // Compute session count & active days from the activityMap
          int sessionCount = 0;
          int activeDays = 0;

          data.activityMap.forEach((date, count) {
            if (date.year == month.year && date.month == month.month) {
              sessionCount += count;
              activeDays++;
            }
          });

          return _buildMonthRow(month, sessionCount, activeDays);
        }),
      ],
    );
  }

  Widget _buildMonthRow(DateTime month, int sessionCount, int activeDays) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                DateFormat('MMMM yyyy').format(month),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '$sessionCount',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'sessions',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${activeDays}d',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// GitHub-style activity heatmap — shows current month fully + 3 previous months
class _ActivityHeatmap extends StatelessWidget {
  final Map<DateTime, int> activityMap;

  const _ActivityHeatmap({required this.activityMap});

  Color _getColor(int count) {
    if (count == 0) return AppColors.heatLevel0;
    if (count == 1) return AppColors.heatLevel1;
    if (count == 2) return AppColors.heatLevel2;
    if (count == 3) return AppColors.heatLevel3;
    if (count <= 5) return AppColors.heatLevel4;
    return AppColors.heatLevel5;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // End at the last day of the current month so it's shown fully
    final endDate = DateTime(now.year, now.month + 1, 0); // last day of current month

    // Start from 1st of 3 months ago
    final startMonth = DateTime(now.year, now.month - 3, 1);
    // Align to the nearest Sunday on or before startMonth
    final startDate = startMonth.subtract(Duration(days: startMonth.weekday % 7));

    // Calculate number of weeks needed
    final totalDays = endDate.difference(startDate).inDays + 1;
    final totalWeeks = (totalDays / 7).ceil();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const dayLabelWidth = 22.0;
          const gridGap = 3.0;
          // Calculate cell size to fill available width with consistent gaps
          final availableWidth = constraints.maxWidth - dayLabelWidth - gridGap;
          final cellSize = ((availableWidth - (totalWeeks - 1) * gridGap) / totalWeeks)
              .clamp(6.0, 13.0);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month labels row
              Padding(
                padding: EdgeInsets.only(left: dayLabelWidth + gridGap),
                child: _buildMonthLabelsRow(startDate, totalWeeks, cellSize, gridGap),
              ),
              const SizedBox(height: 4),
              // Heatmap grid
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day of week labels
                  SizedBox(
                    width: dayLabelWidth,
                    child: Column(
                      children: [
                        SizedBox(height: cellSize + gridGap), // Sun
                        SizedBox(
                          height: cellSize + gridGap,
                          child: const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('M', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                          ),
                        ),
                        SizedBox(height: cellSize + gridGap), // Tue
                        SizedBox(
                          height: cellSize + gridGap,
                          child: const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('W', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                          ),
                        ),
                        SizedBox(height: cellSize + gridGap), // Thu
                        SizedBox(
                          height: cellSize + gridGap,
                          child: const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('F', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                          ),
                        ),
                        SizedBox(height: cellSize), // Sat
                      ],
                    ),
                  ),
                  SizedBox(width: gridGap),
                  // Grid of cells with consistent spacing
                  Expanded(
                    child: Wrap(
                      spacing: gridGap,
                      runSpacing: 0,
                      children: List.generate(totalWeeks, (weekIdx) {
                        return SizedBox(
                          width: cellSize,
                          child: Column(
                            children: List.generate(7, (dayIdx) {
                              final date = startDate.add(Duration(days: weekIdx * 7 + dayIdx));
                              final count = activityMap[date] ?? 0;
                              // Future days (after today) show as transparent
                              final isFuture = date.isAfter(today);
                              // Days before the actual start month are out of range
                              final isBeforeRange = date.isBefore(startMonth);

                              return Padding(
                                padding: EdgeInsets.only(bottom: dayIdx < 6 ? gridGap : 0),
                                child: Tooltip(
                                  message: (isFuture || isBeforeRange)
                                      ? ''
                                      : '$count session${count != 1 ? 's' : ''} on ${DateFormat('MMM d').format(date)}',
                                  child: Container(
                                    width: cellSize,
                                    height: cellSize,
                                    decoration: BoxDecoration(
                                      color: (isFuture || isBeforeRange)
                                          ? AppColors.surfaceLight.withValues(alpha: 0.3)
                                          : _getColor(count),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthLabelsRow(DateTime startDate, int totalWeeks, double cellSize, double gap) {
    final labels = <Widget>[];
    String? lastMonth;

    for (int w = 0; w < totalWeeks; w++) {
      final firstDayOfWeek = startDate.add(Duration(days: w * 7));
      final monthStr = DateFormat('MMM').format(firstDayOfWeek);

      if (monthStr != lastMonth && firstDayOfWeek.day <= 7) {
        lastMonth = monthStr;
        labels.add(SizedBox(
          width: cellSize + gap,
          child: Text(
            monthStr,
            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
          ),
        ));
      } else {
        labels.add(SizedBox(width: cellSize + gap));
      }
    }

    return Row(children: labels);
  }
}

