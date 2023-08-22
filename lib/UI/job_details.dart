import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:expandable_bottom_sheet/expandable_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kcs_engineer/model/general_code.dart';
import 'package:kcs_engineer/model/job.dart';
import 'package:kcs_engineer/model/jobGeneralCodes.dart';
import 'package:kcs_engineer/model/solution.dart';
import 'package:kcs_engineer/model/sparepart.dart';
import 'package:kcs_engineer/model/user.dart';
import 'package:kcs_engineer/model/user_sparepart.dart';
import 'package:kcs_engineer/themes/app_colors.dart';
import 'package:kcs_engineer/themes/text_styles.dart';
import 'package:kcs_engineer/util/api.dart';
import 'package:kcs_engineer/util/full_screen_image.dart';
import 'package:kcs_engineer/util/helpers.dart';
import 'package:kcs_engineer/util/repositories.dart';
import 'package:package_info_plus/package_info_plus.dart';

class JobDetails extends StatefulWidget {
  // Job? data;
  JobDetails(
      //{
      // this.data
      //}

      );

  @override
  _JobDetailsState createState() => _JobDetailsState();
}

class _JobDetailsState extends State<JobDetails> with WidgetsBindingObserver {
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  GlobalKey<ScaffoldState> _imgScaffoldKey = new GlobalKey<ScaffoldState>();

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController serialNoController = new TextEditingController();
  TextEditingController remarksController = new TextEditingController();
  bool isLoading = false;
  bool isSerialNoEditable = false;
  bool isRemarksEditable = false;
  bool showPassword = false;
  String errorMsg = "";
  String version = "";
  bool isChargeable = false;
  Job? selectedJob;
  late FocusNode serialNoFocusNode;
  late FocusNode remarksFocusNode;
  List<Solution> solutions = [];
  List<String> solutionLabels = [];
  XFile? tempImage;
  bool nextImagePressed = false;
  bool continuePressed = false;
  var _refreshKey = GlobalKey<RefreshIndicatorState>();
  List<File> images = [];
  final storage = new FlutterSecureStorage();
  String? token;
  int imageCount = 3;
  final imageUrls = [
    "https://www.pngitem.com/pimgs/m/30-307416_profile-icon-png-image-free-download-searchpng-employee.png",
    "https://www.pngitem.com/pimgs/m/30-307416_profile-icon-png-image-free-download-searchpng-employee.png",
    "https://www.pngitem.com/pimgs/m/30-307416_profile-icon-png-image-free-download-searchpng-employee.png",
    "https://www.pngitem.com/pimgs/m/30-307416_profile-icon-png-image-free-download-searchpng-employee.png"
  ];

  ExpansionStatus _expansionStatus = ExpansionStatus.contracted;
  GlobalKey<ExpandableBottomSheetState> key = new GlobalKey();
  bool isExpanded = false;

  bool isPartsEditable = false;
  bool isGeneralCodeEditable = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();

    serialNoFocusNode = FocusNode();
    remarksFocusNode = FocusNode();

    // if (solutionLabels.length == 0) {
    //   fetchSolutions();
    // }
    setState(() {
      selectedJob = null;
      serialNoController.text = "SER_001";
      remarksController.text =
          "Start collecting only on Friday morning, not Thursday";
    });

