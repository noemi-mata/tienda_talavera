import 'package:flutter/foundation.dart';

import '../../dominio/contratos.dart';
import '../../dominio/excepciones.dart';
import '../../dominio/producto.dart';

class CatalogoViewModel extends ChangeNotifier {
  final RepositorioCatalogo _repo;
  CatalogoViewModel(this._repo);

  List<Producto> _todos = [];
  bool cargando = false;
  String? error;
  Categoria? categoria;
  String texto = '';
  bool soloAr = false;

  Future<void> cargar() async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      _todos = await _repo.listar();
    } catch (e) {
      error = mensajeSeguro(e);
    }
    cargando = false;
    notifyListeners();
  }

  /// Los filtros se combinan con AND: el producto debe cumplir todos.
  List<Producto> get visibles {
    final q = texto.trim().toLowerCase();
    return _todos.where((p) {
      if (categoria != null && p.categoria != categoria) return false;
      if (soloAr && !p.tieneModelo3d) return false;
      if (q.isNotEmpty &&
          !p.nombre.toLowerCase().contains(q) &&
          !p.descripcion.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
  }

  Producto? porId(String id) {
    for (final p in _todos) {
      if (p.id == id) return p;
    }
    return null;
  }

  void elegirCategoria(Categoria? c) {
    categoria = c;
    notifyListeners();
  }

  void buscar(String t) {
    texto = t;
    notifyListeners();
  }

  void alternarSoloAr() {
    soloAr = !soloAr;
    notifyListeners();
  }
}