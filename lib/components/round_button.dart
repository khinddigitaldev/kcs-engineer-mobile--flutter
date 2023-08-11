import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:kcs_engineer/themes/app_colors.dart';
import 'package:kcs_engineer/themes/text_styles.dart';

class RoundButton extends StatelessWidget {
  final String? title;
  final TextStyle? titleStyles;
  final Color? color;
  final double width;
  final double height;
  final Widget? child;
  final Function onPressed;
  final Border? customBorder;
  final BorderRadius? borderRadius;
  final IconData? icon;
  final EdgeInsets? padding;
  final bool iconLeft;

  const RoundButton(
      {Key? key,
      required this.title,
      this.titleStyles,
      this.color,
      this.width = double.infinity,
      this.height = 40.0,
      this.customBorder,
      this.borderRadius,
      this.icon,
      this.child,
      this.padding,
      this.iconLeft = false,
      required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {
          onPressed();
        },
        child: child != null
            ? child
            : Container(
                width: width,
                height: height,
                alignment: Alignment.center,
                padding: padding != null ? padding : EdgeInsets.zero,
                decoration: BoxDecoration(
                    color: color != null ? color : AppColors.primary,
                    borderRadius: borderRadius != null
                        ? borderRadius
                        : BorderRadius.circular(10),
                    border: customBorder != null
                        ? customBorder
                        : Border.all(color: Colors.grey[400]!, width: 0.5)),
                child: Material(
                    color: Colors.transparent,
                    child: icon != null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                iconLeft
                                    ? Icon(icon, color: Colors.white, size: 25)
                                    : Container(),
                                iconLeft ? SizedBox(width: 10) : Container(),
                                Container(
                                  child: Text(title!,
                                      style: TextStyles.textW500
                                          .copyWith(color: Colors.white)),
                                ),
                                !iconLeft ? SizedBox(width: 10) : Container(),
                                !iconLeft
                                    ? Icon(icon, color: Colors.white, size: 25)
                                    : Container()
                              ])
                        : Container(
                            child: Text(title!,
                                textAlign: TextAlign.center,
                                style: titleStyles != null
                                    ? titleStyles
                                    : TextStyles.textDefaultBoldMd),
                          ))));
  }
}