    _loadVersion();
    //_loadToken();
    //_checkPermisions();
  }

  //TODO
  void fetchSolutions() async {
    solutions = await Repositories.fetchSolutions();

    solutions.forEach((element) {
      solutionLabels.add(element.solution ?? "");
    });

    setState(() {
      solutionLabels = solutionLabels;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    serialNoFocusNode.dispose();
    remarksFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Helpers.showAlert(context);
      // this.refreshJobDetails();
      // Navigator.pop(context);
    }
  }

  _loadVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String pkgVersion = packageInfo.version;

    setState(() {
      version = pkgVersion;
    });
  }

  // _loadToken() async {
  //   final accessToken = await storage.read(key: TOKEN);

  //   setState(() {
  //     token = accessToken;
  //   });
  // }

  void _handleSignIn() async {}

  Widget buildProductInfo() {
    final fullWidth = MediaQuery.of(context).size.width;
    final rowWidth = fullWidth * 0.77; //90%

    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Container(
            alignment: Alignment.centerLeft,
            width: rowWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Container(
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: Row(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              RichText(
                                text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      color: Colors.black54,
                                    ),
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: 'SERIAL NO',
                                      ),
                                    ]),
                              ),
                              Container(
                                width: 120,
                                height: 65,
                                child: TextFormField(
                                  keyboardType: TextInputType.multiline,
                                  minLines: 1,
                                  maxLines: 2,
                                  onChanged: (str) {
                                    setState(() {
                                      isSerialNoEditable = true;
                                    });
                                  },
                                  enabled: true,
                                  controller: serialNoController,
                                  //     readOnly: isSerialNoEditable,
                                  focusNode: serialNoFocusNode,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                  style: TextStyle(
                                    fontSize: 15.0,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            width: 30,
                          ),
                          GestureDetector(
                            onTap: () async {
                              if (isSerialNoEditable) {
                                Helpers.showAlert(context);
                                var res = await Repositories.updateSerialNo(
                                    selectedJob!.id ?? 0,
                                    serialNoController.text.toString());
                                setState(() {
                                  isSerialNoEditable = false;
                                });
                                FocusManager.instance.primaryFocus?.unfocus();
                                Navigator.pop(context);
                                await refreshJobDetails();
                              } else {
                                setState(() {
                                  isSerialNoEditable = true;
                                });
                                Future.delayed(Duration.zero, () {
                                  serialNoFocusNode.requestFocus();
                                });
                              }
                            },
                            child: true
                                ? isSerialNoEditable
                                    ? Icon(
                                        // <-- Icon
                                        Icons.check,
                                        color: Colors.black54,
                                        size: 25.0,
                                      )
                                    : Icon(
                                        // <-- Icon
                                        Icons.edit,
                                        color: Colors.black54,
                                        size: 25.0,
                                      )
                                : new Container(),
                          )
                        ],
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: Row(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const <Widget>[
                              Icon(
                                // <-- Icon
                                Icons.person,
                                color: Colors.black54,
                                size: 25.0,
                              ),
                            ],
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          RichText(
                            text: TextSpan(
                                style: TextStyle(
                                  fontSize: 15.0,
                                  color: Colors.black54,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: 'Esther Howard',
                                  ),
                                ]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: RichText(
                        text: TextSpan(
                            style: TextStyle(
                              fontSize: 15.0,
                              color: Colors.black54,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text:
                                    '440A Clementi Avenue 3 #14-10 Clementi Cascadia',
                              ),
                            ]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Container(
                      width: MediaQuery.of(context).size.width * 0.25,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.25,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    RichText(
                                      text: const TextSpan(
                                          style: TextStyle(
                                            fontSize: 15.0,
                                            color: Colors.black54,
                                          ),
                                          children: <TextSpan>[
                                            const TextSpan(
                                              text: 'PRODUCT CODE',
                                            ),
                                          ]),
                                    ),
                                    RichText(
                                      text: TextSpan(
                                          style: TextStyle(
                                            fontSize: 15.0,
                                            color: Colors.black87,
                                          ),
                                          children: <TextSpan>[
                                            TextSpan(
                                              text: '395-9823',
                                            ),
                                          ]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: Row(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Icon(
                                // <-- Icon
                                Icons.mail_outline,
                                color: Colors.black54,
                                size: 25.0,
                              ),
                            ],
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          RichText(
                            text: TextSpan(
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.black54,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: 'binhan628@gmail.com',
                                  ),
                                ]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: RichText(
                        //textAlign: TextAlign.justify,
                        text: TextSpan(
                            style: TextStyle(
                              fontSize: 15.0,
                              color: Colors.black54,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: "408896",
                              ),
                            ]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Container(
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: Row(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              RichText(
                                text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      color: Colors.black54,
                                    ),
                                    children: <TextSpan>[
                                      const TextSpan(
                                        text: 'PRODUCT NAME',
                                      ),
                                    ]),
                              ),
                              Container(
                                alignment: Alignment.centerLeft,
                                width: 130,
                                child: RichText(
                                  text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 15.0,
                                        color: Colors.black87,
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: "Disney x KHIND 3L Air Fryer",
                                        ),
                                      ]),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: Row(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Icon(
                                // <-- Icon
                                Icons.phone,
                                color: Colors.black54,
                                size: 25.0,
                              ),
                            ],
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          RichText(
                            text: TextSpan(
                                // Note: Styles for TextSpans must be explicitly defined.
                                // Child text spans will inherit styles from parent
                                style: TextStyle(
                                  fontSize: 15.0,
                                  color: Colors.black54,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: '+65 1234-5678',
                                  ),
                                ]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                        width: MediaQuery.of(context).size.width * 0.25,
                        child: new Container()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool validateIfEditedValuesAreSaved() {
    if (isRemarksEditable ||
        isSerialNoEditable ||
        isPartsEditable ||
        isGeneralCodeEditable) {
      var editOngoingFields = '';

      int count = 0;

      if (isRemarksEditable) {
        editOngoingFields = "'Remarks'";
        count++;
      }

      if (isSerialNoEditable) {
        if (editOngoingFields != "") {
          editOngoingFields = editOngoingFields + ",'Serial number'";
        } else {
          editOngoingFields = "'Serial number'";
        }
        count++;
      }

      if (isPartsEditable) {
        if (editOngoingFields != "") {
          editOngoingFields = editOngoingFields + ",'Parts'";
        } else {
          editOngoingFields = "'Parts'";
        }
        count++;
      }

      if (isGeneralCodeEditable) {
        if (editOngoingFields != "") {
          editOngoingFields = editOngoingFields + ",'General codes'";
        } else {
          editOngoingFields = "'General codes'";
        }
        count++;
      }

      if (editOngoingFields != "") {
        Helpers.showAlert(context,
            title: "Forgot to Save ?",
            desc: "是否要保存您所所做的更改？如果不保存更改，更改将丢失。",
            hasAction: true,
            okTitle: "Save 保存",
            noTitle: "Discard 丢弃",
            maxWidth: 600.0,
            customImage: Image(
                image: AssetImage('assets/images/info.png'),
                width: 50,
                height: 50),
            onCancelPressed: () async {
              setState(() {
                isPartsEditable = false;
                isGeneralCodeEditable = false;
                isRemarksEditable = false;
                isSerialNoEditable = false;

                FocusManager.instance.primaryFocus?.unfocus();
                FocusScope.of(context).unfocus();
              });
              Navigator.pop(context);

              await refreshJobDetails();
            },
            hasCancel: true,
            onPressed: () async {
              Navigator.pop(context);

              if (isRemarksEditable) {
                Helpers.showAlert(context);
                var res = await Repositories.updateRemarks(
                    selectedJob!.id ?? 0, remarksController.text.toString());
                Navigator.pop(context);
                setState(() {
                  isRemarksEditable = false;
                });
              }

              if (isSerialNoEditable) {
                Helpers.showAlert(context);
                var res = await Repositories.updateSerialNo(
                    selectedJob!.id ?? 0, serialNoController.text.toString());
                Navigator.pop(context);
                setState(() {
                  isSerialNoEditable = false;
                });
              }

              if (isPartsEditable) {
                bool isError = false;
                selectedJob!.jobSpareParts?.forEach((element) {
                  if (element.quantity == "" || element.discount == "") {
                    isError = true;
                  }
                });
                if (isError) {
                  showActionEmptyAlert();
                } else {
                  var res = await this.updateSpareParts();
                  if (!res) {
                    await _renderErrorUpdateValues();
                  }
                  setState(() {
                    isPartsEditable = false;
                  });
                }
              }

              if (isGeneralCodeEditable) {
                bool isError = false;
                Helpers.editableGeneralCodes.forEach((element) {
                  if (element.price == "") {
                    isError = true;
                  }
                });
                if (isError) {
                  showActionEmptyAlert();
                } else {
                  var res = await this.updateGeneralCodePrice();
                  if (!res) {
                    await _renderErrorUpdateValues();
                  } else {
                    setState(() {
                      isGeneralCodeEditable = false;
                    });
                  }
                }
              }
              await refreshJobDetails();

              setState(() {
                isPartsEditable = false;
                isGeneralCodeEditable = false;
                isRemarksEditable = false;
                isSerialNoEditable = false;

                FocusManager.instance.primaryFocus?.unfocus();
                //FocusScope.of(context).unfocus();
              });
            });
        return false;
      } else {
        return false;
      }
    } else {
      return true;
    }
  }

  Widget buildIssueInfo() {
    final fullWidth = MediaQuery.of(context).size.width;
    final rowWidth = fullWidth * 0.85; //90%
    final containerWidth =
        rowWidth / 3; //Could also use this to set the containers individually

    return Container(
      child: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Container(
              width: rowWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Container(
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: Row(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[],
                            ),
                          ],
                        ),
                      ),
                      Container(),
                    ],
                  ),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              RichText(
                                text: const TextSpan(
                                    // Note: Styles for TextSpans must be explicitly defined.
                                    // Child text spans will inherit styles from parent
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      color: Colors.black54,
                                    ),
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: 'PURCHASE DATE',
                                      ),
                                    ]),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              RichText(
                                text: TextSpan(
                                    // Note: Styles for TextSpans must be explicitly defined.
                                    // Child text spans will inherit styles from parent
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      color: Colors.black87,
                                    ),
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: selectedJob != null
                                            ? selectedJob!.purchaseDate
                                                ?.split(' ')[0]
                                            : '-',
                                      ),
                                    ]),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.25,
                            child: Row(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const Icon(
                                      // <-- Icon
                                      Icons.payment_outlined,
                                      color: Colors.black54,
                                      size: 25.0,
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                RichText(
                                  text: TextSpan(
                                      // Note: Styles for TextSpans must be explicitly defined.
                                      // Child text spans will inherit styles from parent
                                      style: TextStyle(
                                        fontSize: 15.0,
                                        color: Colors.black54,
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                            text: ((selectedJob
                                                            ?.paymentMethod !=
                                                        null &&
                                                    (selectedJob?.paymentMethod
                                                            ?.isNotEmpty ??
                                                        false))
                                                ? selectedJob?.paymentMethod
                                                    ?.reduce((value, element) =>
                                                        value +
                                                        (element != ""
                                                            ? " & "
                                                            : "") +
                                                        element)
                                                : "-")),
                                      ]),
                                ),
                              ],
                            ),
                          ),
                        )
                      ]),
                  SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        RichText(
                          text: const TextSpan(
                              // Note: Styles for TextSpans must be explicitly defined.
                              // Child text spans will inherit styles from parent
                              style: TextStyle(
                                fontSize: 15.0,
                                color: Colors.black54,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: 'REPORTED ISSUE',
                                ),
                              ]),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        RichText(
                          text: TextSpan(
                              // Note: Styles for TextSpans must be explicitly defined.
                              // Child text spans will inherit styles from parent
                              style: TextStyle(
                                fontSize: 15.0,
                                color: Colors.black87,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: 'Change order missed by pro',
                                ),
                              ]),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        RichText(
                          text: const TextSpan(
                              // Note: Styles for TextSpans must be explicitly defined.
                              // Child text spans will inherit styles from parent
                              style: TextStyle(
                                fontSize: 15.0,
                                color: Colors.black54,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: 'ACTUAL ISSUE',
                                ),
                              ]),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        RichText(
                          text: TextSpan(
                              // Note: Styles for TextSpans must be explicitly defined.
                              // Child text spans will inherit styles from parent
                              style: TextStyle(
                                fontSize: 15.0,
                                color: Colors.black87,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: 'Change order missed by pro',
                                ),
                              ]),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(
                            height: 20,
                          ),
                          RichText(
                            text: const TextSpan(
                                // Note: Styles for TextSpans must be explicitly defined.
                                // Child text spans will inherit styles from parent
                                style: TextStyle(
                                  fontSize: 15.0,
                                  color: Colors.black54,
                                ),
                                children: <TextSpan>[
                                  const TextSpan(
                                    text: 'REMARKS',
                                  ),
                                ]),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.4,
                            height: MediaQuery.of(context).size.height * 0.05,
                            child: SizedBox(
                              width: 100,
                              height: 40,
                              child: TextFormField(
                                textInputAction: TextInputAction.newline,
                                minLines: 1,
                                maxLines: 5,
                                keyboardType: TextInputType.multiline,
                                onChanged: (str) {
                                  setState(() {
                                    isRemarksEditable = true;
                                  });
                                },
                                controller: remarksController,
                                enabled: false,
                                focusNode: remarksFocusNode,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                ),
                                style: TextStyle(
                                  fontSize: 15.0,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      GestureDetector(
                        onTap: () async {
                          if (isRemarksEditable) {
                            Helpers.showAlert(context);
                            var res = await Repositories.updateRemarks(
                                selectedJob!.id ?? 0,
                                remarksController.text.toString());
                            //TODO
                            await _fetchJobs();
                            setState(() {
                              isRemarksEditable = false;
                            });
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.pop(context);
                          } else {
                            setState(() {
                              isRemarksEditable = true;
                              remarksFocusNode.requestFocus();
                            });
                          }
                        },
                        child: true
                            ? false
                                ? Icon(
                                    // <-- Icon
                                    Icons.check,
                                    color: Colors.black54,
                                    size: 25.0,
                                  )
                                : Icon(
                                    // <-- Icon
                                    Icons.edit,
                                    color: Colors.black54,
                                    size: 25.0,
                                  )
                            : new Container(),
                      )
                    ],
                  ),
                  Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          RichText(
                            text: const TextSpan(
                                // Note: Styles for TextSpans must be explicitly defined.
                                // Child text spans will inherit styles from parent
                                style: TextStyle(
                                  fontSize: 15.0,
                                  color: Colors.black54,
                                ),
                                children: <TextSpan>[
                                  const TextSpan(
                                    text: 'ADMIN REMARKS',
                                  ),
                                ]),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.4,
                            height: MediaQuery.of(context).size.height * 0.05,
                            child: SizedBox(
                              width: 100,
                              height: 40,
                              child: TextFormField(
                                textInputAction: TextInputAction.newline,
                                minLines: 1,
                                maxLines: 5,
                                keyboardType: TextInputType.multiline,
                                onChanged: (str) {
                                  setState(() {
                                    isRemarksEditable = true;
                                  });
                                },
                                controller: remarksController,
                                enabled: false,
                                focusNode: remarksFocusNode,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                ),
                                style: TextStyle(
                                  fontSize: 15.0,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      GestureDetector(
                        onTap: () async {
                          if (isRemarksEditable) {
                            Helpers.showAlert(context);
                            var res = await Repositories.updateRemarks(
                                selectedJob!.id ?? 0,
                                remarksController.text.toString());
                            //TODO
                            await _fetchJobs();
                            setState(() {
                              isRemarksEditable = false;
                            });
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.pop(context);
                          } else {
                            setState(() {
                              isRemarksEditable = true;
                              remarksFocusNode.requestFocus();
                            });
                          }
                        },
                        child: true
                            ? false
                                ? Icon(
                                    // <-- Icon
                                    Icons.check,
                                    color: Colors.black54,
                                    size: 25.0,
                                  )
                                : Icon(
                                    // <-- Icon
                                    Icons.edit,
                                    color: Colors.black54,
                                    size: 25.0,
                                  )
                            : new Container(),
                      )
                    ],
                  ),
                  // Row(
                  //   //mainAxisAlignment: MainAxisAlignment.spaceAround,
                  //   children: <Widget>[

                  //   ],
                  // ),
                  const SizedBox(
                    height: 30,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderForm() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.transparent, borderRadius: BorderRadius.circular(10)),
      child: Form(
        key: _formKey,
        child: Column(children: [
          Container(
            child: Column(children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                      child: Container(
                    child: Padding(
                      padding: const EdgeInsets.all(0.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                RichText(
                                  text: const TextSpan(
                                      // Note: Styles for TextSpans must be explicitly defined.
                                      // Child text spans will inherit styles from parent
                                      style: TextStyle(
                                        fontSize: 25.0,
                                        color: Colors.black,
                                      ),
                                      children: <TextSpan>[
                                        const TextSpan(
                                          text: 'Job',
                                        ),
                                      ]),
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.01,
                                ),
                                RichText(
                                  text: TextSpan(
                                      // Note: Styles for TextSpans must be explicitly defined.
                                      // Child text spans will inherit styles from parent
                                      style: TextStyle(
                                        fontSize: 25.0,
                                        color: Colors.blue,
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: '#84739',
                                        ),
                                      ]),
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.01,
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      // <-- Icon
                                      Icons.circle,
                                      color: Colors.green,

                                      size: 18.0,
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    RichText(
                                      text: TextSpan(
                                          // Note: Styles for TextSpans must be explicitly defined.
                                          // Child text spans will inherit styles from parent
                                          style: TextStyle(
                                            fontSize: 15.0,
                                            color: Colors.black54,
                                          ),
                                          children: <TextSpan>[
                                            TextSpan(
                                              text: 'Pending Repair',
                                            ),
                                          ]),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF242A38),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Center(
                                      child: Text(
                                        'Home Visit',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.2,
                                  height:
                                      MediaQuery.of(context).size.height * 0.03,
                                  child: Stack(
                                    children: List.generate(4, (index) {
                                      double position = index.toDouble() *
                                          25; // Adjust the overlapping position
                                      return Positioned(
                                        left: position,
                                        child: Container(
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color: Colors.white,
                                                    width: 2.0)),
                                            child: CircleAvatar(
                                              radius: 15.0,
                                              backgroundImage:
                                                  CachedNetworkImageProvider(
                                                      imageUrls[index]),
                                            )),
                                      );
                                    }),
                                  ),
                                )

                                //Pending REPAIR
                              ]),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.01,
                          ),
                          RichText(
                            text: TextSpan(
                                // Note: Styles for TextSpans must be explicitly defined.
                                // Child text spans will inherit styles from parent
                                style: TextStyle(
                                  fontSize: 15.0,
                                  color: Colors.black54,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: "31/20/2022 10:00 AM TO 2:00PM"),
                                ]),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: MediaQuery.of(context).size.width *
                                0.15, // <-- match_parent
                            height: MediaQuery.of(context).size.width *
                                0.05, // <-- match-parent
                            child: (selectedJob?.attachments != null &&
                                    (selectedJob?.attachments?.isNotEmpty ??
                                        false))
                                ? ElevatedButton(
                                    child: Padding(
                                        padding: const EdgeInsets.all(0.0),
                                        child: Row(children: [
                                          const Icon(
                                            // <-- Icon
                                            Icons.image,
                                            color: Colors.white,
                                            size: 18.0,
                                          ),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          const Text(
                                            'Media',
                                            style: const TextStyle(
                                                fontSize: 15,
                                                color: Colors.white),
                                          )
                                        ])),
                                    style: ButtonStyle(
                                        foregroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Color(0xFF242A38)),
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Color(0xFF242A38)),
                                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                            RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4.0),
                                                side: const BorderSide(
                                                    color:
                                                        Color(0xFF242A38))))),
                                    onPressed: () async {
                                      setState(() {
                                        images = [];
                                        continuePressed = false;
                                        nextImagePressed = false;
                                      });
                                      await showImageViewerPromptDialog(
                                          context);
                                    })
                                : new Container(),
                          ),
                        ],
                      ),
                    ),
                  )),
                  Flexible(
                    fit: FlexFit.tight,
                    child: Padding(
                      padding: const EdgeInsets.all(0.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: true
                                ? MediaQuery.of(context).size.width * 0.18
                                : MediaQuery.of(context).size.width *
                                    0.22, // <-- match_parent
                            height: MediaQuery.of(context).size.width *
                                0.05, // <-- match-parent
                            child: true
                                ? ElevatedButton(
                                    child: Padding(
                                        padding: const EdgeInsets.all(0.0),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              // <-- Icon
                                              Icons.cancel,
                                              color: Colors.white,
                                              size: 18.0,
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            const Text(
                                              'Cancel Job',
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.white),
                                            )
                                          ],
                                        )),
                                    style: ButtonStyle(
                                        foregroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.red),
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.red),
                                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                            RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4.0),
                                                side: const BorderSide(
                                                    color: Colors.red)))),
                                    onPressed: () async {
                                      var res =
                                          validateIfEditedValuesAreSaved();

                                      if (res) {
                                        Helpers.showAlert(context,
                                            title:
                                                "Are you sure you want to cancel this job?",
                                            hasAction: true,
                                            okTitle: "Yes",
                                            noTitle: "No",
                                            customImage: Image(
                                                image: AssetImage(
                                                    'assets/images/info.png'),
                                                width: 50,
                                                height: 50),
                                            hasCancel: true,
                                            onPressed: () async {
                                          var result =
                                              await Repositories.cancelJob(
                                                  selectedJob!.id ?? 0);
                                          Navigator.pop(context);

                                          result
                                              ? Helpers.showAlert(context,
                                                  hasAction: true,
                                                  title:
                                                      "Job has been successfully cancelled ",
                                                  onPressed: () async {
                                                  await refreshJobDetails();
                                                  Navigator.pop(context);
                                                })
                                              : Helpers.showAlert(context,
                                                  hasAction: true,
                                                  title:
                                                      "Could not cancel the job",
                                                  onPressed: () async {
                                                  await refreshJobDetails();
                                                  Navigator.pop(context);
                                                });
                                        });
                                      }
                                    })
                                : selectedJob!.status == "IN PROGRESS"
                                    ? ElevatedButton(
                                        child: Padding(
                                            padding: const EdgeInsets.all(0.0),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  // <-- Icon
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 18.0,
                                                ),
                                                const SizedBox(
                                                  width: 10,
                                                ),
                                                const Text(
                                                  'Complete Job',
                                                  style: TextStyle(
                                                      fontSize: 15,
                                                      color: Colors.white),
                                                )
                                              ],
                                            )),
                                        style: ButtonStyle(
                                            foregroundColor:
                                                MaterialStateProperty.all<Color>(Colors.green),
                                            backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
                                            shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0), side: const BorderSide(color: Colors.green)))),
                                        onPressed: () async {
                                          var res =
                                              validateIfEditedValuesAreSaved();

                                          if (res) {
                                            if ((selectedJob!.isChargeable ??
                                                    false) &&
                                                selectedJob!.sumTotal != 0) {
                                              Helpers.showAlert(context,
                                                  title:
                                                      "Confirm to Complete Job?",
                                                  desc:
                                                      "Confirm后无法返回此页面进行更改，请仔细检查所有细节是否正确。",
                                                  hasAction: true,
                                                  okTitle: "Confirm",
                                                  maxWidth: 600.0,
                                                  customImage: Image(
                                                      image: AssetImage(
                                                          'assets/images/info.png'),
                                                      width: 50,
                                                      height: 50),
                                                  hasCancel: true,
                                                  onPressed: () async {
                                                Navigator.pop(context);
                                                setState(() {
                                                  images = [];
                                                  continuePressed = false;
                                                  nextImagePressed = false;
                                                });
                                                await pickImage(false, true);
                                              });
                                            } else {
                                              Helpers.showAlert(context,
                                                  title:
                                                      "Confirm to Complete Job?",
                                                  desc:
                                                      "Confirm后无法返回此页面进行更改，请仔细检查所有细节是否正确。\n\n 你确定这是免收费的吗？",
                                                  hasAction: true,
                                                  okTitle: "Confirm",
                                                  maxWidth: 600.0,
                                                  customImage: Image(
                                                      image: AssetImage(
                                                          'assets/images/info.png'),
                                                      width: 50,
                                                      height: 50),
                                                  hasCancel: true,
                                                  onPressed: () async {
                                                Navigator.pop(context);
                                                setState(() {
                                                  images = [];
                                                  continuePressed = false;
                                                  nextImagePressed = false;
                                                });
                                                await pickImage(false, true);
                                              });
                                            }
                                          }
                                        })
                                    : (selectedJob!.status == "COMPLETED" && !(selectedJob?.jobOrderHasPayment ?? true))
                                        ? ElevatedButton(
                                            child: Padding(
                                                padding: const EdgeInsets.all(0.0),
                                                child: Row(
                                                  children: [
                                                    const Text(
                                                      'Complete Payment',
                                                      style: TextStyle(
                                                          fontSize: 15,
                                                          color: Colors.white),
                                                    )
                                                  ],
                                                )),
                                            style: ButtonStyle(foregroundColor: MaterialStateProperty.all<Color>(Colors.green), backgroundColor: MaterialStateProperty.all<Color>(Colors.green), shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0), side: const BorderSide(color: Colors.green)))),
                                            onPressed: () async {
                                              var res =
                                                  validateIfEditedValuesAreSaved();

                                              if (res) {
                                                Navigator.pushNamed(
                                                        context, 'signature',
                                                        arguments: selectedJob)
                                                    .then((val) async {
                                                  if ((val as bool)) {
                                                    await refreshJobDetails();
                                                  }
                                                });
                                              }
                                            })
                                        : new Container(),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width *
                                0.15, // <-- match_parent
                            height: MediaQuery.of(context).size.width *
                                0.05, // <-- match-parent
                            child: true
                                ? ElevatedButton(
                                    child: Padding(
                                        padding: const EdgeInsets.all(0.0),
                                        child: Row(children: [
                                          const Icon(
                                            // <-- Icon
                                            Icons.camera_alt_outlined,
                                            color: Colors.white,
                                            size: 18.0,
                                          ),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          const Text(
                                            'KIV',
                                            style: const TextStyle(
                                                fontSize: 15,
                                                color: Colors.white),
                                          )
                                        ])),
                                    style: ButtonStyle(
                                        foregroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.lightBlue),
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.lightBlue),
                                        shape: MaterialStateProperty.all<
                                                RoundedRectangleBorder>(
                                            RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4.0),
                                                side: const BorderSide(
                                                    color: Colors.lightBlue)))),
                                    onPressed: () async {
                                      var res =
                                          validateIfEditedValuesAreSaved();

                                      if (res) {
                                        setState(() {
                                          images = [];
                                          continuePressed = false;
                                          nextImagePressed = false;
                                        });
                                        await pickImage(true, false);
                                      }
                                    })
                                : new Container(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
            ]),
          ),
          Container(
              padding: EdgeInsets.all(30),
              color: Colors.white,
              child: Column(children: [
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
                            RichText(
                              text: const TextSpan(
                                  // Note: Styles for TextSpans must be explicitly defined.
                                  // Child text spans will inherit styles from parent
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    color: Colors.black,
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: 'Job Description',
                                    ),
                                  ]),
                            ),
                            const SizedBox(height: 10),
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
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                buildProductInfo(),
                const SizedBox(height: 20),
                Divider(),
                const SizedBox(height: 20),
                buildIssueInfo(),
                const SizedBox(height: 20),
                true
                    ? _renderStartButton()
                    : (selectedJob!.status.toString() != "KIV" &&
                            selectedJob!.status.toString() != "CANCELLED")
                        ? _renderPartsAndService()
                        : new Container(),
                SizedBox(
                  height: 5,
                ),
                true ? Divider(color: Colors.grey) : new Container(),
                true ? _renderSolutions() : new Container()
              ]))
        ]),
      ),
    );
  }

  showActionFailedAlert() {
    Widget okButton = TextButton(
      child: Text("Ok"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text("Error"),
      content: Text("Could not complete the action. Please retry."),
      actions: [okButton],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  showActionEmptyAlert() {
    Widget okButton = TextButton(
      child: Text("Ok"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text("Error"),
      content: Text("Following values cannot be empty."),
      actions: [okButton],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  _renderStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 50.0,
      child: ElevatedButton(
          child: const Padding(
              padding: EdgeInsets.all(0.0),
              child: Text(
                'Job Start',
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
            var res = validateIfEditedValuesAreSaved();

            if (res) {
              setState(() {
                images = [];
                continuePressed = false;
                nextImagePressed = false;
              });
              await pickImage(false, false);
            }
          }),
    );
  }

  Future<void> pickImage(bool isKIV, bool isComplete) async {
    images = [];

    await showMultipleImagesPromptDialog(context, true, isKIV, isComplete);
  }

  _renderSolutions() {
    return Column(children: [
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
                  const SizedBox(height: 25),
                  true
                      ? RichText(
                          text: const TextSpan(
                              // Note: Styles for TextSpans must be explicitly defined.
                              // Child text spans will inherit styles from parent
                              style: TextStyle(
                                fontSize: 20.0,
                                color: Colors.black,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: 'Select Solution',
                                ),
                              ]),
                        )
                      : new Container(),
                  const SizedBox(height: 10),
                  true
                      ? DropdownButtonFormField<String>(
                          isExpanded: true,
                          items: solutionLabels.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (element) async {
                            Helpers.showAlert(context);
                            var index =
                                solutionLabels.indexOf(element.toString());
                            var res = await Repositories.updateSolutionOfJob(
                                selectedJob!.id ?? 0,
                                solutions[index].solutionId ?? 0);
                            await refreshJobDetails();
                            Navigator.pop(context);
                          },
                          decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 7, horizontal: 3),
                              border: OutlineInputBorder(
                                borderRadius: const BorderRadius.all(
                                  const Radius.circular(5.0),
                                ),
                              ),
                              filled: true,
                              hintStyle: TextStyle(color: Colors.grey[800]),
                              hintText: "Please Select a Solution",
                              fillColor: Colors.white),
                          //value: dropDownValue,
                        )
                      : new Container(),
                  SizedBox(height: 20),
                  true
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(0.0),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    true
                                        ? RichText(
                                            text: const TextSpan(
                                              style: TextStyle(
                                                fontSize: 12.0,
                                                color: Colors.black54,
                                              ),
                                              children: <TextSpan>[
                                                const TextSpan(
                                                  text: 'SOLUTION CODE',
                                                ),
                                              ],
                                            ),
                                          )
                                        : new Container(),
                                    true
                                        ? SizedBox(
                                            height: 5,
                                          )
                                        : new Container(),
                                    true
                                        ? RichText(
                                            text: TextSpan(
                                              style: TextStyle(
                                                fontSize: 14.0,
                                                color: Colors.black,
                                              ),
                                              children: <TextSpan>[
                                                TextSpan(
                                                  text: "555",
                                                ),
                                              ],
                                            ),
                                          )
                                        : new Container(),
                                  ],
                                ),
                              ),
                            ),
                            Flexible(
                              fit: FlexFit.tight,
                              child: Padding(
                                padding: const EdgeInsets.all(0.0),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    true
                                        ? RichText(
                                            text: const TextSpan(
                                              style: TextStyle(
                                                fontSize: 12.0,
                                                color: Colors.black54,
                                              ),
                                              children: <TextSpan>[
                                                const TextSpan(
                                                  text: 'SOLUTION',
                                                ),
                                              ],
                                            ),
                                          )
                                        : new Container(),
                                    true
                                        ? SizedBox(
                                            height: 5,
                                          )
                                        : new Container(),
                                    true
                                        ? RichText(
                                            text: TextSpan(
                                              style: TextStyle(
                                                fontSize: 14.0,
                                                color: Colors.black,
                                              ),
                                              children: <TextSpan>[
                                                TextSpan(
                                                  text: "solu",
                                                ),
                                              ],
                                            ),
                                          )
                                        : new Container(),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 50,
                            ),
                            true
                                ? SizedBox(
                                    width: 70,
                                    height: 40.0,
                                    child: ElevatedButton(
                                        child: const Padding(
                                            padding: EdgeInsets.all(0.0),
                                            child: Text(
                                              'Clear',
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.white),
                                            )),
                                        style: ButtonStyle(
                                            foregroundColor:
                                                MaterialStateProperty.all<Color>(
                                                    Color(0xFF242A38)),
                                            backgroundColor:
                                                MaterialStateProperty.all<Color>(
                                                    Color(0xFF242A38)),
                                            shape: MaterialStateProperty.all<
                                                    RoundedRectangleBorder>(
                                                RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(
                                                        4.0),
                                                    side: const BorderSide(
                                                        color: Color(0xFF242A38))))),
                                        onPressed: () async {
                                          Helpers.showAlert(context);
                                          await Repositories
                                              .updateSolutionOfJob(
                                                  selectedJob!.id ?? 0, 0);
                                          Navigator.pop(context);
                                          Helpers.showAlert(context);
                                          await refreshJobDetails();
                                          Navigator.pop(context);
                                        }),
                                  )
                                : new Container(),
                          ],
                        )
                      : new Container(),
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
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      true ? const Divider(color: Colors.grey) : new Container(),
    ]);
  }

  _renderErrorUpdateValues() {
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Error"),
      content: Text("Values could not be updated"),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  _renderPartsAndService() {
    return Column(
      children: [
        Row(
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.black,
                ),
                children: <TextSpan>[
                  const TextSpan(
                    text: 'Parts & Service',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            FlutterSwitch(
              activeColor: Colors.green,
              inactiveColor: Colors.red,
              activeTextColor: Colors.white,
              inactiveTextColor: Colors.white,
              activeText: "Chargeable",
              inactiveText: "Not Chargeable",
              value: isChargeable,
              valueFontSize: 14.0,
              width: 170,
              borderRadius: 30.0,
              showOnOff: true,
              onToggle: (val) async {
                if (selectedJob!.status != "COMPLETED") {
                  Helpers.showAlert(context);
                  var result =
                      await Repositories.toggleChargable(selectedJob!.id ?? 0);
                  setState(() {
                    selectedJob?.isChargeable = isChargeable;
                  });

                  if (result) {
                    setState(() {
                      isPartsEditable = false;
                      isGeneralCodeEditable = false;
                      this.isChargeable = val;
                    });
                  } else {
                    //TODO throw error
                  }
                  Navigator.pop(context);
                  await refreshJobDetails();
                }
              },
            ),
          ],
        ),
        Row(
          children: [
            selectedJob != null
                ? (selectedJob!.isUnderWarranty ?? false
                    ? Icon(
                        // <-- Icon
                        Icons.check_circle,
                        color: Colors.green,
                        size: 25.0,
                      )
                    : Icon(
                        // <-- Icon
                        Icons.cancel,
                        color: Colors.red,
                        size: 25.0,
                      ))
                : new Container(),
            SizedBox(
              width: 5,
            ),
            (selectedJob?.isUnderWarranty ?? false)
                ? RichText(
                    text: const TextSpan(
                        // Note: Styles for TextSpans must be explicitly defined.
                        // Child text spans will inherit styles from parent
                        style: TextStyle(
                          fontSize: 15.0,
                          color: Colors.black,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: 'Under warranty',
                          ),
                        ]),
                  )
                : RichText(
                    text: const TextSpan(
                        // Note: Styles for TextSpans must be explicitly defined.
                        // Child text spans will inherit styles from parent
                        style: TextStyle(
                          fontSize: 15.0,
                          color: Colors.black,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: 'Not under warranty',
                          ),
                        ]),
                  )
          ],
        ),
        SizedBox(
          height: 5,
        ),
        (selectedJob?.jobSpareParts != null &&
                (selectedJob?.jobSpareParts!.length ?? 0) > 0)
            ? Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  (!isPartsEditable && selectedJob!.status != "COMPLETED")
                      ? ElevatedButton(
                          child: const Padding(
                              padding: EdgeInsets.all(0.0),
                              child: Text(
                                'Edit',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.white),
                              )),
                          style: ButtonStyle(
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  Color(0xFF242A38)),
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Color(0xFF242A38)),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                      side: const BorderSide(
                                          color: Color(0xFF242A38))))),
                          onPressed: () => {
                                setState(() {
                                  isPartsEditable = true;
                                })
                              })
                      : new Container(),
                  isPartsEditable
                      ? ElevatedButton(
                          child: const Padding(
                              padding: EdgeInsets.all(0.0),
                              child: Text(
                                'Save Changes',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.white),
                              )),
                          style: ButtonStyle(
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  Color(0xFF242A38)),
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Color(0xFF242A38)),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                      side: const BorderSide(
                                          color: Color(0xFF242A38))))),
                          onPressed: () async {
                            bool isError = false;
                            selectedJob!.jobSpareParts?.forEach((element) {
                              if (element.quantity == "" ||
                                  element.discount == "") {
                                isError = true;
                              }
                            });
                            if (isError) {
                              showActionEmptyAlert();
                            } else {
                              var res = await this.updateSpareParts();
                              await this.refreshJobDetails();
                              if (!res) {
                                await _renderErrorUpdateValues();
                              }
                              setState(() {
                                isPartsEditable = false;
                              });
                            }
                          })
                      : new Container(),
                  isPartsEditable
                      ? SizedBox(
                          width: 30,
                        )
                      : new Container(),
                  isPartsEditable
                      ? ElevatedButton(
                          child: const Padding(
                              padding: EdgeInsets.all(0.0),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.white),
                              )),
                          style: ButtonStyle(
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  Color(0xFF242A38)),
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Color(0xFF242A38)),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                      side: const BorderSide(
                                          color: Color(0xFF242A38))))),
                          onPressed: () async {
                            await refreshJobDetails();
                            setState(() {
                              isPartsEditable = false;
                            });
                          })
                      : new Container(),
                ],
              )
            : new Container(),
        Container(
          width: double.infinity,
          //padding: EdgeInsets.symmetric(horizontal: 10),
          //height: MediaQuery.of(context).size.height * 0.3,
          child: false
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      //height: MediaQuery.of(context).size.height * 0.2,
                      child: ListView.builder(
                        // physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        // shrinkWrap: false,
                        itemCount: selectedJob?.jobSpareParts!.length,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (BuildContext context, int index) {
                          return AddPartItem(
                              width: MediaQuery.of(context).size.width * 0.5,
                              part: (selectedJob!.jobSpareParts!
                                  .elementAt(index)),
                              index: index,
                              jobId: (selectedJob!.id ?? 0),
                              editable: isPartsEditable ? true : false,
                              partList: (selectedJob!.jobSpareParts ?? []),
                              onDeletePressed: () async {
                                await refreshJobDetails();
                              },
                              job: selectedJob ?? new Job());
                        },
                      ),
                    ),
                    true
                        ? Container(
                            alignment: Alignment.centerLeft,
                            child: RichText(
                              text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    color: Colors.black,
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: 'General Code',
                                    ),
                                  ]),
                            ),
                          )
                        : new Container(),
                    true
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              !isGeneralCodeEditable
                                  ? ElevatedButton(
                                      child: const Padding(
                                          padding: EdgeInsets.all(0.0),
                                          child: Text(
                                            'Edit',
                                            style: TextStyle(
                                                fontSize: 15,
                                                color: Colors.white),
                                          )),
                                      style: ButtonStyle(
                                          foregroundColor:
                                              MaterialStateProperty.all<Color>(
                                                  Color(0xFF242A38)),
                                          backgroundColor:
                                              MaterialStateProperty.all<Color>(
                                                  Color(0xFF242A38)),
                                          shape: MaterialStateProperty.all<
                                                  RoundedRectangleBorder>(
                                              RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(
                                                      4.0),
                                                  side: const BorderSide(
                                                      color: Color(0xFF242A38))))),
                                      onPressed: () => {
                                            setState(() {
                                              isGeneralCodeEditable = true;
                                            })
                                          })
                                  : new Container(),
                              isGeneralCodeEditable
                                  ? ElevatedButton(
                                      child: const Padding(
                                          padding: EdgeInsets.all(0.0),
                                          child: Text(
                                            'Save Changes',
                                            style: TextStyle(
                                                fontSize: 15,
                                                color: Colors.white),
                                          )),
                                      style: ButtonStyle(
                                          foregroundColor:
                                              MaterialStateProperty.all<Color>(
                                                  Color(0xFF242A38)),
                                          backgroundColor:
                                              MaterialStateProperty.all<Color>(
                                                  Color(0xFF242A38)),
                                          shape: MaterialStateProperty.all<
                                                  RoundedRectangleBorder>(
                                              RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(
                                                      4.0),
                                                  side: const BorderSide(
                                                      color: Color(0xFF242A38))))),
                                      onPressed: () async {
                                        bool isError = false;
                                        Helpers.editableGeneralCodes
                                            .forEach((element) {
                                          if (element.price == "") {
                                            isError = true;
                                          }
                                        });
                                        if (isError) {
                                          showActionEmptyAlert();
                                        } else {
                                          var res = await this
                                              .updateGeneralCodePrice();
                                          await this.refreshJobDetails();
                                          if (!res) {
                                            await _renderErrorUpdateValues();
                                          } else {
                                            setState(() {
                                              isGeneralCodeEditable = false;
                                            });
                                          }
                                        }
                                      })
                                  : new Container(),
                              // isGeneralCodeEditable
                              //     ? SizedBox(
                              //         width: 30,
                              //       )
                              //     : new Container(),
                              // isGeneralCodeEditable
                              //     ? ElevatedButton(
                              //         child: const Padding(
                              //             padding: EdgeInsets.all(0.0),
                              //             child: Text(
                              //               'Cancel',
                              //               style: TextStyle(
                              //                   fontSize: 15,
                              //                   color: Colors.white),
                              //             )),
                              //         style: ButtonStyle(
                              //             foregroundColor:
                              //                 MaterialStateProperty.all<Color>(
                              //                     Color(0xFF242A38)),
                              //             backgroundColor:
                              //                 MaterialStateProperty.all<Color>(
                              //                     Color(0xFF242A38)),
                              //             shape: MaterialStateProperty.all<
                              //                     RoundedRectangleBorder>(
                              //                 RoundedRectangleBorder(
                              //                     borderRadius: BorderRadius.circular(
                              //                         4.0),
                              //                     side: const BorderSide(
                              //                         color: Color(0xFF242A38))))),
                              //         onPressed: () async {
                              //           await refreshJobDetails();
                              //           setState(() {
                              //             isGeneralCodeEditable = false;
                              //           });
                              //         })
                              //     : new Container(),
                            ],
                          )
                        : new Container(),
                    // selectedJob!.generalCodes != null &&
                    //         selectedJob!.generalCodes!.length > 0
                    //     ? Container(
                    //         padding: const EdgeInsets.symmetric(horizontal: 10),
                    //         //height: MediaQuery.of(context).size.height * 0.2,
                    //         child: ListView.builder(
                    //           physics: NeverScrollableScrollPhysics(),
                    //           shrinkWrap: true,
                    //           // shrinkWrap: false,
                    //           itemCount: selectedJob?.generalCodes!.length,
                    //           itemBuilder: (BuildContext context, int index) {
                    //             return GeneralCodeItem(
                    //               width:
                    //                   MediaQuery.of(context).size.width * 0.5,
                    //               generalCode: (selectedJob!.generalCodes!
                    //                   .elementAt(index)),
                    //               jobId: (selectedJob!.id ?? 0),
                    //               job: selectedJob ?? new Job(),
                    //               index: index,
                    //               generalCodes:
                    //                   (selectedJob!.generalCodes ?? []),
                    //               editable: isGeneralCodeEditable,
                    //               isDeletePressed: () async {
                    //                 await refreshJobDetails();
                    //               },
                    //             );
                    //           },
                    //         ),
                    //       )
                    //     : new Container(),
                    const SizedBox(
                      height: 30,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          alignment: Alignment.centerLeft,
                          child: selectedJob!.status != "COMPLETED"
                              ? ElevatedButton(
                                  child: const Padding(
                                      padding: EdgeInsets.all(0.0),
                                      child: Text(
                                        'Add Parts',
                                        style: TextStyle(
                                            fontSize: 15, color: Colors.white),
                                      )),
                                  style: ButtonStyle(
                                      foregroundColor:
                                          MaterialStateProperty.all<Color>(
                                              Color(0xFF242A38)),
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                              Color(0xFF242A38)),
                                      shape: MaterialStateProperty.all<
                                              RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4.0),
                                              side: const BorderSide(
                                                  color: Color(0xFF242A38))))),
                                  onPressed: () => {
                                        Navigator.pushNamed(
                                                context, 'warehouse',
                                                arguments: Helpers.selectedJob)
                                            .then((val) async {
                                          await refreshJobDetails();
                                        })
                                      })
                              : new Container(),
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: new Container(),
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: new Container(),
                        ),
                        Container(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                          text: const TextSpan(
                                              // Note: Styles for TextSpans must be explicitly defined.
                                              // Child text spans will inherit styles from parent
                                              style: TextStyle(
                                                fontSize: 17.0,
                                                color: Colors.black,
                                              ),
                                              children: <TextSpan>[
                                                TextSpan(
                                                  text: 'SUBTOTAL',
                                                ),
                                              ]),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        RichText(
                                          text: const TextSpan(
                                              // Note: Styles for TextSpans must be explicitly defined.
                                              // Child text spans will inherit styles from parent
                                              style: TextStyle(
                                                fontSize: 17.0,
                                                color: Colors.black,
                                              ),
                                              children: <TextSpan>[
                                                TextSpan(
                                                  text: 'TAX',
                                                ),
                                              ]),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        RichText(
                                          text: const TextSpan(
                                              // Note: Styles for TextSpans must be explicitly defined.
                                              // Child text spans will inherit styles from parent
                                              style: TextStyle(
                                                  fontSize: 17.0,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold),
                                              children: <TextSpan>[
                                                const TextSpan(
                                                  text: 'TOTAL',
                                                ),
                                              ]),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          80.0, 0, 0, 0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          RichText(
                                            text: TextSpan(
                                                // Note: Styles for TextSpans must be explicitly defined.
                                                // Child text spans will inherit styles from parent
                                                style: TextStyle(
                                                  fontSize: 17.0,
                                                  color: Colors.black,
                                                ),
                                                children: <TextSpan>[
                                                  TextSpan(
                                                    text: '\$50',
                                                  ),
                                                ]),
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          RichText(
                                            text: TextSpan(
                                                // Note: Styles for TextSpans must be explicitly defined.
                                                // Child text spans will inherit styles from parent
                                                style: TextStyle(
                                                  fontSize: 14.0,
                                                  color: Colors.black,
                                                ),
                                                children: <TextSpan>[
                                                  TextSpan(
                                                    text: '\$50',
                                                  ),
                                                ]),
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          RichText(
                                            text: TextSpan(
                                                // Note: Styles for TextSpans must be explicitly defined.
                                                // Child text spans will inherit styles from parent
                                                style: TextStyle(
                                                  fontSize: 17.0,
                                                  color: Colors.black,
                                                ),
                                                children: <TextSpan>[
                                                  TextSpan(
                                                    text: '\$100',
                                                  ),
                                                ]),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                                padding: EdgeInsets.fromLTRB(280, 0, 0, 0))),
                      ],
                    )
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    true
                        ? Container(
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 50,
                                ),
                                Icon(
                                  // <-- Icon
                                  Icons.indeterminate_check_box,
                                  color: Colors.grey,
                                  size: 130.0,
                                ),
                                RichText(
                                  text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 30.0,
                                        color: Colors.black,
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: 'No data found',
                                        ),
                                      ]),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Container(
                                  alignment: Alignment.center,
                                  width: 400,
                                  child: RichText(
                                    text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 15.0,
                                          color: Colors.black,
                                        ),
                                        children: <TextSpan>[
                                          TextSpan(
                                            text:
                                                'There is currently no parts listed selected.',
                                          ),
                                        ]),
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                ElevatedButton(
                                    child: const Padding(
                                        padding: EdgeInsets.all(0.0),
                                        child: Text(
                                          'Add Parts',
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.white),
                                        )),
                                    style: ButtonStyle(
                                        foregroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.black87),
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.black87),
                                        shape: MaterialStateProperty.all<
                                                RoundedRectangleBorder>(
                                            RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4.0),
                                                side: const BorderSide(
                                                    color: Colors.black87)))),
                                    onPressed: () => {
                                          Navigator.pushNamed(
                                                  context, 'warehouse',
                                                  arguments:
                                                      Helpers.selectedJob)
                                              .then((val) async {
                                            await refreshJobDetails();
                                          })
                                        }),
                              ],
                            ))
                        : new Container(),
                  ],
                ),
        )
      ],
    );
  }

  Future<bool> updateGeneralCodePrice() async {
    Helpers.showAlert(context);
    bool isError = false;
    Helpers.editableGeneralCodes.forEach((element) {
      if (element.price == "") {
        isError = true;
      }
    });

    if (isError) {
      Navigator.pop(context);
      showActionEmptyAlert();
      return false;
    } else {
      var res = await Repositories.updateGeneralCodes(
          (selectedJob!.id ?? 0), Helpers.editableGeneralCodes);
      Navigator.pop(context);
      return res;
    }
  }

  Future<bool> updateSpareParts() async {
    Helpers.showAlert(context);
    var spareParts = await getJobSparePartItems();
    var res = await Repositories.addSparePartsToJob(
        (selectedJob!.id ?? 0), spareParts);
    Navigator.pop(context);
    return res;
  }

  Future<List<SparePart>> getJobSparePartItems() async {
    List<SparePart> spareParts = [];
    SparePart sparePart;
    for (int i = 0; i < selectedJob!.jobSpareParts!.length; i++) {
      sparePart = new SparePart();
      sparePart.sparepartsId = selectedJob!.jobSpareParts![i].sparePartId;
      sparePart.discount =
          double.parse(selectedJob!.jobSpareParts![i].discount ?? "0.0");
      sparePart.quantity =
          double.parse(selectedJob!.jobSpareParts![i].quantity ?? "0.0")
              .round();
      spareParts.add(sparePart);
    }

    return spareParts;
  }

  showImagePrompt() {}

  showImageViewerPromptDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ImageViewerDialog(
            imgScaffoldKey: _imgScaffoldKey,
            attachments: selectedJob?.attachments?.map((key, value) => MapEntry(
                    key,
                    (value as List).map((item) => item as String).toList())) ??
                new Map<String, List<String>>());
      },
    ).then((value) async {
      // if (isComplete) {
      //   if (value) {
      //     Navigator.pushNamed(context, 'signature', arguments: selectedJob)
      //         .then((val) async {
      //       if ((val as bool)) {
      //         Navigator.pop(context);
      //       }
      //     });
      //   } else {
      //     Helpers.showAlert(context,
      //         hasAction: true,
      //         title: "Could complete the Job", onPressed: () async {
      //       await refreshJobDetails();
      //       Navigator.pop(context);
      //     });
      //   }
      // } else {
      //   await this.refreshJobDetails();
      // }
    });
  }

  showMultipleImagesPromptDialog(
      BuildContext context, bool initial, bool isKIV, bool isComplete) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return MultiImageUploadDialog(
            isKiv: isKIV,
            isComplete: isComplete,
            selectedJob: selectedJob ?? new Job());
      },
    ).then((value) async {
      if (isComplete) {
        if (value != null && value) {
          Navigator.pushNamed(context, 'signature', arguments: selectedJob)
              .then((val) async {
            if ((val as bool)) {
              Navigator.pop(context);
            }
          });
        } else {
          Helpers.showAlert(context,
              hasAction: true,
              title: "Could not complete the Job",
              type: "error", onPressed: () async {
            await refreshJobDetails();
            Navigator.pop(context);
          });
        }
      } else {
        await this.refreshJobDetails();
      }
    });
  }

  _fetchJobs() async {
    User? user;
    if (Helpers.loggedInUser != null) {
      user = Helpers.loggedInUser;
    }

    final response = await Api.bearerGet('job-orders/with-relationship');
    print("#Resp: ${jsonEncode(response)}");
    // Navigator.pop(context);
    if (response["success"] != null) {
      if (user == null) {
        user = new User();
      }

      user!.allJobsCount = response["meta"]?["allJobsCount"];
      user!.completedJobsCount = response["meta"]?["completedJobsCount"];
      user!.uncompletedJobsCount = response["meta"]?["uncompletedJobsCount"];

      var fetchedJobs = (response['data'] as List)
          .map((i) => Job.jobListfromJson(i))
          .toList();

      fetchedJobs.sort((a, b) => int.parse((a.sequence ?? "100"))
          .compareTo(int.parse(b.sequence ?? "100")));

      List<Job> completed = [];
      List<Job> inProgress = [];

      for (int i = 0; i < fetchedJobs.length; i++) {
        if (fetchedJobs[i].status == "IN PROGRESS" ||
            fetchedJobs[i].status == "PENDING REPAIR") {
          inProgress.add(fetchedJobs[i]);
        } else {
          completed.add(fetchedJobs[i]);
        }
      }
      setState(() {
        Helpers.completedJobs = completed;
        Helpers.inProgressJobs = inProgress;
        Helpers.loggedInUser = user;
      });
      //await updateJobSequence();
    } else {
      //show ERROR
    }
  }

  _renderError() {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      // SizedBox(height: 10),
      const SizedBox(height: 20),
    ]);
  }

  Future<bool> _onWillPop() async {
    var res = validateIfEditedValuesAreSaved();
    if (res) {
      Navigator.pop(context);
      return true;
    } else {
      return false;
    }
  }

  refreshJobDetails() async {
    Helpers.showAlert(context);
    Job? job = await Repositories.fetchJobDetails(jobId: selectedJob!.id);

    setState(() {
      selectedJob = job;
      isChargeable = job!.isChargeable ?? false;
      if (selectedJob != null) {
        serialNoController.text =
            ((selectedJob!.serialNo != null ? selectedJob!.serialNo : "-") ??
                "-");
        remarksController.text =
            ((selectedJob!.comment != null ? selectedJob!.comment : "-") ??
                "-");
      }
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onWillPop,
        child: RefreshIndicator(
            key: _refreshKey,
            onRefresh: () async {
              await this.refreshJobDetails();
            },
            child: Scaffold(
              key: _scaffoldKey,
              appBar: Helpers.customAppBar(context, _scaffoldKey,
                  title: "Job Details",
                  isBack: true,
                  isAppBarTranparent: true,
                  hasActions: false, handleBackPressed: () {
                var res = validateIfEditedValuesAreSaved();
                if (res) {
                  Navigator.pop(context);
                }
              }),
              body: ExpandableBottomSheet(
                //use the key to get access to expand(), contract() and expansionStatus
                key: key,

                onIsContractedCallback: () => print('contracted'),
                onIsExtendedCallback: () => print('extended'),
                animationDurationExtend: Duration(milliseconds: 500),
                animationDurationContract: Duration(milliseconds: 250),
                animationCurveExpand: Curves.bounceOut,
                animationCurveContract: Curves.ease,
                persistentContentHeight:
                    isExpanded ? MediaQuery.of(context).size.height * .15 : 0,
                background: Stack(children: [
                  CustomPaint(
                      child: SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 10),
                              decoration: new BoxDecoration(
                                  color: Colors.white.withOpacity(0.0)),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    errorMsg != ""
                                        ? _renderError()
                                        : Container(),
                                    _renderForm(),
                                    const SizedBox(height: 10),
                                    //Expanded(child: _renderBottom()),
                                    //version != "" ? _renderVersion() : Container()
                                  ])))),
                  isExpanded
                      ? GestureDetector(
                          onTap: () {
                            setState(() {
                              isExpanded = false;
                            });
                          },
                          child: IgnorePointer(
                            child: BackdropFilter(
                              filter:
                                  ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                              child: Container(
                                width: 200.0,
                                height: 200.0,
                                color: Colors.transparent,
                                child: Center(
                                  child: Text(
                                    'Blurred Content',
                                    style: TextStyle(
                                      fontSize: 20.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ))
                      : new Container(),
                ]),
                expandableContent: isExpanded
                    ? Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          border:
                              Border.all(color: Colors.grey[400]!, width: 1),
                          color: Colors.white,
                        ),
                        width: MediaQuery.of(context).size.width * 1,
                        child: SingleChildScrollView(
                          child: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 30),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
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
                                                text: 'Checklist Attachment',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ]),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 300,
                                  ),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    child: RichText(
                                      textAlign: TextAlign.left,
                                      text: TextSpan(
                                          style: const TextStyle(
                                            fontSize: 20.0,
                                            color: Colors.black,
                                          ),
                                          children: <TextSpan>[
                                            TextSpan(
                                                text: 'Comments',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ]),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.0),
                                      border: Border.all(
                                          color: Colors.grey[400]!, width: 1),
                                      color: Colors.white,
                                    ),
                                    height: MediaQuery.of(context).size.height *
                                        0.2,
                                    alignment: Alignment.centerLeft,
                                    child: Column(children: [
                                      Container(
                                          padding:
                                              EdgeInsets.fromLTRB(20, 0, 20, 0),
                                          child: TextFormField(
                                            maxLines: 10,
                                            textInputAction:
                                                TextInputAction.newline,
                                            // focusNode: focusEmail,
                                            keyboardType:
                                                TextInputType.multiline,
                                            validator: (value) {},
                                            // controller: emailCT,
                                            onFieldSubmitted: (val) {
                                              FocusScope.of(context)
                                                  .requestFocus(
                                                      new FocusNode());
                                            },
                                            style: TextStyle(fontSize: 15),
                                          )),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              color: Colors.white,
                                              height: 40,
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.1,
                                              child: ElevatedButton(
                                                  child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5.0),
                                                      child: Text(
                                                        'CLEAR',
                                                        style: TextStyle(
                                                            fontSize: 11,
                                                            color:
                                                                Colors.white),
                                                      )),
                                                  style: ButtonStyle(
                                                      foregroundColor:
                                                          MaterialStateProperty
                                                              .all<Color>(
                                                    Color(0xFF),
                                                    // backgroundColor:
                                                    //     MaterialStateProperty.all<Color>(
                                                    //         AppColors.primary),
                                                    // shape: MaterialStateProperty.all<
                                                    //         RoundedRectangleBorder>(
                                                    //     RoundedRectangleBorder(
                                                    //         borderRadius:
                                                    //             BorderRadius.circular(5.0),
                                                    //         side: BorderSide(
                                                    //             color: AppColors.primary)))
                                                  )),
                                                  onPressed: () async {
                                                    // setState(() {
                                                    //   startDate = "";
                                                    //   endDate = "";
                                                    //   tempStartDate = "";
                                                    //   tempEndDate = "";
                                                    //   isFiltersAdded = false;
                                                    //   filterCT.text = "";
                                                    //   currentPage = 1;
                                                    // });
                                                    // await _fetchPaymentHistory(true);
                                                  }),
                                            )
                                          ])
                                    ]),
                                  ),
                                  SizedBox(
                                    height: 300,
                                  ),
                                  RichText(
                                    text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 20.0,
                                          color: Colors.black,
                                        ),
                                        children: <TextSpan>[
                                          TextSpan(
                                              text: 'Checklist Attachment',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ]),
                                  ),
                                  SizedBox(
                                    height: 300,
                                  )
                                ]),
                          ),
                        ),
                      )
                    : new Container(),
              ),
              floatingActionButton: !isExpanded
                  ? FloatingActionButton.large(
                      onPressed: () {
                        setState(() {
                          isExpanded = true;
                        });
                      },
                      foregroundColor: Color(0xFF005FF5),
                      backgroundColor: Color(0xFFFDFDFD),
                      child: const Icon(Icons.chat_outlined),
                    )
                  : new Container(),
            )));
  }
}

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

