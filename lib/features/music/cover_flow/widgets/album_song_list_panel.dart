import 'package:classipod/core/constants/app_color_scheme.dart';
import 'package:classipod/core/constants/constants.dart';
import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/features/music/album/models/album_model.dart';
import 'package:classipod/features/music/cover_flow/widgets/cover_flow_album_song_list_tile.dart';
import 'package:flutter/cupertino.dart';

class AlbumSongListPanel extends StatelessWidget {
  final AlbumModel album;
  final int selectedIndex;
  final int? currentlyPlayingOriginalIndex;
  final ScrollController? scrollController;
  final ValueChanged<int>? onSongTap;

  const AlbumSongListPanel({
    super.key,
    required this.album,
    this.selectedIndex = 0,
    this.currentlyPlayingOriginalIndex,
    this.scrollController,
    this.onSongTap,
  });

  static double targetWidth(BuildContext context) =>
      (MediaQuery.sizeOf(context).width - 80)
          .clamp(230.0, double.infinity)
          .toDouble();

  static double targetHeight(BuildContext context) =>
      ((MediaQuery.sizeOf(context).height < Constants.screenHeight
                  ? MediaQuery.sizeOf(context).height
                  : Constants.screenHeight) *
              0.38)
          .clamp(260.0, 360.0)
          .toDouble();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appBackgroundColor,
        border: Border.all(color: context.appOutlineColor),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 50,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColorScheme.coverFlowSelectedGradientStart.resolveFrom(
                      context,
                    ),
                    AppColorScheme.coverFlowSelectedGradientEnd.resolveFrom(
                      context,
                    ),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.albumName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.white,
                      ),
                      maxLines: 1,
                    ),
                    Text(
                      album.albumArtistName,
                      style: const TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.white,
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
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
                  songDuration: Duration.zero,
                  isSelected: false,
                  isCurrentlyPlaying: false,
                  onTap: () {},
                ),
                itemBuilder: (context, index) {
                  final song = album.albumSongs[index];
                  return CoverFlowAlbumSongListTile(
                    songName: song.getTrackName,
                    songDuration: Duration(milliseconds: song.getTrackDuration),
                    isSelected: selectedIndex == index,
                    isCurrentlyPlaying:
                        currentlyPlayingOriginalIndex == song.originalSongIndex,
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
