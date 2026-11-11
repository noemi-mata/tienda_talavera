import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../dominio/producto.dart';

/// "Ver en tu espacio": visor 3D + realidad aumentada con model_viewer_plus.
/// - Android: abre Scene Viewer (ARCore) con el .glb.
/// - iPhone: abre AR Quick Look con el .usdz (iosSrc).
/// - Si el teléfono no soporta AR, el visor 3D sigue funcionando (rotar y acercar).
class PantallaVerEnTuEspacio extends StatelessWidget {
  final Producto producto;
  const PantallaVerEnTuEspacio({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    // Defensa: solo mostramos modelos que pasaron la validación (https o assets).
    if (!producto.tieneModelo3d) {
      return Scaffold(
        appBar: AppBar(title: Text(producto.nombre)),
        body: const Center(child: Text('Este producto aún no tiene modelo 3D.')),
      );
    }
    final ios = producto.modeloUsdz;
    return Scaffold(
      appBar: AppBar(title: Text(producto.nombre)),
      body: Column(children: [
        Expanded(
          child: ModelViewer(
            src: producto.modeloGlb!,
            iosSrc: (ios != null && ios.startsWith('https://')) ? ios : null,
            alt: 'Modelo 3D de ${producto.nombre}',
            ar: true,
            arModes: const ['scene-viewer', 'webxr', 'quick-look'],
            arScale: ArScale.fixed, // tamaño real: NO se puede agrandar al colocarlo
            autoRotate: true,
            cameraControls: true,
            disableZoom: false,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (producto.dimensiones != null)
              Text('Tamaño real: ${producto.dimensiones}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Toca el botón de AR del visor, apunta al piso o la mesa y '
                'mueve el teléfono despacio para que detecte la superficie.'),
          ]),
        ),
      ]),
    );
  }
}