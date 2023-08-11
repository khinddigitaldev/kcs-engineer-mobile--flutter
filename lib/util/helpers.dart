import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:kcs_engineer/model/jobGeneralCodes.dart';
import 'package:kcs_engineer/model/user.dart';
import 'package:kcs_engineer/model/user_sparepart.dart';
import 'package:kcs_engineer/themes/app_colors.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kcs_engineer/model/job.dart';

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
            CircularProgressIndicator(),
            Container(
                margin: EdgeInsets.only(left: 5), child: Text("Loading...")),
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
  static List<JobGeneralCode> editableGeneralCodes = [];
  static List<JobSparePart> editableJobSpareParts = [];
  static List<Job> inProgressJobs = [];
  static List<Job> completedJobs = [];

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
