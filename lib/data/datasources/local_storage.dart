import 'package:drift/drift.dart';
// IMPORTACIÓN CONDICIONAL
import 'db_stub.dart'
    if (dart.library.io) 'db_mobile.dart'
    if (dart.library.html) 'db_web.dart';

part 'local_storage.g.dart';

class Paquetes extends Table {
  TextColumn get id => text()();
  TextColumn get trackingNumber => text().unique()();
  TextColumn get remitenteNombre => text().withDefault(const Constant(''))();
  TextColumn get remitenteTelefono => text().nullable()();
  TextColumn get destinatarioNombre => text().withDefault(const Constant(''))();
  TextColumn get destinatarioDireccion => text().withDefault(const Constant(''))();
  TextColumn get destinatarioTelefono => text().withDefault(const Constant(''))();
  TextColumn get notasEntrega => text().nullable()();
  RealColumn get pesoKg => real().withDefault(const Constant(1.0))();
  
  // Almacenamos como Texto para que coincida con los Strings de Supabase (Mayúsculas)
  TextColumn get estado => text().withDefault(const Constant('RECIBIDO'))();
  TextColumn get choferAsignadoId => text().nullable()();

  // Campos de Pago
  RealColumn get montoEnvio => real().nullable()();
  TextColumn get metodoPago => text().nullable()();
  TextColumn get estadoPago => text().withDefault(const Constant('POR_PAGAR'))();
  TextColumn get referenciaPago => text().nullable()();
  RealColumn get comisionServicio => real().nullable()();

  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class EventosEntrega extends Table {
  TextColumn get id => text()();
  TextColumn get paqueteId => text()(); 
  TextColumn get choferId => text()();
  TextColumn get estadoResultante => text().withDefault(const Constant('ENTREGADO'))();
  RealColumn get latitud => real().nullable()();
  RealColumn get longitud => real().nullable()();
  TextColumn get fotoEvidenciaUrl => text().nullable()();
  TextColumn get firmaDigitalUrl => text().nullable()();
  TextColumn get observaciones => text().nullable()();
  DateTimeColumn get fechaEvento => dateTime().nullable()();
  
  BoolColumn get sincronizado => boolean().withDefault(const Constant(false))();
  DateTimeColumn get sincronizadoServidorAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Paquetes, EventosEntrega])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      await m.createAll();
    },
  );

  Future<List<Paquete>> getAllPaquetes() => select(paquetes).get();
  Stream<List<Paquete>> watchPaquetesEnRuta(String choferId) {
    return (select(paquetes)
          ..where((t) => t.choferAsignadoId.equals(choferId)))
        .watch();
  }

  Future insertPaquete(PaquetesCompanion paquete) => into(paquetes).insertOnConflictUpdate(paquete);
  Future insertEvento(EventosEntregaCompanion evento) => into(eventosEntrega).insert(evento);
  Future<List<EventosEntregaData>> getUnsyncedEventos() {
    return (select(eventosEntrega)..where((t) => t.sincronizado.equals(false))).get();
  }

  Future markAsSynced(String id) {
    return (update(eventosEntrega)..where((t) => t.id.equals(id))).write(
      EventosEntregaCompanion(
        sincronizado: const Value(true),
        sincronizadoServidorAt: Value(DateTime.now()),
      ),
    );
  }
}
