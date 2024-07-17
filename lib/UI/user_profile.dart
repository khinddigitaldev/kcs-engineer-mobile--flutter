import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kcs_engineer/model/user/engineer.dart';
import 'package:kcs_engineer/model/user/user.dart';
import 'package:kcs_engineer/themes/text_styles.dart';
import 'package:kcs_engineer/util/api.dart';
import 'package:kcs_engineer/util/helpers.dart';
import 'package:kcs_engineer/util/repositories.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:after_layout/after_layout.dart';

class UserProfile extends StatefulWidget {
  int? data;
  UserProfile({this.data});

  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> with AfterLayoutMixin {
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController emailCT = new TextEditingController();
  TextEditingController passwordCT = new TextEditingController();
  FocusNode focusEmail = new FocusNode();
  FocusNode focusPwd = new FocusNode();
  bool isLoading = false;
  bool showPassword = false;
  String errorMsg = "";
  String version = "";
  String buildNo = "";
  final storage = new FlutterSecureStorage();
  String? token;
  Engineer? engineer;

  File? _imageFile;
  @override
  void initState() {
    // emailCT.text = 'khindtest1@gmail.com';
    // passwordCT.text = 'Abcd@1234';
    // emailCT.text = 'khindcustomerservice@gmail.com';
    // passwordCT.text = 'Khindanshin118';

    super.initState();

    //_loadToken();
    //_checkPermisions();
  }

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) async {
    await fetchProfileData();
    await _loadVersion();
  }

  @override
  void dispose() {
    emailCT.dispose();
    passwordCT.dispose();
    super.dispose();
  }

