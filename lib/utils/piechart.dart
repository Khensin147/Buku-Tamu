import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ModernPieChart extends StatefulWidget {
  final Map<String, double> data; // label -> value
  final String title;

  const ModernPieChart({
    super.key,
    required this.data,
    this.title = 'Distribusi',
  });

  @override
  State<ModernPieChart> createState() => _ModernPieChartState();
}

class _ModernPieChartState extends State<ModernPieChart> {
  int touchedIndex = -1;

  // Enhanced color palette for better employee distinction
  final List<Color> sectionColors = [
    const Color(0xff0293ee), // Blue
    const Color(0xfff8b250), // Orange
    const Color(0xff845bef), // Purple
    const Color(0xff13d38e), // Green
    const Color(0xffff5722), // Deep Orange
    const Color(0xff2196f3), // Light Blue
    const Color(0xffe91e63), // Pink
    const Color(0xff4caf50), // Light Green
    const Color(0xffff9800), // Amber
    const Color(0xff9c27b0), // Deep Purple
    const Color(0xff607d8b), // Blue Grey
    const Color(0xffcddc39), // Lime
  ];

  @override
  Widget build(BuildContext context) {
    final entries = widget.data.entries.toList();
    final total = widget.data.values.fold(0.0, (a, b) => a + b);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.3,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (
                            FlTouchEvent event,
                            pieTouchResponse,
                          ) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                touchedIndex = -1;
                                return;
                              }
                              touchedIndex =
                                  pieTouchResponse
                                      .touchedSection!
                                      .touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: List.generate(entries.length, (i) {
                          final isTouched = i == touchedIndex;
                          final double radius = isTouched ? 60 : 50;
                          final double fontSize = isTouched ? 18 : 14;

                          final value = entries[i].value;
                          final label = entries[i].key;
                          final percent =
                              total > 0
                                  ? (value / total * 100).toStringAsFixed(1)
                                  : '0';

                          return PieChartSectionData(
                            color: sectionColors[i % sectionColors.length],
                            value: value,
                            title: '$percent%',
                            radius: radius,
                            titleStyle: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: const Offset(1, 1),
                                  blurRadius: 2,
                                  color: Colors.black.withOpacity(0.5),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                      swapAnimationDuration: const Duration(milliseconds: 350),
                      swapAnimationCurve: Curves.easeInOut,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Enhanced Legend / Indicator
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(entries.length, (i) {
                          final isSelected = i == touchedIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? sectionColors[i % sectionColors.length]
                                          .withOpacity(0.1)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        sectionColors[i % sectionColors.length],
                                    boxShadow:
                                        isSelected
                                            ? [
                                              BoxShadow(
                                                color: sectionColors[i %
                                                        sectionColors.length]
                                                    .withOpacity(0.5),
                                                blurRadius: 4,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                            : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entries[i].key,
                                        style: TextStyle(
                                          fontSize: isSelected ? 15 : 14,
                                          fontWeight:
                                              isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${entries[i].value.toInt()} tamu',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
