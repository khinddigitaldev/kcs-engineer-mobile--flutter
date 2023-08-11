import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kcs_engineer/model/part.dart';
import 'package:kcs_engineer/themes/text_styles.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:http/http.dart' as http;

class Bag extends StatefulWidget {
  int? data;
  Bag({this.data});

  @override
  _BagState createState() => _BagState();
}

class _BagState extends State<Bag> {
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  GlobalKey<FormState> _formKeyBottom = GlobalKey<FormState>();

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

  final List<Part> parts = [
    new Part(
        name: '25W Refrigerator Evaporator Fan Motor',
        model: 'SKU #762828',
        noOfUnits: '5'),
    new Part(
        name: '25W Refrigerator Evaporator Fan Motor',
        model: 'SKU #762828',
        noOfUnits: '5'),
    new Part(
        name: '25W Refrigerator Evaporator Fan Motor',
        model: 'SKU #762828',
        noOfUnits: '5'),
    new Part(
        name: '25W Refrigerator Evaporator Fan Motor',
        model: 'SKU #762828',
        noOfUnits: '5'),
  ];

  final List<Part> addParts = [
    new Part(
        name: '25W Refrigerator Evaporator Fan Motor',
        model: 'SKU #762828',
        noOfUnits: '5'),
    new Part(
        name: '25W Refrigerator Evaporator Fan Motor',
        model: 'SKU #762828',
        noOfUnits: '5'),
    new Part(
        name: '25W Refrigerator Evaporator Fan Motor',
        model: 'SKU #762828',
        noOfUnits: '5'),
  ];

  @override
  void initState() {
    // emailCT.text = 'khindtest1@gmail.com';
    // passwordCT.text = 'Abcd@1234';
    // emailCT.text = 'khindcustomerservice@gmail.com';
    // passwordCT.text = 'Khindanshin118';

    super.initState();
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
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Form(
        key: _formKey,
        child: Column(children: [
          SizedBox(height: 10),
          Container(
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                // Note: Styles for TextSpans must be explicitly defined.
                // Child text spans will inherit styles from parent
                style: const TextStyle(
                  fontSize: 29.0,
                  color: Colors.black,
                ),
                children: <TextSpan>[
                  TextSpan(
                      text: 'Bag',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          Divider(color: Colors.grey),
          SizedBox(height: 30),
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
                        text: TextSpan(
                            // Note: Styles for TextSpans must be explicitly defined.
                            // Child text spans will inherit styles from parent
                            style: const TextStyle(
                              fontSize: 25.0,
                              color: Colors.black,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: 'ALL PARTS',
                              ),
                            ]),
                      ),
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
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width *
                                0.15, // <-- match_parent
                            height: MediaQuery.of(context).size.width *
                                0.05, // <-- match-parent
                            child: ElevatedButton(
                                child: Padding(
                                    padding: const EdgeInsets.all(0.0),
                                    child: Text(
                                      'Edit',
                                      style: TextStyle(
                                          fontSize: 15, color: Colors.white),
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
                                            side: BorderSide(
                                                color: Colors.black87)))),
                                onPressed: () => null),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width *
                                0.15, // <-- match_parent
                            height: MediaQuery.of(context).size.width *
                                0.05, // <-- match-parent
                            child: ElevatedButton(
                                child: Padding(
                                    padding: const EdgeInsets.all(0.0),
                                    child: Text(
                                      'Confirm',
                                      style: TextStyle(
                                          fontSize: 15, color: Colors.white),
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
                                            side: BorderSide(
                                                color: Colors.black54)))),
                                onPressed: () => null),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 50,
          ),
          Container(
            alignment: Alignment.centerLeft,
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
                      text: 'Parts List',
                    ),
                  ]),
            ),
          ),
          Container(
            width: double.infinity,
            //padding: EdgeInsets.symmetric(horizontal: 10),
            height: height * 0.75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  height: height * 0.3,
                  child: ListView.builder(
                    // physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    // shrinkWrap: false,
                    itemCount: parts.length,
                    itemBuilder: (BuildContext context, int index) {
                      return PartItem(
                          width: width, part: parts[index], index: index);
                    },
                  ),
                ),
                Divider(color: Colors.grey),
                SizedBox(height: 30),
                Container(
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(
                      // Note: Styles for TextSpans must be explicitly defined.
                      // Child text spans will inherit styles from parent
                      style: const TextStyle(
                        fontSize: 25.0,
                        color: Colors.black,
                      ),
                      children: <TextSpan>[
                        TextSpan(text: 'Add Parts'),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 25),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  height: height * 0.3,
                  child: ListView.builder(
                    // physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    // shrinkWrap: false,
                    itemCount: addParts.length,
                    itemBuilder: (BuildContext context, int index) {
                      return AddPartItem(
                          width: width, part: addParts[index], index: index);
                    },
                  ),
                ),
                // Container(
                //   alignment: Alignment.centerRight,
                //   decoration:
                //       new BoxDecoration(color: Colors.white.withOpacity(0.0)),
                //   child: TextFormField(
                //       focusNode: focusEmail,
                //       keyboardType: TextInputType.text,
                //       validator: (value) {
                //         if (value!.isEmpty) {
                //           return 'Please enter email';
                //         }
                //         return null;
                //       },
                //       controller: emailCT,
                //       onFieldSubmitted: (val) {
                //         FocusScope.of(context).requestFocus(new FocusNode());
                //       },
                //       style: TextStyles.textDefaultBold,
                //       decoration: const InputDecoration(
                //         contentPadding: EdgeInsets.symmetric(
                //             vertical: 10.0, horizontal: 10),
                //         border: OutlineInputBorder(),
                //       )),
                // ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ]),
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
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
        key: _scaffoldKey,
        //resizeToAvoidBottomInset: false,
        body: SingleChildScrollView(
            // physics: ClampingScrollPhysics(parent: NeverScrollableScrollPhysics()),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          _renderForm(),

          //Expanded(child: _renderBottom()),
          //version != "" ? _renderVersion() : Container()
        ])));
  }

  Widget _renderBottom() {
    return Column(children: []);
  }
}

