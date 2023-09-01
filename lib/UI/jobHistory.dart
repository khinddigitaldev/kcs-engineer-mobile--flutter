// import 'dart:async';
// import 'dart:convert';
// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:intl/intl.dart';
// import 'package:kcs_engineer/model/job.dart';
// import 'package:kcs_engineer/model/user.dart';
// import 'package:kcs_engineer/themes/app_colors.dart';
// import 'package:kcs_engineer/themes/text_styles.dart';
// import 'package:kcs_engineer/util/api.dart';
// import 'package:kcs_engineer/util/helpers.dart';
// import 'package:kcs_engineer/util/repositories.dart';
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:readmore/readmore.dart';
// import 'package:syncfusion_flutter_datepicker/datepicker.dart';
// import 'package:url_launcher/url_launcher.dart';

// class JobHistory extends StatefulWidget with WidgetsBindingObserver {
//   int? data;
//   JobHistory({this.data});

//   @override
//   _JobHistoryState createState() => _JobHistoryState();
// }

// class _JobHistoryState extends State<JobHistory> with WidgetsBindingObserver {
//   var _refreshKey = GlobalKey<RefreshIndicatorState>();
//   GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
//   GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//   TextEditingController searchCT = new TextEditingController();
//   TextEditingController filterCT = new TextEditingController();
//   FocusNode focusSearch = new FocusNode();
//   FocusNode focusFilter = new FocusNode();
//   bool isLoading = false;
//   bool showPassword = false;
//   String errorMsg = "";
//   String version = "";
//   bool status = false;
//   //List<Job> inProgressJobs = [];
//   // List<Job> completedJobs = [];
//   Timer? searchOnInProgressStoppedTyping;
//   String currentSearchTextInProgress = "";
//   Timer? searchCompletedOnStoppedTyping;
//   String currentSearchTextCompleted = "";
//   List<Job> completedJobs = [];
//   List<Job> previousData = [];
//   String startDate = "";
//   String endDate = "";
//   String tempStartDate = "";
//   String tempEndDate = "";
//   bool isFiltersAdded = false;
//   int currentPage = 1;
//   int? lastPage;
//   ScrollController? controller;

//   User? user;

//   final storage = new FlutterSecureStorage();
//   String? token;

//   @override
//   void initState() {
//     super.initState();
//     controller = ScrollController()..addListener(_scrollListener);

//     Future.delayed(Duration.zero, () {
//       _loadVersion();
//       _fetchJobHistories(true);
//     });
//   }

//   @override
//   void dispose() {
//     controller?.removeListener(_scrollListener);

//     searchCT.dispose();
//     filterCT.dispose();
//     super.dispose();
//   }

//   void _scrollListener() async {
//     if (controller?.position.atEdge ?? false) {
//       bool isTop = controller?.position.pixels == 0;

//       if (!isTop) {
//         setState(() {
//           currentPage = currentPage + 1;
//         });
//         if (currentPage <= (lastPage ?? 0)) {
//           await _fetchJobHistories(false);
//         }
//       }
//     }
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {}
//   }

//   _loadVersion() async {
//     PackageInfo packageInfo = await PackageInfo.fromPlatform();
//     String pkgVersion = packageInfo.version;

//     setState(() {
//       version = pkgVersion;
//     });
//   }

//   _fetchJobHistories(bool erasePrevious) async {
//     Helpers.showAlert(context);
//     if (Helpers.loggedInUser != null) {
//       user = Helpers.loggedInUser;
//     }

//     previousData = [];

//     if (!erasePrevious) {
//       setState(() {
//         previousData.addAll(completedJobs);
//       });
//     }

//     var url = 'job-orders/history?per_page=20&page=$currentPage' +
//         ((startDate != "") ? '&start_date=$startDate' : '') +
//         ((endDate != "")
//             ? '&end_date=$endDate'
//             : ((startDate != "") ? '&end_date=$startDate' : '')) +
//         ((searchCT.text != "") ? '&q=${searchCT.text}' : '');

//     final response = await Api.bearerGet(url);
//     print("#Resp: ${jsonEncode(response)}");
//     // Navigator.pop(context);
//     if (response["success"] != null) {
//       if (user == null) {
//         user = new User();
//       }

