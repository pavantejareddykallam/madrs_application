class MemoryStorage {
  /// Holds MADRS responses between screens (index -> score)
  static Map<int, double>? madrsResponses;

  /// True if we have any MADRS responses in memory
  static bool get hasMadrs =>
      madrsResponses != null && madrsResponses!.isNotEmpty;

  /// Clear stored MADRS responses (optional after final submit)
  static void clearMadrs() {
    madrsResponses = null;
  }
}
