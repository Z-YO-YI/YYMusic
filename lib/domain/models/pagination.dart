final class PageRequest {
  factory PageRequest({int offset = 0, int limit = 50}) {
    if (offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'must not be negative');
    }
    if (limit <= 0 || limit > 200) {
      throw ArgumentError.value(limit, 'limit', 'must be between 1 and 200');
    }
    return PageRequest._(offset: offset, limit: limit);
  }

  const PageRequest._({required this.offset, required this.limit});

  final int offset;
  final int limit;
}

final class PageResult<T> {
  PageResult({required Iterable<T> items, required this.hasMore})
    : items = List<T>.unmodifiable(items);

  final List<T> items;
  final bool hasMore;
}
