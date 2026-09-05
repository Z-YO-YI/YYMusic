/// A complete third-party legal text and every component attributed to it.
final class SoftwareLicense {
  SoftwareLicense({required Iterable<String> packages, required this.text})
    : packages = List.unmodifiable(packages) {
    if (this.packages.isEmpty ||
        this.packages.any((name) => name.trim().isEmpty) ||
        text.trim().isEmpty) {
      throw ArgumentError(
        'A software license requires names and complete text',
      );
    }
  }

  final List<String> packages;
  final String text;

  /// Case-insensitive component lookup; never searches private user data.
  bool matches(String query) => packages.any(
    (name) => name.toLowerCase().contains(query.trim().toLowerCase()),
  );
}
