/// Represents a mission item assigned to the user based on conversation context.
class Mission {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;

  const Mission({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
  });

  Mission copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
  }) {
    return Mission(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
