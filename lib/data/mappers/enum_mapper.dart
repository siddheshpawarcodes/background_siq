/// Safe conversion between persisted `int` indices and enum values.
///
/// Guards against out-of-range indices (e.g. after a future enum reorder)
/// by clamping to the valid range and falling back to the first value.
extension EnumByIndex<T extends Enum> on List<T> {
  T fromIndex(int index, {T? fallback}) {
    if (index < 0 || index >= length) return fallback ?? first;
    return this[index];
  }
}
