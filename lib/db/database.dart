import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> init() async {
    if (_db != null) return _db!;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    var dbPath = await databaseFactory.getDatabasesPath();
    String path = join(dbPath, "buku_tamu.db");

    _db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 7, // Update version dari 6 ke 7
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE pegawai (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nama TEXT,
              nip TEXT,
              jabatan TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE tamu (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nama TEXT,
              instansi TEXT,
              keperluan TEXT,
              telepon TEXT,
              tanggal TEXT,
              pegawai_id INTEGER,
              FOREIGN KEY (pegawai_id) REFERENCES pegawai(id)
            )
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('ALTER TABLE tamu ADD COLUMN tanggal TEXT');
          }
          if (oldVersion < 3) {
            await db.execute('ALTER TABLE tamu ADD COLUMN pegawai_id INTEGER');
          }
          if (oldVersion < 4) {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS pegawai (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nama TEXT
              )
            ''');
          }
          if (oldVersion < 5) {
            await db.execute('ALTER TABLE tamu ADD COLUMN pegawai_id INTEGER');
          }
          // Tambahan untuk menambahkan kolom nip dan jabatan
          if (oldVersion < 7) {
            // Cek apakah kolom nip sudah ada
            var columns = await db.rawQuery('PRAGMA table_info(pegawai)');
            bool hasNip = columns.any((col) => col['name'] == 'nip');
            bool hasJabatan = columns.any((col) => col['name'] == 'jabatan');

            if (!hasNip) {
              await db.execute('ALTER TABLE pegawai ADD COLUMN nip TEXT');
            }
            if (!hasJabatan) {
              await db.execute('ALTER TABLE pegawai ADD COLUMN jabatan TEXT');
            }
          }
        },
      ),
    );
    return _db!;
  }

  // BAGIAN TAMU

  static Future<int> insertTamu(Map<String, dynamic> data) async {
    final db = await init();
    data["tanggal"] ??= DateTime.now().toIso8601String().substring(0, 10);
    return await db.insert("tamu", data);
  }

  static Future<int> deleteTamu(int id) async {
    final db = await init();
    return await db.delete("tamu", where: "id = ?", whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> getAllTamu({
    int? month,
    int? year,
  }) async {
    final db = await init();

    String baseQuery = '''
      SELECT t.id, t.nama, t.instansi, t.keperluan, t.telepon, t.tanggal,
             t.pegawai_id,
             COALESCE(p.nama, 'Tanpa Pegawai') AS pegawai_nama
      FROM tamu t
      LEFT JOIN pegawai p ON t.pegawai_id = p.id
    ''';

    if (month != null && month > 0 && year != null && year > 0) {
      String bulan = month.toString().padLeft(2, '0');
      String tahun = year.toString();
      return await db.rawQuery(
        '$baseQuery WHERE substr(t.tanggal, 6, 2) = ? AND substr(t.tanggal, 1, 4) = ? ORDER BY t.tanggal DESC, t.id DESC',
        [bulan, tahun],
      );
    } else if (month != null && month > 0) {
      String bulan = month.toString().padLeft(2, '0');
      return await db.rawQuery(
        '$baseQuery WHERE substr(t.tanggal, 6, 2) = ? ORDER BY t.tanggal DESC, t.id DESC',
        [bulan],
      );
    } else {
      return await db.rawQuery('$baseQuery ORDER BY t.tanggal DESC, t.id DESC');
    }
  }

  static Future<Map<int, int>> getStatistikPerHari({
    required int month,
    required int year,
  }) async {
    final db = await init();
    String bulan = month.toString().padLeft(2, '0');
    String tahun = year.toString();

    final result = await db.rawQuery(
      '''
      SELECT substr(tanggal, 9, 2) AS hari, COUNT(*) AS total
      FROM tamu
      WHERE substr(tanggal, 6, 2) = ? AND substr(tanggal, 1, 4) = ?
      GROUP BY hari
      ORDER BY hari ASC
    ''',
      [bulan, tahun],
    );

    Map<int, int> data = {};
    for (var row in result) {
      int hari = int.parse(row['hari'] as String);
      int total = row['total'] as int;
      data[hari] = total;
    }
    return data;
  }

  static Future<Map<String, dynamic>> getStatistikTamuPerPegawaiDetailed({
    int? month,
    int? year,
  }) async {
    final db = await init();
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (month != null && month > 0 && year != null && year > 0) {
      String bulan = month.toString().padLeft(2, '0');
      String tahun = year.toString();
      whereClause =
          'WHERE substr(t.tanggal, 6, 2) = ? AND substr(t.tanggal, 1, 4) = ?';
      whereArgs = [bulan, tahun];
    } else if (month != null && month > 0) {
      String bulan = month.toString().padLeft(2, '0');
      whereClause = 'WHERE substr(t.tanggal, 6, 2) = ?';
      whereArgs = [bulan];
    }

    final result = await db.rawQuery('''
      SELECT 
        t.pegawai_id,
        COALESCE(p.nama, 'Tanpa Pegawai') AS pegawai_nama, 
        COUNT(*) AS total_tamu,
        COUNT(DISTINCT t.instansi) AS jumlah_instansi,
        MIN(t.tanggal) AS tanggal_pertama,
        MAX(t.tanggal) AS tanggal_terakhir
      FROM tamu t
      LEFT JOIN pegawai p ON t.pegawai_id = p.id
      $whereClause
      GROUP BY t.pegawai_id, p.nama
      ORDER BY total_tamu DESC, p.nama ASC
    ''', whereArgs);

    final instansiResult = await db.rawQuery('''
      SELECT 
        t.pegawai_id,
        COALESCE(p.nama, 'Tanpa Pegawai') AS pegawai_nama,
        GROUP_CONCAT(DISTINCT COALESCE(NULLIF(t.instansi, ''), 'Tanpa Instansi')) AS instansi_list
      FROM tamu t
      LEFT JOIN pegawai p ON t.pegawai_id = p.id
      $whereClause
      GROUP BY t.pegawai_id, p.nama
      ORDER BY COUNT(*) DESC
    ''', whereArgs);

    Map<String, double> basicData = {};
    List<Map<String, dynamic>> detailedStats = [];
    Map<String, String> pegawaiInstansi = {};

    for (var row in instansiResult) {
      String pegawaiNama = row['pegawai_nama'] as String;
      String instansiList = row['instansi_list'] as String? ?? '';
      pegawaiInstansi[pegawaiNama] = instansiList;
    }

    for (var row in result) {
      String pegawaiNama = row['pegawai_nama'] as String;
      int totalTamu = row['total_tamu'] as int;
      int jumlahInstansi = row['jumlah_instansi'] as int;
      String tanggalPertama = row['tanggal_pertama'] as String? ?? '';
      String tanggalTerakhir = row['tanggal_terakhir'] as String? ?? '';

      basicData[pegawaiNama] = totalTamu.toDouble();

      detailedStats.add({
        'pegawai_id': row['pegawai_id'],
        'nama': pegawaiNama,
        'total_tamu': totalTamu,
        'jumlah_instansi': jumlahInstansi,
        'tanggal_pertama': tanggalPertama,
        'tanggal_terakhir': tanggalTerakhir,
        'instansi_dilayani': pegawaiInstansi[pegawaiNama]?.split(',') ?? [],
      });
    }

    return {
      'basic_data': basicData,
      'detailed_stats': detailedStats,
      'total_pegawai_aktif': detailedStats.length,
      'total_tamu_keseluruhan': detailedStats.fold(
        0,
        (sum, item) => sum + (item['total_tamu'] as int),
      ),
    };
  }

  static Future<Map<String, double>> getStatistikTamuPerPegawai({
    int? month,
    int? year,
  }) async {
    final detailed = await getStatistikTamuPerPegawaiDetailed(
      month: month,
      year: year,
    );
    return detailed['basic_data'] as Map<String, double>;
  }

  static Future<Map<String, double>> getStatistikTamuPerInstansi({
    int? month,
    int? year,
  }) async {
    final db = await init();
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (month != null && month > 0 && year != null && year > 0) {
      String bulan = month.toString().padLeft(2, '0');
      String tahun = year.toString();
      whereClause =
          'WHERE substr(tanggal, 6, 2) = ? AND substr(tanggal, 1, 4) = ?';
      whereArgs = [bulan, tahun];
    } else if (month != null && month > 0) {
      String bulan = month.toString().padLeft(2, '0');
      whereClause = 'WHERE substr(tanggal, 6, 2) = ?';
      whereArgs = [bulan];
    }

    final result = await db.rawQuery('''
      SELECT 
        COALESCE(NULLIF(instansi, ''), 'Instansi Lainnya') AS instansi_nama, 
        COUNT(*) AS total
      FROM tamu
      $whereClause
      GROUP BY instansi
      ORDER BY total DESC
    ''', whereArgs);

    Map<String, double> data = {};
    for (var row in result) {
      String instansiNama = row['instansi_nama'] as String;
      int total = row['total'] as int;
      data[instansiNama] = total.toDouble();
    }
    return data;
  }

  // BAGIAN PEGAWAI

  static Future<int> insertPegawai(Map<String, dynamic> data) async {
    final db = await init();
    return await db.insert("pegawai", data);
  }

  static Future<List<Map<String, dynamic>>> getAllPegawai() async {
    final db = await init();
    return await db.query("pegawai", orderBy: "nama ASC");
  }

  static Future<int> deletePegawai(int id) async {
    final db = await init();
    await db.update(
      "tamu",
      {"pegawai_id": null},
      where: "pegawai_id = ?",
      whereArgs: [id],
    );
    return await db.delete("pegawai", where: "id = ?", whereArgs: [id]);
  }

  static Future<int> updatePegawai(int id, Map<String, dynamic> data) async {
    final db = await init();
    return await db.update("pegawai", data, where: "id = ?", whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> searchPegawai(String nama) async {
    final db = await init();
    return await db.query(
      "pegawai",
      where: "nama LIKE ?",
      whereArgs: ["%$nama%"],
      orderBy: "nama ASC",
    );
  }
}
