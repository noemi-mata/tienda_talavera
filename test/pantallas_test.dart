import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tienda_talavera/datos/almacenes.dart';
import 'package:tienda_talavera/datos/catalogo_memoria.dart';
import 'package:tienda_talavera/datos/pasarela_simulada.dart';
import 'package:tienda_talavera/dependencias.dart';
import 'package:tienda_talavera/presentacion/pantallas/pantalla_carrito.dart';
import 'package:tienda_talavera/presentacion/pantallas/pantalla_catalogo.dart';
import 'package:tienda_talavera/presentacion/pantallas/pantalla_detalle.dart';
import 'package:tienda_talavera/presentacion/pantallas/pantalla_perfil.dart';
import 'package:tienda_talavera/presentacion/pantallas/pantalla_ver_en_tu_espacio.dart';

/// Dependencias 100 % en memoria: sin plugins, sin disco y sin red.
Future<Dependencias> armarDeps() async {
  final deps = Dependencias.crear(
    almacenCarrito: AlmacenCarritoMemoria(),
    almacenSeguro: AlmacenSeguroMemoria(),
    pasarela: PasarelaSimulada(),
  );
  await deps.iniciar();
  return deps;
}

Widget app(Widget pantalla) => MaterialApp(home: pantalla);

void main() {
  group('pantallas', () {
    testWidgets('el catalogo muestra productos y filtra por AR', (tester) async {
      final deps = await armarDeps();
      await tester.pumpWidget(app(PantallaCatalogo(deps: deps)));
      expect(find.text('Jarrón Talavera azul'), findsOneWidget);
      expect(find.text('Plato decorativo Talavera'), findsOneWidget);

      // El chip "Solo AR" queda fuera de la pantalla de prueba (800 px):
      // primero se desliza la fila de chips hasta que se vea y luego se toca.
      final chipAr = find.ancestor(
        of: find.textContaining('Solo AR'),
        matching: find.byType(FilterChip),
      );
      await tester.ensureVisible(chipAr);
      await tester.pumpAndSettle();
      await tester.tap(chipAr);
      await tester.pump();

      expect(find.text('Jarrón Talavera azul'), findsOneWidget);
      expect(find.text('Caballito decorativo'), findsOneWidget);
      expect(find.text('Plato decorativo Talavera'), findsNothing);
    });

    testWidgets('carrito vacio muestra mensaje', (tester) async {
      final deps = await armarDeps();
      await tester.pumpWidget(app(PantallaCarrito(deps: deps)));
      expect(find.textContaining('Tu carrito está vacío'), findsOneWidget);
    });

    testWidgets('pagar sin sesion pide iniciar sesion', (tester) async {
      final deps = await armarDeps();
      await deps.carrito.agregar(deps.catalogo.porId('taza')!);
      await tester.pumpWidget(app(PantallaCarrito(deps: deps)));
      expect(find.text('Taza Talavera'), findsOneWidget);

      await tester.tap(find.text('Ir a pagar'));
      await tester.pump();
      expect(find.text('Inicia sesión en Perfil para pagar.'), findsOneWidget);
    });

    testWidgets('perfil sin sesion muestra el acceso', (tester) async {
      final deps = await armarDeps();
      await tester.pumpWidget(app(PantallaPerfil(deps: deps)));
      expect(find.text('Iniciar sesión'), findsOneWidget);

      await tester.tap(find.text('Crear una cuenta'));
      await tester.pump();
      expect(find.text('Registrarme'), findsOneWidget);
    });
  });

  group('ver en tu espacio', () {
    testWidgets('producto sin modelo 3D muestra aviso', (tester) async {
      final plato = catalogoInicial.firstWhere((p) => p.id == 'plato');
      await tester.pumpWidget(app(PantallaVerEnTuEspacio(producto: plato)));
      expect(find.text('Este producto aún no tiene modelo 3D.'), findsOneWidget);
    });

    testWidgets('detalle con modelo 3D muestra boton AR', (tester) async {
      final deps = await armarDeps();
      await tester.pumpWidget(app(PantallaDetalle(deps: deps, productoId: 'jarron')));
      expect(find.text('Ver en tu espacio (AR)'), findsOneWidget);
    });

    testWidgets('detalle sin modelo 3D NO muestra boton AR', (tester) async {
      final deps = await armarDeps();
      await tester.pumpWidget(app(PantallaDetalle(deps: deps, productoId: 'plato')));
      expect(find.text('Ver en tu espacio (AR)'), findsNothing);
      expect(find.text('Agregar al carrito'), findsOneWidget);
    });
  });
}