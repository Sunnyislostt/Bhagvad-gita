import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/verse.dart';
import 'glass_container.dart';

class VerseCard extends StatelessWidget {
  static const double _scrollFallbackSentinel = -1;
  static final Map<String, double> _fontSizeCache = <String, double>{};

  final Verse verse;
  final String displayLanguage;
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final bool hideUI;
  final bool showGestureHint;
  final bool isLightTheme;

  const VerseCard({
    super.key,
    required this.verse,
    this.displayLanguage = 'sanskrit',
    this.isSaved = false,
    required this.onSave,
    required this.onShare,
    this.hideUI = false,
    this.showGestureHint = false,
    this.isLightTheme = false,
  });

  static bool _showsReferenceHeader(Verse verse) {
    return !verse.isSummary && !verse.isRecap;
  }

  static void showDetailsBottomSheet(
    BuildContext context,
    Verse verse, {
    bool isLightTheme = false,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 220),
        reverseDuration: Duration(milliseconds: 180),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => _VerseDetailsSheet(
            verse: verse,
            scrollController: scrollController,
            isLightTheme: isLightTheme,
          ),
        );
      },
    );
  }

  static Widget _sectionLabel(
    String title, {
    Color markerColor = const Color(0x99FFFFFF),
    Color textColor = const Color(0x8AFFFFFF),
  }) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: markerColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  static Widget _divider({Color color = const Color(0x14FFFFFF)}) {
    return Container(height: 1, color: color);
  }

  static void _storeFontSizeCache(String key, double value) {
    if (_fontSizeCache.length > 4000) {
      _fontSizeCache.clear();
    }
    _fontSizeCache[key] = value;
  }

  String _textLayoutCacheKey(
    BoxConstraints constraints,
    TextScaler textScaler,
  ) {
    final width = constraints.maxWidth.round();
    final height = constraints.maxHeight.round();
    final scale = (textScaler.scale(1) * 100).round();
    return '${verse.id}|$displayLanguage|$width|$height|$scale';
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isCompactHeight = media.size.height < 700;
    final topInset = media.padding.top + (isCompactHeight ? 62 : 72);
    final bottomInset = media.padding.bottom + 8;

    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: topInset,
          bottom: bottomInset,
        ),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableHeight = constraints.maxHeight;
                  final showHint = showGestureHint && availableHeight > 420;
                  final showReferenceHeader = _showsReferenceHeader(verse);
                  final infoButtonColor = isLightTheme
                      ? const Color(0xFFFFF3DE)
                      : Colors.white;
                  final infoButtonOpacity = isLightTheme ? 0.42 : 0.18;
                  final infoIconColor = isLightTheme
                      ? const Color(0xFF3D2E1F)
                      : Colors.white;

                  return SizedBox(
                    width: double.infinity,
                    height: availableHeight,
                    child: GlassContainer(
                      opacity: 0.0,
                      blur: 0.0,
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Spacer(),
                              GestureDetector(
                                onTap: () =>
                                    showDetailsBottomSheet(
                                      context,
                                      verse,
                                      isLightTheme: isLightTheme,
                                    ),
                                child: GlassContainer(
                                  width: 36,
                                  height: 36,
                                  borderRadius: BorderRadius.circular(18),
                                  padding: EdgeInsets.zero,
                                  blur: 0,
                                  color: infoButtonColor,
                                  opacity: infoButtonOpacity,
                                  child: Icon(
                                    Icons.info_outline,
                                    color: infoIconColor,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (showReferenceHeader) ...[
                            const SizedBox(height: 6),
                            Text(
                              verse.referenceLabel,
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          SizedBox(
                            height: showReferenceHeader
                                ? (availableHeight > 540 ? 22 : 14)
                                : 10,
                          ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, textConstraints) {
                                return _buildPrimaryTextContent(
                                  context,
                                  textConstraints,
                                );
                              },
                            ),
                          ),
                          if (showHint) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.16),
                                ),
                              ),
                              child: Text(
                                'Swipe up/down for verses - swipe left/right for details',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (!hideUI)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    _ActionButton(
                      icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                      label: 'Save',
                      onTap: onSave,
                    ),
                    _ActionButton(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      onTap: onShare,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _primaryText() {
    if (displayLanguage == 'english') {
      return verse.translationEnglish;
    }
    return verse.originalScript;
  }

  TextStyle _primaryTextStyle() {
    if (displayLanguage == 'sanskrit') {
      return GoogleFonts.martel(
        color: Colors.white,
        fontSize: 28,
        height: 1.8,
        fontWeight: FontWeight.w700,
      );
    }

    return GoogleFonts.inter(
      color: Colors.white,
      fontSize: 21,
      height: 1.6,
      fontWeight: FontWeight.w500,
    );
  }

  Widget _buildPrimaryTextContent(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final text = _primaryText();
    final baseStyle = _primaryTextStyle();
    final baseFontSize = baseStyle.fontSize ?? 20;
    final minFontSize = displayLanguage == 'sanskrit' ? 18.0 : 15.0;
    final textDirection = Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final cacheKey = _textLayoutCacheKey(constraints, textScaler);
    final cachedFontSize = _fontSizeCache[cacheKey];

    if (cachedFontSize != null) {
      if (cachedFontSize == _scrollFallbackSentinel) {
        return _buildScrollablePrimaryText(
          text,
          baseStyle.copyWith(fontSize: minFontSize),
          constraints,
        );
      }

      return Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: baseStyle.copyWith(fontSize: cachedFontSize),
        ),
      );
    }

    for (var fontSize = baseFontSize; fontSize >= minFontSize; fontSize -= 1) {
      final candidateStyle = baseStyle.copyWith(fontSize: fontSize);
      final painter = TextPainter(
        text: TextSpan(text: text, style: candidateStyle),
        textAlign: TextAlign.center,
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout(maxWidth: constraints.maxWidth);

      if (painter.height <= constraints.maxHeight) {
        _storeFontSizeCache(cacheKey, fontSize);
        return Center(
          child: Text(text, textAlign: TextAlign.center, style: candidateStyle),
        );
      }
    }

    _storeFontSizeCache(cacheKey, _scrollFallbackSentinel);
    return _buildScrollablePrimaryText(
      text,
      baseStyle.copyWith(fontSize: minFontSize),
      constraints,
    );
  }

  Widget _buildScrollablePrimaryText(
    String text,
    TextStyle fallbackStyle,
    BoxConstraints constraints,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(
          child: Text(text, textAlign: TextAlign.center, style: fallbackStyle),
        ),
      ),
    );
  }
}

