// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_storage.dart';

// ignore_for_file: type=lint
class $PaquetesTable extends Paquetes with TableInfo<$PaquetesTable, Paquete> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaquetesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackingNumberMeta = const VerificationMeta(
    'trackingNumber',
  );
  @override
  late final GeneratedColumn<String> trackingNumber = GeneratedColumn<String>(
    'tracking_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _remitenteNombreMeta = const VerificationMeta(
    'remitenteNombre',
  );
  @override
  late final GeneratedColumn<String> remitenteNombre = GeneratedColumn<String>(
    'remitente_nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _remitenteTelefonoMeta = const VerificationMeta(
    'remitenteTelefono',
  );
  @override
  late final GeneratedColumn<String> remitenteTelefono =
      GeneratedColumn<String>(
        'remitente_telefono',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _destinatarioNombreMeta =
      const VerificationMeta('destinatarioNombre');
  @override
  late final GeneratedColumn<String> destinatarioNombre =
      GeneratedColumn<String>(
        'destinatario_nombre',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _destinatarioDireccionMeta =
      const VerificationMeta('destinatarioDireccion');
  @override
  late final GeneratedColumn<String> destinatarioDireccion =
      GeneratedColumn<String>(
        'destinatario_direccion',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _destinatarioTelefonoMeta =
      const VerificationMeta('destinatarioTelefono');
  @override
  late final GeneratedColumn<String> destinatarioTelefono =
      GeneratedColumn<String>(
        'destinatario_telefono',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _notasEntregaMeta = const VerificationMeta(
    'notasEntrega',
  );
  @override
  late final GeneratedColumn<String> notasEntrega = GeneratedColumn<String>(
    'notas_entrega',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pesoKgMeta = const VerificationMeta('pesoKg');
  @override
  late final GeneratedColumn<double> pesoKg = GeneratedColumn<double>(
    'peso_kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _estadoMeta = const VerificationMeta('estado');
  @override
  late final GeneratedColumn<String> estado = GeneratedColumn<String>(
    'estado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('RECIBIDO'),
  );
  static const VerificationMeta _choferAsignadoIdMeta = const VerificationMeta(
    'choferAsignadoId',
  );
  @override
  late final GeneratedColumn<String> choferAsignadoId = GeneratedColumn<String>(
    'chofer_asignado_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _montoEnvioMeta = const VerificationMeta(
    'montoEnvio',
  );
  @override
  late final GeneratedColumn<double> montoEnvio = GeneratedColumn<double>(
    'monto_envio',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metodoPagoMeta = const VerificationMeta(
    'metodoPago',
  );
  @override
  late final GeneratedColumn<String> metodoPago = GeneratedColumn<String>(
    'metodo_pago',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estadoPagoMeta = const VerificationMeta(
    'estadoPago',
  );
  @override
  late final GeneratedColumn<String> estadoPago = GeneratedColumn<String>(
    'estado_pago',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('POR_PAGAR'),
  );
  static const VerificationMeta _referenciaPagoMeta = const VerificationMeta(
    'referenciaPago',
  );
  @override
  late final GeneratedColumn<String> referenciaPago = GeneratedColumn<String>(
    'referencia_pago',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _comisionServicioMeta = const VerificationMeta(
    'comisionServicio',
  );
  @override
  late final GeneratedColumn<double> comisionServicio = GeneratedColumn<double>(
    'comision_servicio',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trackingNumber,
    remitenteNombre,
    remitenteTelefono,
    destinatarioNombre,
    destinatarioDireccion,
    destinatarioTelefono,
    notasEntrega,
    pesoKg,
    estado,
    choferAsignadoId,
    montoEnvio,
    metodoPago,
    estadoPago,
    referenciaPago,
    comisionServicio,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'paquetes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Paquete> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tracking_number')) {
      context.handle(
        _trackingNumberMeta,
        trackingNumber.isAcceptableOrUnknown(
          data['tracking_number']!,
          _trackingNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trackingNumberMeta);
    }
    if (data.containsKey('remitente_nombre')) {
      context.handle(
        _remitenteNombreMeta,
        remitenteNombre.isAcceptableOrUnknown(
          data['remitente_nombre']!,
          _remitenteNombreMeta,
        ),
      );
    }
    if (data.containsKey('remitente_telefono')) {
      context.handle(
        _remitenteTelefonoMeta,
        remitenteTelefono.isAcceptableOrUnknown(
          data['remitente_telefono']!,
          _remitenteTelefonoMeta,
        ),
      );
    }
    if (data.containsKey('destinatario_nombre')) {
      context.handle(
        _destinatarioNombreMeta,
        destinatarioNombre.isAcceptableOrUnknown(
          data['destinatario_nombre']!,
          _destinatarioNombreMeta,
        ),
      );
    }
    if (data.containsKey('destinatario_direccion')) {
      context.handle(
        _destinatarioDireccionMeta,
        destinatarioDireccion.isAcceptableOrUnknown(
          data['destinatario_direccion']!,
          _destinatarioDireccionMeta,
        ),
      );
    }
    if (data.containsKey('destinatario_telefono')) {
      context.handle(
        _destinatarioTelefonoMeta,
        destinatarioTelefono.isAcceptableOrUnknown(
          data['destinatario_telefono']!,
          _destinatarioTelefonoMeta,
        ),
      );
    }
    if (data.containsKey('notas_entrega')) {
      context.handle(
        _notasEntregaMeta,
        notasEntrega.isAcceptableOrUnknown(
          data['notas_entrega']!,
          _notasEntregaMeta,
        ),
      );
    }
    if (data.containsKey('peso_kg')) {
      context.handle(
        _pesoKgMeta,
        pesoKg.isAcceptableOrUnknown(data['peso_kg']!, _pesoKgMeta),
      );
    }
    if (data.containsKey('estado')) {
      context.handle(
        _estadoMeta,
        estado.isAcceptableOrUnknown(data['estado']!, _estadoMeta),
      );
    }
    if (data.containsKey('chofer_asignado_id')) {
      context.handle(
        _choferAsignadoIdMeta,
        choferAsignadoId.isAcceptableOrUnknown(
          data['chofer_asignado_id']!,
          _choferAsignadoIdMeta,
        ),
      );
    }
    if (data.containsKey('monto_envio')) {
      context.handle(
        _montoEnvioMeta,
        montoEnvio.isAcceptableOrUnknown(data['monto_envio']!, _montoEnvioMeta),
      );
    }
    if (data.containsKey('metodo_pago')) {
      context.handle(
        _metodoPagoMeta,
        metodoPago.isAcceptableOrUnknown(data['metodo_pago']!, _metodoPagoMeta),
      );
    }
    if (data.containsKey('estado_pago')) {
      context.handle(
        _estadoPagoMeta,
        estadoPago.isAcceptableOrUnknown(data['estado_pago']!, _estadoPagoMeta),
      );
    }
    if (data.containsKey('referencia_pago')) {
      context.handle(
        _referenciaPagoMeta,
        referenciaPago.isAcceptableOrUnknown(
          data['referencia_pago']!,
          _referenciaPagoMeta,
        ),
      );
    }
    if (data.containsKey('comision_servicio')) {
      context.handle(
        _comisionServicioMeta,
        comisionServicio.isAcceptableOrUnknown(
          data['comision_servicio']!,
          _comisionServicioMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Paquete map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Paquete(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      trackingNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tracking_number'],
      )!,
      remitenteNombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remitente_nombre'],
      )!,
      remitenteTelefono: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remitente_telefono'],
      ),
      destinatarioNombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destinatario_nombre'],
      )!,
      destinatarioDireccion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destinatario_direccion'],
      )!,
      destinatarioTelefono: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destinatario_telefono'],
      )!,
      notasEntrega: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notas_entrega'],
      ),
      pesoKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}peso_kg'],
      )!,
      estado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estado'],
      )!,
      choferAsignadoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chofer_asignado_id'],
      ),
      montoEnvio: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monto_envio'],
      ),
      metodoPago: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metodo_pago'],
      ),
      estadoPago: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estado_pago'],
      )!,
      referenciaPago: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}referencia_pago'],
      ),
      comisionServicio: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}comision_servicio'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $PaquetesTable createAlias(String alias) {
    return $PaquetesTable(attachedDatabase, alias);
  }
}

