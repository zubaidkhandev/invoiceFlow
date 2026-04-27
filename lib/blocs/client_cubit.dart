import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoice_flow/blocs/history_cubit.dart';
import 'package:invoice_flow/models/client.dart';
import 'package:invoice_flow/services/storage_service.dart';

abstract class ClientState {}

class ClientInitial extends ClientState {}

class ClientLoading extends ClientState {}

class ClientLoaded extends ClientState {
  final List<Client> clients;
  ClientLoaded(this.clients);
}

class ClientCubit extends Cubit<ClientState> {
  final StorageService _storageService;
  final HistoryCubit _historyCubit;

  ClientCubit(this._storageService, this._historyCubit)
      : super(ClientInitial());

  Future<void> loadClients() async {
    emit(ClientLoading());
    try {
      final data = _storageService.getClients();
      final clients = data
          .map((e) => Client.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      clients.sort((a, b) => a.name.compareTo(b.name));
      emit(ClientLoaded(clients));
    } catch (e) {
      emit(ClientLoaded(const []));
    }
  }

  Future<void> saveClient(Client client) async {
    final data = _storageService.getClients();
    final index = data.indexWhere((e) => e['id'] == client.id);
    
    if (index >= 0) {
      data[index] = client.toJson();
    } else {
      data.add(client.toJson());
    }

    await _storageService.saveClients(data);
    
    _historyCubit.logAction(
      title: index >= 0 ? 'Client Updated' : 'Client Added',
      description: '${client.name} has been added/updated in directory',
      type: 'client',
    );

    await loadClients();
  }

  Future<void> deleteClient(String id) async {
    final data = _storageService.getClients();
    final index = data.indexWhere((e) => e['id'] == id);
    if (index >= 0) {
      final name = data[index]['name'];
      data.removeAt(index);
      await _storageService.saveClients(data);
      
      _historyCubit.logAction(
        title: 'Client Removed',
        description: '$name was removed from directory',
        type: 'client',
      );
      
      await loadClients();
    }
  }
}
