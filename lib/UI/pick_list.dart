import 'dart:async';
import 'dart:convert';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kcs_engineer/model/job/job.dart';
import 'package:kcs_engineer/model/spareparts/pick_list_Items.dart';
import 'package:kcs_engineer/model/spareparts/sparepart.dart';
import 'package:kcs_engineer/themes/text_styles.dart';
import 'package:kcs_engineer/util/api.dart';
import 'package:kcs_engineer/util/helpers.dart';
import 'package:kcs_engineer/util/repositories.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PickList extends StatefulWidget {
  String? jobId;
  PickList({this.jobId});

  @override
  _PickListState createState() => _PickListState();
}

class _PickListState extends State<PickList> with AfterLayoutMixin {
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController codeSearchCT = new TextEditingController();

  FocusNode focusWarehouseSearch = new FocusNode();
  bool isLoading = false;
  bool showPassword = false;
  String errorMsg = "";
  String version = "";
  final storage = new FlutterSecureStorage();

  Timer? searchOnStoppedTyping;
  String currentSearchText = "";

  PickListItems? picklistItems;
  List<PickListItemMetaData> notCollected = [];
  List<PickListItemMetaData> collected = [];

  @override
  void initState() {
    // emailCT.text = 'khindtest1@gmail.com';
    // passwordCT.text = 'Abcd@1234';
    // emailCT.text = 'khindcustomerservice@gmail.com';
    // passwordCT.text = 'Khindanshin118';

    super.initState();

    Future.delayed(Duration.zero, () {});
    //_checkPermisions();
  }

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) async {
    // await fetchJobDetails();
    _loadVersion();
    await _fetchTodaysPickList();
    // _fetchGeneralCodes(true);
  }

  // fetchJobDetails() async {
  //   var job = await Repositories.fetchJobDetails(jobId: jobId);
  //   setState(() {
  //     selectedJob = job;
  //   });
  // }

  @override
  void dispose() {
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
            // sparePartsCurrentPage = 1;
            await _fetchTodaysPickList();
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
                        text: 'Pick List',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            picklistItems != null
                ? Column(children: [
                    SizedBox(height: 10),
                    Divider(color: Colors.grey),
                    SizedBox(height: 20),
                    // Row(
                    //   crossAxisAlignment: CrossAxisAlignment.center,
                    //   children: [
                    //     Expanded(
                    //       child: Padding(
                    //         padding: const EdgeInsets.all(0.0),
                    //         child: Column(
                    //           mainAxisAlignment: MainAxisAlignment.spaceAround,
                    //           crossAxisAlignment: CrossAxisAlignment.start,
                    //           mainAxisSize: MainAxisSize.min,
                    //           children: [
                    //             TextFormField(
                    //                 focusNode: focusWarehouseSearch,
                    //                 keyboardType: TextInputType.text,
                    //                 validator: (value) {
                    //                   if (value!.isEmpty) {
                    //                     return 'Please enter email';
                    //                   }
                    //                   return null;
                    //                 },
                    //                 onChanged: _onChangeHandler,
                    //                 controller: codeSearchCT,
                    //                 onFieldSubmitted: (val) {
                    //                   FocusScope.of(context)
                    //                       .requestFocus(new FocusNode());
                    //                 },
                    //                 style: TextStyles.textDefaultBold,
                    //                 decoration: const InputDecoration(
                    //                   contentPadding: EdgeInsets.symmetric(
                    //                       vertical: 10.0, horizontal: 10),
                    //                   border: OutlineInputBorder(),
                    //                   hintText: 'Search',
                    //                 )),
                    //             SizedBox(height: 10),
                    //           ],
                    //         ),
                    //       ),
                    //     ),
                    //     Flexible(
                    //       fit: FlexFit.tight,
                    //       child: Padding(
                    //         padding: const EdgeInsets.all(0.0),
                    //         child: Column(
                    //           mainAxisAlignment: MainAxisAlignment.spaceAround,
                    //           crossAxisAlignment: CrossAxisAlignment.end,
                    //           mainAxisSize: MainAxisSize.min,
                    //           children: [],
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    notCollected.length > 0
                        ? SizedBox(height: 20)
                        : new Container(),
                    notCollected.length > 0
                        ? Container(
                            alignment: Alignment.centerLeft,
                            child: RichText(
                              text: TextSpan(
                                // Note: Styles for TextSpans must be explicitly defined.
                                // Child text spans will inherit styles from parent
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  color: Colors.black87,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: 'Pending Collection',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          )
                        : new Container(),
                    notCollected.length > 0
                        ? SizedBox(
                            height: 30,
                          )
                        : new Container(),
                    notCollected.length > 0
                        ? Container(
                            width: MediaQuery.of(context).size.width * .9,
                            alignment: Alignment.centerLeft,
                            child: DataTable(
                                headingRowHeight: 70.0,
                                dataRowHeight: 70.0,
                                headingRowColor: MaterialStateColor.resolveWith(
                                    (states) => Colors.black87),
                                columns: [
                                  DataColumn(
                                      label: Container(
                                    width:
                                        MediaQuery.of(context).size.width * .2,
                                    child: Padding(
                                        padding:
                                            EdgeInsets.fromLTRB(30, 0, 0, 0),
                                        child: Text('Code',
                                            style: TextStyle(
                                                color: Colors.white))),
                                  )),
                                  DataColumn(
                                      label: Container(
                                    width:
                                        MediaQuery.of(context).size.width * .3,
                                    child: Padding(
                                        padding:
                                            EdgeInsets.fromLTRB(20, 0, 0, 0),
                                        child: Text('Part Name',
                                            style: TextStyle(
                                                color: Colors.white))),
                                  )),
                                  DataColumn(
                                      label: Container(
                                    width:
                                        MediaQuery.of(context).size.width * .1,
                                    child: Padding(
                                        padding:
                                            EdgeInsets.fromLTRB(20, 0, 0, 0),
                                        child: Text('Quantity',
                                            style: TextStyle(
                                                color: Colors.white))),
                                  )),
                                ],
                                rows:
                                    notCollected // Loops through dataColumnText, each iteration assigning the value to element
                                        .map(
                                          ((element) => DataRow(
                                                cells: <DataCell>[
                                                  DataCell(Text(
                                                    element.sparePartCode ?? "",
                                                    style: TextStyle(
                                                        fontSize: 15.0),
                                                  )), //Extracting from Map element the value
                                                  DataCell(Text(
                                                    element.sparePartsDescription ??
                                                        "",
                                                    style: TextStyle(
                                                        fontSize: 15.0),
                                                  )),
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
                                                          RichText(
                                                            textAlign: TextAlign
                                                                .center,
                                                            text: TextSpan(
                                                              // Note: Styles for TextSpans must be explicitly defined.
                                                              // Child text spans will inherit styles from parent
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 15.0,
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                              children: <
                                                                  TextSpan>[
                                                                TextSpan(
                                                                    text: element
                                                                        .quantityTaken
                                                                        .toString(),
                                                                    style: const TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold)),
                                                              ],
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )),
                                        )
                                        .toList()),
                          )
                        : new Container(),
                    collected.length > 0 && notCollected.length > 0
                        ? SizedBox(
                            height: MediaQuery.of(context).size.height * .1,
                          )
                        : new Container(),
                    collected.length > 0
                        ? Container(
                            alignment: Alignment.centerLeft,
                            child: RichText(
                              text: TextSpan(
                                // Note: Styles for TextSpans must be explicitly defined.
                                // Child text spans will inherit styles from parent
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  color: Colors.black87,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: 'Collected',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          )
                        : new Container(),
                    collected.length > 0
                        ? SizedBox(height: 30)
                        : new Container(),
                    collected.length > 0
                        ? Container(
                            width: MediaQuery.of(context).size.width * .9,
                            alignment: Alignment.centerLeft,
                            child: DataTable(
                                headingRowHeight: 70.0,
                                dataRowHeight: 70.0,
                                headingRowColor: MaterialStateColor.resolveWith(
                                    (states) => Colors.black87),
                                columns: [
                                  DataColumn(
                                      label: Container(
                                    width:
                                        MediaQuery.of(context).size.width * .2,
                                    child: Padding(
                                        padding:
                                            EdgeInsets.fromLTRB(30, 0, 0, 0),
                                        child: Text('Code',
                                            style: TextStyle(
                                                color: Colors.white))),
                                  )),
                                  DataColumn(
                                      label: Container(
                                    width:
                                        MediaQuery.of(context).size.width * .3,
                                    child: Padding(
                                        padding:
                                            EdgeInsets.fromLTRB(20, 0, 0, 0),
                                        child: Text('Part Name',
                                            style: TextStyle(
                                                color: Colors.white))),
                                  )),
                                  DataColumn(
                                      label: Container(
                                    width:
                                        MediaQuery.of(context).size.width * .1,
                                    child: Padding(
                                        padding:
                                            EdgeInsets.fromLTRB(20, 0, 0, 0),
                                        child: Text('Quantity',
                                            style: TextStyle(
                                                color: Colors.white))),
                                  )),
                                ],
                                rows:
                                    collected // Loops through dataColumnText, each iteration assigning the value to element
                                        .map(
                                          ((element) => DataRow(
                                                cells: <DataCell>[
                                                  DataCell(Text(
                                                    element.sparePartCode ?? "",
                                                    style: TextStyle(
                                                        fontSize: 15.0),
                                                  )), //Extracting from Map element the value
                                                  DataCell(Text(
                                                    element.sparePartsDescription ??
                                                        "",
                                                    style: TextStyle(
                                                        fontSize: 15.0),
                                                  )),
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
                                                          RichText(
                                                            textAlign: TextAlign
                                                                .center,
                                                            text: TextSpan(
                                                              // Note: Styles for TextSpans must be explicitly defined.
                                                              // Child text spans will inherit styles from parent
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 15.0,
                                                                color: Colors
                                                                    .black,
                                                              ),
                                                              children: <
                                                                  TextSpan>[
                                                                TextSpan(
                                                                    text: element
                                                                        .quantityTaken
                                                                        .toString(),
                                                                    style: const TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold)),
                                                              ],
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )),
                                        )
                                        .toList()),
                          )
                        : new Container(),
                    // ConstrainedBox(
                    //     constraints: BoxConstraints(maxHeight: 900, minHeight: 200),
                    //     child: Container(
                    //         child: Scrollbar(
                    //             child: ListView(shrinkWrap: true, children: [
                    //       collected.length > 0
                    //           ? DataTable(
                    //               dataRowHeight: 70.0,
                    //               headingRowHeight: 0.0,
                    //               columns: [
                    //                   DataColumn(
                    //                       label: Container(
                    //                     child: Padding(
                    //                         padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
                    //                         child: new Container()),
                    //                   )),
                    //                   DataColumn(
                    //                       label: Container(
                    //                     child: Padding(
                    //                       padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                    //                       child: new Container(),
                    //                     ),
                    //                   )),
                    //                   DataColumn(
                    //                       label: Container(
                    //                     child: Padding(
                    //                       padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                    //                       child: new Container(),
                    //                     ),
                    //                   )),
                    //                 ],
                    //               rows: [])
                    //           : new Container()
                    //     ]))))
                  ])
                : Column(children: [
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
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
          ])),
    );
  }

  _fetchTodaysPickList() async {
    Helpers.showAlert(context);
    var response = await Repositories.fetchDailyPickList();
    Navigator.pop(context);

    setState(() {
      picklistItems = response;
      collected = picklistItems?.collected ?? [];
      notCollected = picklistItems?.notCollected ?? [];
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
