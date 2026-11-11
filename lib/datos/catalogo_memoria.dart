import '../dominio/contratos.dart';
import '../dominio/excepciones.dart';
import '../dominio/producto.dart';

/// ⚠️ Los modelos 3D de abajo son de PRÁCTICA (un astronauta y un caballo de la
/// galería de ejemplos de model-viewer). Reemplázalos por modelos propios de
/// tus productos.
const _astronauta = 'https://modelviewer.dev/shared-assets/models/Astronaut.glb';
const _astronautaIos = 'https://modelviewer.dev/shared-assets/models/Astronaut.usdz';
const _caballo = 'https://modelviewer.dev/shared-assets/models/Horse.glb';

const catalogoInicial = <Producto>[
  Producto(
    id: 'jarron',
    nombre: 'Jarrón Talavera azul',
    descripcion: 'Jarrón pintado a mano con motivos florales en azul cobalto.',
    precioCentavos: 125000,
    categoria: Categoria.talavera,
    existencias: 8,
    emoji: '🏺',
    dimensiones: Dimensiones(30, 18, 18),
    modeloGlb: _astronauta,
    modeloUsdz: _astronautaIos,
  ),
  Producto(
    id: 'plato',
    nombre: 'Plato decorativo Talavera',
    descripcion: 'Plato para colgar en pared, esmaltado y pintado a mano.',
    precioCentavos: 48000,
    categoria: Categoria.talavera,
    existencias: 15,
    emoji: '🍽️',
    dimensiones: Dimensiones(3, 28, 28),
  ),
  Producto(
    id: 'taza',
    nombre: 'Taza Talavera',
    descripcion: 'Taza de cerámica para café de olla, lista para usarse.',
    precioCentavos: 22000,
    categoria: Categoria.talavera,
    existencias: 20,
    emoji: '☕',
    dimensiones: Dimensiones(10, 9, 9),
  ),
  Producto(
    id: 'caballo',
    nombre: 'Caballito decorativo',
    descripcion: 'Figura artesanal de caballo para repisa o mesa de centro.',
    precioCentavos: 65000,
    categoria: Categoria.decoracion,
    existencias: 6,
    emoji: '🐴',
    dimensiones: Dimensiones(28, 30, 10),
    modeloGlb: _caballo,
  ),
  Producto(
    id: 'cajeta',
    nombre: 'Cajeta artesanal',
    descripcion: 'Dulce de leche de cabra en frasco de vidrio (250 g).',
    precioCentavos: 9500,
    categoria: Categoria.dulces,
    existencias: 40,
    emoji: '🍯',
  ),
  Producto(
    id: 'alegrias',
    nombre: 'Alegrías de amaranto',
    descripcion: 'Caja con 12 alegrías de amaranto y miel.',
    precioCentavos: 7500,
    categoria: Categoria.dulces,
    existencias: 60,
    emoji: '🍬',
  ),
  Producto(
    id: 'rebozo',
    nombre: 'Rebozo tejido',
    descripcion: 'Rebozo de algodón tejido en telar, colores vivos.',
    precioCentavos: 89000,
    categoria: Categoria.textiles,
    existencias: 5,
    emoji: '🧣',
  ),
  Producto(
    id: 'mantel',
    nombre: 'Mantel bordado',
    descripcion: 'Mantel de manta con bordado a mano para 6 personas.',
    precioCentavos: 54000,
    categoria: Categoria.textiles,
    existencias: 10,
    emoji: '🧵',
  ),
];

/// Catálogo en memoria. En una app real aquí hablarías con un servidor:
/// el resto de la app no notaría el cambio.
class CatalogoMemoria implements RepositorioCatalogo {
  final Map<String, Producto> _productos;

  CatalogoMemoria([List<Producto> productos = catalogoInicial])
      : _productos = {for (final p in productos) p.id: p};

  @override
  Future<List<Producto>> listar() async => _productos.values.toList();

  @override
  Future<Producto?> porId(String id) async => _productos[id];

  @override
  Future<void> descontar(String id, int cantidad) async {
    final p = _productos[id];
    if (p == null) throw const ProductoNoDisponibleException();
    if (p.existencias < cantidad) {
      throw ExistenciasInsuficientesException(p.nombre, p.existencias);
    }
    _productos[id] = p.copiarCon(existencias: p.existencias - cantidad);
  }

  /// Solo para pruebas: simula que el dueño cambió el precio.
  void cambiarPrecio(String id, int nuevoPrecio) {
    _productos[id] = _productos[id]!.copiarCon(precioCentavos: nuevoPrecio);
  }
}