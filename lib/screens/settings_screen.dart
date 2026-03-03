import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/glass_container.dart';

enum SettingsAction { openBookmarks, chooseWidgetVerse, openChapterProgress }

class SettingsScreen extends StatefulWidget {
  final bool notificationsEnabled;
  final String widgetLanguage;
  final Color themeColor;
  final Future<void> Function(bool enabled) onNotificationsChanged;
  final Future<void> Function(String language) onWidgetLanguageChanged;

  const SettingsScreen({
    super.key,
    required this.notificationsEnabled,
    required this.widgetLanguage,
    required this.themeColor,
    required this.onNotificationsChanged,
    required this.onWidgetLanguageChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _notificationsEnabled;
  late String _widgetLanguage;
  bool _isUpdatingNotifications = false;
  bool _isUpdatingLanguage = false;

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = widget.notificationsEnabled;
    _widgetLanguage = _normalizeWidgetLanguage(widget.widgetLanguage);
  }

  String _normalizeWidgetLanguage(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'sanskrit' || normalized == 'sa') {
      return 'sanskrit';
    }
    return 'english';
  }

  Future<void> _handleNotificationsChanged(bool value) async {
    setState(() {
      _isUpdatingNotifications = true;
      _notificationsEnabled = value;
    });

    await widget.onNotificationsChanged(value);

    if (!mounted) {
      return;
    }

    setState(() {
      _isUpdatingNotifications = false;
    });
  }

  Future<void> _handleWidgetLanguageChanged(String value) async {
    if (value == _widgetLanguage) {
      return;
    }

    setState(() {
      _isUpdatingLanguage = true;
      _widgetLanguage = value;
    });

    await widget.onWidgetLanguageChanged(value);

    if (!mounted) {
      return;
    }

    setState(() {
      _isUpdatingLanguage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topColor = widget.themeColor.withValues(alpha: 0.85);
    final bottomColor = widget.themeColor.withValues(alpha: 0.35);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [topColor, bottomColor, const Color(0xFF121A28)],
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: GlassContainer(
                        width: 42,
                        height: 42,
                        padding: EdgeInsets.zero,
                        borderRadius: BorderRadius.circular(21),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Settings',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _glassSection(
                  title: 'Notifications',
                  child: SwitchListTile(
                    value: _notificationsEnabled,
                    onChanged: _isUpdatingNotifications
                        ? null
                        : _handleNotificationsChanged,
                    title: Text(
                      'Daily notifications',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      "Today's Verse + Random Verse",
                      style: GoogleFonts.inter(color: Colors.white70),
                    ),
                    activeThumbColor: Colors.white,
                    activeTrackColor: Colors.white38,
                    inactiveThumbColor: Colors.white70,
                    inactiveTrackColor: Colors.white24,
                  ),
                ),
                const SizedBox(height: 12),
                _glassSection(
                  title: 'Widget',
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.translate,
                          color: Colors.white,
                        ),
                        title: Text(
                          'Widget language',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _widgetLanguage,
                            dropdownColor: const Color(0xFF1E2432),
                            style: GoogleFonts.inter(color: Colors.white),
                            items: const [
                              DropdownMenuItem(
                                value: 'sanskrit',
                                child: Text('Sanskrit'),
                              ),
                              DropdownMenuItem(
                                value: 'english',
                                child: Text('English'),
                              ),
                            ],
                            onChanged: _isUpdatingLanguage
                                ? null
                                : (value) {
                                    if (value != null) {
                                      _handleWidgetLanguageChanged(value);
                                    }
                                  },
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.widgets_outlined,
                          color: Colors.white,
                        ),
                        title: Text(
                          'Choose widget verse',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Pick a specific verse for home screen widget',
                          style: GoogleFonts.inter(color: Colors.white70),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.white70,
                        ),
                        onTap: () => Navigator.pop(
                          context,
                          SettingsAction.chooseWidgetVerse,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _glassSection(
                  title: 'Library',
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.auto_graph_rounded,
                          color: Colors.white,
                        ),
                        title: Text(
                          'Chapter progress',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Open chapter progress and jump to verses',
                          style: GoogleFonts.inter(color: Colors.white70),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.white70,
                        ),
                        onTap: () => Navigator.pop(
                          context,
                          SettingsAction.openChapterProgress,
                        ),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.bookmark,
                          color: Colors.white,
                        ),
                        title: Text(
                          'Bookmarks',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Open saved verses',
                          style: GoogleFonts.inter(color: Colors.white70),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.white70,
                        ),
                        onTap: () => Navigator.pop(
                          context,
                          SettingsAction.openBookmarks,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassSection({required String title, required Widget child}) {
    return GlassContainer(
      blur: 12,
      opacity: 0.14,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
