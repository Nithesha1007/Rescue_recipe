enum DietTag {
  none('None'),
  vegetarian('Vegetarian'),
  vegan('Vegan'),
  eggFree('Egg-free'),
  dairyFree('Dairy-free'),
  glutenFree('Gluten-free'),
  nonVegetarian('Non-vegetarian');

  const DietTag(this.displayName);
  final String displayName;

  static DietTag fromString(String? value) {
    if (value == null) return DietTag.none;
    final normalized = value.trim().toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '');
    for (final tag in DietTag.values) {
      if (tag.name.toLowerCase() == normalized ||
          tag.displayName.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '') == normalized) {
        return tag;
      }
    }
    return DietTag.none;
  }
}
