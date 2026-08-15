import 'package:classipod/core/constants/constants.dart';
import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/features/music/album/models/album_model.dart';
import 'package:classipod/features/music/cover_flow/widgets/cover_flow_album_song_list_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

class AlbumSongListPanel extends StatelessWidget {
  static const headerHeight = 70.0;
  final AlbumModel album;
  final int selectedIndex;
  final int? currentlyPlayingOriginalIndex;
  final ScrollController? scrollController;
  final ValueChanged<int>? onSongTap;
  final ValueListenable<bool>? titleAnimationEnabled;

  const AlbumSongListPanel({
    super.key,
    required this.album,
    this.selectedIndex = 0,
    this.currentlyPlayingOriginalIndex,
    this.scrollController,
    this.onSongTap,
    this.titleAnimationEnabled,
  });

  static double targetWidth(BuildContext context) =>
      (MediaQuery.sizeOf(context).width - 20)
          .clamp(230.0, double.infinity)
          .toDouble();

  static double targetHeight(BuildContext context) =>
      ((MediaQuery.sizeOf(context).height < Constants.screenHeight
                  ? MediaQuery.sizeOf(context).height
                  : Constants.screenHeight) -
              50)
          .clamp(260.0, 360.0)
          .toDouble();

  @override
  Widget build(BuildContext context) {
    final isDarkTheme =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    final headerColors = isDarkTheme
        ? const [Color(0xFF465363), Color(0xFF303944)]
        : const [Color(0xFF91A0AF), Color(0xFF778796)];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appBackgroundColor,
        border: Border.all(color: context.appOutlineColor),
      ),
      child: Column(
        children: [
          SizedBox(
            height: headerHeight,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: headerColors,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: CupertinoColors.white.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      album.albumName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      album.albumArtistName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Flexible(
            child: CupertinoScrollbar(
              controller: scrollController,
              child: ListView.builder(
                controller: scrollController,
                itemCount: album.albumSongs.length,
                prototypeItem: CoverFlowAlbumSongListTile(
                  songName: '',
                  trackNumber: 0,
                  songDuration: Duration.zero,
                  isSelected: false,
                  isCurrentlyPlaying: false,
                  titleAnimationEnabled: titleAnimationEnabled,
                  onTap: () {},
                ),
                itemBuilder: (context, index) {
                  final song = album.albumSongs[index];
                  return CoverFlowAlbumSongListTile(
                    songName: song.getTrackName,
                    trackNumber: index + 1,
                    songDuration: Duration(milliseconds: song.getTrackDuration),
                    isSelected: selectedIndex == index,
                    isCurrentlyPlaying:
                        currentlyPlayingOriginalIndex == song.originalSongIndex,
                    titleAnimationEnabled: titleAnimationEnabled,
                    onTap: () => onSongTap?.call(index),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
