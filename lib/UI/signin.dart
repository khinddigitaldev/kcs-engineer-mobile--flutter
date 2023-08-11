import 'dart:convert';
import 'dart:io';
import 'dart:ui';

//import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:kcs_engineer/themes/text_styles.dart';
import 'package:kcs_engineer/util/api.dart';
import 'package:kcs_engineer/util/helpers.dart';
import 'package:kcs_engineer/util/key.dart';

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
  final storage = new FlutterSecureStorage();
  String? token;
  bool isRememberMe = false;

  @override
  void initState() {
    super.initState();
    //Helpers.showAlert(context);
    validateToken();
  }

  void validateToken() async {
    final accessToken = await storage.read(key: TOKEN);

    if (accessToken != null && accessToken != "") {
      Navigator.pushReplacementNamed(context, 'home');
    }
  }

  @override
  void dispose() {
    emailCT.dispose();
    passwordCT.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    Helpers.showAlert(context);

    final Map<String, dynamic> map = {
      'email': emailCT.text.toString(),
      'password': passwordCT.text.toString(),
    };

    final response = await Api.bearerPost('login', params: jsonEncode(map));
    Navigator.pop(context);

    if (response["success"] != false) {
      Helpers.isAuthenticated = true;
      await storage.write(key: TOKEN, value: response['data']?['token']);
      await storage.write(
          key: USERID, value: response['data']?['user']?['user_id'].toString());

      Navigator.pushReplacementNamed(context, 'home');
    } else {
      setState(() {
        isErrorEmail = true;
        isErrorPassword = true;
      });
    }
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
                Text("Email"),
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
                      color: isErrorEmail ? Colors.red : Colors.black45,
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
                          // Note: Styles for TextSpans must be explicitly defined.
                          // Child text spans will inherit styles from parent
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
                Text("Password"),
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
                          color: isErrorPassword ? Colors.red : Colors.black45,
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
                          // Note: Styles for TextSpans must be explicitly defined.
                          // Child text spans will inherit styles from parent
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
                  child: Padding(
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

  _handleSignin() {}

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
                                _renderForm(),
                                SizedBox(height: 10),
                                //Expanded(child: _renderBottom()),
                                //version != "" ? _renderVersion() : Container()
                              ]))))),
        ));
  }
}
