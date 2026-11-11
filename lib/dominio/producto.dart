enum Categoria { talavera, dulces, textiles, decoracion }

extension NombreCategoria on Categoria {
  String get nombre => switch (this) {
        Categoria.talavera => 'Talavera',
        Categoria.dulces => 'Dulces',
        Categoria.textiles => 'Textiles',
        Categoria.decoracion => 'Decoración',
      };
}

class Dimensiones {
  final int altoCm;
  final int anchoCm;
  final int fondoCm;
  const Dimensiones(this.altoCm, this.anchoCm, this.fondoCm);

  @override
  String toString() => '$altoCm × $anchoCm × $fondoCm cm (alto × ancho × fondo)';
}

class Producto {
  final String id;
  final String nombre;
  final String descripcion;
  final int precioCentavos;
  final Categoria categoria;
  final int existencias;
  final String emoji;
  final Dimensiones? dimensiones;

  /// Modelo 3D para "Ver en tu espacio". Android usa .glb; iPhone necesita .usdz.
  final String? modeloGlb;
  final String? modeloUsdz;

  const Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precioCentavos,
    required this.categoria,
    required this.existencias,
    required this.emoji,
    this.dimensiones,
    this.modeloGlb,
    this.modeloUsdz,
  });

  /// Solo aceptamos modelos locales (assets/) o por https. Nunca http://.
  bool get tieneModelo3d {
    final m = modeloGlb;
    return m != null && (m.startsWith('https://') || m.startsWith('assets/'));
  }

  Producto copiarCon({int? existencias, int? precioCentavos}) => Producto(
        id: id,
        nombre: nombre,
        descripcion: descripcion,
        precioCentavos: precioCentavos ?? this.precioCentavos,
        categoria: categoria,
        existencias: existencias ?? this.existencias,
        emoji: emoji,
        dimensiones: dimensiones,
        modeloGlb: modeloGlb,
        modeloUsdz: modeloUsdz,
      );
}