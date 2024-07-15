import 'dart:async';
import 'dart:convert';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kcs_engineer/model/job/job.dart';
import 'package:kcs_engineer/model/spareparts/sparepart.dart';
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

  bool isSpareParts = true;
  bool isGeneralCode = false;

  List<SparePart> addedSparePartQuantities = [];

  Timer? searchOnStoppedTyping;
  String currentSearchText = "";
  ScrollController? controller;

  int generalCodeCurrentPage = 1;
  int sparePartsMaxPages = 10;
  int sparePartsCurrentPage = 1;
  int generalCodeMaxPages = 10;

  bool isSearchByCodeEnabled = false;

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

    Future.delayed(Duration.zero, () {});
    //_checkPermisions();
  }

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) async {
    await fetchJobDetails();
    _loadVersion();
    await _fetchSpareParts(true, isSearchByCodeEnabled, null);
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
        sparePartsCurrentPage = sparePartsCurrentPage + 1;
        var SpareParts =
            await _fetchSpareParts(false, isSearchByCodeEnabled, null);
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
            sparePartsCurrentPage = 1;
            await _fetchSpareParts(true, isSearchByCodeEnabled, null);
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
          Divider(color: Colors.grey),
          SizedBox(height: 10),
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
                          !isSearchByCodeEnabled
                              ? SizedBox(
                                  height: MediaQuery.of(context).size.width *
                                      0.05, // <-- match-parent
                                  child: ElevatedButton(
                                      child: Padding(
                                        padding: const EdgeInsets.all(0.0),
                                        child: Row(children: [
                                          Icon(
                                            Icons.search,
                                            color: Colors.black54,
                                          ),
                                          Text(
                                            'Search by code',
                                            style: TextStyle(
                                                fontSize: 15,
                                                color: Colors.black54),
                                          ),
                                        ]),
                                      ),
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
                                                      BorderRadius.circular(
                                                          4.0),
                                                  side: BorderSide(
                                                      color: Colors.black54)))),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return SearchByCodePopup(
                                                itemSearched:
                                                    (String searchText) async {
                                              setState(() {
                                                isSearchByCodeEnabled = true;
                                                warehouseSearchCT.text = "";
                                              });
                                              await _fetchSpareParts(
                                                  true,
                                                  isSearchByCodeEnabled,
                                                  searchText);
                                              Navigator.pop(context);
                                            });
                                          },
                                        );
                                      }),
                                )
                              : SizedBox(
                                  height: MediaQuery.of(context).size.width *
                                      0.05, // <-- match-parent
                                  child: ElevatedButton(
                                      child: Padding(
                                        padding: const EdgeInsets.all(0.0),
                                        child: Text(
                                          'Reset',
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.white),
                                        ),
                                      ),
                                      style: ButtonStyle(
                                          foregroundColor:
                                              MaterialStateProperty.all<Color>(
                                                  Colors.red),
                                          backgroundColor:
                                              MaterialStateProperty.all<Color>(
                                                  Colors.red),
                                          shape: MaterialStateProperty.all<
                                                  RoundedRectangleBorder>(
                                              RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          4.0),
                                                  side: BorderSide(
                                                      color: Colors.red)))),
                                      onPressed: () {
                                        setState(() {
                                          isSearchByCodeEnabled = false;
                                        });
                                        _fetchSpareParts(true, false, null);
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

                                  await _AddSparePartsToJob().then(
                                      (value) => Navigator.pop(context, true));

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
          Container(
            alignment: Alignment.centerLeft,
            child: DataTable(
                headingRowHeight: 70.0,
                dataRowHeight: 0.0,
                headingRowColor:
                    MaterialStateColor.resolveWith((states) => Colors.black87),
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
                    width: MediaQuery.of(context).size.width * .16,
                    child: Padding(
                        padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                        child: Text('Part Description',
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
          ),
          sparePartList.length > 0
              ? Container(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Scrollbar(
                      controller: controller,
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
                                    width:
                                        MediaQuery.of(context).size.width * .15,
                                    child: Padding(
                                        padding:
                                            EdgeInsets.fromLTRB(20, 0, 0, 0),
                                        child: new Container()),
                                  )),
                                  DataColumn(
                                      label: Container(
                                    width:
                                        MediaQuery.of(context).size.width * .16,
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                      child: new Container(),
                                    ),
                                  )),
                                  DataColumn(
                                      label: Container(
                                    width:
                                        MediaQuery.of(context).size.width * .15,
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                      child: new Container(),
                                    ),
                                  )),
                                  DataColumn(
                                      label: Container(
                                    width:
                                        MediaQuery.of(context).size.width * .18,
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
                                                      element.description ??
                                                          "")),
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
                                                          element.quantity !=
                                                                      0 &&
                                                                  ((element.quantity ??
                                                                          0) >
                                                                      0)
                                                              ? RichText(
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  text:
                                                                      TextSpan(
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
                                                                          style:
                                                                              const TextStyle(fontWeight: FontWeight.bold)),
                                                                    ],
                                                                  ),
                                                                )
                                                              : RichText(
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
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
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Container(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        //color: Colors.white,
                                                        child: element.quantity !=
                                                                    0 &&
                                                                ((element.quantity ??
                                                                        0) >
                                                                    0)
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
                                                                            ? Colors.black54
                                                                            : Colors.black,
                                                                        Icons
                                                                            .remove,
                                                                        size:
                                                                            11.0,
                                                                      ),
                                                                      onPressed:
                                                                          () =>
                                                                              {
                                                                                if (element.selectedQuantity != 0)
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
                                                                    text:
                                                                        TextSpan(
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
                                                                            text:
                                                                                element.selectedQuantity.toString(),
                                                                            style: const TextStyle(fontWeight: FontWeight.bold)),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  IconButton(
                                                                      icon:
                                                                          new Icon(
                                                                        color: Colors
                                                                            .black,
                                                                        Icons
                                                                            .add,
                                                                        size:
                                                                            11.0,
                                                                      ),
                                                                      onPressed:
                                                                          () =>
                                                                              {
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
                                                                          color:
                                                                              Colors.black,
                                                                        ),
                                                                        children: <
                                                                            TextSpan>[
                                                                          TextSpan(
                                                                              text: 'Out of Stock',
                                                                              style: const TextStyle()),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ])),
                                                  )
                                                ],
                                              )),
                                        )
                                        .toList())
                          ])))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.06,
                      ),
                      Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 10),
                        decoration: new BoxDecoration(
                            color: Colors.white.withOpacity(0.0)),
                        child: Image(
                            image: AssetImage('assets/images/notfound.png'),
                            height: MediaQuery.of(context).size.height * 0.3,
                            width: MediaQuery.of(context).size.width * 0.6),
                      ),
                      RichText(
                        text: TextSpan(
                          // Note: Styles for TextSpans must be explicitly defined.
                          // Child text spans will inherit styles from parent
                          style: const TextStyle(
                            fontSize: 32.0,
                            color: Colors.black,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                                text: 'Could not find any items!',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height * 0.04),
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            // Note: Styles for TextSpans must be explicitly defined.
                            // Child text spans will inherit styles from parent
                            style: const TextStyle(
                              fontSize: 16.0,
                              color: Colors.black54,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                  text:
                                      'It seems like there are no items to add for this given job. If you wish to get a specific item from the sparepart code, please enter the sparepart code in the searcg bar.',
                                  style: const TextStyle()),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ],
                )
        ]),
      ),
    );
  }

  Future<bool> _AddSparePartsToJob() async {
    setState(() {
      addedSparePartQuantities = [];
    });

    var ids = addedSparePartQuantities.map((e) => e.id).toList();

    sparePartList.forEach((element) {
      if ((element.selectedQuantity ?? 0) > 0 && !(ids.contains(element.id))) {
        addedSparePartQuantities.add(element);
      }
    });

    addedSparePartQuantities.forEach((element) {
      element.from = "warehouse";
      element.quantity = (element.selectedQuantity ?? 0);
      var existingQuantity = selectedJob?.picklistCollected
                  ?.indexWhere((e) => element.id == e.id) !=
              -1
          ? (selectedJob?.picklistCollected
                  ?.firstWhere((e) => element.id == e.id)
                  .quantity ??
              0)
          : 0;
      element.quantity = (element.quantity ?? 0) + existingQuantity;
    });

    // var asalall = selectedJob.currentJobSparepartsfromPickList;

    return await Repositories.addItemsToPickList(
        (selectedJob!.serviceRequestid ?? "0"), addedSparePartQuantities);
  }

  _fetchSpareParts(
      bool eraseEarlyRecords, bool searchByCode, String? code) async {
    List<SparePart> currentHistory = [];

    if (!eraseEarlyRecords) {
      currentHistory.addAll(sparePartList);
    }

    Helpers.showAlert(context);

    var url = 'general/spareparts?per_page=15' +
        '&page=$sparePartsCurrentPage' +
        (!searchByCode
            ? (warehouseSearchCT.text != ""
                ? '&q=' + warehouseSearchCT.text.toString()
                : "")
            : (code != "" ? '&q=' + code.toString() : "")) +
        (searchByCode ? '&search_only_by_code=1' : '&search_only_by_code=0') +
        (!searchByCode ? '&product_id=${selectedJob?.productId}' : '') +
        (!searchByCode ? '&service_request_id=${jobId}' : '');
    final response = await Api.bearerGet('general/spareparts?per_page=15' +
        '&page=$sparePartsCurrentPage' +
        (!searchByCode
            ? (warehouseSearchCT.text != ""
                ? '&q=' + warehouseSearchCT.text.toString()
                : "")
            : (code != "" ? '&q=' + code.toString() : "")) +
        (searchByCode ? '&search_only_by_code=1' : '&search_only_by_code=0') +
        (!searchByCode ? '&product_id=${selectedJob?.productId}' : '') +
        ('&service_request_id=${jobId}'));

    print("#Resp: ${jsonEncode(response)}");
    Navigator.pop(context);

    if (response["success"] != null) {
      List<SparePart> spareParts =
          (response['data']?['spareparts']?['data'] as List).length > 0
              ? (response['data']?['spareparts']?['data'] as List)
                  .map((i) => SparePart.fromJson(i))
                  .toList()
              : [];

      currentHistory.addAll(spareParts);

      // currentHistory
      //     .sort((a, b) => b.quantity?.compareTo(a.quantity ?? 0) ?? 0);
    }
    setState(() {
      sparePartsMaxPages =
          response['data']?['spareparts']?['meta']?['last_page'];
      sparePartList = currentHistory;
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
    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          appBar: Helpers.customAppBar(context, _scaffoldKey,
              title: "Warehouse",
              isBack: true,
              isAppBarTranparent: true,
              hasActions: false),
          body: CustomPaint(
              child: SingleChildScrollView(
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: new BoxDecoration(color: Colors.white),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            errorMsg != "" ? _renderError() : Container(),
                            _renderForm(),
                            SizedBox(height: 10),
                            //Expanded(child: _renderBottom()),
                            //version != "" ? _renderVersion() : Container()
                          ])))),
        ));
  }
}

