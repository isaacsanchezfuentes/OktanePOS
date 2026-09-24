import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../data/datasources/local_storage.dart';
import '../data/models/paquete_model.dart';
import '../core/api/supabase_config.dart';
import '../core/api/api_client.dart';

class PaquetesProvider extends ChangeNotifier {
  final AppDatabase db;
  final ApiClient apiClient;
  final _supabase = Supabase.instance.client;

  String? rutaIdActiva;
  String? codigoZonaActiva;
  String? viajeIdActivo; // 🚚 ID de viaje para manifiestos

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? lastError;

  PaquetesProvider({required this.db, required this.apiClient});

  void setRutaActiva(String id, String zona) {
    rutaIdActiva = id;
    codigoZonaActiva = zona;
    notifyListeners();
  }

  void setViajeActivo(String? id) {
    viajeIdActivo = id;
    notifyListeners();
  }

  Stream<List<Paquete>> watchRuta(String choferId) {
    return db.watchPaquetesEnRuta(choferId);
  }

  Future<void> refreshRuta(String choferId) async {
    _isLoading = true;
    lastError = null;
    notifyListeners();
    try {
      var query = _supabase.from('paquetes').select();
      
      // 🛠️ FILTRADO DINÁMICO: Por viaje activo o por ruta
      if (viajeIdActivo != null) {
        query = query.eq('viaje_id', viajeIdActivo as Object);
      } else if (rutaIdActiva != null) {
        query = query.eq('ruta_id', rutaIdActiva as Object);
      }

      final List<dynamic> response = await query;

      for (var item in response) {
        final model = PaqueteModel.fromJson(item);
        await db.insertPaquete(PaquetesCompanion(
          id: Value(model.id),
          trackingNumber: Value(model.trackingNumber),
          remitenteNombre: Value(model.remitenteNombre),
          destinatarioNombre: Value(model.destinatarioNombre),
          destinatarioDireccion: Value(model.destinatarioDireccion),
          destinatarioTelefono: Value(model.destinatarioTelefono),
          pesoKg: Value(model.pesoKg),
          estado: Value(model.estado.name.toUpperCase()),
          choferAsignadoId: Value(model.choferAsignadoId),
          montoEnvio: Value(model.montoEnvio),
          estadoPago: Value(model.estadoPago.name.toUpperCase()),
        ));
      }
    } catch (e) {
      lastError = e.toString();
      debugPrint('Error sync: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> confirmarEntregaLocal({
    required String trackingNumber,
    required String paqueteId,
    required String choferId,
    required String fotoRuta,
    String? observaciones,
  }) async {
    final String eventoId = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      await db.insertEvento(EventosEntregaCompanion(
        id: Value(eventoId),
        paqueteId: Value(paqueteId),
        choferId: Value(choferId),
        estadoResultante: const Value('ENTREGADO'),
        fotoEvidenciaUrl: Value(fotoRuta),
        observaciones: Value(observaciones),
        fechaEvento: Value(DateTime.now()),
        sincronizado: const Value(false),
      ));
      
      await (db.update(db.paquetes)..where((t) => t.id.equals(paqueteId))).write(
        const PaquetesCompanion(estado: Value('ENTREGADO'))
      );

      // 🛠️ ESPERAR LA SINCRONIZACIÓN COMPLETA ANTES DE RETORNAR A LA UI
      await _sincronizarEnBackground(eventoId, trackingNumber, paqueteId, choferId, fotoRuta, observaciones);
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _sincronizarEnBackground(String id, String tracking, String pId, String cId, String fRuta, String? obs) async {
    debugPrint("📡 [SYNC START]: Procesando guía $tracking...");
    try {
      String? publicUrl;
      if (fRuta.isNotEmpty) {
        debugPrint("📡 [STEP 1]: Subiendo foto a Supabase Storage...");
        final file = File(fRuta);
        final String cleanTracking = tracking.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        final String fileName = 'evid_${cleanTracking}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        await _supabase.storage.from(SupabaseConfig.bucketName).upload(fileName, file);
        publicUrl = _supabase.storage.from(SupabaseConfig.bucketName).getPublicUrl(fileName);
        debugPrint("📡 [STEP 2]: Foto lista en: $publicUrl");
      }

      debugPrint("📡 [STEP 3]: Insertando registro en eventos_entrega...");
      final Map<String, dynamic> eventoData = {
        'paquete_id': pId,
        'estado_resultante': 'ENTREGADO',
        'foto_evidencia_url': publicUrl,
        'observaciones': obs,
      };

      if (cId.isNotEmpty && !cId.startsWith('00000000')) {
        eventoData['chofer_id'] = cId;
      }

      await _supabase.from('eventos_entrega').insert(eventoData);
      
      debugPrint("📡 [STEP 5]: Actualizando estado del paquete...");
      // 🛠️ ACTUALIZACIÓN EXACTA POR TRACKING NUMBER (GARANTIZA REFLEJO EN SUPABASE)
      await _supabase.from('paquetes').update({'estado': 'ENTREGADO'}).eq('tracking_number', tracking);
      
      debugPrint("📡 [STEP 6]: Marcando como sincronizado localmente...");
      await db.markAsSynced(id);
      
      debugPrint("✅ [SYNC SUCCESS]: Datos en la nube para guía $tracking");
    } catch (e) {
      debugPrint("❌ FALLO SYNC BACKGROUND (ERROR REAL): $e");
      rethrow;
    }
  }

  Future<bool> procesarPago({required String paqueteId, required MetodoPago metodo, required double monto}) async {
    try {
      await _supabase.from('paquetes').update({
        'estado_pago': 'PAGADO', 'estado': 'RECIBIDO', 'monto_envio': monto,
      }).eq('id', paqueteId);
      return true;
    } catch (e) { return false; }
  }
}
