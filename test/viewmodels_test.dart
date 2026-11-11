import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_talavera/datos/almacenes.dart';
import 'package:tienda_talavera/datos/auth_simulada.dart';
import 'package:tienda_talavera/datos/catalogo_memoria.dart';
import 'package:tienda_talavera/datos/pasarela_simulada.dart';
import 'package:tienda_talavera/dominio/carrito.dart';
import 'package:tienda_talavera/dominio/contratos.dart';
import 'package:tienda_talavera/dominio/direccion.dart';
import 'package:tienda_talavera/dominio/producto.dart';
import 'package:tienda_talavera/dominio/servicio_checkout.dart';
import 'package:tienda_talavera/dominio/tarjeta.dart';
import 'package:tienda_talavera/presentacion/vm/carrito_vm.dart';
import 'package:tienda_talavera/presentacion/vm/catalogo_vm.dart';
import 'package:tienda_talavera/presentacion/vm/checkout_vm.dart';
import 'package:tienda_talavera/presentacion/vm/sesion_vm.dart';

const buena =
    DatosTarjeta(numero: '4242424242424242', titular: 'Ana', mes: 12, anio: 30, cvv: '123');
const dir = Direccion(
  nombreRecibe: 'Ana Pérez',
  calle: 'Calle 5 de Febrero 10',
  colonia: 'Centro',
  codigoPostal: '37800',
  ciudad: 'Dolores Hidalgo',
  estado: 'Guanajuato',
  telefono: '4181234567',
);

/// Pasarela falsa que falla con un error "desconocido" N veces (simula red caída).
class PasarelaQueFalla implements PasarelaPago {
  int fallosRestantes;
  final List<String> clavesVistas = [];
  final PasarelaSimulada real = PasarelaSimulada();
  PasarelaQueFalla(this.fallosRestantes);

  @override
  Future<ResultadoPago> cobrar({
    required int montoCentavos,
    required DatosTarjeta tarjeta,
    required String claveIdempotencia,
  }) async {
    clavesVistas.add(claveIdempotencia);
    if (fallosRestantes > 0) {
      fallosRestantes--;
      throw Exception('sin red'); // NO es ErrorDeApp
    }
    return real.cobrar(
        montoCentavos: montoCentavos, tarjeta: tarjeta, claveIdempotencia: claveIdempotencia);
  }
}

