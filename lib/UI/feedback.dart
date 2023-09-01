// // ignore_for_file: dead_code

// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:flutter_rating_bar/flutter_rating_bar.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:kcs_engineer/model/job.dart';
// import 'package:kcs_engineer/model/payment_request.dart';
// import 'package:kcs_engineer/themes/text_styles.dart';
// import 'package:kcs_engineer/util/helpers.dart';
// import 'package:kcs_engineer/util/repositories.dart';
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:path_provider/path_provider.dart';

// class FeedbackUI extends StatefulWidget {
//   Job? data;
//   PaymentDTO? paymentDTO;
//   FeedbackUI({this.data, this.paymentDTO});

//   @override
//   _FeedbackState createState() => _FeedbackState();
// }

// class _FeedbackState extends State<FeedbackUI> {
//   GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
//   GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//   TextEditingController emailCT = new TextEditingController();
//   TextEditingController passwordCT = new TextEditingController();
//   FocusNode focusEmail = new FocusNode();
//   FocusNode focusPwd = new FocusNode();
//   bool isLoading = false;
//   bool showPassword = false;
//   String errorMsg = "";
//   String version = "";
//   final storage = new FlutterSecureStorage();
//   String? token;
//   Job? selectedJob;
//   bool isGoodRating = false;
//   bool isBadRating = false;
//   bool isNeutralRating = true;

//   bool isCustomerSupport = false;
//   bool friendliness = false;
//   bool punctuality = false;
//   bool professionalism = false;
//   bool other = false;
//   int ratingScore = 0;
//   PaymentDTO? payment;

//   @override
//   void initState() {
//     // emailCT.text = 'khindtest1@gmail.com';
//     // passwordCT.text = 'Abcd@1234';
//     // emailCT.text = 'khindcustomerservice@gmail.com';
//     // passwordCT.text = 'Khindanshin118';

//     super.initState();
//     setState(() {
//       selectedJob = widget.data;
//       payment = widget.paymentDTO;
//     });
//     _loadVersion();
//     //_loadToken();
//     //_checkPermisions();
//   }

//   @override
//   void dispose() {
//     emailCT.dispose();
//     passwordCT.dispose();
//     super.dispose();
//   }

//   _loadVersion() async {
//     PackageInfo packageInfo = await PackageInfo.fromPlatform();
//     String pkgVersion = packageInfo.version;

//     setState(() {
//       version = pkgVersion;
//     });
//   }

//   // _loadToken() async {
//   //   final accessToken = await storage.read(key: TOKEN);

//   //   setState(() {
//   //     token = accessToken;
//   //   });
//   // }

//   void _handleSignIn() async {}

