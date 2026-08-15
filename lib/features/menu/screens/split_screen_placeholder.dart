import 'dart:async';

import 'package:classipod/features/menu/widgets/animated_album_art_scroller.dart';
import 'package:classipod/features/settings/controller/settings_preferences_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplitScreenViewController {
  _SplitScreenPlaceholderState? _state;

  Future<void>? openSplitView() => _state?._forwardAnimation();

  Future<void>? closeSplitView() => _state?._backwardAnimation();

  bool get isScreenVisible => _state?._isScreenVisible ?? true;
}

class SplitScreenPlaceholder extends ConsumerStatefulWidget {
  final Widget child;
  final SplitScreenViewController splitScreenController;

  const SplitScreenPlaceholder({
    super.key,
    required this.child,
    required this.splitScreenController,
  });

  @override
  ConsumerState createState() => _SplitScreenPlaceholderState();
}

class _SplitScreenPlaceholderState extends ConsumerState<SplitScreenPlaceholder>
    with SingleTickerProviderStateMixin {
  bool _isScreenVisible = false;
  late final AnimationController _animationController;
  late final Animation<Offset> _leftSlideAnimation;

  @override
  void initState() {
    widget.splitScreenController._state = this;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _leftSlideAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(_animationController);
    unawaited(_forwardAnimation());
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _forwardAnimation() async {
    await _animationController.forward();
    if (mounted) {
      setState(() => _isScreenVisible = true);
    }
  }

  Future<void> _backwardAnimation() async {
    await _animationController.reverse();
    if (mounted) {
      setState(() => _isScreenVisible = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final splitScreenEnabled = ref.watch(
      settingsPreferencesControllerProvider.select(
        (settings) => settings.splitScreenEnabled,
      ),
    );

    return CupertinoPageScaffold(
      child: splitScreenEnabled
          ? Row(
              children: [
                Expanded(
                  child: SlideTransition(
                    position: _leftSlideAnimation,
                    child: widget.child,
                  ),
                ),
                const Expanded(child: AnimatedAlbumArtScroller()),
              ],
            )
          : widget.child,
    );
  }
}
