/// Todo el dinero se maneja en CENTAVOS ENTEROS (int): sin errores de double.
String formatearPesos(int centavos) {
  final negativo = centavos < 0;
  final abs = centavos.abs();
  final pesos = (abs ~/ 100).toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );
  final cents = (abs % 100).toString().padLeft(2, '0');
  return '${negativo ? '-' : ''}\$$pesos.$cents';
}

/// [pct]% de [centavos], redondeado al centavo más cercano (solo con enteros).
int porcentaje(int centavos, int pct) => (centavos * pct + 50) ~/ 100;

/// En México los precios ya incluyen IVA: esto desglosa el IVA de un total.
int ivaIncluido(int totalCentavos, {int tasa = 16}) =>
    (totalCentavos * tasa + (100 + tasa) ~/ 2) ~/ (100 + tasa);