class PartItem extends StatelessWidget {
  const PartItem(
      {Key? key, required this.width, required this.part, required this.index})
      : super(key: key);

  final double width;
  final Part part;
  final int index;

  @override
  Widget build(BuildContext context) {
    var units = this.part.noOfUnits;
    var name = this.part.name;
    var model = this.part.model;

    return GestureDetector(
      onTap: () async {
        Navigator.pushNamed(context, 'productModel');
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              RichText(
                text: TextSpan(
                    // Note: Styles for TextSpans must be explicitly defined.
                    // Child text spans will inherit styles from parent
                    style: const TextStyle(
                      fontSize: 18.0,
                      color: Colors.black,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: '$name',
                      ),
                    ]),
              ),
              RichText(
                text: TextSpan(
                    // Note: Styles for TextSpans must be explicitly defined.
                    // Child text spans will inherit styles from parent
                    style: const TextStyle(
                      fontSize: 18.0,
                      color: Colors.black54,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: '$model',
                      ),
                    ]),
              ),
              SizedBox(height: 30),
            ],
          ),
          Spacer(),
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(bottom: 50.0, right: 50.0),
            child: RichText(
              text: TextSpan(
                  // Note: Styles for TextSpans must be explicitly defined.
                  // Child text spans will inherit styles from parent
                  style: const TextStyle(
                    fontSize: 18.0,
                    color: Colors.black54,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: '$units units',
                    ),
                  ]),
            ),
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}

class AddPartItem extends StatelessWidget {
  const AddPartItem(
      {Key? key, required this.width, required this.part, required this.index})
      : super(key: key);

  final double width;
  final Part part;
  final int index;

  @override
  Widget build(BuildContext context) {
    var units = this.part.noOfUnits;
    var name = this.part.name;
    var model = this.part.model;

    return GestureDetector(
      onTap: () async {
        Navigator.pushNamed(context, 'productModel');
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              RichText(
                text: TextSpan(
                    // Note: Styles for TextSpans must be explicitly defined.
                    // Child text spans will inherit styles from parent
                    style: const TextStyle(
                      fontSize: 18.0,
                      color: Colors.black,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: '$name',
                      ),
                    ]),
              ),
              RichText(
                text: TextSpan(
                    // Note: Styles for TextSpans must be explicitly defined.
                    // Child text spans will inherit styles from parent
                    style: const TextStyle(
                      fontSize: 18.0,
                      color: Colors.black54,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: '$model',
                      ),
                    ]),
              ),
              SizedBox(height: 30),
            ],
          ),
          Spacer(),
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(bottom: 50.0),
            child: Row(
              children: <Widget>[
                new IconButton(
                    icon: new Icon(Icons.remove), onPressed: () => {}),
                new Text('0'),
                new IconButton(icon: new Icon(Icons.add), onPressed: () => {}),
              ],
            ),
          ),
          Spacer(),
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(bottom: 50.0, right: 30.0),
            child: Icon(
              // <-- Icon
              Icons.highlight_remove_sharp,
              color: Colors.red,
              size: 40.0,
            ),
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}
