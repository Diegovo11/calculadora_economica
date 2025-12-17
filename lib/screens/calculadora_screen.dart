import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../models/empleado.dart';
import '../database/database_helper.dart';

class CalculadoraScreen extends StatefulWidget {
  @override
  _CalculadoraScreenState createState() => _CalculadoraScreenState();
}

class _CalculadoraScreenState extends State<CalculadoraScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  
  // Inputs principales
  final _materialController = TextEditingController();
  final _precioDeseadoController = TextEditingController();
  final _margenReferenciaController = TextEditingController(text: '30');
  
  // Tiempo de producción por empleado (Map: empleadoId -> minutos)
  Map<int, TextEditingController> _tiemposEmpleadosControllers = {};

  // TODOS los empleados activos
  List<Empleado> _empleadosActivos = [];
  int _numeroEmpleados = 0;
  double _eficienciaPromedio = 0;

  // Gastos del sistema
  double _totalGastosFijosMensual = 0;
  double _totalSueldosMensual = 0;
  double _costosFijosMensual = 0;
  
  double _totalGastosFijosSemanal = 0;
  double _totalSueldosSemanal = 0;
  double _costosFijosSemanal = 0;
  
  double _totalGastosFijosDiario = 0;
  double _totalSueldosDiario = 0;
  double _costosFijosDiario = 0;

  // Resultados - COSTOS
  double _costoMaterial = 0;
  double _costoManoObraPromedio = 0;
  double _costoDirecto = 0;
  double _tiempoPromedioProduccion = 0;

  // CON PRECIO DESEADO (lo que el usuario quiere vender)
  double _precioVentaFinal = 0;
  double _gananciaConPrecioDeseado = 0;
  double _margenRealPrecioDeseado = 0;
  bool _precioDeseadoRentable = false;
  
  // Punto de equilibrio con precio deseado
  int _unidadesDiariasDeseado = 0;
  int _unidadesSemanalesDeseado = 0;
  int _unidadesMensualesDeseado = 0;

  // CON MARGEN DE REFERENCIA (alternativa sugerida)
  double _precioConMargenReferencia = 0;
  double _gananciaConMargenReferencia = 0;
  int _unidadesDiariasReferencia = 0;
  int _unidadesSemanalesReferencia = 0;
  int _unidadesMensualesReferencia = 0;

  // CAPACIDAD DE PRODUCCIÓN
  int _capacidadDiaria = 0;
  int _capacidadSemanal = 0;
  int _capacidadMensual = 0;

  // UI
  bool _mostrarDetallesCosto = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final empleados = await DatabaseHelper.instance.getEmpleadosActivos();
    final gastosMes = await DatabaseHelper.instance.getTotalGastosMensuales();
    final sueldosMes = await DatabaseHelper.instance.getTotalSueldosMensuales();
    final sueldosSem = await DatabaseHelper.instance.getTotalSueldosSemanales();
    final sueldosDia = await DatabaseHelper.instance.getTotalSueldosDiarios();
    
    setState(() {
      _empleadosActivos = empleados;
      _numeroEmpleados = empleados.length;
      
      // Crear controladores para tiempo de cada empleado
      _tiemposEmpleadosControllers.clear();
      for (var emp in empleados) {
        _tiemposEmpleadosControllers[emp.id!] = TextEditingController();
      }
      
      // Mensual
      _totalGastosFijosMensual = gastosMes;
      _totalSueldosMensual = sueldosMes;
      _costosFijosMensual = gastosMes + sueldosMes;
      
      // Semanal
      _totalGastosFijosSemanal = gastosMes / 4.33;
      _totalSueldosSemanal = sueldosSem;
      _costosFijosSemanal = _totalGastosFijosSemanal + sueldosSem;
      
      // Diario
      _totalGastosFijosDiario = gastosMes / 30;
      _totalSueldosDiario = sueldosDia;
      _costosFijosDiario = _totalGastosFijosDiario + sueldosDia;
      
      if (empleados.isNotEmpty) {
        _eficienciaPromedio = empleados.fold<double>(0, (sum, emp) => sum + emp.eficiencia) / empleados.length;
      } else {
        _eficienciaPromedio = 100;
      }
    });
    
    _calcular();
  }

  void _calcular() {
    final precioDeseado = double.tryParse(_precioDeseadoController.text) ?? 0;
    final margenReferencia = double.tryParse(_margenReferenciaController.text) ?? 30;

    setState(() {

      // COSTO DE MATERIALES
  
      _costoMaterial = double.tryParse(_materialController.text) ?? 0;
      
      // COSTO MANO DE OBRA PROMEDIO

      double sumaTiempos = 0;
      double sumaCostos = 0;
      int empleadosConTiempo = 0;
      
      // Calcular costo de mano de obra para cada empleado
      for (var empleado in _empleadosActivos) {
        var controller = _tiemposEmpleadosControllers[empleado.id];
        if (controller != null && controller.text.isNotEmpty) {
          double minutos = double.tryParse(controller.text) ?? 0;
          if (minutos > 0) {
            // Tiempo real ajustado por eficiencia
            double tiempoReal = minutos / (empleado.eficiencia / 100);
            // Costo = sueldo REAL por hora × (minutos / 60)
            double costo = empleado.sueldoRealPorHora * (tiempoReal / 60);
            
            
            sumaTiempos += minutos;
            sumaCostos += costo;
            empleadosConTiempo++;
          }
        }
      }
      
      if (empleadosConTiempo > 0) {
        _tiempoPromedioProduccion = sumaTiempos / empleadosConTiempo;
        _costoManoObraPromedio = sumaCostos / empleadosConTiempo;
        
        // Capacidad de producción
        double minutosDisponiblesDia = 0;
        for (var emp in _empleadosActivos) {
          minutosDisponiblesDia += (emp.horasDiarias * 60 * (emp.eficiencia / 100));
        }
        
        _capacidadDiaria = (minutosDisponiblesDia / _tiempoPromedioProduccion).floor();
        _capacidadSemanal = (_capacidadDiaria * 6).floor();
        _capacidadMensual = (_capacidadDiaria * 26).floor();
      } else {
        _tiempoPromedioProduccion = 0;
        _costoManoObraPromedio = 0;
        _capacidadDiaria = 0;
        _capacidadSemanal = 0;
        _capacidadMensual = 0;
      }
      

      // COSTO DIRECTO TOTAL

      _costoDirecto = _costoMaterial + _costoManoObraPromedio;


      // PRECIO CON MARGEN DE REFERENCIA (SIMPLE)
      if (margenReferencia > 0 && margenReferencia < 100 && _costoDirecto > 0) {
        double margenDecimal = margenReferencia / 100;
        
        // Precio = Costo Directo / (1 - Margen%)
        _precioConMargenReferencia = _costoDirecto / (1 - margenDecimal);
        
        // Ganancia = Precio - Costo Directo
        _gananciaConMargenReferencia = _precioConMargenReferencia - _costoDirecto;
        
        // Punto de equilibrio con este precio
        if (_gananciaConMargenReferencia > 0 && _costosFijosMensual > 0) {
          _unidadesMensualesReferencia = (_costosFijosMensual / _gananciaConMargenReferencia).ceil();
          _unidadesSemanalesReferencia = (_unidadesMensualesReferencia / 4.33).ceil();
          _unidadesDiariasReferencia = (_unidadesMensualesReferencia / 30).ceil();
        } else {
          _unidadesMensualesReferencia = 0;
          _unidadesSemanalesReferencia = 0;
          _unidadesDiariasReferencia = 0;
        }

      } else {
        _precioConMargenReferencia = 0;
        _gananciaConMargenReferencia = 0;
        _unidadesDiariasReferencia = 0;
        _unidadesSemanalesReferencia = 0;
        _unidadesMensualesReferencia = 0;
      }


      // ANÁLISIs

      if (precioDeseado > 0 && _costoDirecto > 0) {
        _precioVentaFinal = precioDeseado;
        
        // CÁLCULO SIMPLE: Ganancia y Margen sobre costo directo
        _gananciaConPrecioDeseado = precioDeseado - _costoDirecto;
        _margenRealPrecioDeseado = (_gananciaConPrecioDeseado / precioDeseado) * 100;
        _precioDeseadoRentable = _gananciaConPrecioDeseado > 0;
        
        // PUNTO DE EQUILIBRIO 
        // Unidades necesarias para cubrir costos fijos
        if (_gananciaConPrecioDeseado > 0 && _costosFijosMensual > 0) {
          _unidadesMensualesDeseado = (_costosFijosMensual / _gananciaConPrecioDeseado).ceil();
          _unidadesSemanalesDeseado = (_unidadesMensualesDeseado / 4.33).ceil();
          _unidadesDiariasDeseado = (_unidadesMensualesDeseado / 30).ceil();
        } else {
          _unidadesMensualesDeseado = 0;
          _unidadesSemanalesDeseado = 0;
          _unidadesDiariasDeseado = 0;
        }

      } else {
        _precioVentaFinal = 0;
        _gananciaConPrecioDeseado = 0;
        _margenRealPrecioDeseado = 0;
        _precioDeseadoRentable = false;
        _unidadesDiariasDeseado = 0;
        _unidadesSemanalesDeseado = 0;
        _unidadesMensualesDeseado = 0;
      }
    });
  }

  Future<void> _guardarProducto() async {
    if (_formKey.currentState!.validate()) {
      final precioFinal = double.tryParse(_precioDeseadoController.text) ?? _precioConMargenReferencia;
      
      if (precioFinal <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Debes establecer un precio de venta'), backgroundColor: Colors.orange),
        );
        return;
      }

      final producto = Producto(
        nombre: _nombreController.text,
        costoMateriaPrima: double.parse(_materialController.text),
        costoManoObra: _costoManoObraPromedio,
        precioVentaSugerido: precioFinal,
        gananciaEsperada: _margenRealPrecioDeseado > 0 ? _margenRealPrecioDeseado : double.parse(_margenReferenciaController.text),
        fechaCreacion: DateTime.now(),
      );

      await DatabaseHelper.instance.insertProducto(producto);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Producto guardado con precio \$${precioFinal.toStringAsFixed(2)}'), backgroundColor: Colors.green),
      );

      _limpiarFormulario();
    }
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _materialController.clear();
    _precioDeseadoController.clear();
    _margenReferenciaController.text = '30';
    
    // Limpiar tiempos de empleados
    for (var controller in _tiemposEmpleadosControllers.values) {
      controller.clear();
    }
    
    setState(() => _mostrarDetallesCosto = false);
    _calcular();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calculadora de Precios'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _cargarDatos),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_empleadosActivos.isNotEmpty)
                Card(
                  color: Colors.teal[50],
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.people, color: Colors.teal[700]),
                            SizedBox(width: 10),
                            Text('EQUIPO DE TRABAJO',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal[900])),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text('$_numeroEmpleados empleados activos',
                            style: TextStyle(fontSize: 14)),
                        Text('Eficiencia promedio: ${_eficienciaPromedio.toStringAsFixed(0)}%',
                            style: TextStyle(fontSize: 14, color: Colors.teal[700], fontWeight: FontWeight.bold)),
                        if (_capacidadDiaria > 0) ...[
                          SizedBox(height: 10),
                          Text('CAPACIDAD DE PRODUCCIÓN:', 
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          Text('• Diaria: $_capacidadDiaria unidades', style: TextStyle(fontSize: 13)),
                          Text('• Semanal: $_capacidadSemanal unidades', style: TextStyle(fontSize: 13)),
                          Text('• Mensual: $_capacidadMensual unidades', style: TextStyle(fontSize: 13)),
                        ],
                      ],
                    ),
                  ),
                ),

              SizedBox(height: 15),

              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('COSTOS FIJOS DEL NEGOCIO', 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      _buildInfoRow('Diario:', '\$${_costosFijosDiario.toStringAsFixed(2)}'),
                      _buildInfoRow('Semanal:', '\$${_costosFijosSemanal.toStringAsFixed(2)}'),
                      _buildInfoRow('Mensual:', '\$${_costosFijosMensual.toStringAsFixed(2)}', bold: true),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre del producto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),

              SizedBox(height: 20),
              Text('DATOS DE PRODUCCIÓN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),

              _buildTextField(_materialController, 'Costo de Material por unidad', Icons.category),
              
              // TIEMPO DE PRODUCCIÓN POR EMPLEADO
              if (_empleadosActivos.isNotEmpty) ...[
                SizedBox(height: 15),
                Text('Tiempo de producción por empleado (minutos):', 
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                ..._empleadosActivos.map((emp) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: _buildTextField(
                      _tiemposEmpleadosControllers[emp.id]!,
                      '${emp.nombre} (${emp.eficiencia.toStringAsFixed(0)}% eficiencia)',
                      Icons.person,
                    ),
                  );
                }).toList(),
              ],
              
              SizedBox(height: 20),
              Text('ESTRATEGIA DE VENTA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),

              _buildTextField(_precioDeseadoController, 
                  'Precio al que QUIERES vender', Icons.attach_money,
                  hint: 'Tu precio ideal'),
              
              _buildTextField(_margenReferenciaController, 
                  'Margen de ganancia de referencia (%)', Icons.percent,
                  hint: 'Para comparar alternativas'),

              SizedBox(height: 30),

              Card(
                elevation: 4,
                color: Colors.blue[50],
                child: Column(
                  children: [
                    ListTile(
                      title: Text('COSTO POR UNIDAD',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900])),
                      subtitle: Text('\$${_costoDirecto.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[700])),
                      trailing: IconButton(
                        icon: Icon(_mostrarDetallesCosto ? Icons.expand_less : Icons.expand_more),
                        onPressed: () => setState(() => _mostrarDetallesCosto = !_mostrarDetallesCosto),
                      ),
                    ),
                    if (_mostrarDetallesCosto) ...[
                      Divider(thickness: 2),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildResultRow('Material:', double.parse(_materialController.text.isEmpty ? '0' : _materialController.text)),
                            if (_empleadosActivos.isNotEmpty) ...[
                              _buildResultRow('Mano de Obra (promedio):', _costoManoObraPromedio),
                              _buildResultRow('Tiempo prom. producción:', _tiempoPromedioProduccion, suffix: ' min'),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 15),

              // MOSTRAR SIEMPRE SI HAY PRECIO DESEADO (positivo o negativo)
              if (_precioDeseadoController.text.isNotEmpty && 
                  double.tryParse(_precioDeseadoController.text) != null &&
                  double.parse(_precioDeseadoController.text) > 0)
                _buildResultCard(
                  'TU PRECIO: \$${_precioDeseadoController.text}',
                  _precioDeseadoRentable ? Colors.green[50]! : Colors.red[50]!,
                  _precioDeseadoRentable ? Colors.green[900]! : Colors.red[900]!,
                  [
                    Row(
                      children: [
                        Icon(_precioDeseadoRentable ? Icons.check_circle : Icons.cancel, 
                            color: _precioDeseadoRentable ? Colors.green : Colors.red, size: 30),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _precioDeseadoRentable 
                                ? 'ES RENTABLE' 
                                : 'NO ES RENTABLE',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _precioDeseadoRentable ? Colors.green[900] : Colors.red[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    _buildResultRow('Ganancia por unidad:', _gananciaConPrecioDeseado, 
                        color: _gananciaConPrecioDeseado >= 0 ? Colors.green[700] : Colors.red[700], 
                        bold: true, fontSize: 18),
                    _buildResultRow('Margen real:', _margenRealPrecioDeseado, 
                        suffix: '%', 
                        color: _margenRealPrecioDeseado >= 0 ? Colors.green[700] : Colors.red[700], 
                        fontSize: 16),
                    if (_unidadesMensualesDeseado > 0) ...[
                      Divider(thickness: 2),
                      Text('Debes vender para ser rentable:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      SizedBox(height: 8),
                      _buildResultRow('Diario:', _unidadesDiariasDeseado.toDouble(), suffix: ' unidades'),
                      _buildResultRow('Semanal:', _unidadesSemanalesDeseado.toDouble(), suffix: ' unidades'),
                      _buildResultRow('Mensual:', _unidadesMensualesDeseado.toDouble(), suffix: ' unidades', bold: true),
                      if (_capacidadDiaria > 0) ...[
                        Divider(),
                        Text('CAPACIDAD DE PRODUCCIÓN:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Puedes producir/día:', style: TextStyle(fontSize: 14)),
                            Text('$_capacidadDiaria unidades', 
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue[700])),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Necesitas/día:', style: TextStyle(fontSize: 14)),
                            Text('$_unidadesDiariasDeseado unidades', 
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange[700])),
                          ],
                        ),
                        SizedBox(height: 10),
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _unidadesDiariasDeseado <= _capacidadDiaria 
                                ? Colors.green[100] 
                                : Colors.red[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _unidadesDiariasDeseado <= _capacidadDiaria
                                ? 'Tu equipo PUEDE alcanzar esta meta'
                                : 'Necesitas más personal o mejorar eficiencia',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _unidadesDiariasDeseado <= _capacidadDiaria 
                                  ? Colors.green[900] 
                                  : Colors.red[900],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),

              SizedBox(height: 15),

              if (_precioConMargenReferencia > 0)
                _buildResultCard(
                  'ALTERNATIVA: Precio con ${_margenReferenciaController.text}% ganancia',
                  Colors.purple[50]!,
                  Colors.purple[900]!,
                  [
                    Text('Si prefieres este margen de ganancia:',
                        style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                    SizedBox(height: 10),
                    _buildResultRow('Precio sugerido:', _precioConMargenReferencia, 
                        fontSize: 20, bold: true, color: Colors.purple[900]),
                    _buildResultRow('Ganancia/unidad:', _gananciaConMargenReferencia, 
                        fontSize: 16, color: Colors.purple[700]),
                    _buildResultRow('Margen:', double.tryParse(_margenReferenciaController.text) ?? 0, 
                        suffix: '%', fontSize: 16, color: Colors.purple[700]),
                    Divider(),
                    Text('Deberías vender:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(height: 8),
                    _buildResultRow('Diario:', _unidadesDiariasReferencia.toDouble(), suffix: ' unidades'),
                    _buildResultRow('Semanal:', _unidadesSemanalesReferencia.toDouble(), suffix: ' unidades'),
                    _buildResultRow('Mensual:', _unidadesMensualesReferencia.toDouble(), suffix: ' unidades', bold: true),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purple[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Precio con ganancia',
                        style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                      ),
                    ),
                  ],
                ),

              SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _guardarProducto,
                      icon: Icon(Icons.save),
                      label: Text('GUARDAR PRODUCTO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _limpiarFormulario,
                    icon: Icon(Icons.refresh),
                    label: Text('LIMPIAR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {String? hint}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(),
          prefixIcon: Icon(icon),
        ),
        keyboardType: TextInputType.number,
        onChanged: (_) => _calcular(),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildResultCard(String title, Color bgColor, Color titleColor, List<Widget> children) {
    return Card(
      elevation: 4,
      color: bgColor,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor)),
            Divider(thickness: 2),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, double value, 
      {bool bold = false, double fontSize = 16, Color? color, String suffix = ''}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal))),
          Text(
            suffix.isEmpty ? '\$${value.toStringAsFixed(2)}' : '${value.toStringAsFixed(0)}$suffix',
            style: TextStyle(fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _materialController.dispose();
    _precioDeseadoController.dispose();
    _margenReferenciaController.dispose();
    
    // Dispose tiempos empleados
    for (var controller in _tiemposEmpleadosControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }
}