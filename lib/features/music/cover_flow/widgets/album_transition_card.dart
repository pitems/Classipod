import 'package:classipod/features/music/album/models/album_model.dart';
import 'package:classipod/features/music/cover_flow/widgets/album_song_list_panel.dart';
import 'package:classipod/features/now_playing/widgets/album_reflective_art.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

class AlbumTransitionCard extends StatefulWidget {
  final AlbumModel album;
  final VoidCallback? onOpenCompleted;
  final VoidCallback? onCloseCompleted;

  const AlbumTransitionCard({
    super.key,
    required this.album,
    this.onOpenCompleted,
    this.onCloseCompleted,
  });

  @override
  State<AlbumTransitionCard> createState() => AlbumTransitionCardState();
}

class AlbumTransitionCardState extends State<AlbumTransitionCard>
    with SingleTickerProviderStateMixin {
  static const _openingDuration = Duration(milliseconds: 1000);
  static const _closingDuration = Duration(milliseconds: 1300);

  late final AnimationController _controller;
  final ValueNotifier<bool> _titleAnimationEnabled = ValueNotifier(false);
  bool _hiddenForRoute = false;

  ValueListenable<bool> get titleAnimationEnabled => _titleAnimationEnabled;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _openingDuration,
      reverseDuration: _closingDuration,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleAnimationEnabled.dispose();
    super.dispose();
  }

  Future<void> open() async {
    if (_controller.isAnimating || _controller.value == 1) {
      return;
    }
    await _controller.forward();
    widget.onOpenCompleted?.call();
  }

  Future<void> close() async {
    if (_controller.isAnimating || _controller.value == 0) {
      return;
    }
    await _controller.reverse();
    widget.onCloseCompleted?.call();
  }

  void hideForRoute() {
    if (mounted) {
      setState(() => _hiddenForRoute = true);
    }
  }

  void showForClose() {
    if (mounted) {
      setState(() => _hiddenForRoute = false);
    }
  }

  void startTitleAnimation() {
    _titleAnimationEnabled.value = true;
  }

  void resetTitleAnimation() {
    _titleAnimationEnabled.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final cover = AlbumReflectiveArt(
      imageWidth: 230,
      thumbnailPath: widget.album.albumArtPath,
      isOnDevice: widget.album.isOnDevice(),
      animateReflection: false,
      heroTag:
          '${widget.album.albumName}-${widget.album.albumArtistName}-transition',
    );
    final list = AlbumSongListPanel(
      album: widget.album,
      titleAnimationEnabled: _titleAnimationEnabled,
    );

    return Visibility(
      visible: !_hiddenForRoute,
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = _controller.value;
          final cardRotation =
              -Curves.easeInOutCubic.transform(progress) * 3.14159265359;
          final coverFade =
              1 -
              Curves.easeInOut.transform(
                ((progress - 0.40) / 0.20).clamp(0.0, 1.0),
              );
          final listFade = Curves.easeInOut.transform(
            ((progress - 0.40) / 0.20).clamp(0.0, 1.0),
          );

          return LayoutBuilder(
            builder: (context, _) {
              final targetWidth = AlbumSongListPanel.targetWidth(context);
              final targetHeight = AlbumSongListPanel.targetHeight(context);
              final widthProgress = Curves.easeInOutCubic.transform(
                ((progress - 0.50) / 0.35).clamp(0.0, 1.0),
              );
              final heightProgress = Curves.easeInOutCubic.transform(
                ((progress - 0.45) / 0.55).clamp(0.0, 1.0),
              );
              final width = 230.0 + ((targetWidth - 230.0) * widthProgress);
              final height = 230.0 + ((targetHeight - 230.0) * heightProgress);

              return OverflowBox(
                alignment: Alignment.topCenter,
                maxWidth: targetWidth,
                maxHeight: targetHeight,
                child: Transform(
                  alignment: Alignment.topCenter,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0015)
                    ..rotateY(cardRotation),
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Opacity(
                          opacity: coverFade,
                          child: SizedBox(
                            width: 230,
                            height: 230,
                            child: cover,
                          ),
                        ),
                        Opacity(
                          opacity: listFade,
                          child: Transform(
                            alignment: Alignment.topCenter,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.0015)
                              ..rotateY(3.14159265359),
                            child: SizedBox(
                              width: width,
                              height: height,
                              child: list,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
