/// Frena los ataques de "fuerza bruta": tras [maxIntentos] fallos seguidos,
/// la cuenta se bloquea [duracion]. El reloj se inyecta para poder probarlo.
class BloqueoIntentos {
  final int maxIntentos;
  final Duration duracion;
  final DateTime Function() _reloj;
  final Map<String, int> _fallos = {};
  final Map<String, DateTime> _hasta = {};

  BloqueoIntentos({
    this.maxIntentos = 5,
    this.duracion = const Duration(minutes: 15),
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now;

  void registrarFallo(String clave) {
    final n = (_fallos[clave] ?? 0) + 1;
    if (n >= maxIntentos) {
      _hasta[clave] = _reloj().add(duracion);
      _fallos[clave] = 0;
    } else {
      _fallos[clave] = n;
    }
  }

  void registrarExito(String clave) {
    _fallos.remove(clave);
    _hasta.remove(clave);
  }

  Duration? restante(String clave) {
    final h = _hasta[clave];
    if (h == null) return null;
    final r = h.difference(_reloj());
    return r.isNegative ? null : r;
  }

  bool estaBloqueado(String clave) => restante(clave) != null;
}