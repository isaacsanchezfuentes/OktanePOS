import 'package:json_annotation/json_annotation.dart';

part 'paquete_model.g.dart';

enum EstadoPaquete {
  @JsonValue('RECIBIDO')
  recibido,
  @JsonValue('A_BORDO')
  aBordo,
  @JsonValue('BODEGA_DESTINO')
  bodegaDestino,
  @JsonValue('EN_REPARTO')
  enReparto,
  @JsonValue('ENTREGADO')
  entregado,
  @JsonValue('INCIDENCIA')
  incidencia,
  @JsonValue('CANCELADO')
  cancelado,
}

enum MetodoPago {
  @JsonValue('EFECTIVO')
  efectivo,
  @JsonValue('SPEI_TRANSFERENCIA')
  speiTransferencia,
}

enum EstadoPago {
  @JsonValue('POR_PAGAR')
  porPagar,
  @JsonValue('PAGADO')
  pagado,
}

@JsonSerializable(explicitToJson: true)
class PaqueteModel {
  final String id;
  @JsonKey(name: 'tracking_number')
  final String trackingNumber;
  @JsonKey(name: 'remitente_nombre')
  final String remitenteNombre;
  @JsonKey(name: 'remitente_telefono')
  final String? remitenteTelefono;
  @JsonKey(name: 'destinatario_nombre')
  final String destinatarioNombre;
  @JsonKey(name: 'destinatario_direccion')
  final String destinatarioDireccion;
  @JsonKey(name: 'destinatario_telefono')
  final String destinatarioTelefono;
  @JsonKey(name: 'notas_entrega')
  final String? notasEntrega;
  @JsonKey(name: 'peso_kg')
  final double pesoKg;
  final EstadoPaquete estado;
  @JsonKey(name: 'chofer_asignado_id')
  final String? choferAsignadoId;

  @JsonKey(name: 'monto_envio')
  final double montoEnvio;
  @JsonKey(name: 'metodo_pago')
  final MetodoPago? metodoPago;
  @JsonKey(name: 'estado_pago')
  final EstadoPago estadoPago;
  @JsonKey(name: 'referencia_pago')
  final String? referenciaPago;
  @JsonKey(name: 'comision_servicio')
  final double comisionServicio;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  PaqueteModel({
    required this.id,
    required this.trackingNumber,
    required this.remitenteNombre,
    this.remitenteTelefono,
    required this.destinatarioNombre,
    required this.destinatarioDireccion,
    required this.destinatarioTelefono,
    this.notasEntrega,
    required this.pesoKg,
    required this.estado,
    this.choferAsignadoId,
    this.montoEnvio = 0.0,
    this.metodoPago,
    this.estadoPago = EstadoPago.porPagar,
    this.referenciaPago,
    this.comisionServicio = 5.0,
    this.createdAt,
    this.updatedAt,
  });

  factory PaqueteModel.fromJson(Map<String, dynamic> json) => _$PaqueteModelFromJson(json);
  Map<String, dynamic> toJson() => _$PaqueteModelToJson(this);
}
