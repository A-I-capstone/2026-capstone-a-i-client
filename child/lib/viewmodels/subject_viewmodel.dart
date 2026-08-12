import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/subject.dart';
import '../services/subject/base_subject_repository.dart';

/// ViewModel managing state and business logic for Subject management.
class SubjectViewModel extends ChangeNotifier {
  final BaseSubjectRepository _repository;
  final String _userId;

  List<Subject> _subjects = [];
  bool _isLoading = false;
  StreamSubscription<List<Subject>>? _subscription;

  /// Preset palette colors (Color.value int representation) according to UI design guide:
  /// Sunrise Yellow (#FFE772), Marigold (#FFC533), Tangerine (#FF9849),
  /// Ocean (#0440FE), Ocean Soft (#2672F1), Mint (#8BE5B5),
  /// Teal (#5AC1BC), Peach (#FADFA5), Periwinkle (#7B8BBD)
  static const List<int> paletteColors = [
    0xFFFFE772,
    0xFFFFC533,
    0xFFFF9849,
    0xFF0440FE,
    0xFF2672F1,
    0xFF8BE5B5,
    0xFF5AC1BC,
    0xFFFADFA5,
    0xFF7B8BBD,
  ];

  static const List<String> defaultSubjectNames = [
    '국어',
    '수학',
    '영어',
    '사회',
    '과학',
    '기타',
  ];

  SubjectViewModel({
    required BaseSubjectRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId {
    _initStream();
  }

  List<Subject> get subjects => List.unmodifiable(_subjects);
  bool get isLoading => _isLoading;

  /// Returns Subject by ID, or null if not found.
  Subject? getSubjectById(String id) {
    try {
      return _subjects.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Returns color integer for a subject ID, or default fallback.
  int getColorForSubject(String subjectId) {
    final subject = getSubjectById(subjectId);
    if (subject != null) {
      return subject.colorValue;
    }
    return 0xFFFADFA5; // default Peach
  }

  void _initStream() {
    if (_userId.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _repository.streamSubjects(_userId).listen(
      (loaded) async {
        if (loaded.isEmpty) {
          // Initialize default subjects if database is empty for this user
          await _seedDefaultSubjects();
        } else {
          _subjects = loaded;
          _isLoading = false;
          notifyListeners();
        }
      },
      onError: (error) {
        debugPrint('[SubjectViewModel] stream error: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Seeds default subjects with random palette colors.
  Future<void> _seedDefaultSubjects() async {
    for (int i = 0; i < defaultSubjectNames.length; i++) {
      final color = paletteColors[i % paletteColors.length];
      final subject = Subject(
        id: '',
        name: defaultSubjectNames[i],
        colorValue: color,
        createdAt: DateTime.now().add(Duration(milliseconds: i * 10)),
      );
      await _repository.createSubject(_userId, subject);
    }
  }

  /// Picks a random color from [paletteColors].
  int getRandomPaletteColor() {
    final random = Random();
    return paletteColors[random.nextInt(paletteColors.length)];
  }

  /// Adds a new subject with a given name and optional color (or random color if omitted).
  Future<void> addSubject(String name, {int? colorValue}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    try {
      final color = colorValue ?? getRandomPaletteColor();
      final subject = Subject(
        id: '',
        name: trimmed,
        colorValue: color,
      );
      await _repository.createSubject(_userId, subject);
    } catch (e) {
      debugPrint('[SubjectViewModel] addSubject error: $e');
    }
  }

  /// Updates existing subject name and/or color.
  Future<void> updateSubject(String id, String newName, int newColorValue) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    try {
      final existing = getSubjectById(id);
      if (existing == null) return;

      final updated = existing.copyWith(
        name: trimmed,
        colorValue: newColorValue,
      );
      await _repository.updateSubject(_userId, updated);
    } catch (e) {
      debugPrint('[SubjectViewModel] updateSubject error: $e');
    }
  }

  /// Deletes a subject by ID.
  Future<void> deleteSubject(String id) async {
    try {
      await _repository.deleteSubject(_userId, id);
    } catch (e) {
      debugPrint('[SubjectViewModel] deleteSubject error: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
