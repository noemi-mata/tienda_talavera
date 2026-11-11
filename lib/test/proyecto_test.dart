import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el paquete crypto está instalado y calcula SHA-256', () {
    final hash = sha256.convert(utf8.encode('abc')).toString();
    expect(hash, 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
  });
}