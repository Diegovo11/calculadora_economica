import 'package:flutter/material.dart';
import '../models/gasto_fijo.dart';
import '../database/database_helper.dart';

class GastosScreen extends StatefulWidget {
  @override
  _GastosScreenState createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  List<GastoFijo> gastos = [];
  bool isLoading = true;
  double totalMensual = 0;

  @override
  void initState() {
    super.initState();
    _cargarGastos();
  }

  Future<void> _cargarGastos() async {
    setState(() => isLoading = true);
    final data = await DatabaseHelper.instance.getGastosFijos();
    final total = await DatabaseHelper.instance.getTotalGastosMensuales();
    setState(() {
      gastos = data;
      totalMensual = total;
      isLoading = false;
    });
  }

  Future<void> _mostrarFormulario({GastoFijo? gasto}) async {
    final conceptoController = TextEditingController(text: gasto?.concepto ?? '');
    final montoController = TextEditingController(
        text: gasto?.monto.toString() ?? '');
    String frecuencia = gasto?.frecuencia ?? 'mensual';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(gasto == null ? 'Nuevo Gasto' : 'Editar Gasto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: conceptoController,
                decoration: InputDecoration(
                  labelText: 'Concepto',
                  hintText: 'Ej: Renta, Luz, Internet',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: montoController,
                decoration: InputDecoration(
                  labelText: 'Monto',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: frecuencia,
                decoration: InputDecoration(
                  labelText: 'Frecuencia',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'diario', child: Text('Diario')),
                  DropdownMenuItem(value: 'semanal', child: Text('Semanal')),
                  DropdownMenuItem(value: 'mensual', child: Text('Mensual')),
                ],
                onChanged: (value) {
                  frecuencia = value!;
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
              if (conceptoController.text.isNotEmpty &&
                  montoController.text.isNotEmpty) {
                final nuevoGasto = GastoFijo(
                  id: gasto?.id,
                  concepto: conceptoController.text,
                  monto: double.parse(montoController.text),
                  frecuencia: frecuencia,
                  fechaRegistro: gasto?.fechaRegistro ?? DateTime.now(),
                );

                if (gasto == null) {
                  await DatabaseHelper.instance.insertGastoFijo(nuevoGasto);
                } else {
                  await DatabaseHelper.instance.updateGastoFijo(nuevoGasto);
                }

                Navigator.pop(context);
                _cargarGastos();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('GUARDAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarGasto(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar'),
        content: Text('¿Eliminar este gasto?'),
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
      await DatabaseHelper.instance.deleteGastoFijo(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gasto eliminado')),
      );
      _cargarGastos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gastos Fijos'),
        backgroundColor: Colors.orange[700],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _cargarGastos,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[400]!, Colors.orange[700]!],
              ),
            ),
            child: Column(
              children: [
                Text(
                  'TOTAL GASTOS MENSUALES',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '\$${totalMensual.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 36,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : gastos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 100, color: Colors.grey),
                            SizedBox(height: 20),
                            Text(
                              'No hay gastos registrados',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => _mostrarFormulario(),
                              icon: Icon(Icons.add),
                              label: Text('AGREGAR GASTO'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: gastos.length,
                        itemBuilder: (context, index) {
                          final gasto = gastos[index];
                          return Card(
                            elevation: 2,
                            margin: EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange[100],
                                child: Icon(Icons.attach_money,
                                    color: Colors.orange[900]),
                              ),
                              title: Text(
                                gasto.concepto,
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 5),
                                  Text(
                                    '\$${gasto.monto.toStringAsFixed(2)} / ${gasto.frecuencia}',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  if (gasto.frecuencia != 'mensual')
                                    Text(
                                      'Mensual: \$${gasto.montoMensual.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () =>
                                        _mostrarFormulario(gasto: gasto),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _eliminarGasto(gasto.id!),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: gastos.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _mostrarFormulario(),
              icon: Icon(Icons.add),
              label: Text('NUEVO GASTO'),
              backgroundColor: Colors.orange,
            )
          : null,
    );
  }
}