class MultiImageUploadDialog extends StatefulWidget {
  final bool isKiv;
  final bool isComplete;
  final Job selectedJob;

  MultiImageUploadDialog(
      {required this.isKiv,
      required this.isComplete,
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
  late Job selectedJob = widget.selectedJob;
  bool isImagesEmpty = false;

  processAction(bool isKIV, bool isComplete) async {
    Helpers.showAlert(context);
    var res;
    if (isKIV) {
      res = await Repositories.uploadKIV(images, this.selectedJob!.id ?? 0);
      Navigator.pop(context);
    } else if (isComplete) {
      res = await Repositories.completeJob(images, selectedJob!.id ?? 0);
      Navigator.pop(context);
      Navigator.pop(context, res);
    } else {
      res = await Repositories.startJob(images, selectedJob!.id ?? 0);
      Navigator.pop(context);
    }
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
                        images.length != 3 ? images.length + 1 : images.length,
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
                  await processAction(isKiv, isComplete);
                  Navigator.pop(context);
                }
              }),
        ),
      ],
    );
  }
}

class AddPartItem extends StatelessWidget {
  AddPartItem(
      {Key? key,
      required this.width,
      required this.part,
      required this.job,
      required this.jobId,
      required this.index,
      required this.onDeletePressed,
      required this.editable,
      required this.partList})
      : super(key: key);

