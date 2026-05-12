import 'package:flutter/material.dart';
import '../models/note.dart';

/// Simple state management using ValueNotifier
/// No external packages required
class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  // ValueNotifier automatically rebuilds UI when value changes
  final ValueNotifier<List<Note>> notesNotifier = ValueNotifier([]);

  List<Note> get notes => notesNotifier.value;

  // Add a new note
  void addNote(Note note) {
    final newList = [...notes, note];
    notesNotifier.value = newList;
  }

  // Update an existing note
  void updateNote(Note updatedNote) {
    final newList = notes.map((note) {
      return note.id == updatedNote.id ? updatedNote : note;
    }).toList();
    notesNotifier.value = newList;
  }

  // Delete a note by ID
  void deleteNote(String id) {
    final newList = notes.where((note) => note.id != id).toList();
    notesNotifier.value = newList;
  }

  // Toggle favorite status
  void toggleFavorite(String id) {
    final noteIndex = notes.indexWhere((note) => note.id == id);
    if (noteIndex != -1) {
      final updatedNote = notes[noteIndex].copyWith(
        isFavorite: !notes[noteIndex].isFavorite,
        updatedAt: DateTime.now(),
      );
      updateNote(updatedNote);
    }
  }

  // Initialize with dummy data for demo
  void initializeWithDummy() {
    if (notes.isNotEmpty) return;

    final dummyNotes = [
      Note(
        id: '1',
        title: 'Meeting Notes',
        content: 'Discuss new features and roadmap for Q3. Key points: UI redesign, performance improvements, and user feedback integration.',
        updatedAt: DateTime(2026, 5, 12, 14, 30),
        isFavorite: true,
      ),
      Note(
        id: '2',
        title: 'Shopping List',
        content: 'Milk, Bread, Eggs, Butter, Coffee, Fresh fruits and vegetables for the week.',
        updatedAt: DateTime(2026, 5, 11, 9, 15),
        isFavorite: false,
      ),
      Note(
        id: '3',
        title: 'Project Ideas',
        content: 'Build a habit tracker app, create a recipe sharing platform, develop a local business directory.',
        updatedAt: DateTime(2026, 5, 10, 18, 45),
        isFavorite: true,
      ),
      Note(
        id: '4',
        title: 'Workout Plan',
        content: 'Monday: Cardio, Tuesday: Upper body, Wednesday: Lower body, Thursday: Rest, Friday: Full body.',
        updatedAt: DateTime(2026, 5, 9, 7, 0),
        isFavorite: false,
      ),
    ];
    notesNotifier.value = dummyNotes;
  }
}