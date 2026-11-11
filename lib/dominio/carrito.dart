import 'dinero.dart';
import 'excepciones.dart';
import 'producto.dart';

class Cupon {
  final String codigo;
  final int porcentaje;
  const Cupon(this.codigo, this.porcentaje);

  static const _validos = {'DOLORES10': 10, 'TALAVERA15': 15};

  /// Acepta mayúsculas, minúsculas y espacios sobrantes.
  static Cupon validar(String texto) {
    final c = texto.trim().toUpperCase();
    final p = _validos[c];
    if (p == null) throw const CuponInvalidoException();
    return Cupon(c, p);
  }
}

class LineaCarrito {
  final Producto producto;
  final int cantidad;
  const LineaCarrito(this.producto, this.cantidad);
  int get importe => producto.precioCentavos * cantidad;
}

class Carrito {
  static const int maxPorProducto = 10;
  static const int envioGratisDesde = 80000; // $800.00
  static const int costoEnvio = 9900; // $99.00

  final Map<String, LineaCarrito> _lineas = {};
  Cupon? cupon;

  List<LineaCarrito> get lineas => _lineas.values.toList();
  bool get estaVacio => _lineas.isEmpty;
  int get cantidadTotal => _lineas.values.fold(0, (s, l) => s + l.cantidad);

  void agregar(Producto p, {int cantidad = 1}) {
    if (cantidad <= 0) throw ArgumentError('La cantidad debe ser positiva');
    _poner(p, (_lineas[p.id]?.cantidad ?? 0) + cantidad);
  }

  void cambiarCantidad(String id, int cantidad) {
    final linea = _lineas[id];
    if (linea == null) return;
    if (cantidad <= 0) {
      _lineas.remove(id);
    } else {
      _poner(linea.producto, cantidad);
    }
  }

  void _poner(Producto p, int cantidad) {
    // Se valida ANTES de cambiar el estado: si lanza, el carrito queda intacto.
    if (cantidad > maxPorProducto) throw const LimiteProductoException(maxPorProducto);
    if (cantidad > p.existencias) {
      throw ExistenciasInsuficientesException(p.nombre, p.existencias);
    }
    _lineas[p.id] = LineaCarrito(p, cantidad);
  }

  void quitar(String id) => _lineas.remove(id);

  void vaciar() {
    _lineas.clear();
    cupon = null;
  }

  void aplicarCupon(String texto) => cupon = Cupon.validar(texto);
  void quitarCupon() => cupon = null;

  int get subtotal => _lineas.values.fold(0, (s, l) => s + l.importe);
  int get descuento => cupon == null ? 0 : porcentaje(subtotal, cupon!.porcentaje);
  int get envio =>
      estaVacio ? 0 : (subtotal - descuento >= envioGratisDesde ? 0 : costoEnvio);
  int get total => subtotal - descuento + envio;
  int get iva => ivaIncluido(total);
  int get faltaParaEnvioGratis =>
      estaVacio || envio == 0 ? 0 : envioGratisDesde - (subtotal - descuento);

  /// Solo guardamos id y cantidad: el precio SIEMPRE se vuelve a leer del catálogo.
  List<Map<String, Object?>> aMapas() =>
      [for (final l in _lineas.values) {'id': l.producto.id, 'cantidad': l.cantidad}];

  /// Reconstruye el carrito guardado, descartando productos que ya no existen
  /// y ajustando cantidades a lo que hoy hay en existencia.
  void restaurar(List<Map<String, Object?>> datos, Producto? Function(String) buscar) {
    for (final d in datos) {
      final p = buscar(d['id'] as String);
      if (p == null) continue;
      final pedida = d['cantidad'] as int;
      final tope = p.existencias < maxPorProducto ? p.existencias : maxPorProducto;
      final cantidad = pedida < tope ? pedida : tope;
      if (cantidad > 0) _lineas[p.id] = LineaCarrito(p, cantidad);
    }
  }
}