import 'sensitive_data_storage.dart';

class SensitiveDataSeeder {
  const SensitiveDataSeeder(this._storage);

  final SensitiveDataStorage _storage;


  static const String demoUsername = 'demo_user';

  Future<void> seedIfEmpty() async {
    if (!await _storage.isEmpty()) return;

    await _storage.writeAll(
      username: demoUsername,
      email: 'demo.user@viajeseguro.mx',
      phone: '+52 555 123 4567',
      sessionToken: 'sess_demo_8f2a4c91b7e6',
      userId: '1001',
    );
  }
}