class _VerseDetailsSheet extends StatelessWidget {
  final Verse verse;
  final ScrollController scrollController;
  final bool isLightTheme;

  const _VerseDetailsSheet({
    required this.verse,
    required this.scrollController,
    required this.isLightTheme,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceTop = isLightTheme
        ? const Color(0xFFF0E8DC).withValues(alpha: 0.97)
        : const Color(0xFF101A2A).withValues(alpha: 0.98);
    final surfaceBottom = isLightTheme
        ? const Color(0xFFE3D7C5).withValues(alpha: 0.96)
        : const Color(0xFF0A1220).withValues(alpha: 0.96);
    final borderColor = isLightTheme
        ? const Color(0xFFAF8A5C).withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.08);
    final handleColor = isLightTheme
        ? const Color(0xFF7A6957).withValues(alpha: 0.34)
        : Colors.white.withValues(alpha: 0.5);
    final primaryTextColor =
        isLightTheme ? const Color(0xFF241A12) : Colors.white;
    final secondaryTextColor =
        isLightTheme ? const Color(0xFF5D4A35) : Colors.white70;
    final tertiaryTextColor = isLightTheme
        ? const Color(0xFF6A5845).withValues(alpha: 0.88)
        : Colors.white.withValues(alpha: 0.85);
    final pillBackground = isLightTheme
        ? const Color(0xFFFFF3DE).withValues(alpha: 0.62)
        : Colors.white.withValues(alpha: 0.08);
    final cardBackground = isLightTheme
        ? const Color(0xFFF0E4D2).withValues(alpha: 0.52)
        : Colors.white.withValues(alpha: 0.05);
    final dividerColor = isLightTheme
        ? const Color(0xFFAF8A5C).withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.08);
    final sectionMarkerColor = isLightTheme
        ? const Color(0xFFAF8A5C).withValues(alpha: 0.60)
        : Colors.white.withValues(alpha: 0.6);
    final sectionLabelColor = isLightTheme
        ? const Color(0xFF5B4A36).withValues(alpha: 0.86)
        : Colors.white54;
    final glowColor = isLightTheme
        ? const Color(0xFFFFF3DE).withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.08);

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          gradient: LinearGradient(
            colors: [surfaceTop, surfaceBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 24,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: Stack(
            children: [
              Positioned(
                top: -90,
                right: -40,
                child: IgnorePointer(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [glowColor, glowColor.withValues(alpha: 0.0)],
                      ),
                    ),
                  ),
                ),
              ),
              ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: handleColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  if (VerseCard._showsReferenceHeader(verse)) ...[
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: pillBackground,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          verse.referenceLabel,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ] else
                    const SizedBox(height: 8),
                  VerseCard._sectionLabel(
                    'Original Sanskrit',
                    markerColor: sectionMarkerColor,
                    textColor: sectionLabelColor,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      verse.originalScript,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.martel(
                        fontSize: 20,
                        color: primaryTextColor,
                        fontWeight: FontWeight.w700,
                        height: 1.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  VerseCard._divider(color: dividerColor),
                  const SizedBox(height: 8),
                  VerseCard._sectionLabel(
                    'Transliteration',
                    markerColor: sectionMarkerColor,
                    textColor: sectionLabelColor,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    verse.transliteration,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: tertiaryTextColor,
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  VerseCard._divider(color: dividerColor),
                  const SizedBox(height: 8),
                  VerseCard._sectionLabel(
                    'Deep Dive',
                    markerColor: sectionMarkerColor,
                    textColor: sectionLabelColor,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    verse.deepDiveText,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: secondaryTextColor,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 8),
                  VerseCard._divider(color: dividerColor),
                  const SizedBox(height: 8),
                  if (verse.wordMeanings.trim().isNotEmpty) ...[
                    VerseCard._sectionLabel(
                      'Word Meanings',
                      markerColor: sectionMarkerColor,
                      textColor: sectionLabelColor,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      verse.wordMeanings,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: secondaryTextColor,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    VerseCard._divider(color: dividerColor),
                    const SizedBox(height: 8),
                  ],
                  VerseCard._sectionLabel(
                    'English Translation',
                    markerColor: sectionMarkerColor,
                    textColor: sectionLabelColor,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    verse.translationEnglish,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      color: primaryTextColor,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        borderRadius: BorderRadius.circular(28),
        opacity: 0.18,
        blur: 0,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
