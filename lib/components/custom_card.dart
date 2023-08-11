import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:kcs_engineer/themes/text_styles.dart';

class CustomCard extends StatelessWidget {
  final String? label;
  final double? width;
  final Color? color;
  final double? height;
  final TextStyle? textStyle;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final Widget? child;

  const CustomCard(
      {Key? key,
      this.label,
      this.color,
      this.width,
      this.height,
      this.textStyle,
      this.borderRadius,
      this.padding,
      this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    BorderRadius? radius = BorderRadius.circular(10);
    if (borderRadius != null) {
      radius = borderRadius;
    } else if (height != null) {
      radius = BorderRadius.circular(height! / 2);
    }

    return Container(
        width: width != null ? width : null,
        height: height != null ? height : null,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: color != null ? color : Colors.grey, borderRadius: radius),
        padding: padding != null ? padding : const EdgeInsets.all(5),
        child: child != null
            ? child
            : Text(label!,
                style: textStyle != null ? textStyle : TextStyles.textWhiteXs));
  }
}
