import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/note.dart';
import '../services/app_state.dart';

class CreateEditNoteScreen extends StatefulWidget {
  final Note? note;

  const CreateEditNoteScreen({super.key, this.note});

  @override
  State<CreateEditNoteScreen> createState() => _CreateEditNoteScreenState();
}

class _CreateEditNoteScreenState extends State<CreateEditNoteScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();
  final AppState _appState = AppState();

  bool _isTitleFocused = false;
  bool _isContentFocused = false;
  bool _hasChanges = false;

  late AnimationController _enterAnimationController;
  late AnimationController _saveButtonController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _saveButtonScale;

  bool get isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();

    if (isEditing) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
    }

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);

    _titleFocusNode.addListener(
        () => setState(() => _isTitleFocused = _titleFocusNode.hasFocus));
    _contentFocusNode.addListener(
        () => setState(() => _isContentFocused = _contentFocusNode.hasFocus));

    _enterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _enterAnimationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _saveButtonController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _saveButtonScale = CurvedAnimation(
      parent: _saveButtonController,
      curve: Curves.elasticOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enterAnimationController.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        _saveButtonController.forward();
        _titleFocusNode.requestFocus();
      });
    });
  }

  void _onTextChanged() {
    final changed = isEditing
        ? (_titleController.text.trim() != widget.note!.title ||
            _contentController.text.trim() != widget.note!.content)
        : (_titleController.text.isNotEmpty ||
            _contentController.text.isNotEmpty);
    if (changed != _hasChanges) setState(() => _hasChanges = changed);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _enterAnimationController.dispose();
    _saveButtonController.dispose();
    super.dispose();
  }

  void _saveNote() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      final now = DateTime.now();

      if (isEditing) {
        final updatedNote = widget.note!.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          updatedAt: now,
        );
        _appState.updateNote(updatedNote);
      } else {
        final newNote = Note(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          updatedAt: now,
          isFavorite: false,
        );
        _appState.addNote(newNote);
      }

      Navigator.pop(context, true);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    HapticFeedback.lightImpact();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final dialogBg = isDark ? const Color(0xFF1C1C24) : Colors.white;
        final textPrimary =
            isDark ? const Color(0xFFEDEDFF) : const Color(0xFF1A1A2E);
        final textSecondary =
            isDark ? const Color(0xFF8888AA) : const Color(0xFF888899);
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: dialogBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 26),
                ),
                const SizedBox(height: 16),
                Text(
                  'Discard changes?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your unsaved changes will be lost.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A2A36)
                                : const Color(0xFFF0EFF6),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Keep editing',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Discard',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF5F4F8);
    final cardBg = isDark ? const Color(0xFF1C1C24) : Colors.white;
    final surfaceColor =
        isDark ? const Color(0xFF16161F) : const Color(0xFFEEEDF4);
    final accentColor = const Color(0xFF7C6FE0);
    final textPrimary =
        isDark ? const Color(0xFFEDEDFF) : const Color(0xFF1A1A2E);
    final textSecondary =
        isDark ? const Color(0xFF8888AA) : const Color(0xFF888899);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              // ─── Top Bar ─────────────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () async {
                          if (await _onWillPop()) {
                            if (mounted) Navigator.pop(context);
                          }
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(isDark ? 0.3 : 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded,
                              size: 18, color: textPrimary),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Screen title + subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEditing ? 'Edit Note' : 'New Note',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                                letterSpacing: -0.4,
                              ),
                            ),
                            Text(
                              isEditing
                                  ? 'Make your changes'
                                  : 'Capture your thoughts',
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Save button
                      ScaleTransition(
                        scale: _saveButtonScale,
                        child: GestureDetector(
                          onTap: _saveNote,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: _hasChanges
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF7C6FE0),
                                        Color(0xFF5A4FCC),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: _hasChanges ? null : surfaceColor,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: _hasChanges
                                  ? [
                                      BoxShadow(
                                        color: accentColor.withOpacity(0.4),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Text(
                              isEditing ? 'Update' : 'Save',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _hasChanges
                                    ? Colors.white
                                    : textSecondary,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ─── Form ─────────────────────────────────────────────────
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        children: [
                          // ── Title ──────────────────────────────────────
                          _buildFieldLabel('TITLE', textSecondary),
                          const SizedBox(height: 8),
                          _buildTitleField(
                            isDark: isDark,
                            cardBg: cardBg,
                            accentColor: accentColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),

                          const SizedBox(height: 20),

                          // ── Content ─────────────────────────────────────
                          _buildFieldLabel('CONTENT', textSecondary),
                          const SizedBox(height: 8),
                          _buildContentField(
                            isDark: isDark,
                            cardBg: cardBg,
                            accentColor: accentColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                          ),

                          const SizedBox(height: 28),

                          // ── Bottom Save Button ──────────────────────────
                          _buildBottomSaveButton(
                              accentColor, surfaceColor, textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTitleField({
    required bool isDark,
    required Color cardBg,
    required Color accentColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isTitleFocused
              ? accentColor.withOpacity(0.5)
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: _isTitleFocused
            ? [
                BoxShadow(
                  color: accentColor.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: TextFormField(
        controller: _titleController,
        focusNode: _titleFocusNode,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        decoration: InputDecoration(
          hintText: 'Note title…',
          hintStyle: TextStyle(
            color: textSecondary.withOpacity(0.4),
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 10),
            child: Icon(
              Icons.title_rounded,
              size: 20,
              color: _isTitleFocused ? accentColor : textSecondary,
            ),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter a title';
          }
          return null;
        },
        maxLines: 1,
        textCapitalization: TextCapitalization.sentences,
        onFieldSubmitted: (_) => _contentFocusNode.requestFocus(),
      ),
    );
  }

  Widget _buildContentField({
    required bool isDark,
    required Color cardBg,
    required Color accentColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isContentFocused
              ? accentColor.withOpacity(0.5)
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: _isContentFocused
            ? [
                BoxShadow(
                  color: accentColor.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Stack(
        children: [
          TextFormField(
            controller: _contentController,
            focusNode: _contentFocusNode,
            style: TextStyle(
              fontSize: 15,
              color: textPrimary,
              height: 1.75,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              hintText: 'Start writing your note…',
              hintStyle: TextStyle(
                color: textSecondary.withOpacity(0.4),
                fontWeight: FontWeight.w400,
                fontSize: 15,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(18, 18, 18, 52),
              alignLabelWithHint: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter some content';
              }
              return null;
            },
            maxLines: 14,
            minLines: 10,
            textCapitalization: TextCapitalization.sentences,
          ),

          // Live word count badge
          Positioned(
            bottom: 12,
            right: 14,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _contentController,
              builder: (context, value, _) {
                final wordCount = value.text.trim().isEmpty
                    ? 0
                    : value.text.trim().split(RegExp(r'\s+')).length;
                return AnimatedOpacity(
                  opacity: _isContentFocused ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isContentFocused
                          ? accentColor.withOpacity(0.12)
                          : textSecondary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$wordCount ${wordCount == 1 ? 'word' : 'words'}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _isContentFocused ? accentColor : textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSaveButton(
      Color accentColor, Color surfaceColor, Color textSecondary) {
    return GestureDetector(
      onTap: _saveNote,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          gradient: _hasChanges
              ? const LinearGradient(
                  colors: [Color(0xFF7C6FE0), Color(0xFF5A4FCC)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: _hasChanges ? null : surfaceColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _hasChanges
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isEditing ? Icons.check_rounded : Icons.add_rounded,
              color: _hasChanges ? Colors.white : textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isEditing ? 'Update Note' : 'Create Note',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _hasChanges ? Colors.white : textSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}