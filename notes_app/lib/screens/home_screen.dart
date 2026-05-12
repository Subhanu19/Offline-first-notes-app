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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF5F4F8);
    final cardBg = isDark ? const Color(0xFF1C1C24) : Colors.white;
    final accentColor = const Color(0xFF7C6FE0);
    final accentLight = const Color(0xFFB8AFFF);
    final textPrimary = isDark ? const Color(0xFFEDEDFF) : const Color(0xFF1A1A2E);
    final textSecondary = isDark ? const Color(0xFF8888AA) : const Color(0xFF888899);
    final surfaceColor = isDark ? const Color(0xFF16161F) : const Color(0xFFEEEDF4);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ───────────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: _isScrolled
                    ? (isDark ? const Color(0xFF13131A) : Colors.white)
                    : bgColor,
                boxShadow: _isScrolled
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                                Text(
                                  'My Notes',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                    letterSpacing: -0.5,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                ValueListenableBuilder<List<Note>>(
                                  valueListenable: _appState.notesNotifier,
                                  builder: (context, notes, _) {
                                    return Text(
                                      '${notes.length} note${notes.length == 1 ? '' : 's'}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            _buildSettingsButton(
                                context, isDark, cardBg, textPrimary),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

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
                                  ? cardBg
                                  : surfaceColor,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: _isSearchFocused
                                    ? accentColor.withOpacity(0.5)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                              boxShadow: _isSearchFocused
                                  ? [
                                      BoxShadow(
                                        color: accentColor.withOpacity(0.15),
                                        blurRadius: 20,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : [],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) =>
                                  setState(() => _searchQuery = value),
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search notes…',
                                hintStyle: TextStyle(
                                  color: textSecondary,
                                  fontWeight: FontWeight.w400,
                                ),
                                prefixIcon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    _isSearchFocused
                                        ? Icons.search
                                        : Icons.search_rounded,
                                    key: ValueKey(_isSearchFocused),
                                    color: _isSearchFocused
                                        ? accentColor
                                        : textSecondary,
                                    size: 20,
                                  ),
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
                                            color:
                                                textSecondary.withOpacity(0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
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
                                  vertical: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Filter chips
                    SlideTransition(
                      position: _headerSlideAnimation,
                      child: FadeTransition(
                        opacity: _headerFadeAnimation,
                        child: Row(
                          children: [
                            _buildModernChip(
                              label: 'All',
                              icon: Icons.grid_view_rounded,
                              isSelected: !_showPinnedOnly,
                              accentColor: accentColor,
                              accentLight: accentLight,
                              surfaceColor: surfaceColor,
                              textSecondary: textSecondary,
                              isDark: isDark,
                              onTap: () =>
                                  setState(() => _showPinnedOnly = false),
                            ),
                            const SizedBox(width: 10),
                            _buildModernChip(
                              label: 'Pinned',
                              icon: Icons.push_pin_rounded,
                              isSelected: _showPinnedOnly,
                              accentColor: accentColor,
                              accentLight: accentLight,
                              surfaceColor: surfaceColor,
                              textSecondary: textSecondary,
                              isDark: isDark,
                              onTap: () =>
                                  setState(() => _showPinnedOnly = true),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),
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
                        isDark, textPrimary, textSecondary, accentColor);
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
                      return _AnimatedNoteItem(
                        key: Key('item_$index'),
                        index: index,
                        child: Dismissible(
                          key: Key(note.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red.withOpacity(0.0),
                                  Colors.red.shade400,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.delete_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onDismissed: (direction) {
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
                          child: _buildNoteCard(
                            note: note,
                            isDark: isDark,
                            cardBg: cardBg,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            accentColor: accentColor,
                          ),
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [accentColor, const Color(0xFF5A4FCC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.45),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
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
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'New Note',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsButton(
      BuildContext context, bool isDark, Color cardBg, Color textPrimary) {
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.settings_outlined,
          color: textPrimary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildModernChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color accentColor,
    required Color accentLight,
    required Color surfaceColor,
    required Color textSecondary,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.15) : surfaceColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? accentColor.withOpacity(0.4) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? accentColor : textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? accentColor : textSecondary,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard({
    required Note note,
    required bool isDark,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
  }) {
    return GestureDetector(
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Subtle accent line on left if pinned
              if (note.isFavorite)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 3.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accentColor, accentColor.withOpacity(0.4)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

              Padding(
                padding: EdgeInsets.fromLTRB(
                    note.isFavorite ? 18 : 16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            note.title.isEmpty ? 'Untitled' : note.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildPinButton(note, accentColor, textSecondary, isDark),
                      ],
                    ),

                    if (note.content.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        note.content,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: textSecondary,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: textSecondary.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(note.updatedAt),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: textSecondary.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (note.isFavorite) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.push_pin_rounded,
                                    size: 10, color: accentColor),
                                const SizedBox(width: 3),
                                Text(
                                  'Pinned',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: accentColor,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinButton(
      Note note, Color accentColor, Color textSecondary, bool isDark) {
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
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: note.isFavorite
                    ? accentColor.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                note.isFavorite
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
                size: 18,
                color: note.isFavorite ? accentColor : textSecondary,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
      bool isDark, Color textPrimary, Color textSecondary, Color accentColor) {
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
                    ? Icons.push_pin_outlined
                    : Icons.note_add_outlined,
                size: 36,
                color: accentColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _showPinnedOnly ? 'No pinned notes' : 'No notes found',
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
                      ? 'Pin a note to see it here'
                      : 'Tap + New Note to get started',
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

// ─── Animated Note Item (staggered entrance) ────────────────────────────────
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
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

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