  final double width;
  final JobSparePart part;
  final Job job;
  final int jobId;
  final int index;
  Function onDeletePressed;

  final bool editable;
  final List<JobSparePart> partList;
  var isRecordEditable = false;

  showAlertDialog(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () async {
        List<JobSparePart> finalArr = [];
        for (int i = 0; i < partList.length; i++) {
          if (partList[i].sparePartId == part.sparePartId) {
            partList[i].quantity = "0";
          }
        }
        await _AddSparePartsToJob(partList);
        await onDeletePressed.call();
        Navigator.pop(context);
      },
    );

    Widget cancelButton = TextButton(
      child: Text("Cancel"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text("Confirm"),
      content: Text("Are you sure to delete the selected spare part ?"),
      actions: [
        cancelButton,
        okButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<bool> _AddSparePartsToJob(List<JobSparePart> jobSpareparts) async {
    SparePart sparePart;
    List<SparePart> spareParts = [];
    jobSpareparts.forEach((element) {
      sparePart = new SparePart();
      sparePart.sparepartsId = element!.sparePartId;
      sparePart.discount = double.parse(element!.discount ?? "0.0");
      sparePart.quantity = double.parse(element!.quantity ?? "0");
      spareParts.add(sparePart);
    });

    return await Repositories.addSparePartsToJob(jobId, spareParts);
  }

  @override
  Widget build(BuildContext context) {
    var transactionId = this.part.transactionId;
    var sparePartId = this.part.sparePartId;
    var quantity = this.part.quantity;
    var discount = this.part.discount;
    var price = this.part.price;
    var sparePartCode = this.part.sparePartCode;
    var description = this.part.description;

    var quantityStr = quantity?.split(".")[0];

    var total = (((double.parse(price ?? '0') *
            double.parse((quantity != "" ? quantity : "0") ?? "0")) *
        (100 - double.parse(discount ?? '0')) /
        100));
    return Row(
      // mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        job.status != "COMPLETED"
            ? Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 40),
                child: GestureDetector(
                    onTap: () async {
                      await showAlertDialog(context);
                    },
                    child: Icon(
                      // <-- Icon
                      Icons.delete,
                      color: Colors.black54,
                      size: 25.0,
                    )),
              )
            : new Container(),
        SizedBox(
          width: 5,
        ),
        SizedBox(
          width: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 200,
                child: RichText(
                  text: TextSpan(
                      style: const TextStyle(
                        fontSize: 15.0,
                        color: Colors.black,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: '$sparePartCode',
                        ),
                      ]),
                ),
              ),
              RichText(
                text: TextSpan(
                    // Note: Styles for TextSpans must be explicitly defined.
                    // Child text spans will inherit styles from parent
                    style: const TextStyle(
                      fontSize: 15.0,
                      color: Colors.black54,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: '$description',
                      ),
                    ]),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
        SizedBox(
          width: 10,
        ),
        !editable
            ? SizedBox(
                width: 90,
                child: Container(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: RichText(
                    text: TextSpan(
                        // Note: Styles for TextSpans must be explicitly defined.
                        // Child text spans will inherit styles from parent
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.black54,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: quantity == "1.0"
                                ? '$quantityStr Unit'
                                : '$quantityStr Units',
                          ),
                        ]),
                  ),
                ),
              )
            : Container(
                width: 80,
                padding: EdgeInsets.only(bottom: 50),
                child: TextFormField(
                    //focusNode: focusEmail,
                    keyboardType: TextInputType.number,
                    onChanged: (str) {
                      Helpers.editableJobSpareParts[index].quantity = str;
                    },
                    onEditingComplete: () {},
                    onFieldSubmitted: (val) {
                      FocusScope.of(context).requestFocus(new FocusNode());
                    },
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp("[0-9a-zA-Z]")),
                    ],
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.black54,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      //suffixText: quantity == 1 ? ' Unit' : ' Units',
                      hintText: '$quantity'.split(".")[0],
                      hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7)),
                      contentPadding: EdgeInsets.fromLTRB(20, 5, 0, 0),
                    )),
              ),
        SizedBox(
          width: 10,
        ),
        SizedBox(
          width: 70,
          child: Container(
            padding: const EdgeInsets.only(bottom: 50),
            child: RichText(
              text: TextSpan(
                  // Note: Styles for TextSpans must be explicitly defined.
                  // Child text spans will inherit styles from parent
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.black54,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: '\$' +
                          double.parse(price ?? "0").toStringAsFixed(2) +
                          ((double.parse(price ?? "0")
                                      .toStringAsFixed(2)
                                      .split(".")[1]
                                      .length ==
                                  1)
                              ? "0"
                              : ""),
                    ),
                  ]),
            ),
          ),
        ),
        !editable
            ? Container(
                padding: const EdgeInsets.fromLTRB(30, 0, 0, 50),
                child: RichText(
                  text: TextSpan(
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Colors.black54,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: discount != null
                              ? (discount.split(".")[0] + "%")
                              : ("0%"),
                        ),
                      ]),
                ),
              )
            : Container(
                width: 90,
                padding: EdgeInsets.only(bottom: 50),
                child: TextFormField(
                    //focusNode: focusEmail,
                    keyboardType: TextInputType.number,
                    onChanged: (str) {
                      Helpers.editableJobSpareParts[index].discount = str;
                    },
                    onEditingComplete: () {},
                    onFieldSubmitted: (val) {
                      FocusScope.of(context).requestFocus(new FocusNode());
                    },
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp("[0-9a-zA-Z]")),
                    ],
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.black54,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7)),
                      hintText: discount != null
                          ? (discount.split(".")[0] + "%")
                          : ("0%"),
                      contentPadding: EdgeInsets.fromLTRB(20, 5, 0, 0),
                    )),
              ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.only(bottom: 50),
          child: RichText(
            text: TextSpan(
                // Note: Styles for TextSpans must be explicitly defined.
                // Child text spans will inherit styles from parent
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.black54,
                ),
                children: <TextSpan>[
                  TextSpan(text: '\$' + total.toStringAsFixed(2)),
                  //text: '\$100')
                ]),
          ),
        ),
      ],
    );
  }
}

