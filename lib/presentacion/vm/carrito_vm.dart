import 'package:flutter/foundation.dart';

import '../../dominio/carrito.dart';
import '../../dominio/contratos.dart';
import '../../dominio/excepciones.dart';
import '../../dominio/producto.dart';

class CarritoViewModel extends ChangeNotifier {
  final AlmacenCarrito _almacen;
  final RepositorioCatalogo _catalogo;
  final Carrito carrito = Carrito();

  /// Mensaje de una sola lectura para mostrar en un SnackBar.
  String? mensaje;

  CarritoViewModel(this._almacen, this._catalogo);

  Future<void> restaurar() async {
    final datos = await _almacen.cargar();
    final productos = {for (final p in await _catalogo.listar()) p.id: p};
    carrito.restaurar(datos, (id) => productos[id]);
    notifyListeners();
  }

  Future<void> agregar(Producto p, {int cantidad = 1}) =>
      _intentar(() => carrito.agregar(p, cantidad: cantidad));

  Future<void> cambiarCantidad(String id, int cantidad) =>
      _intentar(() => carrito.cambiarCantidad(id, cantidad));

  Future<void> quitar(String id) => _intentar(() => carrito.quitar(id));

  Future<void> aplicarCupon(String texto) => _intentar(() => carrito.aplicarCupon(texto));

  Future<void> quitarCupon() => _intentar(carrito.quitarCupon);

  /// Se llama tras un pago exitoso.
  Future<void> vaciar() => _intentar(carrito.vaciar);

  String? tomarMensaje() {
    final m = mensaje;
    mensaje = null;
    return m;
  }

  Future<void> _intentar(void Function() accion) async {
    try {
      accion();
      mensaje = null;
      await _almacen.guardar(carrito.aMapas());
    } catch (e) {
      mensaje = mensajeSeguro(e);
    }
    notifyListeners();
  }
}