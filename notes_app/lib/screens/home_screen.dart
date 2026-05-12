import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/note.dart';
import '../services/app_state.dart';
import '../widgets/note_card.dart';
import '../widgets/empty_state.dart';
import 'create_edit_note_screen.dart';
import 'note_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final AppState _appState = AppState();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  bool _showPinnedOnly = false;
  bool _isSearchFocused = false;
  bool _isScrolled = false;

  late AnimationController _fabAnimationController;
  late AnimationController _headerAnimationController;
  late AnimationController _searchAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _searchWidthAnimation;

  // Pastel card colors cycling
  static const List<Color> _cardColors = [
    Color(0xFFFFE8E8), // soft rose
    Color(0xFFFFF3E0), // soft amber
    Color(0xFFE8F5E9), // soft mint
    Color(0xFFE8EAF6), // soft lavender
    Color(0xFFFCE4EC), // soft pink
    Color(0xFFE0F7FA), // soft cyan
  ];

  @override
  void initState() {
    super.initState();

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fabScaleAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    );

    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    ));
    _headerFadeAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOut,
    );

    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _searchWidthAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeOutCubic,
    );

    _scrollController.addListener(() {
      final scrolled = _scrollController.offset > 10;
      if (scrolled != _isScrolled) {
        setState(() => _isScrolled = scrolled);
      }
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _headerAnimationController.forward();
      _fabAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    _headerAnimationController.dispose();
    _searchAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<Note> get _filteredNotes {
    var notes = _appState.notes;

    if (_showPinnedOnly) {
      notes = notes.where((note) => note.isFavorite).toList();
    }

    if (_searchQuery.isNotEmpty) {
      notes = notes.where((note) {
        return note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            note.content.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  void _onSearchFocusChanged(bool focused) {
    setState(() => _isSearchFocused = focused);
    if (focused) {
      _searchAnimationController.forward();
    } else {
      _searchAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Light pastel theme matching the screenshot
    const bgColor = Color(0xFFF3F2F8);
    const cardBg = Colors.white;
    const accentColor = Color(0xFF6C63FF);
    const accentLight = Color(0xFFB8AFFF);
    const textPrimary = Color(0xFF1A1A2E);
    const textSecondary = Color(0xFF888899);
    const surfaceColor = Color(0xFFEEEDF4);
    const bool isDark = false;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ───────────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: _isScrolled ? Colors.white : bgColor,
                boxShadow: _isScrolled
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Row
                    SlideTransition(
                      position: _headerSlideAnimation,
                      child: FadeTransition(
                        opacity: _headerFadeAnimation,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'My Notes',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                    letterSpacing: -0.8,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                ValueListenableBuilder<List<Note>>(
                                  valueListenable: _appState.notesNotifier,
                                  builder: (context, notes, _) {
                                    return Text(
                                      '${notes.length} note${notes.length == 1 ? '' : 's'}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            _buildMenuButton(context),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Search bar
                    SlideTransition(
                      position: _headerSlideAnimation,
                      child: FadeTransition(
                        opacity: _headerFadeAnimation,
                        child: Focus(
                          onFocusChange: _onSearchFocusChanged,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: _isSearchFocused
                                  ? Colors.white
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _isSearchFocused
                                    ? accentColor.withOpacity(0.45)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _isSearchFocused
                                      ? accentColor.withOpacity(0.12)
                                      : Colors.black.withOpacity(0.04),
                                  blurRadius: _isSearchFocused ? 18 : 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) =>
                                  setState(() => _searchQuery = value),
                              style: const TextStyle(
                                color: textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search notes...',
                                hintStyle: const TextStyle(
                                  color: textSecondary,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: _isSearchFocused
                                      ? accentColor
                                      : textSecondary,
                                  size: 20,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _searchController.clear();
                                            _searchQuery = '';
                                          });
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: textSecondary
                                                .withOpacity(0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            size: 14,
                                            color: textSecondary,
                                          ),
                                        ),
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Filter chips with counts
                    SlideTransition(
                      position: _headerSlideAnimation,
                      child: FadeTransition(
                        opacity: _headerFadeAnimation,
                        child: ValueListenableBuilder<List<Note>>(
                          valueListenable: _appState.notesNotifier,
                          builder: (context, notes, _) {
                            final pinnedCount =
                                notes.where((n) => n.isFavorite).length;
                            return Row(
                              children: [
                                _buildPillChip(
                                  label: 'All Notes',
                                  count: notes.length,
                                  isSelected: !_showPinnedOnly,
                                  accentColor: accentColor,
                                  onTap: () =>
                                      setState(() => _showPinnedOnly = false),
                                ),
                                const SizedBox(width: 10),
                                _buildPillChip(
                                  label: 'Favorites',
                                  count: pinnedCount,
                                  isSelected: _showPinnedOnly,
                                  accentColor: accentColor,
                                  onTap: () =>
                                      setState(() => _showPinnedOnly = true),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ─── Note List ────────────────────────────────────────────
            Expanded(
              child: ValueListenableBuilder<List<Note>>(
                valueListenable: _appState.notesNotifier,
                builder: (context, notes, child) {
                  final filteredNotes = _filteredNotes;

                  if (filteredNotes.isEmpty) {
                    return _buildEmptyState(
                        textPrimary, textSecondary, accentColor);
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
                      final cardColor = _cardColors[index % _cardColors.length];
                      return _AnimatedNoteItem(
                        key: Key('item_$index'),
                        index: index,
                        child: _buildPastelNoteCard(
                          note: note,
                          cardColor: cardColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          accentColor: accentColor,
                          onDelete: () {
                            HapticFeedback.mediumImpact();
                            _appState.deleteNote(note.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.check_circle_outline,
                                        color: Colors.white, size: 18),
                                    SizedBox(width: 10),
                                    Text('Note deleted'),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF2D2D3A),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                margin: const EdgeInsets.all(16),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ─── FAB ──────────────────────────────────────────────────────
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF7C6FE0), Color(0xFF5A4FCC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              splashColor: Colors.white24,
              onTap: () async {
                HapticFeedback.mediumImpact();
                final result = await Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, animation, __) =>
                        const CreateEditNoteScreen(),
                    transitionsBuilder: (_, animation, __, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      );
                    },
                  ),
                );
                if (!mounted) return;
                if (result == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: Colors.white, size: 18),
                          SizedBox(width: 10),
                          Text('Note created successfully'),
                        ],
                      ),
                      backgroundColor: const Color(0xFF2D2D3A),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              },
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Menu (···) button ───────────────────────────────────────────
  Widget _buildMenuButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => const SettingsScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.more_horiz_rounded,
          color: Color(0xFF1A1A2E),
          size: 20,
        ),
      ),
    );
  }

  // ─── Pill chip with count badge ──────────────────────────────────
  Widget _buildPillChip({
    required String label,
    required int count,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF888899),
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.25)
                    : const Color(0xFFEEEDF4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF888899),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Pastel note card ────────────────────────────────────────────
  Widget _buildPastelNoteCard({
    required Note note,
    required Color cardColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
    required VoidCallback onDelete,
  }) {
    return _HoverNoteCard(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => NoteDetailScreen(note: note),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: cardColor.withOpacity(0.6),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      note.title.isEmpty ? 'Untitled' : note.title,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Star / pin button
                  _buildStarButton(note, accentColor),
                ],
              ),

              if (note.content.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  note.content,
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.55,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 14),

              // Bottom row: time + trash
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: Color(0xFFAAAAAA),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(note.updatedAt),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFFAAAAAA),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  // Trash button
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        size: 17,
                        color: Color(0xFFBBBBBB),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Star / pin button ───────────────────────────────────────────
  Widget _buildStarButton(Note note, Color accentColor) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _appState.toggleFavorite(note.id);
      },
      child: TweenAnimationBuilder<double>(
        key: ValueKey(note.isFavorite),
        tween: Tween(begin: 0.7, end: 1.0),
        duration: const Duration(milliseconds: 350),
        curve: Curves.elasticOut,
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Icon(
              note.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 22,
              color: note.isFavorite
                  ? const Color(0xFFFFB400)
                  : const Color(0xFFCCCCCC),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
      Color textPrimary, Color textSecondary, Color accentColor) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _showPinnedOnly
                    ? Icons.star_outline_rounded
                    : Icons.note_add_outlined,
                size: 36,
                color: accentColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _showPinnedOnly ? 'No favorites yet' : 'No notes found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : _showPinnedOnly
                      ? 'Star a note to see it here'
                      : 'Tap + to create your first note',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.day}/${date.month}/${date.year}';
  }
}

// ─── Hover-effect wrapper (scales on press/hover) ────────────────────────────
class _HoverNoteCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _HoverNoteCard({required this.child, required this.onTap});

  @override
  State<_HoverNoteCard> createState() => _HoverNoteCardState();
}

class _HoverNoteCardState extends State<_HoverNoteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.965).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ─── Animated Note Item (staggered entrance) ─────────────────────────────────
class _AnimatedNoteItem extends StatefulWidget {
  final Widget child;
  final int index;

  const _AnimatedNoteItem({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  State<_AnimatedNoteItem> createState() => _AnimatedNoteItemState();
}

class _AnimatedNoteItemState extends State<_AnimatedNoteItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Stagger by index
    Future.delayed(Duration(milliseconds: 50 * widget.index.clamp(0, 8)), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}