  Future<void> _getImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: CropAspectRatio(ratioX: 4, ratioY: 4),
          aspectRatioPresets: [
            CropAspectRatioPreset.square
          ],
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: Colors.transparent,
              toolbarWidgetColor: Colors.red,
              statusBarColor: Colors.transparent,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
            IOSUiSettings(title: "Crop Image")
          ]);
      if (croppedFile != null) {
        setState(() {
          _imageFile = File(croppedFile.path);
        });
        await updateProfilePicture();
      }
    }
  }

  updateProfilePicture() async {
    await Repositories.updateProfilePicuture(_imageFile?.path ?? "");

    await fetchProfileData();
  }

  _loadVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String pkgVersion = packageInfo.version;
    String pkgBuild = packageInfo.buildNumber;
    setState(() {
      version = pkgVersion;
      buildNo = pkgBuild;
    });
  }

  // _loadToken() async {
  //   final accessToken = await storage.read(key: TOKEN);

  //   setState(() {
  //     token = accessToken;
  //   });
  // }

  Future<dynamic> fetchProfileData() async {
    Helpers.showAlert(context);

    Engineer? fetchedUser = await Repositories.fetchProfile();

    Navigator.pop(context);
    setState(() {
      engineer = fetchedUser;
    });
  }

  Widget _renderForm() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            Container(
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 29.0,
                    color: Colors.black,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                        text: 'My Profile',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Divider(color: Colors.grey),
            SizedBox(height: 40),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  child: engineer?.profileImage != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Stack(
                              children: [
                                _imageFile != null && engineer != null
                                    ? Container(
                                        width: 280,
                                        height: 300,
                                        decoration: BoxDecoration(
                                            color: Color(0xFF081b29),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            image: DecorationImage(
                                              image: FileImage(
                                                  _imageFile ?? new File("")),
                                            )))
                                    : engineer != null
                                        ? Container(
                                            width: 280,
                                            height: 300,
                                            decoration: BoxDecoration(
                                                color: Color(0xFF081b29),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                image: DecorationImage(
                                                    image:
                                                        CachedNetworkImageProvider(
                                                      engineer?.profileImage ??
                                                          "",
                                                      // maxHeight: 200,
                                                      // maxWidth: 300,
                                                    ),
                                                    fit: BoxFit.cover)),
                                          )
                                        : Container(
                                            width: 280,
                                            height: 300,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                color: Color(0xFF081b29),
                                                image: DecorationImage(
                                                  image: AssetImage(
                                                      'assets/images/user_profile.png'),
                                                  fit: BoxFit.cover,
                                                ))),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Padding(
                                    padding:
                                        EdgeInsets.only(right: 20, bottom: 10),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          primary: Color(0xFF455059)
                                              .withOpacity(0.4)),
                                      onPressed: _getImage,
                                      child: Icon(
                                        size: 30.0,
                                        Icons.camera_alt_outlined,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            )
                          ],
                        )
                      : Stack(children: [
                          Container(
                              width: 280,
                              height: 300,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Color(0xFF081b29),
                                  image: DecorationImage(
                                    image: AssetImage(
                                        'assets/images/user_profile.png'),
                                    fit: BoxFit.cover,
                                  ))),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Padding(
                              padding: EdgeInsets.only(right: 20, bottom: 10),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    primary:
                                        Color(0xFF455059).withOpacity(0.4)),
                                onPressed: _getImage,
                                child: Icon(
                                  size: 30.0,
                                  Icons.camera_alt_outlined,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        ]),
                ),
              ],
            ),

            SizedBox(height: 60),
            Container(
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 45.0,
                    color: Colors.black,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                        text: engineer != null ? engineer?.fullName : '',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 5),
            Container(
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 20.0,
                    color: Colors.grey,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                        text: engineer != null ? engineer?.role : '',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            // Container(
            //   alignment: Alignment.centerLeft,
            //   width: 80,
            //   child: ElevatedButton(
            //       style: ButtonStyle(
            //           backgroundColor: MaterialStateProperty.all(Colors.black),
            //           shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            //               RoundedRectangleBorder(
            //                   borderRadius: BorderRadius.circular(20.0),
            //                   side: BorderSide(color: Colors.black45)))),
            //       onPressed: () {},
            //       child: Icon(
            //         // <-- Icon
            //         Icons.qr_code,
            //         color: Colors.white,
            //         size: 30.0,
            //       )),
            // ),

            SizedBox(height: 40),
            Container(
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 28.0,
                    color: Colors.black,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                        text: 'Personal Details',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RichText(
                          text: TextSpan(
                              style: const TextStyle(
                                fontSize: 14.0,
                                color: Colors.grey,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: 'TECHNICIAN ID',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ]),
                        ),
                        RichText(
                          text: TextSpan(
                              style: const TextStyle(
                                fontSize: 20.0,
                                color: Colors.black,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: engineer != null
                                      ? engineer?.employeeCode
                                      : '',
                                ),
                              ]),
                        ),
                        SizedBox(height: 10),
                        RichText(
                          text: TextSpan(
                              style: const TextStyle(
                                fontSize: 14.0,
                                color: Colors.grey,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: 'EMAIL',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ]),
                        ),
                        RichText(
                          text: TextSpan(
                              style: const TextStyle(
                                fontSize: 20.0,
                                color: Colors.black,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: engineer?.email,
                                ),
                              ]),
                        ),
                      ],
                    ),
                  ),
                ),
                Flexible(
                  fit: FlexFit.tight,
                  child: Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 20),
                        RichText(
                          text: TextSpan(
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: 'CONTACT NO',
                                    style: const TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold)),
                              ]),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: RichText(
                                text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 20.0,
                                      color: Colors.black,
                                    ),
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: engineer?.contactNo,
                                      ),
                                    ]),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        RichText(
                          text: TextSpan(
                              style: const TextStyle(
                                fontSize: 14.0,
                                color: Colors.grey,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: 'HUB LOCATION',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ]),
                        ),
                        RichText(
                          text: TextSpan(
                              style: const TextStyle(
                                fontSize: 20.0,
                                color: Colors.black,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: engineer?.hubLocation,
                                ),
                              ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 30,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                Flexible(
                  fit: FlexFit.tight,
                  child: Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RichText(
                          text: TextSpan(
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: 'OPERATING HOURS',
                                    style: const TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold)),
                              ]),
                        ),
                        SizedBox(height: 5),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: RichText(
                            text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 20.0,
                                  color: Colors.black,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: engineer?.operatingHours,
                                  ),
                                ]),
                          ),
                        ),
                        SizedBox(height: 5),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Row(children: [
              InkWell(
                  onTap: () => {},
                  child: _renderLabel("App Version",
                      textStyle: TextStyles.textGrey,
                      padding: EdgeInsets.only(top: 10))),
              Spacer(),
              Text(
                '$version ($buildNo)' +
                    (FlutterConfig.get("ENVIRONMENT") == "STAGING"
                        ? " (STAGING)"
                        : ""),
                style: TextStyles.textDefault,
              )
            ]),
            // Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            //   Container(
            //       width: MediaQuery.of(context).size.width * 0.15,
            //       height: 40.0,
            //       child: ElevatedButton(
            //           style: ButtonStyle(
            //               backgroundColor:
            //                   MaterialStateProperty.all(Colors.white),
            //               shape:
            //                   MaterialStateProperty.all<RoundedRectangleBorder>(
            //                       RoundedRectangleBorder(
            //                           borderRadius: BorderRadius.circular(20.0),
            //                           side:
            //                               BorderSide(color: Colors.black45)))),
            //           onPressed: () {},
            //           child: Row(
            //             mainAxisAlignment: MainAxisAlignment.center,
            //             children: [
            //               Text(
            //                 "MON - FRI",
            //                 style: TextStyle(
            //                     fontSize: 13.0, color: Colors.black45),
            //               ),
            //             ],
            //           ))),
            //   SizedBox(width: 10),
            //   Container(
            //       width: MediaQuery.of(context).size.width * 0.15,
            //       height: 40.0,
            //       child: ElevatedButton(
            //           style: ButtonStyle(
            //               backgroundColor:
            //                   MaterialStateProperty.all(Colors.white),
            //               shape:
            //                   MaterialStateProperty.all<RoundedRectangleBorder>(
            //                       RoundedRectangleBorder(
            //                           borderRadius: BorderRadius.circular(20.0),
            //                           side:
            //                               BorderSide(color: Colors.black45)))),
            //           onPressed: () {},
            //           child: Row(
            //             mainAxisAlignment: MainAxisAlignment.center,
            //             children: [
            //               Text(
            //                 "9AM - 6PM",
            //                 style: TextStyle(
            //                     fontSize: 13.0, color: Colors.black45),
            //               ),
            //             ],
            //           ))),
            //   SizedBox(width: 10),
            //   Container(
            //       alignment: Alignment.centerLeft,
            //       width: MediaQuery.of(context).size.width * 0.15,
            //       height: 40.0,
            //       child: ElevatedButton(
            //           style: ButtonStyle(
            //               backgroundColor:
            //                   MaterialStateProperty.all(Colors.black54),
            //               shape:
            //                   MaterialStateProperty.all<RoundedRectangleBorder>(
            //                       RoundedRectangleBorder(
            //                           borderRadius: BorderRadius.circular(20.0),
            //                           side:
            //                               BorderSide(color: Colors.black45)))),
            //           onPressed: () {},
            //           child: Row(
            //             mainAxisAlignment: MainAxisAlignment.center,
            //             children: [
            //               Icon(
            //                 // <-- Icon
            //                 Icons.qr_code,
            //                 color: Colors.white,
            //                 size: 40.0,
            //               )
            //             ],
            //           ))),
            // ]),
          ],
        ),
      ),
    );
  }

  _renderError() {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      // SizedBox(height: 10),
      SizedBox(height: 20),
    ]);
  }

  Widget _renderLabel(title,
      {width, padding, TextAlign? textAlign, textStyle}) {
    return Container(
        padding: padding != null ? padding : EdgeInsets.all(0),
        width: width != null ? width : MediaQuery.of(context).size.width * 0.25,
        child: Text(title,
            textAlign: textAlign != null ? textAlign : TextAlign.start,
            style: textStyle != null ? textStyle : TextStyles.textDefault));
  }

  Future<bool> _onWillPop() async {
    //Navigator.pop(context);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      key: _scaffoldKey,
      //resizeToAvoidBottomInset: false,
      body: CustomPaint(
          child: SingleChildScrollView(
              // physics: ClampingScrollPhysics(parent: NeverScrollableScrollPhysics()),
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration:
                      new BoxDecoration(color: Colors.white.withOpacity(0.0)),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        errorMsg != "" ? _renderError() : Container(),
                        _renderForm(),
                        SizedBox(height: 10),
                        //Expanded(child: _renderBottom()),
                        //version != "" ? _renderVersion() : Container()
                      ])))),
    );
  }
}
