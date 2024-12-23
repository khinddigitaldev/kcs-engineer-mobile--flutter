import 'dart:async';
import 'dart:convert';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:kcs_engineer/model/acknowledgement/payment_history.dart';
import 'package:kcs_engineer/model/job/job.dart';
import 'package:kcs_engineer/model/payment/payment_history_item.dart';
import 'package:kcs_engineer/themes/app_colors.dart';
import 'package:kcs_engineer/util/api.dart';
import 'package:kcs_engineer/util/helpers.dart';
import 'package:kcs_engineer/util/repositories.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class PaymentHistory extends StatefulWidget {
  PaymentHistory();

  @override
  _PaymentHistoryState createState() => _PaymentHistoryState();
}

class _PaymentHistoryState extends State<PaymentHistory> with AfterLayoutMixin {
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController searchCT = new TextEditingController();
  TextEditingController filterCT = new TextEditingController();
  FocusNode focusSearch = new FocusNode();
  FocusNode focusFilter = new FocusNode();
  bool isLoading = false;
  bool showPassword = false;
  String errorMsg = "";
  String version = "";
  final storage = new FlutterSecureStorage();
  String? token;
  Job? selectedJob;

  String? type;
  String? description;
  String? quantity;
  String? price;
  String? remarks;

  Timer? searchOnStoppedTyping;
  String currentSearchText = "";
  ScrollController? controller;

