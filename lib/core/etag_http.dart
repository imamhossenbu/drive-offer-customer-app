import 'package:http/http.dart' as http;

/// Bandwidth saver for polling.
///
/// Remembers the last ETag + body for every GET (per URL and auth token) and
/// sends `If-None-Match`. When the backend answers `304 Not Modified` (nothing
/// changed), no body is transferred and the cached body is replayed as a 200,
/// so callers behave exactly as before.
class _CachedEntry {
  final String etag;
  final String body;
  final Map<String, String> headers;
  _CachedEntry(this.etag, this.body, this.headers);
}

final Map<String, _CachedEntry> _etagCache = <String, _CachedEntry>{};
const int _maxEntries = 64;

Future<http.Response> etagGet(Uri url, {Map<String, String>? headers}) async {
  final key = '${headers?['Authorization'] ?? ''}|$url';
  final cached = _etagCache[key];
  final reqHeaders = <String, String>{...?headers};
  if (cached != null) reqHeaders['If-None-Match'] = cached.etag;

  final res = await http.get(url, headers: reqHeaders);

  if (res.statusCode == 304 && cached != null) {
    return http.Response(cached.body, 200, headers: cached.headers, request: res.request);
  }

  final etag = res.headers['etag'];
  if (res.statusCode == 200 && etag != null && etag.isNotEmpty) {
    if (_etagCache.length >= _maxEntries && !_etagCache.containsKey(key)) {
      _etagCache.remove(_etagCache.keys.first);
    }
    _etagCache[key] = _CachedEntry(etag, res.body, res.headers);
  } else if (res.statusCode >= 400) {
    _etagCache.remove(key);
  }
  return res;
}
