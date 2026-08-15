import 'package:classipod/core/constants/app_color_scheme.dart';
import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/extensions/duration_extensions.dart';
import 'package:classipod/core/widgets/marquee_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

class CoverFlowAlbumSongListTile extends StatelessWidget {
  static const height = 44.0;

  final int? trackNumber;
  final String songName;
  final Duration songDuration;
  final bool isSelected;
  final bool isCurrentlyPlaying;
  final ValueListenable<bool>? titleAnimationEnabled;
  final VoidCallback onTap;

  const CoverFlowAlbumSongListTile({
    super.key,
    this.trackNumber,
    required this.songName,
    required this.songDuration,
    required this.isSelected,
    required this.isCurrentlyPlaying,
    this.titleAnimationEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: height,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
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
                  )
                : null,
            border: Border(bottom: BorderSide(color: context.appOutlineColor)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    trackNumber?.toString() ?? '',
                    style: CupertinoTheme.of(context).textTheme.textStyle
                        .copyWith(
                          fontSize: 17,
                          color: isSelected
                              ? AppColorScheme.coverFlowSelectedText
                                    .resolveFrom(context)
                              : context.appSecondaryTextColor,
                        ),
                  ),
                ),
                Flexible(flex: 5, child: _buildTitle(context)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 48,
                  child: isCurrentlyPlaying
                      ? Icon(
                          CupertinoIcons.volume_up,
                          size: 16,
                          color: isSelected
                              ? AppColorScheme.coverFlowSelectedText
                                    .resolveFrom(context)
                              : context.appPrimaryTextColor,
                        )
                      : Text(
                          songDuration.getMinuteAndSecondString,
                          style: CupertinoTheme.of(context).textTheme.textStyle
                              .copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppColorScheme.coverFlowSelectedText
                                          .resolveFrom(context)
                                    : context.appPrimaryTextColor,
                              ),
                          maxLines: 1,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final style = CupertinoTheme.of(context).textTheme.textStyle.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: isSelected
          ? AppColorScheme.coverFlowSelectedText.resolveFrom(context)
          : context.appPrimaryTextColor,
    );
    final marquee = MarqueeText(songName, style: style);
    if (titleAnimationEnabled == null) {
      return marquee;
    }
    return ValueListenableBuilder<bool>(
      valueListenable: titleAnimationEnabled!,
      builder: (context, enabled, _) => enabled
          ? marquee
          : Text(
              songName,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: style,
            ),
    );
  }
}
