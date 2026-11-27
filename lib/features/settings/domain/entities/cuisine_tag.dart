/// Supported cuisine preferences for filtering and ranking dishes.
enum CuisineTag {
  any('Any', 'All Cuisines'),
  southIndian('South Indian', 'Dosa, Idli, Sambar, Rasam, Poriyal'),
  northIndian('North Indian', 'Curries, Dal, Roti, Pulao, Paneer'),
  continental('Continental', 'Pastas, Soups, Salads, Bakes'),
  chinese('Chinese-style', 'Fried Rice, Noodles, Stir-fries, Manchurian'),
  snacks('Quick snacks', 'Chaat, Fritters, Sandwiches, Upma');

  const CuisineTag(this.displayName, this.description);

  final String displayName;
  final String description;

  static CuisineTag fromString(String? value) {
    if (value == null) return CuisineTag.any;
    for (final tag in CuisineTag.values) {
      if (tag.name.toLowerCase() == value.toLowerCase() ||
          tag.displayName.toLowerCase() == value.toLowerCase()) {
        return tag;
      }
    }
    return CuisineTag.any;
  }
}
