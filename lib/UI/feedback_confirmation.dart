import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kcs_engineer/model/job/job.dart';
import 'package:package_info_plus/package_info_plus.dart';

class FeedBackConfirmation extends StatefulWidget {
  Job? data;
  FeedBackConfirmation({this.data});

  @override
  _FeedBackConfirmationState createState() => _FeedBackConfirmationState();
}

class _FeedBackConfirmationState extends State<FeedBackConfirmation> {
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
  final storage = new FlutterSecureStorage();
  String? token;
  Job? selectedJob;

  @override
  void initState() {
    // emailCT.text = 'khindtest1@gmail.com';
    // passwordCT.text = 'Abcd@1234';
    // emailCT.text = 'khindcustomerservice@gmail.com';
    // passwordCT.text = 'Khindanshin118';

    super.initState();
    _loadVersion();
    selectedJob = widget.data;
    //_loadToken();
    //_checkPermisions();
  }

  @override
  void dispose() {
    emailCT.dispose();
    passwordCT.dispose();
    super.dispose();
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

  Widget _renderForm() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Icon(
              // <-- Icon
              Icons.thumb_up_alt,
              color: Colors.red,
              size: 130.0,
            ),
            SizedBox(height: 20),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 39.0,
                  color: Colors.black,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: 'Job Successful!',
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 25.0, color: Colors.grey),
                children: <TextSpan>[
                  TextSpan(
                    text: 'This job has successfully completed ',
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
                child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Text(
                      'Back To Home',
                      style: TextStyle(fontSize: 20, color: Colors.red),
                    )),
                style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.all<Color>(
                        Colors.white.withOpacity(0.7)),
                    backgroundColor: MaterialStateProperty.all<Color>(
                        Colors.white.withOpacity(0.7)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                            side: BorderSide(
                                color: Colors.red.withOpacity(0.7))))),
                onPressed: () {
                  //Navigator.pushReplacementNamed(context, 'home');
                  Navigator.of(context).popUntil((route) => route.isFirst);
                })
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

  Future<bool> _onWillPop() async {
    //Navigator.pop(context);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          key: _scaffoldKey,
          //resizeToAvoidBottomInset: false,
          body: CustomPaint(
              child: SingleChildScrollView(
                  // physics: ClampingScrollPhysics(parent: NeverScrollableScrollPhysics()),
                  child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height),
                      child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 10),
                          decoration: new BoxDecoration(color: Colors.white),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                _renderForm(),
                                SizedBox(height: 10),
                                //Expanded(child: _renderBottom()),
                                //version != "" ? _renderVersion() : Container()
                              ]))))),
        ));
  }
}
