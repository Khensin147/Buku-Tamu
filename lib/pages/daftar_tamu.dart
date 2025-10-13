import 'package:buku_tamu_penmad/utils/grafik.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../db/database.dart';
import 'pegawai.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  int selectedIndex = 0;
  List<Map<String, dynamic>> _tamu = [];
  List<Map<String, dynamic>> _pegawai = [];
  String _selectedMonth = 'All';
  String _selectedYear = 'All';
  String _searchQuery = '';

  // Untuk checkbox selection
  Set<int> _selectedIds = {};
  bool _selectAll = false;

  // Animation Controllers
  late AnimationController _sidebarController;
  late AnimationController _contentController;
  late AnimationController _cardsController;
  late AnimationController _tableController;

  // Animations
  late Animation<Offset> _sidebarSlideAnimation;
  late Animation<double> _sidebarFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<double> _cardsScaleAnimation;
  late Animation<double> _cardsFadeAnimation;
  late Animation<double> _tableAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadData();
    _startAnimations();
  }

  void _setupAnimations() {
    _sidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _tableController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _sidebarSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _sidebarController, curve: Curves.easeOutBack),
    );

    _sidebarFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sidebarController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutQuart),
    );

    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _cardsScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _cardsController, curve: Curves.elasticOut),
    );

    _cardsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardsController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _tableAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tableController, curve: Curves.easeOutQuart),
    );
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _sidebarController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _contentController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _cardsController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    _tableController.forward();
  }

  void _loadData() async {
    final dataTamu = await DBHelper.getAllTamu();
    final dataPegawai = await DBHelper.getAllPegawai();
    setState(() {
      _tamu = dataTamu;
      _pegawai = dataPegawai;
      _selectedIds.clear();
      _selectAll = false;
    });
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        _selectedIds = _filteredTamu.map((t) => t['id'] as int).toSet();
      } else {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        _selectAll = false;
      } else {
        _selectedIds.add(id);
        if (_selectedIds.length == _filteredTamu.length) {
          _selectAll = true;
        }
      }
    });
  }

  Future<void> _deleteSelectedTamu() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih data yang ingin dihapus")),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text('Konfirmasi Hapus'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apakah Anda yakin ingin menghapus ${_selectedIds.length} data tamu?',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'Data yang dihapus tidak dapat dikembalikan.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        for (int id in _selectedIds) {
          await DBHelper.deleteTamu(id);
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(20),
            backgroundColor: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "${_selectedIds.length} data tamu berhasil dihapus!",
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        _loadData();
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            content: Text("Gagal menghapus data: $e"),
          ),
        );
      }
    }
  }

  Future<void> _deleteTamu(int id, String nama) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text('Konfirmasi Hapus'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Apakah Anda yakin ingin menghapus data tamu ini?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        nama,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Data yang dihapus tidak dapat dikembalikan.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await DBHelper.deleteTamu(id);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(20),
            backgroundColor: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Data tamu berhasil dihapus!",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        _loadData();
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            content: Text("Gagal menghapus data: $e"),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _sidebarController.dispose();
    _contentController.dispose();
    _cardsController.dispose();
    _tableController.dispose();
    super.dispose();
  }

  List<String> get _availableYears {
    final years =
        _tamu
            .map((t) {
              try {
                return DateFormat(
                  'yyyy-MM-dd',
                ).parse(t['tanggal']).year.toString();
              } catch (e) {
                return null;
              }
            })
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();
    return years;
  }

  int get _tamuHariIni {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _tamu.where((t) => t['tanggal'] == today).length;
  }

  int get _tamuMingguIni {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return _tamu.where((t) {
      try {
        final date = DateFormat('yyyy-MM-dd').parse(t['tanggal']);
        return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            date.isBefore(endOfWeek.add(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).length;
  }

  int get _tamuBulanIni {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    return _tamu.where((t) {
      try {
        final date = DateFormat('yyyy-MM-dd').parse(t['tanggal']);
        return date.month == currentMonth && date.year == currentYear;
      } catch (e) {
        return false;
      }
    }).length;
  }

  Widget _buildAnimatedSummaryCard(
    String title,
    int count,
    IconData icon,
    Color color,
    double delay,
  ) {
    return Expanded(
      child: AnimatedBuilder(
        animation: _cardsController,
        builder: (context, child) {
          final delayedAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: _cardsController,
              curve: Interval(delay, delay + 0.4, curve: Curves.elasticOut),
            ),
          );

          return Transform.scale(
            scale: delayedAnimation.value,
            child: Opacity(
              opacity: _cardsFadeAnimation.value,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: Duration(
                          milliseconds: (800 + delay * 200).round(),
                        ),
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.rotate(
                            angle: (1 - value) * 0.5,
                            child: Icon(icon, size: 32, color: color),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TweenAnimationBuilder<int>(
                        duration: Duration(
                          milliseconds: (1000 + delay * 300).round(),
                        ),
                        tween: IntTween(begin: 0, end: count),
                        builder: (context, value, child) {
                          return Text(
                            "$value",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _exportExcel() async {
    final exportData = _filteredTamu;
    if (exportData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada data untuk diexport")),
      );
      return;
    }
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Tamu'];
    excel.setDefaultSheet('Tamu');
    sheetObject.appendRow([
      TextCellValue("Nama"),
      TextCellValue("Instansi"),
      TextCellValue("Keperluan"),
      TextCellValue("Telepon"),
      TextCellValue("Tanggal"),
      TextCellValue("Pegawai"),
    ]);
    for (var tamu in exportData) {
      sheetObject.appendRow([
        TextCellValue(tamu["nama"] ?? ""),
        TextCellValue(tamu["instansi"] ?? ""),
        TextCellValue(tamu["keperluan"] ?? ""),
        TextCellValue(tamu["telepon"] ?? ""),
        TextCellValue(tamu["tanggal"] ?? ""),
        TextCellValue(tamu["pegawai_nama"] ?? "-"),
      ]);
    }
    final now = DateTime.now();
    String formattedDate = DateFormat('yyyyMMdd_HHmm').format(now);
    String monthSuffix = _selectedMonth != 'All' ? "_bulan$_selectedMonth" : "";
    String yearSuffix = _selectedYear != 'All' ? "_tahun$_selectedYear" : "";
    final dir = await getApplicationDocumentsDirectory();
    String filePath =
        "${dir.path}/tamu$yearSuffix$monthSuffix\_$formattedDate.xlsx";
    var fileBytes = excel.encode();
    if (fileBytes != null) {
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Data berhasil diexport ke:\n$filePath")),
    );
  }

  String _formatDate(String dateString) {
    try {
      DateTime date = DateFormat('yyyy-MM-dd').parse(dateString);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      return dateString;
    }
  }

  List<Map<String, dynamic>> get _filteredTamu {
    return _tamu.where((t) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          (t['nama']?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false) ||
          (t['instansi']?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false) ||
          (t['keperluan']?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false) ||
          (t['telepon']?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
              false) ||
          (t['pegawai_nama']?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);
      try {
        final date = DateFormat('yyyy-MM-dd').parse(t['tanggal']);
        final bulan = date.month.toString().padLeft(2, '0');
        final tahun = date.year.toString();
        final matchBulan = _selectedMonth == 'All' || bulan == _selectedMonth;
        final matchTahun = _selectedYear == 'All' || tahun == _selectedYear;
        return matchesSearch && matchBulan && matchTahun;
      } catch (e) {
        return matchesSearch;
      }
    }).toList();
  }

  Widget _buildAnimatedMenuItem({
    required IconData icon,
    required String title,
    required int index,
    required VoidCallback onTap,
    double delay = 0.0,
  }) {
    return AnimatedBuilder(
      animation: _sidebarController,
      builder: (context, child) {
        final delayedAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _sidebarController,
            curve: Interval(delay, delay + 0.3, curve: Curves.easeOutBack),
          ),
        );

        return Transform.translate(
          offset: Offset((1 - delayedAnimation.value) * -50, 0),
          child: Opacity(
            opacity: delayedAnimation.value,
            child: ListTile(
              leading: Icon(
                icon,
                color: selectedIndex == index ? Colors.blue : Colors.black,
              ),
              title: Text(
                title,
                style: TextStyle(
                  color: selectedIndex == index ? Colors.blue : Colors.black,
                ),
              ),
              onTap: onTap,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomePage() {
    return SlideTransition(
      position: _contentSlideAnimation,
      child: FadeTransition(
        opacity: _contentFadeAnimation,
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _contentController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - _contentFadeAnimation.value) * 30),
                  child: Opacity(
                    opacity: _contentFadeAnimation.value,
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                TweenAnimationBuilder<int>(
                                  duration: const Duration(milliseconds: 1500),
                                  tween: IntTween(
                                    begin: 0,
                                    end: _filteredTamu.length,
                                  ),
                                  builder: (context, value, child) {
                                    return Text(
                                      "$value",
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                                const Text(
                                  "tamu",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey[300],
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                TweenAnimationBuilder<int>(
                                  duration: const Duration(milliseconds: 1500),
                                  tween: IntTween(
                                    begin: 0,
                                    end: _pegawai.length,
                                  ),
                                  builder: (context, value, child) {
                                    return Text(
                                      "$value",
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                                const Text(
                                  "pegawai",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  _buildAnimatedSummaryCard(
                    "Hari Ini",
                    _tamuHariIni,
                    Icons.today,
                    Colors.green,
                    0.0,
                  ),
                  const SizedBox(width: 12),
                  _buildAnimatedSummaryCard(
                    "Minggu Ini",
                    _tamuMingguIni,
                    Icons.date_range,
                    Colors.orange,
                    0.1,
                  ),
                  const SizedBox(width: 12),
                  _buildAnimatedSummaryCard(
                    "Bulan Ini",
                    _tamuBulanIni,
                    Icons.calendar_month,
                    Colors.blue,
                    0.2,
                  ),
                ],
              ),
            ),

            AnimatedBuilder(
              animation: _contentController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - _contentFadeAnimation.value) * 20),
                  child: Opacity(
                    opacity: _contentFadeAnimation.value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: "Search",
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged:
                                  (val) => setState(() => _searchQuery = val),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_selectedIds.isNotEmpty)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              onPressed: _deleteSelectedTamu,
                              icon: const Icon(Icons.delete),
                              label: Text("HAPUS (${_selectedIds.length})"),
                            ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            onPressed: _exportExcel,
                            icon: const Icon(Icons.file_download_outlined),
                            label: const Text("EXPORT"),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            AnimatedBuilder(
              animation: _contentController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - _contentFadeAnimation.value) * 15),
                  child: Opacity(
                    opacity: _contentFadeAnimation.value,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 24,
                        top: 8,
                        right: 24,
                      ),
                      child: Row(
                        children: [
                          DropdownButton<String>(
                            value: _selectedMonth,
                            items: const [
                              DropdownMenuItem(
                                value: 'All',
                                child: Text('All Bulan'),
                              ),
                              DropdownMenuItem(
                                value: '01',
                                child: Text('Januari'),
                              ),
                              DropdownMenuItem(
                                value: '02',
                                child: Text('Februari'),
                              ),
                              DropdownMenuItem(
                                value: '03',
                                child: Text('Maret'),
                              ),
                              DropdownMenuItem(
                                value: '04',
                                child: Text('April'),
                              ),
                              DropdownMenuItem(value: '05', child: Text('Mei')),
                              DropdownMenuItem(
                                value: '06',
                                child: Text('Juni'),
                              ),
                              DropdownMenuItem(
                                value: '07',
                                child: Text('Juli'),
                              ),
                              DropdownMenuItem(
                                value: '08',
                                child: Text('Agustus'),
                              ),
                              DropdownMenuItem(
                                value: '09',
                                child: Text('September'),
                              ),
                              DropdownMenuItem(
                                value: '10',
                                child: Text('Oktober'),
                              ),
                              DropdownMenuItem(
                                value: '11',
                                child: Text('November'),
                              ),
                              DropdownMenuItem(
                                value: '12',
                                child: Text('Desember'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null)
                                setState(() {
                                  _selectedMonth = val;
                                  _selectedIds.clear();
                                  _selectAll = false;
                                });
                            },
                          ),
                          const SizedBox(width: 16),
                          DropdownButton<String>(
                            value: _selectedYear,
                            items: [
                              const DropdownMenuItem(
                                value: 'All',
                                child: Text('All Tahun'),
                              ),
                              ..._availableYears.map(
                                (y) =>
                                    DropdownMenuItem(value: y, child: Text(y)),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null)
                                setState(() {
                                  _selectedYear = val;
                                  _selectedIds.clear();
                                  _selectAll = false;
                                });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            Expanded(
              child: AnimatedBuilder(
                animation: _tableController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - _tableAnimation.value) * 30),
                    child: Opacity(
                      opacity: _tableAnimation.value,
                      child:
                          _filteredTamu.isEmpty
                              ? const Center(
                                child: Text(
                                  "Belum ada data tamu",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                              : Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth:
                                              MediaQuery.of(
                                                context,
                                              ).size.width -
                                              268,
                                        ),
                                        child: DataTable(
                                          columnSpacing: 20,
                                          headingRowColor:
                                              MaterialStateColor.resolveWith(
                                                (states) => Colors.grey[50]!,
                                              ),
                                          dataRowMinHeight: 48,
                                          dataRowMaxHeight: 60,
                                          columns: [
                                            DataColumn(
                                              label: Checkbox(
                                                value: _selectAll,
                                                onChanged: _toggleSelectAll,
                                              ),
                                            ),
                                            const DataColumn(
                                              label: Text(
                                                "No",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const DataColumn(
                                              label: Text(
                                                "Nama",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const DataColumn(
                                              label: Text(
                                                "Instansi",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const DataColumn(
                                              label: Text(
                                                "Keperluan",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const DataColumn(
                                              label: Text(
                                                "Telephone",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const DataColumn(
                                              label: Text(
                                                "Tanggal",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const DataColumn(
                                              label: Text(
                                                "Pegawai",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const DataColumn(
                                              label: Text(
                                                "Aksi",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                          rows: List.generate(
                                            _filteredTamu.length,
                                            (i) {
                                              final t = _filteredTamu[i];
                                              final id = t['id'] as int;
                                              final isSelected = _selectedIds
                                                  .contains(id);

                                              return DataRow(
                                                selected: isSelected,
                                                color:
                                                    MaterialStateProperty.resolveWith<
                                                      Color?
                                                    >((
                                                      Set<MaterialState> states,
                                                    ) {
                                                      if (isSelected) {
                                                        return Colors.blue
                                                            .withOpacity(0.1);
                                                      }
                                                      return null;
                                                    }),
                                                cells: [
                                                  DataCell(
                                                    Checkbox(
                                                      value: isSelected,
                                                      onChanged:
                                                          (value) =>
                                                              _toggleSelection(
                                                                id,
                                                              ),
                                                    ),
                                                  ),
                                                  DataCell(Text("${i + 1}")),
                                                  DataCell(
                                                    Text(t['nama'] ?? ''),
                                                  ),
                                                  DataCell(
                                                    Text(t['instansi'] ?? ''),
                                                  ),
                                                  DataCell(
                                                    Text(t['keperluan'] ?? ''),
                                                  ),
                                                  DataCell(
                                                    Text(t['telepon'] ?? ''),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      _formatDate(
                                                        t['tanggal'] ?? '',
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      t['pegawai_nama'] ?? '-',
                                                    ),
                                                  ),
                                                  DataCell(
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                      ),
                                                      tooltip: 'Hapus',
                                                      onPressed:
                                                          () => _deleteTamu(
                                                            id,
                                                            t['nama'] ?? 'Tamu',
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrafikPage() {
    return SlideTransition(
      position: _contentSlideAnimation,
      child: FadeTransition(
        opacity: _contentFadeAnimation,
        child: const Center(
          child: Text(
            "Halaman Grafik (belum ada grafik)",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SlideTransition(
            position: _sidebarSlideAnimation,
            child: FadeTransition(
              opacity: _sidebarFadeAnimation,
              child: Container(
                width: 220,
                color: const Color(0xFFF4F4F5),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedBuilder(
                        animation: _sidebarController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _sidebarFadeAnimation.value,
                            child: Opacity(
                              opacity: _sidebarFadeAnimation.value,
                              child: const Padding(
                                padding: EdgeInsets.all(20),
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.grey,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      AnimatedBuilder(
                        animation: _sidebarController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              (1 - _sidebarFadeAnimation.value) * -30,
                              0,
                            ),
                            child: Opacity(
                              opacity: _sidebarFadeAnimation.value,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  "ADMIN",
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 30),

                      _buildAnimatedMenuItem(
                        icon: Icons.home,
                        title: "HOME",
                        index: 0,
                        onTap: () => setState(() => selectedIndex = 0),
                        delay: 0.1,
                      ),
                      _buildAnimatedMenuItem(
                        icon: Icons.people,
                        title: "Pegawai",
                        index: 1,
                        onTap: () => setState(() => selectedIndex = 1),
                        delay: 0.2,
                      ),
                      _buildAnimatedMenuItem(
                        icon: Icons.bar_chart,
                        title: "Grafik",
                        index: 2,
                        onTap: () => setState(() => selectedIndex = 2),
                        delay: 0.3,
                      ),

                      const Spacer(),

                      _buildAnimatedMenuItem(
                        icon: Icons.logout,
                        title: "KELUAR",
                        index: -1,
                        onTap: () => Navigator.pop(context),
                        delay: 0.4,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: IndexedStack(
              index: selectedIndex,
              children: [
                _buildHomePage(),
                const PegawaiPage(),
                const GrafikPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
