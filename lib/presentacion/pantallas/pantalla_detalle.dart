import 'package:flutter/material.dart';

import '../../dependencias.dart';
import '../../dominio/dinero.dart';
import 'pantalla_ver_en_tu_espacio.dart';

class PantallaDetalle extends StatelessWidget {
  final Dependencias deps;
  final String productoId;
  const PantallaDetalle({super.key, required this.deps, required this.productoId});

  @override
  Widget build(BuildContext context) {
    final p = deps.catalogo.porId(productoId);
    if (p == null) return const Scaffold(body: Center(child: Text('Producto no encontrado')));

    return Scaffold(
      appBar: AppBar(
        title: Text(p.nombre),
        actions: [
          ListenableBuilder(
            listenable: deps.sesion,
            builder: (_, __) => IconButton(
              tooltip: 'Favorito',
              icon: Icon(deps.sesion.esFavorito(p.id) ? Icons.favorite : Icons.favorite_border),
              onPressed: () {
                if (!deps.sesion.autenticado) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Inicia sesión en Perfil para guardar favoritos.')),
                  );
                } else {
                  deps.sesion.alternarFavorito(p.id);
                }
              },
            ),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(child: Text(p.emoji, style: const TextStyle(fontSize: 110))),
        const SizedBox(height: 12),
        Text(p.nombre, style: Theme.of(context).textTheme.headlineSmall),
        Text(formatearPesos(p.precioCentavos), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(p.descripcion),
        if (p.dimensiones != null) ...[
          const SizedBox(height: 8),
          Text('Medidas: ${p.dimensiones}'),
        ],
        const SizedBox(height: 8),
        Text(p.existencias > 0 ? 'Disponibles: ${p.existencias}' : 'Agotado'),
        const SizedBox(height: 16),
        if (p.tieneModelo3d) ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.view_in_ar),
            label: const Text('Ver en tu espacio (AR)'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PantallaVerEnTuEspacio(producto: p)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Disponible en teléfonos compatibles con AR.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
          ),
        ],
        const SizedBox(height: 8),
        FilledButton.icon(
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Agregar al carrito'),
          onPressed: p.existencias == 0
              ? null
              : () async {
                  await deps.carrito.agregar(p);
                  if (!context.mounted) return;
                  final msg = deps.carrito.tomarMensaje() ?? 'Agregado al carrito';
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                },
        ),
      ]),
    );
  }
}