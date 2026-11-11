import 'package:flutter/foundation.dart';

import '../../dominio/contratos.dart';
import '../../dominio/excepciones.dart';
import '../../dominio/orden.dart';
import '../../dominio/usuario.dart';

class SesionViewModel extends ChangeNotifier {
  final ServicioAuth _auth;
  final RepositorioOrdenes _ordenes;

  SesionViewModel(this._auth, this._ordenes);

  Usuario? usuario;
  List<Orden> ordenes = [];
  bool ocupado = false;
  String? error;

  bool get autenticado => usuario != null;

  Future<void> restaurar() async {
    usuario = await _auth.restaurarSesion();
    await _cargarOrdenes();
    notifyListeners();
  }

  Future<bool> registrar(String nombre, String correo, String password) =>
      _operar(() async => usuario =
          await _auth.registrar(nombre: nombre, correo: correo, password: password));

  Future<bool> iniciar(String correo, String password) =>
      _operar(() async => usuario = await _auth.iniciarSesion(correo: correo, password: password));

  Future<void> cerrar() async {
    await _auth.cerrarSesion();
    usuario = null;
    ordenes = [];
    notifyListeners();
  }

  Future<bool> actualizarPerfil(Usuario nuevo) =>
      _operar(() async => usuario = await _auth.actualizarPerfil(nuevo));

  Future<void> alternarFavorito(String productoId) async {
    final u = usuario;
    if (u == null) return;
    final nuevos = {...u.favoritos};
    if (!nuevos.remove(productoId)) nuevos.add(productoId);
    await _operar(
        () async => usuario = await _auth.actualizarPerfil(u.copiarCon(favoritos: nuevos)));
  }

  bool esFavorito(String productoId) => usuario?.favoritos.contains(productoId) ?? false;

  Future<void> refrescarOrdenes() async {
    await _cargarOrdenes();
    notifyListeners();
  }

  Future<void> _cargarOrdenes() async {
    final u = usuario;
    ordenes = u == null ? [] : await _ordenes.delUsuario(u.id);
  }

  Future<bool> _operar(Future<void> Function() accion) async {
    if (ocupado) return false; // evita doble toque
    ocupado = true;
    error = null;
    notifyListeners();
    var ok = true;
    try {
      await accion();
      await _cargarOrdenes();
    } catch (e) {
      error = mensajeSeguro(e);
      ok = false;
    }
    ocupado = false;
    notifyListeners();
    return ok;
  }
}