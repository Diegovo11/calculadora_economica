import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../database/database_helper.dart';

class ProductosScreen extends StatefulWidget {
  @override
  _ProductosScreenState createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  List<Producto> productos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    setState(() => isLoading = true);
    final data = await DatabaseHelper.instance.getProductos();
    setState(() {
      productos = data;
      isLoading = false;
    });
  }

  Future<void> _editarProducto(Producto producto) async {
    final nombreController = TextEditingController(text: producto.nombre);
    final materiaController = TextEditingController(text: producto.costoMateriaPrima.toString());
    final manoObraController = TextEditingController(text: producto.costoManoObra.toString());
    final precioController = TextEditingController(text: producto.precioVentaSugerido.toString());
    final gananciaController = TextEditingController(text: producto.gananciaEsperada.toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Producto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: materiaController,
                decoration: InputDecoration(
                  labelText: 'Costo Materia Prima',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 15),
              TextField(
                controller: manoObraController,
                decoration: InputDecoration(
                  labelText: 'Costo Mano de Obra',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 15),
              TextField(
                controller: precioController,
                decoration: InputDecoration(
                  labelText: 'Precio de Venta',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 15),
              TextField(
                controller: gananciaController,
                decoration: InputDecoration(
                  labelText: 'Margen Esperado (%)',
                  suffixText: '%',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
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
                  materiaController.text.isNotEmpty &&
                  manoObraController.text.isNotEmpty &&
                  precioController.text.isNotEmpty) {
                final productoActualizado = Producto(
                  id: producto.id,
                  nombre: nombreController.text,
                  costoMateriaPrima: double.parse(materiaController.text),
                  costoManoObra: double.parse(manoObraController.text),
                  precioVentaSugerido: double.parse(precioController.text),
                  gananciaEsperada: double.parse(gananciaController.text),
                  fechaCreacion: producto.fechaCreacion,
                );

                await DatabaseHelper.instance.updateProducto(productoActualizado);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Producto actualizado'), backgroundColor: Colors.green),
                );
                _cargarProductos();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text('GUARDAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarProducto(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar'),
        content: Text('¿Eliminar este producto?'),
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
      await DatabaseHelper.instance.deleteProducto(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Producto eliminado')),
      );
      _cargarProductos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Productos'),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _cargarProductos),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : productos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 100, color: Colors.grey),
                      SizedBox(height: 20),
                      Text('No hay productos guardados',
                          style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: productos.length,
                  itemBuilder: (context, index) {
                    final producto = productos[index];
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: Icon(Icons.shopping_bag, color: Colors.blue[900]),
                        ),
                        title: Text(producto.nombre,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        subtitle: Text('Precio: \$${producto.precioVentaSugerido.toStringAsFixed(2)}'),
                        trailing: Text('${producto.margenGanancia.toStringAsFixed(0)}%',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[700])),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow('Materia Prima:', '\$${producto.costoMateriaPrima.toStringAsFixed(2)}'),
                                _buildInfoRow('Mano de Obra:', '\$${producto.costoManoObra.toStringAsFixed(2)}'),
                                _buildInfoRow('Costo Total:', '\$${producto.costoTotal.toStringAsFixed(2)}'),
                                _buildInfoRow('Precio Venta:', '\$${producto.precioVentaSugerido.toStringAsFixed(2)}'),
                                _buildInfoRow('Ganancia:', '\$${producto.gananciaObtenida.toStringAsFixed(2)}'),
                                _buildInfoRow('Margen:', '${producto.margenGanancia.toStringAsFixed(1)}%'),
                                SizedBox(height: 15),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _editarProducto(producto),
                                      icon: Icon(Icons.edit, color: Colors.blue),
                                      label: Text('Editar', style: TextStyle(color: Colors.blue)),
                                    ),
                                    SizedBox(width: 10),
                                    TextButton.icon(
                                      onPressed: () => _eliminarProducto(producto.id!),
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
}