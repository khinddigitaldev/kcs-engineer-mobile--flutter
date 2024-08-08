import 'dart:async';
import 'dart:convert';

import 'package:after_layout/after_layout.dart';
import 'package:bottom_sheet_bar/bottom_sheet_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:kcs_engineer/UI/jobs.dart';
import 'package:kcs_engineer/components/job_item.dart';
import 'package:kcs_engineer/model/acknowledgement/payment_history.dart';
import 'package:kcs_engineer/model/job/filters/job_filter_options.dart';
import 'package:kcs_engineer/model/job/general/reason.dart';
import 'package:kcs_engineer/model/job/job.dart';
import 'package:kcs_engineer/model/payment/paymentCollection.dart';
import 'package:kcs_engineer/model/payment/payment_history_item.dart';
import 'package:kcs_engineer/model/user/user.dart';
import 'package:kcs_engineer/themes/app_colors.dart';
import 'package:kcs_engineer/themes/text_styles.dart';
import 'package:kcs_engineer/util/api.dart';
import 'package:kcs_engineer/util/components/calendarView.dart';
import 'package:kcs_engineer/util/helpers.dart';
import 'package:kcs_engineer/util/repositories.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class AcknowledgedJobList extends StatefulWidget {
  String? selectedDate;

  AcknowledgedJobList({this.selectedDate});

  @override
  _AcknowledgedJobListState createState() => _AcknowledgedJobListState();
}

