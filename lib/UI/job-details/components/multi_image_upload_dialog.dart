import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kcs_engineer/model/job/job.dart';
import 'package:kcs_engineer/util/helpers.dart';
import 'package:kcs_engineer/util/repositories.dart';

class MultiImageUploadDialog extends StatefulWidget {
  final bool isKiv;
  final bool isCancel;
  final bool isStart;
  final bool isClose;
  final bool isComplete;
  final bool isReject;
  final int reasonId;
  final Job selectedJob;

  MultiImageUploadDialog(
      {required this.isKiv,
      required this.isCancel,
      required this.isComplete,
      required this.isReject,
      required this.isClose,
      required this.isStart,
      required this.reasonId,
      required this.selectedJob});

  @override
  _MultiImageUploadDialogState createState() =>
      new _MultiImageUploadDialogState();
}

class _MultiImageUploadDialogState extends State<MultiImageUploadDialog> {
  List<File> images = [];

  bool nextPressed = false;
  bool continuePressed = false;
  late bool isKiv = widget.isKiv;
  late bool isComplete = widget.isComplete;
  late bool isCancel = widget.isCancel;
  late bool isStart = widget.isStart;
  late bool isReject = widget.isReject;
  late bool isClose = widget.isClose;
  late Job selectedJob = widget.selectedJob;
  bool isImagesEmpty = false;

  processAction(bool isKIV, bool isComplete, bool isCancel, bool isStart,
      bool isReject, bool isClose) async {
    var res;
    if (isKIV) {
      res = await Repositories.uploadKIV(
          images, this.selectedJob!.serviceRequestid ?? "0", widget.reasonId);
    } else if (isCancel) {
      res = await Repositories.cancelJob(
          images, this.selectedJob!.serviceRequestid ?? "0", widget.reasonId);
    } else if (isComplete) {
      res = await Repositories.completeJob(
          images, selectedJob!.serviceRequestid ?? "0", selectedJob);
    } else if (isStart) {
      res = await Repositories.startJob(
          images, selectedJob!.serviceRequestid ?? "0", selectedJob);
    } else if (isReject) {
      res = await Repositories.rejectJob(
          selectedJob!.serviceRequestid ?? "0", widget.reasonId);

      // Navigator.pop(context, res);
    } else if (isClose) {
      res = await Repositories.closeJob(
          images, selectedJob!.serviceRequestid ?? "0");
    } else {
      // res = await Repositories.startJob(
      //     images, selectedJob!.serviceRequestid ?? "0");
    }
    Navigator.pop(context, res);
  }

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
                  text: 'Image Upload',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
      ),
      content: Container(
        alignment: Alignment.centerLeft,
        height: 320,
        width: 600,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.bottomLeft,
              child: RichText(
                text: TextSpan(
                    style: const TextStyle(
                      fontSize: 17.0,
                      color: Colors.black,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Please select images that you want to upload',
                      ),
                    ]),
              ),
            ),
            SizedBox(
              height: 40,
            ),
            Container(
                alignment: Alignment.centerLeft,
                height: 195.0,
                width: 600.0,
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount:
                        images.length != 5 ? images.length + 1 : images.length,
                    itemBuilder: (BuildContext context, int index) =>
                        (index <= images.length - 1)
                            ? Row(
                                children: [
                                  Container(
                                      height: 195,
                                      width: 150,
                                      color: Colors.grey,
                                      child: Stack(
                                        children: <Widget>[
                                          Image.file(
                                            images[index],
                                            height: 195.0,
                                            width: 150.0,
                                          ),
                                          Align(
                                            alignment: Alignment.topRight,
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  this.images.removeAt(index);
                                                });
                                              },
                                              child: Icon(
                                                Icons.cancel,
                                                color: Colors.red,
                                                size: 35,
                                              ),
                                            ),
                                          )
                                        ],
                                      )),
                                  SizedBox(
                                    width: 20,
                                  )
                                ],
                              )
                            : GestureDetector(
                                onTap: () async {
                                  setState(() {
                                    nextPressed = true;
                                    continuePressed = false;
                                  });
                                  await ImagePicker()
                                      .pickImage(source: ImageSource.camera)
                                      .then((value) async {
                                    if (value != null) {
                                      setState(() {
                                        this.images.add(File(value.path));
                                      });
                                      //showMultipleImagesPromptDialog(context,false,isKIV,isComplete);
                                    }
                                  });
                                },
                                child: Container(
                                  height: 195.0,
                                  width: 150.0,
                                  color: Colors.grey,
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    size: 25,
                                    color: Colors.white,
                                  ),
                                )))),
            isImagesEmpty
                ? SizedBox(
                    height: 40,
                  )
                : new Container(),
            isImagesEmpty
                ? Row(children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    RichText(
                      text: TextSpan(
                          style: const TextStyle(
                            fontSize: 18.0,
                            color: Colors.red,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'You need to add at least 1 Image',
                            ),
                          ]),
                    ),
                  ])
                : new Container()
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: 100,
          height: 50.0,
          child: ElevatedButton(
              child: const Padding(
                  padding: EdgeInsets.all(0.0),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  )),
              style: ButtonStyle(
                  foregroundColor:
                      MaterialStateProperty.all<Color>(Color(0xFF242A38)),
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Color(0xFF242A38)),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                          side: const BorderSide(color: Color(0xFF242A38))))),
              onPressed: () async {
                setState(() {
                  nextPressed = false;
                  continuePressed = false;
                });
                setState(() {
                  images = [];
                });
                Navigator.pop(context);
              }),
        ),
        SizedBox(
          width: 100,
          height: 50.0,
          child: ElevatedButton(
              child: const Padding(
                  padding: EdgeInsets.all(0.0),
                  child: Text(
                    'Continue',
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  )),
              style: ButtonStyle(
                  foregroundColor:
                      MaterialStateProperty.all<Color>(Color(0xFF242A38)),
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Color(0xFF242A38)),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                          side: const BorderSide(color: Color(0xFF242A38))))),
              onPressed: () async {
                if (images.isEmpty) {
                  setState(() => isImagesEmpty = true);
                } else {
                  setState(() {
                    nextPressed = false;
                    continuePressed = true;
                  });
                  Helpers.showAlert(context);
                  await processAction(
                      isKiv, isComplete, isCancel, isStart, isReject, isClose);
                  Navigator.pop(context);
                }
              }),
        ),
      ],
    );
  }
}
