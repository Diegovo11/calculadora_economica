import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../database/database_helper.dart';

class MixProductosScreen extends StatefulWidget {
  @override
  _MixProductosScreenState createState() => _MixProductosScreenState();
}

class _MixProductosScreenState extends State<MixProductosScreen> {
  List<Producto> _productos = [];
  Map<int, TextEditingController> _cantidadesControllers = {};
  
  double _costosFijosMensual = 0;
  double _contribucionTotal = 0;
  double _gananciaNetaMensual = 0;
  bool _esRentable = false;
  
  String _periodoSeleccionado = 'Mensual'; // 'Semanal' o 'Mensual'
  
  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final productos = await DatabaseHelper.instance.getProductos();
    final gastosMes = await DatabaseHelper.instance.getTotalGastosMensuales();
    final sueldosMes = await DatabaseHelper.instance.getTotalSueldosMensuales();
    
    setState(() {
      _productos = productos;
      _costosFijosMensual = gastosMes + sueldosMes;
      
      // Crear controladores para cantidades
      _cantidadesControllers.clear();
      for (var producto in productos) {
        _cantidadesControllers[producto.id!] = TextEditingController();
      }
    });
  }

  void _calcularRentabilidad() {
    setState(() {
      _contribucionTotal = 0;
      
      for (var producto in _productos) {
        final controller = _cantidadesControllers[producto.id];
        if (controller != null && controller.text.isNotEmpty) {
          int cantidad = int.tryParse(controller.text) ?? 0;
          
          // Contribución = (Precio - Costo SOLO Material) × Cantidad
          double gananciaUnitaria = producto.precioVentaSugerido - producto.costoSoloMaterial;
          double contribucion = gananciaUnitaria * cantidad;
          
          _contribucionTotal += contribucion;
        }
      }
      
      // Costos fijos según período
      double costosFijosPeriodo = _periodoSeleccionado == 'Semanal' 
          ? _costosFijosMensual / 4.33 
          : _costosFijosMensual;
      
      // Ganancia neta = Contribución total - Costos fijos
      _gananciaNetaMensual = _contribucionTotal - costosFijosPeriodo;
      _esRentable = _gananciaNetaMensual >= 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ordenar productos por margen de ganancia (mayor a menor)
    List<Producto> productosOrdenados = List.from(_productos);
    productosOrdenados.sort((a, b) => b.margenGanancia.compareTo(a.margenGanancia));
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Mix de Productos'),
        backgroundColor: Colors.purple,
      ),
      body: _productos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text('No hay productos guardados',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  SizedBox(height: 10),
                  Text('Usa la calculadora para crear productos',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                // Selector de período
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Período de análisis:', 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(width: 15),
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                            value: 'Semanal',
                            label: Text('Semanal'),
                            icon: Icon(Icons.calendar_view_week, size: 18),
                          ),
                          ButtonSegment(
                            value: 'Mensual',
                            label: Text('Mensual'),
                            icon: Icon(Icons.calendar_month, size: 18),
                          ),
                        ],
                        selected: {_periodoSeleccionado},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _periodoSeleccionado = newSelection.first;
                            _calcularRentabilidad();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                
                // Resumen de rentabilidad
                Container(
                  padding: EdgeInsets.all(20),
                  color: _esRentable ? Colors.green[50] : Colors.red[50],
                  child: Column(
                    children: [
                      Text(
                        _esRentable ? 'NEGOCIO RENTABLE' : 'NO RENTABLE',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _esRentable ? Colors.green[900] : Colors.red[900],
                        ),
                      ),
                      SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildIndicador(
                            'Contribución',
                            '\$${_contribucionTotal.toStringAsFixed(2)}',
                            Colors.blue,
                          ),
                          _buildIndicador(
                            'Costos Fijos',
                            '\$${(_periodoSeleccionado == 'Semanal' 
                                ? _costosFijosMensual / 4.33 
                                : _costosFijosMensual).toStringAsFixed(2)}',
                            Colors.orange,
                          ),
                          _buildIndicador(
                            _gananciaNetaMensual >= 0 ? 'Ganancia' : 'Pérdida',
                            '\$${_gananciaNetaMensual.abs().toStringAsFixed(2)}',
                            _esRentable ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                      if (!_esRentable && _contribucionTotal > 0) ...[
                        SizedBox(height: 15),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Necesitas aumentar tus ventas en \$${((_periodoSeleccionado == 'Semanal' 
                                ? _costosFijosMensual / 4.33 
                                : _costosFijosMensual) - _contribucionTotal).toStringAsFixed(2)} ${_periodoSeleccionado == 'Semanal' ? 'semanales' : 'mensuales'} para ser rentable',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Título de lista
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.list_alt, color: Colors.purple),
                      SizedBox(width: 10),
                      Text(
                        'Proyección de Ventas ${_periodoSeleccionado == 'Semanal' ? 'Semanal' : 'Mensual'}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                
                // Lista de productos
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: productosOrdenados.length,
                    itemBuilder: (context, index) {
                      final producto = productosOrdenados[index];
                      final controller = _cantidadesControllers[producto.id];
                      
                      int cantidad = int.tryParse(controller?.text ?? '0') ?? 0;
                      // Ganancia = Precio - Solo Material
                      double gananciaUnitaria = producto.precioVentaSugerido - producto.costoSoloMaterial;
                      double contribucion = gananciaUnitaria * cantidad;
                      
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: _getColorByMargen(producto.margenGanancia),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            producto.nombre,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Margen: ${producto.margenGanancia.toStringAsFixed(1)}% | Precio: \$${producto.precioVentaSugerido.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 13),
                          ),
                          children: [
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Detalles del producto
                                  _buildDetalleRow('Costo material/unidad:', '\$${producto.costoSoloMaterial.toStringAsFixed(2)}'),
                                  _buildDetalleRow('Mano de obra/unidad:', '\$${producto.costoManoObra.toStringAsFixed(2)}', 
                                      color: Colors.blue[700]),
                                  _buildDetalleRow('Contribución/unidad:', '\$${gananciaUnitaria.toStringAsFixed(2)}', 
                                      color: Colors.green[700]),
                                  
                                  Divider(height: 20),
                                  
                                  // Input de cantidad
                                  Text('¿Cuántos esperas vender ${_periodoSeleccionado == 'Semanal' ? 'a la semana' : 'al mes'}?',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  SizedBox(height: 10),
                                  TextField(
                                    controller: controller,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Cantidad ${_periodoSeleccionado == 'Semanal' ? 'semanal' : 'mensual'}',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.shopping_cart),
                                      suffixText: 'unidades',
                                    ),
                                    onChanged: (_) => _calcularRentabilidad(),
                                  ),
                                  
                                  if (cantidad > 0) ...[
                                    SizedBox(height: 15),
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.purple[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        children: [
                                          Text('CONTRIBUCIÓN DE ESTE PRODUCTO:',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          SizedBox(height: 5),
                                          Text(
                                            '\$${contribucion.toStringAsFixed(2)}/mes',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.purple[900],
                                            ),
                                          ),
                                          SizedBox(height: 5),
                                          Text(
                                            '($cantidad unidades × \$${gananciaUnitaria.toStringAsFixed(2)})',
                                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: _productos.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => _buildRankingDialog(productosOrdenados),
                );
              },
              icon: Icon(Icons.analytics),
              label: Text('Ranking'),
              backgroundColor: Colors.purple,
            )
          : null,
    );
  }

  Widget _buildIndicador(String label, String valor, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        SizedBox(height: 5),
        Text(
          valor,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDetalleRow(String label, String valor, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13)),
          Text(
            valor,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorByMargen(double margen) {
    if (margen >= 30) return Colors.green;
    if (margen >= 15) return Colors.orange;
    return Colors.red;
  }

  Widget _buildRankingDialog(List<Producto> productosOrdenados) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.emoji_events, color: Colors.amber),
          SizedBox(width: 10),
          Text('Ranking de Rentabilidad'),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: productosOrdenados.length,
          itemBuilder: (context, index) {
            final producto = productosOrdenados[index];
            final controller = _cantidadesControllers[producto.id];
            int cantidad = int.tryParse(controller?.text ?? '0') ?? 0;
            // Contribución = Precio - Solo Material (sueldos se pagan con esto)
            double gananciaUnitaria = producto.precioVentaSugerido - producto.costoSoloMaterial;
            double contribucion = gananciaUnitaria * cantidad;
            
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: index == 0
                    ? Colors.amber
                    : index == 1
                        ? Colors.grey[400]
                        : index == 2
                            ? Colors.brown[300]
                            : Colors.blue[200],
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(producto.nombre),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Margen: ${producto.margenGanancia.toStringAsFixed(1)}%'),
                  if (cantidad > 0)
                    Text(
                      'Contribución: \$${contribucion.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              trailing: Icon(
                _getColorByMargen(producto.margenGanancia) == Colors.green
                    ? Icons.trending_up
                    : _getColorByMargen(producto.margenGanancia) == Colors.orange
                        ? Icons.trending_flat
                        : Icons.trending_down,
                color: _getColorByMargen(producto.margenGanancia),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cerrar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (var controller in _cantidadesControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
