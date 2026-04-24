import 'package:flutter_bloc/flutter_bloc.dart'; // Zubaid khan flutter developer
import 'package:invoice_flow/services/storage_service.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthUnlocked extends AuthState {}

class AuthLocked extends AuthState {}

class AuthCubit extends Cubit<AuthState> {
  final StorageService storageService;

  AuthCubit(this.storageService) : super(AuthInitial()) {
    checkAuth();
  }

  void checkAuth() {
    if (storageService.hasAppPassword()) {
      emit(AuthLocked());
    } else {
      emit(AuthUnlocked());
    }
  }

  bool unlock(String password) {
    final savedPassword = storageService.getPassword();
    if (savedPassword == password) {
      emit(AuthUnlocked());
      return true;
    }
    return false;
  }

  Future<void> setPassword(String? password) async {
    await storageService.savePassword(password);
    checkAuth();
  }
}
