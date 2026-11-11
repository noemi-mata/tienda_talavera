import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dominio/contratos.dart';
import '../dominio/orden.dart';

/// ---- En memoria: para pruebas y modo demo ----

class AlmacenCarritoMemoria implements AlmacenCarrito {
  List<Map<String, Object?>> _datos = [];

  @override
  Future<List<Map<String, Object?>>> cargar() async => [..._datos];

  @override
  Future<void> guardar(List<Map<String, Object?>> lineas) async => _datos = [...lineas];
}

class AlmacenSeguroMemoria implements AlmacenSeguro {
  final Map<String, String> _datos = {};

  @override
  Future<String?> leer(String clave) async => _datos[clave];

  @override
  Future<void> escribir(String clave, String valor) async => _datos[clave] = valor;

  @override
  Future<void> borrar(String clave) async => _datos.remove(clave);
}

class OrdenesMemoria implements RepositorioOrdenes {
  final List<Orden> _ordenes = [];

  @override
  Future<void> guardar(Orden orden) async => _ordenes.add(orden);

  @override
  Future<List<Orden>> delUsuario(String usuarioId) async =>
      _ordenes.where((o) => o.usuarioId == usuarioId).toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));
}

/// ---- En el teléfono ----

/// El carrito NO es secreto: va en shared_preferences (almacenamiento normal).
class AlmacenCarritoPrefs implements AlmacenCarrito {
  static const _clave = 'carrito';

  @override
  Future<List<Map<String, Object?>>> cargar() async {
    final texto = (await SharedPreferences.getInstance()).getString(_clave);
    if (texto == null) return [];
    try {
      return (jsonDecode(texto) as List).cast<Map<String, Object?>>();
    } catch (_) {
      return []; // datos dañados: empezamos de cero en lugar de truenar
    }
  }

  @override
  Future<void> guardar(List<Map<String, Object?>> lineas) async =>
      (await SharedPreferences.getInstance()).setString(_clave, jsonEncode(lineas));
}

/// Los TOKENS de sesión sí son secretos: van en Keychain (iOS) / Keystore (Android).
class AlmacenSeguroFlutter implements AlmacenSeguro {
  final FlutterSecureStorage _s = const FlutterSecureStorage();

  @override
  Future<String?> leer(String clave) => _s.read(key: clave);

  @override
  Future<void> escribir(String clave, String valor) => _s.write(key: clave, value: valor);

  @override
  Future<void> borrar(String clave) => _s.delete(key: clave);
}