import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class ActivityChart extends StatelessWidget {
  final List<Map<String, dynamic>> userTrend;
  final List<Map<String, dynamic>> reservationTrend;

  const ActivityChart({
    super.key,
    required this.userTrend,
    required this.reservationTrend,
  });

  @override
  Widget build(BuildContext context) {
    final userSpots = <FlSpot>[];
    final reservationSpots = <FlSpot>[];

    for (int i = 0; i < userTrend.length; i++) {
      userSpots.add(FlSpot(i.toDouble(), (userTrend[i]['count'] as int).toDouble()));
    }
    for (int i = 0; i < reservationTrend.length; i++) {
      reservationSpots.add(FlSpot(i.toDouble(), (reservationTrend[i]['count'] as int).toDouble()));
    }

    final maxY = [
      ...userSpots.map((s) => s.y),
      ...reservationSpots.map((s) => s.y),
    ].fold<double>(0, (a, b) => a > b ? a : b);

    final labels = userTrend.map((e) => e['month'] as String).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkSurfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Tendencia de actividad',
                style: AppTypography.subtitle1.copyWith(color: AppColors.darkTextPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? (maxY / 4).ceilToDouble().clamp(1, double.infinity) : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.darkSurfaceVariant.withAlpha(120),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: maxY > 0 ? (maxY / 4).ceilToDouble().clamp(1, double.infinity) : 1,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.darkTextSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[idx],
                            style: AppTypography.caption.copyWith(
                              color: AppColors.darkTextSecondary,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (labels.length - 1).toDouble(),
                minY: 0,
                maxY: maxY > 0 ? maxY + 1 : 5,
                lineBarsData: [
                  LineChartBarData(
                    spots: userSpots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.primary,
                        strokeWidth: 2,
                        strokeColor: AppColors.darkBackground,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withAlpha(30),
                    ),
                  ),
                  LineChartBarData(
                    spots: reservationSpots,
                    isCurved: true,
                    color: AppColors.info,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.info,
                        strokeWidth: 2,
                        strokeColor: AppColors.darkBackground,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.info.withAlpha(30),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(color: AppColors.primary, label: 'Usuarios'),
              const SizedBox(width: AppSpacing.lg),
              _legendDot(color: AppColors.info, label: 'Reservas'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.darkTextSecondary)),
      ],
    );
  }
}
