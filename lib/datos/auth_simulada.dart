import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../dominio/bloqueo_intentos.dart';
import '../dominio/contratos.dart';
import '../dominio/excepciones.dart';
import '../dominio/usuario.dart';
import '../dominio/validadores.dart';

class _Registro {
  final Usuario usuario;
  final String sal;
  final String hash;
  const _Registro(this.usuario, this.sal, this.hash);
  _Registro conUsuario(Usuario u) => _Registro(u, sal, hash);
}

/// "Servidor" de autenticación simulado, para practicar el CLIENTE.
/// - NUNCA guarda la contraseña: guarda sal + hash.
/// - Mensajes genéricos de error (no revela si el correo existe).
/// - Bloquea la cuenta tras varios intentos fallidos.
/// - Entrega un token aleatorio que la app guarda en almacenamiento SEGURO.
/// ⚠️ En un backend real usa bcrypt, scrypt o Argon2 (lentos a propósito), no SHA-256.
class AuthSimulada implements ServicioAuth {
  static const _claveToken = 'token_sesion';

  final AlmacenSeguro _seguro;
  final BloqueoIntentos _bloqueo;
  final String Function() _generarToken;
  final String Function() _generarSal;
  final Map<String, _Registro> _usuarios = {}; // por correo en minúsculas
  final Map<String, String> _sesiones = {}; // token → correo
  int _contador = 0;

  AuthSimulada(
    this._seguro, {
    BloqueoIntentos? bloqueo,
    String Function()? generarToken,
    String Function()? generarSal,
  })  : _bloqueo = bloqueo ?? BloqueoIntentos(),
        _generarToken = generarToken ?? _aleatorio,
        _generarSal = generarSal ?? _aleatorio;

  static String _aleatorio() {
    final r = Random.secure(); // aleatorio criptográficamente seguro (NO Random())
    return base64Url.encode(List<int>.generate(32, (_) => r.nextInt(256)));
  }

  static String _hash(String sal, String password) =>
      sha256.convert(utf8.encode('$sal:$password')).toString();

  static String _clave(String correo) => correo.trim().toLowerCase();

  @override
  Future<Usuario> registrar({
    required String nombre,
    required String correo,
    required String password,
  }) async {
    final error = validarNombre(nombre) ?? validarCorreo(correo) ?? validarPassword(password);
    if (error != null) throw DatosInvalidosException(error);

    final clave = _clave(correo);
    if (_usuarios.containsKey(clave)) throw const CorreoRegistradoException();

    final sal = _generarSal();
    final usuario = Usuario(id: 'u${++_contador}', nombre: nombre.trim(), correo: clave);
    _usuarios[clave] = _Registro(usuario, sal, _hash(sal, password));
    await _abrirSesion(clave);
    return usuario;
  }

  @override
  Future<Usuario> iniciarSesion({required String correo, required String password}) async {
    final clave = _clave(correo);

    final restante = _bloqueo.restante(clave);
    if (restante != null) throw CuentaBloqueadaException(restante);

    final registro = _usuarios[clave];
    // Se calcula el hash aunque el correo no exista: tarda lo mismo en ambos casos.
    final hash = _hash(registro?.sal ?? 'sal-falsa', password);
    if (registro == null || hash != registro.hash) {
      _bloqueo.registrarFallo(clave);
      throw const CredencialesInvalidasException();
    }

    _bloqueo.registrarExito(clave);
    await _abrirSesion(clave);
    return registro.usuario;
  }

  Future<void> _abrirSesion(String correo) async {
    final token = _generarToken();
    _sesiones[token] = correo;
    await _seguro.escribir(_claveToken, token);
  }

  @override
  Future<Usuario?> restaurarSesion() async {
    final token = await _seguro.leer(_claveToken);
    if (token == null) return null;
    final correo = _sesiones[token];
    if (correo == null) {
      await _seguro.borrar(_claveToken); // token viejo o inválido: se descarta
      return null;
    }
    return _usuarios[correo]?.usuario;
  }

  @override
  Future<void> cerrarSesion() async {
    final token = await _seguro.leer(_claveToken);
    if (token != null) _sesiones.remove(token);
    await _seguro.borrar(_claveToken);
  }

  @override
  Future<Usuario> actualizarPerfil(Usuario nuevo) async {
    final token = await _seguro.leer(_claveToken);
    final correo = token == null ? null : _sesiones[token];
    final registro = correo == null ? null : _usuarios[correo];
    if (registro == null) throw const SesionRequeridaException();

    final error = validarNombre(nuevo.nombre) ??
        (nuevo.telefono.isEmpty ? null : validarTelefono(nuevo.telefono));
    if (error != null) throw DatosInvalidosException(error);
    final dir = nuevo.direccion;
    if (dir != null && dir.errores().isNotEmpty) {
      throw DatosInvalidosException(dir.errores().first);
    }

    // El id y el correo NO se pueden cambiar desde el cliente.
    final guardado = registro.usuario.copiarCon(
      nombre: nuevo.nombre.trim(),
      telefono: nuevo.telefono,
      direccion: nuevo.direccion,
      favoritos: nuevo.favoritos,
    );
    _usuarios[correo!] = registro.conUsuario(guardado);
    return guardado;
  }
}