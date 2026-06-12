import 'dart:convert';
import 'dart:typed_data';

/// Petit helper : écrit/lit une chaîne préfixée par sa longueur (1 octet).
class _W {
  final BytesBuilder _b = BytesBuilder();
  void str(String s) {
    final bytes = utf8.encode(s);
    if (bytes.length >= 256) {
      throw ArgumentError('Chaîne trop longue pour préfixe 1 octet : ${bytes.length} octets');
    }
    _b.addByte(bytes.length);
    _b.add(bytes);
  }
  void byte(int v) => _b.addByte(v);
  void f64(double v) {
    final d = ByteData(8)..setFloat64(0, v, Endian.big);
    _b.add(d.buffer.asUint8List());
  }
  void i64(int v) {
    final d = ByteData(8)..setInt64(0, v, Endian.big);
    _b.add(d.buffer.asUint8List());
  }
  Uint8List bytes() => _b.toBytes();
}

class _R {
  final Uint8List _d;
  int _o = 0;
  _R(this._d);
  String str() {
    final len = _d[_o++];
    final s = utf8.decode(_d.sublist(_o, _o + len));
    _o += len;
    return s;
  }
  int byte() => _d[_o++];
  double f64() {
    final v = ByteData.sublistView(_d, _o, _o + 8).getFloat64(0, Endian.big);
    _o += 8;
    return v;
  }
  int i64() {
    final v = ByteData.sublistView(_d, _o, _o + 8).getInt64(0, Endian.big);
    _o += 8;
    return v;
  }
}

/// Demande de localisation. [targetId] == '*' signifie « tout le groupe ».
class LocationRequest {
  final String requestId;
  final String targetId;
  final bool live;
  LocationRequest({
    required this.requestId,
    required this.targetId,
    required this.live,
  });

  Uint8List encode() {
    final w = _W()
      ..str(requestId)
      ..str(targetId)
      ..byte(live ? 1 : 0);
    return w.bytes();
  }

  static LocationRequest decode(Uint8List data) {
    final r = _R(data);
    return LocationRequest(
      requestId: r.str(),
      targetId: r.str(),
      live: r.byte() == 1,
    );
  }
}

/// Réponse : position GPS horodatée avec précision (mètres).
class LocationResponse {
  final String requestId;
  final String responderId;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final int timestampMs;
  LocationResponse({
    required this.requestId,
    required this.responderId,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.timestampMs,
  });

  Uint8List encode() {
    final w = _W()
      ..str(requestId)
      ..str(responderId)
      ..f64(latitude)
      ..f64(longitude)
      ..f64(accuracyMeters)
      ..i64(timestampMs);
    return w.bytes();
  }

  static LocationResponse decode(Uint8List data) {
    final r = _R(data);
    return LocationResponse(
      requestId: r.str(),
      responderId: r.str(),
      latitude: r.f64(),
      longitude: r.f64(),
      accuracyMeters: r.f64(),
      timestampMs: r.i64(),
    );
  }
}