class _AcknowledgedJobListState extends State<AcknowledgedJobList>
    with AfterLayoutMixin {
  var _refreshKey = GlobalKey<RefreshIndicatorState>();
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController searchCT = new TextEditingController();
  FocusNode focusinProgressSearch = new FocusNode();
  FocusNode focusCompletedSearch = new FocusNode();
  bool isLoading = false;
  bool isLoadingJobList = false;
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
  List<Job?> rejectableJobs = [];
  int currentPage = 1;

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
  bool isBulkRejectEnabled = false;
  List<Job> selectedJobsToReject = [];
  int? selectedRejectReason = null;
  List<Reason>? rejectReasons = [];
  bool isErrorRejectReason = false;
  PaymentCollection? paymentCollection;
  bool isCollectionVisible = false;

  String? currentSearchText;
  ScrollController? controller;

  final storage = new FlutterSecureStorage();
  String? token;

  String startDate = "";
  String toDate = "";

  bool isLoadedCollectedCash = false;
  bool isLoadingCollectedCash = false;

  @override
  void initState() {
    controller = ScrollController()..addListener(_scrollListener);
    super.initState();
  }

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) async {
    await _loadVersion();
    await _fetchAcknowledgedJobs(true);
    await _fetchJobStatuses();
    await fetchRejecReasons();
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
    setDates();
  }

  setDates() {
    DateTime now = DateTime.now();

    // Get date 30 days ago
    DateTime thirtyDaysAgo = now.subtract(Duration(days: 30));

    // Format dates in '2023-08-29T11:08:12Z' format

    setState(() {
      toDate = now.toString().replaceAll(' ', 'T');
      startDate = thirtyDaysAgo.toString().replaceAll(' ', 'T');
    });
  }

  fetchPaymentCollection() async {
    setState(() {
      isLoadedCollectedCash = false;
      isLoadingCollectedCash = true;
    });
    var collection = await Repositories.fetchPaymentCollection();

    setState(() {
      isLoadedCollectedCash = true;
      isLoadingCollectedCash = false;
      paymentCollection = collection;
      isCollectionVisible = !isCollectionVisible;
    });
  }

  fetchRejecReasons() async {
    isLoading = true;
    var reasons = await Repositories.fetchRejectReasons();
    isLoading = false;
    if (mounted) {
      setState(() {
        rejectReasons = reasons;
      });
    }
  }

  @override
  void dispose() {
    searchCT.dispose();
    controller?.removeListener(_scrollListener);
    super.dispose();
  }

  void _scrollListener() async {
    if (controller?.position.atEdge ?? false) {
      bool isTop = controller?.position.pixels == 0;

      if (!isTop && currentPage <= (jobData?.meta?.lastPage ?? 0)) {
        currentPage = currentPage + 1;

        await _fetchAcknowledgedJobs(false);
      }
    }
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

  _fetchAcknowledgedJobs(bool isErasePrevious) async {
    JobData? existingJobData;

    if (!isErasePrevious) {
      setState(() {
        existingJobData = jobData;
      });
    } else {
      setState(() {
        currentPage = 1;
      });
    }

    if (Helpers.loggedInUser != null) {
      user = Helpers.loggedInUser;
    }
    var fetchedJobData = null;

    var filters = {
      "consecutive_days": consecutiveDays,
      ...(currentSearchText != null && currentSearchText != ""
          ? {"q": currentSearchText}
          : {}),
      "filters": {
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
            : {}),
      },
      "start_date": '${startDate.split('.')[0]}Z',
      "end_date": '${toDate.split('.')[0]}Z',
      ...(currentSearchText != null && currentSearchText != ""
          ? {"q": currentSearchText}
          : {})
    };

    var filterMap = filters["filters"] as Map<dynamic, dynamic>;
    if (filterMap.entries.isEmpty) {
      filters.remove("filters");
    }

    Helpers.showAlert(context);
    fetchedJobData = await Repositories.fetchPaymentHistoryJobList(
        widget.selectedDate ?? "", null, null, null, currentSearchText);
    Navigator.pop(context);

    setState(() {
      jobData = fetchedJobData;
      if (!isErasePrevious) {
        jobData?.jobs?.insertAll(0, existingJobData?.jobs ?? []);
      }
      inProgressJobs = (jobData as JobData).jobs ?? [];
      rejectableJobs = ((jobData as JobData).jobs ?? []).map((e) {
        if (e.serviceJobStatus?.toLowerCase() == "pending job start") {
          return e;
        }
      }).toList();
      Helpers.inProgressJobs = inProgressJobs;
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
    Helpers.inProgressJobs = inProgressJobs;

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

  _onChangeHandlerForInprogress(value) {
    const duration = Duration(
        milliseconds:
            1000); // set the duration that you want call search() after that.

    if (searchOnInProgressStoppedTyping != null) {
      setState(() => searchOnInProgressStoppedTyping!.cancel()); // clear timer
    }
    setState(
        () => searchOnInProgressStoppedTyping = new Timer(duration, () async {
              if (currentSearchTextInProgress != value || value == "") {
                currentSearchText = value;
                await _fetchAcknowledgedJobs(true);
              }
            }));
  }

  _sortJobsForReject() {
    List<Job> items = [];
    items.addAll(inProgressJobs);
    items.sort(customComparator);
    setState(() {
      inProgressJobs = [];
      inProgressJobs = items;
    });
  }

  int customComparator(Job a, Job b) {
    if (a.serviceJobStatus?.toLowerCase() == 'pending job start' &&
        b.serviceJobStatus?.toLowerCase() != 'pending job start') {
      return -1;
    } else if (a.serviceJobStatus?.toLowerCase() != 'pending job start' &&
        b.serviceJobStatus?.toLowerCase() == 'pending job start') {
      return 1;
    } else {
      return 0;
    }
  }

  Widget _renderForm() {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Form(
        key: _formKey,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Padding(
                  padding: EdgeInsets.fromLTRB(10.0, 0, 0, 0),
                  child: Row(children: [
                    Container(
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    Spacer(),
                  ])),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.fromLTRB(10.0, 0, 0, 0),
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: Divider(color: Colors.grey),
                ),
              ),
              SizedBox(height: 20),
              RichText(
                text: const TextSpan(
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Payment Info',
                      ),
                    ]),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              _renderMetaData(),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
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
                            text: 'LIST OF JOBS',
                          ),
                        ]),
                  ),
                ),
              ),
              (inProgressJobs != null && inProgressJobs.length > 0)
                  ? SizedBox(
                      height: 40,
                    )
                  : new Container(),
              SizedBox(
                height: 20,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 0.0, 0),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.4,
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
                                  controller: searchCT,
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
                      )),
                  Spacer(),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.15,
                    height: MediaQuery.of(context).size.width * 0.05,
                    padding: EdgeInsets.only(left: 20),
                    child: ElevatedButton(
                        child: Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: Row(children: [
                              Icon(
                                Icons.filter_list_outlined,
                                color: Colors.black54,
                              ),
                              SizedBox(
                                width: 5,
                              ),
                              Text(
                                'Filter',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.black54),
                              )
                            ])),
                        style: ButtonStyle(
                            foregroundColor:
                                MaterialStateProperty.all<Color>(Colors.white),
                            backgroundColor:
                                MaterialStateProperty.all<Color>(Colors.white),
                            shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
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
                          maxHeight: MediaQuery.of(context).size.height * .5,
                          minHeight: MediaQuery.of(context).size.height * .45),
                      child: ReorderableListView.builder(
                        onReorder: ((oldIndex, newIndex) async {
                          var res = await Repositories.changeSequence(
                              inProgressJobs[oldIndex].serviceRequestid ?? "",
                              newIndex.toString());
                          await _fetchAcknowledgedJobs(false);
                        }),
                        scrollController: controller,
                        shrinkWrap: true,
                        itemCount: inProgressJobs.length,
                        itemBuilder: (BuildContext context, int index) {
                          return GestureDetector(
                            child: JobItem(
                                key: ValueKey(index),
                                width: MediaQuery.of(context).size.width,
                                job: inProgressJobs[index],
                                inProgressJobs: inProgressJobs,
                                isBulkRejectEnabled: isBulkRejectEnabled,
                                selectedJobsToReject: selectedJobsToReject,
                                isSelectedItemForReject: (isAdd, job) {
                                  if (isAdd) {
                                    setState(() {
                                      selectedJobsToReject.add(job);
                                    });
                                  } else {
                                    setState(() {
                                      selectedJobsToReject.remove(job);
                                    });
                                  }
                                },
                                index: index),
                            onTap: () async {
                              Helpers.selectedJobIndex = index;
                              Helpers.showAlert(context);

                              Job? job;
                              Navigator.pop(context);
                              // if (job != null) {
                              Helpers.selectedJob = job;
                              if (!isBulkRejectEnabled) {
                                Navigator.pushNamed(context, 'jobDetails',
                                        arguments: inProgressJobs[index]
                                            .serviceRequestid)
                                    .then((value) async {
                                  await resetArrays();
                                });
                              } else {
                                bool isAdd = selectedJobsToReject
                                        .where((element) =>
                                            element.serviceRequestid ==
                                            inProgressJobs[index]
                                                .serviceRequestid)
                                        ?.isEmpty ??
                                    false;
                                if (isAdd) {
                                  setState(() {
                                    selectedJobsToReject
                                        .add(inProgressJobs[index]);
                                  });
                                } else {
                                  setState(() {
                                    selectedJobsToReject
                                        .remove(inProgressJobs[index]);
                                  });
                                }
                              }

                              // }
                            },
                            key: ValueKey(index),
                          );
                        },
                      ),
                    )
                  : isLoadingJobList
                      ? Container(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: LoadingAnimationWidget.staggeredDotsWave(
                              color: Color(0xFF000000),
                              size: MediaQuery.of(context).size.height * 0.03,
                            ),
                          ),
                        )
                      : Container(),
              SizedBox(
                height: 30,
              ),
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
      isLoadedCollectedCash = false;
      isLoadingCollectedCash = false;
      paymentCollection = null;
      isCollectionVisible = false;
    });
    DateTime now = DateTime.now();
    DateTime thirtyDaysAgo = now.subtract(Duration(days: 30));
    setState(() {
      toDate = now.toString().replaceAll(' ', 'T');
      startDate = thirtyDaysAgo.toString().replaceAll(' ', 'T');
      currentPage = 1;
    });

    await _fetchAcknowledgedJobs(true);
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
    await _fetchAcknowledgedJobs(true);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        key: _refreshKey,
        onRefresh: () async {
          await _fetchAcknowledgedJobs(true);
        },
        child: Scaffold(
          key: _scaffoldKey,
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
                child: Stack(children: [
              SingleChildScrollView(
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
                          ]))),
              Positioned(
                  right: 1,
                  left: 1,
                  bottom: 25,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                  ))
            ])),
          ),
        ));
  }

  _renderMetaData() {
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      RichText(
                        text: const TextSpan(
                            style: TextStyle(
                              fontSize: 13.0,
                              color: Color(0xFFC4C4C4),
                            ),
                            children: <TextSpan>[
                              const TextSpan(
                                text: 'DATE',
                              ),
                            ]),
                      ),
                      RichText(
                        text: TextSpan(
                            style: TextStyle(
                              fontSize: 15.0,
                              color: Colors.black87,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: jobData?.meta?.insertedDate,
                              ),
                            ]),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      RichText(
                        text: const TextSpan(
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Color(0xFFC4C4C4),
                            ),
                            children: <TextSpan>[
                              const TextSpan(
                                text: 'JOBS COMPLETED',
                              ),
                            ]),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        child: RichText(
                          text: TextSpan(
                              style: TextStyle(
                                fontSize: 15.0,
                                color: Colors.black87,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: jobData?.meta?.jobsCompleted.toString(),
                                ),
                              ]),
                        ),
                      )
                    ],
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      RichText(
                        text: const TextSpan(
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Color(0xFFC4C4C4),
                            ),
                            children: <TextSpan>[
                              const TextSpan(
                                text: 'CASH COLLECTED',
                              ),
                            ]),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        child: RichText(
                          text: TextSpan(
                              style: TextStyle(
                                fontSize: 15.0,
                                color: Colors.black87,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: jobData?.meta?.cashCollected,
                                ),
                              ]),
                        ),
                      )
                    ],
                  ),
                ),
              ]),
          SizedBox(height: MediaQuery.of(context).size.height * 0.015),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              RichText(
                text: const TextSpan(
                    style: TextStyle(
                      fontSize: 13.0,
                      color: Color(0xFFC4C4C4),
                    ),
                    children: <TextSpan>[
                      const TextSpan(
                        text: 'CR REMARK',
                      ),
                    ]),
              ),
              SizedBox(
                height: 5,
              ),
              Container(
                child: RichText(
                  text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: Colors.black87,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: jobData?.meta?.crRemark,
                        ),
                      ]),
                ),
              ),
            ],
          ),
        ]);
  }
}
