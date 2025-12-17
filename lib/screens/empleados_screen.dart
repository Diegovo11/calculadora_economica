import 'package:flutter/material.dart';
import '../models/empleado.dart';
import '../database/database_helper.dart';

class EmpleadosScreen extends StatefulWidget {
  @override
  _EmpleadosScreenState createState() => _EmpleadosScreenState();
}

class _EmpleadosScreenState extends State<EmpleadosScreen> {
  List<Empleado> empleados = [];
  bool isLoading = true;
  double totalMensual = 0;
  double totalSemanal = 0;
  double totalDiario = 0;

  @override
  void initState() {
    super.initState();
    _cargarEmpleados();
  }

  Future<void> _cargarEmpleados() async {
    setState(() => isLoading = true);
    final data = await DatabaseHelper.instance.getEmpleados();
    final sueldosMes = await DatabaseHelper.instance.getTotalSueldosMensuales();
    final sueldosSem = await DatabaseHelper.instance.getTotalSueldosSemanales();
    final sueldosDia = await DatabaseHelper.instance.getTotalSueldosDiarios();
    
    setState(() {
      empleados = data;
      totalMensual = sueldosMes;
      totalSemanal = sueldosSem;
      totalDiario = sueldosDia;
      isLoading = false;
    });
  }

  Future<void> _mostrarFormulario({Empleado? empleado}) async {
    final nombreController = TextEditingController(text: empleado?.nombre ?? '');
    final sueldoController = TextEditingController(
        text: empleado?.sueldoPorHora.toString() ?? '');
    final eficienciaController = TextEditingController(
        text: empleado?.eficiencia.toString() ?? '100');
    final horasDiariasController = TextEditingController(
        text: empleado?.horasDiarias.toString() ?? '8');
    final diasSemanaController = TextEditingController(
        text: empleado?.diasSemana.toString() ?? '6');
    
    String tipoContrato = empleado?.tipoContrato ?? 'por_hora';
    bool activo = empleado?.activo ?? true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(empleado == null ? 'Nuevo Empleado' : 'Editar Empleado'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del empleado',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  value: tipoContrato,
                  decoration: InputDecoration(
                    labelText: 'Tipo de Contrato',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'por_hora', child: Text('Por Hora')),
                    DropdownMenuItem(value: 'semanal', child: Text('Semanal')),
                    DropdownMenuItem(value: 'mensual', child: Text('Mensual')),
                  ],
                  onChanged: (value) {
                    setStateDialog(() => tipoContrato = value!);
                  },
                ),
                SizedBox(height: 15),

