import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:kcs_engineer/model/job/job.dart';
import 'package:kcs_engineer/model/payment/payment_history_item.dart';
import 'package:kcs_engineer/themes/app_colors.dart';
import 'package:kcs_engineer/util/api.dart';
import 'package:kcs_engineer/util/helpers.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class PaymentHistory extends StatefulWidget {
  PaymentHistory();

  @override
  _PaymentHistoryState createState() => _PaymentHistoryState();
}

class _PaymentHistoryState extends State<PaymentHistory> {
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
  String endDate = "";
  String tempStartDate = "";
  String tempEndDate = "";
  bool isFiltersAdded = false;
  int currentPage = 1;
  int? lastPage;
  List<PaymentHistoryItem>? paymentHistories;
  List<PaymentHistoryItem>? previousPaymentHistories;

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
      _fetchPaymentHistory(true);
    });
    //_checkPermisions();
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
        currentPage = currentPage + 1;
        var SpareParts = await _fetchPaymentHistory(false);
      }
    }
  }

  _onChangeHandler(value) {
    const duration = Duration(
        milliseconds:
            2000); // set the duration tat you want call search() after that.

    if (searchOnStoppedTyping != null) {
      setState(() => searchOnStoppedTyping!.cancel()); // clear timer
    }
    setState(() => searchOnStoppedTyping = new Timer(duration, () async {
          if (currentSearchText != value) {
            currentSearchText = value;
            currentPage = 1;
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
          Padding(
            padding: EdgeInsets.fromLTRB(10.0, 0, 0, 0),
            child: Container(
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                    style: const TextStyle(
                      fontSize: 25.0,
                      color: Colors.black,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'LIST OF PAYMENTS',
                      ),
                    ]),
              ),
            ),
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
                        await showDatePicker();
                      },
                      child: Container(
                        alignment: Alignment.centerRight,
                        width: 200,
                        child: SizedBox(
                          height: 40,
                          child: TextFormField(
                            focusNode: focusFilter,
                            keyboardType: TextInputType.text,
                            //onChanged: _onChangeHandlerForCompletion,
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
                                  endDate = "";
                                  tempStartDate = "";
                                  tempEndDate = "";
                                  isFiltersAdded = false;
                                  filterCT.text = "";
                                  currentPage = 1;
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
                    headingRowHeight: 70.0,
                    dataRowHeight: 0.0,
                    headingRowColor: MaterialStateColor.resolveWith(
                        (states) => Colors.black87),
                    columns: [
                      DataColumn(
                          label: Container(
                        width: MediaQuery.of(context).size.width * .08,
                        child: Center(
                            child: Text('DATE',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11))),
                      )),
                      DataColumn(
                          label: Container(
                        width: MediaQuery.of(context).size.width * .1,
                        child: Center(
                            child: Text('JOB ID',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11))),
                      )),
                      DataColumn(
                          label: Container(
                              width: MediaQuery.of(context).size.width * .25,
                              child: Center(
                                child: Text(
                                  'JOB STATUS',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 11),
                                ),
                              ))),
                      DataColumn(
                          label: Container(
                        width: MediaQuery.of(context).size.width * .12,
                        child: Center(
                            child: Text('CHARGEABLE',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11))),
                      )),
                      DataColumn(
                          label: Center(
                              child: SizedBox(
                        width: MediaQuery.of(context).size.width * .08,
                        child: Center(
                          child: Text(
                            'PAYMENT MODE',
                            overflow: TextOverflow.visible,
                            softWrap: true,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ))),
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
                      DataColumn(
                        label: Container(
                            width: MediaQuery.of(context).size.width * .08,
                            child: Center(
                              child: Text(
                                'AMOUNT',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            )),
                      )
                    ],
                    rows: []),
              )),
          ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: 900,
                  minHeight: 200,
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
                                width: MediaQuery.of(context).size.width * .04,
                                child: Padding(
                                    padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                                    child: new Container()),
                              )),
                              DataColumn(
                                  label: Container(
                                alignment: Alignment.centerLeft,
                                width: MediaQuery.of(context).size.width * .05,
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                                  child: new Container(),
                                ),
                              )),
                              DataColumn(
                                  label: SizedBox(
                                // alignment: Alignment.centerLeft,
                                width: MediaQuery.of(context).size.width * .045,
                                child: new Container(),
                              )),
                              DataColumn(
                                  label: Container(
                                alignment: Alignment.centerLeft,
                                width: MediaQuery.of(context).size.width * .045,
                                child: Padding(
                                    padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                                    child: new Container()),
                              )),
                              DataColumn(
                                  label: Container(
                                alignment: Alignment.centerRight,
                                width: MediaQuery.of(context).size.width * .045,
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                                  child: new Container(),
                                ),
                              )),
                              DataColumn(
                                  label: Container(
                                alignment: Alignment.centerLeft,
                                width: MediaQuery.of(context).size.width * .045,
                                child: new Container(),
                              )),
                            ],
                            rows: (paymentHistories ??
                                    []) // Loops through dataColumnText, each iteration assigning the value to element
                                .map(
                                  ((element) => DataRow(
                                        cells: <DataCell>[
                                          DataCell(Container(
                                              alignment: Alignment.centerLeft,
                                              child: Text(element.date ??
                                                  ""))), //Extracting from Map element the value
                                          DataCell(Container(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                  element.orderReferenceNo ??
                                                      ""))),
                                          DataCell(Container(
                                              alignment: Alignment.centerLeft,
                                              child: Text(element.orderStatus ??
                                                  ""))), //Extracting from Map element the value
                                          DataCell(Container(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                  (element.chargeable == "1")
                                                      ? "YES"
                                                      : "NO"))),
                                          DataCell(Container(
                                              alignment: Alignment.center,
                                              child: Text(element
                                                      .paymentMethod ??
                                                  ""))), //Extracting from Map element the value
                                          DataCell(Container(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                  element.paymentAmount ??
                                                      ""))),
                                        ],
                                      )),
                                )
                                .toList())
                      ]))))
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

    var url = 'payment/history?per_page=20&page=$currentPage' +
        ((startDate != "") ? '&start_date=$startDate' : '') +
        ((endDate != "")
            ? '&end_date=$endDate'
            : ((startDate != "") ? '&end_date=$startDate' : '')) +
        ((searchCT.text != "") ? '&q=${searchCT.text}' : '');

    final response = await Api.bearerGet(url);
    print("#Resp: ${jsonEncode(response)}");
    // Navigator.pop(context);
    if (response["success"] != null) {
      setState(() {
        lastPage = response['meta']['last_page'];
      });

      var res = (response['data'] as List)
          .map((i) => PaymentHistoryItem.fromJson(i))
          .toList();

      setState(() {
        paymentHistories = res;
      });
    } else {
      //show ERROR
    }

    Navigator.pop(context);
  }

  showDatePicker() {
    AlertDialog filterDialog = AlertDialog(
      title: Center(child: Text("Pick a Date")),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        Container(
          color: Colors.white,
          height: MediaQuery.of(context).size.height * 0.04,
          width: MediaQuery.of(context).size.width * 0.3,
          child: ElevatedButton(
              child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text(
                    'CANCEL',
                    style: TextStyle(fontSize: 13, color: Colors.white),
                  )),
              style: ButtonStyle(
                  foregroundColor:
                      MaterialStateProperty.all<Color>(AppColors.primary),
                  backgroundColor:
                      MaterialStateProperty.all<Color>(AppColors.primary),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                          side: BorderSide(color: AppColors.primary)))),
              onPressed: () async {
                Navigator.pop(context);
              }),
        ),
        Container(
          height: MediaQuery.of(context).size.height * 0.04,
          width: MediaQuery.of(context).size.width * 0.3,
          child: ElevatedButton(
              child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text(
                    'DONE',
                    style: TextStyle(fontSize: 13, color: Colors.white),
                  )),
              style: ButtonStyle(
                  foregroundColor:
                      MaterialStateProperty.all<Color>(AppColors.primary),
                  backgroundColor:
                      MaterialStateProperty.all<Color>(AppColors.primary),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                          side: BorderSide(color: AppColors.primary)))),
              onPressed: () async {
                setState(() {
                  startDate = tempStartDate;
                  endDate = tempEndDate;
                  isFiltersAdded = true;
                  currentPage = 1;
                });
                filterCT.text = '${tempStartDate} - ${tempEndDate}';
                await _fetchPaymentHistory(true);
                Navigator.pop(context);
              }),
        )
      ],
      content: Container(
        height: MediaQuery.of(context).size.height * 0.4,
        width: MediaQuery.of(context).size.width * 0.6,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            width: 0.4,
            color: Colors.grey.withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
                blurRadius: 5, color: Colors.grey[200]!, offset: Offset(0, 10)),
          ],
          borderRadius: BorderRadius.circular(7.5),
        ),
        child: SfDateRangePicker(
          headerHeight: 60,
          selectionMode: DateRangePickerSelectionMode.range,
          headerStyle: DateRangePickerHeaderStyle(
              textStyle: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 20,
                  color: Colors.black)),
          selectionTextStyle: TextStyle(
              fontWeight: FontWeight.w400, fontSize: 16, color: Colors.black),
          monthCellStyle: DateRangePickerMonthCellStyle(
            textStyle: TextStyle(
                fontWeight: FontWeight.w400, fontSize: 16, color: Colors.black),
            leadingDatesDecoration: BoxDecoration(
                color: const Color(0xFFDFDFDF),
                border: Border.all(color: const Color(0xFFB6B6B6), width: 1),
                shape: BoxShape.circle),
          ),
          onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
            setState(() {
              if (args.value.startDate != null) {
                tempStartDate =
                    DateFormat('yyyy-MM-dd').format(args.value.startDate);
              }
              if (args.value.endDate != null) {
                tempEndDate =
                    DateFormat('yyyy-MM-dd').format(args.value.endDate);
              } else if (args.value.startDate != null) {
                tempEndDate = tempStartDate;
              }
            });
          },
        ),
      ),
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return filterDialog;
      },
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
    return Scaffold(
      key: _scaffoldKey,
      //resizeToAvoidBottomInset: false,
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
