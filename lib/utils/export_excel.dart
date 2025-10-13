import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import '../db/database.dart';

class ExportExcel {
  static Future<String> export({int? month}) async {
    final tamuList = await DBHelper.getAllTamu(month: month);

    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];

    // Mendapatkan nama bulan dan tahun
    final now = DateTime.now();
    final currentMonth = month ?? now.month;
    final currentYear = now.year;
    final monthName = DateFormat(
      'MMMM',
      'id_ID',
    ).format(DateTime(currentYear, currentMonth));

    // Baris 1: Judul laporan dengan bulan dan tahun
    sheet.getRangeByName('A1:F1').merge();
    sheet
        .getRangeByName('A1')
        .setText("LAPORAN TAMU PENMAD BULAN $monthName $currentYear");
    sheet.getRangeByName('A1').cellStyle.bold = true;
    sheet.getRangeByName('A1').cellStyle.fontSize = 14;
    sheet.getRangeByName('A1').cellStyle.hAlign = xlsio.HAlignType.center;

    // Baris 2: Rekap data
    sheet.getRangeByName('A2:F2').merge();
    sheet.getRangeByName('A2').setText("REKAP DATA APLIKASI BUKU TAMU DIGITAL");
    sheet.getRangeByName('A2').cellStyle.bold = true;
    sheet.getRangeByName('A2').cellStyle.hAlign = xlsio.HAlignType.center;

    // Baris 3: Nama kantor
    sheet.getRangeByName('A3:F3').merge();
    sheet
        .getRangeByName('A3')
        .setText("KANTOR KEMENTERIAN AGAMA KOTA TASIKMALAYA");
    sheet.getRangeByName('A3').cellStyle.bold = true;
    sheet.getRangeByName('A3').cellStyle.hAlign = xlsio.HAlignType.center;

    // Baris 4: Spasi
    sheet.getRangeByName('A4:F4').merge();

    // Baris 5: Header tabel
    final headers = [
      "ID",
      "Nama",
      "Instansi",
      "Keperluan",
      "Telepon",
      "Tanggal",
    ];
    for (int i = 0; i < headers.length; i++) {
      sheet.getRangeByIndex(5, i + 1).setText(headers[i]);
      sheet.getRangeByIndex(5, i + 1).cellStyle.bold = true;
      sheet.getRangeByIndex(5, i + 1).cellStyle.backColor = '#D3D3D3';
      sheet.getRangeByIndex(5, i + 1).cellStyle.hAlign =
          xlsio.HAlignType.center;
    }

    // Data mulai dari baris 6
    int rowIndex = 6;
    for (var tamu in tamuList) {
      sheet
          .getRangeByIndex(rowIndex, 1)
          .setNumber((tamu["id"] ?? 0).toDouble());
      sheet.getRangeByIndex(rowIndex, 2).setText(tamu["nama"] ?? "");
      sheet.getRangeByIndex(rowIndex, 3).setText(tamu["instansi"] ?? "");
      sheet.getRangeByIndex(rowIndex, 4).setText(tamu["keperluan"] ?? "");
      sheet.getRangeByIndex(rowIndex, 5).setText(tamu["telepon"] ?? "");
      sheet.getRangeByIndex(rowIndex, 6).setText(tamu["tanggal"] ?? "");
      rowIndex++;
    }

    // Auto-fit kolom
    sheet.autoFitColumn(1);
    sheet.autoFitColumn(2);
    sheet.autoFitColumn(3);
    sheet.autoFitColumn(4);
    sheet.autoFitColumn(5);
    sheet.autoFitColumn(6);

    // Simpan file
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    String formattedDate = DateFormat('yyyyMMdd_HHmm').format(now);
    String monthSuffix =
        month != null ? "_bulan${month.toString().padLeft(2, '0')}" : "";

    final dir = await getApplicationDocumentsDirectory();
    final filePath = "${dir.path}/tamu$monthSuffix\_$formattedDate.xlsx";

    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    return filePath;
  }
}
