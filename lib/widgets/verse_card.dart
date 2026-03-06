import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/verse.dart';
import 'glass_container.dart';

class VerseCard extends StatelessWidget {
  final Verse verse;
  final String displayLanguage;
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final bool hideUI;
  final bool showGestureHint;

  const VerseCard({
    super.key,
    required this.verse,
    this.displayLanguage = 'sanskrit',
    this.isSaved = false,
    required this.onSave,
    required this.onShare,
    this.hideUI = false,
    this.showGestureHint = false,
  });

  static bool _showsReferenceHeader(Verse verse) {
    return !verse.isSummary && !verse.isRecap;
  }

  static void showDetailsBottomSheet(BuildContext context, Verse verse) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return GlassContainer(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              opacity: 0.15,
              blur: 25,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24.0),
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  if (_showsReferenceHeader(verse)) ...[
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          verse.referenceLabel,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ] else
                    const SizedBox(height: 8),
                  _sectionLabel('Original Sanskrit'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      verse.originalScript,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.martel(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _divider(),
                  const SizedBox(height: 8),
                  _sectionLabel('Transliteration'),
                  const SizedBox(height: 10),
                  Text(
                    verse.transliteration,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _divider(),
                  const SizedBox(height: 8),
                  _sectionLabel('Deep Dive'),
                  const SizedBox(height: 10),
                  Text(
                    verse.deepDiveText,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white70,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _divider(),
                  const SizedBox(height: 8),
                  if (verse.wordMeanings.trim().isNotEmpty) ...[
                    _sectionLabel('Word Meanings'),
                    const SizedBox(height: 10),
                    Text(
                      verse.wordMeanings,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _divider(),
                    const SizedBox(height: 8),
                  ],
                  _sectionLabel('English Translation'),
                  const SizedBox(height: 10),
                  Text(
                    verse.translationEnglish,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _sectionLabel(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white54,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  static Widget _divider() {
    return Container(height: 1, color: Colors.white.withValues(alpha: 0.08));
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isCompactHeight = media.size.height < 700;
    final topInset = media.padding.top + (isCompactHeight ? 62 : 72);
    final bottomInset = media.padding.bottom + 8;

    return Padding(
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
                                  showDetailsBottomSheet(context, verse),
                              child: GlassContainer(
                                width: 36,
                                height: 36,
                                borderRadius: BorderRadius.circular(18),
                                padding: EdgeInsets.zero,
                                child: const Icon(
                                  Icons.info_outline,
                                  color: Colors.white,
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

    for (var fontSize = baseFontSize; fontSize >= minFontSize; fontSize -= 1) {
      final candidateStyle = baseStyle.copyWith(fontSize: fontSize);
      final painter = TextPainter(
        text: TextSpan(text: text, style: candidateStyle),
        textAlign: TextAlign.center,
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout(maxWidth: constraints.maxWidth);

      if (painter.height <= constraints.maxHeight) {
        return Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: candidateStyle,
          ),
        );
      }
    }

    final fallbackStyle = baseStyle.copyWith(fontSize: minFontSize);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: fallbackStyle,
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
        opacity: 0.15,
        blur: 18,
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
