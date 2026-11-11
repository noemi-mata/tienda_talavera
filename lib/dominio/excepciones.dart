/// Errores "esperados": su mensaje es seguro para mostrarse al usuario.
abstract class ErrorDeApp implements Exception {
  const ErrorDeApp();
}

class ExistenciasInsuficientesException extends ErrorDeApp {
  final String producto;
  final int disponibles;
  const ExistenciasInsuficientesException(this.producto, this.disponibles);
  @override
  String toString() => 'Solo quedan $disponibles de "$producto".';
}

class LimiteProductoException extends ErrorDeApp {
  final int limite;
  const LimiteProductoException(this.limite);
  @override
  String toString() => 'Puedes llevar máximo $limite piezas de cada producto.';
}

class CuponInvalidoException extends ErrorDeApp {
  const CuponInvalidoException();
  @override
  String toString() => 'Ese cupón no es válido.';
}

class CarritoVacioException extends ErrorDeApp {
  const CarritoVacioException();
  @override
  String toString() => 'Tu carrito está vacío.';
}

class DatosInvalidosException extends ErrorDeApp {
  final String mensaje;
  const DatosInvalidosException(this.mensaje);
  @override
  String toString() => mensaje;
}

class TarjetaInvalidaException extends ErrorDeApp {
  final String mensaje;
  const TarjetaInvalidaException(this.mensaje);
  @override
  String toString() => mensaje;
}

class PagoRechazadoException extends ErrorDeApp {
  final String motivo;
  const PagoRechazadoException(this.motivo);
  @override
  String toString() => 'Pago rechazado: $motivo. No se hizo ningún cargo.';
}

class PrecioCambioException extends ErrorDeApp {
  final String producto;
  const PrecioCambioException(this.producto);
  @override
  String toString() => 'El precio de "$producto" cambió. Revisa tu carrito.';
}

class ProductoNoDisponibleException extends ErrorDeApp {
  const ProductoNoDisponibleException();
  @override
  String toString() => 'Un producto de tu carrito ya no está disponible.';
}

class CredencialesInvalidasException extends ErrorDeApp {
  const CredencialesInvalidasException();
  // Mensaje GENÉRICO: no revela si el correo existe o si falló la contraseña.
  @override
  String toString() => 'Correo o contraseña incorrectos.';
}

class CuentaBloqueadaException extends ErrorDeApp {
  final Duration restante;
  const CuentaBloqueadaException(this.restante);
  @override
  String toString() =>
      'Demasiados intentos. Intenta de nuevo en ${restante.inMinutes + 1} minutos.';
}

class CorreoRegistradoException extends ErrorDeApp {
  const CorreoRegistradoException();
  @override
  String toString() => 'No se pudo crear la cuenta con esos datos.';
}

class SesionRequeridaException extends ErrorDeApp {
  const SesionRequeridaException();
  @override
  String toString() => 'Inicia sesión para continuar.';
}

/// Mensaje que SÍ puede ver el usuario (nunca detalles internos).
String mensajeSeguro(Object error) =>
    error is ErrorDeApp ? error.toString() : 'Ocurrió un error inesperado. Intenta de nuevo.';