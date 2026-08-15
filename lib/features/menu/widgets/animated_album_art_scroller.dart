import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:classipod/core/constants/assets.dart';
import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/widgets/empty_state_widget.dart';
import 'package:classipod/features/menu/models/split_screen_type.dart';
import 'package:classipod/features/music/album/providers/album_details_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnimatedAlbumArtScroller extends ConsumerStatefulWidget {
  const AnimatedAlbumArtScroller({super.key});

  @override
  ConsumerState createState() => _AnimatedAlbumArtScrollerState();
}

class _AnimatedAlbumArtScrollerState
    extends ConsumerState<AnimatedAlbumArtScroller>
    with TickerProviderStateMixin {
  ImageProvider _currentAlbumArt = const AssetImage(
    Assets.defaultAlbumCoverImage,
  );
  ImageProvider? _nextAlbumArt;

  late AnimationController _currentMotionController;
  late AnimationController _nextMotionController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late Animation<Alignment> _currentAlignmentAnimation;
  late Animation<Alignment> _nextAlignmentAnimation;

  bool _isEmptyState = false;
  bool _isTransitioning = false;

  ImageProvider _chooseAlbumArt(List<dynamic> albumsWithArtwork) {
    if (albumsWithArtwork.isEmpty) {
      return const AssetImage(Assets.defaultAlbumCoverImage);
    }

    final randomAlbum = albumsWithArtwork.elementAt(
      Random().nextInt(albumsWithArtwork.length),
    );
    return randomAlbum.isOnDevice()
        ? FileImage(File(randomAlbum.albumArtPath!))
        : NetworkImage(randomAlbum.albumArtPath!);
  }

  ImageProvider _getRandomAlbumArtImage() {
    final albumsWithArtwork = ref.read(albumDetailsProvider).where((album) {
      final albumArtPath = album.albumArtPath;
      if (albumArtPath == null) {
        return false;
      }
      return !album.isOnDevice() || File(albumArtPath).existsSync();
    }).toList();

    return _chooseAlbumArt(albumsWithArtwork);
  }

  void _loadInitialAlbumArt() {
    final albumDetails = ref.read(albumDetailsProvider);
    if (albumDetails.isEmpty) {
      setState(() => _isEmptyState = true);
      return;
    }

    setState(() {
      _isEmptyState = false;
      _currentAlbumArt = _getRandomAlbumArtImage();
    });
  }

  Animation<Alignment> _horizontalAnimation(AnimationController controller) {
    final bool leftToRight = Random().nextBool();
    return Tween<Alignment>(
      begin: leftToRight ? Alignment.topLeft : Alignment.topRight,
      end: leftToRight ? Alignment.topRight : Alignment.topLeft,
    ).animate(controller);
  }

  void _setCurrentDirection() {
    _currentAlignmentAnimation = _horizontalAnimation(_currentMotionController);
  }

  void _setNextDirection() {
    _nextAlignmentAnimation = _horizontalAnimation(_nextMotionController);
  }

  void _watchCurrentMotion() {
    if (_currentMotionController.value >= 0.75 && !_isTransitioning) {
      _isTransitioning = true;
      unawaited(_crossfadeToNextAlbumArt());
    }
  }

  Future<void> _crossfadeToNextAlbumArt() async {
    final ImageProvider nextAlbumArt = _getRandomAlbumArtImage();
    await precacheImage(nextAlbumArt, context);
    if (!mounted) {
      return;
    }

    setState(() => _nextAlbumArt = nextAlbumArt);
    _nextMotionController.value = 0;
    _setNextDirection();
    unawaited(_nextMotionController.forward(from: 0));

    await _fadeController.animateTo(
      1,
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
    );
    if (!mounted) {
      return;
    }

    final oldCurrentController = _currentMotionController;
    _currentMotionController.removeListener(_watchCurrentMotion);

    // The incoming cover is now fully visible. Swap controller roles while
    // the outgoing controller is hidden, so no transform can jump on screen.
    _currentMotionController = _nextMotionController;
    _nextMotionController = oldCurrentController;
    _currentAlignmentAnimation = _nextAlignmentAnimation;

    setState(() {
      _currentAlbumArt = _nextAlbumArt!;
      _nextAlbumArt = null;
    });

    _nextMotionController.stop();
    _nextMotionController.value = 0;
    _setNextDirection();
    _fadeController.value = 0;
    _currentMotionController.addListener(_watchCurrentMotion);
    _isTransitioning = false;
  }

  @override
  void initState() {
    super.initState();
    _currentMotionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _nextMotionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _fadeController = AnimationController(
      vsync: this,
      value: 0,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _loadInitialAlbumArt();
    _setCurrentDirection();
    _setNextDirection();
    if (!_isEmptyState) {
      _currentMotionController.addListener(_watchCurrentMotion);
      unawaited(_currentMotionController.forward());
    }
  }

  @override
  void dispose() {
    _currentMotionController.removeListener(_watchCurrentMotion);
    _currentMotionController.dispose();
    _nextMotionController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Widget _albumArtImageWidget(ImageProvider image) {
    return Image(
      image: image,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          Assets.defaultAlbumCoverImage,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isEmptyState) {
      return EmptyStateWidget(
        emptyDescription: context.localization.noMusicFilesFound,
      );
    }

    return RepaintBoundary(
      key: const ValueKey(SplitScreenType.albumArt),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _currentMotionController,
          _nextMotionController,
          _fadeController,
        ]),
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: 1 - _fadeAnimation.value,
                child: AnimatedAlbumArt(
                  animation: _currentAlignmentAnimation,
                  child: _albumArtImageWidget(_currentAlbumArt),
                ),
              ),
              if (_nextAlbumArt != null)
                Opacity(
                  opacity: _fadeAnimation.value,
                  child: AnimatedAlbumArt(
                    animation: _nextAlignmentAnimation,
                    child: _albumArtImageWidget(_nextAlbumArt!),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class AnimatedAlbumArt extends AnimatedWidget {
  final Widget child;

  const AnimatedAlbumArt({
    super.key,
    required Animation<Alignment> animation,
    required this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<Alignment>;
    return SizedBox(
      width: double.infinity,
      child: AspectRatio(
        aspectRatio: 1 / 2,
        child: ClipRect(
          child: Transform.scale(
            scale: 1.5,
            alignment: animation.value,
            child: SizedBox.expand(child: child),
          ),
        ),
      ),
    );
  }
}
