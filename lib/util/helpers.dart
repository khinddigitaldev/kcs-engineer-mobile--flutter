import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_installer/flutter_app_installer.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:kcs_engineer/model/spareparts/miscellaneousItem.dart';
import 'package:kcs_engineer/model/spareparts/sparepart.dart';
import 'package:kcs_engineer/model/user/user.dart';
import 'package:kcs_engineer/model/spareparts/job_sparepart.dart';
import 'package:kcs_engineer/model/util/app_version.dart';
import 'package:kcs_engineer/themes/app_colors.dart';
import 'package:kcs_engineer/util/repositories.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kcs_engineer/model/job/job.dart';

class Helpers {
  static void showAlert(BuildContext ctx,
      {child,
      title,
      desc,
      onPressed,
      hasAction = false,
      onCancelPressed,
      okTitle = "Ok",
      noTitle = "Cancel",
      customImage,
      maxWidth = 0.0,
      customText,
      type = "success",
      hasCancel = false}) {
    if (hasAction) {
      List<DialogButton> actionButtons = [];
      if (hasCancel) {
        actionButtons = [
          DialogButton(
            child: Text(
              noTitle != null ? noTitle : "Cancel",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            border: Border.all(width: 1, color: Colors.grey[300]!),
            color: Colors.grey[400],
            onPressed: onCancelPressed == null
                ? () => Navigator.pop(ctx)
                : () => onCancelPressed(),
          ),
          DialogButton(
            child: Text(
              okTitle != null ? okTitle : "Ok",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            color: AppColors.primary,
            onPressed: () => onPressed(),
          ),
        ];
      } else {
        actionButtons = [
          DialogButton(
            child: Text(
              okTitle != null ? okTitle : "Ok",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            onPressed: () => onPressed(),
            color: AppColors.primary,
          )
        ];
      }

      Alert(
              context: ctx,
              content: child != null ? child : new Container(),
              type: customImage == null
                  ? (type == 'success' ? AlertType.success : AlertType.error)
                  : null,
              image: customImage != null ? customImage : null,
              title: title,
              style: AlertStyle(
                  animationDuration: Duration(milliseconds: 400),
                  constraints: BoxConstraints(
                      maxWidth: maxWidth == 0.0 ? double.infinity : maxWidth)),
              desc: desc,
              buttons: actionButtons,
              alertAnimation: fadeAlertAnimation)
          .show();
    } else if (customText != null) {
      AlertDialog alert;
      alert = AlertDialog(
        content: new Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            Container(
                margin: EdgeInsets.only(left: 5), child: Text(customText)),
          ],
        ),
      );

      showDialog(
        barrierDismissible: false,
        context: ctx,
        builder: (BuildContext context) {
          return alert;
        },
      );
    } else {
      AlertDialog alert;
      alert = AlertDialog(
        content: new Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingAnimationWidget.staggeredDotsWave(
              color: Colors.black,
              size: MediaQuery.of(ctx).size.height * 0.03,
            ),
            // Container(
            //     margin: EdgeInsets.only(left: 5), child: Text("Loading...")
            //     ),
          ],
        ),
      );

      showDialog(
        barrierDismissible: false,
        context: ctx,
        builder: (BuildContext context) {
          return alert;
        },
      );
    }
  }

  static int selectedJobIndex = 0;
  static User? loggedInUser;
  static Job? selectedJob;
  static bool isAuthenticated = false;
  static List<SparePart> editableJobSpareParts = [];
  static List<Job> inProgressJobs = [];
  static List<Job> completedJobs = [];

  static List<MiscellaneousItem> editableMiscItems = [];

  static Future<bool> checkAppVersion(BuildContext context) async {
    AppVersion? version;
    version = await Repositories.fetchAppVersion();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    // if (dotenv.env["ENVIRONMENT"] == "STAGING") {
    if (version?.version.toString() == "${packageInfo.version}" &&
        version?.buildNo.toString() == "${packageInfo.buildNumber}") {
      return true;

      // }
    } else {
      displayForceUpdatePopup(context, version, packageInfo);
      return false;
    }
  }

  static displayForceUpdatePopup(
      BuildContext context, AppVersion? version, PackageInfo info) async {
    AlertDialog alert = AlertDialog(
      title: const Text(
        "Update App",
        textAlign: TextAlign.center,
      ),
      content: Container(
        height: MediaQuery.of(context).size.height * 0.2,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                  text: TextSpan(
                      style: TextStyle(fontSize: 16, color: Colors.black),
                      children: [
                    TextSpan(
                        text:
                            "A new version of your app is available! Please update the app to proceed. "),
                  ])),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.02,
              ),
              Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                        text: TextSpan(
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                            children: [
                          TextSpan(text: "Your version : "),
                        ])),
                    RichText(
                        text: TextSpan(
                            style: TextStyle(fontSize: 16, color: Colors.black),
                            children: [
                          TextSpan(text: "${info.version}"),
                        ])),
                  ]),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.015,
              ),
              Row(children: [
                RichText(
                    text: TextSpan(
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                        children: [
                      TextSpan(text: "Latest version : "),
                    ])),
                RichText(
                    text: TextSpan(
                        style: TextStyle(fontSize: 16, color: Colors.black),
                        children: [
                      TextSpan(text: "${version?.version}"),
                    ])),
              ]),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.015,
              ),
              // RichText(
              //     text: TextSpan(
              //         style: TextStyle(
              //             fontSize: 16,
              //             fontWeight: FontWeight.bold,
              //             color: Colors.black),
              //         children: [
              //       TextSpan(text: "Release Notes :"),
              //     ])),
              // ConstrainedBox(
              //     constraints: BoxConstraints(
              //         minHeight: 1,
              //         maxHeight: MediaQuery.of(context).size.height * 0.5,
              //         maxWidth: MediaQuery.of(context).size.width * 0.5,
              //         minWidth: 1),
              //     child: ListView.builder(
              //       itemCount: version?.releaseNotes?.length ?? 0,
              //       itemBuilder: (context, index) {
              //         return ListTile(
              //           leading: Icon(Icons
              //               .arrow_right), // You can use a bullet icon or any other icon
              //           title: Text(version?.releaseNotes?[index] ?? ""),
              //         );
              //       },
              //     ))
            ]),
      ),
      actions: <Widget>[
        Container(
          alignment: Alignment.center,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: Colors.amberAccent,
            ),
            child: Text(
              'Update App',
              style: TextStyle(color: Colors.black),
            ),
            onPressed: () async {
              await _downloadFile(context, version?.apkUrl ?? "");
            },
          ),
        ),
      ],
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(child: alert, onWillPop: () async => false);
      },
    );
  }

  static _downloadFile(BuildContext context, String url) async {
    ProgressDialog pd = ProgressDialog(context: context);

    try {
      Dio dio = Dio();
      String dir = (await getExternalStorageDirectory())?.path ?? "";
      String filePath = '$dir/apk/${url.split('/').last.split("?")[0]}';

      File file = File(filePath);

      if (await file.exists()) {
        file.deleteSync();
      }

      pd.show(max: 100, msg: 'Downloading...');

      await dio.download('$url', filePath,
          onReceiveProgress: (received, total) {
        int progress = (received / total * 100).toInt();
        pd.update(
            value: progress,
            msg:
                '${(received / (1024 * 1024)).toDouble().toStringAsFixed(2)}MB/${(total / (1024 * 1024)).toDouble().toStringAsFixed(2)}MB');
      });

      pd.close();

      FlutterAppInstaller.installApk(filePath: filePath);
    } catch (e) {
      print(e);
    }
  }

  static Widget fadeAlertAnimation(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return Align(
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  static AppBar customAppBar(
      BuildContext ctx, GlobalKey<ScaffoldState> scaffoldKey,
      {String title = "",
      Widget? customTitle,
      bool isBack = false,
      bool colorsInverted = false,
      hasActions = true,
      isPrimary = false,
      isBackPrimary = false,
      isAppBarTranparent = false,
      handleLocatorPressed,
      handleProfilePressed,
      handleBackPressed}) {
    return AppBar(
      leadingWidth: isBack ? 50 : 20,
      leading: isBack
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios_new,
                  color: colorsInverted ? Colors.white : AppColors.tertiery,
                  size: 20),
              onPressed: () {
                if (handleBackPressed != null) {
                  handleBackPressed();
                } else {
                  if (!isBack) {
                    scaffoldKey.currentState!.openDrawer();
                  } else {
                    Navigator.of(ctx).pop();
                  }
                }
              })
          : Container(),
      //backgroundColor: isPrimary ? AppColors.primary : Colors.transparent,
      backgroundColor:
          isAppBarTranparent ? Colors.transparent : AppColors.amber,
      elevation: 0.0,
      titleSpacing: 0,
      centerTitle: false,
      title: customTitle != null
          ? customTitle
          : Text(
              title,
              style: TextStyle(
                  color: colorsInverted ? Colors.white : AppColors.tertiery,
                  fontWeight: FontWeight.bold),
            ),
      actions: hasActions
          ? [
              new InkWell(
                  // color: Colors.transparent,
                  // icon: Image(image: AssetImage('assets/icons/location.png'), height: 22),
                  child: Icon(Icons.location_pin,
                      size: 27, color: AppColors.tertiery),
                  onTap: () {
                    if (handleLocatorPressed != null) {
                      handleLocatorPressed();
                    } else {
                      Navigator.pushNamed(ctx, 'service_locator');
                    }
                  }),
              SizedBox(width: 5),
              new InkWell(
                  child: Icon(Icons.account_circle_rounded,
                      size: 27, color: AppColors.tertiery),
                  onTap: () {
                    if (handleProfilePressed != null) {
                      handleProfilePressed();
                    } else {
                      Navigator.pushNamed(ctx, 'profile');
                    }
                  }),
              SizedBox(width: 10)
            ]
          : [],
    );
  }

  static Future<void> launchInBrowser(String url) async {
    if (!await launch(
      url,
      forceSafariVC: false,
      forceWebView: false,
      headers: <String, String>{'my_header_key': 'my_header_value'},
    )) {
      throw 'Could not launch $url';
    }
  }

  static bool checkIfEditableByJobStatus(Job? job, bool isMainEngineer) {
    bool res = false;

    if (!isMainEngineer) {
      return false;
    }

    switch (job?.serviceJobStatus?.toLowerCase()) {
      case "pending job start":
        res = true;
        break;
      case "repairing":
        res = true;
        break;
      case "kiv":
        res = true;
        break;
      case "cancelled":
        res = false;
        break;
      case "completed":
        res = false;
        break;
      case "closed":
        res = false;
        break;
      case "pending delivery":
        res = false;
        break;
    }

    return res;
  }

  static bool checkIfEditableByJobStatusForSolution(
      bool isActual, Job? job, bool isMainEngineer) {
    bool res = false;

    switch (job?.serviceJobStatus?.toLowerCase()) {
      case "pending job start":
        res = isActual ? false : true;
        break;
      case "repairing":
        res = !isActual ? false : true;
        break;
      case "kiv":
        res = true;
        break;
      case "cancelled":
        res = false;
        break;
      case "completed":
        res = false;
        break;
      case "closed":
        res = false;
        break;
      case "pending delivery":
        res = false;
        break;
    }

    return res;
  }

  static Color getTextColorByJobStatus(String status) {
    Color color = Color(0xFF676767);
    switch (status.toLowerCase()) {
      case 'pending job start':
        color = Color(0xFF676767);
        break;
      case 'repairing':
        color = Color(0xFF143A55);
        break;
      case 'kiv':
        color = Color(0xFF7E300B);
        break;
      case 'cancelled':
        color = Color(0xFF670B0B);
        break;
      case 'completed':
        color = Color(0xFF57450D);
        break;
      case 'pending delivery':
        color = Color(0xFF1C5830);
        break;
      case 'closed':
        color = Color(0xFF1C5830);
        break;
      default:
        color = Color(0xFF676767);
        break;
    }

    return color;
  }

  static Color getForegroundColorByJobStatus(String status) {
    Color color = Color(0xFFEAEAEA);
    switch (status.toLowerCase()) {
      case 'pending job start':
        color = Color(0xFFEAEAEA);
        break;
      case 'repairing':
        color = Color(0xFFA1D8FF);
        break;
      case 'kiv':
        color = Color(0xFFFFAE88);
        break;
      case 'cancelled':
        color = Color(0xFFFFABAB);
        break;
      case 'completed':
        color = Color(0xFFFFDF7E);
        break;
      case 'pending delivery':
        color = Color(0xFF6EE295);
        break;
      case 'closed':
        color = Color(0xFF6EE295);
        break;
      default:
        color = Color(0xFFEAEAEA);
        break;
    }

    return color;
  }

  static Future<void> launchInWebViewOrVC(String url) async {
    if (!await launch(url,
        forceSafariVC: true,
        forceWebView: true,
        enableDomStorage: true,
        enableJavaScript: true)) {
      throw 'Could not launch $url';
    }
  }

  static bool isEmpty(field) {
    return ["", null, false, 0, '--Select--'].contains(field);
  }

  static bool? fromSignIn = false;

  //service tracker global var
  static int? productIndex;
}