void main() {
  group('CatalogoViewModel', () {
    test('filtra por categoría, texto y AR combinados', () async {
      final vm = CatalogoViewModel(CatalogoMemoria());
      await vm.cargar();
      expect(vm.visibles.length, 8);

      vm.elegirCategoria(Categoria.talavera);
      expect(vm.visibles.every((p) => p.categoria == Categoria.talavera), isTrue);

      vm.alternarSoloAr();
      expect(vm.visibles.map((p) => p.id), ['jarron']);

      vm.buscar('plato'); // el plato no tiene modelo 3D
      expect(vm.visibles, isEmpty);
    });
    test('la búsqueda ignora mayúsculas', () async {
      final vm = CatalogoViewModel(CatalogoMemoria());
      await vm.cargar();
      vm.buscar('CAJETA');
      expect(vm.visibles.single.id, 'cajeta');
    });
  });

  group('CarritoViewModel', () {
    late CatalogoMemoria cat;
    late AlmacenCarritoMemoria almacen;
    late CarritoViewModel vm;
    setUp(() {
      cat = CatalogoMemoria();
      almacen = AlmacenCarritoMemoria();
      vm = CarritoViewModel(almacen, cat);
    });

    test('agregar persiste', () async {
      await vm.agregar((await cat.porId('taza'))!);
      expect((await almacen.cargar()).single['id'], 'taza');
    });
    test('error deja mensaje y no persiste el cambio', () async {
      await vm.agregar((await cat.porId('rebozo'))!, cantidad: 6); // stock 5
      expect(vm.mensaje, isNotNull);
      expect(vm.carrito.estaVacio, isTrue);
    });
    test('restaurar recupera el carrito guardado', () async {
      await vm.agregar((await cat.porId('taza'))!, cantidad: 2);
      final otro = CarritoViewModel(almacen, cat);
      await otro.restaurar();
      expect(otro.carrito.cantidadTotal, 2);
    });
    test('cupón inválido genera mensaje', () async {
      await vm.aplicarCupon('NOEXISTE');
      expect(vm.tomarMensaje(), isNotNull);
      expect(vm.tomarMensaje(), isNull); // se lee una sola vez
    });
  });

  group('SesionViewModel', () {
    late SesionViewModel vm;
    setUp(() {
      vm = SesionViewModel(AuthSimulada(AlmacenSeguroMemoria()), OrdenesMemoria());
    });
    test('registrar deja al usuario autenticado', () async {
      expect(await vm.registrar('Ana Pérez', 'ana@correo.com', 'clave1234'), isTrue);
      expect(vm.autenticado, isTrue);
    });
    test('error de login muestra mensaje genérico', () async {
      await vm.registrar('Ana Pérez', 'ana@correo.com', 'clave1234');
      await vm.cerrar();
      expect(await vm.iniciar('ana@correo.com', 'incorrecta1'), isFalse);
      expect(vm.error, contains('incorrect'));
      expect(vm.autenticado, isFalse);
    });
    test('favoritos se alternan', () async {
      await vm.registrar('Ana Pérez', 'ana@correo.com', 'clave1234');
      await vm.alternarFavorito('jarron');
      expect(vm.esFavorito('jarron'), isTrue);
      await vm.alternarFavorito('jarron');
      expect(vm.esFavorito('jarron'), isFalse);
    });
  });

  group('CheckoutViewModel', () {
    Future<(CheckoutViewModel, Carrito, PasarelaQueFalla)> armar(int fallos) async {
      final cat = CatalogoMemoria();
      final pasarela = PasarelaQueFalla(fallos);
      final servicio = ServicioCheckout(
        catalogo: cat,
        ordenes: OrdenesMemoria(),
        pasarela: pasarela,
        reloj: () => DateTime(2026, 11, 5),
      );
      var n = 0;
      final vm = CheckoutViewModel(servicio, generarClave: () => 'clave-${++n}');
      final carrito = Carrito()..agregar((await cat.porId('taza'))!);
      vm.guardarDireccion(dir);
      return (vm, carrito, pasarela);
    }

    test('dirección inválida no avanza de paso', () async {
      final (vm, _, _) = await armar(0);
      vm.reiniciar();
      const mala = Direccion(
          nombreRecibe: 'A',
          calle: '',
          colonia: '',
          codigoPostal: '',
          ciudad: '',
          estado: '',
          telefono: '');
      expect(vm.guardarDireccion(mala), isFalse);
      expect(vm.paso, PasoCheckout.direccion);
    });

    test('pago exitoso llega a confirmación', () async {
      final (vm, carrito, _) = await armar(0);
      expect(await vm.pagar(usuarioId: 'u1', carrito: carrito, tarjeta: buena), isTrue);
      expect(vm.paso, PasoCheckout.confirmacion);
      expect(vm.ordenConfirmada, isNotNull);
    });

    test('tras un error de red se REUSA la clave de idempotencia', () async {
      final (vm, carrito, pasarela) = await armar(1);
      expect(await vm.pagar(usuarioId: 'u1', carrito: carrito, tarjeta: buena), isFalse);
      expect(vm.error, 'Ocurrió un error inesperado. Intenta de nuevo.');
      expect(await vm.pagar(usuarioId: 'u1', carrito: carrito, tarjeta: buena), isTrue);
      expect(pasarela.clavesVistas, ['clave-1', 'clave-1']);
    });

    test('tras un rechazo definitivo se RENUEVA la clave', () async {
      final (vm, carrito, pasarela) = await armar(0);
      const rechazada =
          DatosTarjeta(numero: '4000000000000002', titular: 'A', mes: 12, anio: 30, cvv: '123');
      await vm.pagar(usuarioId: 'u1', carrito: carrito, tarjeta: rechazada);
      await vm.pagar(usuarioId: 'u1', carrito: carrito, tarjeta: buena);
      expect(pasarela.clavesVistas, ['clave-1', 'clave-2']);
    });

    test('doble toque: el segundo pago simultáneo se ignora', () async {
      final cat = CatalogoMemoria();
      final pasarela = PasarelaSimulada(latencia: const Duration(milliseconds: 50));
      final servicio = ServicioCheckout(
        catalogo: cat,
        ordenes: OrdenesMemoria(),
        pasarela: pasarela,
        reloj: () => DateTime(2026, 11, 5),
      );
      final vm = CheckoutViewModel(servicio);
      final carrito = Carrito()..agregar((await cat.porId('taza'))!);
      vm.guardarDireccion(dir);
      final a = vm.pagar(usuarioId: 'u1', carrito: carrito, tarjeta: buena);
      final b = vm.pagar(usuarioId: 'u1', carrito: carrito, tarjeta: buena);
      expect(await b, isFalse);
      expect(await a, isTrue);
      expect(pasarela.cobrosAprobados, 1);
    });
  });
}