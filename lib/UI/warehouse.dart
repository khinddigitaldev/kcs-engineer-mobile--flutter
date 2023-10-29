import 'dart:async';
import 'dart:convert';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kcs_engineer/model/general_code.dart';
import 'package:kcs_engineer/model/job.dart';
import 'package:kcs_engineer/model/sparepart.dart';
import 'package:kcs_engineer/themes/text_styles.dart';
import 'package:kcs_engineer/util/api.dart';
import 'package:kcs_engineer/util/helpers.dart';
import 'package:kcs_engineer/util/repositories.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Warehouse extends StatefulWidget {
  String? jobId;
  Warehouse({this.jobId});

  @override
  _WarehouseState createState() => _WarehouseState();
}

class _WarehouseState extends State<Warehouse> with AfterLayoutMixin {
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController warehouseSearchCT = new TextEditingController();
  TextEditingController codeSearchCT = new TextEditingController();

  FocusNode focusWarehouseSearch = new FocusNode();
  bool isLoading = false;
  bool showPassword = false;
  String errorMsg = "";
  String version = "";
  final storage = new FlutterSecureStorage();
  String? token;
  String? jobId;
  Job? selectedJob;

  String? type;
  String? sparepartsId;
  String? sparepartsCode;
  String? description;
  String? quantity;
  String? price;
  String? remarks;
  List<SparePart> sparePartList = [];
  List<GeneralCode> generalCodeList = [];

  bool isSpareParts = true;
  bool isGeneralCode = false;

  List<SparePart> addedSparePartQuantities = [];
  List<GeneralCode> addedGeneralCodeQuantities = [];

  Timer? searchOnStoppedTyping;
  String currentSearchText = "";
  ScrollController? controller;
  int sparePartsCurrentPage = 1;
  int generalCodeCurrentPage = 1;
  int sparePartsMaxPages = 10;
  int generalCodeMaxPages = 10;

