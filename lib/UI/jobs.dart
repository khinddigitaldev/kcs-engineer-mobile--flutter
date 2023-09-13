import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:after_layout/after_layout.dart';
import 'package:bottom_sheet_bar/bottom_sheet_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kcs_engineer/model/job.dart';
import 'package:kcs_engineer/model/job_filter_options.dart';
import 'package:kcs_engineer/model/job_order_seq.dart';
import 'package:kcs_engineer/model/user.dart';
import 'package:kcs_engineer/themes/text_styles.dart';
import 'package:kcs_engineer/util/api.dart';
import 'package:kcs_engineer/util/components/calendarView.dart';
import 'package:kcs_engineer/util/helpers.dart';
import 'package:kcs_engineer/util/repositories.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:readmore/readmore.dart';
import 'package:url_launcher/url_launcher.dart';

class JobList extends StatefulWidget with WidgetsBindingObserver {
  int? data;
  JobList({this.data});

  @override
  _JobListState createState() => _JobListState();
}

class _JobListState extends State<JobList>
    with WidgetsBindingObserver, AfterLayoutMixin {
  var _refreshKey = GlobalKey<RefreshIndicatorState>();
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController inProgressSearchCT = new TextEditingController();
  TextEditingController completedSearchCT = new TextEditingController();
  FocusNode focusinProgressSearch = new FocusNode();
  FocusNode focusCompletedSearch = new FocusNode();
  bool isLoading = false;
  bool showPassword = false;
  String errorMsg = "";
  String version = "";
  bool status = false;
  //List<Job> inProgressJobs = [];
  // List<Job> completedJobs = [];
  Timer? searchOnInProgressStoppedTyping;
  String currentSearchTextInProgress = "";
  Timer? searchCompletedOnStoppedTyping;
  String currentSearchTextCompleted = "";
  List<Job> inProgressJobs = [];
  List<Job> completedJobs = [];
  final _listSizeController = TextEditingController(text: '5');
  int _listSize = 5;
  final _bsbController = BottomSheetBarController();
  bool _isLocked = false;
  bool isExpandedFilters = false;
  bool isFilterPressed = false;
  JobFilterOptions? fetchedJobFilterOptions;
  int consecutiveDays = -1;

  var serviceTypes = [];
  var paymentStatuses = ["Paid", "Unpaid"];
  var serviceStatuses = [];

  var selectedServiceTypes = [];
  var selectedPaymentStatuses = [];
  var selectedServiceStatuses = [];

  var prevSelectedServiceTypes = [];
  var prevSelectedPaymentStatuses = [];
  var prevSelectedServiceStatuses = [];

  JobData? jobData;

  int? currentSelectedIndex = 0;

  User? user;

  final storage = new FlutterSecureStorage();
  String? token;

  @override
  void initState() {
    super.initState();
  }

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) async {
    await _loadVersion();
    await _fetchJobs();
    await _fetchJobStatuses();
    _bsbController.addListener(() {
      if (isFilterPressed) {
        setState(() {
          selectedServiceTypes = [];
          selectedPaymentStatuses = [];
          selectedServiceStatuses = [];
          selectedServiceTypes.addAll(prevSelectedServiceTypes);
          selectedPaymentStatuses.addAll(prevSelectedPaymentStatuses);
          selectedServiceStatuses.addAll(prevSelectedServiceStatuses);
        });

        setState(() {
          isFilterPressed = false;
        });
      }
    });
  }

  @override
  void dispose() {
    inProgressSearchCT.dispose();
    completedSearchCT.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {}
  }

  _loadVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String pkgVersion = packageInfo.version;

    setState(() {
      version = pkgVersion;
    });
  }

  _fetchJobs() async {
    if (Helpers.loggedInUser != null) {
      user = Helpers.loggedInUser;
    }
    var fetchedJobData = null;

    var filters = {
      // "consecutive_days": consecutiveDays,
      "filter": {
        ...(selectedServiceTypes.length > 0
            ? {
                "service_type": (fetchedJobFilterOptions?.serviceTypes
                        ?.where((element) =>
                            selectedServiceTypes.contains(element.serviceType))
                        .toList())
                    ?.map((e) => e.id)
                    .toList()
              }
            : {}),
        ...((selectedPaymentStatuses.length == 0 ||
                selectedPaymentStatuses.length == 2)
            ? {}
            : {"payment_status": selectedPaymentStatuses[0] == "Paid"}),
        ...(selectedServiceStatuses.length > 0
            ? {
                "service_request_status": (fetchedJobFilterOptions
                    ?.serviceJobStatuses
                    ?.where((element) => selectedServiceStatuses
                        .contains(element.serviceJobStatus))
                    .toList()
                    .map((e) => e?.id)
                    .toList())
              }
            : {})
      }
    };

    var filterMap = filters["filter"] as Map<dynamic, dynamic>;
    if (filterMap.entries.isEmpty) {
      filters.remove("filter");
    }

    Helpers.showAlert(context);
    fetchedJobData = await Repositories.fetchJobs(filters);
    Navigator.pop(context);

    setState(() {
      jobData = fetchedJobData;
      inProgressJobs = (jobData as JobData).jobs ?? [];
      completedJobs = (jobData as JobData).jobs ?? [];
      Helpers.completedJobs = inProgressJobs;
      Helpers.inProgressJobs = completedJobs;
      Helpers.loggedInUser = user;
    });
  }

  _fetchJobStatuses() async {
    Helpers.showAlert(context);
    if (Helpers.loggedInUser != null) {
      user = Helpers.loggedInUser;
    }
    var fetched = null;

    fetched = await Repositories.fetchJobStatus();

    if (fetched != null) {
      setState(() {
        fetchedJobFilterOptions = fetched;
        serviceTypes = (fetched as JobFilterOptions)
                .serviceTypes
                ?.map((e) => e.serviceType)
                .toList() ??
            [];
        serviceStatuses = (fetched as JobFilterOptions)
                .serviceJobStatuses
                ?.map((e) => e.serviceJobStatus)
                .toList() ??
            [];
      });
    }

    Navigator.pop(context);
  }

  searchBox(String query, bool isInprogress) async {
    if (isInprogress) {
      Helpers.inProgressJobs = inProgressJobs;
    } else {
      Helpers.completedJobs = completedJobs;
    }
    setState(() {
      if (isInprogress) {
        Helpers.inProgressJobs = Helpers.inProgressJobs.where((element) {
          final customerName = element.customerName != null
              ? element.customerName!.toLowerCase()
              : "";
          final productCode = element.productCode != null
              ? element.productCode!.toLowerCase()
              : "";
          final productDesc = element.productDescription != null
              ? element.productDescription!.toLowerCase()
              : "";
          final input = query.toLowerCase();

          return (customerName.toLowerCase().contains(input) ||
              productCode.toLowerCase().contains(input) ||
              productDesc.toLowerCase().contains(input));
        }).toList();
      } else {
        Helpers.completedJobs = Helpers.completedJobs.where((element) {
          final customerName = element.customerName != null
              ? element.customerName!.toLowerCase()
              : "";
          final productCode = element.productCode != null
              ? element.productCode!.toLowerCase()
              : "";
          final productDesc = element.productDescription != null
              ? element.productDescription!.toLowerCase()
              : "";

          final input = query.toLowerCase();

          return (customerName.toLowerCase().contains(input) ||
              productCode.toLowerCase().contains(input) ||
              productDesc.toLowerCase().contains(input));
        }).toList();
      }
    });
  }

  Widget _buildTester() {
    final fullWidth = MediaQuery.of(context).size.width;
    final rowWidth = fullWidth * 0.5; //90%
    final containerWidth =
        rowWidth / 3; //Could also use this to set the containers individually

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Container(
            width: MediaQuery.of(context).size.width * 0.2,
            height: MediaQuery.of(context).size.height * 0.15,
            decoration:
                BoxDecoration(border: Border.all(color: Color(0xFFD4D4D4))),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  // <-- Icon
                  Icons.highlight_remove,
                  color: Colors.red,
                  size: 40.0,
                ),
                SizedBox(
                  height: 20,
                ),
                RichText(
                  text: TextSpan(
                    // Note: Styles for TextSpans must be explicitly defined.
                    // Child text spans will inherit styles from parent
                    style: const TextStyle(
                      fontSize: 38.0,
                      color: Colors.black,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                          text: '${jobData?.meta?.uncompleted ?? 0}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                RichText(
                  text: TextSpan(
                    // Note: Styles for TextSpans must be explicitly defined.
                    // Child text spans will inherit styles from parent
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Colors.black54,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                          text: 'Uncompleted Jobs',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            )),
        Container(
          width: MediaQuery.of(context).size.width * 0.2,
          height: MediaQuery.of(context).size.height * 0.15,
          decoration:
              BoxDecoration(border: Border.all(color: Color(0xFFD4D4D4))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                // <-- Icon
                Icons.work,
                color: Colors.lightBlue,
                size: 40.0,
              ),
              SizedBox(
                height: 20,
              ),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 38.0,
                    color: Colors.black,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                        text:
                            '${(jobData?.meta?.completed ?? 0) + (jobData?.meta?.uncompleted ?? 0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              SizedBox(
                height: 20,
              ),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: Colors.black54,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                        text: 'Total Jobs',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width * 0.2,
          height: MediaQuery.of(context).size.height * 0.15,
          decoration:
              BoxDecoration(border: Border.all(color: Color(0xFFD4D4D4))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                // <-- Icon
                Icons.done_all_outlined,
                color: Colors.green,
                size: 40.0,
              ),
              SizedBox(
                height: 20,
              ),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 38.0,
                    color: Colors.black,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                        text: '${jobData?.meta?.completed ?? 0}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              SizedBox(
                height: 20,
              ),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: Colors.black54,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                        text: 'Completed Jobs',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 40,
        )
      ],
    );
  }

  _onChangeHandlerForInprogress(value) {
    const duration = Duration(
        milliseconds:
            50); // set the duration that you want call search() after that.

    if (searchOnInProgressStoppedTyping != null) {
      setState(() => searchOnInProgressStoppedTyping!.cancel()); // clear timer
    }
    setState(
        () => searchOnInProgressStoppedTyping = new Timer(duration, () async {
              if (currentSearchTextInProgress != value) {
                currentSearchTextInProgress = value;
                await searchBox(currentSearchTextInProgress, true);
              }
            }));
  }

  _onChangeHandlerForCompletion(value) {
    const duration = Duration(
        milliseconds:
            50); // set the duration that you want call search() after that.

    if (searchCompletedOnStoppedTyping != null) {
      setState(() => searchCompletedOnStoppedTyping!.cancel()); // clear timer
    }
    setState(
        () => searchCompletedOnStoppedTyping = new Timer(duration, () async {
              if (currentSearchTextCompleted != value) {
                currentSearchTextCompleted = value;
                await searchBox(currentSearchTextCompleted, false);
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
          Padding(
            padding: EdgeInsets.fromLTRB(10.0, 0, 0, 0),
            child: Container(
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 32.0,
                    color: Colors.black,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                        text: 'Jobs',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.fromLTRB(10.0, 0, 0, 0),
            child: Container(
              alignment: Alignment.centerLeft,
              child: Divider(color: Colors.grey),
            ),
          ),
          SizedBox(height: 20),
          Container(
            height: MediaQuery.of(context).size.height * .08,
            width: MediaQuery.of(context).size.width * 1,
            child: CalendarView(
              selectedIndex: currentSelectedIndex,
              dateSelected: (index) async {
                if (index == 0) {
                  setState(() {
                    consecutiveDays = -1;
                  });
                } else {
                  setState(() {
                    consecutiveDays = index + 1;
                  });
                }
                setState(() {
                  currentSelectedIndex = index;
                });

                await _fetchJobs();
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(10.0, 0, 0, 0),
            child: Container(
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
                      TextSpan(
                        text: 'JOBS TODAY',
                      ),
                    ]),
              ),
            ),
          ),
          SizedBox(
            height: 20,
          ),
          _buildTester(),
          (inProgressJobs != null && inProgressJobs.length > 0)
              ? SizedBox(
                  height: 40,
                )
              : new Container(),
          (inProgressJobs != null && inProgressJobs.length > 0)
              ? Padding(
                  padding: EdgeInsets.fromLTRB(10.0, 0, 0, 0),
                  child: Container(
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
                            TextSpan(
                              text: 'LIST OF JOBS',
                            ),
                          ]),
                    ),
                  ),
                )
              : new Container(),
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              (inProgressJobs != null && inProgressJobs.length > 0)
                  ? Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 0.0, 0),
                      child: Container(
                        width: 250,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 40,
                              child: TextFormField(
                                  focusNode: focusinProgressSearch,
                                  keyboardType: TextInputType.text,
                                  controller: inProgressSearchCT,
                                  onChanged: _onChangeHandlerForInprogress,
                                  onFieldSubmitted: (val) {
                                    FocusScope.of(context)
                                        .requestFocus(new FocusNode());
                                  },
                                  style: TextStyles.textDefaultBold,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Search',
                                    contentPadding:
                                        EdgeInsets.fromLTRB(0, 5, 0, 0),
                                    prefixIcon: Icon(Icons.search),
                                  )),
                            ),
                          ],
                        ),
                      ))
                  : new Container(),
              SizedBox(
                width:
                    MediaQuery.of(context).size.width * 0.1, // <-- match_parent
                height: MediaQuery.of(context).size.width *
                    0.05, // <-- match-parent
                child: ElevatedButton(
                    child: Padding(
                        padding: const EdgeInsets.all(0.0),
                        child: Text(
                          'Filter',
                          style: TextStyle(fontSize: 15, color: Colors.black54),
                        )),
                    style: ButtonStyle(
                        foregroundColor:
                            MaterialStateProperty.all<Color>(Colors.white),
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.white),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4.0),
                                    side: BorderSide(color: Colors.black54)))),
                    onPressed: () {
                      setState(() {
                        isFilterPressed = true;
                      });
                      _bsbController.expand();
                    }),
              ),
            ],
          ),
          (inProgressJobs != null && inProgressJobs.length > 0)
              ? SizedBox(
                  height: 20,
                )
              : new Container(),
          (inProgressJobs != null && inProgressJobs.length > 0)
              ? ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * .58,
                      minHeight: MediaQuery.of(context).size.height * .1),
                  child: ReorderableListView.builder(
                    onReorder: ((oldIndex, newIndex) async {
                      // final index =
                      //     newIndex > oldIndex ? newIndex - 1 : newIndex;
                      // final job = Helpers.inProgressJobs.removeAt(oldIndex);
                      // Helpers.inProgressJobs.insert(index, job);
                      //  Helpers.showAlert(context);
                      // await updateJobSequence();
                      //  Navigator.pop(context);
                    }),

                    shrinkWrap: true,
                    // shrinkWrap: false,
                    itemCount: inProgressJobs.length,
                    itemBuilder: (BuildContext context, int index) {
                      return GestureDetector(
                        child: JobItem(
                            key: ValueKey(index),
                            width: MediaQuery.of(context).size.width,
                            job: Helpers.inProgressJobs[index],
                            index: index),
                        onTap: () async {
                          Helpers.selectedJobIndex = index;
                          Helpers.showAlert(context);

                          Job? job;
                          Navigator.pop(context);
                          // if (job != null) {
                          Helpers.selectedJob = job;
                          Helpers.showAlert(context);
                          Navigator.pushNamed(context, 'jobDetails',
                                  arguments: inProgressJobs[index].id)
                              .then((value) async {
                            await _fetchJobs();
                          });
                          // }
                        },
                        key: ValueKey(index),
                      );
                    },
                  ),
                )
              : new Container(),
          SizedBox(
            height: 30,
          ),
        ]),
      ),
    );
  }

  // updateJobSequence() async {
  //   List<JobOrderSequence> sequences = [];
  //   JobOrderSequence seq;
  //   for (var i = 0; i < Helpers.inProgressJobs.length; i++) {
  //     seq = new JobOrderSequence();
  //     seq.jobOrderId = Helpers.inProgressJobs[i].id;
  //     seq.sequence = i + 1;
  //     sequences.add(seq);
  //   }

  //   bool response = await Repositories.updateJobOrderSequence(sequences);

  //   setState(() {
  //     //Sequence erorr failed or not
  //   });
  // }

  _renderError() {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      // SizedBox(height: 10),
      SizedBox(height: 20),
    ]);
  }

  Future<bool> _onWillPop() async {
    // Navigator.pop(context);
    return true;
  }

  resetArrays() async {
    setState(() {
      selectedPaymentStatuses = [];
      selectedServiceStatuses = [];
      selectedServiceTypes = [];
      prevSelectedPaymentStatuses = [];
      prevSelectedServiceStatuses = [];
      prevSelectedServiceTypes = [];
    });

    await _fetchJobs();
  }

  submitFilters() async {
    setState(() {
      prevSelectedPaymentStatuses = [];
      prevSelectedServiceStatuses = [];
      prevSelectedServiceTypes = [];

      prevSelectedPaymentStatuses.addAll(selectedPaymentStatuses);
      prevSelectedServiceStatuses.addAll(selectedServiceStatuses);
      prevSelectedServiceTypes.addAll(selectedServiceTypes);
    });
    await _fetchJobs();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        key: _refreshKey,
        onRefresh: () async {
          await this._fetchJobs();
        },
        child: Scaffold(
          key: _scaffoldKey,
          //resizeToAvoidBottomInset: false,
          body: BottomSheetBar(
            height: 0,
            color: Colors.white,
            isDismissable: true,
            backdropColor: Colors.black.withOpacity(0.6),
            locked: _isLocked,
            controller: _bsbController,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(0.0),
              topRight: Radius.circular(0.0),
            ),
            borderRadiusExpanded: const BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
            // boxShadows: [
            //   BoxShadow(
            //     color: Colors.grey.withOpacity(0.5),
            //     spreadRadius: 5.0,
            //     blurRadius: 32.0,
            //     offset: const Offset(0, 0), // changes position of shadow
            //   ),
            // ],
            expandedBuilder: (scrollController) {
              final itemList =
                  List<int>.generate(_listSize, (index) => index + 1);

              // Wrapping the returned widget with [Material] for tap effects
              return Material(
                  color: Colors.transparent,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.55,
                    width: MediaQuery.of(context).size.width * 1,
                    padding: EdgeInsets.only(left: 80, right: 20, top: 10),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 20.0,
                                  color: Colors.black,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: 'Filter',
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                                onTap: () async {
                                  await resetArrays();
                                  _bsbController.collapse();
                                },
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 20.0,
                                      color: Colors.blue,
                                    ),
                                    children: <TextSpan>[
                                      TextSpan(
                                          text: 'Reset',
                                          style: const TextStyle()),
                                    ],
                                  ),
                                ))
                          ],
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * .08,
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 20.0,
                                color: Colors.black,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: 'Service Type',
                                    style: const TextStyle()),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        LayoutBuilder(builder:
                            (BuildContext context, BoxConstraints constraints) {
                          return AnimatedAlign(
                              alignment: Alignment.centerLeft,
                              duration: Duration(milliseconds: 300),
                              child: Container(
                                  width: constraints.maxWidth,
                                  child: Wrap(
                                      direction: Axis.horizontal,
                                      alignment: WrapAlignment.start,
                                      spacing: 10,
                                      runSpacing: 10,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.start,
                                      children: serviceTypes
                                          .map(
                                            (e) => GestureDetector(
                                                onTap: () {
                                                  if (selectedServiceTypes
                                                      .contains(e)) {
                                                    setState(() {
                                                      selectedServiceTypes
                                                          .remove(e);
                                                    });
                                                  } else {
                                                    setState(() {
                                                      selectedServiceTypes
                                                          .add(e);
                                                    });
                                                  }
                                                },
                                                child: Container(
                                                    decoration: BoxDecoration(
                                                        color:
                                                            selectedServiceTypes
                                                                    .contains(e)
                                                                ? Color(
                                                                    0xFF323F4B)
                                                                : Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                        border: Border.all(
                                                          color:
                                                              Color(0xFF323F4B),
                                                        )),
                                                    child: Padding(
                                                        padding:
                                                            EdgeInsets.fromLTRB(
                                                                30, 10, 30, 10),
                                                        child: RichText(
                                                            text: TextSpan(
                                                                style:
                                                                    TextStyle(
                                                                  color: selectedServiceTypes
                                                                          .contains(
                                                                              e)
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .black,
                                                                  fontSize: 12,
                                                                ),
                                                                children: [
                                                              TextSpan(
                                                                  text: '${e}'),
                                                              WidgetSpan(
                                                                child: SizedBox(
                                                                  width: selectedServiceTypes
                                                                          .contains(
                                                                              e)
                                                                      ? 10
                                                                      : 0,
                                                                ),
                                                              ),
                                                              WidgetSpan(
                                                                  child: Icon(
                                                                Icons.check,
                                                                size: selectedServiceTypes
                                                                        .contains(
                                                                            e)
                                                                    ? 15
                                                                    : 0,
                                                                color: Colors
                                                                    .white,
                                                              ))
                                                            ]))))),
                                          )
                                          .toList())));
                        }),
                        SizedBox(
                          height: 20,
                        ),
                        Divider(),
                        SizedBox(
                          height: 20,
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 20.0,
                                color: Colors.black,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: 'Payment Status',
                                    style: const TextStyle()),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        LayoutBuilder(builder:
                            (BuildContext context, BoxConstraints constraints) {
                          return AnimatedAlign(
                              alignment: Alignment.centerLeft,
                              duration: Duration(milliseconds: 300),
                              child: Container(
                                  width: constraints.maxWidth,
                                  child: Wrap(
                                      direction: Axis.horizontal,
                                      alignment: WrapAlignment.start,
                                      spacing: 10,
                                      runSpacing: 10,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.start,
                                      children: paymentStatuses
                                          .map(
                                            (e) => GestureDetector(
                                                onTap: () {
                                                  if (selectedPaymentStatuses
                                                      .contains(e)) {
                                                    setState(() {
                                                      selectedPaymentStatuses
                                                          .remove(e);
                                                    });
                                                  } else {
                                                    setState(() {
                                                      selectedPaymentStatuses
                                                          .add(e);
                                                    });
                                                  }
                                                },
                                                child: Container(
                                                    decoration: BoxDecoration(
                                                        color:
                                                            selectedPaymentStatuses
                                                                    .contains(e)
                                                                ? Color(
                                                                    0xFF323F4B)
                                                                : Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                        border: Border.all(
                                                          color:
                                                              Color(0xFF323F4B),
                                                        )),
                                                    child: Padding(
                                                        padding:
                                                            EdgeInsets.fromLTRB(
                                                                30, 10, 30, 10),
                                                        child: RichText(
                                                            text: TextSpan(
                                                                style:
                                                                    TextStyle(
                                                                  color: selectedPaymentStatuses
                                                                          .contains(
                                                                              e)
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .black,
                                                                  fontSize: 12,
                                                                ),
                                                                children: [
                                                              TextSpan(
                                                                  text: '${e}'),
                                                              WidgetSpan(
                                                                child: SizedBox(
                                                                  width: selectedPaymentStatuses
                                                                          .contains(
                                                                              e)
                                                                      ? 10
                                                                      : 0,
                                                                ),
                                                              ),
                                                              WidgetSpan(
                                                                  child: Icon(
                                                                Icons.check,
                                                                size: selectedPaymentStatuses
                                                                        .contains(
                                                                            e)
                                                                    ? 15
                                                                    : 0,
                                                                color: Colors
                                                                    .white,
                                                              ))
                                                            ]))))),
                                          )
                                          .toList())));
                        }),
                        SizedBox(
                          height: 20,
                        ),
                        Divider(),
                        SizedBox(
                          height: 20,
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 20.0,
                                color: Colors.black,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: 'Service Status',
                                    style: const TextStyle()),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        LayoutBuilder(builder:
                            (BuildContext context, BoxConstraints constraints) {
                          return AnimatedAlign(
                              alignment: Alignment.centerLeft,
                              duration: Duration(milliseconds: 300),
                              child: Container(
                                  width: constraints.maxWidth,
                                  child: Wrap(
                                      direction: Axis.horizontal,
                                      alignment: WrapAlignment.start,
                                      spacing: 10,
                                      runSpacing: 10,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.start,
                                      children: serviceStatuses
                                          .map(
                                            (e) => GestureDetector(
                                                onTap: () {
                                                  if (selectedServiceStatuses
                                                      .contains(e)) {
                                                    setState(() {
                                                      selectedServiceStatuses
                                                          .remove(e);
                                                    });
                                                  } else {
                                                    setState(() {
                                                      selectedServiceStatuses
                                                          .add(e);
                                                    });
                                                  }
                                                },
                                                child: Container(
                                                    decoration: BoxDecoration(
                                                        color:
                                                            selectedServiceStatuses
                                                                    .contains(e)
                                                                ? Color(
                                                                    0xFF323F4B)
                                                                : Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                        border: Border.all(
                                                          color:
                                                              Color(0xFF323F4B),
                                                        )),
                                                    child: Padding(
                                                        padding:
                                                            EdgeInsets.fromLTRB(
                                                                30, 10, 30, 10),
                                                        child: RichText(
                                                            text: TextSpan(
                                                                style:
                                                                    TextStyle(
                                                                  color: selectedServiceStatuses
                                                                          .contains(
                                                                              e)
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .black,
                                                                  fontSize: 12,
                                                                ),
                                                                children: [
                                                              TextSpan(
                                                                  text: '${e}'),
                                                              WidgetSpan(
                                                                child: SizedBox(
                                                                  width: selectedServiceStatuses
                                                                          .contains(
                                                                              e)
                                                                      ? 10
                                                                      : 0,
                                                                ),
                                                              ),
                                                              WidgetSpan(
                                                                  child: Icon(
                                                                Icons.check,
                                                                size: selectedServiceStatuses
                                                                        .contains(
                                                                            e)
                                                                    ? 15
                                                                    : 0,
                                                                color: Colors
                                                                    .white,
                                                              ))
                                                            ]))))),
                                          )
                                          .toList())));
                        }),
                        SizedBox(
                          height: 40,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: double.infinity, // <-- match_parent
                              height: MediaQuery.of(context).size.width *
                                  0.05, // <-- match-parent
                              child: ElevatedButton(
                                  child: Padding(
                                      padding: const EdgeInsets.all(0.0),
                                      child: Text(
                                        'Submit',
                                        style: TextStyle(
                                            fontSize: 15, color: Colors.white),
                                      )),
                                  style: ButtonStyle(
                                      foregroundColor:
                                          MaterialStateProperty.all<Color>(
                                              Color(0xFF323F4B)),
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                              Color(0xFF323F4B)),
                                      shape: MaterialStateProperty.all<
                                              RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4.0),
                                              side: BorderSide(
                                                  color: Color(0xFF323F4B))))),
                                  onPressed: () async {
                                    await submitFilters();
                                    _bsbController.collapse();
                                  }),
                            ),
                          ],
                        )
                      ],
                    ),
                  ));
            },
            body: CustomPaint(
                child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        decoration: new BoxDecoration(
                            color: Colors.white.withOpacity(0.0)),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              errorMsg != "" ? _renderError() : Container(),
                              _renderForm(),
                            ])))),
          ),
        ));
  }
}

