import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/glass_container.dart';

class SettingsScreen extends StatefulWidget {
  final bool notificationsEnabled;
  final String widgetLanguage;
  final String widgetMode;
  final String themeMode;
  final Future<bool> Function(bool enabled) onNotificationsChanged;
  final Future<void> Function(String language) onWidgetLanguageChanged;
  final Future<void> Function(String mode) onWidgetModeChanged;
  final Future<void> Function(String mode) onThemeModeChanged;
  final Future<void> Function()? onOpenBookmarks;
  final Future<void> Function()? onOpenChapterProgress;
  final Future<void> Function()? onPickFixedWidgetVerse;

  const SettingsScreen({
    super.key,
    required this.notificationsEnabled,
    required this.widgetLanguage,
    required this.widgetMode,
    required this.themeMode,
    required this.onNotificationsChanged,
    required this.onWidgetLanguageChanged,
    required this.onWidgetModeChanged,
    required this.onThemeModeChanged,
    this.onOpenBookmarks,
    this.onOpenChapterProgress,
    this.onPickFixedWidgetVerse,
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

    if (value == 'fixed') {
      final onPick = widget.onPickFixedWidgetVerse;
      if (onPick != null) {
        await onPick();
      }
    }
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
        ? const Color(0xFFF0E8DC)
        : const Color(0xFF0D1118);
    final bottomColor = isLightTheme
        ? const Color(0xFFE3D7C5)
        : const Color(0xFF121927);
    final backgroundTail = isLightTheme
        ? const Color(0xFFD7C7B2)
        : const Color(0xFF070A10);
    final scaffoldColor = isLightTheme
        ? const Color(0xFFEDE3D3)
        : const Color(0xFF090C12);
    final primaryTextColor = isLightTheme
        ? const Color(0xFF241A12)
        : Colors.white;
    final secondaryTextColor = isLightTheme
        ? const Color(0xFF5D4A35)
        : Colors.white70;
    final iconColor = isLightTheme ? const Color(0xFF2E231A) : Colors.white;
    final dropdownColor = isLightTheme
        ? const Color(0xFFF0E4D2)
        : const Color(0xFF161E2C);
    final switchThumbColor = isLightTheme
        ? const Color(0xFF2E231A)
        : Colors.white;
    final switchActiveTrackColor = isLightTheme
        ? const Color(0xFFAF8A5C)
        : const Color(0xFF405169);
    final switchInactiveThumbColor = isLightTheme
        ? const Color(0xFF7A6957)
        : Colors.white70;
    final switchInactiveTrackColor = isLightTheme
        ? const Color(0xFFCCB89A)
        : const Color(0xFF263042);
    final helperPanelColor = isLightTheme
        ? Colors.black.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.06);
    final helperPanelBorderColor = isLightTheme
        ? Colors.black.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.1);

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
                        child: Icon(
                          Icons.arrow_back,
                          color: iconColor,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Settings',
                      style: GoogleFonts.inter(
                        color: primaryTextColor,
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
                      'Notifications',
                      style: GoogleFonts.inter(
                        color: primaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Verse reminders',
                      style: GoogleFonts.inter(color: secondaryTextColor),
                    ),
                    activeThumbColor: switchThumbColor,
                    activeTrackColor: switchActiveTrackColor,
                    inactiveThumbColor: switchInactiveThumbColor,
                    inactiveTrackColor: switchInactiveTrackColor,
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
                    secondary: Icon(
                      Icons.brightness_6_outlined,
                      color: iconColor,
                    ),
                    title: Text(
                      _themeMode == 'light' ? 'Light theme' : 'Dark theme',
                      style: GoogleFonts.inter(
                        color: primaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    activeThumbColor: switchThumbColor,
                    activeTrackColor: switchActiveTrackColor,
                    inactiveThumbColor: switchInactiveThumbColor,
                    inactiveTrackColor: switchInactiveTrackColor,
                  ),
                ),
                const SizedBox(height: 12),
                _glassSection(
                  title: 'Widget',
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.translate,
                          color: iconColor,
                        ),
                        title: Text(
                          'Widget language',
                          style: GoogleFonts.inter(
                            color: primaryTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _widgetLanguage,
                            dropdownColor: dropdownColor,
                            style: GoogleFonts.inter(color: primaryTextColor),
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
                        leading: Icon(
                          Icons.shuffle_rounded,
                          color: iconColor,
                        ),
                        title: Text(
                          'Widget mode',
                          style: GoogleFonts.inter(
                            color: primaryTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _widgetMode,
                            dropdownColor: dropdownColor,
                            style: GoogleFonts.inter(color: primaryTextColor),
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
                      if (_widgetMode == 'fixed')
                        ListTile(
                          leading: Icon(
                            Icons.tune_rounded,
                            color: iconColor,
                          ),
                          title: Text(
                            'Choose fixed verse',
                            style: GoogleFonts.inter(
                              color: primaryTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Select verse from in-app picker',
                            style: GoogleFonts.inter(color: secondaryTextColor),
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: secondaryTextColor,
                          ),
                          onTap: () async {
                            final onPick = widget.onPickFixedWidgetVerse;
                            if (onPick != null) {
                              await onPick();
                            }
                          },
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: helperPanelColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: helperPanelBorderColor,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.touch_app_outlined,
                                color: secondaryTextColor,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _widgetMode == 'random'
                                      ? 'Tap the widget card to refresh random verses.'
                                      : 'Choose a fixed verse here or tap the widget on home screen.',
                                  style: GoogleFonts.inter(
                                    color: secondaryTextColor,
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
                        leading: Icon(
                          Icons.auto_graph_rounded,
                          color: iconColor,
                        ),
                        title: Text(
                          'Chapter progress',
                          style: GoogleFonts.inter(
                            color: primaryTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Open chapter progress and jump to verses',
                          style: GoogleFonts.inter(color: secondaryTextColor),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: secondaryTextColor,
                        ),
                        onTap: () async {
                          final onOpen = widget.onOpenChapterProgress;
                          if (onOpen != null) {
                            await onOpen();
                          }
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.bookmark,
                          color: iconColor,
                        ),
                        title: Text(
                          'Bookmarks',
                          style: GoogleFonts.inter(
                            color: primaryTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Open saved verses',
                          style: GoogleFonts.inter(color: secondaryTextColor),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: secondaryTextColor,
                        ),
                        onTap: () async {
                          final onOpen = widget.onOpenBookmarks;
                          if (onOpen != null) {
                            await onOpen();
                          }
                        },
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
    final isLightTheme = _themeMode == 'light';
    final sectionTitleColor = isLightTheme
        ? const Color(0xFF5B4A36)
        : Colors.white70;
    final glassColor = isLightTheme
        ? const Color(0xFFFFF3DE)
        : const Color(0xFF1A2230);
    return GlassContainer(
      blur: 12,
      opacity: isLightTheme ? 0.34 : 0.3,
      color: glassColor,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: GoogleFonts.inter(
                color: sectionTitleColor,
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
