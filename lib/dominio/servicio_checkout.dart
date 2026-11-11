import 'carrito.dart';
import 'contratos.dart';
import 'direccion.dart';
import 'excepciones.dart';
import 'orden.dart';
import 'tarjeta.dart';

/// Orquesta el pago. Regla de oro: el SERVIDOR (aquí, el catálogo) es la fuente
/// de la verdad. Nunca se cobra el precio que "dice" el teléfono sin revisarlo.
class ServicioCheckout {
  final RepositorioCatalogo _catalogo;
  final RepositorioOrdenes _ordenes;
  final PasarelaPago _pasarela;
  final DateTime Function() _reloj;

  ServicioCheckout({
    required RepositorioCatalogo catalogo,
    required RepositorioOrdenes ordenes,
    required PasarelaPago pasarela,
    DateTime Function()? reloj,
  })  : _catalogo = catalogo,
        _ordenes = ordenes,
        _pasarela = pasarela,
        _reloj = reloj ?? DateTime.now;

  Future<Orden> pagar({
    required String usuarioId,
    required Carrito carrito,
    required Direccion direccion,
    required DatosTarjeta tarjeta,
    required String claveIdempotencia,
  }) async {
    // 1. Validaciones baratas y locales.
    if (carrito.estaVacio) throw const CarritoVacioException();

    final errores = direccion.errores();
    if (errores.isNotEmpty) throw DatosInvalidosException(errores.first);

    final ahora = _reloj();

    if (!ValidadorTarjeta.luhn(tarjeta.numero)) {
      throw const TarjetaInvalidaException('El número de tarjeta no es válido.');
    }
    if (!ValidadorTarjeta.vigente(tarjeta.mes, tarjeta.anio, hoy: ahora)) {
      throw const TarjetaInvalidaException('La tarjeta está vencida.');
    }
    if (!ValidadorTarjeta.cvvValido(tarjeta.cvv, tarjeta.marca)) {
      throw const TarjetaInvalidaException('El código de seguridad no es válido.');
    }

    // 2. Revalidar contra el catálogo ANTES de cobrar.
    for (final l in carrito.lineas) {
      final actual = await _catalogo.porId(l.producto.id);
      if (actual == null) throw const ProductoNoDisponibleException();
      if (actual.precioCentavos != l.producto.precioCentavos) {
        throw PrecioCambioException(actual.nombre);
      }
      if (actual.existencias < l.cantidad) {
        throw ExistenciasInsuficientesException(actual.nombre, actual.existencias);
      }
    }

    // 3. Cobrar con clave de idempotencia.
    final resultado = await _pasarela.cobrar(
      montoCentavos: carrito.total,
      tarjeta: tarjeta,
      claveIdempotencia: claveIdempotencia,
    );

    // 4. Solo si se aprobó: descontar inventario y guardar la orden.
    switch (resultado) {
      case PagoRechazado(:final motivo):
        throw PagoRechazadoException(motivo); // sin orden, sin tocar inventario
      case PagoAprobado(:final referencia):
        for (final l in carrito.lineas) {
          await _catalogo.descontar(l.producto.id, l.cantidad);
        }
        final orden = Orden(
          id: 'ORD-${ahora.millisecondsSinceEpoch}',
          usuarioId: usuarioId,
          fecha: ahora,
          lineas: [
            for (final l in carrito.lineas)
              LineaOrden(
                  l.producto.id, l.producto.nombre, l.cantidad, l.producto.precioCentavos),
          ],
          subtotal: carrito.subtotal,
          descuento: carrito.descuento,
          envio: carrito.envio,
          total: carrito.total,
          direccion: direccion,
          tarjetaUltimos4: tarjeta.ultimos4,
          referenciaPago: referencia,
        );
        await _ordenes.guardar(orden);
        return orden;
    }
  }
}