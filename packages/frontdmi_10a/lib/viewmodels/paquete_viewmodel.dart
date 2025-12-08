import 'dart:io';
import 'package:flutter/material.dart';
import '../models/paquete_model.dart';
import '../services/paquete_service.dart';

// ViewModel de paquetes - BojitaNoir
class PaqueteViewModel extends ChangeNotifier {
  final PaqueteService _paqueteService = PaqueteService();

  List<Paquete> _paquetes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Paquete> get paquetes => _paquetes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Cargar todos los paquetes
  void cargarPaquetes() {
    _isLoading = true;
    notifyListeners();

    _paqueteService.obtenerPaquetes().listen(
      (paquetes) {
        _paquetes = paquetes;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Cargar paquetes por cliente
  void cargarPaquetesPorCliente(String clienteId) {
    _isLoading = true;
    notifyListeners();

    _paqueteService
        .obtenerPaquetesPorCliente(clienteId)
        .listen(
          (paquetes) {
            _paquetes = paquetes;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Cargar paquetes por repartidor
  void cargarPaquetesPorRepartidor(String repartidorId) {
    _isLoading = true;
    notifyListeners();

    _paqueteService
        .obtenerPaquetesPorRepartidor(repartidorId)
        .listen(
          (paquetes) {
            _paquetes = paquetes;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = error.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Crear paquete
  Future<bool> crearPaquete(Paquete paquete, File? foto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _paqueteService.crearPaquete(paquete, foto);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Actualizar paquete
  Future<bool> actualizarPaquete(Paquete paquete, File? nuevaFoto) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _paqueteService.actualizarPaquete(paquete, nuevaFoto);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Eliminar paquete
  Future<bool> eliminarPaquete(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _paqueteService.eliminarPaquete(id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Actualizar estado
  Future<bool> actualizarEstado(
    String id,
    String nuevoEstado, {
    Map<String, dynamic>? ubicacion,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _paqueteService.actualizarEstado(
        id,
        nuevoEstado,
        ubicacion: ubicacion,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Filtrar paquetes por estado
  List<Paquete> filtrarPorEstado(String estado) {
    return _paquetes.where((p) => p.estado == estado).toList();
  }

  // Limpiar error
  void limpiarError() {
    _errorMessage = null;
    notifyListeners();
  }
}
