import 'datos/almacenes.dart';
import 'datos/auth_simulada.dart';
import 'datos/catalogo_memoria.dart';
import 'datos/pasarela_simulada.dart';
import 'dominio/contratos.dart';
import 'dominio/servicio_checkout.dart';
import 'presentacion/vm/carrito_vm.dart';
import 'presentacion/vm/catalogo_vm.dart';
import 'presentacion/vm/checkout_vm.dart';
import 'presentacion/vm/sesion_vm.dart';

/// Raíz de composición: el ÚNICO lugar donde se eligen las implementaciones.
/// Para pasar a una pasarela o un servidor real, solo cambia este archivo.
class Dependencias {
  final CatalogoViewModel catalogo;
  final CarritoViewModel carrito;
  final SesionViewModel sesion;
  final CheckoutViewModel checkout;

  Dependencias._(this.catalogo, this.carrito, this.sesion, this.checkout);

  factory Dependencias.crear({
    RepositorioCatalogo? repoCatalogo,
    AlmacenCarrito? almacenCarrito,
    AlmacenSeguro? almacenSeguro,
    PasarelaPago? pasarela,
  }) {
    final cat = repoCatalogo ?? CatalogoMemoria();
    final seguro = almacenSeguro ?? AlmacenSeguroFlutter();
    final ordenes = OrdenesMemoria();
    final auth = AuthSimulada(seguro);
    final servicio = ServicioCheckout(
      catalogo: cat,
      ordenes: ordenes,
      pasarela: pasarela ?? PasarelaSimulada(latencia: const Duration(milliseconds: 600)),
    );
    return Dependencias._(
      CatalogoViewModel(cat),
      CarritoViewModel(almacenCarrito ?? AlmacenCarritoPrefs(), cat),
      SesionViewModel(auth, ordenes),
      CheckoutViewModel(servicio),
    );
  }

  Future<void> iniciar() async {
    await catalogo.cargar();
    await carrito.restaurar();
    await sesion.restaurar();
  }
}