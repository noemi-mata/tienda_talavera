import 'package:flutter/material.dart';

import '../../dependencias.dart';
import '../../dominio/dinero.dart';
import 'pantalla_checkout.dart';

class PantallaCarrito extends StatefulWidget {
  final Dependencias deps;
  const PantallaCarrito({super.key, required this.deps});
  @override
  State<PantallaCarrito> createState() => _PantallaCarritoState();
}

class _PantallaCarritoState extends State<PantallaCarrito> {
  final _cupon = TextEditingController();

  @override
  void dispose() {
    _cupon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.deps.carrito;
    return Scaffold(
      appBar: AppBar(title: const Text('Tu carrito')),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          final c = vm.carrito;
          final msg = vm.tomarMensaje();
          if (msg != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
              }
            });
          }
          if (c.estaVacio) return const Center(child: Text('Tu carrito está vacío 🛒'));
          return Column(children: [
            Expanded(
              child: ListView(children: [
                for (final l in c.lineas)
                  ListTile(
                    leading: Text(l.producto.emoji, style: const TextStyle(fontSize: 32)),
                    title: Text(l.producto.nombre),
                    subtitle: Text(formatearPesos(l.importe)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => vm.cambiarCantidad(l.producto.id, l.cantidad - 1),
                      ),
                      Text('${l.cantidad}'),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => vm.cambiarCantidad(l.producto.id, l.cantidad + 1),
                      ),
                    ]),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _cupon,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Cupón',
                          border: const OutlineInputBorder(),
                          helperText: c.cupon == null ? null : 'Aplicado: ${c.cupon!.codigo}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () =>
                          c.cupon == null ? vm.aplicarCupon(_cupon.text) : vm.quitarCupon(),
                      child: Text(c.cupon == null ? 'Aplicar' : 'Quitar'),
                    ),
                  ]),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _Fila('Subtotal', formatearPesos(c.subtotal)),
                if (c.descuento > 0) _Fila('Descuento', '- ${formatearPesos(c.descuento)}'),
                _Fila('Envío', c.envio == 0 ? 'Gratis' : formatearPesos(c.envio)),
                if (c.faltaParaEnvioGratis > 0)
                  Text('Agrega ${formatearPesos(c.faltaParaEnvioGratis)} más para envío gratis 🚚'),
                _Fila('Total', formatearPesos(c.total), fuerte: true),
                _Fila('(IVA incluido)', formatearPesos(c.iva)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (!widget.deps.sesion.autenticado) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Inicia sesión en Perfil para pagar.')),
                        );
                        return;
                      }
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PantallaCheckout(deps: widget.deps),
                      ));
                    },
                    child: const Text('Ir a pagar'),
                  ),
                ),
              ]),
            ),
          ]);
        },
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final String a;
  final String b;
  final bool fuerte;
  const _Fila(this.a, this.b, {this.fuerte = false});

  @override
  Widget build(BuildContext context) {
    final estilo = fuerte ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 18) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(a, style: estilo), Text(b, style: estilo)],
      ),
    );
  }
}