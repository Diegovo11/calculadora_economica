class GastoFijo {
  int? id;
  String concepto;
  double monto;
  String frecuencia; // 'mensual', 'semanal', 'diario'
  DateTime fechaRegistro;

  GastoFijo({
    this.id,
    required this.concepto,
    required this.monto,
    required this.frecuencia,
    required this.fechaRegistro,
  });

  // Convertir a monto mensual
  double get montoMensual {
    switch (frecuencia) {
      case 'diario':
        return monto * 30;
      case 'semanal':
        return monto * 4;
      case 'mensual':
      default:
        return monto;
    }
  }

  factory GastoFijo.fromMap(Map<String, dynamic> map) {
    return GastoFijo(
      id: map['id'],
      concepto: map['concepto'],
      monto: map['monto'],
      frecuencia: map['frecuencia'],
      fechaRegistro: DateTime.parse(map['fecha_registro']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'concepto': concepto,
      'monto': monto,
      'frecuencia': frecuencia,
      'fecha_registro': fechaRegistro.toIso8601String(),
    };
  }
}