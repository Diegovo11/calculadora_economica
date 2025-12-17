class Empleado {
  int? id;
  String nombre;
  double sueldoPorHora;
  double eficiencia; // Porcentaje de productividad 
  String tipoContrato; // 'por_hora', 'semanal', 'mensual'
  double horasDiarias; // Horas trabajadas por día
  double diasSemana; // Días trabajados por semana 
  bool activo;
  DateTime fechaContratacion;

  Empleado({
    this.id,
    required this.nombre,
    required this.sueldoPorHora,
    required this.eficiencia,
    required this.tipoContrato,
    this.horasDiarias = 8,
    this.diasSemana = 6,
    this.activo = true,
    required this.fechaContratacion,
  });

  // Horas por semana
  double get horasSemana => horasDiarias * diasSemana;

  // Horas por mes (4.33 semanas promedio)
  double get horasMes => horasSemana * 4.33;

  // SUELDO REAL POR HORA (sin importar el tipo de contrato)
  double get sueldoRealPorHora {
    switch (tipoContrato) {
      case 'por_hora':
        return sueldoPorHora; // hora
      case 'semanal':
        return sueldoPorHora / horasSemana; // Sueldo semanal ÷ horas semana
      case 'mensual':
        return sueldoPorHora / horasMes; // Sueldo mensual ÷ horas mes
      default:
        return 0;
    }
  }

  // Sueldo mensual estimado
  double get sueldoMensual {
    switch (tipoContrato) {
      case 'por_hora':
        return sueldoPorHora * horasMes;
      case 'semanal':
        return sueldoPorHora * 4.33;
      case 'mensual':
        return sueldoPorHora;
      default:
        return 0;
    }
  }

  // Sueldo semanal
  double get sueldoSemanal {
    switch (tipoContrato) {
      case 'por_hora':
        return sueldoPorHora * horasSemana;
      case 'semanal':
        return sueldoPorHora;
      case 'mensual':
        return sueldoPorHora / 4.33;
      default:
        return 0;
    }
  }

  // Sueldo diario
  double get sueldoDiario {
    switch (tipoContrato) {
      case 'por_hora':
        return sueldoPorHora * horasDiarias;
      case 'semanal':
        return sueldoPorHora / diasSemana;
      case 'mensual':
        return sueldoPorHora / (diasSemana * 4.33);
      default:
        return 0;
    }
  }

  factory Empleado.fromMap(Map<String, dynamic> map) {
    return Empleado(
      id: map['id'],
      nombre: map['nombre'],
      sueldoPorHora: map['sueldo_por_hora'],
      eficiencia: map['eficiencia'],
      tipoContrato: map['tipo_contrato'],
      horasDiarias: map['horas_diarias'],
      diasSemana: map['dias_semana'],
      activo: map['activo'] == 1,
      fechaContratacion: DateTime.parse(map['fecha_contratacion']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'sueldo_por_hora': sueldoPorHora,
      'eficiencia': eficiencia,
      'tipo_contrato': tipoContrato,
      'horas_diarias': horasDiarias,
      'dias_semana': diasSemana,
      'activo': activo ? 1 : 0,
      'fecha_contratacion': fechaContratacion.toIso8601String(),
    };
  }
}