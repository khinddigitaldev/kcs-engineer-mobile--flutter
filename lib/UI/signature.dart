import 'dart:io';
import 'dart:typed_data';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:kcs_engineer/model/job/job.dart';
import 'package:kcs_engineer/model/payment/payment_method.dart';
import 'package:kcs_engineer/model/payment/payment_request.dart';
import 'package:kcs_engineer/model/payment/rcpCost.dart';
import 'package:kcs_engineer/model/payment/rcpCost.dart';
import 'package:kcs_engineer/payment_method_icons.dart' as PaymentMethodIcons;
import 'package:kcs_engineer/themes/text_styles.dart';
import 'package:kcs_engineer/util/components/payment_image_uploader.dart';
import 'package:kcs_engineer/util/helpers.dart';
import 'package:kcs_engineer/util/repositories.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';

class SignatureUI extends StatefulWidget {
  Job? data;
  RCPCost? rcpCost;
  SignatureUI({this.data, this.rcpCost});

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
  bool isWantInvoice = false;
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

  Widget _renderCost(bool isStepper) {
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          Row(
            children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.black,
                  ),
                  children: <TextSpan>[
                    const TextSpan(
                      text: 'Total Charges',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * .2,
                  minHeight: MediaQuery.of(context).size.height * .1),
              child: Container(
                child: ListView(
                  children: [
                    widget.rcpCost?.sparePartCost != "MYR 0.00"
                        ? _buildChargeItem("Picklist charges (Estimated)",
                            widget.rcpCost?.pickListCost ?? "MYR 0.00", false)
                        : new Container(),
                    widget.rcpCost?.sparePartCost != "MYR 0.00" &&
                            (selectedJob?.aggregatedSpareparts?.length ?? 0) > 0
                        ? _buildChargeItem("Sparepart charges",
                            widget.rcpCost?.sparePartCost ?? "MYR 0.00", false)
                        : new Container(),
                    widget.rcpCost?.solutionCost != "MYR 0.00"
                        ? _buildChargeItem(
                            "Solution charges",
                            "MYR " +
                                (((widget.rcpCost?.solutionCost?.amountVal ??
                                            0))
                                        ?.toStringAsFixed(2) ??
                                    "0.00"),
                            false)
                        : new Container(),
                    widget.rcpCost?.miscCost != "MYR 0.00"
                        ? _buildChargeItem("Miscellaneous charges",
                            widget.rcpCost?.miscCost ?? "MYR 0.00", false)
                        : new Container(),
                    widget.rcpCost?.transportCost != "MYR 0.00"
                        ? _buildChargeItem("Transport charges",
                            widget.rcpCost?.transportCost ?? "MYR 0.00", false)
                        : new Container(),
                    widget.rcpCost?.pickupCost != "MYR 0.00"
                        ? _buildChargeItem("Pickup charges",
                            widget.rcpCost?.pickupCost ?? "MYR 0.00", false)
                        : new Container(),
                    widget.rcpCost?.totalSSTRCP != "MYR 0.00"
                        ? _buildChargeItem("Total SST",
                            widget.rcpCost?.totalSSTRCP ?? "MYR 0.00", false)
                        : new Container(),
                    SizedBox(
                      height: 3,
                    ),
                    Divider(),
                    SizedBox(
                      height: 3,
                    ),
                    widget.rcpCost?.discountTotalSumVal != "MYR 0.00"
                        ? _buildChargeItem(
                            "Discount",
                            "- MYR " +
                                (widget.rcpCost?.discountTotalSumVal
                                        ?.toStringAsFixed(2) ??
                                    "MYR 0.00"),
                            false)
                        : new Container(),
                    _buildChargeItem(
                        (widget.rcpCost?.isDiscountValid ?? false) &&
                                widget.rcpCost?.discountPercentage != "0%"
                            ? "Total"
                            : "Grand Total",
                        'MYR ${((widget.rcpCost?.totalAmount ?? 0) + (widget.rcpCost?.totalAmountSST ?? 0) - (widget.rcpCost?.discountTotalSumVal ?? 0)).toStringAsFixed(2)}',
                        true),
                    (widget.rcpCost?.isDiscountValid ?? false) &&
                            widget.rcpCost?.discountPercentage != "0%"
                        ? _buildChargeItem(
                            '${widget.rcpCost?.discountPercentage} Discount applied',
                            widget.rcpCost?.discount ?? "MYR 0.00",
                            true)
                        : new Container(),
                    (widget.rcpCost?.isDiscountValid ?? false) &&
                            widget.rcpCost?.discountPercentage != "0%"
                        ? Divider()
                        : new Container(),
                    (widget.rcpCost?.isDiscountValid ?? false) &&
                            widget.rcpCost?.discountPercentage != "0%"
                        ? _buildChargeItem(
                            "Grand Total",
                            'MYR ${((widget.rcpCost?.totalAmountRCP ?? 0) + (widget.rcpCost?.totalAmountSSTRCP ?? 0) - (widget.rcpCost?.rcpDiscountTotalSumVal ?? 0)).toStringAsFixed(2)}',
                            true)
                        : new Container(),
                  ],
                ),
              ))
        ]));
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
            Divider(),
            (((widget.rcpCost?.isDiscountValid ?? false)
                        ? widget.rcpCost?.totalRCP
                        : widget.rcpCost?.total) !=
                    "MYR 0.00")
                ? _renderCost(false)
                : new Container(),
            Divider(),
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
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: Colors.black,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text:
                              'I $consumerName hereby acknowledge the receipt of the product and service promised from KHIND.',
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
            Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: Color(0xFFE7F3FF),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                      child: Column(
                        children: [
                          RichText(
                            text: TextSpan(
                                style: TextStyle(
                                  fontSize: 25.0,
                                  color: Colors.blue,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: (widget.rcpCost?.isDiscountValid ??
                                              false)
                                          ? 'MYR ${((widget.rcpCost?.totalAmountRCP ?? 0) + (widget.rcpCost?.totalAmountSST ?? 0) - (widget.rcpCost?.rcpDiscountTotalSumVal ?? 0)).toStringAsFixed(2)}'
                                          : 'MYR ${((widget.rcpCost?.totalAmount ?? 0) + (widget.rcpCost?.totalAmountSST ?? 0) - (widget.rcpCost?.rcpDiscountTotalSumVal ?? 0)).toStringAsFixed(2)}'),
                                ]),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          RichText(
                            text: TextSpan(
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
                  ),
                ]),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.05,
            ),
            (((widget.rcpCost?.isDiscountValid ?? false)
                        ? widget.rcpCost?.totalRCP
                        : widget.rcpCost?.total) !=
                    "MYR 0.00")
                ? Row(
                    children: [
                      RichText(
                        text: TextSpan(
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
                  )
                : new Container(),
            SizedBox(height: 30),
            (((widget.rcpCost?.isDiscountValid ?? false)
                        ? widget.rcpCost?.totalRCP
                        : widget.rcpCost?.total) !=
                    "MYR 0.00")
                ? Row(
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
                                    color: payByCash
                                        ? Colors.white
                                        : Colors.black87,
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
                                    "DuitNow",
                                    style: TextStyle(
                                      fontSize: 19.0,
                                      color: payNow
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Icon(
                                    // <-- Icon
                                    PaymentMethodIcons.PaymentMethod.paynow,
                                    color:
                                        payNow ? Colors.white : Colors.black87,
                                    size: 35.0,
                                  )
                                ],
                              ))),
                    ],
                  )
                : new Container(),
            SizedBox(height: 70),
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
                    if (!isLoading) {
                      var res = await _processPayment();
                      Uint8List? bodyBytes =
                          await paymentDTO.signatureController?.toPngBytes();
                      File signature = await _convertImageToFile(bodyBytes!);
                      if (res) {
                        if (paymentMethods != null &&
                            paymentMethods.isNotEmpty) {
                          if (payNow) {
                            Navigator.pushNamed(context, 'payment', arguments: [
                              selectedJob,
                              paymentDTO,
                              widget.rcpCost,
                              signature,
                              isWantInvoice,
                              payByCash,
                              emailCT.text.toString(),
                              paymentMethods
                            ]);
                          } else {
                            setState(() {
                              isLoading = true;
                            });
                            var val = await Repositories.confirmAcknowledgement(
                                selectedJob?.serviceRequestid ?? "",
                                signature,
                                null,
                                isWantInvoice,
                                emailCT.text.toString(),
                                (((widget.rcpCost?.isDiscountValid ?? false)
                                            ? widget.rcpCost?.totalRCP
                                            : widget.rcpCost?.total) !=
                                        "MYR 0.00")
                                    ? payByCash
                                        ? paymentMethods
                                            .where((element) =>
                                                element.method?.toLowerCase() ==
                                                "cash")
                                            .toList()[0]
                                            .id
                                            .toString()
                                        : paymentMethods
                                            .where((element) =>
                                                element.method?.toLowerCase() ==
                                                "scanned")
                                            .toList()[0]
                                            .id
                                            .toString()
                                    : "3");
                            setState(() {
                              isLoading = false;
                            });

                            if (val) {
                              if (!signatureErr && !errorEmail) {
                                //if (res) {

                                Navigator.pushNamed(
                                    context, 'feedback_confirmation',
                                    arguments: selectedJob);
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
                                  content:
                                      Text("Payment Could not be completed."),
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
                            } else {
                              Helpers.showAlert(context,
                                  hasAction: true,
                                  type: "error",
                                  title: "Something went wrong.",
                                  onPressed: () async {
                                Navigator.pop(context);
                              });
                            }
                          }
                        } else {
                          Helpers.showAlert(context,
                              hasAction: true,
                              type: "error",
                              title: "Could not find any payment methods.",
                              onPressed: () async {
                            Navigator.pop(context);
                          });
                        }
                      }
                    }
                  }),
            ),
          ],
        ),
      ),
    );
  }

  showMultipleImagesPromptDialog(BuildContext context, String jobId, File image,
      bool isMailInvoice, String mailEmail, String paymentMethodId) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SignatureMultiImageUploadDialog(
          jobId: jobId,
          image: image,
          isMailInvoice: isMailInvoice,
          mailEmail: mailEmail,
          paymentMethodId: paymentMethodId,
        );
      },
    ).then((value) async {
      if (value != null && value) {
        Navigator.pushNamed(context, 'feedback_confirmation',
            arguments: selectedJob);
      } else {
        Helpers.showAlert(context,
            hasAction: true,
            title: "Payment Could not be completed.",
            type: "error", onPressed: () async {
          Navigator.pop(context);
        });
      }
    });
  }

  Future<File> _convertImageToFile(Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();
    File fileToBeUploaded = await File('${tempDir.path}/image.png').create();
    fileToBeUploaded.writeAsBytesSync(bytes);
    return fileToBeUploaded;
  }

  _fetchPaymentMethods() async {
    var res = await Repositories.fetchPaymentMethods(
        widget.data?.serviceRequestid ?? "");

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

    if (!signatureErr) {
      paymentDTO = new PaymentDTO();
      paymentDTO.dropDownOneSelectedText = dropDownOneSelectedText;
      paymentDTO.dropDownTwoSelectedText = PMLabelCT.text;
      paymentDTO.isWantInvoice = isWantInvoice;
      paymentDTO.payByCash = payByCash;
      paymentDTO.payNow = payNow;
      paymentDTO.emailCT = emailCT.text.toString();
      paymentDTO.paymentMethods = paymentMethods;
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
      backgroundColor: Colors.white,
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

Widget _buildChargeItem(String chargeType, String cost, bool isTotal) {
  return Padding(
      padding: EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(chargeType,
              style: TextStyle(
                  fontSize: 16.0,
                  color: isTotal ? Colors.black : Colors.black54)),
          Text(cost,
              style: TextStyle(
                  fontSize: 16.0,
                  color: isTotal ? Colors.black : Colors.black54)),
        ],
      ));
}
