import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/producto.dart';
import '../models/gasto_fijo.dart';
import '../models/empleado.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if(_database != null) return _database!;
    _database = await _initDB('calculadora_ganancias.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Incrementamos versión
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        costo_materia_prima REAL NOT NULL,
        costo_mano_obra REAL NOT NULL,
        precio_venta_sugerido REAL NOT NULL,
        ganancia_esperada REAL NOT NULL,
        fecha_creacion TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE gastos_fijos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        concepto TEXT NOT NULL,
        monto REAL NOT NULL,
        frecuencia TEXT NOT NULL,
        fecha_registro TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE empleados (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        sueldo_por_hora REAL NOT NULL,
        eficiencia REAL NOT NULL,
        tipo_contrato TEXT NOT NULL,
        horas_diarias REAL NOT NULL,
        dias_semana REAL NOT NULL,
        activo INTEGER NOT NULL,
        fecha_contratacion TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE empleados (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          sueldo_por_hora REAL NOT NULL,
          eficiencia REAL NOT NULL,
          tipo_contrato TEXT NOT NULL,
          horas_diarias REAL NOT NULL,
          dias_semana REAL NOT NULL,
          activo INTEGER NOT NULL,
          fecha_contratacion TEXT NOT NULL
        )
      ''');
    }
  }

  // CRUD Productos
  Future<int> insertProducto(Producto producto) async {
    final db = await database;
    return await db.insert('productos', producto.toMap());
  }

  Future<List<Producto>> getProductos() async {
    final db = await database;
    final result = await db.query('productos', orderBy: 'fecha_creacion DESC');
    return result.map((json) => Producto.fromMap(json)).toList();
  }

  Future<int> updateProducto(Producto producto) async {
    final db = await database;
    return await db.update(
      'productos',
      producto.toMap(),
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }

  Future<int> deleteProducto(int id) async {
    final db = await database;
    return await db.delete(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD Gastos Fijos
  Future<int> insertGastoFijo(GastoFijo gasto) async {
    final db = await database;
    return await db.insert('gastos_fijos', gasto.toMap());
  }

  Future<List<GastoFijo>> getGastosFijos() async {
    final db = await database;
    final result = await db.query('gastos_fijos', orderBy: 'fecha_registro DESC');
    return result.map((json) => GastoFijo.fromMap(json)).toList();
  }

  Future<int> updateGastoFijo(GastoFijo gasto) async {
    final db = await database;
    return await db.update(
      'gastos_fijos',
      gasto.toMap(),
      where: 'id = ?',
      whereArgs: [gasto.id],
    );
  }

  Future<int> deleteGastoFijo(int id) async {
    final db = await database;
    return await db.delete(
      'gastos_fijos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD Empleados
  Future<int> insertEmpleado(Empleado empleado) async {
    final db = await database;
    return await db.insert('empleados', empleado.toMap());
  }

  Future<List<Empleado>> getEmpleados() async {
    final db = await database;
    final result = await db.query('empleados', orderBy: 'nombre ASC');
    return result.map((json) => Empleado.fromMap(json)).toList();
  }

  Future<List<Empleado>> getEmpleadosActivos() async {
    final db = await database;
    final result = await db.query(
      'empleados',
      where: 'activo = ?',
      whereArgs: [1],
      orderBy: 'nombre ASC',
    );
    return result.map((json) => Empleado.fromMap(json)).toList();
  }

  Future<int> updateEmpleado(Empleado empleado) async {
    final db = await database;
    return await db.update(
      'empleados',
      empleado.toMap(),
      where: 'id = ?',
      whereArgs: [empleado.id],
    );
  }

  Future<int> deleteEmpleado(int id) async {
    final db = await database;
    return await db.delete(
      'empleados',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Cálculos totales
  Future<double> getTotalGastosMensuales() async {
    final gastos = await getGastosFijos();
    return gastos.fold<double>(0.0, (sum, gasto) => sum + gasto.montoMensual);
  }

  Future<double> getTotalSueldosMensuales() async {
    final empleados = await getEmpleadosActivos();
    return empleados.fold<double>(0.0, (sum, emp) => sum + emp.sueldoMensual);
  }

  Future<double> getTotalSueldosSemanales() async {
    final empleados = await getEmpleadosActivos();
    return empleados.fold<double>(0.0, (sum, emp) => sum + emp.sueldoSemanal);
  }

  Future<double> getTotalSueldosDiarios() async {
    final empleados = await getEmpleadosActivos();
    return empleados.fold<double>(0.0, (sum, emp) => sum + emp.sueldoDiario);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}