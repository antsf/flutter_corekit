// ignore_for_file: public_member_api_docs

import 'dart:math';
import 'dart:typed_data';

import 'package:uuid/data.dart';
import 'package:uuid/rng.dart';
import 'package:uuid/uuid.dart';

/// The shared [UuidGenerator] instance used throughout the app.
///
/// Example:
/// ```dart
/// final id = uuid.v4(); // e.g. '3f2504e0-4f89-41d3-9a0c-0305e82c3301'
/// ```
final uuid = UuidGenerator._();

/// {@template uuid_generator}
/// Generates RFC 4122 v4 (random) UUIDs, e.g. for client-side IDs that need
/// to exist before a value round-trips through a server (optimistic
/// inserts in an offline-first app, idempotency keys, temp file names).
///
/// Wraps the `uuid` package rather than exposing it directly so the app has
/// one place to swap the underlying RNG or library later. Access the shared
/// instance via the top-level [uuid] getter instead of constructing this
/// directly.
/// {@endtemplate}
class UuidGenerator {
  UuidGenerator._();

  final _uuid = Uuid(goptions: GlobalOptions(_SecureRandomRng._()));

  /// Generates a random (v4) UUID string.
  String v4() => _uuid.v4();
}

/// A [RNG] backed by [Random.secure] so generated UUIDs aren't predictable
/// from the default (non-cryptographic) PRNG the `uuid` package otherwise
/// uses.
class _SecureRandomRng extends RNG {
  _SecureRandomRng._() : _secureRandom = Random.secure();

  final Random _secureRandom;

  @override
  Uint8List generate() {
    final bytes = Uint8List(16);
    for (var i = 0; i < 16; i += 4) {
      final chunk = _secureRandom.nextInt(1 << 32);
      bytes[i] = chunk;
      bytes[i + 1] = chunk >> 8;
      bytes[i + 2] = chunk >> 16;
      bytes[i + 3] = chunk >> 24;
    }
    return bytes;
  }
}
