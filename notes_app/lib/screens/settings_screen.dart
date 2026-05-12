import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _enterController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOutCubic,
    ));
    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
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

    final settingsItems = [
      _SettingsItem(
        icon: Icons.dark_mode_rounded,
        title: 'Dark Mode',
        subtitle: 'Switch between light & dark',
        iconBgColor: const Color(0xFF3B2F6E),
        iconColor: const Color(0xFFB8AFFF),
      ),
      _SettingsItem(
        icon: Icons.palette_rounded,
        title: 'Theme Color',
        subtitle: 'Choose your accent color',
        iconBgColor: const Color(0xFF1E3A5F),
        iconColor: const Color(0xFF7EB8FF),
      ),
      _SettingsItem(
        icon: Icons.cloud_upload_rounded,
        title: 'Backup & Sync',
        subtitle: 'Secure your notes in the cloud',
        iconBgColor: const Color(0xFF1A3D2E),
        iconColor: const Color(0xFF6FDDAA),
      ),
      _SettingsItem(
        icon: Icons.notifications_rounded,
        title: 'Notifications',
        subtitle: 'Get reminded about your notes',
        iconBgColor: const Color(0xFF3D2B1A),
        iconColor: const Color(0xFFFFB86F),
      ),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Top Bar ──────────────────────────────────────────────
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          'Customize your experience',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ─── Content ──────────────────────────────────────────────
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    children: [
                      // Section label
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 12),
                        child: Text(
                          'PREFERENCES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: textSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),

                      // Settings cards
                      ...settingsItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return _AnimatedSettingsItem(
                          index: index,
                          child: _buildSettingsCard(
                            item: item,
                            isDark: isDark,
                            cardBg: cardBg,
                            surfaceColor: surfaceColor,
                            accentColor: accentColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            context: context,
                          ),
                        );
                      }),

                      const SizedBox(height: 28),

                      // About card
                      _AnimatedSettingsItem(
                        index: settingsItems.length,
                        child: _buildAboutCard(
                          isDark: isDark,
                          cardBg: cardBg,
                          accentColor: accentColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required _SettingsItem item,
    required bool isDark,
    required Color cardBg,
    required Color surfaceColor,
    required Color accentColor,
    required Color textPrimary,
    required Color textSecondary,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.rocket_launch_rounded,
                    color: Colors.white, size: 16),
                const SizedBox(width: 10),
                Text('${item.title} — coming soon!'),
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.iconBgColor,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 20),
            ),

            const SizedBox(width: 14),

            // Labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // "Soon" badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: accentColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                'Soon',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard({
    required bool isDark,
    required Color cardBg,
    required Color accentColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // App icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C6FE0), Color(0xFF5A4FCC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.sticky_note_2_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'NoteFlow',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 4),

          // Version badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accentColor,
                letterSpacing: 0.3,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'A beautiful and minimal notes app\nbuilt with Flutter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: textSecondary,
              height: 1.55,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 20),

          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  textSecondary.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Made with love row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_rounded,
                  size: 13, color: Colors.red.shade400),
              const SizedBox(width: 5),
              Text(
                'Made with love',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Settings Item Model ───────────────────────────────────────────────────
class _SettingsItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBgColor;
  final Color iconColor;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBgColor,
    required this.iconColor,
  });
}

// ─── Staggered Entrance Animation ─────────────────────────────────────────
class _AnimatedSettingsItem extends StatefulWidget {
  final Widget child;
  final int index;

  const _AnimatedSettingsItem({
    required this.child,
    required this.index,
  });

  @override
  State<_AnimatedSettingsItem> createState() => _AnimatedSettingsItemState();
}

class _AnimatedSettingsItemState extends State<_AnimatedSettingsItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(
        Duration(milliseconds: 80 * widget.index.clamp(0, 6)), () {
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
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}