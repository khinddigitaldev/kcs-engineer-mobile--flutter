import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kcs_engineer/util/full_screen_image.dart';
import 'package:kcs_engineer/util/helpers.dart';

class ImageViewerDialog extends StatefulWidget {
  final Map<String, List<String>> attachments;
  GlobalKey<ScaffoldState> imgScaffoldKey;

  ImageViewerDialog({required this.attachments, required this.imgScaffoldKey});

  @override
  _ImageViewerDialogState createState() => new _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<ImageViewerDialog> {
  List<File> images = [];

  late Map<String, dynamic>? attachments = widget.attachments;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: RichText(
        text: TextSpan(
            style: const TextStyle(
              fontSize: 20.0,
              color: Colors.black,
            ),
            children: <TextSpan>[
              TextSpan(
                  text: 'Media',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
      ),
      content: Container(
        alignment: Alignment.centerLeft,
        height: 800,
        width: 600,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
                alignment: Alignment.centerLeft,
                height: 800,
                width: 600.0,
                child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: attachments?.keys.length,
                    itemBuilder: (BuildContext context, int index) =>
                        Column(children: [
                          Container(
                              alignment: Alignment.centerLeft,
                              child: RichText(
                                text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 20.0,
                                      color: Colors.black,
                                    ),
                                    children: <TextSpan>[
                                      TextSpan(
                                          text:
                                              attachments?.keys.toList()[index],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ]),
                              )),
                          SizedBox(
                            height: 30,
                          ),
                          Container(
                              alignment: Alignment.centerLeft,
                              height: 150.0,
                              width: 600.0,
                              child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: attachments?[
                                          attachments?.keys.toList()[index]]
                                      .length,
                                  itemBuilder: (BuildContext context,
                                          int subIndex) =>
                                      Row(
                                        children: [
                                          Container(
                                              color: Colors.grey,
                                              child: Stack(
                                                children: <Widget>[
                                                  GestureDetector(
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              Scaffold(
                                                            key: widget
                                                                .imgScaffoldKey,
                                                            backgroundColor:
                                                                Colors.black,
                                                            appBar: Helpers.customAppBar(context,
                                                                widget.imgScaffoldKey,
                                                                title:
                                                                    "Resource Image",
                                                                isBack: true,
                                                                colorsInverted:
                                                                    true,
                                                                isAppBarTranparent:
                                                                    true,
                                                                hasActions:
                                                                    false,
                                                                handleBackPressed:
                                                                    () {
                                                              Navigator.pop(
                                                                  context);
                                                            }),
                                                            body: Center(
                                                              child:
                                                                  ZoomableImage(
                                                                imageUrl: attachments?[
                                                                        attachments
                                                                            ?.keys
                                                                            .toList()[index]]
                                                                    [subIndex],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: Image.network(
                                                        attachments?[attachments
                                                                ?.keys
                                                                .toList()[index]]
                                                            [subIndex],
                                                        fit: BoxFit.cover,
                                                        loadingBuilder:
                                                            (BuildContext
                                                                    context,
                                                                Widget child,
                                                                ImageChunkEvent?
                                                                    loadingProgress) {
                                                      if (loadingProgress ==
                                                          null) return child;
                                                      return Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                          value: loadingProgress
                                                                      .expectedTotalBytes !=
                                                                  null
                                                              ? loadingProgress
                                                                      .cumulativeBytesLoaded /
                                                                  loadingProgress
                                                                      .expectedTotalBytes!
                                                              : null,
                                                        ),
                                                      );
                                                    }),
                                                  ),
                                                ],
                                              )),
                                          SizedBox(
                                            width: 20,
                                          )
                                        ],
                                      ))),
                          SizedBox(
                            height: 30,
                          )
                        ]))),
          ],
        ),
      ),
    );
  }
}