class GeneralCodeItem extends StatelessWidget {
  const GeneralCodeItem({
    Key? key,
    required this.width,
    required this.generalCode,
    required this.generalCodes,
    required this.jobId,
    required this.job,
    required this.index,
    required this.editable,
    required this.isDeletePressed,
  }) : super(key: key);

  final double width;
  final JobGeneralCode generalCode;
  final List<JobGeneralCode> generalCodes;
  final int jobId;
  final int index;
  final bool editable;
  final Function isDeletePressed;
  final Job job;

  showAlertDialog(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () async {
        await Repositories.deleteGeneralCodeFromJob(
            generalCode.generalCodeTransactonId ?? 0);
        await isDeletePressed.call();
        Navigator.pop(context);
      },
    );

    Widget cancelButton = TextButton(
      child: Text("Cancel"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text("Confirm"),
      content: Text("Are you sure to delete the selected general code ?"),
      actions: [
        cancelButton,
        okButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<bool> _AddGeneralCodeToJob(
      List<JobGeneralCode> jobGeneralCodes) async {
    GeneralCode generalCode;
    List<GeneralCode> generalCodes = [];
    jobGeneralCodes.forEach((element) {
      generalCode = new GeneralCode();
      generalCode.generalCodeId = element!.generalCodeId;
      generalCode.transactionId = element!.generalCodeTransactonId.toString();
      generalCode.price = element!.price;
      generalCodes.add(generalCode);
    });
    return await Repositories.addGeneralCodeToJob(jobId, generalCodes);
  }

  @override
  Widget build(BuildContext context) {
    var generalCodeItem = this.generalCode.generalCodeId;
    var description = this.generalCode.description;
    var price = this.generalCode.price;
    var itemCode = this.generalCode.itemCode;
    var type = this.generalCode.type;

    return GestureDetector(
      onTap: () async {
        //Navigator.pushNamed(context, 'productModel');
      },
      child: Row(
        // mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          job.status != "COMPLETED"
              ? Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 40),
                  child: GestureDetector(
                      onTap: () async {
                        await showAlertDialog(context);
                      },
                      child: Icon(
                        // <-- Icon
                        Icons.delete,
                        color: Colors.black54,
                        size: 25.0,
                      )),
                )
              : new Container(),
          SizedBox(
            width: 5,
          ),
          SizedBox(
            width: 300,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 200,
                  child: RichText(
                    text: TextSpan(
                        style: const TextStyle(
                          fontSize: 15.0,
                          color: Colors.black,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: '$itemCode',
                          ),
                        ]),
                  ),
                ),
                RichText(
                  text: TextSpan(
                      // Note: Styles for TextSpans must be explicitly defined.
                      // Child text spans will inherit styles from parent
                      style: const TextStyle(
                        fontSize: 15.0,
                        color: Colors.black54,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: '$description',
                        ),
                      ]),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
          SizedBox(
            width: 10,
          ),
          SizedBox(
            width: 70,
            child: Container(
              padding: const EdgeInsets.only(bottom: 50),
              child: RichText(
                text: TextSpan(
                    // Note: Styles for TextSpans must be explicitly defined.
                    // Child text spans will inherit styles from parent
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.black54,
                    ),
                    children: <TextSpan>[
                      TextSpan(text: '1 Unit'
                          // text: quantity == 1
                          //     ? '$quantity Unit'
                          //     : '$quantity Units',
                          ),
                    ]),
              ),
            ),
          ),
          SizedBox(
            width: 70,
          ),
          editable
              ? Container(
                  padding: const EdgeInsets.only(bottom: 50),
                  width: 90,
                  child: TextFormField(
                      onChanged: (str) {
                        Helpers.editableGeneralCodes[index].price = str;
                      },
                      onEditingComplete: () {},
                      //focusNode: focusEmail,
                      keyboardType: TextInputType.number,
                      // controller: emailCT,

                      onFieldSubmitted: (val) {
                        FocusScope.of(context).requestFocus(new FocusNode());
                      },
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                            RegExp("[0-9a-zA-Z]")),
                      ],
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Colors.black54,
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintStyle:
                            TextStyle(color: Colors.grey.withOpacity(0.7)),
                        hintText: '\$' +
                            double.parse((price != "" ? price : "0") ?? "0")
                                .toStringAsFixed(2) +
                            ('\$$price'.contains(".") &&
                                    ('\$$price'.split(".")[1].length == 1)
                                ? "0"
                                : ""),
                        contentPadding: EdgeInsets.fromLTRB(20, 5, 0, 0),
                      )),
                )
              : SizedBox(
                  width: 80,
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 50),
                    child: RichText(
                      text: TextSpan(
                          // Note: Styles for TextSpans must be explicitly defined.
                          // Child text spans will inherit styles from parent
                          style: TextStyle(
                            fontSize: 18.0,
                            color: Colors.black54,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: '\$' +
                                  double.parse(
                                          (price != "" ? price : "0") ?? "0")
                                      .toStringAsFixed(2),
                            ),
                          ]),
                    ),
                  ),
                ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.only(bottom: 50),
            child: RichText(
              text: TextSpan(
                  // Note: Styles for TextSpans must be explicitly defined.
                  // Child text spans will inherit styles from parent
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.black54,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                        text: "\$" +
                            double.parse((price != "" ? price : "0") ?? "0")
                                .toStringAsFixed(2))
                  ]),
            ),
          ),
        ],
      ),
    );
  }
}
