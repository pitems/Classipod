import 'package:classipod/core/models/music_metadata.dart';
import 'package:classipod/core/navigation/routes.dart';
import 'package:classipod/core/services/audio_player_service.dart';
import 'package:classipod/features/custom_screen_elements/custom_screen.dart';
import 'package:classipod/features/music/album/models/album_model.dart';
import 'package:classipod/features/music/cover_flow/widgets/album_song_list_panel.dart';
import 'package:classipod/features/music/cover_flow/widgets/cover_flow_album_song_list_tile.dart';
import 'package:classipod/features/now_playing/provider/now_playing_details_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CoverFlowAlbumSelectionRouteArgs {
  final AlbumModel albumDetail;
  final VoidCallback? onRouteReady;
  final ValueListenable<bool>? titleAnimationEnabled;

  const CoverFlowAlbumSelectionRouteArgs({
    required this.albumDetail,
    this.onRouteReady,
    this.titleAnimationEnabled,
  });
}

class CoverFlowAlbumSelectionScreen extends ConsumerStatefulWidget {
  final AlbumModel albumDetail;
  final VoidCallback? onRouteReady;
  final ValueListenable<bool>? titleAnimationEnabled;

  const CoverFlowAlbumSelectionScreen({
    super.key,
    required this.albumDetail,
    this.onRouteReady,
    this.titleAnimationEnabled,
  });

  @override
  ConsumerState createState() => _CoverFlowAlbumSelectionScreenState();
}

class _CoverFlowAlbumSelectionScreenState
    extends ConsumerState<CoverFlowAlbumSelectionScreen>
    with CustomScreen {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onRouteReady?.call();
      }
    });
  }

  @override
  int get topStatusBarHeight => 60;

  @override
  String get routeName => Routes.coverFlowSelection.name;

  @override
  List<MusicMetadata> get displayItems => widget.albumDetail.albumSongs;

  @override
  Future<void> onSelectPressed() => _playSongFromAlbum(selectedDisplayItem);

  @override
  void scrollForward() {
    if (selectedDisplayItem >= displayItems.length - 1) {
      return;
    }
    setState(() => selectedDisplayItem++);
    _scheduleSelectedSongVisibility();
  }

  @override
  void scrollBackward() {
    if (selectedDisplayItem <= 0) {
      return;
    }
    setState(() => selectedDisplayItem--);
    _scheduleSelectedSongVisibility();
  }

  void _scheduleSelectedSongVisibility() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) {
        return;
      }

      const rowHeight = CoverFlowAlbumSongListTile.height;
      final position = scrollController.position;
      final selectedTop = selectedDisplayItem * rowHeight;
      final selectedBottom = selectedTop + rowHeight;
      final viewportTop = position.pixels;
      final viewportBottom = viewportTop + position.viewportDimension;

      final targetOffset = selectedTop < viewportTop
          ? selectedTop
          : selectedBottom > viewportBottom
          ? selectedBottom - position.viewportDimension
          : position.pixels;

      final clampedOffset = targetOffset.clamp(0.0, position.maxScrollExtent);
      if (clampedOffset != position.pixels) {
        scrollController.jumpTo(clampedOffset);
      }
    });
  }

  Future<void> _playSongFromAlbum(int index) async {
    setState(() => selectedDisplayItem = index);
    await ref
        .read(audioPlayerServiceProvider.notifier)
        .playAlbum(albumDetail: widget.albumDetail, songIndex: index);

    if (mounted) {
      await context.pushNamed(Routes.nowPlaying.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int? currentlyPlayingOriginalIndex = ref
        .watch(nowPlayingDetailsProvider.select((e) => e.currentMetadata))
        ?.originalSongIndex;
    return Padding(
      // Match the cover-flow transition's content origin:
      // Keep the list 10px from each side and under the top bar.
      padding: const EdgeInsets.fromLTRB(10, 40, 10, 0),
      child: SizedBox(
        width: AlbumSongListPanel.targetWidth(context),
        height: AlbumSongListPanel.targetHeight(context),
        child: AlbumSongListPanel(
          album: widget.albumDetail,
          titleAnimationEnabled: widget.titleAnimationEnabled,
          selectedIndex: selectedDisplayItem,
          currentlyPlayingOriginalIndex: currentlyPlayingOriginalIndex,
          scrollController: scrollController,
          onSongTap: _playSongFromAlbum,
        ),
      ),
    );
  }
}
