import 'dart:async';
import 'dart:io';

//import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:kcs_engineer/themes/text_styles.dart';
import 'package:kcs_engineer/util/key.dart';
import 'package:kcs_engineer/util/repositories.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SignIn extends StatefulWidget {
  int? data;
  SignIn({this.data});

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
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
  String buildNo = "";
  final storage = new FlutterSecureStorage();
  String? token;
  bool isRememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    validateToken();
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

  void validateToken() async {
    try {
      final accessToken = 
      await storage.read(key: TOKEN);

      if (accessToken != null && accessToken != "") {
        Navigator.pushReplacementNamed(context, 'home');
      }
    } catch (err) {}
  }

  @override
  void dispose() {
    emailCT.dispose();
    passwordCT.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    // Helpers.showAlert(context);
    setState(() {
      isLoading = true;
    });

    var res = await Repositories.handleSignIn(
        emailCT.text.toString(), passwordCT.text.toString());
    setState(() {
      isLoading = false;
    });
    if (res["success"]) {
      Navigator.pushReplacementNamed(context, 'home');
    } else {
      setState(() {
        isErrorEmail = true;
        isErrorPassword = true;
      });
    }
    print("RES");
  }

  // _registerOnFirebase() async {
  //   FirebaseMessaging _fcm = FirebaseMessaging.instance;

  //   var userStorage = await storage.read(key: USER);
  //   User userJson = User.fromJson(jsonDecode(userStorage!));
  //   var email = userJson.email?.toLowerCase();

  //   if (email != null) {
  //     _fcm.subscribeToTopic('all');
  //     _fcm.getToken().then((value) async => {
  //           value.toString(),
  //           await handleNewRegistrationToken(
  //               value.toString(), email.toString()),
  //         });
  //   }
  // }

  handleNewRegistrationToken(String token, String email) async {
    final Map<String, dynamic> map = {
      'email': email,
      'token': token,
      'device_id': 'deviceID',
      'platform': Platform.isAndroid ? 'Android' : 'iOS'
    };
    var baseUrl = FlutterConfig.get("API_URL");

    var response = await http.post(
        Uri.parse((baseUrl ?? "https://cm.khind.com.my") +
            "/provider/fcm/register.php"),
        body: map,
        headers: null);

    var g = response.toString();
  }

  Widget _renderHeader() {
    return Container(
      alignment: Alignment.center,
      child: Image(
          image: AssetImage('assets/images/khind-logo.png'),
          height: MediaQuery.of(context).size.width * 0.1),
    );
  }

  Widget _renderForm() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Text(
                  "Email",
                  style: TextStyle(color: Color(0xFF333333), fontSize: 14),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.start,
            ),
            SizedBox(height: 5),
            TextFormField(
                focusNode: focusEmail,
                keyboardType: TextInputType.text,
                controller: emailCT,
                onFieldSubmitted: (val) {
                  FocusScope.of(context).requestFocus(new FocusNode());
                },
                style: TextStyles.textDefaultBold,
                decoration: InputDecoration(
                  //labelText: "example@gmail.com",
                  fillColor: Colors.white,
                  focusedBorder: OutlineInputBorder(
                    //borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide(
                      color: isErrorEmail ? Colors.red : Colors.blue,
                    ),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 5.0, horizontal: 5),
                  enabledBorder: OutlineInputBorder(
                    // borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide(
                      color: isErrorEmail ? Colors.red : Color(0xFFD4D4D4),
                      width: 2.0,
                    ),
                  ),
                )),
            SizedBox(height: 5),
            isErrorEmail
                ? Row(children: [
                    Icon(
                      Icons.warning_outlined,
                      color: Colors.red,
                      size: 25.0,
                    ),
                    SizedBox(width: 5),
                    RichText(
                      text: TextSpan(
                          
                          
                          style: const TextStyle(
                            fontSize: 13.0,
                            color: Colors.red,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'Invalid email address',
                            ),
                          ]),
                    ),
                  ])
                : new Container(),
            SizedBox(height: 10),

            Row(
              children: [
                Text(
                  "Password",
                  style: TextStyle(color: Color(0xFF333333), fontSize: 14),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.start,
            ),
            SizedBox(height: 5),
            Stack(
              children: [
                TextFormField(
                    focusNode: focusPwd,
                    keyboardType: TextInputType.text,
                    obscureText: !showPassword,
                    controller: passwordCT,
                    onFieldSubmitted: (val) {
                      FocusScope.of(context).requestFocus(new FocusNode());
                    },
                    style: TextStyles.textDefaultBold,
                    decoration: InputDecoration(
                      // labelText: "Password",
                      fillColor: Colors.white,
                      focusedBorder: OutlineInputBorder(
                        //borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide(
                          color: isErrorEmail ? Colors.red : Colors.blue,
                        ),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 5.0, horizontal: 5),
                      enabledBorder: OutlineInputBorder(
                        // borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide(
                          color:
                              isErrorPassword ? Colors.red : Color(0xFFD4D4D4),
                          width: 2.0,
                        ),
                      ),
                    )),
                Positioned(
                    right: 15,
                    top: 10,
                    child: InkWell(
                        onTap: () {
                          setState(() {
                            showPassword = !showPassword;
                          });
                        },
                        child: Icon(showPassword
                            ? Icons.visibility
                            : Icons.visibility_off)))
              ],
            ),
            SizedBox(height: 5),
            isErrorPassword
                ? Row(children: [
                    Icon(
                      Icons.warning_outlined,
                      color: Colors.red,
                      size: 25.0,
                    ),
                    SizedBox(width: 5),
                    RichText(
                      text: TextSpan(
                          
                          
                          style: const TextStyle(
                            fontSize: 13.0,
                            color: Colors.red,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'Invalid password',
                            ),
                          ]),
                    ),
                  ])
                : new Container(),
            SizedBox(height: 25),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(
                children: [
                  Row(
                    children: <Widget>[
                      Row(
                        children: [
                          Container(
                            alignment: Alignment.centerLeft,
                            child: Checkbox(
                                value: isRememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    isRememberMe = value ?? false;
                                  });
                                }),
                          ),
                          Container(
                            padding: EdgeInsets.fromLTRB(0, 0, 20, 0),
                            child: Text('Remember Me'),
                          )
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              RichText(
                text: TextSpan(
                    
                    
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF3FA2F7),
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Forgot password',
                      ),
                    ]),
              ),
            ]),

            SizedBox(height: 15),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: <Widget>[
            //     Row(
            //       mainAxisAlignment: MainAxisAlignment.start,
            //       children: [
            //         Container(
            //           alignment: Alignment.centerLeft,
            //           child: Checkbox(
            //               value: isRememberMe,
            //               onChanged: (value) {
            //                 setState(() {
            //                   isRememberMe = value ?? false;
            //                 });
            //               }),
            //         ),
            //         Text('Remember Me'),
            //       ],
            //     ),
            //   ],
            //),
            SizedBox(height: 30),
            SizedBox(
              width:
                  MediaQuery.of(context).size.width * 0.9, // <-- match_parent
              height:
                  MediaQuery.of(context).size.height * 0.04, // <-- match-parent
              child: ElevatedButton(
                  child: isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: LoadingAnimationWidget.staggeredDotsWave(
                            color: Color(0xFFFFFFFF),
                            size: MediaQuery.of(context).size.height * 0.03,
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Text(
                            'Log in',
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          )),
                  style: ButtonStyle(
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.black),
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.black),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                              side: BorderSide(color: Colors.black)))),
                  onPressed: () => {_handleSignIn()}),
            )
          ],
        ),
      ),
    );
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
                      child: Stack(children: [
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: new BoxDecoration(color: Colors.white),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.30),
                                  _renderHeader(),
                                  SizedBox(height: errorMsg != "" ? 20 : 50),
                                  errorMsg != "" ? _renderError() : Container(),
                                  _renderForm(),
                                  SizedBox(height: 10),
                                  //Expanded(child: _renderBottom()),
                                  //version != "" ? _renderVersion() : Container()
                                ])),
                        Positioned(
                          bottom: 10,
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            color: Colors.white
                                .withOpacity(0.8), // Darker background color
                            padding: EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                  onTap: () =>
                                      {}, // Replace with your desired function
                                  child: _renderLabel(
                                    "App Version",
                                    textStyle: TextStyles.textGrey,
                                    padding: EdgeInsets.only(top: 10),
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  '$version ($buildNo)' +
                                      (FlutterConfig.get("ENVIRONMENT") ==
                                              "STAGING"
                                          ? " (STAGING)"
                                          : ""),
                                  style: TextStyles.textDefault,
                                )
                              ],
                            ),
                          ),
                        ),
                      ]))))),
    );
  }
}