                TextField(
                  controller: sueldoController,
                  decoration: InputDecoration(
                    labelText: tipoContrato == 'por_hora'
                        ? 'Sueldo por hora'
                        : tipoContrato == 'semanal'
                            ? 'Sueldo semanal'
                            : 'Sueldo mensual',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 15),

                TextField(
                  controller: horasDiariasController,
                  decoration: InputDecoration(
                    labelText: 'Horas trabajadas por día',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time),
                    hintText: 'Ej: 8',
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 15),

                TextField(
                  controller: diasSemanaController,
                  decoration: InputDecoration(
                    labelText: 'Días trabajados por semana',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                    hintText: 'Ej: 6',
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 15),

                TextField(
                  controller: eficienciaController,
                  decoration: InputDecoration(
                    labelText: 'Eficiencia (%)',
                    hintText: '100 = 100% eficiente',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.trending_up),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 15),

                SwitchListTile(
                  title: Text('Empleado Activo'),
                  value: activo,
                  onChanged: (value) {
                    setStateDialog(() => activo = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nombreController.text.isNotEmpty &&
                    sueldoController.text.isNotEmpty) {
                  final nuevoEmpleado = Empleado(
                    id: empleado?.id,
                    nombre: nombreController.text,
                    sueldoPorHora: double.parse(sueldoController.text),
                    eficiencia: double.parse(eficienciaController.text),
                    tipoContrato: tipoContrato,
                    horasDiarias: double.parse(horasDiariasController.text),
                    diasSemana: double.parse(diasSemanaController.text),
                    activo: activo,
                    fechaContratacion: empleado?.fechaContratacion ?? DateTime.now(),
                  );

                  if (empleado == null) {
                    await DatabaseHelper.instance.insertEmpleado(nuevoEmpleado);
                  } else {
                    await DatabaseHelper.instance.updateEmpleado(nuevoEmpleado);
                  }

                  Navigator.pop(context);
                  _cargarEmpleados();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: Text('GUARDAR', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eliminarEmpleado(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar'),
        content: Text('¿Eliminar este empleado?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('ELIMINAR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await DatabaseHelper.instance.deleteEmpleado(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Empleado eliminado')),
      );
      _cargarEmpleados();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Empleados'),
        backgroundColor: Colors.teal[700],
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _cargarEmpleados),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal[400]!, Colors.teal[700]!],
              ),
            ),
            child: Column(
              children: [
                Text('NÓMINA TOTAL',
                    style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTotalCard('Diario', totalDiario),
                    _buildTotalCard('Semanal', totalSemanal),
                    _buildTotalCard('Mensual', totalMensual),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : empleados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 100, color: Colors.grey),
                            SizedBox(height: 20),
                            Text('No hay empleados registrados',
                                style: TextStyle(fontSize: 18, color: Colors.grey)),
                            SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => _mostrarFormulario(),
                              icon: Icon(Icons.add),
                              label: Text('AGREGAR EMPLEADO'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: empleados.length,
                        itemBuilder: (context, index) {
                          final empleado = empleados[index];
                          return Card(
                            elevation: 2,
                            margin: EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: empleado.activo ? Colors.green[100] : Colors.grey[300],
                                child: Icon(Icons.person,
                                    color: empleado.activo ? Colors.green[900] : Colors.grey[600]),
                              ),
                              title: Text(empleado.nombre,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      decoration: empleado.activo ? null : TextDecoration.lineThrough)),
                              subtitle: Text(
                                  '${empleado.horasDiarias}h/día | ${empleado.diasSemana.toStringAsFixed(0)} días/sem | Eficiencia: ${empleado.eficiencia.toStringAsFixed(0)}%'),
                              trailing: Text('\$${empleado.sueldoMensual.toStringAsFixed(0)}/mes',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal[700])),
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildInfoRow('Sueldo Diario:', '\$${empleado.sueldoDiario.toStringAsFixed(2)}'),
                                      _buildInfoRow('Sueldo Semanal:', '\$${empleado.sueldoSemanal.toStringAsFixed(2)}'),
                                      _buildInfoRow('Sueldo Mensual:', '\$${empleado.sueldoMensual.toStringAsFixed(2)}'),
                                      _buildInfoRow('Horas/semana:', '${empleado.horasSemana.toStringAsFixed(1)} hrs'),
                                      _buildInfoRow('Eficiencia:', '${empleado.eficiencia.toStringAsFixed(0)}%'),
                                      _buildInfoRow('Contratado:', _formatearFecha(empleado.fechaContratacion)),
                                      SizedBox(height: 15),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () => _mostrarFormulario(empleado: empleado),
                                            icon: Icon(Icons.edit, color: Colors.blue),
                                            label: Text('Editar', style: TextStyle(color: Colors.blue)),
                                          ),
                                          SizedBox(width: 10),
                                          TextButton.icon(
                                            onPressed: () => _eliminarEmpleado(empleado.id!),
                                            icon: Icon(Icons.delete, color: Colors.red),
                                            label: Text('Eliminar', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
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
      floatingActionButton: empleados.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _mostrarFormulario(),
              icon: Icon(Icons.add),
              label: Text('NUEVO EMPLEADO'),
              backgroundColor: Colors.teal,
            )
          : null,
    );
  }

  Widget _buildTotalCard(String periodo, double monto) {
    return Column(
      children: [
        Text(periodo, style: TextStyle(color: Colors.white70, fontSize: 12)),
        SizedBox(height: 5),
        Text('\$${monto.toStringAsFixed(0)}',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}