import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kcs_engineer/model/job.dart';
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

class _JobListState extends State<JobList> with WidgetsBindingObserver {
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

  int? currentSelectedIndex = 0;

  User? user;

  final storage = new FlutterSecureStorage();
  String? token;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _loadVersion();
      _fetchJobs();
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
    Helpers.showAlert(context);
    if (Helpers.loggedInUser != null) {
      user = Helpers.loggedInUser;
    }

    // final response = await Api.bearerGet('job-orders/with-relationship');
    // print("#Resp: ${jsonEncode(response)}");
    // // Navigator.pop(context);
    // if (response["success"] != null) {
    //   if (user == null) {
    //     user = new User();
    //   }

    //   user!.allJobsCount = response["meta"]?["allJobsCount"];
    //   user!.completedJobsCount = response["meta"]?["completedJobsCount"];
    //   user!.uncompletedJobsCount = response["meta"]?["uncompletedJobsCount"];

    //   var fetchedJobs = (response['data'] as List)
    //       .map((i) => Job.jobListfromJson(i))
    //       .toList();

    //   fetchedJobs.sort((a, b) => int.parse((a.sequence ?? "100"))
    //       .compareTo(int.parse(b.sequence ?? "100")));

    //   List<Job> completed = [];
    //   List<Job> inProgress = [];

    //   for (int i = 0; i < fetchedJobs.length; i++) {
    //     if (fetchedJobs[i].status == "IN PROGRESS" ||
    //         fetchedJobs[i].status == "PENDING REPAIR") {
    //       inProgress.add(fetchedJobs[i]);
    //     } else {
    //       completed.add(fetchedJobs[i]);
    //     }
    //   }
    //   setState(() {
    //     inProgressJobs = inProgress;
    //     completedJobs = completed;
    //     Helpers.completedJobs = completed;
    //     Helpers.inProgressJobs = inProgress;
    //     Helpers.loggedInUser = user;
    //   });
    //   await updateJobSequence();
    // } else {
    //   //show ERROR
    // }

    var jobs = [];

    setState(() {
      inProgressJobs = [new Job(), new Job(), new Job(), new Job(), new Job()];
      completedJobs = [new Job(), new Job(), new Job(), new Job(), new Job()];
      Helpers.completedJobs = [
        new Job(),
        new Job(),
        new Job(),
        new Job(),
        new Job()
      ];
      Helpers.inProgressJobs = [
        new Job(),
        new Job(),
        new Job(),
        new Job(),
        new Job()
      ];
      Helpers.loggedInUser = user;
    });

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
          final comment =
              element.comment != null ? element.comment!.toLowerCase() : "";
          final customerName = element.customerName != null
              ? element.customerName!.toLowerCase()
              : "";
          final productCode = element.productCode != null
              ? element.productCode!.toLowerCase()
              : "";
          final productDesc = element.productDescription != null
              ? element.productDescription!.toLowerCase()
              : "";
          final remark =
              element.problem != null ? element.problem!.toLowerCase() : "";
          final jobRefNo =
              element.refNo != null ? element.refNo!.toLowerCase() : "";
          final input = query.toLowerCase();

