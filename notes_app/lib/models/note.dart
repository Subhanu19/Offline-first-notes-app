import 'package:flutter/foundation.dart';

@immutable
class Note {
  final String id;
  final String title;
  final String content;
  final DateTime updatedAt;
  final bool isFavorite;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
    this.isFavorite = false,
  });

  // Create a copy with updated fields
  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? updatedAt,
    bool? isFavorite,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Note &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.updatedAt == updatedAt &&
        other.isFavorite == isFavorite;
  }

  @override
  int get hashCode => Object.hash(id, title, content, updatedAt, isFavorite);
}