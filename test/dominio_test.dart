import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_talavera/dominio/carrito.dart';
import 'package:tienda_talavera/dominio/dinero.dart';
import 'package:tienda_talavera/dominio/direccion.dart';
import 'package:tienda_talavera/dominio/excepciones.dart';
import 'package:tienda_talavera/dominio/orden.dart';
import 'package:tienda_talavera/dominio/producto.dart';
import 'package:tienda_talavera/dominio/tarjeta.dart';
import 'package:tienda_talavera/dominio/usuario.dart';
import 'package:tienda_talavera/dominio/validadores.dart';

Producto prod(String id, int precio, {int stock = 10, String? glb}) => Producto(
      id: id,
      nombre: 'P$id',
      descripcion: 'd',
      precioCentavos: precio,
      categoria: Categoria.talavera,
      existencias: stock,
      emoji: '🏺',
      modeloGlb: glb,
    );

void main() {
  group('dinero', () {
    test('formatea pesos', () => expect(formatearPesos(125000), r'$1,250.00'));
    test('IVA incluido de 116.00 es 16.00', () => expect(ivaIncluido(11600), 1600));
    test('porcentaje redondea al centavo', () => expect(porcentaje(9999, 10), 1000));
  });

  group('producto', () {
    test('https cuenta como modelo 3D',
        () => expect(prod('a', 1, glb: 'https://x.com/a.glb').tieneModelo3d, isTrue));
    test('http NO cuenta',
        () => expect(prod('a', 1, glb: 'http://x.com/a.glb').tieneModelo3d, isFalse));
    test('sin modelo', () => expect(prod('a', 1).tieneModelo3d, isFalse));
  });

  group('excepciones', () {
    test('mensajeSeguro oculta los errores internos', () {
      expect(mensajeSeguro(Exception('C:/servidor/ruta/secreta')),
          'Ocurrió un error inesperado. Intenta de nuevo.');
      expect(mensajeSeguro(const CuponInvalidoException()), 'Ese cupón no es válido.');
    });
  });

  group('carrito', () {
    test('suma subtotal', () {
      final c = Carrito()
        ..agregar(prod('a', 10000), cantidad: 2)
        ..agregar(prod('b', 5000));
      expect(c.subtotal, 25000);
    });
    test('rechaza más que las existencias y queda intacto', () {
      final c = Carrito()..agregar(prod('a', 100, stock: 3), cantidad: 2);
      expect(() => c.agregar(prod('a', 100, stock: 3), cantidad: 2),
          throwsA(isA<ExistenciasInsuficientesException>()));
      expect(c.cantidadTotal, 2);
    });
    test('límite de 10 por producto', () {
      final c = Carrito();
      expect(() => c.agregar(prod('a', 100, stock: 50), cantidad: 11),
          throwsA(isA<LimiteProductoException>()));
    });
    test('envío gratis desde \$800', () {
      expect((Carrito()..agregar(prod('a', 79999))).envio, Carrito.costoEnvio);
      expect((Carrito()..agregar(prod('a', 80000))).envio, 0);
    });
    test('cupón DOLORES10 descuenta 10%', () {
      final c = Carrito()
        ..agregar(prod('a', 10000))
        ..aplicarCupon(' dolores10 ');
      expect(c.descuento, 1000);
    });
    test('cupón inválido lanza', () {
      expect(() => Carrito().aplicarCupon('XYZ'), throwsA(isA<CuponInvalidoException>()));
    });
    test('restaurar recorta a existencias y descarta desconocidos', () {
      final c = Carrito();
      final p = prod('a', 100, stock: 2);
      c.restaurar([
        {'id': 'a', 'cantidad': 9},
        {'id': 'fantasma', 'cantidad': 1},
      ], (id) => id == 'a' ? p : null);
      expect(c.cantidadTotal, 2);
      expect(c.lineas.length, 1);
    });
    test('aMapas solo guarda id y cantidad', () {
      final c = Carrito()..agregar(prod('a', 100));
      expect(c.aMapas().first.keys.toSet(), {'id', 'cantidad'});
    });
  });

  group('validadores', () {
    test('correo', () {
      expect(validarCorreo('a@b.com'), isNull);
      expect(validarCorreo('abc'), isNotNull);
    });
    test('password', () {
      expect(validarPassword('abc12345'), isNull);
      expect(validarPassword('corta1'), isNotNull);
      expect(validarPassword('sololetras'), isNotNull);
    });
    test('código postal y teléfono', () {
      expect(validarCodigoPostal('37800'), isNull);
      expect(validarCodigoPostal('378'), isNotNull);
      expect(validarTelefono('4181234567'), isNull);
      expect(validarTelefono('123'), isNotNull);
    });
  });

  group('dirección, usuario y orden', () {
    const valida = Direccion(
      nombreRecibe: 'Ana Pérez',
      calle: 'Calle 5 de Febrero 10',
      colonia: 'Centro',
      codigoPostal: '37800',
      ciudad: 'Dolores Hidalgo',
      estado: 'Guanajuato',
      telefono: '418 123 4567',
    );

    test('dirección válida no tiene errores', () {
      expect(valida.errores(), isEmpty);
      expect(valida.esValida, isTrue);
    });
    test('dirección vacía marca los 7 campos a la vez', () {
      const vacia = Direccion(
          nombreRecibe: '',
          calle: '',
          colonia: '',
          codigoPostal: '',
          ciudad: '',
          estado: '',
          telefono: '');
      expect(vacia.errores().length, 7);
      expect(vacia.esValida, isFalse);
    });
    test('copiarCon del usuario no cambia id ni correo', () {
      const u = Usuario(id: 'u1', nombre: 'Ana Pérez', correo: 'ana@correo.com');
      final nuevo = u.copiarCon(nombre: 'Ana P.', direccion: valida);
      expect(nuevo.id, 'u1');
      expect(nuevo.correo, 'ana@correo.com');
      expect(nuevo.direccion!.codigoPostal, '37800');
    });
    test('la línea de orden calcula su importe con el precio guardado', () {
      const l = LineaOrden('taza', 'Taza Talavera', 3, 22000);
      expect(l.importe, 66000);
    });
  });

  group('tarjeta', () {
    test('Luhn válidas', () {
      for (final n in ['4242424242424242', '5555555555554444', '378282246310005']) {
        expect(ValidadorTarjeta.luhn(n), isTrue, reason: n);
      }
    });
    test('Luhn inválida', () => expect(ValidadorTarjeta.luhn('4242424242424241'), isFalse));
    test('acepta espacios',
        () => expect(ValidadorTarjeta.luhn('4242 4242 4242 4242'), isTrue));
    test('marcas', () {
      expect(ValidadorTarjeta.marca('4242424242424242'), Marca.visa);
      expect(ValidadorTarjeta.marca('5555555555554444'), Marca.mastercard);
      expect(ValidadorTarjeta.marca('378282246310005'), Marca.amex);
    });
    test('vigencia hasta el último día del mes', () {
      final hoy = DateTime(2026, 11, 30);
      expect(ValidadorTarjeta.vigente(11, 26, hoy: hoy), isTrue);
      expect(ValidadorTarjeta.vigente(10, 26, hoy: hoy), isFalse);
    });
    test('CVV de 4 dígitos solo en Amex', () {
      expect(ValidadorTarjeta.cvvValido('1234', Marca.amex), isTrue);
      expect(ValidadorTarjeta.cvvValido('123', Marca.visa), isTrue);
      expect(ValidadorTarjeta.cvvValido('1234', Marca.visa), isFalse);
    });
    test('toString nunca muestra el número completo', () {
      const t = DatosTarjeta(
          numero: '4242424242424242', titular: 'A', mes: 1, anio: 30, cvv: '123');
      expect(t.toString(), isNot(contains('4242424242424242')));
      expect(t.toString(), contains('4242'));
    });
  });
}