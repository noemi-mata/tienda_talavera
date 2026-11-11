import 'direccion.dart';

class Usuario {
  final String id;
  final String nombre;
  final String correo;
  final String telefono;
  final Direccion? direccion;
  final Set<String> favoritos;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    this.telefono = '',
    this.direccion,
    this.favoritos = const {},
  });

  Usuario copiarCon({
    String? nombre,
    String? telefono,
    Direccion? direccion,
    Set<String>? favoritos,
  }) =>
      Usuario(
        id: id,
        nombre: nombre ?? this.nombre,
        correo: correo,
        telefono: telefono ?? this.telefono,
        direccion: direccion ?? this.direccion,
        favoritos: favoritos ?? this.favoritos,
      );
}