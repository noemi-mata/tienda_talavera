import 'package:flutter/material.dart';

import '../../dependencias.dart';
import '../../dominio/dinero.dart';
import '../../dominio/direccion.dart';

class PantallaPerfil extends StatelessWidget {
  final Dependencias deps;
  const PantallaPerfil({super.key, required this.deps});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mi perfil')),
        body: ListenableBuilder(
          listenable: deps.sesion,
          builder: (context, _) =>
              deps.sesion.autenticado ? _Cuenta(deps: deps) : _Acceso(deps: deps),
        ),
      );
}

class _Acceso extends StatefulWidget {
  final Dependencias deps;
  const _Acceso({required this.deps});

  @override
  State<_Acceso> createState() => _AccesoState();
}

class _AccesoState extends State<_Acceso> {
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _pass = TextEditingController();
  bool _registro = false;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.deps.sesion;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(_registro ? 'Crear cuenta' : 'Iniciar sesión',
          style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 12),
      if (_registro)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(
              controller: _nombre,
              decoration:
                  const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())),
        ),
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
            controller: _correo,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Correo', border: OutlineInputBorder())),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
            controller: _pass,
            obscureText: true,
            decoration:
                const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder())),
      ),
      if (vm.error != null)
        Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(vm.error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
      FilledButton(
        onPressed: vm.ocupado
            ? null
            : () => _registro
                ? vm.registrar(_nombre.text, _correo.text, _pass.text)
                : vm.iniciar(_correo.text, _pass.text),
        child: Text(_registro ? 'Registrarme' : 'Entrar'),
      ),
      TextButton(
        onPressed: () => setState(() => _registro = !_registro),
        child: Text(_registro ? 'Ya tengo cuenta' : 'Crear una cuenta'),
      ),
    ]);
  }
}

class _Cuenta extends StatelessWidget {
  final Dependencias deps;
  const _Cuenta({required this.deps});

  @override
  Widget build(BuildContext context) {
    final vm = deps.sesion;
    final u = vm.usuario!;
    return ListView(padding: const EdgeInsets.all(16), children: [
      ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(u.nombre),
        subtitle: Text(u.correo),
      ),
      ListTile(
        leading: const Icon(Icons.home),
        title: const Text('Dirección de envío'),
        subtitle: Text(u.direccion?.toString() ?? 'Aún no guardas una dirección'),
        trailing: const Icon(Icons.edit),
        onTap: () => _editarDireccion(context),
      ),
      ListTile(
        leading: const Icon(Icons.favorite),
        title: Text('Favoritos: ${u.favoritos.length}'),
      ),
      const Divider(),
      Text('Mis compras', style: Theme.of(context).textTheme.titleMedium),
      if (vm.ordenes.isEmpty)
        const Padding(padding: EdgeInsets.all(8), child: Text('Aún no tienes compras.')),
      for (final o in vm.ordenes)
        ListTile(
          leading: const Icon(Icons.receipt_long),
          title: Text(o.id),
          subtitle: Text('${o.lineas.length} producto(s) · tarjeta **** ${o.tarjetaUltimos4}'),
          trailing: Text(formatearPesos(o.total)),
        ),
      const SizedBox(height: 12),
      OutlinedButton(onPressed: vm.cerrar, child: const Text('Cerrar sesión')),
    ]);
  }

  Future<void> _editarDireccion(BuildContext context) async {
    final d = deps.sesion.usuario!.direccion;
    final c = {
      'nombre': TextEditingController(text: d?.nombreRecibe),
      'calle': TextEditingController(text: d?.calle),
      'colonia': TextEditingController(text: d?.colonia),
      'cp': TextEditingController(text: d?.codigoPostal),
      'ciudad': TextEditingController(text: d?.ciudad ?? 'Dolores Hidalgo'),
      'estado': TextEditingController(text: d?.estado ?? 'Guanajuato'),
      'tel': TextEditingController(text: d?.telefono),
    };
    final etiquetas = {
      'nombre': 'Nombre',
      'calle': 'Calle y número',
      'colonia': 'Colonia',
      'cp': 'Código postal',
      'ciudad': 'Ciudad',
      'estado': 'Estado',
      'tel': 'Teléfono',
    };
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dirección de envío'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final k in c.keys)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                    controller: c[k], decoration: InputDecoration(labelText: etiquetas[k])),
              ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final nueva = Direccion(
                nombreRecibe: c['nombre']!.text,
                calle: c['calle']!.text,
                colonia: c['colonia']!.text,
                codigoPostal: c['cp']!.text,
                ciudad: c['ciudad']!.text,
                estado: c['estado']!.text,
                telefono: c['tel']!.text,
              );
              final ok = await deps.sesion
                  .actualizarPerfil(deps.sesion.usuario!.copiarCon(direccion: nueva));
              if (ok && ctx.mounted) Navigator.pop(ctx);
              if (!ok && ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(deps.sesion.error ?? 'Error')));
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    for (final x in c.values) {
      x.dispose();
    }
  }
}