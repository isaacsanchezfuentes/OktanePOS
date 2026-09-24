import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:oktane_pos/data/datasources/local_storage.dart';
import 'package:oktane_pos/core/api/api_client.dart';
import 'package:oktane_pos/core/api/app_config.dart';
import 'package:oktane_pos/core/api/supabase_config.dart';
import 'package:oktane_pos/providers/auth_provider.dart';
import 'package:oktane_pos/providers/paquetes_provider.dart';
import 'package:oktane_pos/ui/screens/login_screen.dart';
import 'package:oktane_pos/ui/screens/chofer/seleccionar_ruta_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optimización para dispositivos de gama baja (Low-RAM)
  PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 25; // 25 MB max
  PaintingBinding.instance.imageCache.maximumSize = 50; // 50 imágenes max

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  final db = AppDatabase();
  const storage = FlutterSecureStorage();
  final apiClient = ApiClient(
    baseUrl: AppConfig.baseUrl,
    storage: storage,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiClient: apiClient, storage: storage),
        ),
        ChangeNotifierProvider(
          create: (_) => PaquetesProvider(db: db, apiClient: apiClient),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Supabase.instance.client.auth.currentSession != null
          ? const SeleccionarRutaScreen()
          : const LoginScreen(),
    );
  }
}
