import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';
import 'create_edit_note_screen.dart';

class NoteDetailScreen extends ConsumerStatefulWidget {
  final Note note;
  const NoteDetailScreen({super.key, required this.note});

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _enterController;
  late AnimationController _pinController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pinScaleAnimation;
  late bool _isPinned;

  @override
  void initState() {
    super.initState();
    _isPinned = widget.note.isFavorite;

    _enterController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _enterController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterController, curve: Curves.easeOutCubic));

    _pinController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pinScaleAnimation = CurvedAnimation(parent: _pinController, curve: Curves.elasticOut);
    _pinController.value = 1.0;

    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _editNote() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => CreateEditNoteScreen(note: widget.note),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
      ),
    );
    if (result == true && mounted) Navigator.pop(context);
  }

  void _deleteNote() {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1C1C24) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFEDEDFF) : const Color(0xFF1A1A2E);
    final textSecondary = isDark ? const Color(0xFF8888AA) : const Color(0xFF888899);

    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                  color: Colors.red.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_rounded, color: Colors.red, size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete note?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This note will be permanently removed and cannot be recovered.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: textSecondary, height: 1.45),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A36) : const Color(0xFFF0EFF6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(noteProvider.notifier).deleteNote(widget.note.id);
                        Navigator.pop(context);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                                SizedBox(width: 10),
                                Text('Note deleted'),
                              ],
                            ),
                            backgroundColor: const Color(0xFF2D2D3A),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            margin: const EdgeInsets.all(16),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: const Text('Delete', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red)),
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

  void _togglePin() {
    HapticFeedback.lightImpact();
    ref.read(noteProvider.notifier).toggleFavorite(widget.note.id);
    setState(() => _isPinned = !_isPinned);
    _pinController.reset();
    _pinController.forward();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF5F4F8);
    final cardBg = isDark ? const Color(0xFF1C1C24) : Colors.white;
    final surfaceColor = isDark ? const Color(0xFF16161F) : const Color(0xFFEEEDF4);
    final accentColor = const Color(0xFF7C6FE0);
    final textPrimary = isDark ? const Color(0xFFEDEDFF) : const Color(0xFF1A1A2E);
    final textSecondary = isDark ? const Color(0xFF8888AA) : const Color(0xFF888899);

    final wordCount = widget.note.content.trim().isEmpty
        ? 0
        : widget.note.content.trim().split(RegExp(r'\s+')).length;
    final charCount = widget.note.content.length;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
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
                        child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: textPrimary),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.note.title.isEmpty ? 'Untitled' : widget.note.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ScaleTransition(
                      scale: _pinScaleAnimation,
                      child: GestureDetector(
                        onTap: _togglePin,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _isPinned ? accentColor.withOpacity(0.15) : cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _isPinned ? accentColor.withOpacity(0.3) : Colors.transparent,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                            size: 18,
                            color: _isPinned ? accentColor : textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _editNote,
                      child: Container(
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
                        child: Icon(Icons.edit_rounded, size: 18, color: textPrimary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _deleteNote,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              _buildMetaChip(
                                icon: Icons.access_time_rounded,
                                label: _formatDate(widget.note.updatedAt),
                                color: textSecondary,
                                bgColor: surfaceColor,
                              ),
                              const SizedBox(width: 10),
                              _buildMetaChip(
                                icon: Icons.text_fields_rounded,
                                label: '$wordCount words',
                                color: textSecondary,
                                bgColor: surfaceColor,
                              ),
                              const SizedBox(width: 10),
                              _buildMetaChip(
                                icon: Icons.format_size_rounded,
                                label: '$charCount chars',
                                color: textSecondary,
                                bgColor: surfaceColor,
                              ),
                              if (_isPinned) ...[
                                const SizedBox(width: 10),
                                _buildMetaChip(
                                  icon: Icons.push_pin_rounded,
                                  label: 'Pinned',
                                  color: accentColor,
                                  bgColor: accentColor.withOpacity(0.1),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.22 : 0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: accentColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'NOTE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: textSecondary,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SelectableText(
                                widget.note.content.isEmpty ? 'No content.' : widget.note.content,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  color: widget.note.content.isEmpty ? textSecondary : textPrimary,
                                  height: 1.75,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                label: 'Edit Note',
                                icon: Icons.edit_rounded,
                                onTap: _editNote,
                                isDestructive: false,
                                accentColor: accentColor,
                                surfaceColor: surfaceColor,
                                textPrimary: textPrimary,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionButton(
                                label: 'Delete',
                                icon: Icons.delete_rounded,
                                onTap: _deleteNote,
                                isDestructive: true,
                                accentColor: accentColor,
                                surfaceColor: surfaceColor,
                                textPrimary: textPrimary,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.1)),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDestructive,
    required Color accentColor,
    required Color surfaceColor,
    required Color textPrimary,
    required bool isDark,
  }) {
    final bg = isDestructive ? Colors.red.withOpacity(0.08) : surfaceColor;
    final fg = isDestructive ? Colors.red : textPrimary;
    final borderColor = isDestructive ? Colors.red.withOpacity(0.2) : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg, letterSpacing: 0.1)),
          ],
        ),
      ),
    );
  }
}