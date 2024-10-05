import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper.internal();
  factory DatabaseHelper() => _instance;

  static Database? _db;

  DatabaseHelper.internal();

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  _initDb() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, './database.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  void _onCreate(Database db, int newVersion) async {
    await db.execute('''
        DROP TABLE IF EXISTS notes
    ''');

    await db.execute('''
          CREATE TABLE IF NOT EXISTS notes (
            id INTEGER PRIMARY KEY, 
            title TEXT, 
            content TEXT,
            modification_date TEXT
            )''');
  }

  // CREATE
  Future<int> insertNote(Map<String, dynamic> note) async {
    var dbClient = await db;
    print('note:\n\n');
    print(note);
    print('\n\n:note');
    return await dbClient.insert('notes', note);
  }

  // READ - retorna uma nota se receber um id, caso contrário retornar todas
  Future<List<Map<String, dynamic>>> selectNotes({int id = -1}) async {
    var dbClient = await db;
    if (id == -1) {
      return await dbClient.query('notes');
    } else {
      return await dbClient.query('notes', where: 'id = ?', whereArgs: [id]);
    }
  }

  // UPDATE
  Future<int> updateNote(int id, Map<String, dynamic> note) async {
    var dbClient = await db;
    return await dbClient.update('notes', note, where: 'id = ?', whereArgs: [id]);
  }

  // DELETE
  Future<int> deleteNote(int id) async {
    var dbClient = await db;
    return await dbClient.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // create
  void addNote(Map<String, dynamic> note) async {
    print(note);
    await insertNote(note);
  }

  // read
  Future<List<Map<String, dynamic>>> getNote({int id = -1}) async {
    return await selectNotes(id: id);
  }

  // update
  Future<void> modifyNote(int id, Map<String, dynamic> note) async {
    // print('ATUALIZANDO!');
    // print(note);
    // int noteId = await updateNote(id, note);
    await updateNote(id, note);
    // print('Nota de id $noteId modificada.');
  }

  // delete
  void removeNote(int id) async {
    int noteId = await deleteNote(id);
    print('Nota de id $noteId deletada.');
  }
}