  String startDate = "";
  String toDate = "";
  String tempStartDate = "";
  String tempToDate = "";
  bool isFiltersAdded = false;
  // int currentPage = 1;
  int? lastPage;
  List<PaymentHistoryMeta>? paymentHistories;
  List<PaymentHistoryMeta>? previousPaymentHistories;
  String? cursor;
  @override
  void initState() {
    // emailCT.text = 'khindtest1@gmail.com';
    // passwordCT.text = 'Abcd@1234';
    // emailCT.text = 'khindcustomerservice@gmail.com';
    // passwordCT.text = 'Khindanshin118';

    super.initState();
    controller = ScrollController()..addListener(_scrollListener);

    Future.delayed(Duration.zero, () {
      _loadVersion();
    });
    //_checkPermisions();
  }

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) async {
    setDates();

    await _fetchPaymentHistory(true);
  }

  setDates() {
    DateTime now = DateTime.now();
    DateTime tomorrow = now.add(Duration(days: 1));

    // Get date 30 days ago
    DateTime thirtyDaysAgo = now.subtract(Duration(days: 30));

    // Format dates in '2023-08-29T11:08:12Z' format

    setState(() {
      toDate = tomorrow.toString().replaceAll(' ', 'T');
      startDate = thirtyDaysAgo.toString().replaceAll(' ', 'T');
    });
    print("lala");
  }

  @override
  void dispose() {
    controller?.removeListener(_scrollListener);
    searchCT.dispose();
    filterCT.dispose();
    super.dispose();
  }

  _loadVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String pkgVersion = packageInfo.version;

    setState(() {
      version = pkgVersion;
    });
  }

  void _scrollListener() async {
    if (controller?.position.atEdge ?? false) {
      bool isTop = controller?.position.pixels == 0;

      if (!isTop) {
        cursor = DateTime.parse(paymentHistories?.last?.insertedDate ?? "")
            .add(Duration(days: 1))
            .toString();
        await _fetchPaymentHistory(false);
      }
    }
  }

  _onChangeHandler(value) {
    const duration = Duration(milliseconds: 2000);

    if (searchOnStoppedTyping != null) {
      setState(() => searchOnStoppedTyping!.cancel());
    }
    setState(() => searchOnStoppedTyping = new Timer(duration, () async {
          if (currentSearchText != value) {
            currentSearchText = value;
            cursor = DateTime.now().add(Duration(days: 1)).toString();

            await _fetchPaymentHistory(true);
          }
        }));
  }

  Widget _renderForm() {
    return Container(
      padding: EdgeInsets.all(10),
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
                style: const TextStyle(
                  fontSize: 29.0,
                  color: Colors.black,
                ),
                children: <TextSpan>[
                  TextSpan(
                      text: 'Payment History',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          Divider(color: Colors.grey),
          SizedBox(
            height: 20,
          ),
          SizedBox(
            height: 20,
          ),
          Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 250,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 40, child: new Container()),
                    ],
                  ),
                ),
                Spacer(),
                Row(children: [
                  GestureDetector(
                      onTap: () async {
                        Helpers.showDatePicker(context, () {
                          setState(() {
                            tempStartDate = "";
                            tempToDate = "";
                          });
                        }, (DateTime? strtDate, DateTime? endDate) {
                          setState(() {
                            tempStartDate = strtDate.toString();
                            tempToDate = endDate.toString();
                          });
                        }, () async {
                          setState(() {
                            startDate =
                                (tempStartDate ?? "").replaceFirst(" ", "T");
                            toDate = (tempToDate ?? "").replaceFirst(" ", "T");
                            filterCT.text =
                                '${startDate.split("T")[0]}-${toDate.split("T")[0]}';
                            isFiltersAdded = true;
                          });

                          _fetchPaymentHistory(true);
                          // _fetchKIVJobs(true);
                        });
                      },
                      child: Container(
                        alignment: Alignment.centerRight,
                        width: 200,
                        child: SizedBox(
                          height: 40,
                          child: TextFormField(
                            focusNode: focusFilter,
                            keyboardType: TextInputType.text,
                            onChanged: _onChangeHandler,
                            enabled: false,
                            controller: filterCT,
                            onFieldSubmitted: (val) {
                              FocusScope.of(context)
                                  .requestFocus(new FocusNode());
                            },
                            style: TextStyle(fontSize: 10, color: Colors.black),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Filter By',
                              contentPadding: EdgeInsets.fromLTRB(15, 5, 5, 5),
                              suffixIcon: Icon(Icons.calendar_month),
                            ),
                          ),
                        ),
                      )),
                  SizedBox(
                    width: 5,
                  ),
                  isFiltersAdded
                      ? Container(
                          color: Colors.white,
                          height: 40,
                          width: MediaQuery.of(context).size.width * 0.1,
                          child: ElevatedButton(
                              child: Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: Text(
                                    'CLEAR',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.white),
                                  )),
                              style: ButtonStyle(
                                  foregroundColor:
                                      MaterialStateProperty.all<Color>(
                                          AppColors.primary),
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          AppColors.primary),
                                  shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(5.0),
                                          side: BorderSide(
                                              color: AppColors.primary)))),
                              onPressed: () async {
                                setState(() {
                                  startDate = "";
                                  toDate = "";
                                  tempStartDate = "";
                                  tempToDate = "";
                                  isFiltersAdded = false;
                                  filterCT.text = "";
                                  cursor = DateTime.now()
                                      .add(Duration(days: 1))
                                      .toString();
                                });
                                await _fetchPaymentHistory(true);
                              }),
                        )
                      : new Container(),
                ])
              ]),
          SizedBox(height: 20),
          ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 1,
                  minWidth: MediaQuery.of(context).size.width * 1),
              child: Container(
                alignment: Alignment.centerLeft,
                child: DataTable(
                    columnSpacing: 10,
                    headingRowHeight: MediaQuery.of(context).size.height * 0.04,
                    dataRowHeight: 0.0,
                    headingRowColor: MaterialStateColor.resolveWith(
                        (states) => Colors.black87),
                    columns: [
                      DataColumn(
                          label: Container(
                        width: MediaQuery.of(context).size.width * .15,
                        child: Center(
                            child: Text('Date',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14))),
                      )),
                      DataColumn(
                          label: Container(
                        width: MediaQuery.of(context).size.width * .2,
                        child: Center(
                            child: Text('Cash given to CR',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14))),
                      )),
                      DataColumn(
                          label: Container(
                              width: MediaQuery.of(context).size.width * .22,
                              child: Center(
                                child: Text(
                                  'Status',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 14),
                                ),
                              ))),
                      DataColumn(
                          label: Container(
                        width: MediaQuery.of(context).size.width * .25,
                        child: Center(
                            child: Text('Action',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14))),
                      )),

                      // DataColumn(
                      //     label: Container(
                      //   width: MediaQuery.of(context).size.width * .114,
                      //   child: SizedBox(
                      //     width: 100,
                      //     //alignment: Alignment.centerRight,
                      //     child: Text('PAYMENT MODE',
                      //         maxLines: 2,
                      //         overflow: TextOverflow.ellipsis,
                      //         style:
                      //             TextStyle(color: Colors.white, fontSize: 11)),
                      //   ),
                      // )),
                    ],
                    rows: []),
              )),
          paymentHistories != null && (paymentHistories?.length ?? 0) > 0
              ? ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.9,
                      minHeight: MediaQuery.of(context).size.height * 0,
                      maxWidth: MediaQuery.of(context).size.width * 1,
                      minWidth: MediaQuery.of(context).size.width * 1),
                  child: Container(
                      width: MediaQuery.of(context).size.width * 1,
                      child: Scrollbar(
                          child: ListView(
                              shrinkWrap: true,
                              controller: controller,
                              children: [
                            DataTable(
                                columnSpacing: 5,
                                dataRowHeight: 70.0,
                                headingRowHeight: 0.0,
                                columns: [
                                  DataColumn(
                                      label: Container(
                                    alignment: Alignment.centerLeft,
                                    width:
                                        MediaQuery.of(context).size.width * .15,
                                    child: Padding(
                                        padding:
                                            EdgeInsets.fromLTRB(0, 0, 0, 0),
                                        child: new Container()),
                                  )),
                                  DataColumn(
                                      label: Container(
                                    alignment: Alignment.centerLeft,
                                    width:
                                        MediaQuery.of(context).size.width * .13,
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                                      child: new Container(),
                                    ),
                                  )),
                                  DataColumn(
                                      label: SizedBox(
                                    // alignment: Alignment.centerLeft,
                                    width:
                                        MediaQuery.of(context).size.width * .18,
                                    child: new Container(),
                                  )),
                                  DataColumn(
                                      label: Container(
                                    alignment: Alignment.centerLeft,
                                    width: MediaQuery.of(context).size.width *
                                        .045,
                                    child: Padding(
                                        padding:
                                            EdgeInsets.fromLTRB(0, 0, 0, 0),
                                        child: new Container()),
                                  )),
                                ],
                                rows: (paymentHistories ??
                                        []) // Loops through dataColumnText, each iteration assigning the value to element
                                    .map(
                                      ((element) => DataRow(
                                            cells: <DataCell>[
                                              DataCell(Container(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(element
                                                          .insertedDate ??
                                                      ""))), //Extracting from Map element the value
                                              DataCell(Container(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                      element.formatted ??
                                                          ""))),
                                              DataCell(Container(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(element
                                                          .paymentStatus ??
                                                      ""))), //Extracting from Map element the value
                                              DataCell(GestureDetector(
                                                  onTap: () {
                                                    Navigator.pushNamed(context,
                                                        'acknowledged_jobs_list',
                                                        arguments: [
                                                          element.insertedDate
                                                        ]);
                                                  },
                                                  child: Icon(
                                                      Icons
                                                          .remove_red_eye_rounded,
                                                      color: Color(0xFF323F4B))

                                                  //          Container(
                                                  // width:
                                                  //     MediaQuery.of(context)
                                                  //             .size
                                                  //             .height *
                                                  //         0.03,
                                                  // height:
                                                  //     MediaQuery.of(context)
                                                  //             .size
                                                  //             .height *
                                                  //         0.03,
                                                  // alignment:
                                                  //     Alignment.center,
                                                  // padding:
                                                  //     EdgeInsets.all(5),
                                                  // decoration: BoxDecoration(
                                                  //   color:
                                                  //       Color(0xFF323F4B),
                                                  //   shape: BoxShape.circle,
                                                  // ),
                                                  // child: Icon(
                                                  //     Icons
                                                  //         .remove_red_eye_rounded,
                                                  //     color:
                                                  //         Colors.white))

                                                  )),
                                            ],
                                          )),
                                    )
                                    .toList())
                          ]))))
              : Container()
        ]),
      ),
    );
  }

  _fetchPaymentHistory(bool erasePrevious) async {
    Helpers.showAlert(context);

    previousPaymentHistories = [];

    if (!erasePrevious) {
      setState(() {
        previousPaymentHistories?.addAll(paymentHistories ?? []);
      });
    }

    var res = await Repositories.fetchPaymentHistory(
        startDate, toDate, cursor ?? toDate.toString().split('T')[0]);

    setState(() {
      previousPaymentHistories?.addAll(res ?? []);
      paymentHistories = previousPaymentHistories;
    });
    print("lala");

    Navigator.pop(context);
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
    return Scaffold(
      key: _scaffoldKey,
      //resizeToAvoidBottomInset: false,
      appBar: Helpers.customAppBar(context, _scaffoldKey,
          title: "",
          isBack: true,
          isAppBarTranparent: true,
          hasActions: false, handleBackPressed: () {
        Navigator.pop(context);
        // var res = validateIfEditedValuesAreSaved();
        // if (res) {
        // }
      }),
      body: CustomPaint(
          child: SingleChildScrollView(
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration:
                      new BoxDecoration(color: Colors.white.withOpacity(0.0)),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        errorMsg != "" ? _renderError() : Container(),
                        _renderForm(),
                        SizedBox(height: 10),
                        //Expanded(child: _renderBottom()),
                        //version != "" ? _renderVersion() : Container()
                      ])))),
    );
  }
}
