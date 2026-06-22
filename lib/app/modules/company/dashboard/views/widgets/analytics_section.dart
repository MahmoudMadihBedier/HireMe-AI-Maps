import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/utils/app_color.dart';
import '../../controllers/company_dashboard_controller.dart';

class AnalyticsSection extends StatelessWidget {
  final CompanyDashboardController controller;

  const AnalyticsSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColor.kwhite,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColor.kblack.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Analytics',
                style: TextStyle(
                  color: AppColor.kblack,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              _TimeRangeChips(controller: controller),
            ],
          ),
          const SizedBox(height: 14),
          Obx(() {
            if (controller.isChartLoading.value) {
              return const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return Column(
              children: [
                _BarChartSection(controller: controller),
                const SizedBox(height: 18),
                _PieChartSection(controller: controller),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _TimeRangeChips extends StatelessWidget {
  final CompanyDashboardController controller;
  const _TimeRangeChips({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedTimeRange.value;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: ['week', 'month', 'all'].map((range) {
          final isSelected = selected == range;
          final label = range == 'week'
              ? 'Week'
              : range == 'month'
              ? 'Month'
              : 'All';
          return Padding(
            padding: const EdgeInsets.only(left: 6),
            child: GestureDetector(
              onTap: () => controller.setTimeRange(range),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF4A6CF7) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF4A6CF7), width: 1),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppColor.kwhite : const Color(0xFF4A6CF7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}

class _BarChartSection extends StatelessWidget {
  final CompanyDashboardController controller;
  const _BarChartSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.topJobs;
      if (items.isEmpty) {
        return _chartEmpty('No application data for this period');
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Jobs by Applications',
            style: TextStyle(
              color: AppColor.kblack,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (items.map((e) => e.count).reduce((a, b) => a > b ? a : b) + 1)
                    .toDouble(),
                barGroups: items.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.count.toDouble(),
                        color: entry.value.color,
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        if (value == value.roundToDouble()) {
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFA6A6A6),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= items.length) {
                          return const SizedBox();
                        }
                        final title = items[idx].jobTitle;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            title.length > 10
                                ? '${title.substring(0, 10)}..'
                                : title,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFFA6A6A6),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _chartEmpty(String message) {
    return SizedBox(
      height: 80,
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: AppColor.greyLight, fontSize: 12),
        ),
      ),
    );
  }
}

class _PieChartSection extends StatelessWidget {
  final CompanyDashboardController controller;
  const _PieChartSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.statusDistribution;
      if (items.isEmpty) {
        return _chartEmpty('No status data for this period');
      }
      final total = items.fold(0, (sum, e) => sum + e.count);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Application Status',
            style: TextStyle(
              color: AppColor.kblack,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: PieChart(
                  PieChartData(
                    sections: items.map((item) {
                      final pct = total > 0 ? item.count / total : 0.0;
                      return PieChartSectionData(
                        value: pct * 100,
                        color: item.color,
                        radius: 42,
                        title: '${(pct * 100).round()}%',
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 26,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items.map((item) {
                    final label = item.status == 'under_review'
                        ? 'Under Review'
                        : item.status[0].toUpperCase() +
                              item.status.substring(1);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: item.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '${item.count}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _chartEmpty(String message) {
    return SizedBox(
      height: 80,
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: AppColor.greyLight, fontSize: 12),
        ),
      ),
    );
  }
}
