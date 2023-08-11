import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:kcs_engineer/util/helpers.dart';
import 'package:photo_view/photo_view.dart';

class ZoomableImage extends StatefulWidget {
  final String imageUrl;

  ZoomableImage({required this.imageUrl});

  @override
  _ZoomableImageState createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage> {
  @override
  Widget build(BuildContext context) {
    return Container(
        child: PhotoView(
      imageProvider: NetworkImage(widget.imageUrl),
    ));
  }
}