          return (comment.toLowerCase().contains(input) ||
              customerName.toLowerCase().contains(input) ||
              productCode.toLowerCase().contains(input) ||
              productDesc.toLowerCase().contains(input) ||
              jobRefNo.toLowerCase().contains(input) ||
              remark.toLowerCase().contains(input));
        }).toList();
      } else {
        Helpers.completedJobs = Helpers.completedJobs.where((element) {
          final comment =
              element.comment != null ? element.comment!.toLowerCase() : "";
          final customerName = element.customerName != null
              ? element.customerName!.toLowerCase()
              : "";
          final productCode = element.productCode != null
              ? element.productCode!.toLowerCase()
              : "";
          final productDesc = element.productDescription != null
              ? element.productDescription!.toLowerCase()
              : "";
          final remark =
              element.problem != null ? element.problem!.toLowerCase() : "";
          final jobRefNo =
              element.refNo != null ? element.refNo!.toLowerCase() : "";
          final input = query.toLowerCase();

          return (comment.toLowerCase().contains(input) ||
              customerName.toLowerCase().contains(input) ||
              productCode.toLowerCase().contains(input) ||
              productDesc.toLowerCase().contains(input) ||
              jobRefNo.toLowerCase().contains(input) ||
              remark.toLowerCase().contains(input));
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
                          text:
                              Helpers.loggedInUser?.uncompletedJobsCount != null
                                  ? Helpers.loggedInUser?.uncompletedJobsCount
                                      .toString()
                                  : "",
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
                        text: Helpers.loggedInUser?.allJobsCount != null
                            ? Helpers.loggedInUser?.allJobsCount.toString()
                            : "",
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
                        text: Helpers.loggedInUser?.completedJobsCount != null
                            ? Helpers.loggedInUser?.completedJobsCount
                                .toString()
                            : "",
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
              dateSelected: (index) {
                setState(() {
                  currentSelectedIndex = index;
                });
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
          (inProgressJobs != null && inProgressJobs.length > 0)
              ? Padding(
                  padding: EdgeInsets.fromLTRB(0, 0, 420.0, 0),
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
                                contentPadding: EdgeInsets.fromLTRB(0, 5, 0, 0),
                                prefixIcon: Icon(Icons.search),
                              )),
                        ),
                      ],
                    ),
                  ))
              : new Container(),
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
                      final index =
                          newIndex > oldIndex ? newIndex - 1 : newIndex;
                      final job = Helpers.inProgressJobs.removeAt(oldIndex);
                      Helpers.inProgressJobs.insert(index, job);
                      Helpers.showAlert(context);
                      await updateJobSequence();
                      Navigator.pop(context);
                    }),

                    shrinkWrap: true,
                    // shrinkWrap: false,
                    itemCount: 5,
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
                          // Job? job = await Repositories.fetchJobDetails(
                          //     jobId: Helpers.inProgressJobs[index].id);
                          Job? job;
                          Navigator.pop(context);
                          // if (job != null) {
                          Helpers.selectedJob = job;
                          Navigator.pushNamed(context, 'jobDetails',
                                  arguments: Helpers.selectedJob)
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

  updateJobSequence() async {
    List<JobOrderSequence> sequences = [];
    JobOrderSequence seq;
    for (var i = 0; i < Helpers.inProgressJobs.length; i++) {
      seq = new JobOrderSequence();
      seq.jobOrderId = Helpers.inProgressJobs[i].id;
      seq.sequence = i + 1;
      sequences.add(seq);
    }

    bool response = await Repositories.updateJobOrderSequence(sequences);

    setState(() {
      //Sequence erorr failed or not
    });
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

                            //Expanded(child: _renderBottom()),
                            //version != "" ? _renderVersion() : Container()
                          ])))),
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
    if (job.status == "IN PROGRESS" || job.status == "PENDING REPAIR") {
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
                                          text: "#38472",

                                          // job != null
                                          //     ? '# ${job.refNo}'.toString()
                                          //     : '#38472',
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
                                      MediaQuery.of(context).size.width * 0.3,
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
                                    padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
                                    child: Center(
                                      child: Text(
                                        'Drop-In',
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
                                    padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
                                    child: Center(
                                      child: Text(
                                        'Completed',
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
                                            text: job.date != null
                                                ? job.date
                                                : '06/02/2019',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  RichText(
                                    text: TextSpan(
                                      // Note: Styles for TextSpans must be explicitly defined.
                                      // Child text spans will inherit styles from parent
                                      style: const TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.red,
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                            text: job.time != null
                                                ? job.time
                                                : '10:00 AM TO 02:00PM',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              RichText(
                                text: TextSpan(
                                  // Note: Styles for TextSpans must be explicitly defined.
                                  // Child text spans will inherit styles from parent
                                  style: const TextStyle(
                                    fontSize: 14.0,
                                    color: Colors.black45,
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                        text:
                                            "3517 W. Gray St. Utica, Pennsylvania 57867",

                                        // job != null
                                        //     ? job.address
                                        //         .toString()
                                        //         .replaceAll("\n", " ")
                                        //     : '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
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
                                    text: 'Esther Howard (+65 9572 0181)',

                                    // job != null
                                    //     ? '${job.customerName} (${job.customerContactNo})'
                                    //     : 'Esther Howard (+65 9572 0181)',
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
                                    text: 'Disney x Mayer 3L Air Fryer',

                                    // job != null
                                    //     ? job.productDescription
                                    //     : 'Disney x Mayer 3L Air Fryer',
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
                                    text: "MMDO12C",

                                    // job != null
                                    //     ? job.productCode
                                    //     : '',
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
                                    this.job.address != ""
                                        ? GestureDetector(
                                            onTap: () async {
                                              var address = this
                                                  .job
                                                  .address
                                                  ?.replaceAll("\n", "");
                                              launch(
                                                  "https://www.google.com/maps/search/?api=1&query=$address");
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
                        // job != null
                        //     ? job.problem
                        //         .toString()
                        //         .toLowerCase()
                        //         .replaceAll("\n", " ")
                        //     : '-',
                        "Changed order missed by pro",
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
                            // job.comment != null
                            //     ? job.comment.toString().toLowerCase()
                            //     : '-',

                            "Start collecting on Friday morning, not Thursday",
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