class Paquete extends DataClass implements Insertable<Paquete> {
  final String id;
  final String trackingNumber;
  final String remitenteNombre;
  final String? remitenteTelefono;
  final String destinatarioNombre;
  final String destinatarioDireccion;
  final String destinatarioTelefono;
  final String? notasEntrega;
  final double pesoKg;
  final String estado;
  final String? choferAsignadoId;
  final double? montoEnvio;
  final String? metodoPago;
  final String estadoPago;
  final String? referenciaPago;
  final double? comisionServicio;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  const Paquete({
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
    this.montoEnvio,
    this.metodoPago,
    required this.estadoPago,
    this.referenciaPago,
    this.comisionServicio,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tracking_number'] = Variable<String>(trackingNumber);
    map['remitente_nombre'] = Variable<String>(remitenteNombre);
    if (!nullToAbsent || remitenteTelefono != null) {
      map['remitente_telefono'] = Variable<String>(remitenteTelefono);
    }
    map['destinatario_nombre'] = Variable<String>(destinatarioNombre);
    map['destinatario_direccion'] = Variable<String>(destinatarioDireccion);
    map['destinatario_telefono'] = Variable<String>(destinatarioTelefono);
    if (!nullToAbsent || notasEntrega != null) {
      map['notas_entrega'] = Variable<String>(notasEntrega);
    }
    map['peso_kg'] = Variable<double>(pesoKg);
    map['estado'] = Variable<String>(estado);
    if (!nullToAbsent || choferAsignadoId != null) {
      map['chofer_asignado_id'] = Variable<String>(choferAsignadoId);
    }
    if (!nullToAbsent || montoEnvio != null) {
      map['monto_envio'] = Variable<double>(montoEnvio);
    }
    if (!nullToAbsent || metodoPago != null) {
      map['metodo_pago'] = Variable<String>(metodoPago);
    }
    map['estado_pago'] = Variable<String>(estadoPago);
    if (!nullToAbsent || referenciaPago != null) {
      map['referencia_pago'] = Variable<String>(referenciaPago);
    }
    if (!nullToAbsent || comisionServicio != null) {
      map['comision_servicio'] = Variable<double>(comisionServicio);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<DateTime>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  PaquetesCompanion toCompanion(bool nullToAbsent) {
    return PaquetesCompanion(
      id: Value(id),
      trackingNumber: Value(trackingNumber),
      remitenteNombre: Value(remitenteNombre),
      remitenteTelefono: remitenteTelefono == null && nullToAbsent
          ? const Value.absent()
          : Value(remitenteTelefono),
      destinatarioNombre: Value(destinatarioNombre),
      destinatarioDireccion: Value(destinatarioDireccion),
      destinatarioTelefono: Value(destinatarioTelefono),
      notasEntrega: notasEntrega == null && nullToAbsent
          ? const Value.absent()
          : Value(notasEntrega),
      pesoKg: Value(pesoKg),
      estado: Value(estado),
      choferAsignadoId: choferAsignadoId == null && nullToAbsent
          ? const Value.absent()
          : Value(choferAsignadoId),
      montoEnvio: montoEnvio == null && nullToAbsent
          ? const Value.absent()
          : Value(montoEnvio),
      metodoPago: metodoPago == null && nullToAbsent
          ? const Value.absent()
          : Value(metodoPago),
      estadoPago: Value(estadoPago),
      referenciaPago: referenciaPago == null && nullToAbsent
          ? const Value.absent()
          : Value(referenciaPago),
      comisionServicio: comisionServicio == null && nullToAbsent
          ? const Value.absent()
          : Value(comisionServicio),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory Paquete.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Paquete(
      id: serializer.fromJson<String>(json['id']),
      trackingNumber: serializer.fromJson<String>(json['trackingNumber']),
      remitenteNombre: serializer.fromJson<String>(json['remitenteNombre']),
      remitenteTelefono: serializer.fromJson<String?>(
        json['remitenteTelefono'],
      ),
      destinatarioNombre: serializer.fromJson<String>(
        json['destinatarioNombre'],
      ),
      destinatarioDireccion: serializer.fromJson<String>(
        json['destinatarioDireccion'],
      ),
      destinatarioTelefono: serializer.fromJson<String>(
        json['destinatarioTelefono'],
      ),
      notasEntrega: serializer.fromJson<String?>(json['notasEntrega']),
      pesoKg: serializer.fromJson<double>(json['pesoKg']),
      estado: serializer.fromJson<String>(json['estado']),
      choferAsignadoId: serializer.fromJson<String?>(json['choferAsignadoId']),
      montoEnvio: serializer.fromJson<double?>(json['montoEnvio']),
      metodoPago: serializer.fromJson<String?>(json['metodoPago']),
      estadoPago: serializer.fromJson<String>(json['estadoPago']),
      referenciaPago: serializer.fromJson<String?>(json['referenciaPago']),
      comisionServicio: serializer.fromJson<double?>(json['comisionServicio']),
      createdAt: serializer.fromJson<DateTime?>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'trackingNumber': serializer.toJson<String>(trackingNumber),
      'remitenteNombre': serializer.toJson<String>(remitenteNombre),
      'remitenteTelefono': serializer.toJson<String?>(remitenteTelefono),
      'destinatarioNombre': serializer.toJson<String>(destinatarioNombre),
      'destinatarioDireccion': serializer.toJson<String>(destinatarioDireccion),
      'destinatarioTelefono': serializer.toJson<String>(destinatarioTelefono),
      'notasEntrega': serializer.toJson<String?>(notasEntrega),
      'pesoKg': serializer.toJson<double>(pesoKg),
      'estado': serializer.toJson<String>(estado),
      'choferAsignadoId': serializer.toJson<String?>(choferAsignadoId),
      'montoEnvio': serializer.toJson<double?>(montoEnvio),
      'metodoPago': serializer.toJson<String?>(metodoPago),
      'estadoPago': serializer.toJson<String>(estadoPago),
      'referenciaPago': serializer.toJson<String?>(referenciaPago),
      'comisionServicio': serializer.toJson<double?>(comisionServicio),
      'createdAt': serializer.toJson<DateTime?>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  Paquete copyWith({
    String? id,
    String? trackingNumber,
    String? remitenteNombre,
    Value<String?> remitenteTelefono = const Value.absent(),
    String? destinatarioNombre,
    String? destinatarioDireccion,
    String? destinatarioTelefono,
    Value<String?> notasEntrega = const Value.absent(),
    double? pesoKg,
    String? estado,
    Value<String?> choferAsignadoId = const Value.absent(),
    Value<double?> montoEnvio = const Value.absent(),
    Value<String?> metodoPago = const Value.absent(),
    String? estadoPago,
    Value<String?> referenciaPago = const Value.absent(),
    Value<double?> comisionServicio = const Value.absent(),
    Value<DateTime?> createdAt = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => Paquete(
    id: id ?? this.id,
    trackingNumber: trackingNumber ?? this.trackingNumber,
    remitenteNombre: remitenteNombre ?? this.remitenteNombre,
    remitenteTelefono: remitenteTelefono.present
        ? remitenteTelefono.value
        : this.remitenteTelefono,
    destinatarioNombre: destinatarioNombre ?? this.destinatarioNombre,
    destinatarioDireccion: destinatarioDireccion ?? this.destinatarioDireccion,
    destinatarioTelefono: destinatarioTelefono ?? this.destinatarioTelefono,
    notasEntrega: notasEntrega.present ? notasEntrega.value : this.notasEntrega,
    pesoKg: pesoKg ?? this.pesoKg,
    estado: estado ?? this.estado,
    choferAsignadoId: choferAsignadoId.present
        ? choferAsignadoId.value
        : this.choferAsignadoId,
    montoEnvio: montoEnvio.present ? montoEnvio.value : this.montoEnvio,
    metodoPago: metodoPago.present ? metodoPago.value : this.metodoPago,
    estadoPago: estadoPago ?? this.estadoPago,
    referenciaPago: referenciaPago.present
        ? referenciaPago.value
        : this.referenciaPago,
    comisionServicio: comisionServicio.present
        ? comisionServicio.value
        : this.comisionServicio,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  Paquete copyWithCompanion(PaquetesCompanion data) {
    return Paquete(
      id: data.id.present ? data.id.value : this.id,
      trackingNumber: data.trackingNumber.present
          ? data.trackingNumber.value
          : this.trackingNumber,
      remitenteNombre: data.remitenteNombre.present
          ? data.remitenteNombre.value
          : this.remitenteNombre,
      remitenteTelefono: data.remitenteTelefono.present
          ? data.remitenteTelefono.value
          : this.remitenteTelefono,
      destinatarioNombre: data.destinatarioNombre.present
          ? data.destinatarioNombre.value
          : this.destinatarioNombre,
      destinatarioDireccion: data.destinatarioDireccion.present
          ? data.destinatarioDireccion.value
          : this.destinatarioDireccion,
      destinatarioTelefono: data.destinatarioTelefono.present
          ? data.destinatarioTelefono.value
          : this.destinatarioTelefono,
      notasEntrega: data.notasEntrega.present
          ? data.notasEntrega.value
          : this.notasEntrega,
      pesoKg: data.pesoKg.present ? data.pesoKg.value : this.pesoKg,
      estado: data.estado.present ? data.estado.value : this.estado,
      choferAsignadoId: data.choferAsignadoId.present
          ? data.choferAsignadoId.value
          : this.choferAsignadoId,
      montoEnvio: data.montoEnvio.present
          ? data.montoEnvio.value
          : this.montoEnvio,
      metodoPago: data.metodoPago.present
          ? data.metodoPago.value
          : this.metodoPago,
      estadoPago: data.estadoPago.present
          ? data.estadoPago.value
          : this.estadoPago,
      referenciaPago: data.referenciaPago.present
          ? data.referenciaPago.value
          : this.referenciaPago,
      comisionServicio: data.comisionServicio.present
          ? data.comisionServicio.value
          : this.comisionServicio,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Paquete(')
          ..write('id: $id, ')
          ..write('trackingNumber: $trackingNumber, ')
          ..write('remitenteNombre: $remitenteNombre, ')
          ..write('remitenteTelefono: $remitenteTelefono, ')
          ..write('destinatarioNombre: $destinatarioNombre, ')
          ..write('destinatarioDireccion: $destinatarioDireccion, ')
          ..write('destinatarioTelefono: $destinatarioTelefono, ')
          ..write('notasEntrega: $notasEntrega, ')
          ..write('pesoKg: $pesoKg, ')
          ..write('estado: $estado, ')
          ..write('choferAsignadoId: $choferAsignadoId, ')
          ..write('montoEnvio: $montoEnvio, ')
          ..write('metodoPago: $metodoPago, ')
          ..write('estadoPago: $estadoPago, ')
          ..write('referenciaPago: $referenciaPago, ')
          ..write('comisionServicio: $comisionServicio, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    trackingNumber,
    remitenteNombre,
    remitenteTelefono,
    destinatarioNombre,
    destinatarioDireccion,
    destinatarioTelefono,
    notasEntrega,
    pesoKg,
    estado,
    choferAsignadoId,
    montoEnvio,
    metodoPago,
    estadoPago,
    referenciaPago,
    comisionServicio,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Paquete &&
          other.id == this.id &&
          other.trackingNumber == this.trackingNumber &&
          other.remitenteNombre == this.remitenteNombre &&
          other.remitenteTelefono == this.remitenteTelefono &&
          other.destinatarioNombre == this.destinatarioNombre &&
          other.destinatarioDireccion == this.destinatarioDireccion &&
          other.destinatarioTelefono == this.destinatarioTelefono &&
          other.notasEntrega == this.notasEntrega &&
          other.pesoKg == this.pesoKg &&
          other.estado == this.estado &&
          other.choferAsignadoId == this.choferAsignadoId &&
          other.montoEnvio == this.montoEnvio &&
          other.metodoPago == this.metodoPago &&
          other.estadoPago == this.estadoPago &&
          other.referenciaPago == this.referenciaPago &&
          other.comisionServicio == this.comisionServicio &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PaquetesCompanion extends UpdateCompanion<Paquete> {
  final Value<String> id;
  final Value<String> trackingNumber;
  final Value<String> remitenteNombre;
  final Value<String?> remitenteTelefono;
  final Value<String> destinatarioNombre;
  final Value<String> destinatarioDireccion;
  final Value<String> destinatarioTelefono;
  final Value<String?> notasEntrega;
  final Value<double> pesoKg;
  final Value<String> estado;
  final Value<String?> choferAsignadoId;
  final Value<double?> montoEnvio;
  final Value<String?> metodoPago;
  final Value<String> estadoPago;
  final Value<String?> referenciaPago;
  final Value<double?> comisionServicio;
  final Value<DateTime?> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const PaquetesCompanion({
    this.id = const Value.absent(),
    this.trackingNumber = const Value.absent(),
    this.remitenteNombre = const Value.absent(),
    this.remitenteTelefono = const Value.absent(),
    this.destinatarioNombre = const Value.absent(),
    this.destinatarioDireccion = const Value.absent(),
    this.destinatarioTelefono = const Value.absent(),
    this.notasEntrega = const Value.absent(),
    this.pesoKg = const Value.absent(),
    this.estado = const Value.absent(),
    this.choferAsignadoId = const Value.absent(),
    this.montoEnvio = const Value.absent(),
    this.metodoPago = const Value.absent(),
    this.estadoPago = const Value.absent(),
    this.referenciaPago = const Value.absent(),
    this.comisionServicio = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaquetesCompanion.insert({
    required String id,
    required String trackingNumber,
    this.remitenteNombre = const Value.absent(),
    this.remitenteTelefono = const Value.absent(),
    this.destinatarioNombre = const Value.absent(),
    this.destinatarioDireccion = const Value.absent(),
    this.destinatarioTelefono = const Value.absent(),
    this.notasEntrega = const Value.absent(),
    this.pesoKg = const Value.absent(),
    this.estado = const Value.absent(),
    this.choferAsignadoId = const Value.absent(),
    this.montoEnvio = const Value.absent(),
    this.metodoPago = const Value.absent(),
    this.estadoPago = const Value.absent(),
    this.referenciaPago = const Value.absent(),
    this.comisionServicio = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       trackingNumber = Value(trackingNumber);
  static Insertable<Paquete> custom({
    Expression<String>? id,
    Expression<String>? trackingNumber,
    Expression<String>? remitenteNombre,
    Expression<String>? remitenteTelefono,
    Expression<String>? destinatarioNombre,
    Expression<String>? destinatarioDireccion,
    Expression<String>? destinatarioTelefono,
    Expression<String>? notasEntrega,
    Expression<double>? pesoKg,
    Expression<String>? estado,
    Expression<String>? choferAsignadoId,
    Expression<double>? montoEnvio,
    Expression<String>? metodoPago,
    Expression<String>? estadoPago,
    Expression<String>? referenciaPago,
    Expression<double>? comisionServicio,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackingNumber != null) 'tracking_number': trackingNumber,
      if (remitenteNombre != null) 'remitente_nombre': remitenteNombre,
      if (remitenteTelefono != null) 'remitente_telefono': remitenteTelefono,
      if (destinatarioNombre != null) 'destinatario_nombre': destinatarioNombre,
      if (destinatarioDireccion != null)
        'destinatario_direccion': destinatarioDireccion,
      if (destinatarioTelefono != null)
        'destinatario_telefono': destinatarioTelefono,
      if (notasEntrega != null) 'notas_entrega': notasEntrega,
      if (pesoKg != null) 'peso_kg': pesoKg,
      if (estado != null) 'estado': estado,
      if (choferAsignadoId != null) 'chofer_asignado_id': choferAsignadoId,
      if (montoEnvio != null) 'monto_envio': montoEnvio,
      if (metodoPago != null) 'metodo_pago': metodoPago,
      if (estadoPago != null) 'estado_pago': estadoPago,
      if (referenciaPago != null) 'referencia_pago': referenciaPago,
      if (comisionServicio != null) 'comision_servicio': comisionServicio,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaquetesCompanion copyWith({
    Value<String>? id,
    Value<String>? trackingNumber,
    Value<String>? remitenteNombre,
    Value<String?>? remitenteTelefono,
    Value<String>? destinatarioNombre,
    Value<String>? destinatarioDireccion,
    Value<String>? destinatarioTelefono,
    Value<String?>? notasEntrega,
    Value<double>? pesoKg,
    Value<String>? estado,
    Value<String?>? choferAsignadoId,
    Value<double?>? montoEnvio,
    Value<String?>? metodoPago,
    Value<String>? estadoPago,
    Value<String?>? referenciaPago,
    Value<double?>? comisionServicio,
    Value<DateTime?>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return PaquetesCompanion(
      id: id ?? this.id,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      remitenteNombre: remitenteNombre ?? this.remitenteNombre,
      remitenteTelefono: remitenteTelefono ?? this.remitenteTelefono,
      destinatarioNombre: destinatarioNombre ?? this.destinatarioNombre,
      destinatarioDireccion:
          destinatarioDireccion ?? this.destinatarioDireccion,
      destinatarioTelefono: destinatarioTelefono ?? this.destinatarioTelefono,
      notasEntrega: notasEntrega ?? this.notasEntrega,
      pesoKg: pesoKg ?? this.pesoKg,
      estado: estado ?? this.estado,
      choferAsignadoId: choferAsignadoId ?? this.choferAsignadoId,
      montoEnvio: montoEnvio ?? this.montoEnvio,
      metodoPago: metodoPago ?? this.metodoPago,
      estadoPago: estadoPago ?? this.estadoPago,
      referenciaPago: referenciaPago ?? this.referenciaPago,
      comisionServicio: comisionServicio ?? this.comisionServicio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (trackingNumber.present) {
      map['tracking_number'] = Variable<String>(trackingNumber.value);
    }
    if (remitenteNombre.present) {
      map['remitente_nombre'] = Variable<String>(remitenteNombre.value);
    }
    if (remitenteTelefono.present) {
      map['remitente_telefono'] = Variable<String>(remitenteTelefono.value);
    }
    if (destinatarioNombre.present) {
      map['destinatario_nombre'] = Variable<String>(destinatarioNombre.value);
    }
    if (destinatarioDireccion.present) {
      map['destinatario_direccion'] = Variable<String>(
        destinatarioDireccion.value,
      );
    }
    if (destinatarioTelefono.present) {
      map['destinatario_telefono'] = Variable<String>(
        destinatarioTelefono.value,
      );
    }
    if (notasEntrega.present) {
      map['notas_entrega'] = Variable<String>(notasEntrega.value);
    }
    if (pesoKg.present) {
      map['peso_kg'] = Variable<double>(pesoKg.value);
    }
    if (estado.present) {
      map['estado'] = Variable<String>(estado.value);
    }
    if (choferAsignadoId.present) {
      map['chofer_asignado_id'] = Variable<String>(choferAsignadoId.value);
    }
    if (montoEnvio.present) {
      map['monto_envio'] = Variable<double>(montoEnvio.value);
    }
    if (metodoPago.present) {
      map['metodo_pago'] = Variable<String>(metodoPago.value);
    }
    if (estadoPago.present) {
      map['estado_pago'] = Variable<String>(estadoPago.value);
    }
    if (referenciaPago.present) {
      map['referencia_pago'] = Variable<String>(referenciaPago.value);
    }
    if (comisionServicio.present) {
      map['comision_servicio'] = Variable<double>(comisionServicio.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaquetesCompanion(')
          ..write('id: $id, ')
          ..write('trackingNumber: $trackingNumber, ')
          ..write('remitenteNombre: $remitenteNombre, ')
          ..write('remitenteTelefono: $remitenteTelefono, ')
          ..write('destinatarioNombre: $destinatarioNombre, ')
          ..write('destinatarioDireccion: $destinatarioDireccion, ')
          ..write('destinatarioTelefono: $destinatarioTelefono, ')
          ..write('notasEntrega: $notasEntrega, ')
          ..write('pesoKg: $pesoKg, ')
          ..write('estado: $estado, ')
          ..write('choferAsignadoId: $choferAsignadoId, ')
          ..write('montoEnvio: $montoEnvio, ')
          ..write('metodoPago: $metodoPago, ')
          ..write('estadoPago: $estadoPago, ')
          ..write('referenciaPago: $referenciaPago, ')
          ..write('comisionServicio: $comisionServicio, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventosEntregaTable extends EventosEntrega
    with TableInfo<$EventosEntregaTable, EventosEntregaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventosEntregaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paqueteIdMeta = const VerificationMeta(
    'paqueteId',
  );
  @override
  late final GeneratedColumn<String> paqueteId = GeneratedColumn<String>(
    'paquete_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _choferIdMeta = const VerificationMeta(
    'choferId',
  );
  @override
  late final GeneratedColumn<String> choferId = GeneratedColumn<String>(
    'chofer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _estadoResultanteMeta = const VerificationMeta(
    'estadoResultante',
  );
  @override
  late final GeneratedColumn<String> estadoResultante = GeneratedColumn<String>(
    'estado_resultante',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ENTREGADO'),
  );
  static const VerificationMeta _latitudMeta = const VerificationMeta(
    'latitud',
  );
  @override
  late final GeneratedColumn<double> latitud = GeneratedColumn<double>(
    'latitud',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudMeta = const VerificationMeta(
    'longitud',
  );
  @override
  late final GeneratedColumn<double> longitud = GeneratedColumn<double>(
    'longitud',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fotoEvidenciaUrlMeta = const VerificationMeta(
    'fotoEvidenciaUrl',
  );
  @override
  late final GeneratedColumn<String> fotoEvidenciaUrl = GeneratedColumn<String>(
    'foto_evidencia_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firmaDigitalUrlMeta = const VerificationMeta(
    'firmaDigitalUrl',
  );
  @override
  late final GeneratedColumn<String> firmaDigitalUrl = GeneratedColumn<String>(
    'firma_digital_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _observacionesMeta = const VerificationMeta(
    'observaciones',
  );
  @override
  late final GeneratedColumn<String> observaciones = GeneratedColumn<String>(
    'observaciones',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fechaEventoMeta = const VerificationMeta(
    'fechaEvento',
  );
  @override
  late final GeneratedColumn<DateTime> fechaEvento = GeneratedColumn<DateTime>(
    'fecha_evento',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sincronizadoMeta = const VerificationMeta(
    'sincronizado',
  );
  @override
  late final GeneratedColumn<bool> sincronizado = GeneratedColumn<bool>(
    'sincronizado',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sincronizado" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sincronizadoServidorAtMeta =
      const VerificationMeta('sincronizadoServidorAt');
  @override
  late final GeneratedColumn<DateTime> sincronizadoServidorAt =
      GeneratedColumn<DateTime>(
        'sincronizado_servidor_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    paqueteId,
    choferId,
    estadoResultante,
    latitud,
    longitud,
    fotoEvidenciaUrl,
    firmaDigitalUrl,
    observaciones,
    fechaEvento,
    sincronizado,
    sincronizadoServidorAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'eventos_entrega';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventosEntregaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('paquete_id')) {
      context.handle(
        _paqueteIdMeta,
        paqueteId.isAcceptableOrUnknown(data['paquete_id']!, _paqueteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_paqueteIdMeta);
    }
    if (data.containsKey('chofer_id')) {
      context.handle(
        _choferIdMeta,
        choferId.isAcceptableOrUnknown(data['chofer_id']!, _choferIdMeta),
      );
    } else if (isInserting) {
      context.missing(_choferIdMeta);
    }
    if (data.containsKey('estado_resultante')) {
      context.handle(
        _estadoResultanteMeta,
        estadoResultante.isAcceptableOrUnknown(
          data['estado_resultante']!,
          _estadoResultanteMeta,
        ),
      );
    }
    if (data.containsKey('latitud')) {
      context.handle(
        _latitudMeta,
        latitud.isAcceptableOrUnknown(data['latitud']!, _latitudMeta),
      );
    }
    if (data.containsKey('longitud')) {
      context.handle(
        _longitudMeta,
        longitud.isAcceptableOrUnknown(data['longitud']!, _longitudMeta),
      );
    }
    if (data.containsKey('foto_evidencia_url')) {
      context.handle(
        _fotoEvidenciaUrlMeta,
        fotoEvidenciaUrl.isAcceptableOrUnknown(
          data['foto_evidencia_url']!,
          _fotoEvidenciaUrlMeta,
        ),
      );
    }
    if (data.containsKey('firma_digital_url')) {
      context.handle(
        _firmaDigitalUrlMeta,
        firmaDigitalUrl.isAcceptableOrUnknown(
          data['firma_digital_url']!,
          _firmaDigitalUrlMeta,
        ),
      );
    }
    if (data.containsKey('observaciones')) {
      context.handle(
        _observacionesMeta,
        observaciones.isAcceptableOrUnknown(
          data['observaciones']!,
          _observacionesMeta,
        ),
      );
    }
    if (data.containsKey('fecha_evento')) {
      context.handle(
        _fechaEventoMeta,
        fechaEvento.isAcceptableOrUnknown(
          data['fecha_evento']!,
          _fechaEventoMeta,
        ),
      );
    }
    if (data.containsKey('sincronizado')) {
      context.handle(
        _sincronizadoMeta,
        sincronizado.isAcceptableOrUnknown(
          data['sincronizado']!,
          _sincronizadoMeta,
        ),
      );
    }
    if (data.containsKey('sincronizado_servidor_at')) {
      context.handle(
        _sincronizadoServidorAtMeta,
        sincronizadoServidorAt.isAcceptableOrUnknown(
          data['sincronizado_servidor_at']!,
          _sincronizadoServidorAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventosEntregaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventosEntregaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      paqueteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paquete_id'],
      )!,
      choferId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chofer_id'],
      )!,
      estadoResultante: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estado_resultante'],
      )!,
      latitud: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitud'],
      ),
      longitud: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitud'],
      ),
      fotoEvidenciaUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}foto_evidencia_url'],
      ),
      firmaDigitalUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firma_digital_url'],
      ),
      observaciones: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observaciones'],
      ),
      fechaEvento: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_evento'],
      ),
      sincronizado: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sincronizado'],
      )!,
      sincronizadoServidorAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sincronizado_servidor_at'],
      ),
    );
  }

  @override
  $EventosEntregaTable createAlias(String alias) {
    return $EventosEntregaTable(attachedDatabase, alias);
  }
}

class EventosEntregaData extends DataClass
    implements Insertable<EventosEntregaData> {
  final String id;
  final String paqueteId;
  final String choferId;
  final String estadoResultante;
  final double? latitud;
  final double? longitud;
  final String? fotoEvidenciaUrl;
  final String? firmaDigitalUrl;
  final String? observaciones;
  final DateTime? fechaEvento;
  final bool sincronizado;
  final DateTime? sincronizadoServidorAt;
  const EventosEntregaData({
    required this.id,
    required this.paqueteId,
    required this.choferId,
    required this.estadoResultante,
    this.latitud,
    this.longitud,
    this.fotoEvidenciaUrl,
    this.firmaDigitalUrl,
    this.observaciones,
    this.fechaEvento,
    required this.sincronizado,
    this.sincronizadoServidorAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['paquete_id'] = Variable<String>(paqueteId);
    map['chofer_id'] = Variable<String>(choferId);
    map['estado_resultante'] = Variable<String>(estadoResultante);
    if (!nullToAbsent || latitud != null) {
      map['latitud'] = Variable<double>(latitud);
    }
    if (!nullToAbsent || longitud != null) {
      map['longitud'] = Variable<double>(longitud);
    }
    if (!nullToAbsent || fotoEvidenciaUrl != null) {
      map['foto_evidencia_url'] = Variable<String>(fotoEvidenciaUrl);
    }
    if (!nullToAbsent || firmaDigitalUrl != null) {
      map['firma_digital_url'] = Variable<String>(firmaDigitalUrl);
    }
    if (!nullToAbsent || observaciones != null) {
      map['observaciones'] = Variable<String>(observaciones);
    }
    if (!nullToAbsent || fechaEvento != null) {
      map['fecha_evento'] = Variable<DateTime>(fechaEvento);
    }
    map['sincronizado'] = Variable<bool>(sincronizado);
    if (!nullToAbsent || sincronizadoServidorAt != null) {
      map['sincronizado_servidor_at'] = Variable<DateTime>(
        sincronizadoServidorAt,
      );
    }
    return map;
  }

  EventosEntregaCompanion toCompanion(bool nullToAbsent) {
    return EventosEntregaCompanion(
      id: Value(id),
      paqueteId: Value(paqueteId),
      choferId: Value(choferId),
      estadoResultante: Value(estadoResultante),
      latitud: latitud == null && nullToAbsent
          ? const Value.absent()
          : Value(latitud),
      longitud: longitud == null && nullToAbsent
          ? const Value.absent()
          : Value(longitud),
      fotoEvidenciaUrl: fotoEvidenciaUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(fotoEvidenciaUrl),
      firmaDigitalUrl: firmaDigitalUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(firmaDigitalUrl),
      observaciones: observaciones == null && nullToAbsent
          ? const Value.absent()
          : Value(observaciones),
      fechaEvento: fechaEvento == null && nullToAbsent
          ? const Value.absent()
          : Value(fechaEvento),
      sincronizado: Value(sincronizado),
      sincronizadoServidorAt: sincronizadoServidorAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sincronizadoServidorAt),
    );
  }

  factory EventosEntregaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventosEntregaData(
      id: serializer.fromJson<String>(json['id']),
      paqueteId: serializer.fromJson<String>(json['paqueteId']),
      choferId: serializer.fromJson<String>(json['choferId']),
      estadoResultante: serializer.fromJson<String>(json['estadoResultante']),
      latitud: serializer.fromJson<double?>(json['latitud']),
      longitud: serializer.fromJson<double?>(json['longitud']),
      fotoEvidenciaUrl: serializer.fromJson<String?>(json['fotoEvidenciaUrl']),
      firmaDigitalUrl: serializer.fromJson<String?>(json['firmaDigitalUrl']),
      observaciones: serializer.fromJson<String?>(json['observaciones']),
      fechaEvento: serializer.fromJson<DateTime?>(json['fechaEvento']),
      sincronizado: serializer.fromJson<bool>(json['sincronizado']),
      sincronizadoServidorAt: serializer.fromJson<DateTime?>(
        json['sincronizadoServidorAt'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'paqueteId': serializer.toJson<String>(paqueteId),
      'choferId': serializer.toJson<String>(choferId),
      'estadoResultante': serializer.toJson<String>(estadoResultante),
      'latitud': serializer.toJson<double?>(latitud),
      'longitud': serializer.toJson<double?>(longitud),
      'fotoEvidenciaUrl': serializer.toJson<String?>(fotoEvidenciaUrl),
      'firmaDigitalUrl': serializer.toJson<String?>(firmaDigitalUrl),
      'observaciones': serializer.toJson<String?>(observaciones),
      'fechaEvento': serializer.toJson<DateTime?>(fechaEvento),
      'sincronizado': serializer.toJson<bool>(sincronizado),
      'sincronizadoServidorAt': serializer.toJson<DateTime?>(
        sincronizadoServidorAt,
      ),
    };
  }

  EventosEntregaData copyWith({
    String? id,
    String? paqueteId,
    String? choferId,
    String? estadoResultante,
    Value<double?> latitud = const Value.absent(),
    Value<double?> longitud = const Value.absent(),
    Value<String?> fotoEvidenciaUrl = const Value.absent(),
    Value<String?> firmaDigitalUrl = const Value.absent(),
    Value<String?> observaciones = const Value.absent(),
    Value<DateTime?> fechaEvento = const Value.absent(),
    bool? sincronizado,
    Value<DateTime?> sincronizadoServidorAt = const Value.absent(),
  }) => EventosEntregaData(
    id: id ?? this.id,
    paqueteId: paqueteId ?? this.paqueteId,
    choferId: choferId ?? this.choferId,
    estadoResultante: estadoResultante ?? this.estadoResultante,
    latitud: latitud.present ? latitud.value : this.latitud,
    longitud: longitud.present ? longitud.value : this.longitud,
    fotoEvidenciaUrl: fotoEvidenciaUrl.present
        ? fotoEvidenciaUrl.value
        : this.fotoEvidenciaUrl,
    firmaDigitalUrl: firmaDigitalUrl.present
        ? firmaDigitalUrl.value
        : this.firmaDigitalUrl,
    observaciones: observaciones.present
        ? observaciones.value
        : this.observaciones,
    fechaEvento: fechaEvento.present ? fechaEvento.value : this.fechaEvento,
    sincronizado: sincronizado ?? this.sincronizado,
    sincronizadoServidorAt: sincronizadoServidorAt.present
        ? sincronizadoServidorAt.value
        : this.sincronizadoServidorAt,
  );
  EventosEntregaData copyWithCompanion(EventosEntregaCompanion data) {
    return EventosEntregaData(
      id: data.id.present ? data.id.value : this.id,
      paqueteId: data.paqueteId.present ? data.paqueteId.value : this.paqueteId,
      choferId: data.choferId.present ? data.choferId.value : this.choferId,
      estadoResultante: data.estadoResultante.present
          ? data.estadoResultante.value
          : this.estadoResultante,
      latitud: data.latitud.present ? data.latitud.value : this.latitud,
      longitud: data.longitud.present ? data.longitud.value : this.longitud,
      fotoEvidenciaUrl: data.fotoEvidenciaUrl.present
          ? data.fotoEvidenciaUrl.value
          : this.fotoEvidenciaUrl,
      firmaDigitalUrl: data.firmaDigitalUrl.present
          ? data.firmaDigitalUrl.value
          : this.firmaDigitalUrl,
      observaciones: data.observaciones.present
          ? data.observaciones.value
          : this.observaciones,
      fechaEvento: data.fechaEvento.present
          ? data.fechaEvento.value
          : this.fechaEvento,
      sincronizado: data.sincronizado.present
          ? data.sincronizado.value
          : this.sincronizado,
      sincronizadoServidorAt: data.sincronizadoServidorAt.present
          ? data.sincronizadoServidorAt.value
          : this.sincronizadoServidorAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventosEntregaData(')
          ..write('id: $id, ')
          ..write('paqueteId: $paqueteId, ')
          ..write('choferId: $choferId, ')
          ..write('estadoResultante: $estadoResultante, ')
          ..write('latitud: $latitud, ')
          ..write('longitud: $longitud, ')
          ..write('fotoEvidenciaUrl: $fotoEvidenciaUrl, ')
          ..write('firmaDigitalUrl: $firmaDigitalUrl, ')
          ..write('observaciones: $observaciones, ')
          ..write('fechaEvento: $fechaEvento, ')
          ..write('sincronizado: $sincronizado, ')
          ..write('sincronizadoServidorAt: $sincronizadoServidorAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    paqueteId,
    choferId,
    estadoResultante,
    latitud,
    longitud,
    fotoEvidenciaUrl,
    firmaDigitalUrl,
    observaciones,
    fechaEvento,
    sincronizado,
    sincronizadoServidorAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventosEntregaData &&
          other.id == this.id &&
          other.paqueteId == this.paqueteId &&
          other.choferId == this.choferId &&
          other.estadoResultante == this.estadoResultante &&
          other.latitud == this.latitud &&
          other.longitud == this.longitud &&
          other.fotoEvidenciaUrl == this.fotoEvidenciaUrl &&
          other.firmaDigitalUrl == this.firmaDigitalUrl &&
          other.observaciones == this.observaciones &&
          other.fechaEvento == this.fechaEvento &&
          other.sincronizado == this.sincronizado &&
          other.sincronizadoServidorAt == this.sincronizadoServidorAt);
}

class EventosEntregaCompanion extends UpdateCompanion<EventosEntregaData> {
  final Value<String> id;
  final Value<String> paqueteId;
  final Value<String> choferId;
  final Value<String> estadoResultante;
  final Value<double?> latitud;
  final Value<double?> longitud;
  final Value<String?> fotoEvidenciaUrl;
  final Value<String?> firmaDigitalUrl;
  final Value<String?> observaciones;
  final Value<DateTime?> fechaEvento;
  final Value<bool> sincronizado;
  final Value<DateTime?> sincronizadoServidorAt;
  final Value<int> rowid;
  const EventosEntregaCompanion({
    this.id = const Value.absent(),
    this.paqueteId = const Value.absent(),
    this.choferId = const Value.absent(),
    this.estadoResultante = const Value.absent(),
    this.latitud = const Value.absent(),
    this.longitud = const Value.absent(),
    this.fotoEvidenciaUrl = const Value.absent(),
    this.firmaDigitalUrl = const Value.absent(),
    this.observaciones = const Value.absent(),
    this.fechaEvento = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.sincronizadoServidorAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventosEntregaCompanion.insert({
    required String id,
    required String paqueteId,
    required String choferId,
    this.estadoResultante = const Value.absent(),
    this.latitud = const Value.absent(),
    this.longitud = const Value.absent(),
    this.fotoEvidenciaUrl = const Value.absent(),
    this.firmaDigitalUrl = const Value.absent(),
    this.observaciones = const Value.absent(),
    this.fechaEvento = const Value.absent(),
    this.sincronizado = const Value.absent(),
    this.sincronizadoServidorAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       paqueteId = Value(paqueteId),
       choferId = Value(choferId);
  static Insertable<EventosEntregaData> custom({
    Expression<String>? id,
    Expression<String>? paqueteId,
    Expression<String>? choferId,
    Expression<String>? estadoResultante,
    Expression<double>? latitud,
    Expression<double>? longitud,
    Expression<String>? fotoEvidenciaUrl,
    Expression<String>? firmaDigitalUrl,
    Expression<String>? observaciones,
    Expression<DateTime>? fechaEvento,
    Expression<bool>? sincronizado,
    Expression<DateTime>? sincronizadoServidorAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (paqueteId != null) 'paquete_id': paqueteId,
      if (choferId != null) 'chofer_id': choferId,
      if (estadoResultante != null) 'estado_resultante': estadoResultante,
      if (latitud != null) 'latitud': latitud,
      if (longitud != null) 'longitud': longitud,
      if (fotoEvidenciaUrl != null) 'foto_evidencia_url': fotoEvidenciaUrl,
      if (firmaDigitalUrl != null) 'firma_digital_url': firmaDigitalUrl,
      if (observaciones != null) 'observaciones': observaciones,
      if (fechaEvento != null) 'fecha_evento': fechaEvento,
      if (sincronizado != null) 'sincronizado': sincronizado,
      if (sincronizadoServidorAt != null)
        'sincronizado_servidor_at': sincronizadoServidorAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventosEntregaCompanion copyWith({
    Value<String>? id,
    Value<String>? paqueteId,
    Value<String>? choferId,
    Value<String>? estadoResultante,
    Value<double?>? latitud,
    Value<double?>? longitud,
    Value<String?>? fotoEvidenciaUrl,
    Value<String?>? firmaDigitalUrl,
    Value<String?>? observaciones,
    Value<DateTime?>? fechaEvento,
    Value<bool>? sincronizado,
    Value<DateTime?>? sincronizadoServidorAt,
    Value<int>? rowid,
  }) {
    return EventosEntregaCompanion(
      id: id ?? this.id,
      paqueteId: paqueteId ?? this.paqueteId,
      choferId: choferId ?? this.choferId,
      estadoResultante: estadoResultante ?? this.estadoResultante,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      fotoEvidenciaUrl: fotoEvidenciaUrl ?? this.fotoEvidenciaUrl,
      firmaDigitalUrl: firmaDigitalUrl ?? this.firmaDigitalUrl,
      observaciones: observaciones ?? this.observaciones,
      fechaEvento: fechaEvento ?? this.fechaEvento,
      sincronizado: sincronizado ?? this.sincronizado,
      sincronizadoServidorAt:
          sincronizadoServidorAt ?? this.sincronizadoServidorAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (paqueteId.present) {
      map['paquete_id'] = Variable<String>(paqueteId.value);
    }
    if (choferId.present) {
      map['chofer_id'] = Variable<String>(choferId.value);
    }
    if (estadoResultante.present) {
      map['estado_resultante'] = Variable<String>(estadoResultante.value);
    }
    if (latitud.present) {
      map['latitud'] = Variable<double>(latitud.value);
    }
    if (longitud.present) {
      map['longitud'] = Variable<double>(longitud.value);
    }
    if (fotoEvidenciaUrl.present) {
      map['foto_evidencia_url'] = Variable<String>(fotoEvidenciaUrl.value);
    }
    if (firmaDigitalUrl.present) {
      map['firma_digital_url'] = Variable<String>(firmaDigitalUrl.value);
    }
    if (observaciones.present) {
      map['observaciones'] = Variable<String>(observaciones.value);
    }
    if (fechaEvento.present) {
      map['fecha_evento'] = Variable<DateTime>(fechaEvento.value);
    }
    if (sincronizado.present) {
      map['sincronizado'] = Variable<bool>(sincronizado.value);
    }
    if (sincronizadoServidorAt.present) {
      map['sincronizado_servidor_at'] = Variable<DateTime>(
        sincronizadoServidorAt.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventosEntregaCompanion(')
          ..write('id: $id, ')
          ..write('paqueteId: $paqueteId, ')
          ..write('choferId: $choferId, ')
          ..write('estadoResultante: $estadoResultante, ')
          ..write('latitud: $latitud, ')
          ..write('longitud: $longitud, ')
          ..write('fotoEvidenciaUrl: $fotoEvidenciaUrl, ')
          ..write('firmaDigitalUrl: $firmaDigitalUrl, ')
          ..write('observaciones: $observaciones, ')
          ..write('fechaEvento: $fechaEvento, ')
          ..write('sincronizado: $sincronizado, ')
          ..write('sincronizadoServidorAt: $sincronizadoServidorAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PaquetesTable paquetes = $PaquetesTable(this);
  late final $EventosEntregaTable eventosEntrega = $EventosEntregaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    paquetes,
    eventosEntrega,
  ];
}

typedef $$PaquetesTableCreateCompanionBuilder =
    PaquetesCompanion Function({
      required String id,
      required String trackingNumber,
      Value<String> remitenteNombre,
      Value<String?> remitenteTelefono,
      Value<String> destinatarioNombre,
      Value<String> destinatarioDireccion,
      Value<String> destinatarioTelefono,
      Value<String?> notasEntrega,
      Value<double> pesoKg,
      Value<String> estado,
      Value<String?> choferAsignadoId,
      Value<double?> montoEnvio,
      Value<String?> metodoPago,
      Value<String> estadoPago,
      Value<String?> referenciaPago,
      Value<double?> comisionServicio,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$PaquetesTableUpdateCompanionBuilder =
    PaquetesCompanion Function({
      Value<String> id,
      Value<String> trackingNumber,
      Value<String> remitenteNombre,
      Value<String?> remitenteTelefono,
      Value<String> destinatarioNombre,
      Value<String> destinatarioDireccion,
      Value<String> destinatarioTelefono,
      Value<String?> notasEntrega,
      Value<double> pesoKg,
      Value<String> estado,
      Value<String?> choferAsignadoId,
      Value<double?> montoEnvio,
      Value<String?> metodoPago,
      Value<String> estadoPago,
      Value<String?> referenciaPago,
      Value<double?> comisionServicio,
      Value<DateTime?> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$PaquetesTableFilterComposer
    extends Composer<_$AppDatabase, $PaquetesTable> {
  $$PaquetesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackingNumber => $composableBuilder(
    column: $table.trackingNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remitenteNombre => $composableBuilder(
    column: $table.remitenteNombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remitenteTelefono => $composableBuilder(
    column: $table.remitenteTelefono,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinatarioNombre => $composableBuilder(
    column: $table.destinatarioNombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinatarioDireccion => $composableBuilder(
    column: $table.destinatarioDireccion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinatarioTelefono => $composableBuilder(
    column: $table.destinatarioTelefono,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notasEntrega => $composableBuilder(
    column: $table.notasEntrega,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pesoKg => $composableBuilder(
    column: $table.pesoKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get choferAsignadoId => $composableBuilder(
    column: $table.choferAsignadoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get montoEnvio => $composableBuilder(
    column: $table.montoEnvio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metodoPago => $composableBuilder(
    column: $table.metodoPago,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estadoPago => $composableBuilder(
    column: $table.estadoPago,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenciaPago => $composableBuilder(
    column: $table.referenciaPago,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get comisionServicio => $composableBuilder(
    column: $table.comisionServicio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PaquetesTableOrderingComposer
    extends Composer<_$AppDatabase, $PaquetesTable> {
  $$PaquetesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackingNumber => $composableBuilder(
    column: $table.trackingNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remitenteNombre => $composableBuilder(
    column: $table.remitenteNombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remitenteTelefono => $composableBuilder(
    column: $table.remitenteTelefono,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinatarioNombre => $composableBuilder(
    column: $table.destinatarioNombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinatarioDireccion => $composableBuilder(
    column: $table.destinatarioDireccion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinatarioTelefono => $composableBuilder(
    column: $table.destinatarioTelefono,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notasEntrega => $composableBuilder(
    column: $table.notasEntrega,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pesoKg => $composableBuilder(
    column: $table.pesoKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get choferAsignadoId => $composableBuilder(
    column: $table.choferAsignadoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get montoEnvio => $composableBuilder(
    column: $table.montoEnvio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metodoPago => $composableBuilder(
    column: $table.metodoPago,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estadoPago => $composableBuilder(
    column: $table.estadoPago,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenciaPago => $composableBuilder(
    column: $table.referenciaPago,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get comisionServicio => $composableBuilder(
    column: $table.comisionServicio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PaquetesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaquetesTable> {
  $$PaquetesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trackingNumber => $composableBuilder(
    column: $table.trackingNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remitenteNombre => $composableBuilder(
    column: $table.remitenteNombre,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remitenteTelefono => $composableBuilder(
    column: $table.remitenteTelefono,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destinatarioNombre => $composableBuilder(
    column: $table.destinatarioNombre,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destinatarioDireccion => $composableBuilder(
    column: $table.destinatarioDireccion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destinatarioTelefono => $composableBuilder(
    column: $table.destinatarioTelefono,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notasEntrega => $composableBuilder(
    column: $table.notasEntrega,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pesoKg =>
      $composableBuilder(column: $table.pesoKg, builder: (column) => column);

  GeneratedColumn<String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);

  GeneratedColumn<String> get choferAsignadoId => $composableBuilder(
    column: $table.choferAsignadoId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get montoEnvio => $composableBuilder(
    column: $table.montoEnvio,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metodoPago => $composableBuilder(
    column: $table.metodoPago,
    builder: (column) => column,
  );

  GeneratedColumn<String> get estadoPago => $composableBuilder(
    column: $table.estadoPago,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referenciaPago => $composableBuilder(
    column: $table.referenciaPago,
    builder: (column) => column,
  );

  GeneratedColumn<double> get comisionServicio => $composableBuilder(
    column: $table.comisionServicio,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PaquetesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaquetesTable,
          Paquete,
          $$PaquetesTableFilterComposer,
          $$PaquetesTableOrderingComposer,
          $$PaquetesTableAnnotationComposer,
          $$PaquetesTableCreateCompanionBuilder,
          $$PaquetesTableUpdateCompanionBuilder,
          (Paquete, BaseReferences<_$AppDatabase, $PaquetesTable, Paquete>),
          Paquete,
          PrefetchHooks Function()
        > {
  $$PaquetesTableTableManager(_$AppDatabase db, $PaquetesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaquetesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaquetesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaquetesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> trackingNumber = const Value.absent(),
                Value<String> remitenteNombre = const Value.absent(),
                Value<String?> remitenteTelefono = const Value.absent(),
                Value<String> destinatarioNombre = const Value.absent(),
                Value<String> destinatarioDireccion = const Value.absent(),
                Value<String> destinatarioTelefono = const Value.absent(),
                Value<String?> notasEntrega = const Value.absent(),
                Value<double> pesoKg = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<String?> choferAsignadoId = const Value.absent(),
                Value<double?> montoEnvio = const Value.absent(),
                Value<String?> metodoPago = const Value.absent(),
                Value<String> estadoPago = const Value.absent(),
                Value<String?> referenciaPago = const Value.absent(),
                Value<double?> comisionServicio = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaquetesCompanion(
                id: id,
                trackingNumber: trackingNumber,
                remitenteNombre: remitenteNombre,
                remitenteTelefono: remitenteTelefono,
                destinatarioNombre: destinatarioNombre,
                destinatarioDireccion: destinatarioDireccion,
                destinatarioTelefono: destinatarioTelefono,
                notasEntrega: notasEntrega,
                pesoKg: pesoKg,
                estado: estado,
                choferAsignadoId: choferAsignadoId,
                montoEnvio: montoEnvio,
                metodoPago: metodoPago,
                estadoPago: estadoPago,
                referenciaPago: referenciaPago,
                comisionServicio: comisionServicio,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String trackingNumber,
                Value<String> remitenteNombre = const Value.absent(),
                Value<String?> remitenteTelefono = const Value.absent(),
                Value<String> destinatarioNombre = const Value.absent(),
                Value<String> destinatarioDireccion = const Value.absent(),
                Value<String> destinatarioTelefono = const Value.absent(),
                Value<String?> notasEntrega = const Value.absent(),
                Value<double> pesoKg = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<String?> choferAsignadoId = const Value.absent(),
                Value<double?> montoEnvio = const Value.absent(),
                Value<String?> metodoPago = const Value.absent(),
                Value<String> estadoPago = const Value.absent(),
                Value<String?> referenciaPago = const Value.absent(),
                Value<double?> comisionServicio = const Value.absent(),
                Value<DateTime?> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaquetesCompanion.insert(
                id: id,
                trackingNumber: trackingNumber,
                remitenteNombre: remitenteNombre,
                remitenteTelefono: remitenteTelefono,
                destinatarioNombre: destinatarioNombre,
                destinatarioDireccion: destinatarioDireccion,
                destinatarioTelefono: destinatarioTelefono,
                notasEntrega: notasEntrega,
                pesoKg: pesoKg,
                estado: estado,
                choferAsignadoId: choferAsignadoId,
                montoEnvio: montoEnvio,
                metodoPago: metodoPago,
                estadoPago: estadoPago,
                referenciaPago: referenciaPago,
                comisionServicio: comisionServicio,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PaquetesTable, Paquete>(table),
                  BaseReferences<_$AppDatabase, $PaquetesTable, Paquete>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PaquetesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaquetesTable,
      Paquete,
      $$PaquetesTableFilterComposer,
      $$PaquetesTableOrderingComposer,
      $$PaquetesTableAnnotationComposer,
      $$PaquetesTableCreateCompanionBuilder,
      $$PaquetesTableUpdateCompanionBuilder,
      (Paquete, BaseReferences<_$AppDatabase, $PaquetesTable, Paquete>),
      Paquete,
      PrefetchHooks Function()
    >;
typedef $$EventosEntregaTableCreateCompanionBuilder =
    EventosEntregaCompanion Function({
      required String id,
      required String paqueteId,
      required String choferId,
      Value<String> estadoResultante,
      Value<double?> latitud,
      Value<double?> longitud,
      Value<String?> fotoEvidenciaUrl,
      Value<String?> firmaDigitalUrl,
      Value<String?> observaciones,
      Value<DateTime?> fechaEvento,
      Value<bool> sincronizado,
      Value<DateTime?> sincronizadoServidorAt,
      Value<int> rowid,
    });
typedef $$EventosEntregaTableUpdateCompanionBuilder =
    EventosEntregaCompanion Function({
      Value<String> id,
      Value<String> paqueteId,
      Value<String> choferId,
      Value<String> estadoResultante,
      Value<double?> latitud,
      Value<double?> longitud,
      Value<String?> fotoEvidenciaUrl,
      Value<String?> firmaDigitalUrl,
      Value<String?> observaciones,
      Value<DateTime?> fechaEvento,
      Value<bool> sincronizado,
      Value<DateTime?> sincronizadoServidorAt,
      Value<int> rowid,
    });

class $$EventosEntregaTableFilterComposer
    extends Composer<_$AppDatabase, $EventosEntregaTable> {
  $$EventosEntregaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paqueteId => $composableBuilder(
    column: $table.paqueteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get choferId => $composableBuilder(
    column: $table.choferId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estadoResultante => $composableBuilder(
    column: $table.estadoResultante,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitud => $composableBuilder(
    column: $table.latitud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitud => $composableBuilder(
    column: $table.longitud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fotoEvidenciaUrl => $composableBuilder(
    column: $table.fotoEvidenciaUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firmaDigitalUrl => $composableBuilder(
    column: $table.firmaDigitalUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observaciones => $composableBuilder(
    column: $table.observaciones,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaEvento => $composableBuilder(
    column: $table.fechaEvento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sincronizado => $composableBuilder(
    column: $table.sincronizado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sincronizadoServidorAt => $composableBuilder(
    column: $table.sincronizadoServidorAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventosEntregaTableOrderingComposer
    extends Composer<_$AppDatabase, $EventosEntregaTable> {
  $$EventosEntregaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paqueteId => $composableBuilder(
    column: $table.paqueteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get choferId => $composableBuilder(
    column: $table.choferId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estadoResultante => $composableBuilder(
    column: $table.estadoResultante,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitud => $composableBuilder(
    column: $table.latitud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitud => $composableBuilder(
    column: $table.longitud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fotoEvidenciaUrl => $composableBuilder(
    column: $table.fotoEvidenciaUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firmaDigitalUrl => $composableBuilder(
    column: $table.firmaDigitalUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observaciones => $composableBuilder(
    column: $table.observaciones,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaEvento => $composableBuilder(
    column: $table.fechaEvento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sincronizado => $composableBuilder(
    column: $table.sincronizado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sincronizadoServidorAt => $composableBuilder(
    column: $table.sincronizadoServidorAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventosEntregaTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventosEntregaTable> {
  $$EventosEntregaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get paqueteId =>
      $composableBuilder(column: $table.paqueteId, builder: (column) => column);

  GeneratedColumn<String> get choferId =>
      $composableBuilder(column: $table.choferId, builder: (column) => column);

  GeneratedColumn<String> get estadoResultante => $composableBuilder(
    column: $table.estadoResultante,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitud =>
      $composableBuilder(column: $table.latitud, builder: (column) => column);

  GeneratedColumn<double> get longitud =>
      $composableBuilder(column: $table.longitud, builder: (column) => column);

  GeneratedColumn<String> get fotoEvidenciaUrl => $composableBuilder(
    column: $table.fotoEvidenciaUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get firmaDigitalUrl => $composableBuilder(
    column: $table.firmaDigitalUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get observaciones => $composableBuilder(
    column: $table.observaciones,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaEvento => $composableBuilder(
    column: $table.fechaEvento,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get sincronizado => $composableBuilder(
    column: $table.sincronizado,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get sincronizadoServidorAt => $composableBuilder(
    column: $table.sincronizadoServidorAt,
    builder: (column) => column,
  );
}

class $$EventosEntregaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventosEntregaTable,
          EventosEntregaData,
          $$EventosEntregaTableFilterComposer,
          $$EventosEntregaTableOrderingComposer,
          $$EventosEntregaTableAnnotationComposer,
          $$EventosEntregaTableCreateCompanionBuilder,
          $$EventosEntregaTableUpdateCompanionBuilder,
          (
            EventosEntregaData,
            BaseReferences<
              _$AppDatabase,
              $EventosEntregaTable,
              EventosEntregaData
            >,
          ),
          EventosEntregaData,
          PrefetchHooks Function()
        > {
  $$EventosEntregaTableTableManager(
    _$AppDatabase db,
    $EventosEntregaTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventosEntregaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventosEntregaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventosEntregaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> paqueteId = const Value.absent(),
                Value<String> choferId = const Value.absent(),
                Value<String> estadoResultante = const Value.absent(),
                Value<double?> latitud = const Value.absent(),
                Value<double?> longitud = const Value.absent(),
                Value<String?> fotoEvidenciaUrl = const Value.absent(),
                Value<String?> firmaDigitalUrl = const Value.absent(),
                Value<String?> observaciones = const Value.absent(),
                Value<DateTime?> fechaEvento = const Value.absent(),
                Value<bool> sincronizado = const Value.absent(),
                Value<DateTime?> sincronizadoServidorAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventosEntregaCompanion(
                id: id,
                paqueteId: paqueteId,
                choferId: choferId,
                estadoResultante: estadoResultante,
                latitud: latitud,
                longitud: longitud,
                fotoEvidenciaUrl: fotoEvidenciaUrl,
                firmaDigitalUrl: firmaDigitalUrl,
                observaciones: observaciones,
                fechaEvento: fechaEvento,
                sincronizado: sincronizado,
                sincronizadoServidorAt: sincronizadoServidorAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String paqueteId,
                required String choferId,
                Value<String> estadoResultante = const Value.absent(),
                Value<double?> latitud = const Value.absent(),
                Value<double?> longitud = const Value.absent(),
                Value<String?> fotoEvidenciaUrl = const Value.absent(),
                Value<String?> firmaDigitalUrl = const Value.absent(),
                Value<String?> observaciones = const Value.absent(),
                Value<DateTime?> fechaEvento = const Value.absent(),
                Value<bool> sincronizado = const Value.absent(),
                Value<DateTime?> sincronizadoServidorAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventosEntregaCompanion.insert(
                id: id,
                paqueteId: paqueteId,
                choferId: choferId,
                estadoResultante: estadoResultante,
                latitud: latitud,
                longitud: longitud,
                fotoEvidenciaUrl: fotoEvidenciaUrl,
                firmaDigitalUrl: firmaDigitalUrl,
                observaciones: observaciones,
                fechaEvento: fechaEvento,
                sincronizado: sincronizado,
                sincronizadoServidorAt: sincronizadoServidorAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EventosEntregaTable, EventosEntregaData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $EventosEntregaTable,
                    EventosEntregaData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventosEntregaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventosEntregaTable,
      EventosEntregaData,
      $$EventosEntregaTableFilterComposer,
      $$EventosEntregaTableOrderingComposer,
      $$EventosEntregaTableAnnotationComposer,
      $$EventosEntregaTableCreateCompanionBuilder,
      $$EventosEntregaTableUpdateCompanionBuilder,
      (
        EventosEntregaData,
        BaseReferences<_$AppDatabase, $EventosEntregaTable, EventosEntregaData>,
      ),
      EventosEntregaData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PaquetesTableTableManager get paquetes =>
      $$PaquetesTableTableManager(_db, _db.paquetes);
  $$EventosEntregaTableTableManager get eventosEntrega =>
      $$EventosEntregaTableTableManager(_db, _db.eventosEntrega);
}
