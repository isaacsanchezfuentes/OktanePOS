import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void setupTestMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 1. Mock de flutter_secure_storage para evitar MissingPluginException en unit tests
  const MethodChannel secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureStorageChannel, (MethodCall methodCall) async {
    if (methodCall.method == 'read') return null;
    if (methodCall.method == 'write') return true;
    if (methodCall.method == 'delete') return true;
    return null;
  });
}
