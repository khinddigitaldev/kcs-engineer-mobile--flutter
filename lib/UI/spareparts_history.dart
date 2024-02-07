import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:kcs_engineer/model/spareparts/sparepart_history_item.dart';
import 'package:kcs_engineer/themes/text_styles.dart';
import 'package:kcs_engineer/util/api.dart';
import 'package:kcs_engineer/util/helpers.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class SparepartHistory extends StatefulWidget {
  int? data;
  SparepartHistory({this.data});

  @override
  _SparepartHistoryState createState() => _SparepartHistoryState();
}

class _SparepartHistoryState extends State<SparepartHistory> {
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
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
  List<SparePartHistoryItem> sparePartHistoryItemList = [];
  String selectedStartDate = "";
  String selectedEndDate = "";
  bool isFilterAdded = false;
  Timer? searchOnStoppedTyping;
  String currentSearchText = "";
  ScrollController? controller;
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    controller = ScrollController()..addListener(_scrollListener);
    _loadVersion();
    Future.delayed(Duration.zero, () {
      _fetchSparePartsHistory(selectedStartDate, selectedEndDate,
          currentSearchText, currentPage, true);
    });
  }

  @override
  void dispose() {
    controller?.removeListener(_scrollListener);
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

  void _scrollListener() async {
    if (controller?.position.atEdge ?? false) {
      bool isTop = controller?.position.pixels == 0;

      if (!isTop) {
        currentPage = currentPage + 1;
        var SpareParts = await _fetchSparePartsHistory(selectedStartDate,
            selectedEndDate, currentSearchText, currentPage, false);
      }
    }
  }

  _fetchSparePartsHistory(String startDate, String endDate, String searchText,
      int page, bool eraseEarlyRecords) async {
    Helpers.showAlert(context);
    List<SparePartHistoryItem> currentHistory = [];

    if (!eraseEarlyRecords) {
      currentHistory.addAll(sparePartHistoryItemList);
    }
    if (startDate != "" && endDate == "") {
      endDate = startDate;
    }
    var url = 'spareparts/history?per_page=20' +
        '&page=$currentPage' +
        (startDate != "" ? '&start_date=$startDate' : '') +
        (endDate != "" ? '&end_date=$endDate' : '') +
        (searchText != "" ? '&q=$searchText' : '');

    final response = await Api.bearerGet(url);
    print("#Resp: $jsonEncode(response)}");
    if (response["success"] != null) {
      var spareParts = (response['data']['data'] as List)
          .map((i) => SparePartHistoryItem.fromJson(i))
          .toList();

      currentHistory.addAll(spareParts);
    }
    Navigator.pop(context);
    setState(() {
      sparePartHistoryItemList = currentHistory;
    });
    //Navigator.pop(context);
  }

  // _loadToken() async {
  //   final accessToken = await storage.read(key: TOKEN);

  //   setState(() {
  //     token = accessToken;
  //   });
  // }

  void selectionChanged(DateRangePickerSelectionChangedArgs args) async {
    setState(() {
      isFilterAdded = true;
    });
    if (args.value.startDate != null) {
      selectedStartDate = DateFormat('yyyy-MM-dd').format(args.value.startDate);
    }
    if (args.value.endDate != null) {
      selectedEndDate = DateFormat('yyyy-MM-dd').format(args.value.endDate);
    }
  }

  Widget getDateRangePicker(BuildContext context) {
    selectedStartDate = "";
    selectedEndDate = "";
    return Container(
        height: 300,
        child: Card(
            child: SfDateRangePicker(
          view: DateRangePickerView.month,
          selectionMode: DateRangePickerSelectionMode.range,
          onSelectionChanged: selectionChanged,
        )));
  }

  _onChangeHandler(value) {
    const duration = Duration(
        milliseconds:
            2000); // set the duration that you want call search() after that.

    if (searchOnStoppedTyping != null) {
      setState(() => searchOnStoppedTyping!.cancel()); // clear timer
    }
    setState(() => searchOnStoppedTyping = new Timer(duration, () async {
          if (currentSearchText != value) {
            currentSearchText = value;
            currentPage = 1;
            await _fetchSparePartsHistory(selectedStartDate, selectedEndDate,
                currentSearchText, currentPage, true);
          }
        }));
  }

  Widget _renderForm() {
    return Container(
      padding: EdgeInsets.all(15),
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
                      text: 'Parts History',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          Divider(color: Colors.grey),
          SizedBox(height: 40),
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
                                  text: 'PARTS USED',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ]),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 20.0, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 40,
                        child: TextFormField(
                            focusNode: focusEmail,
                            onChanged: _onChangeHandler,
                            keyboardType: TextInputType.text,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Please enter email';
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
                              border: OutlineInputBorder(),
                              hintText: 'Search',
                              contentPadding: EdgeInsets.fromLTRB(0, 5, 0, 0),
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(
                                    top: 0), // add padding to adjust icon
                                child: Icon(Icons.search),
                              ),
                            )),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              Flexible(
                fit: FlexFit.tight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10.0, 0, 0, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.4,
                        height: 40.0,
                        child: Row(children: [
                          ElevatedButton(
                              child: Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: Wrap(
                                    children: [
                                      Icon(
                                        Icons.calendar_month,
                                        color: Colors.white,
                                        size: 24.0,
                                      ),
                                      SizedBox(
                                        width: 5,
                                      ),
                                      Text(
                                        'Filter',
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                        ),
                                      )
                                    ],
                                  )),
                              style: ButtonStyle(
                                  foregroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.black87.withOpacity(0.7)),
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.black87.withOpacity(0.7)),
                                  shape:
                                      MaterialStateProperty.all<RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                              borderRadius: BorderRadius.zero,
                                              side: BorderSide(
                                                  color: Colors.black87
                                                      .withOpacity(0.7))))),
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        insetPadding: EdgeInsets.symmetric(
                                            horizontal: 20),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              Container(
                                                child: Text(
                                                  'Pick a Date Range',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 20),
                                                ),
                                              ),
                                              SizedBox(height: 15.0),
                                              Container(
                                                  width: 300.0,
                                                  height: 300.0,
                                                  child: getDateRangePicker(
                                                      context)),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  ElevatedButton(
                                                      child: Padding(
                                                          padding: const EdgeInsets.all(
                                                              5.0),
                                                          child: Text(
                                                            'Cancel',
                                                            style: TextStyle(
                                                                fontSize: 20,
                                                                color: Colors
                                                                    .white),
                                                          )),
                                                      style: ButtonStyle(
                                                          foregroundColor:
                                                              MaterialStateProperty.all<Color>(
                                                                  Colors.black87
                                                                      .withOpacity(
                                                                          0.7)),
                                                          backgroundColor:
                                                              MaterialStateProperty.all<Color>(
                                                                  Colors.black87
                                                                      .withOpacity(
                                                                          0.7)),
                                                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                                              RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: Colors.black87.withOpacity(0.7))))),
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      }),
                                                  SizedBox(
                                                    width: 10,
                                                  ),
                                                  ElevatedButton(
                                                      child: Padding(
                                                          padding: const EdgeInsets.all(
                                                              5.0),
                                                          child: Text(
                                                            'Ok',
                                                            style: TextStyle(
                                                                fontSize: 20,
                                                                color: Colors
                                                                    .white),
                                                          )),
                                                      style: ButtonStyle(
                                                          foregroundColor:
                                                              MaterialStateProperty.all<Color>(
                                                                  Colors.black87
                                                                      .withOpacity(
                                                                          0.7)),
                                                          backgroundColor:
                                                              MaterialStateProperty.all<Color>(
                                                                  Colors.black87
                                                                      .withOpacity(
                                                                          0.7)),
                                                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                                              RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: Colors.black87.withOpacity(0.7))))),
                                                      onPressed: () async {
                                                        Helpers.showAlert(
                                                            context);
                                                        currentPage = 1;
                                                        await _fetchSparePartsHistory(
                                                            selectedStartDate,
                                                            selectedEndDate,
                                                            currentSearchText,
                                                            currentPage,
                                                            true);

                                                        Navigator.pop(context);
                                                        Navigator.pop(context);
                                                      }),
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                    });
                              }),
                          isFilterAdded
                              ? SizedBox(
                                  width: 20,
                                )
                              : new Container(),
                          isFilterAdded
                              ? ElevatedButton(
                                  child: Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: Wrap(
                                        children: [
                                          Icon(
                                            Icons.cancel,
                                            color: Colors.white,
                                            size: 24.0,
                                          ),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsets.fromLTRB(0, 4, 0, 0),
                                            child: Text(
                                              'Clear Filters',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          )
                                        ],
                                      )),
                                  style: ButtonStyle(
                                      foregroundColor:
                                          MaterialStateProperty.all<Color>(
                                              Colors.black87.withOpacity(0.7)),
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                              Colors.black87.withOpacity(0.7)),
                                      shape: MaterialStateProperty.all<
                                              RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                              borderRadius: BorderRadius.zero,
                                              side: BorderSide(
                                                  color: Colors.black87.withOpacity(0.7))))),
                                  onPressed: () async {
                                    setState(() {
                                      isFilterAdded = false;
                                    });
                                    selectedStartDate = "";
                                    selectedEndDate = "";
                                    Helpers.showAlert(context);
                                    currentPage = 1;
                                    await _fetchSparePartsHistory(
                                        selectedStartDate,
                                        selectedEndDate,
                                        currentSearchText,
                                        currentPage,
                                        true);
                                    Navigator.pop(context);
                                  })
                              : new Container(),
                        ]),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            height: 70,
            alignment: Alignment.centerLeft,
            child: DataTable(
                headingRowHeight: 70.0,
                dataRowHeight: 0.0,
                headingRowColor:
                    MaterialStateColor.resolveWith((states) => Colors.black87),
                columns: [
                  DataColumn(
                      label: Container(
                    width: MediaQuery.of(context).size.width * .09,
                    child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
                        child: Text('Date',
                            style:
                                TextStyle(fontSize: 14, color: Colors.white))),
                  )),
                  DataColumn(
                      label: Container(
                    width: MediaQuery.of(context).size.width * .09,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
                      child: Text('Job Id',
                          style: TextStyle(fontSize: 14, color: Colors.white)),
                    ),
                  )),
                  DataColumn(
                      label: Container(
                    width: MediaQuery.of(context).size.width * .15,
                    child: Text('Part Description',
                        style: TextStyle(fontSize: 14, color: Colors.white)),
                  )),
                  DataColumn(
                      label: Container(
                    alignment: Alignment.centerLeft,
                    width: MediaQuery.of(context).size.width * .7,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(50, 0, 80, 0),
                      child: Text('Quantity',
                          textAlign: TextAlign.left,
                          style: TextStyle(fontSize: 14, color: Colors.white)),
                    ),
                  )),
                ],
                rows: []),
          ),
          ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 900, minHeight: 200),
              child: Container(
                  child: Scrollbar(
                      child: ListView(
                          shrinkWrap: true,
                          controller: controller,
                          children: [
                    DataTable(
                      dataRowHeight: 70.0,
                      headingRowHeight: 0.0,
                      columns: [
                        DataColumn(
                            label: Container(
                          width: MediaQuery.of(context).size.width * .07,
                          child: Padding(
                              padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
                              child: new Container()),
                        )),
                        DataColumn(
                            label: Container(
                          width: MediaQuery.of(context).size.width * .07,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                            child: new Container(),
                          ),
                        )),
                        DataColumn(
                            label: Container(
                          width: MediaQuery.of(context).size.width * .15,
                          child: new Container(),
                        )),
                        DataColumn(
                            label: Container(
                          alignment: Alignment.centerLeft,
                          width: MediaQuery.of(context).size.width * .7,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(0, 0, 120, 0),
                            child: new Container(),
                          ),
                        )),
                      ],
                      rows:
                          sparePartHistoryItemList // Loops through dataColumnText, each iteration assigning the value to element
                              .map(
                                ((element) => DataRow(
                                      cells: <DataCell>[
                                        DataCell(Text(
                                            element?.date?.substring(
                                                    0,
                                                    element.date!
                                                        .indexOf('T')) ??
                                                "date error",
                                            style: TextStyle(
                                                fontSize:
                                                    13.0))), //Extracting from Map element the value
                                        DataCell(Text(
                                          element.jobRefNo ?? "",
                                          style: TextStyle(fontSize: 13.0),
                                        )),
                                        DataCell(Text(
                                          '${element.sparepartsCode} ${element.description}',
                                          style: TextStyle(fontSize: 13.0),
                                        )),
                                        DataCell(Padding(
                                            padding: EdgeInsets.fromLTRB(
                                                30, 0, 0, 0),
                                            child: Text(
                                                element.quantity!
                                                        .split('.')[0] ??
                                                    "",
                                                style: TextStyle(
                                                    fontSize: 13.0)))),
                                      ],
                                    )),
                              )
                              .toList(),
                    ),
                  ]))))
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
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: new BoxDecoration(
                            color: Colors.white.withOpacity(0.0)),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              errorMsg != "" ? _renderError() : Container(),
                              _renderForm(),
                              SizedBox(height: 10),
                              //Expanded(child: _renderBottom()),
                              //version != "" ? _renderVersion() : Container()
                            ]))))));
  }
}
