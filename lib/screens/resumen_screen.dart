import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../models/empleado.dart';
import '../database/database_helper.dart';

class ResumenScreen extends StatefulWidget {
  @override
  _ResumenScreenState createState() => _ResumenScreenState();
}

class _ResumenScreenState extends State<ResumenScreen> {
  bool isLoading = true;
  int totalProductos = 0;
  int totalEmpleados = 0;
  double gastosMensuales = 0;
  double sueldosMensuales = 0;
  double costosTotalesMensuales = 0;
  double promedioGanancia = 0;
  double promedioCosto = 0;
  double promedioPrecioVenta = 0;
  List<Producto> productosTop = [];

  @override
  void initState() {
    super.initState();
    _cargarResumen();
  }

  Future<void> _cargarResumen() async {
    setState(() => isLoading = true);

    final productos = await DatabaseHelper.instance.getProductos();
    final empleados = await DatabaseHelper.instance.getEmpleadosActivos();
    final gastos = await DatabaseHelper.instance.getTotalGastosMensuales();
    final sueldos = await DatabaseHelper.instance.getTotalSueldosMensuales();

    setState(() {
      totalProductos = productos.length;
      totalEmpleados = empleados.length;
      gastosMensuales = gastos;
      sueldosMensuales = sueldos;
      costosTotalesMensuales = gastos + sueldos;

      if (productos.isNotEmpty) {
        promedioGanancia = productos.fold(0.0, (sum, p) => sum + p.gananciaObtenida) / productos.length;
        promedioCosto = productos.fold(0.0, (sum, p) => sum + p.costoTotal) / productos.length;
        promedioPrecioVenta = productos.fold(0.0, (sum, p) => sum + p.precioVentaSugerido) / productos.length;
        
        productosTop = List.from(productos)
          ..sort((a, b) => b.margenGanancia.compareTo(a.margenGanancia))
          ..take(5).toList();
      }

      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resumen'),
        backgroundColor: Colors.purple[700],
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _cargarResumen),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard('Productos', totalProductos.toString(), Colors.blue),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard('Empleados', totalEmpleados.toString(), Colors.teal),
                      ),
                    ],
                  ),

                  SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard('Gastos', '\$${gastosMensuales.toStringAsFixed(0)}', Colors.orange),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard('Sueldos', '\$${sueldosMensuales.toStringAsFixed(0)}', Colors.red),
                      ),
                    ],
                  ),

                  SizedBox(height: 10),

                  _buildStatCard('💵 COSTOS TOTALES/MES', '\$${costosTotalesMensuales.toStringAsFixed(0)}', Colors.purple),

                  SizedBox(height: 30),

                  Text('Indicadores Financieros', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 15),

                  Card(
                    elevation: 3,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildIndicadorRow('Costo Promedio Producto', '\$${promedioCosto.toStringAsFixed(2)}', 
                              Icons.production_quantity_limits, Colors.blue),
                          Divider(),
                          _buildIndicadorRow('Ganancia Promedio', '\$${promedioGanancia.toStringAsFixed(2)}', 
                              Icons.trending_up, Colors.green),
                          Divider(),
                          _buildIndicadorRow('Margen Promedio',
                              promedioCosto > 0 ? '${((promedioGanancia / promedioCosto) * 100).toStringAsFixed(1)}%' : '0%',
                              Icons.percent, Colors.purple),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 30),

                  if (productosTop.isNotEmpty) ...[
                    Text('Productos con Mayor Margen', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 15),
                    ...productosTop.map((producto) => Card(
                          elevation: 2,
                          margin: EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green[100],
                              child: Text('${producto.margenGanancia.toStringAsFixed(0)}%',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green[900])),
                            ),
                            title: Text(producto.nombre, style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Ganancia: \$${producto.gananciaObtenida.toStringAsFixed(2)}'),
                            trailing: Text('\$${producto.precioVentaSugerido.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[700])),
                          ),
                        )),
                  ],

                  SizedBox(height: 30),

                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb, color: Colors.blue[700]),
                              SizedBox(width: 10),
                              Text('Consejos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900])),
                            ],
                          ),
                          SizedBox(height: 10),
                          _buildConsejo('Mantén gastos + sueldos bajo control'),
                          _buildConsejo('Busca productos con margen mayor al 30%'),
                          _buildConsejo('Actualiza costos de materiales regularmente'),
                          _buildConsejo('Optimiza la eficiencia de tus empleados'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      elevation: 4,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 14, color: Colors.white70)),
            SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicadorRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(width: 15),
          Expanded(child: Text(label, style: TextStyle(fontSize: 16))),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildConsejo(String texto) {
    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 16, color: Colors.blue[700])),
          Expanded(child: Text(texto, style: TextStyle(fontSize: 14, color: Colors.blue[900]))),
        ],
      ),
    );
  }
}