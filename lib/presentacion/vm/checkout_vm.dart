import 'package:flutter/foundation.dart';

import '../../dominio/carrito.dart';
import '../../dominio/direccion.dart';
import '../../dominio/excepciones.dart';
import '../../dominio/orden.dart';
import '../../dominio/servicio_checkout.dart';
import '../../dominio/tarjeta.dart';

enum PasoCheckout { direccion, pago, confirmacion }

class CheckoutViewModel extends ChangeNotifier {
  final ServicioCheckout _servicio;
  final String Function() _generarClave;

  CheckoutViewModel(this._servicio, {String Function()? generarClave})
      : _generarClave = generarClave ??
            (() => 'pedido-${DateTime.now().microsecondsSinceEpoch}-${_contador++}');

  static int _contador = 0;

  PasoCheckout paso = PasoCheckout.direccion;
  Direccion? direccion;
  bool procesando = false;
  String? error;
  Orden? ordenConfirmada;

  /// Clave de idempotencia del intento actual de pago.
  /// - Se REUSA si el resultado fue desconocido (p. ej. se cayó la red).
  /// - Se RENUEVA tras un éxito o un rechazo definitivo.
  String? _clave;

  bool guardarDireccion(Direccion d) {
    final errores = d.errores();
    if (errores.isNotEmpty) {
      error = errores.first;
      notifyListeners();
      return false;
    }
    direccion = d;
    error = null;
    paso = PasoCheckout.pago;
    notifyListeners();
    return true;
  }

  void volver() {
    if (paso == PasoCheckout.pago) paso = PasoCheckout.direccion;
    error = null;
    notifyListeners();
  }

  Future<bool> pagar({
    required String usuarioId,
    required Carrito carrito,
    required DatosTarjeta tarjeta,
  }) async {
    if (procesando) return false; // doble toque: ignorado
    final dir = direccion;
    if (dir == null) {
      error = 'Falta la dirección de envío.';
      notifyListeners();
      return false;
    }
    procesando = true;
    error = null;
    notifyListeners();

    _clave ??= _generarClave();
    try {
      ordenConfirmada = await _servicio.pagar(
        usuarioId: usuarioId,
        carrito: carrito,
        direccion: dir,
        tarjeta: tarjeta,
        claveIdempotencia: _clave!,
      );
      _clave = null; // pago exitoso: el siguiente pedido será otra operación
      paso = PasoCheckout.confirmacion;
      procesando = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Errores definitivos: la siguiente vez es un intento NUEVO.
      if (e is PagoRechazadoException ||
          e is TarjetaInvalidaException ||
          e is PrecioCambioException ||
          e is ExistenciasInsuficientesException ||
          e is ProductoNoDisponibleException) {
        _clave = null;
      }
      // Cualquier otro (red, desconocido): se conserva la clave para reintentar seguro.
      error = mensajeSeguro(e);
      procesando = false;
      notifyListeners();
      return false;
    }
  }

  void reiniciar() {
    paso = PasoCheckout.direccion;
    ordenConfirmada = null;
    error = null;
    _clave = null;
    notifyListeners();
  }
}