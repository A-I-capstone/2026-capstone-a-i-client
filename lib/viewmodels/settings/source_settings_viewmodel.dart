import 'package:flutter/foundation.dart';

class SourceSettingsViewModel extends ChangeNotifier {
  final List<String> _blacklistedSources = [
    'youtube.com/shorts',
    'tiktok.com',
    'instagram.com/reels',
  ];

  List<String> get blacklistedSources => List.unmodifiable(_blacklistedSources);

  void addSource(String source) {
    final cleanSource = source.trim();
    if (cleanSource.isNotEmpty && !_blacklistedSources.contains(cleanSource)) {
      _blacklistedSources.insert(0, cleanSource);
      notifyListeners();
    }
  }

  void editSource(int index, String newSource) {
    final cleanSource = newSource.trim();
    if (cleanSource.isNotEmpty) {
      _blacklistedSources[index] = cleanSource;
      notifyListeners();
    }
  }

  void deleteSource(int index) {
    if (index >= 0 && index < _blacklistedSources.length) {
      _blacklistedSources.removeAt(index);
      notifyListeners();
    }
  }
}
