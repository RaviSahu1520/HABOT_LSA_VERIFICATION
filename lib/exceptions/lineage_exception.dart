class LineageException implements Exception {
  const LineageException([
    this.message = 'Required predecessor lineage is missing.',
  ]);

  final String message;

  @override
  String toString() => 'LineageException: $message';
}
