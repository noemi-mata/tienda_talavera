import 'package:flutter/material.dart';

import '../../dependencias.dart';
import '../../dominio/dinero.dart';
import '../../dominio/direccion.dart';
import '../../dominio/tarjeta.dart';
import '../vm/checkout_vm.dart';

class PantallaCheckout extends StatefulWidget {
  final Dependencias deps;
  const PantallaCheckout({super.key, required this.deps});
  @override
  State<PantallaCheckout> createState() => _PantallaCheckoutState();
}

class _PantallaCheckoutState extends State<PantallaCheckout> {
  final _c = {
    for (final k in [
      'nombre', 'calle', 'colonia', 'cp', 'ciudad', 'estado', 'tel',
      'titular', 'numero', 'mes', 'anio', 'cvv',
    ])
      k: TextEditingController()
  };

  @override
  void initState() {
    super.initState();
    widget.deps.checkout.reiniciar();
    final d = widget.deps.sesion.usuario?.direccion;
    if (d != null) {
      _c['nombre']!.text = d.nombreRecibe;
      _c['calle']!.text = d.calle;
      _c['colonia']!.text = d.colonia;
      _c['cp']!.text = d.codigoPostal;
      _c['ciudad']!.text = d.ciudad;
      _c['estado']!.text = d.estado;
      _c['tel']!.text = d.telefono;
    }
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose(); // el número y el CVV no deben quedarse en memoria más de lo necesario
    }
    super.dispose();
  }

  Widget _campo(String k, String etiqueta, {TextInputType? tipo, bool oculto = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: _c[k],
          keyboardType: tipo,
          obscureText: oculto,
          decoration: InputDecoration(labelText: etiqueta, border: const OutlineInputBorder()),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final vm = widget.deps.checkout;
    return Scaffold(
      appBar: AppBar(title: const Text('Finalizar compra')),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) => ListView(padding: const EdgeInsets.all(16), children: [
          if (vm.error != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(padding: const EdgeInsets.all(12), child: Text(vm.error!)),
            ),
          if (vm.paso == PasoCheckout.direccion) ..._pasoDireccion(vm),
          if (vm.paso == PasoCheckout.pago) ..._pasoPago(vm),
          if (vm.paso == PasoCheckout.confirmacion) ..._pasoConfirmacion(vm),
        ]),
      ),
    );
  }

  List<Widget> _pasoDireccion(CheckoutViewModel vm) => [
        Text('1. Dirección de envío', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _campo('nombre', 'Nombre de quien recibe'),
        _campo('calle', 'Calle y número'),
        _campo('colonia', 'Colonia'),
        _campo('cp', 'Código postal', tipo: TextInputType.number),
        _campo('ciudad', 'Ciudad'),
        _campo('estado', 'Estado'),
        _campo('tel', 'Teléfono (10 dígitos)', tipo: TextInputType.phone),
        FilledButton(
          onPressed: () => vm.guardarDireccion(Direccion(
            nombreRecibe: _c['nombre']!.text,
            calle: _c['calle']!.text,
            colonia: _c['colonia']!.text,
            codigoPostal: _c['cp']!.text,
            ciudad: _c['ciudad']!.text,
            estado: _c['estado']!.text,
            telefono: _c['tel']!.text,
          )),
          child: const Text('Continuar'),
        ),
      ];

  List<Widget> _pasoPago(CheckoutViewModel vm) {
    final carrito = widget.deps.carrito.carrito;
    return [
      Text('2. Pago', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 4),
      const Text('Modo práctica: usa 4242 4242 4242 4242, cualquier fecha futura y CVV 123.'),
      const SizedBox(height: 12),
      _campo('titular', 'Nombre en la tarjeta'),
      _campo('numero', 'Número de tarjeta', tipo: TextInputType.number),
      Row(children: [
        Expanded(child: _campo('mes', 'Mes (MM)', tipo: TextInputType.number)),
        const SizedBox(width: 8),
        Expanded(child: _campo('anio', 'Año (AA)', tipo: TextInputType.number)),
        const SizedBox(width: 8),
        Expanded(child: _campo('cvv', 'CVV', tipo: TextInputType.number, oculto: true)),
      ]),
      FilledButton(
        onPressed: vm.procesando
            ? null
            : () async {
                final tarjeta = DatosTarjeta(
                  numero: _c['numero']!.text,
                  titular: _c['titular']!.text,
                  mes: int.tryParse(_c['mes']!.text) ?? 0,
                  anio: int.tryParse(_c['anio']!.text) ?? 0,
                  cvv: _c['cvv']!.text,
                );
                final ok = await vm.pagar(
                  usuarioId: widget.deps.sesion.usuario!.id,
                  carrito: carrito,
                  tarjeta: tarjeta,
                );
                if (ok) {
                  _c['numero']!.clear();
                  _c['cvv']!.clear();
                  await widget.deps.carrito.vaciar();
                  await widget.deps.sesion.refrescarOrdenes();
                  await widget.deps.catalogo.cargar(); // existencias actualizadas
                }
              },
        child: vm.procesando
            ? const SizedBox(
                height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text('Pagar ${formatearPesos(carrito.total)}'),
      ),
      TextButton(onPressed: vm.volver, child: const Text('Volver')),
    ];
  }

  List<Widget> _pasoConfirmacion(CheckoutViewModel vm) {
    final o = vm.ordenConfirmada!;
    return [
      const Center(child: Text('✅', style: TextStyle(fontSize: 72))),
      Center(
          child: Text('¡Gracias por tu compra!',
              style: Theme.of(context).textTheme.headlineSmall)),
      const SizedBox(height: 12),
      Text('Orden: ${o.id}'),
      Text('Pago: ${o.referenciaPago} (tarjeta **** ${o.tarjetaUltimos4})'),
      Text('Total: ${formatearPesos(o.total)}'),
      Text('Enviamos a: ${o.direccion}'),
      const SizedBox(height: 16),
      FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Volver a la tienda')),
    ];
  }
}