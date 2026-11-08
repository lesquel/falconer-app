/// Wire-contract primitives (TRD §6.1): X25519, HKDF-SHA256 (32 bytes),
/// XChaCha20-Poly1305 with 24-byte nonces. Pure Dart so it also runs in the
/// background push isolate. The ciphertext layout matches RustCrypto's
/// `chacha20poly1305`: `ciphertext || 16-byte tag`.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

const nonceLength = 24;
const macLength = 16;
const keyLength = 32;

final _x25519 = X25519();
final _aead = Xchacha20.poly1305Aead();
final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: keyLength);

/// Fresh random X25519 key pair.
Future<SimpleKeyPair> newX25519KeyPair() => _x25519.newKeyPair();

/// Key pair from a stored 32-byte private key.
Future<SimpleKeyPair> x25519FromPrivate(List<int> private) {
  if (private.length != keyLength) throw ArgumentError('bad X25519 private key');
  return _x25519.newKeyPairFromSeed(private);
}

Future<Uint8List> x25519PublicBytes(SimpleKeyPair pair) async =>
    Uint8List.fromList((await pair.extractPublicKey()).bytes);

Future<Uint8List> x25519PrivateBytes(SimpleKeyPair pair) async =>
    Uint8List.fromList(await pair.extractPrivateKeyBytes());

/// `HKDF(ikm = X25519(priv, remotePub), salt, info)`.
Future<SecretKey> deriveKey({
  required SimpleKeyPair private,
  required List<int> remotePublic,
  required List<int> salt,
  required String info,
}) async {
  if (remotePublic.length != keyLength) throw ArgumentError('bad X25519 public key');
  final shared = await _x25519.sharedSecretKey(
    keyPair: private,
    remotePublicKey: SimplePublicKey(remotePublic, type: KeyPairType.x25519),
  );
  return _hkdf.deriveKey(secretKey: shared, nonce: salt, info: utf8.encode(info));
}

Future<Uint8List> seal({
  required SecretKey key,
  required List<int> nonce,
  required List<int> plaintext,
  required String aad,
}) async {
  if (nonce.length != nonceLength) throw ArgumentError('bad nonce');
  final box = await _aead.encrypt(plaintext, secretKey: key, nonce: nonce, aad: utf8.encode(aad));
  return Uint8List.fromList([...box.cipherText, ...box.mac.bytes]);
}

/// Throws [SecretBoxAuthenticationError] when the tag does not verify.
Future<Uint8List> open({
  required SecretKey key,
  required List<int> nonce,
  required List<int> combined,
  required String aad,
}) async {
  if (nonce.length != nonceLength || combined.length < macLength) {
    throw SecretBoxAuthenticationError();
  }
  final split = combined.length - macLength;
  final box = SecretBox(
    combined.sublist(0, split),
    nonce: nonce,
    mac: Mac(combined.sublist(split)),
  );
  return Uint8List.fromList(await _aead.decrypt(box, secretKey: key, aad: utf8.encode(aad)));
}

Uint8List randomBytes(int n) {
  final rng = Random.secure();
  return Uint8List.fromList(List<int>.generate(n, (_) => rng.nextInt(256)));
}

/// Best-effort wipe of key buffers (T-11).
void wipe(List<int> bytes) {
  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = 0;
  }
}
