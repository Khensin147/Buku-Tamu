import 'package:buku_tamu_penmad/utils/Barchart.dart';
import 'package:buku_tamu_penmad/utils/piechart.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db/database.dart';

enum PeriodType { weekly, monthly, yearly }

class GrafikPage extends StatefulWidget {
  const GrafikPage({super.key});

  @override
  State<GrafikPage> createState() => _GrafikPageState();
}

class _GrafikPageState extends State<GrafikPage> with TickerProviderStateMixin {
  PeriodType selectedPeriod = PeriodType.monthly;
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  int selectedWeek = 1;
  int touchedIndex = -1;

  // Data untuk charts - fokus pada pegawai
  List<int> jumlahPerPeriod = [];
  Map<String, int> jumlahPerPegawai = {};
  Map<String, int> jumlahPerInstansi = {};
  List<String> periodLabels = [];

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _chartController;
  late Animation<Offset> _slideAnimation1;
  late Animation<Offset> _slideAnimation2;
  late Animation<Offset> _slideAnimation3;
  late Animation<Offset> _slideAnimation4;
  late Animation<double> _fadeAnimation;
  late Animation<double> _chartAnimation;

  bool _isDataLoaded = false;
  String _debugInfo = ""; // For debugging week range

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Create slide animations with staggered delays
    _slideAnimation1 = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation2 = Tween<Offset>(
      begin: const Offset(-1.0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation3 = Tween<Offset>(
      begin: const Offset(1.0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation4 = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _chartController, curve: Curves.elasticOut),
    );

    loadData();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  // Improved week range calculation - fixed to properly handle weeks
  Map<String, DateTime> _getWeekRange(int year, int month, int week) {
    // Get first day of the month
    DateTime firstDayOfMonth = DateTime(year, month, 1);

    // Find the first Monday of the month (or the first day if it's already Monday)
    int firstWeekday = firstDayOfMonth.weekday; // 1=Monday, 7=Sunday
    DateTime firstMondayOfMonth;

    if (firstWeekday == DateTime.monday) {
      firstMondayOfMonth = firstDayOfMonth;
    } else {
      // Calculate how many days to add to reach the next Monday
      int daysToAdd = DateTime.monday - firstWeekday;
      if (daysToAdd < 0) daysToAdd += 7; // Handle Sunday case
      firstMondayOfMonth = firstDayOfMonth.add(Duration(days: daysToAdd));
    }

    // Calculate start of the selected week (week 1 starts from first Monday)
    DateTime weekStart = firstMondayOfMonth.add(Duration(days: (week - 1) * 7));

    // Make sure weekStart is not before the first day of the month
    if (weekStart.month != month) {
      weekStart = firstDayOfMonth;
    }

    // Calculate end of the week (6 days after start)
    DateTime weekEnd = weekStart.add(Duration(days: 6));

    // Make sure weekEnd doesn't exceed the month boundary
    DateTime lastDayOfMonth = DateTime(year, month + 1, 0);
    if (weekEnd.isAfter(lastDayOfMonth)) {
      weekEnd = DateTime(
        lastDayOfMonth.year,
        lastDayOfMonth.month,
        lastDayOfMonth.day,
        23,
        59,
        59,
      );
    } else {
      weekEnd = DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59);
    }

    return {'start': weekStart, 'end': weekEnd};
  }

  // Helper function to check if date is in selected period
  bool _isDateInSelectedPeriod(DateTime date) {
    switch (selectedPeriod) {
      case PeriodType.weekly:
        Map<String, DateTime> weekRange = _getWeekRange(
          selectedYear,
          selectedMonth,
          selectedWeek,
        );
        DateTime weekStart = weekRange['start']!;
        DateTime weekEnd = weekRange['end']!;

        // Update debug info
        _debugInfo =
            "Week Range: ${weekStart.day}/${weekStart.month} - ${weekEnd.day}/${weekEnd.month}";

        return date.isAfter(weekStart.subtract(Duration(milliseconds: 1))) &&
            date.isBefore(weekEnd.add(Duration(milliseconds: 1)));
      case PeriodType.monthly:
        return date.month == selectedMonth && date.year == selectedYear;
      case PeriodType.yearly:
        return date.year == selectedYear;
    }
  }

  Future<void> loadData() async {
    setState(() => _isDataLoaded = false);

    // Reset animations
    _slideController.reset();
    _chartController.reset();

    // Load ALL data first, then filter
    final data = await DBHelper.getAllTamu();

    await _processDataByPeriod(data);
    _processEmployeeData(data);
    _processInstansiData(data);

    setState(() => _isDataLoaded = true);

    // Debug: Print some info
    print("=== DEBUG INFO ===");
    print("Selected Period: $selectedPeriod");
    print(
      "Selected Year: $selectedYear, Month: $selectedMonth, Week: $selectedWeek",
    );
    print("Total data loaded: ${data.length}");
    print("Data filtered: ${jumlahPerPeriod.fold(0, (a, b) => a + b)}");
    if (selectedPeriod == PeriodType.weekly) {
      print(_debugInfo);
      Map<String, DateTime> weekRange = _getWeekRange(
        selectedYear,
        selectedMonth,
        selectedWeek,
      );
      print(
        "Week range calculated: ${weekRange['start']} to ${weekRange['end']}",
      );

      // Debug: Print actual dates in week range
      DateTime start = weekRange['start']!;
      DateTime end = weekRange['end']!;
      print(
        "Checking data between: ${start.toString().substring(0, 10)} and ${end.toString().substring(0, 10)}",
      );

      // Count matching records for debugging
      int matchingRecords = 0;
      for (var row in data) {
        if (row["tanggal"] != null) {
          try {
            DateTime tgl = DateTime.parse(row["tanggal"]);
            if (tgl.isAfter(start.subtract(Duration(milliseconds: 1))) &&
                tgl.isBefore(end.add(Duration(milliseconds: 1)))) {
              matchingRecords++;
              print(
                "Found matching record: ${row["tanggal"]} - ${row["nama"]}",
              );
            }
          } catch (e) {
            print("Error parsing date: ${row["tanggal"]} - $e");
          }
        }
      }
      print("Total matching records found: $matchingRecords");
    }
    print("==================");

    // Start animations
    _slideController.forward();

    // Start chart animation after a short delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _chartController.forward();
    });
  }

  void _processInstansiData(List<Map<String, dynamic>> data) {
    Map<String, int> countPerInstansi = {};
    for (var row in data) {
      if (row["instansi"] != null && row["instansi"].toString().isNotEmpty) {
        if (row["tanggal"] != null) {
          try {
            DateTime tgl = DateTime.parse(row["tanggal"]);

            if (_isDateInSelectedPeriod(tgl)) {
              String instansi = row["instansi"];
              countPerInstansi[instansi] =
                  (countPerInstansi[instansi] ?? 0) + 1;
            }
          } catch (e) {
            print("Error parsing date: ${row["tanggal"]} - $e");
          }
        }
      }
    }
    jumlahPerInstansi = countPerInstansi;
  }

  Future<void> _processDataByPeriod(List<Map<String, dynamic>> data) async {
    Map<dynamic, int> countPerPeriod = {};

    switch (selectedPeriod) {
      case PeriodType.weekly:
        Map<String, DateTime> weekRange = _getWeekRange(
          selectedYear,
          selectedMonth,
          selectedWeek,
        );
        DateTime weekStart = weekRange['start']!;
        DateTime weekEnd = weekRange['end']!;

        // Initialize counter for 7 days (Mon-Sun)
        for (int i = 0; i < 7; i++) {
          countPerPeriod[i] = 0;
        }

        print("Processing weekly data...");
        print("Week range: $weekStart to $weekEnd");

        int processedCount = 0;
        for (var row in data) {
          if (row["tanggal"] != null) {
            try {
              DateTime tgl = DateTime.parse(row["tanggal"]);

              // Check if date is within the selected week range
              if (tgl.isAfter(weekStart.subtract(Duration(milliseconds: 1))) &&
                  tgl.isBefore(weekEnd.add(Duration(milliseconds: 1)))) {
                int weekdayIndex = tgl.weekday - 1; // 0=Monday, 6=Sunday
                countPerPeriod[weekdayIndex] =
                    (countPerPeriod[weekdayIndex] ?? 0) + 1;
                processedCount++;
                print(
                  "Found data for ${tgl.toString().substring(0, 10)} (weekday: ${tgl.weekday})",
                );
              }
            } catch (e) {
              print("Error parsing date: ${row["tanggal"]} - $e");
            }
          }
        }

        print("Total processed for week: $processedCount");

        jumlahPerPeriod = List.generate(7, (i) => countPerPeriod[i] ?? 0);
        periodLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
        break;

      case PeriodType.monthly:
        int daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
        for (int i = 1; i <= daysInMonth; i++) {
          countPerPeriod[i] = 0;
        }

        for (var row in data) {
          if (row["tanggal"] != null) {
            try {
              DateTime tgl = DateTime.parse(row["tanggal"]);
              if (tgl.month == selectedMonth && tgl.year == selectedYear) {
                int hari = tgl.day;
                countPerPeriod[hari] = (countPerPeriod[hari] ?? 0) + 1;
              }
            } catch (e) {
              print("Error parsing date: ${row["tanggal"]} - $e");
            }
          }
        }

        jumlahPerPeriod = List.generate(
          daysInMonth,
          (i) => countPerPeriod[i + 1] ?? 0,
        );
        periodLabels = List.generate(daysInMonth, (i) => '${i + 1}');
        break;

      case PeriodType.yearly:
        for (int i = 1; i <= 12; i++) {
          countPerPeriod[i] = 0;
        }

        for (var row in data) {
          if (row["tanggal"] != null) {
            try {
              DateTime tgl = DateTime.parse(row["tanggal"]);
              if (tgl.year == selectedYear) {
                int bulan = tgl.month;
                countPerPeriod[bulan] = (countPerPeriod[bulan] ?? 0) + 1;
              }
            } catch (e) {
              print("Error parsing date: ${row["tanggal"]} - $e");
            }
          }
        }

        jumlahPerPeriod = List.generate(12, (i) => countPerPeriod[i + 1] ?? 0);
        periodLabels = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'Mei',
          'Jun',
          'Jul',
          'Agu',
          'Sep',
          'Okt',
          'Nov',
          'Des',
        ];
        break;
    }
  }

  void _processEmployeeData(List<Map<String, dynamic>> data) {
    Map<String, int> countPerPegawai = {};
    for (var row in data) {
      if (row["tanggal"] != null) {
        try {
          DateTime tgl = DateTime.parse(row["tanggal"]);

          if (_isDateInSelectedPeriod(tgl)) {
            String pegawai = row["pegawai_nama"] ?? "Tanpa Pegawai";
            countPerPegawai[pegawai] = (countPerPegawai[pegawai] ?? 0) + 1;
          }
        } catch (e) {
          print("Error parsing date: ${row["tanggal"]} - $e");
        }
      }
    }
    jumlahPerPegawai = countPerPegawai;
  }

  // Get available weeks for the selected month - improved calculation
  int _getMaxWeeksInMonth(int year, int month) {
    DateTime firstDay = DateTime(year, month, 1);
    DateTime lastDay = DateTime(year, month + 1, 0);

    // Find first Monday of the month (or first day if no Monday exists)
    int firstWeekday = firstDay.weekday;
    DateTime firstMondayOfMonth;

    if (firstWeekday == DateTime.monday) {
      firstMondayOfMonth = firstDay;
    } else {
      int daysToAdd = DateTime.monday - firstWeekday;
      if (daysToAdd < 0) daysToAdd += 7;
      firstMondayOfMonth = firstDay.add(Duration(days: daysToAdd));
    }

    // Count how many complete weeks fit from first Monday to end of month
    if (firstMondayOfMonth.month != month) {
      // No complete weeks starting with Monday in this month
      return 1; // At least show 1 week (partial week)
    }

    int daysFromFirstMondayToEndOfMonth =
        lastDay.difference(firstMondayOfMonth).inDays + 1;
    int completeWeeks = (daysFromFirstMondayToEndOfMonth / 7).ceil();

    return completeWeeks > 0 ? completeWeeks : 1;
  }

  Widget _buildAnimatedLineChart() {
    final data = jumlahPerPeriod.map((e) => e.toDouble()).toList();

    if (data.isEmpty) return const Center(child: Text("No data available"));

    final maxY =
        data.isNotEmpty ? data.reduce((a, b) => a > b ? a : b) + 5 : 100;

    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trend Kunjungan Tamu',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Debug info for weekly
              if (selectedPeriod == PeriodType.weekly && _debugInfo.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _debugInfo,
                    style: TextStyle(color: Colors.grey[500], fontSize: 10),
                  ),
                ),
              const SizedBox(height: 16),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 5,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: periodLabels.length > 12 ? 5 : 1,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final index = value.toInt() - 1;
                            if (index >= 0 && index < periodLabels.length) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(
                                  periodLabels[index],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: maxY / 5,
                          reservedSize: 40,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return Text(
                              '${value.toInt()}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 1,
                    maxX: data.length.toDouble(),
                    minY: 0,
                    lineBarsData: [
                      LineChartBarData(
                        spots:
                            data.asMap().entries.map((entry) {
                              return FlSpot(
                                (entry.key + 1).toDouble(),
                                entry.value * _chartAnimation.value,
                              );
                            }).toList(),
                        isCurved: true,
                        color: const Color(0xFF4F46E5),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4 * _chartAnimation.value,
                              color: const Color(0xFF4F46E5),
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(
                            0xFF4F46E5,
                          ).withOpacity(0.1 * _chartAnimation.value),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedBarChart() {
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Distribusi Kunjungan',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ModernBarChart(
                  data:
                      jumlahPerPeriod
                          .map((e) => e.toDouble() * _chartAnimation.value)
                          .toList(),
                  labels: periodLabels,
                  title: '',
                  subtitle: '',
                  showPercentage: false,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedPieChart() {
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Distribusi Tamu per Pegawai',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Increase the height for better visibility
              SizedBox(
                height: 400, // Increased from AspectRatio to fixed height
                child:
                    jumlahPerPegawai.isNotEmpty &&
                            jumlahPerPegawai.values.any((value) => value > 0)
                        ? Transform.scale(
                          scale: _chartAnimation.value,
                          child: Opacity(
                            opacity: _chartAnimation.value,
                            child: ModernPieChart(
                              data: jumlahPerPegawai.map(
                                (key, value) => MapEntry(key, value.toDouble()),
                              ),
                              title: '',
                            ),
                          ),
                        )
                        : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.pie_chart_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tidak ada data untuk ditampilkan',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                selectedPeriod == PeriodType.weekly
                                    ? 'Data minggu ini kosong'
                                    : 'Silakan pilih periode yang berbeda',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Analytics Dashboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          !_isDataLoaded
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Period Selection Card with slide animation
                    SlideTransition(
                      position: _slideAnimation1,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // First Row: Period and Year
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<PeriodType>(
                                      value: selectedPeriod,
                                      decoration: const InputDecoration(
                                        labelText: 'Periode',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: PeriodType.weekly,
                                          child: Text("Minggu"),
                                        ),
                                        DropdownMenuItem(
                                          value: PeriodType.monthly,
                                          child: Text("Bulan"),
                                        ),
                                        DropdownMenuItem(
                                          value: PeriodType.yearly,
                                          child: Text("Tahun"),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            selectedPeriod = val;
                                            // Reset week when changing period
                                            if (val == PeriodType.weekly) {
                                              selectedWeek = 1;
                                            }
                                          });
                                          loadData();
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      value: selectedYear,
                                      decoration: const InputDecoration(
                                        labelText: 'Tahun',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      items: List.generate(5, (i) {
                                        int year = DateTime.now().year - i;
                                        return DropdownMenuItem(
                                          value: year,
                                          child: Text("$year"),
                                        );
                                      }),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => selectedYear = val);
                                          loadData();
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              // Second Row: Month and Week (if applicable)
                              if (selectedPeriod != PeriodType.yearly) ...[
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<int>(
                                        value: selectedMonth,
                                        decoration: const InputDecoration(
                                          labelText: 'Bulan',
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                        items: List.generate(12, (i) {
                                          final monthNames = [
                                            'Jan',
                                            'Feb',
                                            'Mar',
                                            'Apr',
                                            'Mei',
                                            'Jun',
                                            'Jul',
                                            'Agu',
                                            'Sep',
                                            'Okt',
                                            'Nov',
                                            'Des',
                                          ];
                                          return DropdownMenuItem(
                                            value: i + 1,
                                            child: Text(monthNames[i]),
                                          );
                                        }),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              selectedMonth = val;
                                              if (selectedPeriod ==
                                                  PeriodType.weekly) {
                                                selectedWeek = 1;
                                              }
                                            });
                                            loadData();
                                          }
                                        },
                                      ),
                                    ),

                                    if (selectedPeriod ==
                                        PeriodType.weekly) ...[
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: DropdownButtonFormField<int>(
                                          value: selectedWeek,
                                          decoration: const InputDecoration(
                                            labelText: 'Minggu',
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                          ),
                                          items: List.generate(
                                            _getMaxWeeksInMonth(
                                              selectedYear,
                                              selectedMonth,
                                            ),
                                            (i) => DropdownMenuItem(
                                              value: i + 1,
                                              child: Text("Minggu ${i + 1}"),
                                            ),
                                          ),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(
                                                () => selectedWeek = val,
                                              );
                                              loadData();
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SlideTransition(
                            position: _slideAnimation2,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildAnimatedBarChart(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SlideTransition(
                            position: _slideAnimation3,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildAnimatedLineChart(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SlideTransition(
                      position: _slideAnimation4,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildAnimatedPieChart(),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
