import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A small JSON store for content that should keep working offline: Qur'an
/// text, prayer times, athkar.
///
/// On iOS and Android entries are files under Application Support (backed up
/// by neither iCloud nor the user's Files app, and not purged like caches).
/// On the web, where there is no file system, entries go to
/// SharedPreferences.
class OfflineCache {
  OfflineCache._();
  static final OfflineCache instance = OfflineCache._();

  Directory? _dir;

  Future<Directory> _directory() async {
    final existing = _dir;
    if (existing != null) return existing;
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/offline_cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    return _dir = dir;
  }

  static String _safe(String key) =>
      key.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');

  /// Returns the stored value, or null if absent or unreadable. Never throws.
  Future<Object?> read(String key) async {
    try {
      final String? raw;
      if (kIsWeb) {
        raw = (await SharedPreferences.getInstance()).getString('cache.$key');
      } else {
        final file = File('${(await _directory()).path}/${_safe(key)}.json');
        raw = await file.exists() ? await file.readAsString() : null;
      }
      return raw == null ? null : jsonDecode(raw);
    } catch (e) {
      debugPrint('OfflineCache.read($key) failed: $e');
      return null;
    }
  }

  /// Stores [value] (anything jsonEncode accepts). Failures are logged and
  /// swallowed: a cache that cannot be written must not break the screen.
  Future<void> write(String key, Object value) async {
    try {
      final raw = jsonEncode(value);
      if (kIsWeb) {
        await (await SharedPreferences.getInstance())
            .setString('cache.$key', raw);
      } else {
        final file = File('${(await _directory()).path}/${_safe(key)}.json');
        // Write then rename, so a crash mid-write never leaves half a file.
        final tmp = File('${file.path}.tmp');
        await tmp.writeAsString(raw, flush: true);
        await tmp.rename(file.path);
      }
    } catch (e) {
      debugPrint('OfflineCache.write($key) failed: $e');
    }
  }
}

/// Network-first with offline fallback: try [fetch]; on success store and
/// return it; on failure return the last stored copy, or rethrow if none.
Future<T> withOfflineFallback<T>({
  required String key,
  required Future<T> Function() fetch,
  required Object Function(T value) encode,
  required T Function(Object json) decode,
  OfflineCache? cache,
}) async {
  final store = cache ?? OfflineCache.instance;
  try {
    final value = await fetch();
    await store.write(key, encode(value));
    return value;
  } catch (e) {
    final cached = await store.read(key);
    if (cached != null) {
      try {
        return decode(cached);
      } catch (_) {
        // Fall through to the original error.
      }
    }
    rethrow;
  }
}
