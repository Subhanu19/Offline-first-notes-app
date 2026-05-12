import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note.dart';

// --- StateNotifier implementation ---
class NoteNotifier extends StateNotifier<List<Note>> {
  NoteNotifier() : super([]) {
    _loadDummyNotes();
  }

  void _loadDummyNotes() {
    if (state.isNotEmpty) return;
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
    state = dummyNotes;
  }

  void addNote(Note note) {
    state = [...state, note];
  }

  void updateNote(Note updatedNote) {
    state = state.map((note) => note.id == updatedNote.id ? updatedNote : note).toList();
  }

  void deleteNote(String id) {
    state = state.where((note) => note.id != id).toList();
  }

  void toggleFavorite(String id) {
    final index = state.indexWhere((note) => note.id == id);
    if (index != -1) {
      final updated = state[index].copyWith(
        isFavorite: !state[index].isFavorite,
        updatedAt: DateTime.now(),
      );
      updateNote(updated);
    }
  }
}

// --- Provider definition ---
final noteProvider = StateNotifierProvider<NoteNotifier, List<Note>>((ref) {
  return NoteNotifier();
});