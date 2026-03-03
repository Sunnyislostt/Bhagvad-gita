import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/verse.dart';
import 'glass_container.dart';

class VerseCard extends StatelessWidget {
  final Verse verse;
  final bool isEnglish;
  final bool isSaved;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final bool hideUI;

  const VerseCard({
    super.key,
    required this.verse,
    this.isEnglish = false,
    this.isSaved = false,
    required this.onSave,
    required this.onShare,
    this.hideUI = false,
  });

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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
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
                  // Chapter & Verse header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Chapter ${verse.chapter}, Verse ${verse.verseNumber}",
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

                  // Original Sanskrit
                  _sectionLabel("Original Sanskrit"),
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

                  // Transliteration
                  _sectionLabel("Transliteration"),
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

                  // English Translation
                  _sectionLabel("English Translation"),
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
                  const SizedBox(height: 8),
                  _divider(),
                  const SizedBox(height: 8),

                  // Deep Dive
                  _sectionLabel("Deep Dive"),
                  const SizedBox(height: 10),
                  Text(
                    verse.deepDiveText,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white70,
                      height: 1.7,
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
    return Container(
      height: 1,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: MediaQuery.of(context).padding.top + 80,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        children: [
          // Main Verse Content — scrollable for long verses
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: GlassContainer(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Chapter ${verse.chapter} • Verse ${verse.verseNumber}",
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        isEnglish ? verse.translationEnglish : verse.originalScript,
                        textAlign: TextAlign.center,
                        style: isEnglish
                            ? GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 22,
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                              )
                            : GoogleFonts.martel(
                                color: Colors.white,
                                fontSize: 28,
                                height: 1.8,
                                fontWeight: FontWeight.w700,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom action buttons — always visible, never overlapped
          if (!hideUI)
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.info_outline,
                    label: "Meaning",
                    onTap: () => showDetailsBottomSheet(context, verse),
                  ),
                  _ActionButton(
                    icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                    label: "Save",
                    onTap: onSave,
                  ),
                  _ActionButton(
                    icon: Icons.share_outlined,
                    label: "Share",
                    onTap: onShare,
                  ),
                ],
              ),
            ),
        ],
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassContainer(
            width: 50,
            height: 50,
            borderRadius: BorderRadius.circular(25),
            padding: EdgeInsets.zero,
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
