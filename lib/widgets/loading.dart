import 'package:flutter/material.dart';

class LoadingOverlay {
  static OverlayEntry? _entry;

  static void show(BuildContext context) {
    if (_entry != null) return; // prevent duplicate

    _entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // grey background
          Container(color: Colors.black.withOpacity(0.4)),

          // spinner
          const Center(child: CircularProgressIndicator()),
        ],
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }
}
