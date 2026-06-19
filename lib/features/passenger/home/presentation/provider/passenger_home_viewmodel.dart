import 'package:flutter/foundation.dart';

import '../../../../../shared/domain/entities/user.dart';
import '../../../../profile/domain/repositories/profile_repository.dart';


class PassengerHomeViewModel extends ChangeNotifier {
  PassengerHomeViewModel(this._profileRepo);

  final ProfileRepository _profileRepo;

  int _selectedIndex = 0;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  int get selectedIndex => _selectedIndex;
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get greetingName {
    if (_user == null) return 'Pasajero';
    final nombre = _user!.nombreUsuario;
    if (nombre.isEmpty) return 'Pasajero';
    return nombre.split(' ').first;
  }

  Future<void> loadUser() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await _profileRepo.getMe();
    } catch (_) {
      _errorMessage = 'No se pudo cargar el perfil';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectTab(int index) {
    if (_selectedIndex == index) return;
    _selectedIndex = index;
    notifyListeners();
  }
}
