import 'package:flutter/foundation.dart';

import 'sensitive_data_storage.dart';


Future<void> debugDumpSensitiveData(
  SensitiveDataStorage storage,
  String label,
) async {
  if (!kDebugMode) return;

  String estado(String? value) =>
      (value == null || value.isEmpty) ? 'VACÍO' : 'PRESENTE';

  debugPrint(
    '[Sensitive][$label] '
    'username=${estado(await storage.readUsername())} '
    'email=${estado(await storage.readEmail())} '
    'phone=${estado(await storage.readPhone())} '
    'sessionToken=${estado(await storage.readSessionToken())} '
    'userId=${estado(await storage.readUserId())}',
  );
}
