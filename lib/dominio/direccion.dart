import 'validadores.dart';

class Direccion {
  final String nombreRecibe;
  final String calle;
  final String colonia;
  final String codigoPostal;
  final String ciudad;
  final String estado;
  final String telefono;

  const Direccion({
    required this.nombreRecibe,
    required this.calle,
    required this.colonia,
    required this.codigoPostal,
    required this.ciudad,
    required this.estado,
    required this.telefono,
  });

  /// Todos los errores a la vez (para marcar el formulario completo).
  List<String> errores() => [
        validarNombre(nombreRecibe),
        validarTextoObligatorio(calle, 'la calle y número'),
        validarTextoObligatorio(colonia, 'la colonia'),
        validarCodigoPostal(codigoPostal),
        validarTextoObligatorio(ciudad, 'la ciudad'),
        validarTextoObligatorio(estado, 'el estado'),
        validarTelefono(telefono),
      ].whereType<String>().toList();

  bool get esValida => errores().isEmpty;

  @override
  String toString() => '$calle, $colonia, C.P. $codigoPostal, $ciudad, $estado';
}