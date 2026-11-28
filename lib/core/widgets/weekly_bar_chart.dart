import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WeeklyBarChartItem {
  final String dayLabel;
  final int rescuedCount;
  final int usedCount;
  final int discardedCount;
  final DateTime date;

  const WeeklyBarChartItem({
    required this.dayLabel,
    required this.rescuedCount,
    required this.usedCount,
    required this.discardedCount,
    required this.date,
  });

  int get total => rescuedCount + usedCount + discardedCount;
}

class WeeklyBarChart extends StatefulWidget {
  final List<WeeklyBarChartItem> items;
  final double height;

  const WeeklyBarChart({
    super.key,
    required this.items,
    this.height = 160,
  });

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showTable = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.normal,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Accessibility / alternative table view toggle
        Align(
          alignment: Alignment.centerRight,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: TextButton.icon(
              icon: Icon(
                _showTable ? Icons.bar_chart_rounded : Icons.table_chart_outlined,
                size: AppSizes.iconSm,
              ),
              label: Text(_showTable ? 'Show as chart' : 'Show as table'),
              onPressed: () {
                setState(() {
                  _showTable = !_showTable;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (_showTable)
          _buildTableView(context)
        else
          _buildChartView(context, text),
        const SizedBox(height: AppSpacing.md),
        // Legend
        _buildLegend(context, text),
      ],
    );
  }

  Widget _buildChartView(BuildContext context, TextTheme text) {
    return Semantics(
      label: '7-day food usage stacked bar chart. Toggle table view for accessible values.',
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return SizedBox(
            height: widget.height,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _BarChartPainter(
                  items: widget.items,
                  animationProgress: _animation.value,
                  rescuedColor: AppColors.lime,
                  usedColor: AppColors.orange,
                  discardedColor: AppColors.critical,
                  gridColor: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                  textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTableView(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: AppSpacing.md,
        columns: [
          DataColumn(label: Text('Day', style: text.labelMedium)),
          DataColumn(label: Text('Rescued', style: text.labelMedium?.copyWith(color: AppColors.lime))),
          DataColumn(label: Text('Used', style: text.labelMedium?.copyWith(color: AppColors.orange))),
          DataColumn(label: Text('Discarded', style: text.labelMedium?.copyWith(color: AppColors.critical))),
          DataColumn(label: Text('Total', style: text.labelMedium)),
        ],
        rows: widget.items.map((item) {
          return DataRow(cells: [
            DataCell(Text(item.dayLabel)),
            DataCell(Text('${item.rescuedCount}')),
            DataCell(Text('${item.usedCount}')),
            DataCell(Text('${item.discardedCount}')),
            DataCell(Text('${item.total}', style: const TextStyle(fontWeight: FontWeight.bold))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildLegend(BuildContext context, TextTheme text) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        _legendItem(AppColors.lime, 'Rescued', text),
        _legendItem(AppColors.orange, 'Used', text),
        _legendItem(AppColors.critical, 'Discarded', text),
      ],
    );
  }

  Widget _legendItem(Color color, String label, TextTheme text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: text.labelSmall,
        ),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<WeeklyBarChartItem> items;
  final double animationProgress;
  final Color rescuedColor;
  final Color usedColor;
  final Color discardedColor;
  final Color gridColor;
  final Color textColor;

  _BarChartPainter({
    required this.items,
    required this.animationProgress,
    required this.rescuedColor,
    required this.usedColor,
    required this.discardedColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    const double bottomPadding = 24.0;
    const double topPadding = 12.0;
    final double availableHeight = size.height - bottomPadding - topPadding;
    final double width = size.width;

    // Find max value across all items for Y-axis scale (at least 5 for breathing room)
    int maxVal = 5;
    for (final item in items) {
      if (item.total > maxVal) {
        maxVal = item.total;
      }
    }

    // Draw horizontal grid lines (3 lines)
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final y = topPadding + (availableHeight * (1 - i / 3));
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // Bar dimensions
    final double colWidth = width / items.length;
    final double barWidth = (colWidth * 0.45).clamp(8.0, 28.0);

    final rescuedPaint = Paint()..color = rescuedColor;
    final usedPaint = Paint()..color = usedColor;
    final discardedPaint = Paint()..color = discardedColor;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final centerX = (i * colWidth) + (colWidth / 2);

      // Heights scaled to animation
      final double rH = (item.rescuedCount / maxVal) * availableHeight * animationProgress;
      final double uH = (item.usedCount / maxVal) * availableHeight * animationProgress;
      final double dH = (item.discardedCount / maxVal) * availableHeight * animationProgress;

      double currentY = topPadding + availableHeight;

      // Draw bottom-up stacked bar: 1. Rescued (lime)
      if (rH > 0) {
        final rect = Rect.fromLTWH(centerX - barWidth / 2, currentY - rH, barWidth, rH);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            rect,
            bottomLeft: const Radius.circular(2),
            bottomRight: const Radius.circular(2),
          ),
          rescuedPaint,
        );
        currentY -= rH;
      }

      // 2. Used (orange)
      if (uH > 0) {
        final rect = Rect.fromLTWH(centerX - barWidth / 2, currentY - uH, barWidth, uH);
        canvas.drawRect(rect, usedPaint);
        currentY -= uH;
      }

      // 3. Discarded (red)
      if (dH > 0) {
        final rect = Rect.fromLTWH(centerX - barWidth / 2, currentY - dH, barWidth, dH);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: const Radius.circular(2),
            topRight: const Radius.circular(2),
          ),
          discardedPaint,
        );
      }

      // Draw X-axis day label
      final textSpan = TextSpan(
        text: item.dayLabel,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(centerX - textPainter.width / 2, size.height - bottomPadding + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.items != items;
  }
}
