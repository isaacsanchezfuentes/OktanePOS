import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oktane_pos/data/datasources/local_storage.dart';
import 'package:oktane_pos/core/api/api_client.dart';
import 'package:oktane_pos/core/api/app_config.dart';
import 'package:oktane_pos/core/api/supabase_config.dart';
import 'package:oktane_pos/core/theme/theme_service.dart';
import 'package:oktane_pos/providers/auth_provider.dart';
import 'package:oktane_pos/providers/paquetes_provider.dart';
import 'package:oktane_pos/ui/screens/login_screen.dart';
import 'package:oktane_pos/ui/screens/chofer/seleccionar_ruta_screen.dart';
import 'package:oktane_pos/features/charge/screens/quick_charge_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es_MX', null);
  await initializeDateFormatting('es', null);

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
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: ThemeService.instance.currentThemeData,
          initialRoute: Supabase.instance.client.auth.currentSession != null
              ? '/charge'
              : '/login',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/charge': (context) => const QuickChargeScreen(),
            '/routes': (context) => const SeleccionarRutaScreen(),
          },
        );
      },
    );
  }
}
