import 'orden.dart';
import 'producto.dart';
import 'tarjeta.dart';
import 'usuario.dart';

/// Contratos: el dominio no sabe si los datos vienen de memoria, de disco o de un servidor.

abstract class RepositorioCatalogo {
  Future<List<Producto>> listar();
  Future<Producto?> porId(String id);
  Future<void> descontar(String id, int cantidad);
}

abstract class RepositorioOrdenes {
  Future<void> guardar(Orden orden);
  Future<List<Orden>> delUsuario(String usuarioId); // la más reciente primero
}

abstract class AlmacenCarrito {
  Future<List<Map<String, Object?>>> cargar();
  Future<void> guardar(List<Map<String, Object?>> lineas);
}

/// Para secretos (tokens de sesión): en el teléfono vive en Keychain / Keystore.
abstract class AlmacenSeguro {
  Future<String?> leer(String clave);
  Future<void> escribir(String clave, String valor);
  Future<void> borrar(String clave);
}

sealed class ResultadoPago {
  const ResultadoPago();
}

class PagoAprobado extends ResultadoPago {
  final String referencia;
  const PagoAprobado(this.referencia);
}

class PagoRechazado extends ResultadoPago {
  final String motivo;
  const PagoRechazado(this.motivo);
}

abstract class PasarelaPago {
  /// [claveIdempotencia]: si la misma clave llega dos veces, NO se cobra dos veces.
  Future<ResultadoPago> cobrar({
    required int montoCentavos,
    required DatosTarjeta tarjeta,
    required String claveIdempotencia,
  });
}

abstract class ServicioAuth {
  Future<Usuario> registrar({
    required String nombre,
    required String correo,
    required String password,
  });
  Future<Usuario> iniciarSesion({required String correo, required String password});
  Future<Usuario?> restaurarSesion();
  Future<void> cerrarSesion();
  Future<Usuario> actualizarPerfil(Usuario usuario);
}