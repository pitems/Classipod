import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:classipod/core/constants/app_palette.dart';
import 'package:classipod/core/constants/assets.dart';
import 'package:classipod/core/models/music_metadata.dart';
import 'package:flutter/cupertino.dart';

class AlbumReflectiveArt extends StatefulWidget {
  final String? thumbnailPath;
  final bool isOnDevice;
  final double reflectedImageHeight;
  final double? imageWidth;
  final String heroTag;
  final bool tiltedImage;
  final bool animateReflection;

  const AlbumReflectiveArt({
    super.key,
    this.thumbnailPath,
    this.isOnDevice = true,
    this.reflectedImageHeight = 50,
    this.imageWidth,
    required this.heroTag,
    this.tiltedImage = false,
    this.animateReflection = true,
  });

  static ImageProvider<Object> imageProviderFor({
    required String? thumbnailPath,
    required bool isOnDevice,
  }) {
    final path = thumbnailPath?.trim();
    if (path == null || path.isEmpty) {
      return const AssetImage(Assets.defaultAlbumCoverImage);
    }
    if (isOnDevice) {
      final file = File(path);
      if (!file.existsSync()) {
        return const AssetImage(Assets.defaultAlbumCoverImage);
      }
      return FileImage(file);
    }
    return NetworkImage(path);
  }

  static Future<void> precacheArtwork(
    BuildContext context,
    MusicMetadata metadata,
  ) async {
    final decodedImageWidth = (200 * MediaQuery.devicePixelRatioOf(context))
        .round();
    final provider = ResizeImage(
      imageProviderFor(
        thumbnailPath: metadata.thumbnailPath,
        isOnDevice: metadata.isOnDevice,
      ),
      width: decodedImageWidth,
    );
    try {
      await precacheImage(
        provider,
        context,
      ).timeout(const Duration(seconds: 3));
    } catch (_) {
      // The player can still render its fallback artwork if preloading fails.
    }
  }

  @override
  State<AlbumReflectiveArt> createState() => _AlbumReflectiveArtState();
}

