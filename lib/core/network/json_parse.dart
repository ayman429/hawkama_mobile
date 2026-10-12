Map<String, dynamic> asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

String asString(Object? value, [String fallback = '']) =>
    value?.toString() ?? fallback;

int asInt(Object? value) => value is int ? value : int.tryParse('$value') ?? 0;

int? asIntOrNull(Object? value) => value == null ? null : asInt(value);

List<T> asList<T>(Object? data, T Function(Map<String, dynamic>) parse) {
  if (data is! List) return [];
  return data
      .whereType<Map>()
      .map((e) => parse(Map<String, dynamic>.from(e)))
      .toList();
}