//   Widget _renderForm() {
//     return Container(
//       padding: EdgeInsets.all(20),
//       decoration: BoxDecoration(
//           color: Colors.white, borderRadius: BorderRadius.circular(10)),
//       child: Form(
//         key: _formKey,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             SizedBox(height: 5),
//             Container(
//               alignment: Alignment.center,
//               padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
//               decoration:
//                   new BoxDecoration(color: Colors.white.withOpacity(0.0)),
//               child: Image(
//                   image: AssetImage('assets/images/feedback.png'),
//                   height: MediaQuery.of(context).size.width * 0.2,
//                   width: MediaQuery.of(context).size.width * 0.4),
//             ),
//             SizedBox(height: 20),
//             Divider(color: Colors.grey),
//             SizedBox(height: 40),
//             Container(
//               alignment: Alignment.center,
//               decoration:
//                   new BoxDecoration(color: Colors.white.withOpacity(0.0)),
//               child: RichText(
//                 text: TextSpan(
//                   // Note: Styles for TextSpans must be explicitly defined.
//                   // Child text spans will inherit styles from parent
//                   style: const TextStyle(
//                     fontSize: 35.0,
//                     color: Colors.red,
//                   ),
//                   children: <TextSpan>[
//                     TextSpan(
//                       text: 'Rate Your Experience',
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             SizedBox(height: 5),
//             Container(
//               alignment: Alignment.center,
//               decoration:
//                   new BoxDecoration(color: Colors.white.withOpacity(0.0)),
//               child: RichText(
//                 text: TextSpan(
//                   // Note: Styles for TextSpans must be explicitly defined.
//                   // Child text spans will inherit styles from parent
//                   style: const TextStyle(
//                     fontSize: 15.0,
//                     color: Colors.grey,
//                   ),
//                   children: <TextSpan>[
//                     TextSpan(
//                       text: 'WE VALUE YOUR FEEDBACK',
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             SizedBox(height: 40),
//             Container(
//               alignment: Alignment.center,
//               decoration:
//                   new BoxDecoration(color: Colors.white.withOpacity(0.0)),
//               child: RichText(
//                 text: TextSpan(
//                   // Note: Styles for TextSpans must be explicitly defined.
//                   // Child text spans will inherit styles from parent
//                   style: const TextStyle(
//                     fontSize: 18.0,
//                     color: Colors.black,
//                   ),
//                   children: <TextSpan>[
//                     TextSpan(
//                       text: 'Are you happy with our service?',
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             SizedBox(height: 30),
//             RatingBar.builder(
//               initialRating: 0,
//               minRating: 1,
//               direction: Axis.horizontal,
//               allowHalfRating: false,
//               itemCount: 5,
//               itemSize: 60,
//               itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
//               itemBuilder: (context, _) => Icon(
//                 Icons.star,
//                 color: Colors.amber,
//               ),
//               onRatingUpdate: (rating) {
//                 if (rating <= 3.0) {
//                   setState(() {
//                     ratingScore = rating.round();
//                     isBadRating = true;
//                     isGoodRating = false;
//                     isNeutralRating = false;
//                   });
//                 } else {
//                   setState(() {
//                     ratingScore = rating.round();
//                     isBadRating = false;
//                     isGoodRating = true;
//                     isNeutralRating = false;
//                   });
//                 }
//               },
//             ),
//             SizedBox(height: 30),
//             !isNeutralRating
//                 ? new Divider(color: Colors.grey)
//                 : new Container(),
//             SizedBox(height: 30),
//             !isNeutralRating && isGoodRating
//                 ? Container(
//                     alignment: Alignment.centerLeft,
//                     decoration:
//                         new BoxDecoration(color: Colors.white.withOpacity(0.0)),
//                     child: RichText(
//                       text: TextSpan(
//                         // Note: Styles for TextSpans must be explicitly defined.
//                         // Child text spans will inherit styles from parent
//                         style: const TextStyle(
//                           fontSize: 14.0,
//                           color: Colors.grey,
//                         ),
//                         children: <TextSpan>[
//                           TextSpan(
//                             text: "Comments for our technician's performance",
//                           ),
//                         ],
//                       ),
//                     ),
//                   )
//                 : new Container(),
//             SizedBox(height: 20),
//             !isNeutralRating && isGoodRating
//                 ? Container(
//                     height: 80,
//                     alignment: Alignment.centerLeft,
//                     decoration:
//                         new BoxDecoration(color: Colors.white.withOpacity(0.0)),
//                     child: TextFormField(
//                         minLines: 1,
//                         maxLines: 10,
//                         textInputAction: TextInputAction.newline,
//                         focusNode: focusEmail,
//                         keyboardType: TextInputType.multiline,
//                         validator: (value) {},
//                         controller: emailCT,
//                         onFieldSubmitted: (val) {
//                           FocusScope.of(context).requestFocus(new FocusNode());
//                         },
//                         style: TextStyles.textDefaultBold,
//                         decoration: const InputDecoration(
//                           contentPadding: EdgeInsets.symmetric(
//                               vertical: 10.0, horizontal: 10),
//                           border: OutlineInputBorder(),
//                         )),
//                   )
//                 : new Container(),
//             SizedBox(height: 20),

