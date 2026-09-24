import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/api/api_client.dart';

enum AuthStatus { authenticated, unauthenticated, authenticating }

class AuthProvider extends ChangeNotifier {
  final ApiClient apiClient;
  final FlutterSecureStorage storage;

  AuthStatus _status = AuthStatus.unauthenticated;
  String? _userId;
  String? _rol;

  AuthStatus get status => _status;
  String? get userId => _userId ?? Supabase.instance.client.auth.currentUser?.id;

  // 🛡️ Getter único y blindado: detecta ADMIN automáticamente
  String? get rol {
    if (_rol != null) return _rol;
    final user = Supabase.instance.client.auth.currentUser;
    if (user?.email != null && user!.email!.toLowerCase().contains('admin')) {
      return 'ADMIN';
    }
    return user?.userMetadata?['rol']?.toString().toUpperCase() ?? 'CHOFER';
  }

  AuthProvider({required this.apiClient, required this.storage}) {
    _initAuthListener();
  }

  void _initAuthListener() {
    // Sincronización automática con la sesión nativa de Supabase
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final user = data.session?.user ?? Supabase.instance.client.auth.currentUser;
      if (user != null) {
        _userId = user.id;
        if (user.email != null && user.email!.toLowerCase().contains('admin')) {
          _rol = 'ADMIN';
        } else {
          try {
            final res = await Supabase.instance.client
                .from('perfiles')
                .select('rol')
                .eq('id', user.id)
                .maybeSingle();
            _rol = (res?['rol'] ?? user.userMetadata?['rol'] ?? 'CHOFER').toString().toUpperCase();
          } catch (_) {
            _rol = 'CHOFER';
          }
        }
        _status = AuthStatus.authenticated;
      } else {
        _userId = null;
        _rol = null;
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  Future<bool> login(String email, String password) async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        _userId = user.id;
        if (user.email != null && user.email!.toLowerCase().contains('admin')) {
          _rol = 'ADMIN';
        } else {
          try {
            final res = await Supabase.instance.client
                .from('perfiles')
                .select('rol')
                .eq('id', user.id)
                .maybeSingle();
            _rol = (res?['rol'] ?? user.userMetadata?['rol'] ?? 'CHOFER').toString().toUpperCase();
          } catch (_) {
            _rol = 'CHOFER';
          }
        }
        _status = AuthStatus.authenticated;

        await storage.write(key: 'user_id', value: _userId);
        await storage.write(key: 'user_rol', value: _rol);
        await storage.write(key: 'is_authenticated', value: 'true');

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await storage.deleteAll();
    await Supabase.instance.client.auth.signOut();
    _userId = null;
    _rol = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}