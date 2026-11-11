enum Marca { visa, mastercard, amex, desconocida }

class ValidadorTarjeta {
  static String soloDigitos(String s) => s.replaceAll(RegExp(r'\D'), '');

  /// Algoritmo de Luhn: detecta errores de captura (un dígito mal, dos intercambiados).
  /// OJO: solo sirve para ayudar al usuario. NO prueba que la tarjeta exista ni tenga fondos.
  static bool luhn(String numero) {
    final d = soloDigitos(numero);
    if (d.length < 12 || d.length > 19) return false;
    var suma = 0;
    var duplicar = false;
    for (var i = d.length - 1; i >= 0; i--) {
      var n = int.parse(d[i]);
      if (duplicar) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      suma += n;
      duplicar = !duplicar;
    }
    return suma % 10 == 0;
  }

  static Marca marca(String numero) {
    final d = soloDigitos(numero);
    if (d.startsWith('4')) return Marca.visa;
    if (d.startsWith('34') || d.startsWith('37')) return Marca.amex;
    if (d.length >= 2) {
      final dos = int.parse(d.substring(0, 2));
      if (dos >= 51 && dos <= 55) return Marca.mastercard;
    }
    if (d.length >= 4) {
      final cuatro = int.parse(d.substring(0, 4));
      if (cuatro >= 2221 && cuatro <= 2720) return Marca.mastercard;
    }
    return Marca.desconocida;
  }

  /// Una tarjeta vale hasta el ÚLTIMO día del mes de vencimiento.
  static bool vigente(int mes, int anio, {DateTime? hoy}) {
    if (mes < 1 || mes > 12) return false;
    final a = anio < 100 ? 2000 + anio : anio;
    final ahora = hoy ?? DateTime.now();
    final primerDiaDelMesSiguiente = DateTime(a, mes + 1, 1);
    return primerDiaDelMesSiguiente.isAfter(DateTime(ahora.year, ahora.month, ahora.day));
  }

  static bool cvvValido(String cvv, Marca marca) =>
      RegExp(r'^\d+$').hasMatch(cvv) && cvv.length == (marca == Marca.amex ? 4 : 3);
}

/// Datos de tarjeta: viven SOLO en memoria, el tiempo mínimo, y NUNCA se guardan ni se imprimen.
class DatosTarjeta {
  final String numero;
  final String titular;
  final int mes;
  final int anio;
  final String cvv;

  const DatosTarjeta({
    required this.numero,
    required this.titular,
    required this.mes,
    required this.anio,
    required this.cvv,
  });

  String get ultimos4 {
    final d = ValidadorTarjeta.soloDigitos(numero);
    return d.length <= 4 ? d : d.substring(d.length - 4);
  }

  Marca get marca => ValidadorTarjeta.marca(numero);

  /// Si alguien hace print(tarjeta) por accidente, no se filtra nada sensible.
  @override
  String toString() => '${marca.name} **** $ultimos4';
}