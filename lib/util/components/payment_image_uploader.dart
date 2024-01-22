import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kcs_engineer/util/repositories.dart';

class SignatureMultiImageUploadDialog extends StatefulWidget {
  final String jobId;
  final File image;
  final bool isMailInvoice;
  final String mailEmail;
  final String paymentMethodId;

  SignatureMultiImageUploadDialog({
    required this.jobId,
    required this.image,
    required this.isMailInvoice,
    required this.mailEmail,
    required this.paymentMethodId,
  });

  @override
  _SignatureMultiImageUploadDialogState createState() =>
      new _SignatureMultiImageUploadDialogState();
}

class _SignatureMultiImageUploadDialogState
    extends State<SignatureMultiImageUploadDialog> {
  List<File> images = [];

  bool nextPressed = false;
  bool continuePressed = false;
  late String jobId = widget.jobId;
  late File image = widget.image;
  late bool isMailInvoice = widget.isMailInvoice;
  late String mailEmail = widget.mailEmail;
  late String paymentMethodId = widget.paymentMethodId;
  bool isImagesEmpty = false;

  processAction() async {
    var res;
    res = await Repositories.confirmAcknowledgement(
        jobId,
        image,
        images.length > 0 ? images[0] : null,
        isMailInvoice,
        mailEmail,
        paymentMethodId);

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
                        text: 'Please upload a picture of the receipt of the transaction',
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
                    itemCount: 1,
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
                  await processAction();
                }
              }),
        ),
      ],
    );
  }
}