class _AlbumReflectiveArtState extends State<AlbumReflectiveArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    unawaited(_controller.forward());
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _albumImageProvider();
    // Album artwork can be much larger than the 200px player surface. Decode
    // it at display size so the first Now Playing frame does not stall while
    // Flutter uploads a full-resolution cover to the GPU.
    final decodedImageWidth =
        ((widget.imageWidth ?? 200) * MediaQuery.devicePixelRatioOf(context))
            .round();
    late final Matrix4 transform;
    if (widget.tiltedImage) {
      transform = Matrix4.identity()
        ..setEntry(3, 2, 0.003)
        ..rotateY(-0.12);
    } else {
      transform = Matrix4.identity();
    }

    final isDarkTheme =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    final overlayTopColor = isDarkTheme
        ? AppPalette.darkReflectionOverlayColor1
        : const Color(0x66FFFFFF);
    final overlayBottomColor = isDarkTheme
        ? AppPalette.darkReflectionOverlayColor2
        : const Color(0xFFFFFFFF);
    final overlayBorderColor = isDarkTheme
        ? CupertinoColors.black
        : CupertinoColors.white;

    return Hero(
      tag: widget.heroTag,
      flightShuttleBuilder:
          (
            flightContext,
            animation,
            flightDirection,
            fromHeroContext,
            toHeroContext,
          ) {
            late final Widget sourceWidget;
            late final Widget destinationWidget;
            switch (flightDirection) {
              case HeroFlightDirection.push:
                sourceWidget = fromHeroContext.widget;
                destinationWidget = toHeroContext.widget;
              case HeroFlightDirection.pop:
                sourceWidget = toHeroContext.widget;
                destinationWidget = fromHeroContext.widget;
            }
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                if (animation.value < 0.01 || animation.value > 0.999) {
                  unawaited(_controller.forward());
                }
                final progress = Curves.easeInOutCubic.transform(
                  animation.value,
                );
                final sourceProgress = (progress * 2).clamp(0.0, 1.0);
                final destinationProgress = ((progress - 0.5) * 2).clamp(
                  0.0,
                  1.0,
                );
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(sourceProgress * (pi / 2)),
                      alignment: Alignment.center,
                      child: child,
                    ),
                    Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY((1 - destinationProgress) * (pi / 2)),
                      alignment: Alignment.center,
                      child: destinationWidget,
                    ),
                  ],
                );
              },
              child: sourceWidget,
            );
          },
      child: Transform(
        transform: transform,
        child: Column(
          children: [
            Flexible(
              child: Image(
                image: ResizeImage(imageProvider, width: decodedImageWidth),
                errorBuilder: (_, _, _) => Image.asset(
                  Assets.defaultAlbumCoverImage,
                  height: widget.imageWidth,
                  width: widget.imageWidth ?? double.infinity,
                  fit: (widget.imageWidth == null)
                      ? BoxFit.fitWidth
                      : BoxFit.scaleDown,
                ),
                height: widget.imageWidth,
                width: widget.imageWidth ?? double.infinity,
                fit: (widget.imageWidth == null)
                    ? BoxFit.fitWidth
                    : BoxFit.scaleDown,
              ),
            ),
            widget.animateReflection
                ? FadeTransition(
                    opacity: _animation,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        Transform.flip(
                          flipY: true,
                          child: Image(
                            image: ResizeImage(
                              imageProvider,
                              width: decodedImageWidth,
                            ),
                            height: widget.reflectedImageHeight,
                            width: widget.imageWidth != null
                                ? (widget.imageWidth! -
                                      widget.reflectedImageHeight)
                                : double.infinity,
                            alignment: Alignment.bottomCenter,
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                        _reflectionOverlay(
                          overlayTopColor,
                          overlayBottomColor,
                          overlayBorderColor,
                        ),
                      ],
                    ),
                  )
                : Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      Transform.flip(
                        flipY: true,
                        child: Image(
                          image: ResizeImage(
                            imageProvider,
                            width: decodedImageWidth,
                          ),
                          errorBuilder: (_, _, _) => Image.asset(
                            Assets.defaultAlbumCoverImage,
                            height: widget.reflectedImageHeight,
                            width: widget.imageWidth != null
                                ? (widget.imageWidth! -
                                      widget.reflectedImageHeight)
                                : double.infinity,
                            alignment: Alignment.bottomCenter,
                            fit: BoxFit.fitWidth,
                          ),
                          height: widget.reflectedImageHeight,
                          width: widget.imageWidth != null
                              ? (widget.imageWidth! -
                                    widget.reflectedImageHeight)
                              : double.infinity,
                          alignment: Alignment.bottomCenter,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                      SizedBox(
                        height: widget.reflectedImageHeight,
                        width: widget.imageWidth != null
                            ? (widget.imageWidth! - widget.reflectedImageHeight)
                            : double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: overlayBorderColor,
                                width: 0,
                              ),
                              right: BorderSide(
                                color: overlayBorderColor,
                                width: 0,
                              ),
                              bottom: BorderSide(
                                color: overlayBorderColor,
                                width: 0,
                              ),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [overlayTopColor, overlayBottomColor],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _reflectionOverlay(
    Color overlayTopColor,
    Color overlayBottomColor,
    Color overlayBorderColor,
  ) {
    return SizedBox(
      height: widget.reflectedImageHeight,
      width: widget.imageWidth != null
          ? (widget.imageWidth! - widget.reflectedImageHeight)
          : double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: overlayBorderColor, width: 0),
            right: BorderSide(color: overlayBorderColor, width: 0),
            bottom: BorderSide(color: overlayBorderColor, width: 0),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [overlayTopColor, overlayBottomColor],
          ),
        ),
      ),
    );
  }

  ImageProvider<Object> _albumImageProvider() {
    return AlbumReflectiveArt.imageProviderFor(
      thumbnailPath: widget.thumbnailPath,
      isOnDevice: widget.isOnDevice,
    );
  }
}
