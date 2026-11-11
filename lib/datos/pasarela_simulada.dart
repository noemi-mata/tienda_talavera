import '../dominio/contratos.dart';
import '../dominio/tarjeta.dart';

/// Pasarela de pagos SIMULADA para practicar. Imita el comportamiento de una real
/// (Stripe, Mercado Pago, Conekta...) con tarjetas de prueba:
///   4242 4242 4242 4242 → aprobada
///   4000 0000 0000 0002 → rechazada por el banco
///   4000 0000 0000 9995 → fondos insuficientes
/// NUNCA procesa dinero real ni guarda datos de tarjeta.
class PasarelaSimulada implements PasarelaPago {
  static const int limiteCentavos = 5000000; // $50,000

  final Duration latencia;
  final Map<String, ResultadoPago> _vistos = {};
  int cobrosAprobados = 0;
  int _secuencia = 1000;

  PasarelaSimulada({this.latencia = Duration.zero});

  @override
  Future<ResultadoPago> cobrar({
    required int montoCentavos,
    required DatosTarjeta tarjeta,
    required String claveIdempotencia,
  }) async {
    // Idempotencia: si ya procesamos esta clave, devolvemos lo MISMO sin cobrar otra vez.
    final previo = _vistos[claveIdempotencia];
    if (previo != null) return previo;

    if (latencia > Duration.zero) await Future<void>.delayed(latencia);

    final numero = ValidadorTarjeta.soloDigitos(tarjeta.numero);
    final ResultadoPago r;
    if (montoCentavos <= 0) {
      r = const PagoRechazado('Monto inválido');
    } else if (montoCentavos > limiteCentavos) {
      r = const PagoRechazado('El monto excede el límite permitido');
    } else if (numero == '4000000000000002') {
      r = const PagoRechazado('Tarjeta rechazada por el banco');
    } else if (numero == '4000000000009995') {
      r = const PagoRechazado('Fondos insuficientes');
    } else {
      r = PagoAprobado('PAY-${_secuencia++}');
      cobrosAprobados++;
    }
    _vistos[claveIdempotencia] = r;
    return r;
  }
}