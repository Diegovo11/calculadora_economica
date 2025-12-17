import 'package:flutter/material.dart';
import 'calculadora_screen.dart';
import 'productos_screen.dart';
import 'gastos_screen.dart';
import 'empleados_screen.dart';
import 'resumen_screen.dart';
import 'mix_productos_screen.dart';

class MenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calculadora de Ganancias'),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          children: [
            _buildMenuCard(
              context,
              'Calcular Precio',
              'Calcula cuánto vender tu producto',
              Colors.green,
              CalculadoraScreen(),
            ),
            _buildMenuCard(
              context,
              'Mis Productos',
              'Ver y gestionar productos',
              Colors.blue,
              ProductosScreen(),
            ),
            _buildMenuCard(
              context,
              'Mix de Productos',
              'Analiza rentabilidad de tu mix',
              Colors.deepPurple,
              MixProductosScreen(),
            ),
            _buildMenuCard(
              context,
              'Empleados',
              'Gestionar personal y nómina',
              Colors.teal,
              EmpleadosScreen(),
            ),
            _buildMenuCard(
              context,
              'Gastos Fijos',
              'Renta, luz, internet, etc.',
              Colors.orange,
              GastosScreen(),
            ),
            _buildMenuCard(
              context,
              'Resumen',
              'Estado financiero general',
              Colors.purple,
              ResumenScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, String subtitle,
      Color color, Widget screen) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        ),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}