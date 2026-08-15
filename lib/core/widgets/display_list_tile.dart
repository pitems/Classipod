import 'package:classipod/core/constants/app_palette.dart';
import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:flutter/cupertino.dart';

class DisplayListTile extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool isAlternate;
  final VoidCallback? onTap;

  const DisplayListTile({
    super.key,
    required this.text,
    required this.isSelected,
    this.isAlternate = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkTheme =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    final alternateColor = isDarkTheme
        ? const Color(0xFF242424)
        : const Color(0xFFE8E8E8);
    final baseColor = isDarkTheme
        ? const Color(0xFF151515)
        : CupertinoColors.white;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 44,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isSelected
                ? null
                : (isAlternate ? alternateColor : baseColor),
            border: isSelected
                ? const Border(
                    top: BorderSide(
                      color: AppPalette.selectedTileTopBorderColor,
                    ),
                    bottom: BorderSide(
                      color: AppPalette.selectedTileBottomBorderColor,
                    ),
                  )
                : null,
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppPalette.selectedTileGradientColor1,
                      AppPalette.selectedTileGradientColor2,
                    ],
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    text,
                    style: CupertinoTheme.of(context).textTheme.textStyle
                        .copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? CupertinoColors.white
                              : context.appPrimaryTextColor,
                        ),
                    maxLines: 1,
                  ),
                ),
                Icon(
                  CupertinoIcons.right_chevron,
                  color: isSelected
                      ? CupertinoColors.white
                      : context.appSecondaryTextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
