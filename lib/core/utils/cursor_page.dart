class CursorPage<T> {
  final List<T> items;
  final bool hasNext;
  final String? nextCursor;

  const CursorPage({
    required this.items,
    required this.hasNext,
    this.nextCursor,
  });
}