class SearchByCodePopup extends StatefulWidget {
  Function? itemSearched;

  SearchByCodePopup({required this.itemSearched}) {}

  @override
  _SearchByCodePopupState createState() => _SearchByCodePopupState();
}

class _SearchByCodePopupState extends State<SearchByCodePopup> {
  TextEditingController itemNameController = TextEditingController();
  Function? itemSearched;
  int quantity = 1;

  void increment() {
    setState(() {
      quantity++;
    });
  }

  void decrement() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    itemSearched = widget.itemSearched;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Search Item by Item code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 25),
          RichText(
            text: const TextSpan(
                style: TextStyle(
                  fontSize: 15.0,
                  color: Colors.black,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: 'item code:',
                  ),
                ]),
          ),
          SizedBox(height: 10),
          Container(
            width: MediaQuery.of(context).size.width * 0.5,
            padding: EdgeInsets.only(bottom: 50),
            child: TextFormField(
                //focusNode: focusEmail,
                controller: itemNameController,
                keyboardType: TextInputType.text,
                onChanged: (str) {},
                onEditingComplete: () {},
                onFieldSubmitted: (val) {
                  FocusScope.of(context).requestFocus(new FocusNode());
                },
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s.-]')),
                ],
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7)),
                  contentPadding: EdgeInsets.fromLTRB(20, 5, 0, 0),
                )),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
            child: Padding(
                padding: EdgeInsets.all(0.0),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    'Search',
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  )
                ])),
            style: ButtonStyle(
                foregroundColor:
                    MaterialStateProperty.all<Color>(Color(0xFF242A38)),
                backgroundColor:
                    MaterialStateProperty.all<Color>(Color(0xFF242A38)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                        side: const BorderSide(color: Color(0xFF242A38))))),
            onPressed: () async {
              await itemSearched?.call(
                itemNameController.text.toString(),
              );
            }),
        ElevatedButton(
            child: Padding(
                padding: EdgeInsets.all(0.0),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    'Cancel',
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  )
                ])),
            style: ButtonStyle(
                foregroundColor:
                    MaterialStateProperty.all<Color>(Color(0xFF242A38)),
                backgroundColor:
                    MaterialStateProperty.all<Color>(Color(0xFF242A38)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                        side: const BorderSide(color: Color(0xFF242A38))))),
            onPressed: () {
              Navigator.pop(context);
            }),
      ],
    );
  }
}
