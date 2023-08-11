import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kcs_engineer/model/job.dart';
import 'package:kcs_engineer/model/payment_request.dart';
import 'package:kcs_engineer/util/helpers.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

class Payment extends StatefulWidget {
  Job? data;
  PaymentDTO? paymentDTO;
  Payment({this.data, this.paymentDTO});

  @override
  _PaymentState createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController emailCT = new TextEditingController();
  TextEditingController passwordCT = new TextEditingController();
  FocusNode focusEmail = new FocusNode();
  FocusNode focusPwd = new FocusNode();
  bool isLoading = false;
  Job? selectedJob;
  bool showPassword = false;
  String errorMsg = "";
  String version = "";
  final storage = new FlutterSecureStorage();
  String? token;
  PaymentDTO? paymentDTO;

  @override
  void initState() {
    // emailCT.text = 'khindtest1@gmail.com';
    // passwordCT.text = 'Abcd@1234';
    // emailCT.text = 'khindcustomerservice@gmail.com';
    // passwordCT.text = 'Khindanshin118';

    super.initState();
    setState(() {
      selectedJob = widget.data;
      paymentDTO = widget.paymentDTO;
    });
    _loadVersion();
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
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              decoration:
                  new BoxDecoration(color: Colors.white.withOpacity(0.0)),
              child: Image(
                  image: AssetImage('assets/images/payment.png'),
                  height: MediaQuery.of(context).size.width * 0.2,
                  width: MediaQuery.of(context).size.width * 0.4),
            ),
            SizedBox(height: 20),
            Container(
              alignment: Alignment.center,
              child: Image(
                  image: AssetImage('assets/images/khind-logo.png'),
                  height: MediaQuery.of(context).size.width * 0.1),
            ),
            SizedBox(height: 50),
            Container(
              alignment: Alignment.center,
              decoration:
                  new BoxDecoration(color: Colors.white.withOpacity(0.0)),
              child: RichText(
                text: TextSpan(
                  // Note: Styles for TextSpans must be explicitly defined.
                  // Child text spans will inherit styles from parent
                  style: const TextStyle(
                    fontSize: 25.0,
                    color: Colors.black,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Scan QR Code',
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
              width: 500,
              alignment: Alignment.center,
              decoration:
                  new BoxDecoration(color: Colors.white.withOpacity(0.0)),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  // Note: Styles for TextSpans must be explicitly defined.
                  // Child text spans will inherit styles from parent
                  style: const TextStyle(
                    fontSize: 17.0,
                    color: Colors.black54,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text:
                          'Place QR code inside the frame to scan, please avoid shake to get results quickly',
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 50),
            Container(
              alignment: Alignment.center,
              child: QrImage(
                data:
                    "00020101021226370009SG.PAYNOW010120210198701251D030115204000053037025802SG5923MAYER MARKETING PTE LTD6009Singapore62260122MAYER MARKETING - UBI 63040880",
                version: QrVersions.auto,
                size: 300.0,
              ),
            ),
            Container(
              height: 100,
              width: 300,
              alignment: Alignment.center,
              child: Image(
                  image: AssetImage('assets/images/paynowlogo.png'),
                  height: MediaQuery.of(context).size.width * 0.2,
                  width: MediaQuery.of(context).size.width * 0.4),
            ),
            SizedBox(height: 30),
            Container(
              alignment: Alignment.center,
              decoration:
                  new BoxDecoration(color: Colors.white.withOpacity(0.0)),
              child: RichText(
                text: TextSpan(
                  // Note: Styles for TextSpans must be explicitly defined.
                  // Child text spans will inherit styles from parent
                  style: const TextStyle(
                    fontSize: 20.0,
                    color: Colors.black,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'UEN : 198701251D',
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),
            Container(
              alignment: Alignment.center,
              decoration:
                  new BoxDecoration(color: Colors.white.withOpacity(0.0)),
              child: RichText(
                text: TextSpan(
                  // Note: Styles for TextSpans must be explicitly defined.
                  // Child text spans will inherit styles from parent
                  style: TextStyle(
                    fontSize: 28.0,
                    color: Colors.black,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: '\$' +
                          (((widget?.paymentDTO?.mixedPayment ?? false)
                                  ? double.parse(
                                          widget?.paymentDTO?.PMOneCT ?? "0.0")
                                      .toStringAsFixed(2)
                                  : selectedJob!.sumTotal!
                                      .toStringAsFixed(2)) ??
                              ""),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),
            Container(
              width: MediaQuery.of(context).size.width * 0.3,
              height: MediaQuery.of(context).size.height * 0.04,
              alignment: Alignment.center,
              decoration: new BoxDecoration(color: Colors.black),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 15,
                  ),
                  RichText(
                    text: TextSpan(
                      // Note: Styles for TextSpans must be explicitly defined.
                      // Child text spans will inherit styles from parent
                      style: const TextStyle(
                        fontSize: 15.0,
                        color: Colors.white,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Pay For Job',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  RichText(
                    text: TextSpan(
                      // Note: Styles for TextSpans must be explicitly defined.
                      // Child text spans will inherit styles from parent
                      style: const TextStyle(
                        fontSize: 15.0,
                        color: Colors.blue,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: '#' + (selectedJob?.refNo ?? ""),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            SizedBox(height: 40),
            SizedBox(
              width:
                  MediaQuery.of(context).size.width * 0.9, // <-- match_parent
              height:
                  MediaQuery.of(context).size.height * 0.05, // <-- match-parent
              child: ElevatedButton(
                  child: Padding(
                      padding: const EdgeInsets.all(1.0),
                      child: Text(
                        'Next',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      )),
                  style: ButtonStyle(
                      foregroundColor: MaterialStateProperty.all<Color>(
                          Colors.red.withOpacity(0.7)),
                      backgroundColor: MaterialStateProperty.all<Color>(
                          Colors.red.withOpacity(0.7)),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                              side: BorderSide(
                                  color: Colors.red.withOpacity(0.7))))),
                  onPressed: () {
                    Navigator.pushNamed(context, 'feedback',
                        arguments: [selectedJob, paymentDTO]);
                  }),
            ),
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
    Navigator.pop(context);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          key: _scaffoldKey,
          appBar: Helpers.customAppBar(context, _scaffoldKey,
              title: "Payment",
              isBack: true,
              isAppBarTranparent: true,
              hasActions: false, handleBackPressed: () {
            if (widget.data == 1) {
              Navigator.pushReplacementNamed(context, 'home', arguments: 0);
            } else {
              Navigator.pop(context);
            }
          }),
          //resizeToAvoidBottomInset: false,
          body: CustomPaint(
              child: SingleChildScrollView(
                  // physics: ClampingScrollPhysics(parent: NeverScrollableScrollPhysics()),
                  child: Container(
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
                          ])))),
        ));
  }
}
