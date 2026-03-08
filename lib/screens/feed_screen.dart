import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
  const FeedScreen({
    super.key,
    this.initialVerseId,
    this.persistReadingState = true,
    this.enableWidgetLaunchHandling = true,
    this.entryContextLabel,
  });

  final String? initialVerseId;
  final bool persistReadingState;
  final bool enableWidgetLaunchHandling;
  final String? entryContextLabel;

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
  static const String _darkBackgroundImage = 'assets/images/dark.jpeg';
  static const String _lightBackgroundImage = 'assets/images/light.jpeg';
  static const List<String> _darkBackgroundCandidates = <String>[
    'assets/images/dark.jpeg',
    'assets/images/dark.jpg',
    'assets/images/dark.png',
    'assets/images/dark.webp',
  ];
  static const List<String> _lightBackgroundCandidates = <String>[
    'assets/images/light.jpeg',
    'assets/images/light.jpg',
    'assets/images/light.png',
    'assets/images/light.webp',
  ];

  final PageController _pageController = PageController();
  final GlobalKey _globalKey = GlobalKey();
  final WidgetService _widgetService = WidgetService();
  final VerseRepository _verseRepository = const VerseRepository();
  final ReadingProgressService _readingProgressService =
      ReadingProgressService();
  final ValueNotifier<int> _currentIndexNotifier = ValueNotifier<int>(0);

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
  bool _didPrecacheBackgrounds = false;

  @override
  void initState() {
    super.initState();
    if (widget.enableWidgetLaunchHandling) {
      _widgetService.setLaunchActionHandler(_handleWidgetLaunchAction);
    }
    _initializeScreen();
  }

  @override
  void dispose() {
    if (widget.enableWidgetLaunchHandling) {
      _widgetService.clearLaunchActionHandler();
    }
    _currentIndexNotifier.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheBackgrounds) {
      return;
    }

    _didPrecacheBackgrounds = true;
    precacheImage(const AssetImage(_darkBackgroundImage), context);
    precacheImage(const AssetImage(_lightBackgroundImage), context);
  }

  Future<void> _initializeScreen() async {
    await _loadPersistedState();
    await _loadVerses();
    await _loadNotificationState();
    await _widgetService.setLanguage(_widgetLanguage);
    await _widgetService.setMode(_widgetMode);
    await _widgetService.setTheme(_themeMode);
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
    final selectedBackground = await _backgroundForTheme(normalizedThemeMode);

    if (!mounted) {
      return;
    }

    _currentIndexNotifier.value = prefs.getInt(_lastReadIndexKey) ?? 0;
    setState(() {
      _savedVerseIds = (prefs.getStringList(_savedVersesKey) ?? <String>[])
          .toSet();
      _recentVerseIds = prefs.getStringList(_recentVerseIdsKey) ?? <String>[];
      _currentIndex = _currentIndexNotifier.value;
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
      await _showWidgetVersePicker();
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

      _currentIndexNotifier.value = safeIndex;
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

        if (widget.persistReadingState) {
          _recordVerseInHistory(loadedVerses[safeIndex].id);
          _persistCurrentIndex(safeIndex);
          _recordChapterProgress(loadedVerses[safeIndex]);
        }
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

  Future<String> _resolveExistingAsset(
    List<String> candidates, {
    required String fallback,
  }) async {
    for (final candidate in candidates) {
      try {
        await rootBundle.load(candidate);
        return candidate;
      } catch (_) {
        // Ignore missing candidates and continue to the next supported format.
      }
    }
    return fallback;
  }

  Future<String> _backgroundForTheme(String mode) async {
    return _normalizeThemeMode(mode) == 'light'
        ? _resolveExistingAsset(
            _lightBackgroundCandidates,
            fallback: _lightBackgroundImage,
          )
        : _resolveExistingAsset(
            _darkBackgroundCandidates,
            fallback: _darkBackgroundImage,
          );
  }

  Widget _buildBackgroundImage() {
    return Image.asset(
      _activeBackgroundImage,
      key: ValueKey<String>(_activeBackgroundImage),
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        final fallbackAsset = _themeMode == 'light'
            ? _darkBackgroundImage
            : _lightBackgroundImage;

        if (_activeBackgroundImage == fallbackAsset) {
          return Container(color: Colors.black);
        }

        return Image.asset(
          fallbackAsset,
          key: ValueKey<String>(fallbackAsset),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.low,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            return Container(color: Colors.black);
          },
        );
      },
    );
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
          text: '${verse.referenceLabel} - Bhagavad Gita',
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
              ? 'Pinned ${verse.referenceLabel} to widget'
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
    final selectedBackground = await _backgroundForTheme(normalized);
    if (!mounted) {
      return;
    }
    setState(() {
      _themeMode = normalized;
      _activeBackgroundImage = selectedBackground;
    });
    await _persistThemeMode(normalized);
    await _widgetService.setTheme(normalized);
  }

  Widget _buildDynamicVerseAccent() {
    return ValueListenableBuilder<int>(
      valueListenable: _currentIndexNotifier,
      builder: (context, activeIndex, child) {
        if (_verses.isEmpty) {
          return const SizedBox.shrink();
        }

        final safeIndex = activeIndex.clamp(0, _verses.length - 1);
        final currentBgColor = _hexToColor(
          _verses[safeIndex].backgroundHexColor,
        );

        return IgnorePointer(
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
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
            ],
          ),
        );
      },
    );
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
          text: '${verse.referenceLabel}\n\n$verseText\n\n- Bhagavad Gita',
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
    VerseCard.showDetailsBottomSheet(
      context,
      _verses[_currentIndex],
      isLightTheme: _themeMode == 'light',
    );
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
      entry.value.sort(Verse.compareByReadingOrder);
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
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = constraints.maxWidth < 360
                                ? 4
                                : 5;
                            return GridView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                    childAspectRatio: crossAxisCount == 4
                                        ? 1.9
                                        : 1.6,
                                  ),
                              itemCount: chapterVerses.length,
                              itemBuilder: (context, index) {
                                final verse = chapterVerses[index];
                                final isCurrent = verse.id == currentVerseId;
                                return InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () =>
                                      Navigator.of(context).pop(verse.id),
                                  child: Container(
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isCurrent
                                          ? const Color(
                                              0xFFFFD27D,
                                            ).withValues(alpha: 0.26)
                                          : Colors.white.withValues(
                                              alpha: 0.12,
                                            ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isCurrent
                                            ? const Color(
                                                0xFFFFD27D,
                                              ).withValues(alpha: 0.85)
                                            : Colors.white.withValues(
                                                alpha: 0.18,
                                              ),
                                      ),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        verse.displayVerseLabel,
                                        maxLines: 1,
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
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

  Future<void> _showWidgetVersePicker() async {
    if (_verses.isEmpty) {
      return;
    }

    final versesByChapter = <int, List<Verse>>{};
    for (final verse in _verses) {
      versesByChapter.putIfAbsent(verse.chapter, () => <Verse>[]).add(verse);
    }
    for (final entry in versesByChapter.entries) {
      entry.value.sort(Verse.compareByReadingOrder);
    }

    final chapters = versesByChapter.keys.toList()..sort();
    if (chapters.isEmpty) {
      return;
    }

    final currentVerse = _verses[_currentIndex];
    var selectedChapter = chapters.contains(currentVerse.chapter)
        ? currentVerse.chapter
        : chapters.first;
    var chapterVerses = versesByChapter[selectedChapter] ?? const <Verse>[];
    var selectedVerseId =
        chapterVerses.any((verse) => verse.id == currentVerse.id)
        ? currentVerse.id
        : (chapterVerses.isNotEmpty ? chapterVerses.first.id : '');

    final selectedId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.68,
          maxChildSize: 0.96,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                chapterVerses =
                    versesByChapter[selectedChapter] ?? const <Verse>[];
                if (chapterVerses.isEmpty) {
                  return GlassContainer(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    opacity: 0.16,
                    blur: 24,
                    child: Center(
                      child: Text(
                        'No verses available for this chapter.',
                        style: GoogleFonts.inter(color: Colors.white70),
                      ),
                    ),
                  );
                } else if (!chapterVerses.any((v) => v.id == selectedVerseId)) {
                  selectedVerseId = chapterVerses.first.id;
                }

                final selectedVerse = chapterVerses.firstWhere(
                  (v) => v.id == selectedVerseId,
                  orElse: () => chapterVerses.first,
                );

                return GlassContainer(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  opacity: 0.16,
                  blur: 24,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    children: [
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
                      const SizedBox(height: 16),
                      Text(
                        'Choose Fixed Widget Verse',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pick a chapter, then tap the exact verse you want pinned.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Language: ${_languageDisplayName(_widgetLanguage)}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Chapters',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: chapters.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final chapter = chapters[index];
                            final isSelected = chapter == selectedChapter;
                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                setModalState(() {
                                  selectedChapter = chapter;
                                  final updated =
                                      versesByChapter[selectedChapter] ??
                                      const <Verse>[];
                                  selectedVerseId = updated.isEmpty
                                      ? ''
                                      : updated.first.id;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(
                                          0xFFFFD27D,
                                        ).withValues(alpha: 0.26)
                                      : Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(
                                            0xFFFFD27D,
                                          ).withValues(alpha: 0.85)
                                        : Colors.white.withValues(alpha: 0.14),
                                  ),
                                ),
                                child: Text(
                                  'Ch $chapter',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Verses',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: chapterVerses.map((verse) {
                            final isSelected = verse.id == selectedVerseId;
                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setModalState(() {
                                  selectedVerseId = verse.id;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                constraints: const BoxConstraints(minWidth: 60),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.14),
                                  ),
                                ),
                                child: Text(
                                  verse.displayVerseLabel,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: isSelected
                                        ? Colors.black87
                                        : Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    selectedVerse.referenceLabel,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _textForLanguage(selectedVerse, _widgetLanguage),
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: selectedVerseId.isEmpty
                              ? null
                              : () =>
                                    Navigator.of(context).pop(selectedVerseId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.widgets_outlined),
                          label: Text(
                            'Pin to widget',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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

    if (!mounted || selectedId == null || selectedId.isEmpty) {
      return;
    }

    final selectedVerse = _verses.where((verse) => verse.id == selectedId);
    if (selectedVerse.isEmpty) {
      return;
    }

    if (_widgetMode != 'fixed') {
      await _setWidgetMode('fixed');
    }
    await _pinVerseToWidget(selectedVerse.first);
  }

  Future<void> _openSettingsPage() async {
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, animation, secondaryAnimation) => SettingsScreen(
          notificationsEnabled: _notificationsEnabled,
          widgetLanguage: _widgetLanguage,
          widgetMode: _widgetMode,
          themeMode: _themeMode,
          onNotificationsChanged: _setNotifications,
          onWidgetLanguageChanged: _setWidgetLanguage,
          onWidgetModeChanged: _setWidgetMode,
          onThemeModeChanged: _setThemeMode,
          onOpenBookmarks: () => _showSavedVerses(context),
          onOpenChapterProgress: _showChapterProgressSheet,
          onPickFixedWidgetVerse: _showWidgetVersePicker,
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
  }

  Future<void> _showSavedVerses(BuildContext parentContext) async {
    await showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
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
                                      verse.referenceLabel,
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
                                              isLightTheme:
                                                  _themeMode == 'light',
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
                                        isLightTheme: _themeMode == 'light',
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
    final chapterReadIds = await _readingProgressService.loadChapterReadIds();
    if (!mounted) {
      return;
    }

    final versesByChapter = <int, List<Verse>>{};
    for (final verse in _verses) {
      if (!verse.countsTowardProgress) {
        continue;
      }
      versesByChapter.putIfAbsent(verse.chapter, () => <Verse>[]).add(verse);
    }
    for (final entry in versesByChapter.entries) {
      entry.value.sort(Verse.compareByReadingOrder);
    }
    final chapters = versesByChapter.keys.toList()..sort();

    final selectedVerseId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
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
                        final read = chapterVerses
                            .where((verse) => readIds.contains(verse.id))
                            .length;
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
                                          constraints: const BoxConstraints(
                                            minWidth: 44,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
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
                                            verse.verseLabel,
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
        opacity: 0.18,
        blur: 0,
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
        opacity: 0.18,
        blur: 0,
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildNotificationPreviewBadge() {
    final label = widget.entryContextLabel ?? 'Notification Preview';
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(18),
      opacity: 0.18,
      blur: 0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.notifications_active_outlined,
            color: Colors.white,
            size: 17,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
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
            Positioned.fill(child: _buildBackgroundImage()),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [loadingTopOverlay, loadingBottomOverlay],
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
              Positioned.fill(child: _buildBackgroundImage()),
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
              Positioned.fill(child: _buildDynamicVerseAccent()),
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                allowImplicitScrolling: true,
                itemCount: _verses.length,
                onPageChanged: (index) {
                  _currentIndex = index;
                  _currentIndexNotifier.value = index;
                  if (widget.persistReadingState) {
                    _persistCurrentIndex(index);
                    _recordVerseInHistory(_verses[index].id);
                    _recordChapterProgress(_verses[index]);
                  }
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
                    isLightTheme: isLightTheme,
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
                    opacity: 0.16,
                    blur: 0,
                    child: Row(
                      children: [
                        if (!widget.persistReadingState) ...[
                          _buildTopIconButton(
                            icon: Icons.arrow_back,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(width: 8),
                          _buildNotificationPreviewBadge(),
                          const SizedBox(width: 8),
                        ],
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
