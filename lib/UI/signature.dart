import 'dart:io';
import 'dart:typed_data';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kcs_engineer/model/job.dart';
import 'package:kcs_engineer/model/payment_method.dart';
import 'package:kcs_engineer/model/payment_request.dart';
import 'package:kcs_engineer/payment_method_icons.dart' as PaymentMethodIcons;
import 'package:kcs_engineer/themes/text_styles.dart';
import 'package:kcs_engineer/util/helpers.dart';
import 'package:kcs_engineer/util/repositories.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';

class SignatureUI extends StatefulWidget {
  Job? data;
  SignatureUI({this.data});

  @override
  _SignatureState createState() => _SignatureState();
}

class _SignatureState extends State<SignatureUI> {
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController emailCT = new TextEditingController();
  TextEditingController PMOneCT = new TextEditingController();
  TextEditingController PMTwoCT = new TextEditingController();
  TextEditingController PMLabelCT = new TextEditingController();

  FocusNode focusEmail = new FocusNode();
  FocusNode focusPMOne = new FocusNode();
  FocusNode focusPMTwo = new FocusNode();
  bool isLoading = false;
  bool showPassword = false;
  String errorMsg = "";
  Job? selectedJob;
  String version = "";
  bool status = false;
  final storage = new FlutterSecureStorage();
  String? token;
  List<String> paymentMethodLabels = [];
  List<PaymentMethod> paymentMethods = [];
  bool isWantInvoice = true;
  bool payByCash = false;
  bool payNow = false;
  bool pendingPayment = false;
  bool billing = false;
  bool payByCheque = false;
  bool mixedPayment = false;
  int? dropDownOneSelectedIndex;
  int? dropDownTwoSelectedIndex;
  String? dropDownOneSelectedText;
  String? dropDownTwoSelectedText;
  bool signatureErr = false;
  bool errorEmail = false;
  String consumerName = "";
  PaymentDTO paymentDTO = new PaymentDTO();
  final dropdownOneState = GlobalKey<FormFieldState>();
  final dropdownTwoState = GlobalKey<FormFieldState>();