//       user!.allJobsCount = response["meta"]?["allJobsCount"];
//       user!.completedJobsCount = response["meta"]?["completedJobsCount"];
//       user!.uncompletedJobsCount = response["meta"]?["uncompletedJobsCount"];

//       setState(() {
//         lastPage = response['meta']['last_page'];
//       });

//       var fetchedJobs = (response['data'] as List)
//           .map((i) => Job.jobListfromJson(i))
//           .toList();

//       previousData.addAll(fetchedJobs);

//       setState(() {
//         completedJobs = previousData;
//         Helpers.completedJobs = completedJobs;
//         Helpers.loggedInUser = user;
//       });
//     } else {
//       //show ERROR
//     }

//     Navigator.pop(context);
//   }

//   // searchBox(String query) async {
//   //   setState(() {
//   //     Helpers.inProgressJobs = Helpers.inProgressJobs.where((element) {
//   //       final comment =
//   //           element.comment != null ? element.comment!.toLowerCase() : "";
//   //       final customerName = element.customerName != null
//   //           ? element.customerName!.toLowerCase()
//   //           : "";
//   //       final productCode = element.productCode != null
//   //           ? element.productCode!.toLowerCase()
//   //           : "";
//   //       final productDesc = element.productDescription != null
//   //           ? element.productDescription!.toLowerCase()
//   //           : "";
//   //       final remark =
//   //           element.problem != null ? element.problem!.toLowerCase() : "";
//   //       final jobRefNo =
//   //           element.refNo != null ? element.refNo!.toLowerCase() : "";
//   //       final input = query.toLowerCase();

//   //       return (comment.toLowerCase().contains(input) ||
//   //           customerName.toLowerCase().contains(input) ||
//   //           productCode.toLowerCase().contains(input) ||
//   //           productDesc.toLowerCase().contains(input) ||
//   //           jobRefNo.toLowerCase().contains(input) ||
//   //           remark.toLowerCase().contains(input));
//   //     }).toList();
//   //   });
//   // }

//   _onChangeHandlerForCompletion(value) {
//     const duration = Duration(
//         milliseconds:
//             2000); // set the duration that you want call search() after that.

//     if (searchCompletedOnStoppedTyping != null) {
//       setState(() => searchCompletedOnStoppedTyping!.cancel()); // clear timer
//     }
//     setState(
//         () => searchCompletedOnStoppedTyping = new Timer(duration, () async {
//               currentPage = 1;
//               await _fetchJobHistories(true);
//             }));
//   }

//   showDatePicker() {
//     AlertDialog filterDialog = AlertDialog(
//       title: Center(child: Text("Pick a Date")),
//       actionsAlignment: MainAxisAlignment.center,
//       actions: [
//         Container(
//           color: Colors.white,
//           height: MediaQuery.of(context).size.height * 0.04,
//           width: MediaQuery.of(context).size.width * 0.3,
//           child: ElevatedButton(
//               child: Padding(
//                   padding: const EdgeInsets.all(5.0),
//                   child: Text(
//                     'CANCEL',
//                     style: TextStyle(fontSize: 13, color: Colors.white),
//                   )),
//               style: ButtonStyle(
//                   foregroundColor:
//                       MaterialStateProperty.all<Color>(AppColors.primary),
//                   backgroundColor:
//                       MaterialStateProperty.all<Color>(AppColors.primary),
//                   shape: MaterialStateProperty.all<RoundedRectangleBorder>(
//                       RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(5.0),
//                           side: BorderSide(color: AppColors.primary)))),
//               onPressed: () async {
//                 Navigator.pop(context);
//               }),
//         ),
//         Container(
//           height: MediaQuery.of(context).size.height * 0.04,
//           width: MediaQuery.of(context).size.width * 0.3,
//           child: ElevatedButton(
//               child: Padding(
//                   padding: const EdgeInsets.all(5.0),
//                   child: Text(
//                     'DONE',
//                     style: TextStyle(fontSize: 13, color: Colors.white),
//                   )),
//               style: ButtonStyle(
//                   foregroundColor:
//                       MaterialStateProperty.all<Color>(AppColors.primary),
//                   backgroundColor:
//                       MaterialStateProperty.all<Color>(AppColors.primary),
//                   shape: MaterialStateProperty.all<RoundedRectangleBorder>(
//                       RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(5.0),
//                           side: BorderSide(color: AppColors.primary)))),
//               onPressed: () async {
//                 setState(() {
//                   startDate = tempStartDate;
//                   endDate = tempEndDate;
//                   isFiltersAdded = true;
//                   currentPage = 1;
//                 });
//                 filterCT.text = '${tempStartDate} - ${tempEndDate}';
//                 await _fetchJobHistories(true);
//                 Navigator.pop(context);
//               }),
//         )
//       ],
//       content: Container(
//         height: MediaQuery.of(context).size.height * 0.4,
//         width: MediaQuery.of(context).size.width * 0.6,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: Border.all(
//             width: 0.4,
//             color: Colors.grey.withOpacity(0.5),
//           ),
//           boxShadow: [
//             BoxShadow(
//                 blurRadius: 5, color: Colors.grey[200]!, offset: Offset(0, 10)),
//           ],
//           borderRadius: BorderRadius.circular(7.5),
//         ),
//         child: SfDateRangePicker(
//           headerHeight: 60,
//           selectionMode: DateRangePickerSelectionMode.range,
//           headerStyle: DateRangePickerHeaderStyle(
//               textStyle: TextStyle(
//                   fontWeight: FontWeight.w400,
//                   fontSize: 20,
//                   color: Colors.black)),
//           selectionTextStyle: TextStyle(
//               fontWeight: FontWeight.w400, fontSize: 16, color: Colors.black),
//           monthCellStyle: DateRangePickerMonthCellStyle(
//             textStyle: TextStyle(
//                 fontWeight: FontWeight.w400, fontSize: 16, color: Colors.black),
//             leadingDatesDecoration: BoxDecoration(
//                 color: const Color(0xFFDFDFDF),
//                 border: Border.all(color: const Color(0xFFB6B6B6), width: 1),
//                 shape: BoxShape.circle),
//           ),

