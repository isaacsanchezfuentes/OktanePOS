// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paquete_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaqueteModel _$PaqueteModelFromJson(Map<String, dynamic> json) => PaqueteModel(
  id: json['id'] as String,
  trackingNumber: json['tracking_number'] as String,
  remitenteNombre: json['remitente_nombre'] as String,
  remitenteTelefono: json['remitente_telefono'] as String?,
  destinatarioNombre: json['destinatario_nombre'] as String,
  destinatarioDireccion: json['destinatario_direccion'] as String,
  destinatarioTelefono: json['destinatario_telefono'] as String,
  notasEntrega: json['notas_entrega'] as String?,
  pesoKg: (json['peso_kg'] as num).toDouble(),
  estado: $enumDecode(_$EstadoPaqueteEnumMap, json['estado']),
  choferAsignadoId: json['chofer_asignado_id'] as String?,
  montoEnvio: (json['monto_envio'] as num?)?.toDouble() ?? 0.0,
  metodoPago: $enumDecodeNullable(_$MetodoPagoEnumMap, json['metodo_pago']),
  estadoPago:
      $enumDecodeNullable(_$EstadoPagoEnumMap, json['estado_pago']) ??
      EstadoPago.porPagar,
  referenciaPago: json['referencia_pago'] as String?,
  comisionServicio: (json['comision_servicio'] as num?)?.toDouble() ?? 5.0,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$PaqueteModelToJson(PaqueteModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tracking_number': instance.trackingNumber,
      'remitente_nombre': instance.remitenteNombre,
      'remitente_telefono': instance.remitenteTelefono,
      'destinatario_nombre': instance.destinatarioNombre,
      'destinatario_direccion': instance.destinatarioDireccion,
      'destinatario_telefono': instance.destinatarioTelefono,
      'notas_entrega': instance.notasEntrega,
      'peso_kg': instance.pesoKg,
      'estado': _$EstadoPaqueteEnumMap[instance.estado]!,
      'chofer_asignado_id': instance.choferAsignadoId,
      'monto_envio': instance.montoEnvio,
      'metodo_pago': _$MetodoPagoEnumMap[instance.metodoPago],
      'estado_pago': _$EstadoPagoEnumMap[instance.estadoPago]!,
      'referencia_pago': instance.referenciaPago,
      'comision_servicio': instance.comisionServicio,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$EstadoPaqueteEnumMap = {
  EstadoPaquete.recibido: 'RECIBIDO',
  EstadoPaquete.aBordo: 'A_BORDO',
  EstadoPaquete.bodegaDestino: 'BODEGA_DESTINO',
  EstadoPaquete.enReparto: 'EN_REPARTO',
  EstadoPaquete.entregado: 'ENTREGADO',
  EstadoPaquete.incidencia: 'INCIDENCIA',
  EstadoPaquete.cancelado: 'CANCELADO',
};

const _$MetodoPagoEnumMap = {
  MetodoPago.efectivo: 'EFECTIVO',
  MetodoPago.speiTransferencia: 'SPEI_TRANSFERENCIA',
};

const _$EstadoPagoEnumMap = {
  EstadoPago.porPagar: 'POR_PAGAR',
  EstadoPago.pagado: 'PAGADO',
};