  SignatureController controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white);

  @override
  void initState() {
    setState(() {
      selectedJob = widget.data;
      consumerName = selectedJob?.customerName ?? "";
    });
    super.initState();
    _fetchPaymentMethods();
    _loadVersion();
    PMLabelCT.text = "Cash";
    //_loadToken();
    //_checkPermisions();
  }

  @override
  void dispose() {
    emailCT.dispose();
    PMOneCT.dispose();
    PMTwoCT.dispose();
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
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 5),
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              decoration:
                  new BoxDecoration(color: Colors.white.withOpacity(0.0)),
              child: Image(
                  image: AssetImage('assets/images/signature.png'),
                  height: MediaQuery.of(context).size.width * 0.2,
                  width: MediaQuery.of(context).size.width * 0.4),
            ),
            SizedBox(height: 20),
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              decoration:
                  new BoxDecoration(color: Colors.white.withOpacity(0.0)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      // Note: Styles for TextSpans must be explicitly defined.
                      // Child text spans will inherit styles from parent
                      style: const TextStyle(
                        fontSize: 17.0,
                        color: Colors.black,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                            text: 'ACKNOWLEDGED RECEIPT OF JOB COMPLETION',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline)),
                      ],
                    ),
                  ),
                  SizedBox(height: 15),
                  RichText(
                    text: TextSpan(
                      // Note: Styles for TextSpans must be explicitly defined.
                      // Child text spans will inherit styles from parent
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: Colors.black,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              'I $consumerName hereby acknowledge the receipt of the product and service promised from Mayer.',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.12,
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    border: Border.all(color: Colors.black),
                                  ),
                                  child: Signature(
                                    controller: controller,
                                    height: MediaQuery.of(context).size.height *
                                        0.1,
                                    width:
                                        MediaQuery.of(context).size.width * .6,
                                    backgroundColor: Colors.transparent,
                                  ),
                                ),
                                SizedBox(
                                    height: 10,
                                    child: Divider(color: Colors.grey))
                              ],
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(0, 0, 0, 95),
                              child: Container(
                                alignment: Alignment.centerRight,
                                height: 40,
                                width: 40,
                                child: ElevatedButton(
                                    child: Padding(
                                        padding: const EdgeInsets.all(0.0),
                                        child: Text(
                                          textAlign: TextAlign.center,
                                          'X',
                                          style: TextStyle(
                                              fontSize: 15, color: Colors.red),
                                        )),
                                    style: ButtonStyle(
                                        foregroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.white.withOpacity(0.7)),
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.white.withOpacity(0.7)),
                                        shape: MaterialStateProperty.all<
                                                RoundedRectangleBorder>(
                                            RoundedRectangleBorder(
                                                borderRadius: BorderRadius.zero,
                                                side: BorderSide(
                                                    color: Colors.red)))),
                                    onPressed: () {
                                      setState(() {
                                        controller!.clear();
                                      });
                                    }),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  signatureErr
                      ? RichText(
                          text: TextSpan(
                            // Note: Styles for TextSpans must be explicitly defined.
                            // Child text spans will inherit styles from parent
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: Colors.red,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text:
                                    'Please draw the signature on the above space',
                              ),
                            ],
                          ),
                        )
                      : new Container(),
                  Row(
                    children: [
                      RichText(
                        text: TextSpan(
                          // Note: Styles for TextSpans must be explicitly defined.
                          // Child text spans will inherit styles from parent
                          style: const TextStyle(
                            fontSize: 14.0,
                            color: Colors.black,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'Signature',
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            SizedBox(height: 20),
            Divider(color: Colors.grey),
            SizedBox(height: 20),
            Row(children: <Widget>[
              Expanded(
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      color: Color(0xFFE7F3FF),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                        child: Column(
                          children: [
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
                                      text: 'MYR 250.00',
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
                                  style: const TextStyle(
                                    fontSize: 18.0,
                                    color: Colors.blue,
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: 'Total Amount Charged',
                                    ),
                                  ]),
                            ),
                          ],
                        ),
                      ),
                    )),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                      color: Colors.white,
                      child: Column(
                        children: [
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
                                    text: 'Do you want an invoice?',
                                  ),
                                ]),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 40,
                                  width: 60,
                                  child: ElevatedButton(
                                      child: Padding(
                                          padding: const EdgeInsets.all(5.0),
                                          child: Text(
                                            'Yes',
                                            style: TextStyle(
                                                fontSize: 20,
                                                color: isWantInvoice
                                                    ? Colors.white
                                                    : Colors.black),
                                          )),
                                      style: ButtonStyle(
                                          foregroundColor: isWantInvoice
                                              ? MaterialStateProperty.all<Color>(
                                                  Colors.black87
                                                      .withOpacity(0.7))
                                              : MaterialStateProperty.all<Color>(
                                                  Colors.white
                                                      .withOpacity(0.7)),
                                          backgroundColor: isWantInvoice
                                              ? MaterialStateProperty.all<Color>(
                                                  Colors.black87
                                                      .withOpacity(0.7))
                                              : MaterialStateProperty.all<Color>(
                                                  Colors.white.withOpacity(0.7)),
                                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: Colors.black87.withOpacity(0.7))))),
                                      onPressed: () {
                                        setState(() {
                                          isWantInvoice = true;
                                        });
                                      }),
                                ),
                              ),
                              SizedBox(
                                width: 20,
                              ),
                              Expanded(
                                child: Container(
                                    height: 40,
                                    width: 60,
                                    child: ElevatedButton(
                                        child: Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: Text(
                                              'No',
                                              style: TextStyle(
                                                  fontSize: 20,
                                                  color: isWantInvoice
                                                      ? Colors.black
                                                      : Colors.white),
                                            )),
                                        style: ButtonStyle(
                                            foregroundColor: isWantInvoice
                                                ? MaterialStateProperty.all<Color>(
                                                    Colors.white
                                                        .withOpacity(0.7))
                                                : MaterialStateProperty.all<Color>(
                                                    Colors.black87
                                                        .withOpacity(0.7)),
                                            backgroundColor: isWantInvoice
                                                ? MaterialStateProperty.all<Color>(
                                                    Colors.white
                                                        .withOpacity(0.7))
                                                : MaterialStateProperty.all<Color>(
                                                    Colors.black87.withOpacity(0.7)),
                                            shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: Colors.black87.withOpacity(0.7))))),
                                        onPressed: () {
                                          setState(() {
                                            isWantInvoice = false;
                                            errorEmail = false;
                                          });
                                        })),
                              )
                            ],
                          )
                        ],
                      )),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 200,
                    //height: 80,
                    color: Colors.white,
                    child: isWantInvoice
                        ? Container(
                            alignment: Alignment.centerLeft,
                            decoration: new BoxDecoration(
                                color: Colors.white.withOpacity(0.0)),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(0, 40, 0, 0),
                              child: SizedBox(
                                  height: 80,
                                  child: TextFormField(
                                      onChanged: (text) {
                                        if (errorEmail) {
                                          setState(() {
                                            errorEmail = false;
                                          });
                                        }
                                      },
                                      focusNode: focusEmail,
                                      keyboardType: TextInputType.text,
                                      validator: (value) {
                                        if (value!.isEmpty ||
                                            !EmailValidator.validate(value)) {
                                          setState(() {
                                            errorEmail = true;
                                          });
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                      controller: emailCT,
                                      onFieldSubmitted: (val) {
                                        FocusScope.of(context)
                                            .requestFocus(new FocusNode());
                                      },
                                      style: TextStyles.textDefaultBold,
                                      decoration: const InputDecoration(
                                        hintText: 'Email',
                                        //errorStyle: ,
                                        //errorText: 'This is an error text',
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 10.0, horizontal: 10.0),
                                        border: OutlineInputBorder(),
                                      ))),
                            ))
                        : new Container(),
                  ),
                ),
              ),
            ]),
            // ((selectedJob!.isChargeable ?? false) && selectedJob!.sumTotal != 0)
            //     ? SizedBox(height: 40)
            //     : new Container(),
            // ((selectedJob!.isChargeable ?? false) && selectedJob!.sumTotal != 0)
            //  ?
            Row(
              children: [
                RichText(
                  text: TextSpan(
                    // Note: Styles for TextSpans must be explicitly defined.
                    // Child text spans will inherit styles from parent
                    style: const TextStyle(
                      fontSize: 17.0,
                      color: Colors.black,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'How do you want to pay ?',
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 20),
              ],
            ),
            //  : new Container(),
            // ((selectedJob!.isChargeable ?? false) && selectedJob!.sumTotal != 0)
            //     ? SizedBox(height: 10)
            //     : new Container(),
            // ((selectedJob!.isChargeable ?? false) && selectedJob!.sumTotal != 0)
            //     ? SizedBox(height: 20)
            //     : new Container(),
            // ((selectedJob!.isChargeable ?? false) && selectedJob!.sumTotal != 0)
            //?
            SizedBox(height: 30),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    color: payByCash ? Colors.black87 : Colors.white,
                    width: MediaQuery.of(context).size.width * 0.27,
                    height: 100.0,
                    child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            payByCash = true;
                            payNow = false;
                            pendingPayment = false;
                            billing = false;
                            payByCheque = false;
                            mixedPayment = false;
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Pay By Cash",
                              style: TextStyle(
                                  fontSize: 19.0,
                                  color: payByCash
                                      ? Colors.white
                                      : Colors.black87),
                            ),
                            Icon(
                              // <-- Icon
                              Icons.money,
                              color: payByCash ? Colors.white : Colors.black87,
                              size: 40.0,
                            )
                          ],
                        ))),
                SizedBox(
                  width: 20,
                ),
                Container(
                    color: payNow ? Colors.black87 : Colors.white,
                    width: MediaQuery.of(context).size.width * 0.27,
                    height: 100.0,
                    child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            payByCash = false;
                            payNow = true;
                            pendingPayment = false;
                            billing = false;
                            payByCheque = false;
                            mixedPayment = false;
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Pay Now",
                              style: TextStyle(
                                fontSize: 19.0,
                                color: payNow ? Colors.white : Colors.black87,
                              ),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Icon(
                              // <-- Icon
                              PaymentMethodIcons.PaymentMethod.paynow,
                              color: payNow ? Colors.white : Colors.black87,
                              size: 35.0,
                            )
                          ],
                        ))),
                // Container(
                //     color: pendingPayment ? Colors.black87 : Colors.white,
                //     width: MediaQuery.of(context).size.width * 0.27,
                //     height: 100.0,
                //     child: OutlinedButton(
                //         onPressed: () {
                //           setState(() {
                //             payByCash = false;
                //             payNow = false;
                //             pendingPayment = true;
                //             billing = false;
                //             payByCheque = false;
                //             mixedPayment = false;
                //           });
                //         },
                //         child: Row(
                //           mainAxisAlignment: MainAxisAlignment.center,
                //           children: [
                //             Text(
                //               "Pending Payment",
                //               style: TextStyle(
                //                   fontSize: 17.0,
                //                   color: pendingPayment
                //                       ? Colors.white
                //                       : Colors.black87),
                //             ),
                //             SizedBox(
                //               width: 10,
                //             ),
                //             Icon(
                //               // <-- Icon
                //               PaymentMethodIcons
                //                   .PaymentMethod.pending_payment,
                //               color: pendingPayment
                //                   ? Colors.white
                //                   : Colors.black87,
                //               size: 30.0,
                //             )
                //           ],
                //         ))),
              ],
            )
            //   : new Container(),
            // SizedBox(height: 20),
            // ((selectedJob!.isChargeable ?? false) && selectedJob!.sumTotal != 0)
            //     ? Row(
            //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //         children: [
            //           Container(
            //               color: billing ? Colors.black87 : Colors.white,
            //               width: MediaQuery.of(context).size.width * 0.27,
            //               height: 100.0,
            //               child: OutlinedButton(
            //                   onPressed: () {
            //                     setState(() {
            //                       payByCash = false;
            //                       payNow = false;
            //                       pendingPayment = false;
            //                       billing = true;
            //                       payByCheque = false;
            //                       mixedPayment = false;
            //                     });
            //                   },
            //                   child: Row(
            //                     mainAxisAlignment: MainAxisAlignment.center,
            //                     children: [
            //                       Text(
            //                         "Billing",
            //                         style: TextStyle(
            //                             fontSize: 19.0,
            //                             color: billing
            //                                 ? Colors.white
            //                                 : Colors.black87),
            //                       ),
            //                       SizedBox(
            //                         width: 10,
            //                       ),
            //                       Icon(
            //                         // <-- Icon
            //                         PaymentMethodIcons.PaymentMethod.billing,
            //                         color:
            //                             billing ? Colors.white : Colors.black87,
            //                         size: 35.0,
            //                       )
            //                     ],
            //                   ))),
            //           Container(
            //               color: payByCheque ? Colors.black87 : Colors.white,
            //               width: MediaQuery.of(context).size.width * 0.27,
            //               height: 100.0,
            //               child: OutlinedButton(
            //                   onPressed: () {
            //                     setState(() {
            //                       payByCash = false;
            //                       payNow = false;
            //                       pendingPayment = false;
            //                       billing = false;
            //                       payByCheque = true;
            //                       mixedPayment = false;
            //                     });
            //                   },
            //                   child: Row(
            //                     mainAxisAlignment: MainAxisAlignment.center,
            //                     children: [
            //                       Text(
            //                         "Pay By Cheque",
            //                         style: TextStyle(
            //                             fontSize: 19.0,
            //                             color: payByCheque
            //                                 ? Colors.white
            //                                 : Colors.black87),
            //                       ),
            //                       SizedBox(
            //                         width: 10,
            //                       ),
            //                       Icon(
            //                         // <-- Icon
            //                         PaymentMethodIcons.PaymentMethod.cheque,
            //                         color: payByCheque
            //                             ? Colors.white
            //                             : Colors.black87,
            //                         size: 25.0,
            //                       )
            //                     ],
            //                   ))),
            //           Container(
            //               color: mixedPayment ? Colors.black87 : Colors.white,
            //               width: MediaQuery.of(context).size.width * 0.27,
            //               height: 100.0,
            //               child: OutlinedButton(
            //                   onPressed: () {
            //                     setState(() {
            //                       payByCash = false;
            //                       payNow = false;
            //                       pendingPayment = false;
            //                       billing = false;
            //                       payByCheque = false;
            //                       mixedPayment = true;
            //                     });
            //                   },
            //                   child: Row(
            //                     mainAxisAlignment: MainAxisAlignment.center,
            //                     children: [
            //                       Text(
            //                         "Mixed Payment",
            //                         style: TextStyle(
            //                             fontSize: 19.0,
            //                             color: mixedPayment
            //                                 ? Colors.white
            //                                 : Colors.black87),
            //                       ),
            //                       SizedBox(
            //                         width: 10,
            //                       ),
            //                       Icon(
            //                         PaymentMethodIcons.PaymentMethod.mixed,
            //                         color: mixedPayment
            //                             ? Colors.white
            //                             : Colors.black87,
            //                         size: 35.0,
            //                       )
            //                     ],
            //                   ))),
            //         ],
            //       )
            //     : new Container(),
            // ((selectedJob!.isChargeable ?? false) && selectedJob!.sumTotal != 0)
            //     ? SizedBox(
            //         height: 30,
            //       )
            //     : new Container(),
            // mixedPayment
            //     ? Column(
            //         mainAxisAlignment: MainAxisAlignment.center,
            //         crossAxisAlignment: CrossAxisAlignment.center,
            //         children: [
            //           RichText(
            //             text: TextSpan(
            //               // Note: Styles for TextSpans must be explicitly defined.
            //               // Child text spans will inherit styles from parent
            //               style: const TextStyle(
            //                   fontSize: 20.0, color: Colors.black87),
            //               children: <TextSpan>[
            //                 TextSpan(
            //                     text: 'Mixed Payment',
            //                     style: const TextStyle()),
            //               ],
            //             ),
            //           ),
            //           SizedBox(
            //             height: 10,
            //           ),
            //           SizedBox(
            //             width: 300,
            //             child: RichText(
            //               textAlign: TextAlign.center,
            //               text: TextSpan(
            //                 // Note: Styles for TextSpans must be explicitly defined.
            //                 // Child text spans will inherit styles from parent
            //                 style: const TextStyle(
            //                   fontSize: 17.0,
            //                   color: Colors.black54,
            //                 ),
            //                 children: <TextSpan>[
            //                   TextSpan(
            //                     text:
            //                         'Choose payment option from the dropdown and fill out the appropriate information',
            //                     style: const TextStyle(),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           ),
            //           SizedBox(
            //             height: 30,
            //           ),
            //           Column(
            //             mainAxisAlignment: MainAxisAlignment.center,
            //             crossAxisAlignment: CrossAxisAlignment.center,
            //             children: [
            //               RichText(
            //                 textAlign: TextAlign.center,
            //                 text: TextSpan(
            //                   // Note: Styles for TextSpans must be explicitly defined.
            //                   // Child text spans will inherit styles from parent
            //                   style: TextStyle(
            //                     fontSize: 25.0,
            //                     color: Colors.blue,
            //                   ),
            //                   children: <TextSpan>[
            //                     TextSpan(
            //                       text: '\$' +
            //                           selectedJob!.sumTotal!.toStringAsFixed(2),
            //                     ),
            //                   ],
            //                 ),
            //               ),
            //               RichText(
            //                 textAlign: TextAlign.center,
            //                 text: TextSpan(
            //                   // Note: Styles for TextSpans must be explicitly defined.
            //                   // Child text spans will inherit styles from parent
            //                   style: TextStyle(
            //                     fontSize: 18.0,
            //                     color: Colors.lightBlue,
            //                   ),
            //                   children: <TextSpan>[
            //                     TextSpan(
            //                       text: 'Payment Amount',
            //                     ),
            //                   ],
            //                 ),
            //               ),
            //             ],
            //           ),
            //           SizedBox(
            //             height: 50,
            //           ),
            //           Row(
            //             children: [
            //               Expanded(
            //                   child: Column(
            //                 children: [
            //                   SizedBox(
            //                     //height: 50,
            //                     width: 300,
            //                     child: DropdownButtonFormField<String>(
            //                       key: dropdownOneState,
            //                       validator: (value) {
            //                         if (value == null || value!.isEmpty) {
            //                           return "Please choose a payment method";
            //                         }
            //                         return null;
            //                       },
            //                       items: paymentMethodLabels
            //                           .where((element) => element != "Cash")
            //                           .map((String value) {
            //                         return DropdownMenuItem<String>(
            //                           enabled: paymentMethodLabels
            //                                           .indexOf(value) !=
            //                                       dropDownTwoSelectedIndex &&
            //                                   value != "Cash"
            //                               ? true
            //                               : false,
            //                           value: value,
            //                           child: Text(
            //                             value,
            //                             style: TextStyle(
            //                                 color: paymentMethodLabels
            //                                                 .indexOf(value) !=
            //                                             dropDownTwoSelectedIndex &&
            //                                         value != "Cash"
            //                                     ? Colors.black
            //                                     : Colors.black54),
            //                           ),
            //                         );
            //                       }).toList(),
            //                       onChanged: (element) async {
            //                         setState(() {
            //                           dropDownOneSelectedIndex =
            //                               paymentMethodLabels
            //                                   .indexOf(element ?? "");
            //                           dropDownOneSelectedText = element;
            //                         });

            //                         if (dropDownTwoSelectedText != "Cash" &&
            //                             element != "Cash") {
            //                           setState(() {
            //                             dropdownTwoState.currentState
            //                                 ?.didChange('Cash');
            //                           });
            //                         }
            //                       },
            //                       decoration: InputDecoration(
            //                           contentPadding: EdgeInsets.symmetric(
            //                               vertical: 7, horizontal: 3),
            //                           border: OutlineInputBorder(
            //                             borderRadius: const BorderRadius.all(
            //                               const Radius.circular(5.0),
            //                             ),
            //                           ),
            //                           filled: true,
            //                           hintStyle:
            //                               TextStyle(color: Colors.grey[800]),
            //                           hintText: "Select Payment Method",
            //                           fillColor: Colors.white),
            //                       //value: dropDownValue,
            //                     ),
            //                   ),
            //                   SizedBox(
            //                     height: 20,
            //                   ),
            //                   Padding(
            //                     padding: EdgeInsets.fromLTRB(0, 0, 150, 0),
            //                     child: RichText(
            //                       textAlign: TextAlign.left,
            //                       text: TextSpan(
            //                         // Note: Styles for TextSpans must be explicitly defined.
            //                         // Child text spans will inherit styles from parent
            //                         style: TextStyle(
            //                           fontSize: 17.0,
            //                           color: Colors.black,
            //                         ),
            //                         children: <TextSpan>[
            //                           TextSpan(
            //                             text: 'Payment Amount',
            //                           ),
            //                         ],
            //                       ),
            //                     ),
            //                   ),
            //                   SizedBox(
            //                     height: 10,
            //                   ),
            //                   TextFormField(
            //                       focusNode: focusPMOne,
            //                       keyboardType: TextInputType.number,
            //                       validator: (value) {
            //                         if (value!.isEmpty) {
            //                           return 'Please enter an amount';
            //                         }
            //                         return null;
            //                       },
            //                       inputFormatters: <TextInputFormatter>[
            //                         FilteringTextInputFormatter.allow(
            //                             RegExp("[0-9a-zA-Z\.]")),
            //                       ],
            //                       controller: PMOneCT,
            //                       onFieldSubmitted: (val) {
            //                         FocusScope.of(context)
            //                             .requestFocus(focusPMOne);
            //                       },
            //                       onChanged: (text) {
            //                         if ((text != "" ? double.parse(text) : 0) >
            //                             (double.parse(selectedJob!.sumTotal
            //                                     ?.toStringAsFixed(2) ??
            //                                 "0"))) {
            //                           PMOneCT.text = selectedJob?.sumTotal
            //                                   ?.toStringAsFixed(2) ??
            //                               "";
            //                         } else if ((text != ""
            //                                 ? double.parse(text)
            //                                 : 0) <
            //                             0) {
            //                           PMOneCT.text = "0";
            //                         }

            //                         PMTwoCT.text = ((double.parse(selectedJob!
            //                                     .sumTotal!
            //                                     .toStringAsFixed(2)) -
            //                                 (PMOneCT.text.toString() != ""
            //                                     ? double.parse(PMOneCT.text)
            //                                     : 0)))
            //                             .toStringAsFixed(2);
            //                       },
            //                       style: TextStyles.textDefaultBold,
            //                       decoration: const InputDecoration(
            //                         hintText: 'amount',
            //                         contentPadding: EdgeInsets.symmetric(
            //                             vertical: 10.0, horizontal: 10),
            //                         border: OutlineInputBorder(),
            //                       )),
            //                 ],
            //               )),
            //               SizedBox(
            //                 width: 100,
            //               ),
            //               Expanded(
            //                   child: Column(
            //                 children: [
            //                   SizedBox(
            //                     //height: 50,
            //                     width: 300,
            //                     child: TextFormField(
            //                       key: dropdownTwoState,
            //                       enabled: false,
            //                       controller: PMLabelCT,
            //                       onChanged: (element) async {
            //                         // setState(() {
            //                         //   dropDownTwoSelectedIndex =
            //                         //       paymentMethodLabels
            //                         //           .indexOf(element ?? "");
            //                         //   dropDownTwoSelectedText = element;
            //                         // });
            //                         // if (
            //                         //     dropDownOneSelectedText != "Cash" && element != "Cash") {
            //                         //   setState(() {
            //                         //     dropdownOneState.currentState
            //                         //         ?.didChange('Cash');
            //                         //   });
            //                         // }
            //                       },
            //                       decoration: InputDecoration(
            //                           contentPadding: EdgeInsets.symmetric(
            //                               vertical: 7, horizontal: 3),
            //                           border: OutlineInputBorder(
            //                             borderRadius: const BorderRadius.all(
            //                               const Radius.circular(5.0),
            //                             ),
            //                           ),
            //                           filled: true,
            //                           // hintStyle:
            //                           //     TextStyle(color: Colors.grey[800]),
            //                           //hintText: "Select Payment Method",
            //                           fillColor: Colors.white),
            //                       //value: dropDownValue,
            //                     ),
            //                   ),
            //                   SizedBox(
            //                     height: 20,
            //                   ),
            //                   Padding(
            //                     padding: EdgeInsets.fromLTRB(0, 0, 150, 0),
            //                     child: RichText(
            //                       textAlign: TextAlign.left,
            //                       text: TextSpan(
            //                         // Note: Styles for TextSpans must be explicitly defined.
            //                         // Child text spans will inherit styles from parent
            //                         style: TextStyle(
            //                           fontSize: 17.0,
            //                           color: Colors.black,
            //                         ),
            //                         children: <TextSpan>[
            //                           TextSpan(
            //                             text: 'Payment Amount',
            //                           ),
            //                         ],
            //                       ),
            //                     ),
            //                   ),
            //                   SizedBox(
            //                     height: 10,
            //                   ),
            //                   TextFormField(
            //                       focusNode: focusPMTwo,
            //                       keyboardType: TextInputType.number,
            //                       validator: (value) {
            //                         if (value!.isEmpty) {
            //                           return 'Please enter an amount';
            //                         }
            //                         return null;
            //                       },
            //                       inputFormatters: <TextInputFormatter>[
            //                         FilteringTextInputFormatter.allow(
            //                             RegExp("[0-9a-zA-Z]")),
            //                       ],
            //                       enabled: true,
            //                       controller: PMTwoCT,
            //                       onFieldSubmitted: (val) {
            //                         FocusScope.of(context)
            //                             .requestFocus(focusPMTwo);
            //                       },
            //                       onChanged: (text) {
            //                         // if (text.contains(".") &&
            //                         //     text.split(".")[1] == "") {
            //                         //   text = text.split(".")[0];
            //                         // }
            //                         // if ((text != "" ? double.parse(text) : 0) >
            //                         //     (double.parse(selectedJob!.sumTotal
            //                         //                 ?.toStringAsFixed(2) ??
            //                         //             "0") ??
            //                         //         0)) {
            //                         //   PMTwoCT.text = (selectedJob!.sumTotal
            //                         //           ?.toStringAsFixed(2) ??
            //                         //       "0");
            //                         // } else if ((text != ""
            //                         //         ? double.parse(text)
            //                         //         : 0) <
            //                         //     0) {
            //                         //   PMTwoCT.text = "0";
            //                         // }
            //                         // if (PMTwoCT.text.contains(".") &&
            //                         //     PMTwoCT.text.split(".")[1].length ==
            //                         //         0) {
            //                         //   PMTwoCT.text = PMTwoCT.text.split(".")[0];
            //                         // }

            //                         // PMOneCT.text = ((double.parse(selectedJob
            //                         //                 ?.sumTotal
            //                         //                 ?.toStringAsFixed(2) ??
            //                         //             "0") -
            //                         //         (PMTwoCT.text.toString() != ""
            //                         //             ? double.parse(
            //                         //                 double.parse(PMTwoCT.text)
            //                         //                     .toStringAsFixed(2))
            //                         //             : 0)))
            //                         //     .toStringAsFixed(2);
            //                       },
            //                       style: TextStyles.textDefaultBold,
            //                       decoration: const InputDecoration(
            //                         hintText: 'amount',
            //                         contentPadding: EdgeInsets.symmetric(
            //                             vertical: 10.0, horizontal: 10),
            //                         border: OutlineInputBorder(),
            //                       )),
            //                 ],
            //               )),
            //             ],
            //           ),
            //         ],
            //       )
            //     : new Container(),
            // ((selectedJob!.isChargeable ?? false) && selectedJob!.sumTotal != 0)
            //     ?
            ,
            SizedBox(height: 70),
            // : SizedBox(height: 50),
            SizedBox(
              width:
                  MediaQuery.of(context).size.width * 0.9, // <-- match_parent
              height:
                  MediaQuery.of(context).size.height * 0.04, // <-- match-parent
              child: ElevatedButton(
                  child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text(
                        'Next',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      )),
                  style: ButtonStyle(
                      foregroundColor: MaterialStateProperty.all<Color>(
                          Color(0xFFFFB700).withOpacity(0.7)),
                      backgroundColor: MaterialStateProperty.all<Color>(
                          Color(0xFFFFB700).withOpacity(0.7)),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                              side: BorderSide(
                                  color: Color(0xFFFFB700).withOpacity(0.7))))),
                  onPressed: () async {
                    var res = await _processPayment();

                    if (res) {
                      Uint8List? bodyBytes =
                          await paymentDTO.signatureController?.toPngBytes();
                      File signature = await _convertImageToFile(bodyBytes!);
                      var val = await Repositories.confirmAcknowledgement(
                          selectedJob?.serviceRequestid ?? "",
                          signature,
                          isWantInvoice,
                          emailCT.text.toString(),
                          payByCash
                              ? paymentMethods
                                  .where((element) =>
                                      element.method?.toLowerCase() == "cash")
                                  .toList()[0]
                                  .id
                                  .toString()
                              : paymentMethods
                                  .where((element) =>
                                      element.method?.toLowerCase() ==
                                      "scanned")
                                  .toList()[0]
                                  .id
                                  .toString());

                      if (val) {
                        if (!signatureErr && !errorEmail) {
                          //if (res) {
                          if (payNow) {
                            Navigator.pushNamed(context, 'payment',
                                arguments: [selectedJob, paymentDTO]);
                          } else {
                            Navigator.pushNamed(context, 'feedback',
                                arguments: [selectedJob, paymentDTO]);
                          }
                        } else {
                          Widget okButton = TextButton(
                            child: Text("OK"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          );

                          // set up the AlertDialog
                          AlertDialog alert = AlertDialog(
                            title: Text("Error"),
                            content: Text("Payment Could not be completed."),
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
                      }
                    }
                    // }
                    //  else {
                    //   Navigator.pushNamed(context, 'feedback',
                    //       arguments: [selectedJob, paymentDTO]);
                    // }
                  }),
            ),
          ],
        ),
      ),
    );
  }

  Future<File> _convertImageToFile(Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();
    File fileToBeUploaded = await File('${tempDir.path}/image.png').create();
    fileToBeUploaded.writeAsBytesSync(bytes);
    return fileToBeUploaded;
  }

  _fetchPaymentMethods() async {
    var res = await Repositories.fetchPaymentMethods();

    setState(() {
      paymentMethods = res;
    });
  }

  _processPayment() async {
    if (controller.isEmpty) {
      setState(() {
        signatureErr = true;
      });
    }

    if (signatureErr && !controller.isEmpty) {
      setState(() {
        signatureErr = false;
      });
      return false;
    }

    if (_formKey.currentState!.validate() && !signatureErr) {
      if (isWantInvoice && emailCT.text == "") {
        setState(() {
          errorEmail = true;
        });
        return false;
      }
      paymentDTO = new PaymentDTO();
      // paymentDTO.PMOneCT = PMOneCT.text;
      // paymentDTO.PMTwoCT = PMTwoCT.text;
      // paymentDTO.billing = billing;
      paymentDTO.dropDownOneSelectedText = dropDownOneSelectedText;
      paymentDTO.dropDownTwoSelectedText = PMLabelCT.text;
      paymentDTO.isWantInvoice = isWantInvoice;
      // paymentDTO.mixedPayment = mixedPayment;
      paymentDTO.payByCash = payByCash;
      // paymentDTO.payByCheque = payByCheque;
      paymentDTO.payNow = payNow;
      paymentDTO.emailCT = emailCT.text.toString();
      paymentDTO.paymentMethods = paymentMethods;
      // paymentDTO.pendingPayment = pendingPayment;
      paymentDTO.signatureController = controller;

      return true;
    } else {
      return false;
    }
  }

  _renderError() {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      // SizedBox(height: 10),
      SizedBox(height: 20),
    ]);
  }

  Future<bool> _onWillPop() async {
    Navigator.pop(context, true);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      key: _scaffoldKey,
      appBar: Helpers.customAppBar(context, _scaffoldKey,
          title: "Acknowledgement & Payment Options",
          isBack: true,
          isAppBarTranparent: true,
          hasActions: false, handleBackPressed: () {
        if (widget.data == 1) {
          Navigator.pushReplacementNamed(context, 'home', arguments: 0);
        } else {
          Navigator.pop(context, true);
        }
      }),
      //resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
          // physics: ClampingScrollPhysics(parent: NeverScrollableScrollPhysics()),
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              decoration: new BoxDecoration(color: Colors.white),
              child:
                  Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                _renderForm(),
                SizedBox(height: 10),
                //Expanded(child: _renderBottom()),
                //version != "" ? _renderVersion() : Container()
              ]))),
    );
  }
}
