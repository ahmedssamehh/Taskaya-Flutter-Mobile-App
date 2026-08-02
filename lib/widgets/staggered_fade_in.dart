import 'dart:async';

import 'package:flutter/material.dart';

import '../core/motion/app_motion.dart';

/// Fades and slides its child in on first build, delayed by [index] * 40ms
/// (capped so a long list doesn't keep animating for seconds).
class StaggeredFadeIn extends StatefulWidget {
  const StaggeredFadeIn({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  static const int _maxStaggered = 8;

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn> {
  bool _visible = false;
  bool _scheduled = false;
  Timer? _timer;

  // Reading MediaQuery (via AppMotion.reduced) is only legal once
  // dependencies are available, so the entrance is scheduled here rather
  // than in initState. Guarded so it runs only on the first call.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;

    if (AppMotion.reduced(context)) {
      _visible = true;
      return;
    }

    final delayIndex = widget.index.clamp(0, StaggeredFadeIn._maxStaggered);
    _timer = Timer(Duration(milliseconds: 40 * delayIndex), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.06),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