//           onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
//             setState(() {
//               if (args.value.startDate != null) {
//                 tempStartDate =
//                     DateFormat('yyyy-MM-dd').format(args.value.startDate);
//               }
//               if (args.value.endDate != null) {
//                 tempEndDate =
//                     DateFormat('yyyy-MM-dd').format(args.value.endDate);
//               } else if (args.value.startDate != null) {
//                 tempEndDate = tempStartDate;
//               }
//             });

//             // setState(() {
//             //   tempSelectedDate = DateFormat('yyyy-MM-dd').format(
//             //       DateFormat('yyyy-MM-dd hh:mm:ss')
//             //           .parse(args.value.toString()));
//             // });
//           },
//           // initialSelectedRange: PickerDateRange(
//           //     DateTime.now().subtract(const Duration(days: 4)),
//           //     DateTime.now().add(const Duration(days: 3))),
//         ),
//       ),
//     );
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return filterDialog;
//       },
//     );
//   }

//   Widget _renderForm() {
//     return Container(
//       padding: EdgeInsets.all(10),
//       decoration: BoxDecoration(
//           color: Colors.white, borderRadius: BorderRadius.circular(10)),
//       child: Form(
//         key: _formKey,
//         child: Column(children: [
//           SizedBox(height: 10),
//           Padding(
//             padding: EdgeInsets.fromLTRB(10.0, 0, 0, 0),
//             child: Container(
//               alignment: Alignment.centerLeft,
//               child: RichText(
//                 text: TextSpan(
//                   style: const TextStyle(
//                     fontSize: 32.0,
//                     color: Colors.black,
//                   ),
//                   children: <TextSpan>[
//                     TextSpan(
//                         text: 'Job History',
//                         style: const TextStyle(fontWeight: FontWeight.bold)),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           SizedBox(height: 10),
//           Padding(
//             padding: EdgeInsets.fromLTRB(10.0, 0, 0, 0),
//             child: Container(
//               alignment: Alignment.centerLeft,
//               child: Divider(color: Colors.grey),
//             ),
//           ),
//           SizedBox(height: 20),
//           Padding(
//             padding: EdgeInsets.fromLTRB(10.0, 0, 0, 0),
//             child: Container(
//               alignment: Alignment.centerLeft,
//               child: RichText(
//                 text: TextSpan(
//                     // Note: Styles for TextSpans must be explicitly defined.
//                     // Child text spans will inherit styles from parent
//                     style: const TextStyle(
//                       fontSize: 25.0,
//                       color: Colors.black,
//                     ),
//                     children: <TextSpan>[
//                       TextSpan(
//                         text: 'LIST OF JOBS',
//                       ),
//                     ]),
//               ),
//             ),
//           ),
//           SizedBox(
//             height: 20,
//           ),
//           Row(
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   width: 250,
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.spaceAround,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       SizedBox(
//                         height: 40,
//                         child: TextFormField(
//                             focusNode: focusSearch,
//                             keyboardType: TextInputType.text,
//                             onChanged: _onChangeHandlerForCompletion,
//                             controller: searchCT,
//                             onFieldSubmitted: (val) {
//                               FocusScope.of(context)
//                                   .requestFocus(new FocusNode());
//                             },
//                             style: TextStyles.textDefaultBold,
//                             decoration: const InputDecoration(
//                               border: OutlineInputBorder(),
//                               hintText: 'Search',
//                               contentPadding: EdgeInsets.fromLTRB(0, 5, 0, 0),
//                               prefixIcon: Icon(Icons.search),
//                             )),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Spacer(),
//                 Row(children: [
//                   GestureDetector(
//                       onTap: () async {
//                         await showDatePicker();
//                       },
//                       child: Container(
//                         alignment: Alignment.centerRight,
//                         width: 200,
//                         child: SizedBox(
//                           height: 40,
//                           child: TextFormField(
//                               focusNode: focusFilter,
//                               keyboardType: TextInputType.text,
//                               //onChanged: _onChangeHandlerForCompletion,
//                               enabled: false,
//                               controller: filterCT,
//                               onFieldSubmitted: (val) {
//                                 FocusScope.of(context)
//                                     .requestFocus(new FocusNode());
//                               },
//                               style:
//                                   TextStyle(fontSize: 10, color: Colors.black),
//                               decoration: const InputDecoration(
//                                 border: OutlineInputBorder(),
//                                 hintText: 'Filter By',
//                                 contentPadding:
//                                     EdgeInsets.fromLTRB(15, 5, 5, 5),
//                                 suffixIcon: Icon(Icons.calendar_month),
//                               )),
//                         ),
//                       )),
//                   SizedBox(
//                     width: 5,
//                   ),
//                   isFiltersAdded
//                       ? Container(
//                           color: Colors.white,
//                           height: 40,
//                           width: MediaQuery.of(context).size.width * 0.1,
//                           child: ElevatedButton(
//                               child: Padding(
//                                   padding: const EdgeInsets.all(5.0),
//                                   child: Text(
//                                     'CLEAR',
//                                     style: TextStyle(
//                                         fontSize: 11, color: Colors.white),
//                                   )),
//                               style: ButtonStyle(
//                                   foregroundColor:
//                                       MaterialStateProperty.all<Color>(
//                                           AppColors.primary),
//                                   backgroundColor:
//                                       MaterialStateProperty.all<Color>(
//                                           AppColors.primary),
//                                   shape: MaterialStateProperty.all<
//                                           RoundedRectangleBorder>(
//                                       RoundedRectangleBorder(
//                                           borderRadius:
//                                               BorderRadius.circular(5.0),
//                                           side: BorderSide(
//                                               color: AppColors.primary)))),
//                               onPressed: () async {
//                                 setState(() {
//                                   startDate = "";
//                                   endDate = "";
//                                   tempStartDate = "";
//                                   tempEndDate = "";
//                                   isFiltersAdded = false;
//                                   filterCT.text = "";
//                                   currentPage = 1;
//                                 });
//                                 await _fetchJobHistories(true);
//                               }),
//                         )
//                       : new Container(),
//                 ])
//               ]),
//           SizedBox(
//             height: 20,
//           ),
//           (completedJobs != null && completedJobs.length > 0)
//               ? SizedBox(
//                   height: 20,
//                 )
//               : new Container(),
//           (completedJobs != null && completedJobs.length > 0)
//               ? ConstrainedBox(
//                   constraints: BoxConstraints(
//                       maxHeight: MediaQuery.of(context).size.height * 0.7,
//                       minHeight: MediaQuery.of(context).size.height * 0.2),
//                   child: Container(
//                       child: Scrollbar(
//                     child: ListView.builder(
//                       shrinkWrap: true,
//                       controller: controller,
//                       itemCount: Helpers.completedJobs.length,
//                       itemBuilder: (BuildContext context, int index) {
//                         return GestureDetector(
//                           onTap: () async {
//                             Helpers.selectedJobIndex = index;
//                             Job? job = await Repositories.fetchJobDetails(
//                                 jobId: Helpers.completedJobs[index].id);
//                             if (job != null) {
//                               Helpers.selectedJob = job;
//                               Navigator.pushNamed(context, 'jobDetails',
//                                       arguments: Helpers.selectedJob)
//                                   .then((value) async {
//                                 await _fetchJobHistories(true);
//                               });
//                             }
//                           },
//                           child: JobItem(
//                               key: ValueKey(index),
//                               width: MediaQuery.of(context).size.width,
//                               job: Helpers.completedJobs[index],
//                               index: index),
//                         );
//                       },
//                     ),
//                   )))
//               : new Container(),
//           (Helpers.completedJobs != null && Helpers.completedJobs.length > 0)
//               ? SizedBox(
//                   height: 60,
//                 )
//               : new Container()
//         ]),
//       ),
//     );
//   }

//   _renderError() {
//     return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
//       // SizedBox(height: 10),
//       SizedBox(height: 20),
//     ]);
//   }

//   Future<bool> _onWillPop() async {
//     // Navigator.pop(context);
//     return true;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return RefreshIndicator(
//         key: _refreshKey,
//         onRefresh: () async {
//           await this._fetchJobHistories(true);
//         },
//         child: Scaffold(
//           key: _scaffoldKey,
//           //resizeToAvoidBottomInset: false,
//           body: CustomPaint(
//               child: SingleChildScrollView(
//                   physics: AlwaysScrollableScrollPhysics(),
//                   child: Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 10, vertical: 10),
//                       decoration: new BoxDecoration(
//                           color: Colors.white.withOpacity(0.0)),
//                       child: Column(
//                           mainAxisAlignment: MainAxisAlignment.start,
//                           children: [
//                             errorMsg != "" ? _renderError() : Container(),
//                             _renderForm(),

//                             //Expanded(child: _renderBottom()),
//                             //version != "" ? _renderVersion() : Container()
//                           ])))),
//         ));
//   }
// }

// class JobItem extends StatelessWidget {
//   const JobItem(
//       {Key? key, required this.width, required this.job, required this.index})
//       : super(key: key);

//   final double width;
//   final Job job;
//   final int index;

//   Color getColor() {
//     if (job.status == "IN PROGRESS" || job.status == "PENDING REPAIR") {
//       return Colors.red;
//     } else {
//       return Colors.green;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//         key: ValueKey(this.key),
//         child: Container(
//           width: double.infinity,
//           margin: EdgeInsets.only(bottom: 10),
//           decoration: BoxDecoration(
//             border: Border.all(width: 0.1),
//             color: getColor(),
//             boxShadow: [
//               BoxShadow(
//                   blurRadius: 5,
//                   color: Colors.grey[200]!,
//                   offset: Offset(0, 10)),
//             ],
//             borderRadius: BorderRadius.circular(7.5),
//           ),
//           child: Padding(
//             padding: EdgeInsets.fromLTRB(15, 0, 0, 0),
//             child: Container(
//               color: Colors.white,
//               child: Column(
//                 children: [
//                   SizedBox(
//                     height: 15,
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Expanded(
//                         flex: 2,
//                         child: Container(
//                           child: Padding(
//                             padding: EdgeInsets.fromLTRB(20.0, 0, 0, 0),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 RichText(
//                                   text: TextSpan(
//                                     style: const TextStyle(
//                                       fontSize: 20.0,
//                                       color: Colors.blue,
//                                     ),
//                                     children: <TextSpan>[
//                                       TextSpan(
//                                           text: job != null
//                                               ? '# ${job.refNo}'.toString()
//                                               : '#-',
//                                           style: const TextStyle(
//                                               fontWeight: FontWeight.bold)),
//                                     ],
//                                   ),
//                                 ),
//                                 SizedBox(
//                                   height: 10,
//                                 ),
//                                 Row(
//                                   children: [
//                                     RichText(
//                                       text: TextSpan(
//                                         // Note: Styles for TextSpans must be explicitly defined.
//                                         // Child text spans will inherit styles from parent
//                                         style: const TextStyle(
//                                           fontSize: 14.0,
//                                           color: Colors.black87,
//                                         ),
//                                         children: <TextSpan>[
//                                           TextSpan(
//                                               text: job.date != null
//                                                   ? job.date
//                                                   : 'Date not found',
//                                               style: const TextStyle(
//                                                   fontWeight: FontWeight.bold)),
//                                         ],
//                                       ),
//                                     ),
//                                     RichText(
//                                       text: TextSpan(
//                                         // Note: Styles for TextSpans must be explicitly defined.
//                                         // Child text spans will inherit styles from parent
//                                         style: const TextStyle(
//                                           fontSize: 14.0,
//                                           color: Colors.red,
//                                         ),
//                                         children: <TextSpan>[
//                                           TextSpan(
//                                               text: job.time != null
//                                                   ? job.time
//                                                   : 'time not found',
//                                               style: const TextStyle(
//                                                   fontWeight: FontWeight.bold)),
//                                         ],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 SizedBox(
//                                   height: 5,
//                                 ),
//                                 RichText(
//                                   text: TextSpan(
//                                     // Note: Styles for TextSpans must be explicitly defined.
//                                     // Child text spans will inherit styles from parent
//                                     style: const TextStyle(
//                                       fontSize: 14.0,
//                                       color: Colors.black45,
//                                     ),
//                                     children: <TextSpan>[
//                                       TextSpan(
//                                           text: job != null
//                                               ? job.address
//                                                   .toString()
//                                                   .replaceAll("\n", " ")
//                                               : '',
//                                           style: const TextStyle(
//                                               fontWeight: FontWeight.bold)),
//                                     ],
//                                   ),
//                                 ),
//                                 SizedBox(
//                                   height: 25,
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                       Expanded(
//                           flex: 2,
//                           child: Container(
//                               width: width,
//                               child: Padding(
//                                   padding:
//                                       EdgeInsets.fromLTRB(20.0, 0, 0, 40.0),
//                                   child: Column(
//                                     children: [
//                                       RichText(
//                                         textAlign: TextAlign.center,
//                                         text: TextSpan(
//                                           // Note: Styles for TextSpans must be explicitly defined.
//                                           // Child text spans will inherit styles from parent
//                                           style: const TextStyle(
//                                             fontSize: 16.0,
//                                             color: Colors.black54,
//                                           ),
//                                           children: <TextSpan>[
//                                             TextSpan(
//                                                 text: job != null
//                                                     ? '${job.customerName} (${job.customerContactNo})'
//                                                     : 'Esther Howard (+65 9572 0181)',
//                                                 style: const TextStyle(
//                                                     fontWeight:
//                                                         FontWeight.bold)),
//                                           ],
//                                         ),
//                                       ),
//                                       SizedBox(
//                                         height: 5,
//                                       ),
//                                       RichText(
//                                         textAlign: TextAlign.center,
//                                         text: TextSpan(
//                                           // Note: Styles for TextSpans must be explicitly defined.
//                                           // Child text spans will inherit styles from parent
//                                           style: const TextStyle(
//                                             fontSize: 14.0,
//                                             color: Colors.black45,
//                                           ),
//                                           children: <TextSpan>[
//                                             TextSpan(
//                                                 text: job != null
//                                                     ? job.productDescription
//                                                     : 'Disney x Mayer 3L Air Fryer',
//                                                 style: const TextStyle(
//                                                     fontWeight:
//                                                         FontWeight.bold)),
//                                           ],
//                                         ),
//                                       ),
//                                       RichText(
//                                         textAlign: TextAlign.center,
//                                         text: TextSpan(
//                                           // Note: Styles for TextSpans must be explicitly defined.
//                                           // Child text spans will inherit styles from parent
//                                           style: const TextStyle(
//                                             fontSize: 14.0,
//                                             color: Colors.black45,
//                                           ),
//                                           children: <TextSpan>[
//                                             TextSpan(
//                                                 text: job != null
//                                                     ? job.productCode
//                                                     : '',
//                                                 style: const TextStyle(
//                                                     fontWeight:
//                                                         FontWeight.bold)),
//                                           ],
//                                         ),
//                                       ),
//                                     ],
//                                   )))),
//                       Expanded(
//                           flex: 1,
//                           child: Container(
//                               child: Column(
//                             children: [
//                               Padding(
//                                 padding:
//                                     EdgeInsets.fromLTRB(50.0, 0.0, 0, 80.0),
//                                 child: Row(
//                                   children: [
//                                     this.job.address != ""
//                                         ? GestureDetector(
//                                             onTap: () async {
//                                               var address = this
//                                                   .job
//                                                   .address
//                                                   ?.replaceAll("\n", "");
//                                               launch(
//                                                   "https://www.google.com/maps/search/?api=1&query=$address");
//                                             },
//                                             child: Icon(
//                                               // <-- Icon
//                                               Icons.location_pin,
//                                               color: Colors.black54,
//                                               size: 25.0,
//                                             ),
//                                           )
//                                         : new Container(),
//                                     SizedBox(
//                                       width: 10,
//                                     ),
//                                     Icon(
//                                       // <-- Icon
//                                       Icons.navigate_next_outlined,
//                                       color: Colors.black54,
//                                       size: 25.0,
//                                     ),
//                                   ],
//                                 ),
//                               )
//                             ],
//                           ))),
//                     ],
//                   ),
//                   Padding(
//                     padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
//                     child: Container(
//                       alignment: Alignment.centerLeft,
//                       child: ReadMoreText(
//                         job != null
//                             ? job.problem
//                                 .toString()
//                                 .toLowerCase()
//                                 .replaceAll("\n", " ")
//                             : '-',
//                         trimLines: 2,
//                         colorClickableText: Colors.black54,
//                         trimMode: TrimMode.Line,
//                         style: const TextStyle(
//                           fontSize: 14.0,
//                           color: Colors.black54,
//                         ),
//                         trimCollapsedText: 'Show more',
//                         trimExpandedText: 'Show less',
//                         moreStyle: TextStyle(
//                             fontSize: 14, fontWeight: FontWeight.bold),
//                       ),
//                       // RichText(
//                       //   text: TextSpan(
//                       //     // Note: Styles for TextSpans must be explicitly defined.
//                       //     // Child text spans will inherit styles from parent
//                       //     style: const TextStyle(
//                       //       fontSize: 14.0,
//                       //       color: Colors.black54,
//                       //     ),
//                       //     children: <TextSpan>[
//                       //       TextSpan(
//                       //           text: job != null
//                       //               ? job.problem
//                       //                   .toString()
//                       //                   .toLowerCase()
//                       //                   .replaceAll("\n", " ")
//                       //               : 'Changed order missed by pro',
//                       //           style: const TextStyle(
//                       //               fontWeight: FontWeight.bold)),
//                       //     ],
//                       //   ),
//                       // ),
//                     ),
//                   ),
//                   SizedBox(
//                     height: 10,
//                   ),
//                   Padding(
//                     padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
//                     child: Row(
//                       children: [
//                         Icon(
//                           // <-- Icon
//                           Icons.chat_outlined,
//                           color: Colors.black54,
//                           size: 19.0,
//                         ),
//                         SizedBox(
//                           width: 5,
//                         ),
//                         Container(
//                           width: 500,
//                           child: ReadMoreText(
//                             job.comment != null
//                                 ? job.comment.toString().toLowerCase()
//                                 : '-',
//                             trimLines: 2,
//                             colorClickableText: Colors.black54,
//                             trimMode: TrimMode.Line,
//                             style: const TextStyle(
//                               fontSize: 14.0,
//                               color: Colors.red,
//                             ),
//                             trimCollapsedText: 'Show more',
//                             trimExpandedText: 'Show less',
//                             moreStyle: TextStyle(
//                                 fontSize: 14, fontWeight: FontWeight.bold),
//                           ),
//                           // RichText(
//                           //   maxLines: 5,
//                           //   text: TextSpan(
//                           //     // Note: Styles for TextSpans must be explicitly defined.
//                           //     // Child text spans will inherit styles from parent
//                           //     style: const TextStyle(
//                           //       fontSize: 14.0,
//                           //       color: Colors.red,
//                           //     ),
//                           //     children: <TextSpan>[
//                           //       TextSpan(
//                           //           text: job.comment != null
//                           //               ? job.comment.toString().toLowerCase()
//                           //               : '-',
//                           //           style: const TextStyle(
//                           //               fontWeight: FontWeight.bold)),
//                           //     ],
//                           //   ),
//                           // ),
//                         )
//                       ],
//                     ),
//                   ),
//                   SizedBox(
//                     height: 15,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ));
//   }
// }