class JobItem extends StatelessWidget {
  JobItem(
      {Key? key, required this.width, required this.job, required this.index})
      : super(key: key);

  final double width;
  final Job job;
  final int index;

  final imageUrls = [
    "https://www.pngitem.com/pimgs/m/30-307416_profile-icon-png-image-free-download-searchpng-employee.png",
    "https://www.pngitem.com/pimgs/m/30-307416_profile-icon-png-image-free-download-searchpng-employee.png",
    "https://www.pngitem.com/pimgs/m/30-307416_profile-icon-png-image-free-download-searchpng-employee.png",
    "https://www.pngitem.com/pimgs/m/30-307416_profile-icon-png-image-free-download-searchpng-employee.png"
  ];

  Color getColor() {
    if (job.serviceJobStatus?.toLowerCase() == "request created" ||
        job.serviceJobStatus == "PENDING REPAIR") {
      return Colors.red;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        key: ValueKey(this.key),
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            border: Border.all(width: 0.1),
            color: getColor(),
            boxShadow: [
              BoxShadow(
                  blurRadius: 5,
                  color: Colors.grey[200]!,
                  offset: Offset(0, 10)),
            ],
            borderRadius: BorderRadius.circular(7.5),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  SizedBox(
                    height: 15,
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 20.0,
                                      color: Colors.blue,
                                    ),
                                    children: <TextSpan>[
                                      TextSpan(
                                          text: job != null
                                              ? '# ${job.serviceJobNo}'
                                                  .toString()
                                              : '#-',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 20,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF56C568),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Center(
                                      child: Text(
                                        'Paid',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 20,
                                ),
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.2,
                                  height:
                                      MediaQuery.of(context).size.height * 0.03,
                                  child: Stack(
                                    children: List.generate(4, (index) {
                                      double position = index.toDouble() *
                                          25; // Adjust the overlapping position
                                      return Positioned(
                                        left: position,
                                        child: Container(
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color: Colors.white,
                                                    width: 2.0)),
                                            child: CircleAvatar(
                                              radius: 15.0,
                                              backgroundImage:
                                                  CachedNetworkImageProvider(
                                                      imageUrls[index]),
                                            )),
                                      );
                                    }),
                                  ),
                                )
                              ]),
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF323F4B),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
                                    child: Center(
                                      child: Text(
                                        '${job != null ? job.serviceType : ""}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF56C568),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
                                    child: Center(
                                      child: Text(
                                        '${job.serviceJobStatus}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ])
                        ]),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20.0, 0, 0, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      // Note: Styles for TextSpans must be explicitly defined.
                                      // Child text spans will inherit styles from parent
                                      style: const TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.black87,
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                            text: job.serviceDate != null
                                                ? job.serviceDate
                                                : '-',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  // RichText(
                                  //   text: TextSpan(
                                  //     // Note: Styles for TextSpans must be explicitly defined.
                                  //     // Child text spans will inherit styles from parent
                                  //     style: const TextStyle(
                                  //       fontSize: 14.0,
                                  //       color: Colors.red,
                                  //     ),
                                  //     children: <TextSpan>[
                                  //       TextSpan(
                                  //           text: job.serviceTime != null
                                  //               ? job.serviceTime
                                  //               : '10:00 AM TO 02:00PM',
                                  //           style: const TextStyle(
                                  //               fontWeight: FontWeight.bold)),
                                  //     ],
                                  //   ),
                                  // ),
                                ],
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width * 0.25,
                                child: RichText(
                                  text: TextSpan(
                                    // Note: Styles for TextSpans must be explicitly defined.
                                    // Child text spans will inherit styles from parent
                                    style: const TextStyle(
                                      fontSize: 14.0,
                                      color: Colors.black45,
                                    ),
                                    children: <TextSpan>[
                                      TextSpan(
                                          // text:
                                          //     "3517 W. Gray St. Utica, Pennsylvania 57867",

                                          text: job != null
                                              ? '${job.serviceAddressStreet},${job.serviceAddressCity},${job.serviceAddressPostcode},${job.serviceAddressState}, '
                                              : '',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(
                                height: 10,
                              ),
                              // RichText(
                              //   text: TextSpan(
                              //     // Note: Styles for TextSpans must be explicitly defined.
                              //     // Child text spans will inherit styles from parent
                              //     style: const TextStyle(
                              //       fontSize: 14.0,
                              //       color: Colors.black87,
                              //     ),
                              //     children: <TextSpan>[
                              //       TextSpan(
                              //           text: job != null
                              //               ? job.postcode
                              //                   .toString()
                              //                   .replaceAll("\n", " ")
                              //               : '',
                              //           style: const TextStyle(
                              //               fontWeight: FontWeight.bold)),
                              //     ],
                              //   ),
                              // ),
                              SizedBox(
                                height: 15,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          RichText(
                            textAlign: TextAlign.start,
                            text: TextSpan(
                              // Note: Styles for TextSpans must be explicitly defined.
                              // Child text spans will inherit styles from parent
                              style: const TextStyle(
                                fontSize: 16.0,
                                color: Colors.black54,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: job != null
                                        ? '${job.customerName} (${job.customerTelephone})'
                                        : '-',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              // Note: Styles for TextSpans must be explicitly defined.
                              // Child text spans will inherit styles from parent
                              style: const TextStyle(
                                fontSize: 14.0,
                                color: Colors.black45,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: job != null
                                        ? job.productDescription
                                        : '-',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              // Note: Styles for TextSpans must be explicitly defined.
                              // Child text spans will inherit styles from parent
                              style: const TextStyle(
                                fontSize: 14.0,
                                color: Colors.black45,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: job != null ? job.productCode : '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      )),
                      Container(
                          alignment: Alignment.topRight,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(0.0, 0.0, 0,
                                    MediaQuery.of(context).size.height * 0.03),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    this.job.serviceAddressStreet != ""
                                        ? GestureDetector(
                                            onTap: () async {
                                              var address = this
                                                  .job
                                                  .serviceAddressStreet
                                                  ?.replaceAll("\n", "");
                                              launch(
                                                  "https://www.google.com/maps/search/?api=1&query=${'${job.serviceAddressStreet},${job.serviceAddressCity},${job.serviceAddressPostcode},${job.serviceAddressState},'}");
                                            },
                                            child: Icon(
                                              // <-- Icon
                                              Icons.location_pin,
                                              color: Colors.black54,
                                              size: 25.0,
                                            ),
                                          )
                                        : new Container(),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Icon(
                                      Icons.navigate_next_outlined,
                                      color: Colors.black54,
                                      size: 25.0,
                                    ),
                                  ],
                                ),
                              )
                            ],
                          )),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: ReadMoreText(
                        job != null
                            ? job.remarks
                                .toString()
                                .toLowerCase()
                                .replaceAll("\n", " ")
                            : '-',
                        trimLines: 2,
                        colorClickableText: Colors.black54,
                        trimMode: TrimMode.Line,
                        style: const TextStyle(
                          fontSize: 14.0,
                          color: Colors.black54,
                        ),
                        trimCollapsedText: 'Show more',
                        trimExpandedText: 'Show less',
                        moreStyle: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      // RichText(
                      //   text: TextSpan(
                      //     // Note: Styles for TextSpans must be explicitly defined.
                      //     // Child text spans will inherit styles from parent
                      //     style: const TextStyle(
                      //       fontSize: 14.0,
                      //       color: Colors.black54,
                      //     ),
                      //     children: <TextSpan>[
                      //       TextSpan(
                      //           text: job != null
                      //               ? job.problem
                      //                   .toString()
                      //                   .toLowerCase()
                      //                   .replaceAll("\n", " ")
                      //               : 'Changed order missed by pro',
                      //           style: const TextStyle(
                      //               fontWeight: FontWeight.bold)),
                      //     ],
                      //   ),
                      // ),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
                    child: Row(
                      children: [
                        Icon(
                          // <-- Icon
                          Icons.chat_outlined,
                          color: Colors.black54,
                          size: 19.0,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Container(
                          width: 500,
                          child: ReadMoreText(
                            job.problemDescription != null
                                ? job.problemDescription
                                    .toString()
                                    .toLowerCase()
                                : '-',
                            trimLines: 2,
                            colorClickableText: Colors.black54,
                            trimMode: TrimMode.Line,
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: Colors.red,
                            ),
                            trimCollapsedText: 'Show more',
                            trimExpandedText: 'Show less',
                            moreStyle: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          // RichText(
                          //   maxLines: 5,
                          //   text: TextSpan(
                          //     // Note: Styles for TextSpans must be explicitly defined.
                          //     // Child text spans will inherit styles from parent
                          //     style: const TextStyle(
                          //       fontSize: 14.0,
                          //       color: Colors.red,
                          //     ),
                          //     children: <TextSpan>[
                          //       TextSpan(
                          //           text: job.comment != null
                          //               ? job.comment.toString().toLowerCase()
                          //               : '-',
                          //           style: const TextStyle(
                          //               fontWeight: FontWeight.bold)),
                          //     ],
                          //   ),
                          // ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
