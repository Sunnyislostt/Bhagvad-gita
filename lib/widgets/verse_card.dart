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

  void _showVerseDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Transparent to show glass effect
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
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
                  Text(
                    "Chapter ${verse.chapter}, Verse ${verse.verseNumber}",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Transliteration",
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    verse.transliteration,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "English Translation",
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    verse.translationEnglish,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Deep Dive",
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white54),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    verse.deepDiveText,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white70,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Stack(
        children: [
          // Main Verse Content
          Center(
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

          // Bottom action buttons
          if (!hideUI)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.info_outline,
                    label: "Meaning",
                    onTap: () => _showVerseDetails(context),
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
