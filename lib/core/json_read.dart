/// Tolerant readers for API JSON.
///
/// The server is Laravel on MySQL: decimals arrive as strings ("14.0"),
/// booleans as 0/1 or "1", ids sometimes as strings. A strict `as int?` cast
/// on any of those throws, and one bad field took down whole screens
/// (pathways showed "type 'String' is not a subtype of type 'int?'").
/// These never throw: an unreadable value is null.
library;

int? jInt(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim()) ?? double.tryParse(v.trim())?.toInt();
  if (v is bool) return v ? 1 : 0;
  return null;
}

double? jDouble(Object? v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim());
  return null;
}

num? jNum(Object? v) {
  if (v is num) return v;
  if (v is String) return num.tryParse(v.trim());
  return null;
}

bool? jBool(Object? v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    switch (v.trim().toLowerCase()) {
      case '1':
      case 'true':
      case 'yes':
        return true;
      case '0':
      case 'false':
      case 'no':
      case '':
        return false;
    }
  }
  return null;
}

String? jStr(Object? v) {
  if (v == null) return null;
  if (v is String) return v;
  if (v is num || v is bool) return v.toString();
  return null;
}
