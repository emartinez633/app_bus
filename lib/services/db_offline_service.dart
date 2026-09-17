import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbOfflineService {
  // Patrón Singleton
  static final DbOfflineService _instance = DbOfflineService._internal();
  factory DbOfflineService() => _instance;
  DbOfflineService._internal();

  Database? _database;

  // Obtiene la instancia de la base de datos (la inicializa si no existe)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // Inicialización de SQLite
  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'smart_transport_offline.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE viajes_pendientes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tag_id TEXT NOT NULL,
            fecha TEXT NOT NULL,
            sincronizado INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  // Guarda un cobro cuando no hay internet
  Future<int> guardarViajeOffline(String tagId) async {
    final db = await database;
    return await db.insert('viajes_pendientes', {
      'tag_id': tagId,
      'fecha': DateTime.now().toIso8601String(),
      'sincronizado': 0
    });
  }

  // Obtiene todos los viajes que no se han enviado al backend
  Future<List<Map<String, dynamic>>> obtenerViajesPendientes() async {
    final db = await database;
    return await db.query(
      'viajes_pendientes',
      where: 'sincronizado = ?',
      whereArgs: [0],
    );
  }

  // Elimina un viaje de la base de datos local tras enviarlo exitosamente
  Future<void> eliminarViajeSincronizado(int id) async {
    final db = await database;
    await db.delete(
      'viajes_pendientes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}