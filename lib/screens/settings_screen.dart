import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/glass_container.dart';

enum SettingsAction { openBookmarks, openChapterProgress }

class SettingsScreen extends StatefulWidget {
  final bool notificationsEnabled;
  final String widgetLanguage;
  final String widgetMode;
  final String themeMode;
  final Color themeColor;
  final Future<bool> Function(bool enabled) onNotificationsChanged;
  final Future<void> Function(String language) onWidgetLanguageChanged;
  final Future<void> Function(String mode) onWidgetModeChanged;
  final Future<void> Function(String mode) onThemeModeChanged;
  final void Function(SettingsAction action)? onLibraryAction;

  const SettingsScreen({
    super.key,
    required this.notificationsEnabled,
    required this.widgetLanguage,
    required this.widgetMode,
    required this.themeMode,
    required this.themeColor,
    required this.onNotificationsChanged,
    required this.onWidgetLanguageChanged,
    required this.onWidgetModeChanged,
    required this.onThemeModeChanged,
    this.onLibraryAction,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _notificationsEnabled;
  late String _widgetLanguage;
  late String _widgetMode;
  late String _themeMode;
  bool _isUpdatingNotifications = false;
  bool _isUpdatingLanguage = false;
  bool _isUpdatingMode = false;
  bool _isUpdatingTheme = false;

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = widget.notificationsEnabled;
    _widgetLanguage = _normalizeWidgetLanguage(widget.widgetLanguage);
    _widgetMode = _normalizeWidgetMode(widget.widgetMode);
    _themeMode = _normalizeThemeMode(widget.themeMode);
  }

  String _normalizeWidgetLanguage(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'sanskrit' || normalized == 'sa') {
      return 'sanskrit';
    }
    return 'english';
  }

  String _normalizeWidgetMode(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'random') {
      return 'random';
    }
    return 'fixed';
  }

  String _normalizeThemeMode(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'light') {
      return 'light';
    }
    return 'dark';
  }

  Future<void> _handleNotificationsChanged(bool value) async {
    setState(() {
      _isUpdatingNotifications = true;
      _notificationsEnabled = value;
    });

    final actualEnabled = await widget.onNotificationsChanged(value);

    if (!mounted) {
      return;
    }

    setState(() {
      _notificationsEnabled = actualEnabled;
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

  Future<void> _handleWidgetModeChanged(String value) async {
    if (value == _widgetMode) {
      return;
    }

    setState(() {
      _isUpdatingMode = true;
      _widgetMode = value;
    });

    await widget.onWidgetModeChanged(value);

    if (!mounted) {
      return;
    }

    setState(() {
      _isUpdatingMode = false;
    });
  }

  Future<void> _handleThemeModeChanged(String value) async {
    if (value == _themeMode) {
      return;
    }

    setState(() {
      _isUpdatingTheme = true;
      _themeMode = value;
    });

    await widget.onThemeModeChanged(value);

    if (!mounted) {
      return;
    }

    setState(() {
      _isUpdatingTheme = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLightTheme = _themeMode == 'light';
    final topColor = isLightTheme
        ? const Color(0xFFF6E8D1)
        : widget.themeColor.withValues(alpha: 0.85);
    final bottomColor = isLightTheme
        ? const Color(0xFFE7D3B4)
        : widget.themeColor.withValues(alpha: 0.35);
    final backgroundTail = isLightTheme
        ? const Color(0xFFDCC5A4)
        : const Color(0xFF121A28);
    final scaffoldColor = isLightTheme
        ? const Color(0xFFF1E2CA)
        : Colors.black;
    final primaryTextColor = isLightTheme
        ? const Color(0xFF241A12)
        : Colors.white;
    final secondaryTextColor = isLightTheme
        ? const Color(0xFF5D4A35)
        : Colors.white70;
    final iconColor = isLightTheme ? const Color(0xFF2E231A) : Colors.white;
    final dropdownColor = isLightTheme
        ? const Color(0xFFF4E6D1)
        : const Color(0xFF1E2432);
    final switchThumbColor = isLightTheme
        ? const Color(0xFF2E231A)
        : Colors.white;
    final switchActiveTrackColor = isLightTheme
        ? const Color(0xFFAF8A5C)
        : Colors.white38;
    final switchInactiveThumbColor = isLightTheme
        ? const Color(0xFF7A6957)
        : Colors.white70;
    final switchInactiveTrackColor = isLightTheme
        ? const Color(0xFFCCB89A)
        : Colors.white24;
    final helperPanelColor = isLightTheme
        ? Colors.black.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.08);
    final helperPanelBorderColor = isLightTheme
        ? Colors.black.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.14);

    return Scaffold(
      backgroundColor: scaffoldColor,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [topColor, bottomColor, backgroundTail],
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
                      'One daily verse reminder',
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
                  title: 'Appearance',
                  child: SwitchListTile(
                    value: _themeMode == 'light',
                    onChanged: _isUpdatingTheme
                        ? null
                        : (value) =>
                              _handleThemeModeChanged(value ? 'light' : 'dark'),
                    secondary: const Icon(
                      Icons.brightness_6_outlined,
                      color: Colors.white,
                    ),
                    title: Text(
                      'Light theme',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      _themeMode == 'light'
                          ? 'Using light backgrounds'
                          : 'Using dark backgrounds',
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
                          Icons.shuffle_rounded,
                          color: Colors.white,
                        ),
                        title: Text(
                          'Widget mode',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _widgetMode,
                            dropdownColor: const Color(0xFF1E2432),
                            style: GoogleFonts.inter(color: Colors.white),
                            items: const [
                              DropdownMenuItem(
                                value: 'fixed',
                                child: Text('Fixed'),
                              ),
                              DropdownMenuItem(
                                value: 'random',
                                child: Text('Random'),
                              ),
                            ],
                            onChanged: _isUpdatingMode
                                ? null
                                : (value) {
                                    if (value != null) {
                                      _handleWidgetModeChanged(value);
                                    }
                                  },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.14),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.touch_app_outlined,
                                color: Colors.white70,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _widgetMode == 'random'
                                      ? 'Tap the widget card to refresh random verses.'
                                      : 'Add the widget first, then tap it to choose a fixed verse.',
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 12.5,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
