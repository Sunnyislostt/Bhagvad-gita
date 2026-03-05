import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/verse.dart';
import '../widgets/verse_card.dart';
import '../widgets/glass_container.dart';
import '../services/notification_service.dart';
import '../services/reading_progress_service.dart';
import '../services/widget_service.dart';
import '../services/verse_repository.dart';
import 'settings_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, this.initialVerseId});

  final String? initialVerseId;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  static const String _savedVersesKey = 'saved_verse_ids';
  static const String _lastReadIndexKey = 'last_read_verse_index';
  static const String _recentVerseIdsKey = 'recent_verse_ids';
  static const String _widgetLanguageKey = 'widget_language';
  static const String _widgetModeKey = 'widget_mode';
  static const String _displayLanguageKey = 'display_language';
  static const String _themeModeKey = 'theme_mode';
  static const String _darkBackgroundImage = 'assets/images/Dark.jpeg';
  static const String _lightBackgroundImage = 'assets/images/light .jpeg';

  final PageController _pageController = PageController();
  final GlobalKey _globalKey = GlobalKey();
  final WidgetService _widgetService = WidgetService();
  final VerseRepository _verseRepository = const VerseRepository();
  final ReadingProgressService _readingProgressService =
      ReadingProgressService();

  List<Verse> _verses = <Verse>[];
  Set<String> _savedVerseIds = <String>{};
  List<String> _recentVerseIds = <String>[];

  int _currentIndex = 0;
  bool _isLoading = true;
  String _displayLanguage = 'sanskrit';
  bool _hideUI = false;
  bool _notificationsEnabled = false;
  String _widgetLanguage = 'english';
  String _widgetMode = 'fixed';
  String _themeMode = 'dark';
  String _activeBackgroundImage = _darkBackgroundImage;
  String? _pendingWidgetLaunchAction;
  bool _isHandlingWidgetLaunchAction = false;

  @override
  void initState() {
    super.initState();
    _widgetService.setLaunchActionHandler(_handleWidgetLaunchAction);
    _initializeScreen();
  }

  @override
  void dispose() {
    _widgetService.clearLaunchActionHandler();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    await _loadPersistedState();
    await _loadVerses();
    await _loadNotificationState();
    await _widgetService.setLanguage(_widgetLanguage);
    await _widgetService.setMode(_widgetMode);
    await _consumePendingWidgetLaunchAction();
  }

  Future<void> _loadPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    final rawWidgetLanguage = prefs.getString(_widgetLanguageKey);
    final rawWidgetMode = prefs.getString(_widgetModeKey);
    final rawDisplayLanguage = prefs.getString(_displayLanguageKey);
    final rawThemeMode = prefs.getString(_themeModeKey);
    final normalizedWidgetLanguage = _normalizeWidgetLanguage(
      rawWidgetLanguage,
    );
    final normalizedWidgetMode = _normalizeWidgetMode(rawWidgetMode);
    final normalizedDisplayLanguage = _normalizeDisplayLanguage(
      rawDisplayLanguage,
    );
    final normalizedThemeMode = _normalizeThemeMode(rawThemeMode);
    final selectedBackground = _backgroundForTheme(normalizedThemeMode);

    if (!mounted) {
      return;
    }

    setState(() {
      _savedVerseIds = (prefs.getStringList(_savedVersesKey) ?? <String>[])
          .toSet();
      _recentVerseIds = prefs.getStringList(_recentVerseIdsKey) ?? <String>[];
      _currentIndex = prefs.getInt(_lastReadIndexKey) ?? 0;
      _widgetLanguage = normalizedWidgetLanguage;
      _widgetMode = normalizedWidgetMode;
      _displayLanguage = normalizedDisplayLanguage;
      _themeMode = normalizedThemeMode;
      _activeBackgroundImage = selectedBackground;
    });

    if (rawWidgetLanguage != null &&
        rawWidgetLanguage != normalizedWidgetLanguage) {
      await prefs.setString(_widgetLanguageKey, normalizedWidgetLanguage);
    }
    if (rawWidgetMode != null && rawWidgetMode != normalizedWidgetMode) {
      await prefs.setString(_widgetModeKey, normalizedWidgetMode);
    }
    if (rawDisplayLanguage != null &&
        rawDisplayLanguage != normalizedDisplayLanguage) {
      await prefs.setString(_displayLanguageKey, normalizedDisplayLanguage);
    }
    if (rawThemeMode != null && rawThemeMode != normalizedThemeMode) {
      await prefs.setString(_themeModeKey, normalizedThemeMode);
    }
  }

  String _normalizeWidgetLanguage(String? language) {
    final normalized = language?.trim().toLowerCase();
    if (normalized == 'sanskrit' || normalized == 'sa') {
      return 'sanskrit';
    }
    return 'english';
  }

  String _normalizeDisplayLanguage(String? language) {
    final normalized = language?.trim().toLowerCase();
    if (normalized == 'english' ||
        normalized == 'en' ||
        normalized == 'hindi' ||
        normalized == 'hi') {
      return 'english';
    }
    return 'sanskrit';
  }

  String _normalizeWidgetMode(String? mode) {
    final normalized = mode?.trim().toLowerCase();
    if (normalized == 'random') {
      return 'random';
    }
    return 'fixed';
  }

  String _normalizeThemeMode(String? mode) {
    final normalized = mode?.trim().toLowerCase();
    if (normalized == 'light') {
      return 'light';
    }
    return 'dark';
  }

  String _languageDisplayName(String language) {
    return switch (language) {
      'sanskrit' => 'Sanskrit',
      _ => 'English',
    };
  }

  Future<void> _persistSavedVerses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_savedVersesKey, _savedVerseIds.toList());
  }

  Future<void> _persistCurrentIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastReadIndexKey, index);
  }

  Future<void> _persistRecentVerses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentVerseIdsKey, _recentVerseIds);
  }

  Future<void> _persistWidgetLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_widgetLanguageKey, language);
  }

  Future<void> _persistWidgetMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_widgetModeKey, mode);
  }

  Future<void> _persistDisplayLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_displayLanguageKey, language);
  }

  Future<void> _persistThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode);
  }

  void _recordVerseInHistory(String verseId) {
    _recentVerseIds.remove(verseId);
    _recentVerseIds.insert(0, verseId);

    if (_recentVerseIds.length > 30) {
      _recentVerseIds = _recentVerseIds.sublist(0, 30);
    }

    _persistRecentVerses();
  }

  Future<void> _loadNotificationState() async {
    final enabled = await NotificationService().areNotificationsEnabled();
    if (!mounted) {
      return;
    }

    setState(() {
      _notificationsEnabled = enabled;
    });
  }

  Future<bool> _setNotifications(bool enabled) async {
    await NotificationService().toggleNotifications(enabled);
    final actualEnabled = await NotificationService().areNotificationsEnabled();
    if (!mounted) {
      return actualEnabled;
    }

    setState(() {
      _notificationsEnabled = actualEnabled;
    });
    return actualEnabled;
  }

  Future<void> _consumePendingWidgetLaunchAction() async {
    final action = await _widgetService.consumeLaunchAction();
    if (action == null || action.isEmpty) {
      return;
    }
    await _handleWidgetLaunchAction(action);
  }

  Future<void> _handleWidgetLaunchAction(String action) async {
    if (action != WidgetService.actionPickVerse) {
      return;
    }

    if (_isLoading || _verses.isEmpty) {
      _pendingWidgetLaunchAction = action;
      return;
    }

    if (!mounted || _isHandlingWidgetLaunchAction) {
      return;
    }

    _pendingWidgetLaunchAction = null;
    _isHandlingWidgetLaunchAction = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!mounted) {
        return;
      }
      if (_widgetMode == 'random') {
        await _setWidgetMode('fixed');
      }
      await _showWidgetVersePicker(
        title: 'Choose Verse For Widget',
        subtitle: 'Opened from widget tap - ${_languageDisplayName(_widgetLanguage)}',
      );
    } finally {
      _isHandlingWidgetLaunchAction = false;
    }
  }

  Future<void> _loadVerses() async {
    try {
      final loadedVerses = await _verseRepository.loadVerses();

      if (!mounted) {
        return;
      }

      final preferredIndex =
          _resolveInitialIndex(loadedVerses) ?? _currentIndex;
      final safeIndex = loadedVerses.isEmpty
          ? 0
          : preferredIndex.clamp(0, loadedVerses.length - 1).toInt();

      setState(() {
        _verses = loadedVerses;
        _currentIndex = safeIndex;
        _isLoading = false;
      });

      if (loadedVerses.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(safeIndex);
          }
        });

        _recordVerseInHistory(loadedVerses[safeIndex].id);
        _persistCurrentIndex(safeIndex);
        _recordChapterProgress(loadedVerses[safeIndex]);
      }

      final pendingAction = _pendingWidgetLaunchAction;
      if (pendingAction != null && pendingAction.isNotEmpty) {
        await _handleWidgetLaunchAction(pendingAction);
      }
    } catch (e) {
      debugPrint('Error loading verses: $e');
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  int? _resolveInitialIndex(List<Verse> verses) {
    final initialId = widget.initialVerseId;
    if (initialId == null || initialId.isEmpty || verses.isEmpty) {
      return null;
    }

    final targetIndex = verses.indexWhere((verse) => verse.id == initialId);
    if (targetIndex == -1) {
      return null;
    }
    return targetIndex;
  }

  String _backgroundForTheme(String mode) {
    return _normalizeThemeMode(mode) == 'light'
        ? _lightBackgroundImage
        : _darkBackgroundImage;
  }

  Future<void> _recordChapterProgress(Verse verse) async {
    await _readingProgressService.recordVerse(verse);
  }

  Color _hexToColor(String hexCode) {
    var hex = hexCode.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse('0x$hex'));
  }

  Future<void> _shareCurrentScreen() async {
    setState(() {
      _hideUI = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));
    try {
      final boundary =
          _globalKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Could not capture screen');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to encode image');
      }

      final pngBytes = byteData.buffer.asUint8List();
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/bhagavad_gita_verse_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);

      final verse = _verses[_currentIndex];
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(file.path)],
          text:
              'Chapter ${verse.chapter}, Verse ${verse.verseNumber} - Bhagavad Gita',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to share. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _hideUI = false;
        });
      }
    }
  }

  Future<void> _pinVerseToWidget(Verse verse) async {
    final success = await _widgetService.pinVerse(
      verse,
      language: _widgetLanguage,
    );
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Pinned Chapter ${verse.chapter}, Verse ${verse.verseNumber} to widget'
              : 'Unable to pin verse to widget',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _setWidgetLanguage(String language) async {
    final normalized = _normalizeWidgetLanguage(language);
    setState(() {
      _widgetLanguage = normalized;
    });
    await _persistWidgetLanguage(normalized);
    await _widgetService.setLanguage(normalized);
  }

  Future<void> _setWidgetMode(String mode) async {
    final normalized = _normalizeWidgetMode(mode);
    setState(() {
      _widgetMode = normalized;
    });
    await _persistWidgetMode(normalized);
    await _widgetService.setMode(normalized);
  }

  Future<void> _setThemeMode(String mode) async {
    final normalized = _normalizeThemeMode(mode);
    setState(() {
      _themeMode = normalized;
      _activeBackgroundImage = _backgroundForTheme(normalized);
    });
    await _persistThemeMode(normalized);
  }

  void _cycleDisplayLanguage() {
    final next = switch (_displayLanguage) {
      'sanskrit' => 'english',
      _ => 'sanskrit',
    };

    setState(() {
      _displayLanguage = next;
    });
    _persistDisplayLanguage(next);
  }

  String _displayLanguageLabel() {
    return switch (_displayLanguage) {
      'sanskrit' => 'SA',
      'english' => 'EN',
      _ => 'SA',
    };
  }

  String _textForLanguage(Verse verse, String language) {
    return switch (language) {
      'sanskrit' => verse.originalScript,
      _ => verse.translationEnglish,
    };
  }

  Future<void> _shareVerseText(Verse verse) async {
    try {
      final verseText = _textForLanguage(verse, _displayLanguage);
      await SharePlus.instance.share(
        ShareParams(
          text:
              'Chapter ${verse.chapter}, Verse ${verse.verseNumber}\n\n$verseText\n\n- Bhagavad Gita',
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to share this verse right now.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _openCurrentVerseDetails() {
    if (_verses.isEmpty ||
        _currentIndex < 0 ||
        _currentIndex >= _verses.length) {
      return;
    }
    VerseCard.showDetailsBottomSheet(context, _verses[_currentIndex]);
  }

  void _toggleSave(String id) {
    setState(() {
      if (_savedVerseIds.contains(id)) {
        _savedVerseIds.remove(id);
      } else {
        _savedVerseIds.add(id);
      }
    });
    _persistSavedVerses();
  }

  bool _matchesSearchQuery(Verse verse, String query) {
    final lowerQuery = query.toLowerCase();
    final chapterVerse = '${verse.chapter}:${verse.verseNumber}';
    final chapterVerseSpaced = '${verse.chapter} ${verse.verseNumber}';

    return chapterVerse.contains(lowerQuery) ||
        chapterVerseSpaced.contains(lowerQuery) ||
        verse.id.toLowerCase().contains(lowerQuery) ||
        verse.translationEnglish.toLowerCase().contains(lowerQuery) ||
        verse.transliteration.toLowerCase().contains(lowerQuery) ||
        verse.originalScript.contains(query);
  }

  void _jumpToVerseById(String verseId) {
    final targetIndex = _verses.indexWhere((verse) => verse.id == verseId);
    if (targetIndex == -1) {
      return;
    }

    _pageController.animateToPage(
      targetIndex,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _showChapterPickerSheet() async {
    final versesByChapter = <int, List<Verse>>{};
    for (final verse in _verses) {
      versesByChapter.putIfAbsent(verse.chapter, () => <Verse>[]).add(verse);
    }
    for (final entry in versesByChapter.entries) {
      entry.value.sort((a, b) => a.verseNumber.compareTo(b.verseNumber));
    }
    final chapters = versesByChapter.keys.toList()..sort();
    if (chapters.isEmpty) {
      return;
    }

    final currentChapter = _verses[_currentIndex].chapter;
    final currentVerseId = _verses[_currentIndex].id;
    var selectedChapter = currentChapter;

    final selectedVerseId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.48,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                final chapterVerses =
                    versesByChapter[selectedChapter] ?? const <Verse>[];
                return GlassContainer(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  opacity: 0.15,
                  blur: 25,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Go To Chapter & Verse',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: DropdownButtonFormField<int>(
                          key: ValueKey<int>(selectedChapter),
                          initialValue: selectedChapter,
                          dropdownColor: const Color(0xFF1C1C1E),
                          style: GoogleFonts.inter(color: Colors.white),
                          iconEnabledColor: Colors.white70,
                          decoration: InputDecoration(
                            labelText: 'Chapter',
                            labelStyle: GoogleFonts.inter(
                              color: Colors.white70,
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.08),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: chapters
                              .map(
                                (chapter) => DropdownMenuItem<int>(
                                  value: chapter,
                                  child: Text('Chapter $chapter'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setModalState(() {
                              selectedChapter = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Tap a verse',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: GridView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 1.5,
                              ),
                          itemCount: chapterVerses.length,
                          itemBuilder: (context, index) {
                            final verse = chapterVerses[index];
                            final isCurrent = verse.id == currentVerseId;
                            return InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => Navigator.of(context).pop(verse.id),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? const Color(
                                          0xFFFFD27D,
                                        ).withValues(alpha: 0.26)
                                      : Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isCurrent
                                        ? const Color(
                                            0xFFFFD27D,
                                          ).withValues(alpha: 0.85)
                                        : Colors.white.withValues(alpha: 0.18),
                                  ),
                                ),
                                child: Text(
                                  '${verse.verseNumber}',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
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
              },
            );
          },
        );
      },
    );

    if (!mounted || selectedVerseId == null) {
      return;
    }
    _jumpToVerseById(selectedVerseId);
  }

  Future<void> _showWidgetVersePicker({
    String? title,
    String? subtitle,
  }) async {
    final selectedVerseId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) {
        return _VerseSearchSheet(
          verses: _verses,
          matchesSearchQuery: _matchesSearchQuery,
          initialChildSize: 0.8,
          title: title ?? 'Choose Fixed Widget Verse',
          subtitle:
              subtitle ??
              'Widget language: ${_languageDisplayName(_widgetLanguage)}',
          trailingIcon: const Icon(
            Icons.widgets_outlined,
            color: Colors.white70,
          ),
          previewTextBuilder: (verse) =>
              _textForLanguage(verse, _widgetLanguage),
        );
      },
    );

    if (!mounted || selectedVerseId == null) {
      return;
    }

    final selectedIndex = _verses.indexWhere(
      (verse) => verse.id == selectedVerseId,
    );
    if (selectedIndex == -1) {
      return;
    }
    if (_widgetMode != 'fixed') {
      await _setWidgetMode('fixed');
    }
    await _pinVerseToWidget(_verses[selectedIndex]);
  }

  Future<void> _openSettingsPage() async {
    final accentColor = _hexToColor(_verses[_currentIndex].backgroundHexColor);
    final action = await Navigator.of(context).push<SettingsAction>(
      PageRouteBuilder<SettingsAction>(
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, animation, secondaryAnimation) => SettingsScreen(
          notificationsEnabled: _notificationsEnabled,
          widgetLanguage: _widgetLanguage,
          widgetMode: _widgetMode,
          themeMode: _themeMode,
          themeColor: accentColor,
          onNotificationsChanged: _setNotifications,
          onWidgetLanguageChanged: _setWidgetLanguage,
          onWidgetModeChanged: _setWidgetMode,
          onThemeModeChanged: _setThemeMode,
        ),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          final slide = Tween<Offset>(
            begin: const Offset(0.03, 0),
            end: Offset.zero,
          ).animate(fade);
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    );

    if (!mounted || action == null) {
      return;
    }

    // Wait for settings pop transition to fully settle before opening sheets.
    await Future<void>.delayed(const Duration(milliseconds: 360));
    if (!mounted) {
      return;
    }

    if (action == SettingsAction.openBookmarks) {
      await _showSavedVerses(context);
    } else if (action == SettingsAction.openChapterProgress) {
      await _showChapterProgressSheet();
    }
  }

  Future<void> _showSavedVerses(BuildContext parentContext) async {
    await showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                final activeSavedVerses = _verses
                    .where((verse) => _savedVerseIds.contains(verse.id))
                    .toList();
                return GlassContainer(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  opacity: 0.15,
                  blur: 25,
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Saved Verses',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: activeSavedVerses.isEmpty
                            ? Center(
                                child: Text(
                                  'No saved verses yet.',
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: activeSavedVerses.length,
                                itemBuilder: (context, index) {
                                  final verse = activeSavedVerses[index];
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 8,
                                    ),
                                    title: Text(
                                      'Chapter ${verse.chapter}, Verse ${verse.verseNumber}',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    subtitle: Text(
                                      verse.translationEnglish,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.info_outline,
                                            color: Colors.white54,
                                          ),
                                          onPressed: () {
                                            Navigator.of(sheetContext).pop();
                                            VerseCard.showDetailsBottomSheet(
                                              parentContext,
                                              verse,
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.share_outlined,
                                            color: Colors.white54,
                                          ),
                                          onPressed: () =>
                                              _shareVerseText(verse),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.bookmark_remove,
                                            color: Colors.white54,
                                          ),
                                          onPressed: () {
                                            _toggleSave(verse.id);
                                            setModalState(() {});
                                          },
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.of(sheetContext).pop();
                                      VerseCard.showDetailsBottomSheet(
                                        parentContext,
                                        verse,
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showChapterProgressSheet() async {
    final chapterProgress = await _readingProgressService.loadChapterProgress();
    final chapterReadIds = await _readingProgressService.loadChapterReadIds();
    if (!mounted) {
      return;
    }

    final versesByChapter = <int, List<Verse>>{};
    for (final verse in _verses) {
      versesByChapter.putIfAbsent(verse.chapter, () => <Verse>[]).add(verse);
    }
    for (final entry in versesByChapter.entries) {
      entry.value.sort((a, b) => a.verseNumber.compareTo(b.verseNumber));
    }
    final chapters = versesByChapter.keys.toList()..sort();

    final selectedVerseId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.42,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return GlassContainer(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              opacity: 0.15,
              blur: 25,
              child: Column(
                children: [
                  const SizedBox(height: 22),
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Chapter Progress',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: chapters.length,
                      itemBuilder: (context, index) {
                        final chapter = chapters[index];
                        final chapterVerses = versesByChapter[chapter]!;
                        final total = chapterVerses.length;
                        final readIds = chapterReadIds[chapter] ?? <String>{};
                        final readRaw =
                            chapterProgress[chapter] ?? readIds.length;
                        final read = readRaw < 0
                            ? 0
                            : (readRaw > total ? total : readRaw);
                        final progress = total == 0 ? 0.0 : read / total;

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Chapter $chapter',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '$read / $total',
                                      style: GoogleFonts.inter(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 7,
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.14,
                                    ),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Color(0xFFFFD27D),
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 38,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: chapterVerses.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (context, verseIndex) {
                                      final verse = chapterVerses[verseIndex];
                                      final isRead = readIds.contains(verse.id);
                                      return InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () => Navigator.of(
                                          sheetContext,
                                        ).pop(verse.id),
                                        child: Container(
                                          width: 44,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: isRead
                                                ? const Color(
                                                    0xFFFFD27D,
                                                  ).withValues(alpha: 0.28)
                                                : Colors.white.withValues(
                                                    alpha: 0.12,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: isRead
                                                  ? const Color(
                                                      0xFFFFD27D,
                                                    ).withValues(alpha: 0.8)
                                                  : Colors.white.withValues(
                                                      alpha: 0.18,
                                                    ),
                                            ),
                                          ),
                                          child: Text(
                                            '${verse.verseNumber}',
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted || selectedVerseId == null) {
      return;
    }
    _jumpToVerseById(selectedVerseId);
  }

  Widget _buildAura(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }

  Widget _buildTopLanguageButton() {
    return GestureDetector(
      onTap: _cycleDisplayLanguage,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        borderRadius: BorderRadius.circular(18),
        opacity: 0.15,
        blur: 18,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.translate, color: Colors.white, size: 17),
            const SizedBox(width: 8),
            Text(
              _displayLanguageLabel(),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(9),
        borderRadius: BorderRadius.circular(18),
        opacity: 0.15,
        blur: 18,
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLightTheme = _themeMode == 'light';
    final loadingTopOverlay = isLightTheme
        ? const Color(0x66000000)
        : const Color(0xAA000000);
    final loadingBottomOverlay = isLightTheme
        ? const Color(0x88101824)
        : const Color(0xCC101824);
    final feedTopOverlay = isLightTheme
        ? const Color(0x50000000)
        : const Color(0x66000000);
    final feedBottomOverlay = isLightTheme
        ? const Color(0x18000000)
        : const Color(0x22000000);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image(
                image: AssetImage(_activeBackgroundImage),
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      loadingTopOverlay,
                      loadingBottomOverlay,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Center(
              child: Text(
                'Loading verses...',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_verses.isEmpty) {
      return const Scaffold(body: Center(child: Text('No verses found.')));
    }

    final currentBgColor = _hexToColor(
      _verses[_currentIndex].backgroundHexColor,
    );

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: RepaintBoundary(
        key: _globalKey,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity.abs() < 280) {
              return;
            }
            _openCurrentVerseDetails();
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: Image(
                  image: AssetImage(_activeBackgroundImage),
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [feedTopOverlay, feedBottomOverlay],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      currentBgColor.withValues(alpha: 0.18),
                      currentBgColor.withValues(alpha: 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(
                top: -120,
                right: -90,
                child: _buildAura(currentBgColor.withValues(alpha: 0.28), 300),
              ),
              Positioned(
                bottom: -140,
                left: -100,
                child: _buildAura(
                  const Color(0xFFFFD27D).withValues(alpha: 0.22),
                  330,
                ),
              ),
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: _verses.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  _persistCurrentIndex(index);
                  _recordVerseInHistory(_verses[index].id);
                  _recordChapterProgress(_verses[index]);
                },
                itemBuilder: (context, index) {
                  final verse = _verses[index];
                  return VerseCard(
                    verse: verse,
                    displayLanguage: _displayLanguage,
                    isSaved: _savedVerseIds.contains(verse.id),
                    onSave: () => _toggleSave(verse.id),
                    onShare: _shareCurrentScreen,
                    hideUI: _hideUI,
                    showGestureHint: index == 0,
                  );
                },
              ),
              if (!_hideUI)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16,
                  right: 16,
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    opacity: 0.12,
                    blur: 22,
                    child: Row(
                      children: [
                        _buildTopLanguageButton(),
                        const Spacer(),
                        _buildTopIconButton(
                          icon: Icons.menu_book_outlined,
                          onTap: _showChapterPickerSheet,
                        ),
                        const SizedBox(width: 8),
                        _buildTopIconButton(
                          icon: Icons.settings_outlined,
                          onTap: _openSettingsPage,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerseSearchSheet extends StatefulWidget {
  const _VerseSearchSheet({
    required this.verses,
    required this.matchesSearchQuery,
    required this.initialChildSize,
    required this.trailingIcon,
    this.title,
    this.subtitle,
    this.previewTextBuilder,
  });

  final List<Verse> verses;
  final bool Function(Verse verse, String query) matchesSearchQuery;
  final double initialChildSize;
  final String? title;
  final String? subtitle;
  final String Function(Verse verse)? previewTextBuilder;
  final Icon trailingIcon;

  @override
  State<_VerseSearchSheet> createState() => _VerseSearchSheetState();
}

class _VerseSearchSheetState extends State<_VerseSearchSheet> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  late final List<int> _chapters;
  int? _selectedChapter;
  int? _selectedVerseNumber;

  @override
  void initState() {
    super.initState();
    _chapters = widget.verses.map((verse) => verse.chapter).toSet().toList()
      ..sort();
    if (_chapters.isNotEmpty) {
      _selectedChapter = _chapters.first;
      final verseNumbers = _verseNumbersForChapter(_selectedChapter!);
      if (verseNumbers.isNotEmpty) {
        _selectedVerseNumber = verseNumbers.first;
      }
    }
  }

  List<Verse> get _searchResults {
    if (_query.isEmpty) {
      return const <Verse>[];
    }

    return widget.verses
        .where((verse) => widget.matchesSearchQuery(verse, _query))
        .take(60)
        .toList();
  }

  List<int> _verseNumbersForChapter(int chapter) {
    return widget.verses
        .where((verse) => verse.chapter == chapter)
        .map((verse) => verse.verseNumber)
        .toSet()
        .toList()
      ..sort();
  }

  Verse? get _selectedVerse {
    final chapter = _selectedChapter;
    final verseNumber = _selectedVerseNumber;
    if (chapter == null || verseNumber == null) {
      return null;
    }

    for (final verse in widget.verses) {
      if (verse.chapter == chapter && verse.verseNumber == verseNumber) {
        return verse;
      }
    }
    return null;
  }

  Map<int, List<Verse>> _groupByChapter(List<Verse> verses) {
    final grouped = <int, List<Verse>>{};
    for (final verse in verses) {
      grouped.putIfAbsent(verse.chapter, () => <Verse>[]).add(verse);
    }
    final sortedKeys = grouped.keys.toList()..sort();
    return <int, List<Verse>>{
      for (final chapter in sortedKeys) chapter: grouped[chapter]!,
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateQuery(String value) {
    if (!mounted) {
      return;
    }
    setState(() {
      _query = value.trim();
    });
  }

  void _onChapterChanged(int? chapter) {
    if (chapter == null || !mounted) {
      return;
    }
    final verseNumbers = _verseNumbersForChapter(chapter);
    setState(() {
      _selectedChapter = chapter;
      _selectedVerseNumber = verseNumbers.isEmpty ? null : verseNumbers.first;
    });
  }

  void _onVerseChanged(int? verseNumber) {
    if (verseNumber == null || !mounted) {
      return;
    }
    setState(() {
      _selectedVerseNumber = verseNumber;
    });
  }

  Widget _buildBrowseSection(ScrollController scrollController) {
    final chapter = _selectedChapter;
    final verseNumbers = chapter == null
        ? const <int>[]
        : _verseNumbersForChapter(chapter);
    final selectedVerse = _selectedVerse;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Browse by Chapter & Verse',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pick chapter and verse directly',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: ValueKey<int?>(chapter),
                      initialValue: chapter,
                      decoration: InputDecoration(
                        labelText: 'Chapter',
                        labelStyle: GoogleFonts.inter(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      dropdownColor: const Color(0xFF1C1C1E),
                      style: GoogleFonts.inter(color: Colors.white),
                      iconEnabledColor: Colors.white70,
                      items: _chapters
                          .map(
                            (value) => DropdownMenuItem<int>(
                              value: value,
                              child: Text(
                                'Chapter $value',
                                style: GoogleFonts.inter(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _onChapterChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: ValueKey<int?>(_selectedVerseNumber),
                      initialValue: verseNumbers.contains(_selectedVerseNumber)
                          ? _selectedVerseNumber
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Verse',
                        labelStyle: GoogleFonts.inter(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      dropdownColor: const Color(0xFF1C1C1E),
                      style: GoogleFonts.inter(color: Colors.white),
                      iconEnabledColor: Colors.white70,
                      items: verseNumbers
                          .map(
                            (value) => DropdownMenuItem<int>(
                              value: value,
                              child: Text(
                                'V$value',
                                style: GoogleFonts.inter(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _onVerseChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedVerse == null
                      ? null
                      : () {
                          FocusScope.of(context).unfocus();
                          Navigator.of(context).pop(selectedVerse.id);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    selectedVerse == null
                        ? 'Select a verse'
                        : 'Open Chapter ${selectedVerse.chapter}, Verse ${selectedVerse.verseNumber}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Or type in search above',
          style: GoogleFonts.inter(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGroupedResults(
    ScrollController scrollController,
    List<Verse> results,
  ) {
    final grouped = _groupByChapter(results);
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      children: [
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
            child: Text(
              'Chapter ${entry.key}',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
          for (final verse in entry.value)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 6,
              ),
              title: Text(
                'Verse ${verse.verseNumber}',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                widget.previewTextBuilder?.call(verse) ??
                    verse.translationEnglish,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(color: Colors.white70),
              ),
              trailing: widget.trailingIcon,
              onTap: () {
                FocusScope.of(context).unfocus();
                Navigator.of(context).pop(verse.id);
              },
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _searchResults;
    return DraggableScrollableSheet(
      initialChildSize: widget.initialChildSize,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return GlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          opacity: 0.15,
          blur: 25,
          child: Column(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (widget.title != null) ...[
                const SizedBox(height: 20),
                Text(
                  widget.title!,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ] else
                const SizedBox(height: 20),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  widget.subtitle!,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                ),
              ],
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(color: Colors.white),
                  onChanged: _updateQuery,
                  decoration: InputDecoration(
                    hintText: 'Search chapter, verse, Sanskrit, or English',
                    hintStyle: GoogleFonts.inter(color: Colors.white70),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _updateQuery('');
                            },
                          ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _query.isEmpty
                    ? _buildBrowseSection(scrollController)
                    : results.isEmpty
                    ? Center(
                        child: Text(
                          'No verses found',
                          style: GoogleFonts.inter(color: Colors.white70),
                        ),
                      )
                    : _buildGroupedResults(scrollController, results),
              ),
            ],
          ),
        );
      },
    );
  }
}
