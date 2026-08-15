import 'package:classipod/core/constants/app_color_scheme.dart';
import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/extensions/duration_extensions.dart';
import 'package:classipod/core/widgets/marquee_text.dart';
import 'package:flutter/cupertino.dart';

class CoverFlowAlbumSongListTile extends StatelessWidget {
  final String songName;
  final Duration songDuration;
  final bool isSelected;
  final bool isCurrentlyPlaying;
  final VoidCallback onTap;

  const CoverFlowAlbumSongListTile({
    super.key,
    required this.songName,
    required this.songDuration,
    required this.isSelected,
    required this.isCurrentlyPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 30,
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
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 5,
                  child: MarqueeText(
                    songName,
                    style: CupertinoTheme.of(context).textTheme.textStyle
                        .copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppColorScheme.coverFlowSelectedText
                                    .resolveFrom(context)
                              : context.appPrimaryTextColor,
                        ),
                  ),
                ),
                Flexible(
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
}
