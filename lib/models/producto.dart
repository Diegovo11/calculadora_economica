class Producto {
  int? id;
  String nombre;
  double costoMateriaPrima;
  double costoManoObra;
  double precioVentaSugerido;
  double gananciaEsperada;
  DateTime fechaCreacion;

  Producto({
    this.id,
    required this.nombre,
    required this.costoMateriaPrima,
    required this.costoManoObra,
    required this.precioVentaSugerido,
    required this.gananciaEsperada,
    required this.fechaCreacion,
  });

  double get costoTotal => costoMateriaPrima + costoManoObra;

  // Solo materia prima
  double get costoSoloMaterial => costoMateriaPrima;

  double get precioMinimo => costoTotal;

  double get gananciaObtenida => precioVentaSugerido - costoTotal;

  double get margenGanancia => (gananciaObtenida / costoTotal) * 100;

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'],
      nombre: map['nombre'],
      costoMateriaPrima: map['costo_materia_prima'],
      costoManoObra: map['costo_mano_obra'],
      precioVentaSugerido: map['precio_venta_sugerido'],
      gananciaEsperada: map['ganancia_esperada'],
      fechaCreacion: DateTime.parse(map['fecha_creacion']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'costo_materia_prima': costoMateriaPrima,
      'costo_mano_obra': costoManoObra,
      'precio_venta_sugerido': precioVentaSugerido,
      'ganancia_esperada': gananciaEsperada,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }
}