  @override
  void initState() {
    // emailCT.text = 'khindtest1@gmail.com';
    // passwordCT.text = 'Abcd@1234';
    // emailCT.text = 'khindcustomerservice@gmail.com';
    // passwordCT.text = 'Khindanshin118';

    super.initState();
    controller = ScrollController()..addListener(_scrollListener);

    jobId = widget.jobId;

    addedSparePartQuantities = [];
    addedGeneralCodeQuantities = [];

    Future.delayed(Duration.zero, () {});
    //_checkPermisions();
  }

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) async {
    await fetchJobDetails();
    _loadVersion();
    await _fetchSpareParts(true, false);
    // _fetchGeneralCodes(true);
  }

  fetchJobDetails() async {
    Helpers.showAlert(context);
    var job = await Repositories.fetchJobDetails(jobId: jobId);
    Navigator.pop(context);
    if (mounted) {
      setState(() {
        selectedJob = job;
      });
    }
  }

  @override
  void dispose() {
    controller?.removeListener(_scrollListener);
    warehouseSearchCT.dispose();
    codeSearchCT.dispose();
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
        if (isSpareParts && sparePartsCurrentPage <= sparePartsMaxPages) {
          sparePartsCurrentPage = sparePartsCurrentPage + 1;
          var SpareParts = await _fetchSpareParts(false, false);
        } else if (!isSpareParts &&
            generalCodeCurrentPage <= generalCodeMaxPages) {
          generalCodeCurrentPage = generalCodeCurrentPage + 1;
          var SpareParts = await _fetchGeneralCodes(false);
        }
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
            if (isSpareParts) {
              sparePartsCurrentPage = 1;
              await _fetchSpareParts(true, false);
            } else {
              generalCodeCurrentPage = 1;
              await _fetchGeneralCodes(true);
            }
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
                      text: 'Warehouse',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          Divider(color: Colors.grey),
          SizedBox(height: 20),
          Row(
            children: [
              // ElevatedButton(
              //     child: Padding(
              //       padding: const EdgeInsets.all(0.0),
              //       child: Text(
              //         'Spare Parts',
              //         style: TextStyle(
              //             fontSize: 15,
              //             color: isSpareParts ? Colors.white : Colors.black87),
              //       ),
              //     ),
              //     style: ButtonStyle(
              //         foregroundColor: MaterialStateProperty.all<Color>(
              //             isSpareParts ? Colors.black87 : Colors.white),
              //         backgroundColor: MaterialStateProperty.all<Color>(
              //             isSpareParts ? Colors.black87 : Colors.white),
              //         shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              //             RoundedRectangleBorder(
              //                 borderRadius: BorderRadius.circular(4.0),
              //                 side: BorderSide(
              //                     color: isSpareParts
              //                         ? Colors.black87
              //                         : Colors.white)))),
              //     onPressed: () async {
              //       //Helpers.showAlert(context);
              //       setState(() {
              //         isSpareParts = !isSpareParts;
              //         isGeneralCode = !isGeneralCode;
              //       });
              //     }),
              // SizedBox(
              //   width: 20,
              // ),
              // ElevatedButton(
              //     child: Padding(
              //         padding: const EdgeInsets.all(0.0),
              //         child: Text(
              //           'Miscellaneous',
              //           style: TextStyle(
              //               fontSize: 15,
              //               color:
              //                   isGeneralCode ? Colors.white : Colors.black87),
              //         )),
              //     style: ButtonStyle(
              //         foregroundColor: MaterialStateProperty.all<Color>(
              //             isGeneralCode ? Colors.black87 : Colors.white),
              //         backgroundColor: MaterialStateProperty.all<Color>(
              //             isGeneralCode ? Colors.black87 : Colors.white),
              //         shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              //             RoundedRectangleBorder(
              //                 borderRadius: BorderRadius.circular(4.0),
              //                 side: BorderSide(
              //                     color: isGeneralCode
              //                         ? Colors.black87
              //                         : Colors.white)))),
              //     onPressed: () async {
              //       setState(() {
              //         isSpareParts = !isSpareParts;
              //         isGeneralCode = !isGeneralCode;
              //       });
              //     })
            ],
          ),
          SizedBox(height: 20),
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
                                  text: isSpareParts
                                      ? 'PARTS LIST'
                                      : 'GENERAL CODE',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
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
                                      'Cancel',
                                      style: TextStyle(
                                          fontSize: 15, color: Colors.black54),
                                    )),
                                style: ButtonStyle(
                                    foregroundColor:
                                        MaterialStateProperty.all<Color>(
                                            Colors.white),
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                            Colors.white),
                                    shape: MaterialStateProperty.all<
                                            RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4.0),
                                            side: BorderSide(
                                                color: Colors.black54)))),
                                onPressed: () {
                                  Navigator.pop(context);
                                }),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width *
                                0.2, // <-- match_parent
                            height: MediaQuery.of(context).size.width *
                                0.05, // <-- match-parent
                            child: ElevatedButton(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      isSpareParts
                                          ? 'Add Parts'
                                          : 'Add General Code',
                                      style: TextStyle(
                                          fontSize: 15, color: Colors.white),
                                    ),
                                  ],
                                ),
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
                                onPressed: () async {
                                  Helpers.showAlert(context);
                                  if (isSpareParts) {
                                    if (await _AddSparePartsToJob()) {
                                      Navigator.pop(context, true);
                                    } else {
                                      Navigator.pop(context, true);
                                    }
                                  } else {
                                    if (await _AddGeneralCodeToJob()) {
                                      Navigator.pop(context, true);
                                    } else {
                                      Navigator.pop(context, true);
                                    }
                                  }

                                  Navigator.pop(context, true);
                                }),
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
            height: 10,
          ),
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
                      TextFormField(
                          focusNode: focusWarehouseSearch,
                          keyboardType: TextInputType.text,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter email';
                            }
                            return null;
                          },
                          onChanged: _onChangeHandler,
                          controller: warehouseSearchCT,
                          onFieldSubmitted: (val) {
                            FocusScope.of(context)
                                .requestFocus(new FocusNode());
                          },
                          style: TextStyles.textDefaultBold,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 10),
                            border: OutlineInputBorder(),
                            hintText: 'Search',
                          )),
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
                    children: [],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          isSpareParts
              ? Container(
                  alignment: Alignment.centerLeft,
                  child: DataTable(
                      headingRowHeight: 70.0,
                      dataRowHeight: 0.0,
                      headingRowColor: MaterialStateColor.resolveWith(
                          (states) => Colors.black87),
                      columns: [
                        DataColumn(
                            label: Container(
                          width: MediaQuery.of(context).size.width * .15,
                          child: Padding(
                              padding: EdgeInsets.fromLTRB(30, 0, 0, 0),
                              child: Text('Code',
                                  style: TextStyle(color: Colors.white))),
                        )),
                        DataColumn(
                            label: Container(
                          width: MediaQuery.of(context).size.width * .14,
                          child: Padding(
                              padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
                              child: Text('Part Name',
                                  style: TextStyle(color: Colors.white))),
                        )),
                        DataColumn(
                            label: Container(
                          width: MediaQuery.of(context).size.width * .18,
                          child: Padding(
                              padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
                              child: Text('Remaining Stock',
                                  style: TextStyle(color: Colors.white))),
                        )),
                        DataColumn(
                            label: Container(
                          width: MediaQuery.of(context).size.width * .25,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                            child: Text('Add/Remove',
                                style: TextStyle(color: Colors.white)),
                          ),
                        )),
                      ],
                      rows: []),
                )
              : Container(
                  alignment: Alignment.centerLeft,
                  child: DataTable(
                      headingRowHeight: 70.0,
                      dataRowHeight: 0.0,
                      headingRowColor: MaterialStateColor.resolveWith(
                          (states) => Colors.black87),
                      columns: [
                        DataColumn(
                            label: Container(
                          width: MediaQuery.of(context).size.width * .2,
                          child: Text('Code',
                              style: TextStyle(color: Colors.white)),
                        )),
                        DataColumn(
                            label: Container(
                          width: MediaQuery.of(context).size.width * .33,
                          child: Padding(
                              padding: EdgeInsets.fromLTRB(30, 0, 0, 0),
                              child: Text('Part Name',
                                  style: TextStyle(color: Colors.white))),
                        )),
                        DataColumn(
                            label: Container(
                          width: MediaQuery.of(context).size.width * .26,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                            child: Text('Add/Remove',
                                style: TextStyle(color: Colors.white)),
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
                    isSpareParts
                        ? DataTable(
                            dataRowHeight: 70.0,
                            headingRowHeight: 0.0,
                            columns: [
                              DataColumn(
                                  label: Container(
                                width: MediaQuery.of(context).size.width * .15,
                                child: Padding(
                                    padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
                                    child: new Container()),
                              )),
                              DataColumn(
                                  label: Container(
                                width: MediaQuery.of(context).size.width * .16,
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                  child: new Container(),
                                ),
                              )),
                              DataColumn(
                                  label: Container(
                                width: MediaQuery.of(context).size.width * .15,
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                  child: new Container(),
                                ),
                              )),
                              DataColumn(
                                  label: Container(
                                width: MediaQuery.of(context).size.width * .18,
                                child: new Container(),
                              )),
                            ],
                            rows:
                                sparePartList // Loops through dataColumnText, each iteration assigning the value to element
                                    .map(
                                      ((element) => DataRow(
                                            cells: <DataCell>[
                                              DataCell(Text(element.code ??
                                                  "")), //Extracting from Map element the value
                                              DataCell(Text(
                                                  element.description ?? "")),
                                              DataCell(
                                                Container(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  //color: Colors.white,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      element.quantity != 0
                                                          ? RichText(
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              text: TextSpan(
                                                                // Note: Styles for TextSpans must be explicitly defined.
                                                                // Child text spans will inherit styles from parent
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize:
                                                                      12.0,
                                                                  color: Colors
                                                                      .black,
                                                                ),
                                                                children: <
                                                                    TextSpan>[
                                                                  TextSpan(
                                                                      text: element
                                                                          .quantity
                                                                          .toString(),
                                                                      style: const TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.bold)),
                                                                ],
                                                              ),
                                                            )
                                                          : RichText(
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              text: TextSpan(
                                                                // Note: Styles for TextSpans must be explicitly defined.
                                                                // Child text spans will inherit styles from parent
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize:
                                                                      15.0,
                                                                  color: Colors
                                                                      .black,
                                                                ),
                                                                children: <
                                                                    TextSpan>[
                                                                  TextSpan(
                                                                      text:
                                                                          'Out of Stock',
                                                                      style:
                                                                          const TextStyle()),
                                                                ],
                                                              ),
                                                            ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Container(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    //color: Colors.white,
                                                    child: element.quantity != 0
                                                        ? Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .center,
                                                            children: [
                                                              IconButton(
                                                                  icon:
                                                                      new Icon(
                                                                    color: element.quantity ==
                                                                            0
                                                                        ? Colors
                                                                            .black54
                                                                        : Colors
                                                                            .black,
                                                                    Icons
                                                                        .remove,
                                                                    size: 11.0,
                                                                  ),
                                                                  onPressed:
                                                                      () => {
                                                                            if (element.quantity !=
                                                                                0)
                                                                              {
                                                                                if (addedSparePartQuantities.contains(element))
                                                                                  {
                                                                                    addedSparePartQuantities.forEach((d) {
                                                                                      if (d.id == element.id) {
                                                                                        d.selectedQuantity = (d.selectedQuantity ?? 0) - 1;
                                                                                      }
                                                                                    }),
                                                                                  }
                                                                                else
                                                                                  {},
                                                                                setState(() {
                                                                                  sparePartList[sparePartList.indexOf(element)] = element;
                                                                                })
                                                                              }
                                                                          }),
                                                              RichText(
                                                                text: TextSpan(
                                                                  // Note: Styles for TextSpans must be explicitly defined.
                                                                  // Child text spans will inherit styles from parent
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        12.0,
                                                                    color: Colors
                                                                        .black,
                                                                  ),
                                                                  children: <
                                                                      TextSpan>[
                                                                    TextSpan(
                                                                        text: element
                                                                            .selectedQuantity
                                                                            .toString(),
                                                                        style: const TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.bold)),
                                                                  ],
                                                                ),
                                                              ),
                                                              IconButton(
                                                                  icon:
                                                                      new Icon(
                                                                    color: Colors
                                                                        .black,
                                                                    Icons.add,
                                                                    size: 11.0,
                                                                  ),
                                                                  onPressed:
                                                                      () => {
                                                                            if (addedSparePartQuantities.contains(element))
                                                                              {
                                                                                addedSparePartQuantities.forEach((d) {
                                                                                  if (d.id == element.id) {
                                                                                    element.selectedQuantity = (element.selectedQuantity ?? 0) + 1;
                                                                                  }
                                                                                }),
                                                                              }
                                                                            else
                                                                              {
                                                                                element.selectedQuantity = (element.selectedQuantity ?? 0) + 1,
                                                                                addedSparePartQuantities.add(element)
                                                                              },
                                                                            setState(() {
                                                                              sparePartList[sparePartList.indexOf(element)] = element;
                                                                            }),
                                                                          }),
                                                            ],
                                                          )
                                                        : Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .center,
                                                            children: [
                                                                RichText(
                                                                  text:
                                                                      TextSpan(
                                                                    // Note: Styles for TextSpans must be explicitly defined.
                                                                    // Child text spans will inherit styles from parent
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          15.0,
                                                                      color: Colors
                                                                          .black,
                                                                    ),
                                                                    children: <
                                                                        TextSpan>[
                                                                      TextSpan(
                                                                          text:
                                                                              'Out of Stock',
                                                                          style:
                                                                              const TextStyle()),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ])),
                                              )
                                            ],
                                          )),
                                    )
                                    .toList())
                        : DataTable(
                            dataRowHeight: 70.0,
                            headingRowHeight: 0.0,
                            columns: [
                              DataColumn(
                                  label: Container(
                                width: MediaQuery.of(context).size.width * .2,
                                child: Padding(
                                    padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
                                    child: new Container()),
                              )),
                              DataColumn(
                                  label: Container(
                                width: MediaQuery.of(context).size.width * .33,
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                  child: new Container(),
                                ),
                              )),
                              DataColumn(
                                  label: Container(
                                width: MediaQuery.of(context).size.width * .26,
                                child: new Container(),
                              )),
                            ],
                            rows:
                                generalCodeList // Loops through dataColumnText, each iteration assigning the value to element
                                    .map(
                                      ((element) => DataRow(
                                            cells: <DataCell>[
                                              DataCell(Text(element.itemCode
                                                  .toString())), //Extracting from Map element the value
                                              DataCell(Text(
                                                  element.description ?? "-")),
                                              DataCell(
                                                Container(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  //color: Colors.white,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      IconButton(
                                                          icon: new Icon(
                                                            color: Colors.black,
                                                            element.stock == 0
                                                                ? Icons.add
                                                                : Icons.remove,
                                                            size: 14.0,
                                                          ),
                                                          onPressed: () async {
                                                            if (element.stock ==
                                                                0) {
                                                              //add
                                                              if (!addedGeneralCodeQuantities
                                                                  .contains(
                                                                      element)) {
                                                                addedGeneralCodeQuantities
                                                                    .add(
                                                                        element);
                                                                setState(() {
                                                                  element.stock =
                                                                      (element.stock ??
                                                                              0) +
                                                                          1;
                                                                });
                                                              }
                                                            } else {
                                                              if (addedGeneralCodeQuantities
                                                                  .contains(
                                                                      element)) {
                                                                addedGeneralCodeQuantities
                                                                    .remove(
                                                                        element);
                                                                setState(() {
                                                                  element.stock =
                                                                      (element.stock ??
                                                                              0) -
                                                                          1;
                                                                });
                                                              }
                                                            }
                                                          }),
                                                    ],
                                                  ),
                                                ),
                                              )
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

  Future<bool> _AddSparePartsToJob() async {
    // sparePartList.forEach((element) {
    //   if (element.quantity > 0) {
    //     addedSparePartQuantities.add(element);
    //   }
    // });

    return await Repositories.addSparePartsToJob(
        (selectedJob!.serviceRequestid ?? "0"), addedSparePartQuantities);
  }

  Future<bool> _AddGeneralCodeToJob() async {
    // generalCodeList.forEach((element) {
    //   if (element.stock == 1) {
    //     addedGeneralCodeQuantities.add(element);
    //   }
    // });

    return await Repositories.addGeneralCodeToJob(
        (selectedJob!.serviceRequestid ?? "0"), addedGeneralCodeQuantities);
  }

  _fetchSpareParts(bool eraseEarlyRecords, bool searchByCode) async {
    List<SparePart> currentHistory = [];

    if (!eraseEarlyRecords) {
      currentHistory.addAll(sparePartList);
    }
    var url = 'general/spareparts?per_page=20' +
        '&page=$sparePartsCurrentPage' +
        (warehouseSearchCT.text != ""
            ? '&q=' + warehouseSearchCT.text.toString()
            : "") +
        (searchByCode ? '&search_only_by_code=1' : '&search_only_by_code=0') +
        (!searchByCode ? '&product_id=${selectedJob?.productId}' : '') +
        (searchByCode
            ? '&q=${codeSearchCT.text.toString()}'
            : (warehouseSearchCT.text != ""
                ? '&q=' + warehouseSearchCT.text.toString()
                : ""));

    Helpers.showAlert(context);

    final response = await Api.bearerGet('general/spareparts?per_page=20' +
        '&page=$sparePartsCurrentPage' +
        (warehouseSearchCT.text != ""
            ? '&q=' + warehouseSearchCT.text.toString()
            : "") +
        (searchByCode ? '&search_only_by_code=1' : '&search_only_by_code=0') +
        (!searchByCode ? '&product_id=${selectedJob?.productId}' : '') +
        (searchByCode
            ? '&q=${codeSearchCT.text.toString()}'
            : (warehouseSearchCT.text != ""
                ? '&q=' + warehouseSearchCT.text.toString()
                : "")));
    Navigator.pop(context);

    print("#Resp: ${jsonEncode(response)}");

    if (response["success"] != null) {
      List<SparePart> spareParts =
          (response['data']?['spareparts']?['data'] as List).length > 0
              ? (response['data']?['spareparts']?['data'] as List)
                  .map((i) => SparePart.fromJson(i))
                  .toList()
              : [];

      currentHistory.addAll(spareParts);
    }
    setState(() {
      sparePartsMaxPages =
          response['data']?['spareparts']?['meta']?['last_page'];
      sparePartList = currentHistory;
    });
  }

  _fetchGeneralCodes(bool eraseEarlyRecords) async {
    Helpers.showAlert(context);
    List<GeneralCode> currentHistory = [];

    if (!eraseEarlyRecords) {
      currentHistory.addAll(generalCodeList);
    }

    final response = await Api.bearerGet(
        'general-code?per_page=20&page=${generalCodeCurrentPage}' +
            (warehouseSearchCT.text != ""
                ? '&q=' + warehouseSearchCT.text.toString()
                : ""));
    Navigator.pop(context);
    print("#Resp: ${jsonEncode(response)}");
    if (response["success"] != null) {
      var generalCodes = (response['data']?['data'] as List)
          .map((i) => GeneralCode.fromJson(i))
          .toList();

      currentHistory.addAll(generalCodes);
    }

    setState(() {
      generalCodeMaxPages = response['data']?['meta']?['last_page'];
      generalCodeList = currentHistory;
    });
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
