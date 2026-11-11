import 'package:flutter/material.dart';

import 'dependencias.dart';
import 'presentacion/pantallas/pantalla_carrito.dart';
import 'presentacion/pantallas/pantalla_catalogo.dart';
import 'presentacion/pantallas/pantalla_perfil.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TiendaApp());
}

class TiendaApp extends StatelessWidget {
  const TiendaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Talavera Dolores',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F4E9C)),
          useMaterial3: true,
        ),
        home: const _Raiz(),
      );
}

class _Raiz extends StatefulWidget {
  const _Raiz();
  @override
  State<_Raiz> createState() => _RaizState();
}

class _RaizState extends State<_Raiz> {
  late final Dependencias deps = Dependencias.crear();
  late final Future<void> _inicio = deps.iniciar();
  int _tab = 0;

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: _inicio,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final paginas = [
            PantallaCatalogo(deps: deps),
            PantallaCarrito(deps: deps),
            PantallaPerfil(deps: deps),
          ];
          return Scaffold(
            body: IndexedStack(index: _tab, children: paginas),
            bottomNavigationBar: ListenableBuilder(
              listenable: deps.carrito,
              builder: (_, __) => NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: (i) => setState(() => _tab = i),
                destinations: [
                  const NavigationDestination(icon: Icon(Icons.storefront), label: 'Catálogo'),
                  NavigationDestination(
                    icon: Badge(
                      isLabelVisible: deps.carrito.carrito.cantidadTotal > 0,
                      label: Text('${deps.carrito.carrito.cantidadTotal}'),
                      child: const Icon(Icons.shopping_cart),
                    ),
                    label: 'Carrito',
                  ),
                  const NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
                ],
              ),
            ),
          );
        },
      );
}