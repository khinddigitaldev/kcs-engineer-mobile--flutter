import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kcs_engineer/model/job.dart';
import 'package:kcs_engineer/util/key.dart';

class SplashScreen extends StatefulWidget {
  Job? data;
  SplashScreen({this.data});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController emailCT = new TextEditingController();
  TextEditingController passwordCT = new TextEditingController();
  FocusNode focusEmail = new FocusNode();
  FocusNode focusPwd = new FocusNode();
  bool isLoading = false;
  bool showPassword = false;
  bool isErrorEmail = false;
  bool isErrorPassword = false;
  String errorMsg = "";
  String version = "";
  final storage = new FlutterSecureStorage();
  String? token;
  bool isRememberMe = false;

  Job? selectedJob;

  @override
  void initState() {
    super.initState();

    selectedJob = widget.data;
    validateToken();
  }

  void validateToken() async {
    await Future.delayed(const Duration(seconds: 1), () async {
      if (selectedJob != null) {
        Navigator.pushReplacementNamed(context, 'home');
      } else {
        final accessToken = await storage.read(key: TOKEN);
        if (accessToken != null && accessToken != "") {
          Navigator.pushReplacementNamed(context, 'home');
        } else {
          Navigator.pushReplacementNamed(context, 'signIn');
        }
      }
    });
  }

  @override
  void dispose() {
    emailCT.dispose();
    passwordCT.dispose();
    super.dispose();
  }

  Widget _renderHeader() {
    if (selectedJob == null) {
      return Container(
        alignment: Alignment.center,
        child: Image(
            image: AssetImage('assets/images/khind-logo.png'),
            height: MediaQuery.of(context).size.width * 0.1),
      );
    } else {
      return Container();
    }
  }

  _renderError() {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      // SizedBox(height: 10),
      SizedBox(height: 20),
    ]);
  }

  Future<bool> _onWillPop() async {
    //Navigator.pop(context);
    return true;
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: new BoxDecoration(color: Colors.white),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.30),
                                _renderHeader(),
                                SizedBox(height: errorMsg != "" ? 20 : 50),

                                errorMsg != "" ? _renderError() : Container(),
                                SizedBox(height: 10),
                                //Expanded(child: _renderBottom()),
                                //version != "" ? _renderVersion() : Container()
                              ]))))),
        ));
  }
}