//             (!isNeutralRating && isBadRating)
//                 ? RichText(
//                     text: TextSpan(
//                       // Note: Styles for TextSpans must be explicitly defined.
//                       // Child text spans will inherit styles from parent
//                       style: const TextStyle(
//                         fontSize: 17.0,
//                         color: Colors.black,
//                       ),
//                       children: <TextSpan>[
//                         TextSpan(
//                           text: 'TELL US WHAT WE CAN DO TO SERVE YOU BETTER',
//                         ),
//                       ],
//                     ),
//                   )
//                 : new Container(),
//             SizedBox(
//               height: 50,
//             ),
//             (!isNeutralRating && isBadRating)
//                 ? Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Container(
//                           width: MediaQuery.of(context).size.width * 0.25,
//                           height: 40.0,
//                           child: ElevatedButton(
//                               style: ButtonStyle(
//                                   backgroundColor: MaterialStateProperty.all(
//                                       isCustomerSupport
//                                           ? Colors.black
//                                           : Colors.grey),
//                                   shape: MaterialStateProperty.all<
//                                           RoundedRectangleBorder>(
//                                       RoundedRectangleBorder(
//                                           borderRadius:
//                                               BorderRadius.circular(20.0),
//                                           side: BorderSide(
//                                               color: isCustomerSupport
//                                                   ? Colors.black
//                                                   : Colors.grey)))),
//                               onPressed: () {
//                                 setState(() {
//                                   isCustomerSupport = !isCustomerSupport;
//                                 });
//                               },
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Text(
//                                     "Customer Support ",
//                                     style: TextStyle(
//                                         fontSize: 19.0,
//                                         color: isCustomerSupport
//                                             ? Colors.white
//                                             : Colors.black),
//                                   ),
//                                 ],
//                               ))),
//                       SizedBox(width: 10),
//                       Container(
//                           width: MediaQuery.of(context).size.width * 0.2,
//                           height: 40.0,
//                           child: ElevatedButton(
//                               style: ButtonStyle(
//                                   backgroundColor: MaterialStateProperty.all(
//                                       friendliness
//                                           ? Colors.black
//                                           : Colors.grey),
//                                   shape: MaterialStateProperty.all<
//                                           RoundedRectangleBorder>(
//                                       RoundedRectangleBorder(
//                                           borderRadius:
//                                               BorderRadius.circular(20.0),
//                                           side: BorderSide(
//                                               color: friendliness
//                                                   ? Colors.black
//                                                   : Colors.grey)))),
//                               onPressed: () {
//                                 setState(() {
//                                   friendliness = !friendliness;
//                                 });
//                               },
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Text(
//                                     "Friendliness",
//                                     style: TextStyle(
//                                         fontSize: 19.0,
//                                         color: friendliness
//                                             ? Colors.white
//                                             : Colors.black),
//                                   ),
//                                 ],
//                               ))),
//                       SizedBox(width: 10),
//                       Container(
//                           width: MediaQuery.of(context).size.width * 0.2,
//                           height: 40.0,
//                           child: ElevatedButton(
//                               style: ButtonStyle(
//                                   backgroundColor: MaterialStateProperty.all(
//                                       punctuality ? Colors.black : Colors.grey),
//                                   shape: MaterialStateProperty.all<
//                                           RoundedRectangleBorder>(
//                                       RoundedRectangleBorder(
//                                           borderRadius:
//                                               BorderRadius.circular(20.0),
//                                           side: BorderSide(
//                                               color: punctuality
//                                                   ? Colors.black
//                                                   : Colors.grey)))),
//                               onPressed: () {
//                                 setState(() {
//                                   punctuality = !punctuality;
//                                 });
//                               },
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Text(
//                                     "Punctuality",
//                                     style: TextStyle(
//                                         fontSize: 19.0,
//                                         color: punctuality
//                                             ? Colors.white
//                                             : Colors.black),
//                                   ),
//                                 ],
//                               ))),
//                     ],
//                   )
//                 : new Container(),
//             SizedBox(height: 10),
//             (!isNeutralRating && isBadRating)
//                 ? Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Container(
//                           width: MediaQuery.of(context).size.width * 0.25,
//                           height: 40.0,
//                           child: ElevatedButton(
//                               style: ButtonStyle(
//                                   backgroundColor: MaterialStateProperty.all(
//                                       professionalism
//                                           ? Colors.black
//                                           : Colors.grey),
//                                   shape: MaterialStateProperty.all<
//                                           RoundedRectangleBorder>(
//                                       RoundedRectangleBorder(
//                                           borderRadius:
//                                               BorderRadius.circular(20.0),
//                                           side: BorderSide(
//                                               color: professionalism
//                                                   ? Colors.black
//                                                   : Colors.grey)))),
//                               onPressed: () {
//                                 setState(() {
//                                   professionalism = !professionalism;
//                                 });
//                               },
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Text(
//                                     "Professionalism",
//                                     style: TextStyle(
//                                         fontSize: 19.0,
//                                         color: professionalism
//                                             ? Colors.white
//                                             : Colors.black),
//                                   ),
//                                 ],
//                               ))),
//                       SizedBox(width: 10),
//                       Container(
//                           width: MediaQuery.of(context).size.width * 0.15,
//                           height: 40.0,
//                           child: ElevatedButton(
//                               style: ButtonStyle(
//                                   backgroundColor: MaterialStateProperty.all(
//                                       other ? Colors.black : Colors.grey),
//                                   shape: MaterialStateProperty.all<
//                                           RoundedRectangleBorder>(
//                                       RoundedRectangleBorder(
//                                           borderRadius:
//                                               BorderRadius.circular(20.0),
//                                           side: BorderSide(
//                                               color: other
//                                                   ? Colors.black
//                                                   : Colors.grey)))),
//                               onPressed: () {
//                                 setState(() {
//                                   other = !other;
//                                 });
//                               },
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Text(
//                                     "Other",
//                                     style: TextStyle(
//                                         fontSize: 19.0,
//                                         color: other
//                                             ? Colors.white
//                                             : Colors.black),
//                                   ),
//                                 ],
//                               ))),
//                     ],
//                   )
//                 : new Container(),
//             SizedBox(height: 30),
//             !isNeutralRating ? Divider(color: Colors.grey) : new Container(),
//             SizedBox(height: 180),
//             SizedBox(
//               width:
//                   MediaQuery.of(context).size.width * 0.9, // <-- match_parent
//               height:
//                   MediaQuery.of(context).size.height * 0.04, // <-- match-parent
//               child: ElevatedButton(
//                   child: Padding(
//                       padding: const EdgeInsets.all(5.0),
//                       child: Text(
//                         'Submit',
//                         style: TextStyle(fontSize: 20, color: Colors.white),
//                       )),
//                   style: ButtonStyle(
//                       foregroundColor: MaterialStateProperty.all<Color>(
//                           Colors.red.withOpacity(0.7)),
//                       backgroundColor: MaterialStateProperty.all<Color>(
//                           Colors.red.withOpacity(0.7)),
//                       shape: MaterialStateProperty.all<RoundedRectangleBorder>(
//                           RoundedRectangleBorder(
//                               borderRadius: BorderRadius.zero,
//                               side: BorderSide(
//                                   color: Colors.red.withOpacity(0.7))))),
//                   onPressed: () async {
//                     if (payment == null) {
//                       Widget okButton = TextButton(
//                         child: Text("OK"),
//                         onPressed: () {
//                           Navigator.pop(context);
//                         },
//                       );

//                       // set up the AlertDialog
//                       AlertDialog alert = AlertDialog(
//                         title: Text("Error"),
//                         content: Text("Payment Could not be completed."),
//                         actions: [
//                           okButton,
//                         ],
//                       );

//                       // show the dialog
//                       showDialog(
//                         context: context,
//                         builder: (BuildContext context) {
//                           return alert;
//                         },
//                       );
//                     } else {
//                       Helpers.showAlert(context);
//                       await _processPayment();
//                       Navigator.pop(context);

//                       Helpers.showAlert(context);
//                       var res = await this._postRating();
//                       Navigator.pop(context);
//                       if (res) {
//                         Navigator.pushNamed(context, 'feedback_confirmation',
//                             arguments: Helpers.selectedJob);
//                       }
//                     }
//                   }),
//             ),

//             // ElevatedButton(
//             //     child:
//             //         Text("Next".toUpperCase(), style: TextStyle(fontSize: 14)),
//             //     style: ButtonStyle(
//             //         foregroundColor:
//             //             MaterialStateProperty.all<Color>(Colors.white),
//             //         backgroundColor:
//             //             MaterialStateProperty.all<Color>(Colors.red),
//             //         shape: MaterialStateProperty.all<RoundedRectangleBorder>(
//             //             RoundedRectangleBorder(
//             //                 borderRadius: BorderRadius.zero,
//             //                 side: BorderSide(color: Colors.red)))),
//             //     onPressed: () => null)
//           ],
//         ),
//       ),
//     );
//   }

//   Future<bool> _postRating() async {
//     return await Repositories.postRating(selectedJob!.id ?? 0,
//         await generateCategorieArr(), ratingScore, getNewLineString());
//   }

//   String getNewLineString() {
//     LineSplitter ls = new LineSplitter();
//     List<String> lines = ls.convert(emailCT.text.toString());

//     var comment = "";

//     for (var i = 0; i < lines.length; i++) {
//       comment = comment == "" ? lines[i] + "\\n" : comment + lines[i] + "\\n";
//     }

//     return comment;
//   }

//   Future<List<int>> generateCategorieArr() async {
//     List<String> categoriesStr = [
//       "isCustomerSupport",
//       "isFriendliness",
//       "punctuality",
//       "professionalism",
//       "other"
//     ];
//     List<int> categories = [];

//     categoriesStr.forEach((element) {
//       var category = 0;
//       switch (element) {
//         case "isCustomerSupport":
//           category = 1;
//           break;
//         case "isFriendliness":
//           category = 2;
//           break;
//         case "punctuality":
//           category = 3;
//           break;
//         case "professionalism":
//           category = 4;
//           break;
//         case "other":
//           category = 5;
//           break;
//       }
//       if (category == 1 && isCustomerSupport) {
//         categories.add(1);
//       } else if (category == 2 && friendliness) {
//         categories.add(2);
//       } else if (category == 3 && punctuality) {
//         categories.add(3);
//       } else if (category == 4 && professionalism) {
//         categories.add(4);
//       } else if (category == 5 && other) {
//         categories.add(5);
//       }
//     });

//     return categories;
//   }

//   Future<File> _convertImageToFile(Uint8List bytes) async {
//     final tempDir = await getTemporaryDirectory();
//     File fileToBeUploaded = await File('${tempDir.path}/image.png').create();
//     fileToBeUploaded.writeAsBytesSync(bytes);
//     return fileToBeUploaded;
//   }

//   _processPayment() async {
//     Uint8List? bodyBytes = await payment?.signatureController?.toPngBytes();
//     File signature = await _convertImageToFile(bodyBytes!);

//     List<Map<String, dynamic>>? map;

//     if (payment?.mixedPayment ?? false) {
//       if (payment?.dropDownOneSelectedText!.toLowerCase() == "pay now" &&
//           payment?.dropDownTwoSelectedText!.toLowerCase() == "pay now") {
//         setState(() {
//           payment?.payNow = true;
//         });
//       }

//       map = [
//         {
//           'payment_method_id': (payment?.paymentMethods ?? [])
//               .where((element) =>
//                   element.description == payment?.dropDownOneSelectedText)
//               .toList()
//               .first
//               .id,
//           "amount": payment?.PMOneCT,
//           "currency": "SGD"
//         },
//         {
//           'payment_method_id': (payment?.paymentMethods ?? [])
//               .where((element) =>
//                   element.description == payment?.dropDownTwoSelectedText)
//               .toList()
//               .first
//               .id,
//           "amount": payment?.PMTwoCT,
//           "currency": "SGD"
//         }
//       ];
//       return await Repositories.processPayment(
//           selectedJob!.id ?? 0,
//           signature,
//           (payment?.isWantInvoice ?? false),
//           payment?.emailCT?.toString() ?? "",
//           double.parse(selectedJob?.sumTotal.toString() ?? "0"),
//           "SGD",
//           map);
//     } else if (!(selectedJob?.isChargeable ?? true)) {
//       map = [
//         {'payment_method_id': 11, "amount": "0.00", "currency": "SGD"},
//       ];

//       return await Repositories.processPayment(
//           selectedJob!.id ?? 0,
//           signature,
//           (payment?.isWantInvoice ?? false),
//           payment?.emailCT?.toString() ?? "",
//           double.parse("0"),
//           "SGD",
//           map);
//     } else {
//       var paymentMethodId = "0";

//       if (payment?.payByCash ?? false) {
//         paymentMethodId = "6";
//       } else if (payment?.payNow ?? false) {
//         paymentMethodId = "4";
//       } else if (payment?.pendingPayment ?? false) {
//         paymentMethodId = "5";
//       } else if (payment?.billing ?? false) {
//         paymentMethodId = "10";
//       } else if (payment?.payByCheque ?? false) {
//         paymentMethodId = "7";
//       } else {
//         paymentMethodId = "0";
//       }

//       map = [
//         {
//           'payment_method_id': paymentMethodId,
//           "amount": selectedJob!.sumTotal?.toStringAsFixed(2),
//           "currency": "SGD"
//         },
//       ];
//       if (paymentMethodId != "0") {
//         return await Repositories.processPayment(
//             selectedJob!.id ?? 0,
//             signature,
//             (payment?.isWantInvoice ?? false),
//             payment?.emailCT?.toString() ?? "",
//             double.parse(selectedJob?.sumTotal.toString() ?? "0"),
//             "SGD",
//             map);
//       } else {
//         return false;
//       }
//     }
//   }

//   _renderError() {
//     return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
//       // SizedBox(height: 10),
//       SizedBox(height: 20),
//     ]);
//   }

//   Future<bool> _onWillPop() async {
//     Navigator.pop(context);
//     return true;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//         onWillPop: _onWillPop,
//         child: Scaffold(
//           key: _scaffoldKey,
//           appBar: Helpers.customAppBar(context, _scaffoldKey,
//               title: "Feedback",
//               isBack: true,
//               isAppBarTranparent: true,
//               hasActions: false, handleBackPressed: () {
//             if (widget.data == 1) {
//               Navigator.pushReplacementNamed(context, 'home', arguments: 0);
//             } else {
//               Navigator.pop(context);
//             }
//           }),
//           //resizeToAvoidBottomInset: false,
//           body: CustomPaint(
//               child: SingleChildScrollView(
//                   // physics: ClampingScrollPhysics(parent: NeverScrollableScrollPhysics()),
//                   child: ConstrainedBox(
//                       constraints: BoxConstraints(
//                           maxHeight: MediaQuery.of(context).size.height),
//                       child: Container(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 40, vertical: 10),
//                           decoration: new BoxDecoration(color: Colors.white),
//                           child: Column(
//                               mainAxisAlignment: MainAxisAlignment.start,
//                               children: [
//                                 _renderForm(),
//                                 SizedBox(height: 10),
//                                 //Expanded(child: _renderBottom()),
//                                 //version != "" ? _renderVersion() : Container()
//                               ]))))),
//         ));
//   }
// }
