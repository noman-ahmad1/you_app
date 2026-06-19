/// A tiny in-memory cache with per-entry time-to-live.
///
/// Intended for short-lived caching of frequently re-read Firestore documents
/// within a service (services are registered as `LazySingleton`, so a cache
/// instance lives for the app session). Always clear caches on sign-out.
class TtlCache<K, V> {
  TtlCache({required this.ttl});

  final Duration ttl;
  final Map<K, _Entry<V>> _store = {};

  /// Returns the cached value if present and not expired, otherwise null.
  V? get(K key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.storedAt) > ttl) {
      _store.remove(key);
      return null;
    }
    return entry.value;
  }

  void put(K key, V value) {
    _store[key] = _Entry(value, DateTime.now());
  }

  void invalidate(K key) => _store.remove(key);

  void clear() => _store.clear();
}

class _Entry<V> {
  _Entry(this.value, this.storedAt);
  final V value;
  final DateTime storedAt;
}
