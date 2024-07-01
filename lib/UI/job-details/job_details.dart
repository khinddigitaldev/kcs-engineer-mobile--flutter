import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:after_layout/after_layout.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:expandable_bottom_sheet/expandable_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kcs_engineer/UI/job-details/components/add_misc_items_popup.dart';
import 'package:kcs_engineer/UI/job-details/components/add_part_item_state.dart';
import 'package:kcs_engineer/UI/job-details/components/comment_item.dart';
import 'package:kcs_engineer/UI/job-details/components/job_item.dart';
import 'package:kcs_engineer/UI/job-details/components/misc_item.dart';
import 'package:kcs_engineer/UI/job-details/components/multi_image_upload_dialog.dart';
import 'package:kcs_engineer/UI/job-details/components/picklist_item.dart';
import 'package:kcs_engineer/UI/job-details/components/stepper_alert_dialog.dart';
import 'package:kcs_engineer/UI/job_details.dart';
import 'package:kcs_engineer/model/user/bag.dart';
import 'package:kcs_engineer/model/job/checklistAttachment.dart';
import 'package:kcs_engineer/model/job/comment.dart';
import 'package:kcs_engineer/model/job/job.dart';
import 'package:kcs_engineer/model/payment/pickup_charges.dart';
import 'package:kcs_engineer/model/job/general/problem.dart';
import 'package:kcs_engineer/model/payment/rcpCost.dart';
import 'package:kcs_engineer/model/job/general/reason.dart';
import 'package:kcs_engineer/model/job/general/solution.dart';
import 'package:kcs_engineer/model/spareparts/sparepart.dart';
import 'package:kcs_engineer/model/job/general/transportCharge.dart';
import 'package:kcs_engineer/util/components/add_items_bag.dart';
import 'package:kcs_engineer/util/helpers.dart';
import 'package:kcs_engineer/util/key.dart';
import 'package:kcs_engineer/util/repositories.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';

class JobDetails extends StatefulWidget {
  String? id;
  JobDetails({this.id});

  @override
  _JobDetailsState createState() => _JobDetailsState();
}

class _JobDetailsState extends State<JobDetails>
    with WidgetsBindingObserver, AfterLayoutMixin, TickerProviderStateMixin {
  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  GlobalKey<ScaffoldState> _imgScaffoldKey = new GlobalKey<ScaffoldState>();

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController serialNoController = new TextEditingController();
  TextEditingController remarksController = new TextEditingController();
  TextEditingController adminRemarksController = new TextEditingController();
  TextEditingController commentTextController = new TextEditingController();
  TextEditingController engineerRemarksController = new TextEditingController();

  bool isLoading = false;
  bool isSerialNoEditable = false;
  bool isRemarksEditable = false;
  bool isAdminRemarksEditable = false;
  bool isEngineerRemarksEditable = false;

  bool showPassword = false;
  String errorMsg = "";
  String version = "";
  bool isChargeableTransportCharges = false;
  bool isChargeablePickupCharges = false;
  bool isChargeableSolutionCharges = false;
  bool isChargeableMiscellaneousCharges = false;

  Job? selectedJob;
  late FocusNode serialNoFocusNode;
  late FocusNode remarksFocusNode;
  late FocusNode adminRemarksFocusNode;
  late FocusNode engineerRemarksFocusNode;

  List<Solution> solutions = [];
  List<Problem> problems = [];

  List<Comment> comments = [];
  List<ChecklistAttachment> checklistAttachments = [];
  List<String> solutionLabels = [];
  List<String> problemLabels = [];

  XFile? tempImage;
  bool nextImagePressed = false;
  bool continuePressed = false;
  int? currentlyEditingCommentIndex = null;
  var _refreshKey = GlobalKey<RefreshIndicatorState>();
  List<File> images = [];
  final storage = new FlutterSecureStorage();
  String? token;
  String jobId = "";
  int imageCount = 3;
  String? loggedInUserId;
  List<String?> imageUrls = [];
  ExpansionStatus _expansionStatus = ExpansionStatus.contracted;
  GlobalKey<ExpandableBottomSheetState> key = new GlobalKey();
  bool isExpanded = false;
  bool isExpandedTotal = false;

  bool isPartsEditable = false;
  bool isMiscItemsEditable = false;
  bool isPickListPartsEditable = false;

  List<FocusNode> commentFocusNodes = [];
  List<TextEditingController> commentTextEditingControllers = [];

  Job? selectedJobDetails;

  List<Reason>? cancellationReasons = [];
  List<Reason>? rejectReasons = [];

  List<Reason>? KIVReasons = [];
  int? selectedKIVReason = null;
  int? selectedCancellationReason = null;
  int? selectedRejectReason = null;

  bool isErrorCancellationReason = false;
  bool isErrorRejectReason = false;
  bool isErrorKIVReason = false;

  bool isErrorProblemSelection = false;
  bool isErrorEstimatedSolutionSelection = false;
  bool isErrorActualSolutionSelection = false;
  bool isErrorSerialNo = false;
  bool isPendingItemsInPickList = false;

  bool isPreviousJobsSelected = false;
  List<Job> jobHistory = [];
  BagMetaData? userBag;
  RCPCost? rcpCost;

  bool isNewTransportCharge = false;
  bool isNewPickUpCharge = false;

  List<PickupCharge>? allPickupCharges = null;
  List<TransportCharge>? allTransportCharges = null;

  bool isTransportationChargesAvailable = true;
  List<String> priority = ["bag", "warehouse", "picklist"];

  int stepperCounter = 1;

  TabController? tabController;
  bool isDiscountApplied = false;
  bool isRCPValid = false;
  ScrollController _scrollController = ScrollController();
  Map<int, int> pickListIndexToQuantityTemp = {};

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) async {
    jobId = widget.id ?? "";
    await fetchJobDetails();
    await Future.wait([
      fetchRCPCost(),
      fetchTransportCharges(),
      fetchPickUpCharges(),
      fetchCancellationReasons(),
      fetchRejecReasons(),
      fetchKIVReasons(),
      fetchJobHistory(),
      fetchChecklistAttachments(),
      fetchComments(),
      fetchProblems(),
      fetchSolutionsByProduct()
    ]);

    if (solutionLabels.length == 0 && selectedJob != null) {}

    loggedInUserId = await storage.read(key: USERID);

    if (selectedJob != null && mounted) {
      setState(() {
        serialNoController.text = selectedJob?.serialNo ?? "-";
        remarksController.text = selectedJob?.remarks ?? "";
        adminRemarksController.text = selectedJob?.adminRemarks ?? "";
        engineerRemarksController.text = selectedJob?.engineerRemarks ?? "";
      });
    }
  }

  Future<void> fetchCancellationReasons() async {
    isLoading = true;
    var reasons = await Repositories.fetchCancellationReasons();
    isLoading = false;
    if (mounted) {
      setState(() {
        cancellationReasons = reasons;
      });
    }
  }

  Future<void> fetchRejecReasons() async {
    isLoading = true;
    var reasons = await Repositories.fetchRejectReasons();
    isLoading = false;
    if (mounted) {
      setState(() {
        rejectReasons = reasons;
      });
    }
  }

  Future<void> fetchKIVReasons() async {
    isLoading = true;
    var reasons = await Repositories.fetchKIVReasons();
    isLoading = false;

    if (mounted) {
      setState(() {
        KIVReasons = reasons;
      });
    }
  }

  Future<void> fetchTransportCharges() async {
    isLoading = true;
    var transportCharges =
        await Repositories.fetchTransportCharges(selectedJob?.productModelId);
    isLoading = false;
    if (mounted) {
      setState(() {
        allTransportCharges = transportCharges;
        isTransportationChargesAvailable = transportCharges.length > 0;
      });
    }
  }

  Future<void> fetchPickUpCharges() async {
    isLoading = true;
    var pickupCharges = await Repositories.fetchPickUpCharges();
    isLoading = false;
    if (mounted) {
      setState(() {
        allPickupCharges = pickupCharges;
      });
    }
  }

  bool checkActionsEnabled(String action) {
    List<String> res = [];

    if (!(selectedJob?.isMainEngineer ?? true)) {
      return res.contains(action);
    }

    switch (selectedJob?.serviceJobStatus?.toLowerCase()) {
      case "pending job start":
        res.addAll(["cancel", "reject", "kiv", "start"]);
        break;
      case "repairing":
        res.addAll(["kiv", "complete"]);
        break;
      case "kiv":
        res.addAll(["kiv", "start"]);
        break;
      case "cancelled":
        res = [];
        break;
      case "completed":
        res = ["payment"];
        break;
      case "closed":
        res = [];
        break;
      case "pending delivery":
        res = [];
        break;
    }

    return res.contains(action);
  }

  _renderStepper() {
    setState(() {
      stepperCounter = 0;
    });

    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return StepperAlertDialog(
                content: getStepperContent(),
                stepperCounter: stepperCounter,
                isStepperCountChanged: (isIncremented) async {
                  var counter = stepperCounter;

                  if (isIncremented) {
                    counter = counter + 1;
                  } else {
                    counter = counter - 1;
                  }
                  setState(() {
                    stepperCounter = counter;
                  });
                },
                isConfirmPressed: () async {
                  setState(() {
                    images = [];
                    continuePressed = false;
                    nextImagePressed = false;
                  });
                  Navigator.pop(context);
                  await pickImage(false, true, false, false, false, false)
                      .then((value) {});
                });
          });
        });

    // showDialog(
    //   context: context,
    //   builder: (context) {
    //     return
    //   },
    // );
  }

  Widget getStepperContent() {
    switch (stepperCounter) {
      case 0:
        return _renderProblems(true);
      case 1:
        return _renderSolutions(true);
      case 2:
        return _renderPartsList(true);
      case 3:
        return _renderMiscItems(true);
      case 4:
        return _renderTransportCharges(true);
      case 5:
        return _renderPickupCharges(true);
      case 6:
        return _renderCost(true);
      default:
        return Container();
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    super.initState();

    serialNoFocusNode = FocusNode();
    remarksFocusNode = FocusNode();
    adminRemarksFocusNode = FocusNode();
    engineerRemarksFocusNode = FocusNode();
    _loadVersion();
    //_loadToken();
    //_checkPermisions();
  }

  Future<void> fetchChecklistAttachments() async {
    var res = await Repositories.fetchChecklistAttachment(jobId);

    if (mounted) {
      setState(() {
        checklistAttachments = res;
      });
    }
  }

  removeItemsBasedOnPriority(List<SparePart>? updatedArray) async {
    List<SparePart> itemsToRemove = [];
    List<SparePart> finalArr = [];
    List<SparePart>? sparePartExisting = [];
    int? quantityToRemove;
    bool? isItemRemoved = false;

    //completely removed
    selectedJob?.aggregatedSpareparts?.forEach((element) {
      var abc =
          (updatedArray?.map((e) => e.id == element.id).toList().length ?? 0);

      print(abc);

      int indexIfExists =
          updatedArray?.indexWhere((e) => e.id == element.id) ?? 0;

      // if((updatedArray?.length ?? 0) < (selectedJob?.aggregatedSpareparts?.length ?? 0)){
      //   isItemRemoved  = true;
      // }

      if (indexIfExists == -1) {
        var obj = SparePart.cloneInstance(element);
        obj.quantity = 0 - (obj.quantity ?? 0);
        quantityToRemove = obj.quantity;

        priority.forEach((priority) {
          if (priority == "bag") {
            sparePartExisting = selectedJob?.currentJobSparepartsfromBag
                ?.where((currentSparePart) => currentSparePart.id == obj.id)
                .toList();
          } else if (priority == "warehouse") {
            sparePartExisting = selectedJob?.currentJobSparepartsfromWarehouse
                ?.where((currentSparePart) => currentSparePart.id == obj.id)
                .toList();
          } else if (priority == "picklist") {
            sparePartExisting = selectedJob?.currentJobSparepartsfromPickList
                ?.where((currentSparePart) => currentSparePart.id == obj.id)
                .toList();
          }

          if ((sparePartExisting?.length ?? 0) != 0) {
            SparePart newClone = SparePart.cloneInstance(obj);
            newClone.quantity = (quantityToRemove ?? 0);
            newClone.from = priority;

            finalArr.add(newClone);
          }

          if (quantityToRemove == 0) {
            return;
          }
        });
      } else {
        //reduced quantity
        if (updatedArray?[indexIfExists].quantity != element?.quantity) {
          var obj = updatedArray?.firstWhere((e) => element.id == e.id);

          if (obj != null && obj.quantity != element.quantity) {
            quantityToRemove = (element.quantity ?? 0) - (obj.quantity ?? 0);

            priority.forEach((priority) {
              switch (priority) {
                case "bag":
                  sparePartExisting = selectedJob?.currentJobSparepartsfromBag
                      ?.where(
                          (currentSparePart) => currentSparePart.id == obj.id)
                      .toList();
                  break;
                case "warehouse":
                  sparePartExisting = selectedJob
                      ?.currentJobSparepartsfromWarehouse
                      ?.where(
                          (currentSparePart) => currentSparePart.id == obj.id)
                      .toList();
                  break;
                case "picklist":
                  sparePartExisting = selectedJob
                      ?.currentJobSparepartsfromPickList
                      ?.where(
                          (currentSparePart) => currentSparePart.id == obj.id)
                      .toList();
                  break;
              }

              if ((sparePartExisting?.length ?? 0) != 0) {
                int currentQuantity = sparePartExisting?[0].quantity ?? 0;
                SparePart newClone = SparePart.cloneInstance(obj);
                newClone.quantity = 0 - (quantityToRemove ?? 0);
                newClone.from = priority;

                quantityToRemove =
                    (quantityToRemove ?? 0) + (newClone.quantity ?? 0);
                finalArr.add(newClone);
              }

              if (quantityToRemove == 0) {
                return;
              }
            });
          }
        }
      }
    });

    var res = await Repositories.addSparePartsToJob(jobId, finalArr);

    await refreshJobDetails();
  }

  Future<void> fetchComments() async {
    var res = await Repositories.fetchOrderComments(jobId);

    if (mounted) {
      setState(() {
        comments = res;

        commentFocusNodes = [];
        commentTextEditingControllers = [];
        commentFocusNodes.addAll(res.map((e) => FocusNode()));
        commentTextEditingControllers
            .addAll(res.map((e) => new TextEditingController()));
      });
    }
  }

  Future<void> fetchSolutionsByProduct() async {
    solutions = await Repositories.fetchSolutions(
        selectedJob?.productModelId.toString() ?? "",
        selectedJob?.serviceTypeId.toString() ?? "");

    solutions.forEach((element) {
      solutionLabels.add(element.solution ?? "");
    });

    if (mounted) {
      solutionLabels..sort();
      setState(() {
        solutionLabels = solutionLabels;
      });
    }
  }

  Future<void> fetchProblems() async {
    problems = await Repositories.fetchProblems(
        selectedJob?.productGroupdId.toString() ?? "");

    problems.forEach((element) {
      problemLabels.add(element.problem ?? "");
    });

    if (mounted) {
      problemLabels..sort();

      setState(() {
        problemLabels = problemLabels;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    serialNoFocusNode.dispose();
    remarksFocusNode.dispose();
    adminRemarksFocusNode.dispose();
    engineerRemarksFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      //
      // this.refreshJobDetails();
      //
    }
  }

  _loadVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String pkgVersion = packageInfo.version;

    setState(() {
      version = pkgVersion;
    });
  }

  // void fetchCurrentPrice() async {
  //   problems = await Repositories.fetchProblems();

  //   problems.forEach((element) {
  //     problemLabels.add(element.problem ?? "");
  //   });

  //   if (mounted) {
  //     setState(() {
  //       problemLabels = problemLabels;
  //     });
  //   }
  // }

  void _handleSignIn() async {}

  Widget buildProductInfo() {
    final fullWidth = MediaQuery.of(context).size.width;
    final rowWidth = fullWidth * 0.77; //90%

    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Container(
            alignment: Alignment.centerLeft,
            width: rowWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Container(
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: Row(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              RichText(
                                text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      color: Colors.black54,
                                    ),
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: 'SERIAL NO',
                                      ),
                                    ]),
                              ),
                              Container(
                                width: 120,
                                height: 65,
                                child: TextFormField(
                                  keyboardType: TextInputType.multiline,
                                  minLines: 1,
                                  maxLines: 2,
                                  onChanged: (str) {
                                    setState(() {
                                      isSerialNoEditable = true;
                                      isErrorSerialNo = false;
                                    });
                                  },
                                  enabled: isSerialNoEditable,
                                  controller: serialNoController,
                                  //     readOnly: isSerialNoEditable,
                                  focusNode: serialNoFocusNode,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                  style: TextStyle(
                                    fontSize: 15.0,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              isErrorSerialNo
                                  ? SizedBox(
                                      width: MediaQuery.of(context).size.width *
                                          0.25,
                                      child: Row(children: [
                                        Container(
                                            child: Row(children: [
                                          Icon(
                                            Icons.warning,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          SizedBox(width: 10),
                                          Container(
                                            child: RichText(
                                              text: TextSpan(
                                                  style: const TextStyle(
                                                    fontSize: 14.0,
                                                    color: Colors.red,
                                                  ),
                                                  children: <TextSpan>[
                                                    TextSpan(
                                                      text:
                                                          "Please fill in the serial number before proceeding.",
                                                    ),
                                                  ]),
                                            ),
                                          ),
                                        ]))
                                      ]))
                                  : new Container()
                            ],
                          ),
                          const SizedBox(
                            width: 30,
                          ),
                          Helpers.checkIfEditableByJobStatus(selectedJob,
                                  (selectedJob?.isMainEngineer ?? true))
                              ? GestureDetector(
                                  onTap: () async {
                                    if (isSerialNoEditable) {
                                      var res =
                                          await Repositories.updateSerialNo(
                                              selectedJob!.serviceRequestid ??
                                                  "0",
                                              serialNoController.text
                                                  .toString());

                                      setState(() {
                                        isSerialNoEditable = false;
                                      });
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      await refreshJobDetails();
                                    } else {
                                      setState(() {
                                        isSerialNoEditable = true;
                                      });
                                      Future.delayed(Duration.zero, () {
                                        serialNoFocusNode.requestFocus();
                                      });
                                    }
                                  },
                                  child: isSerialNoEditable
                                      ? Icon(
                                          // <-- Icon
                                          Icons.check,
                                          color: Colors.black54,
                                          size: 25.0,
                                        )
                                      : Icon(
                                          // <-- Icon
                                          Icons.edit,
                                          color: Colors.black54,
                                          size: 25.0,
                                        ))
                              : new Container()
                        ],
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.28,
                      child: Row(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const <Widget>[
                              Icon(
                                // <-- Icon
                                Icons.person,
                                color: Colors.black54,
                                size: 25.0,
                              ),
                            ],
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * .22,
                            child: RichText(
                              text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 15.0,
                                    color: Colors.black54,
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: selectedJob?.customerName,
                                    ),
                                  ]),
                            ),
                          )
                        ],
                      ),
                    ),
                    Spacer(),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.28,
                      child: RichText(
                        text: TextSpan(
                            style: TextStyle(
                              fontSize: 15.0,
                              color: Colors.black54,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text:
                                    '${selectedJob?.serviceAddressStreet},${selectedJob?.serviceAddressCity},${selectedJob?.serviceAddressPostcode},${selectedJob?.serviceAddressState}, ',
                              ),
                            ]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      width: MediaQuery.of(context).size.width * 0.25,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.25,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    RichText(
                                      text: const TextSpan(
                                          style: TextStyle(
                                            fontSize: 15.0,
                                            color: Colors.black54,
                                          ),
                                          children: <TextSpan>[
                                            const TextSpan(
                                              text: 'PRODUCT CODE',
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
                                              text: selectedJob?.productCode,
                                            ),
                                          ]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: selectedJob != null
                          ? Row(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const Icon(
                                      // <-- Icon
                                      Icons.mail_outline,
                                      color: Colors.black54,
                                      size: 25.0,
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                RichText(
                                  text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.black54,
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: selectedJob?.customerEmail,
                                        ),
                                      ]),
                                ),
                              ],
                            )
                          : new Container(),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: Container(
                          width: MediaQuery.of(context).size.width * 0.15,
                          child: new Container()),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Container(
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: Row(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              RichText(
                                text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      color: Colors.black54,
                                    ),
                                    children: <TextSpan>[
                                      const TextSpan(
                                        text: 'PRODUCT NAME',
                                      ),
                                    ]),
                              ),
                              Container(
                                alignment: Alignment.centerLeft,
                                width: 130,
                                child: RichText(
                                  text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 15.0,
                                        color: Colors.black87,
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: selectedJob?.productDescription,
                                        ),
                                      ]),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: Row(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Icon(
                                // <-- Icon
                                Icons.phone,
                                color: Colors.black54,
                                size: 25.0,
                              ),
                            ],
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          RichText(
                            text: TextSpan(
                                style: TextStyle(
                                  fontSize: 15.0,
                                  color: Colors.black54,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: '+${selectedJob?.customerTelephone}',
                                  ),
                                ]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                        width: MediaQuery.of(context).size.width * 0.25,
                        child: new Container()),
                  ],
                ),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Container(
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: Row(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              RichText(
                                text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 15.0,
                                      color: Colors.black54,
                                    ),
                                    children: <TextSpan>[
                                      const TextSpan(
                                        text: 'WARRANTY INFO',
                                      ),
                                    ]),
                              ),
                              Row(
                                children: [
                                  selectedJob != null
                                      ? (selectedJob!.isUnderWarranty ?? false
                                          ? Icon(
                                              // <-- Icon
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 25.0,
                                            )
                                          : Icon(
                                              // <-- Icon
                                              Icons.cancel,
                                              color: Colors.red,
                                              size: 25.0,
                                            ))
                                      : new Container(),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  (selectedJob?.isUnderWarranty ?? false)
                                      ? RichText(
                                          text: const TextSpan(
                                              style: TextStyle(
                                                fontSize: 15.0,
                                                color: Colors.black,
                                              ),
                                              children: <TextSpan>[
                                                TextSpan(
                                                  text: 'Under warranty',
                                                ),
                                              ]),
                                        )
                                      : RichText(
                                          text: const TextSpan(
                                              style: TextStyle(
                                                fontSize: 15.0,
                                                color: Colors.black,
                                              ),
                                              children: <TextSpan>[
                                                TextSpan(
                                                  text: 'Not under warranty',
                                                ),
                                              ]),
                                        )
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.32,
                      child: selectedJob?.warrantyAdditionalInfo != null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                RichText(
                                  text: const TextSpan(
                                      style: TextStyle(
                                        fontSize: 15.0,
                                        color: Colors.black54,
                                      ),
                                      children: <TextSpan>[
                                        const TextSpan(
                                          text: 'WARRANTY ADDITIONAL INFO',
                                        ),
                                      ]),
                                ),
                                RichText(
                                  text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 15.0,
                                        color: Colors.black,
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text:
                                              '${selectedJob?.warrantyAdditionalInfo}',
                                        ),
                                      ]),
                                )
                              ],
                            )
                          : new Container(),
                    ),
                    Container(
                        width: MediaQuery.of(context).size.width * 0.2,
                        child: new Container()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool validateIfEditedValuesAreSaved() {
    if (isRemarksEditable ||
        isAdminRemarksEditable ||
        isSerialNoEditable ||
        isPartsEditable) {
      var editOngoingFields = '';

      int count = 0;

      if (isRemarksEditable) {
        editOngoingFields = "'Remarks'";
        count++;
      }

      if (isAdminRemarksEditable) {
        editOngoingFields = "'Admin Remarks'";
        count++;
      }

      if (isSerialNoEditable) {
        if (editOngoingFields != "") {
          editOngoingFields = editOngoingFields + ",'Serial number'";
        } else {
          editOngoingFields = "'Serial number'";
        }
        count++;
      }

      if (isPartsEditable) {
        if (editOngoingFields != "") {
          editOngoingFields = editOngoingFields + ",'Parts'";
        } else {
          editOngoingFields = "'Parts'";
        }
        count++;
      }

      if (editOngoingFields != "") {
        Helpers.showAlert(context,
            title: "Forgot to Save ?",
            desc:
                "Do you want to save your changes? If you do not save the changes, they will be lost.",
            hasAction: true,
            okTitle: "Save",
            noTitle: "Discard",
            maxWidth: 600.0,
            customImage: Image(
                image: AssetImage('assets/images/info.png'),
                width: 50,
                height: 50),
            onCancelPressed: () async {
              setState(() {
                isPartsEditable = false;
                isRemarksEditable = false;
                isAdminRemarksEditable = false;
                isSerialNoEditable = false;

                FocusManager.instance.primaryFocus?.unfocus();
                FocusScope.of(context).unfocus();
              });

              await refreshJobDetails();
            },
            hasCancel: true,
            onPressed: () async {
              if (isRemarksEditable) {
                var res = await Repositories.updateRemarks(
                    selectedJob!.serviceRequestid ?? "0",
                    remarksController.text.toString());

                setState(() {
                  isRemarksEditable = false;
                });
              }

              if (isAdminRemarksEditable) {
                var res = await Repositories.updateAdminRemarks(
                    selectedJob!.serviceRequestid ?? "0",
                    remarksController.text.toString());

                setState(() {
                  isAdminRemarksEditable = false;
                });
              }

              if (isEngineerRemarksEditable) {
                var res = await Repositories.updateEngineerRemarks(
                    selectedJob!.serviceRequestid ?? "0",
                    engineerRemarksController.text.toString());

                setState(() {
                  isEngineerRemarksEditable = false;
                });
              }

              if (isSerialNoEditable) {
                var res = await Repositories.updateSerialNo(
                    selectedJob!.serviceRequestid ?? "0",
                    serialNoController.text.toString());

                setState(() {
                  isSerialNoEditable = false;
                });
              }

              if (isPartsEditable) {
                var abc = Helpers.editableMiscItems;
                print("LALALAL");
              }

              await refreshJobDetails();

              setState(() {
                isPartsEditable = false;
                isRemarksEditable = false;
                isAdminRemarksEditable = false;
                isSerialNoEditable = false;

                FocusManager.instance.primaryFocus?.unfocus();
                //FocusScope.of(context).unfocus();
              });
            });
        return false;
      } else {
        return false;
      }
    } else {
      return true;
    }
  }

  Widget buildIssueInfo() {
    final fullWidth = MediaQuery.of(context).size.width;
    final rowWidth = fullWidth * 0.75; //90%
    final containerWidth =
        rowWidth / 3; //Could also use this to set the containers individually

    return Container(
      child: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Container(
              width: rowWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Container(
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: Row(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[],
                            ),
                          ],
                        ),
                      ),
                      Container(),
                    ],
                  ),
                  Row(children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          RichText(
                            text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 15.0,
                                  color: Colors.black54,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: 'PURCHASE DATE',
                                  ),
                                ]),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          RichText(
                            text: TextSpan(
                                style: TextStyle(
                                  fontSize: 15.0,
                                  color: Colors.black87,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: selectedJob?.purchaseDate ?? "-"

                                      // selectedJob != null
                                      //     ? selectedJob!.purchaseDate
                                      //         ?.split(' ')[0]
                                      //     : '-',
                                      ),
                                ]),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                      child: Container(
                        child: Row(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Icon(
                                  // <-- Icon
                                  Icons.payment_outlined,
                                  color: Colors.black54,
                                  size: 25.0,
                                ),
                              ],
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            RichText(
                              text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 15.0,
                                    color: Colors.black54,
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                        text: '${selectedJob?.paymentMethods}')
                                  ]),
                            ),
                          ],
                        ),
                      ),
                    )
                  ]),
                  SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        RichText(
                          text: const TextSpan(
                              style: TextStyle(
                                fontSize: 15.0,
                                color: Colors.black54,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: 'REPORTED PROBLEM',
                                ),
                              ]),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        RichText(
                          text: TextSpan(
                              style: TextStyle(
                                fontSize: 15.0,
                                color: Colors.black87,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text:
                                      '${selectedJob?.reportedProblemDescription ?? "-"}',
                                ),
                              ]),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        RichText(
                          text: const TextSpan(
                              style: TextStyle(
                                fontSize: 15.0,
                                color: Colors.black54,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: 'ACTUAL PROBLEM',
                                ),
                              ]),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        RichText(
                          text: TextSpan(
                              style: TextStyle(
                                fontSize: 15.0,
                                color: Colors.black87,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text:
                                      '${selectedJob?.actualProblemDescription ?? "-"}',
                                ),
                              ]),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(
                            height: 20,
                          ),
                          RichText(
                            text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 15.0,
                                  color: Colors.black54,
                                ),
                                children: <TextSpan>[
                                  const TextSpan(
                                    text: 'CUSTOMER REMARKS',
                                  ),
                                ]),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.4,
                            height: MediaQuery.of(context).size.height * 0.05,
                            child: SizedBox(
                              width: 100,
                              height: 40,
                              child: TextFormField(
                                textInputAction: TextInputAction.newline,
                                minLines: 1,
                                maxLines: 5,
                                enabled: false,
                                keyboardType: TextInputType.multiline,
                                onChanged: (str) {
                                  setState(() {
                                    isRemarksEditable = true;
                                  });
                                },
                                controller: remarksController,
                                focusNode: remarksFocusNode,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                ),
                                style: TextStyle(
                                  fontSize: 15.0,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          RichText(
                            text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 15.0,
                                  color: Colors.black54,
                                ),
                                children: <TextSpan>[
                                  const TextSpan(
                                    text: 'ADMIN REMARKS',
                                  ),
                                ]),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.4,
                            height: MediaQuery.of(context).size.height * 0.05,
                            child: SizedBox(
                              width: 100,
                              height: 40,
                              child: TextFormField(
                                enabled: false,
                                textInputAction: TextInputAction.newline,
                                minLines: 1,
                                maxLines: 5,
                                keyboardType: TextInputType.multiline,
                                onChanged: (str) {
                                  setState(() {
                                    isAdminRemarksEditable = true;
                                  });
                                },
                                controller: adminRemarksController,
                                focusNode: adminRemarksFocusNode,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                ),
                                style: TextStyle(
                                  fontSize: 15.0,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          RichText(
                            text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 15.0,
                                  color: Colors.black54,
                                ),
                                children: <TextSpan>[
                                  const TextSpan(
                                    text: 'ENGINEER REMARKS',
                                  ),
                                ]),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.4,
                            height: MediaQuery.of(context).size.height * 0.05,
                            child: SizedBox(
                              width: 100,
                              height: 40,
                              child: TextFormField(
                                enabled: isEngineerRemarksEditable,
                                textInputAction: TextInputAction.newline,
                                minLines: 1,
                                maxLines: 5,
                                keyboardType: TextInputType.multiline,
                                onChanged: (str) {
                                  setState(() {
                                    isEngineerRemarksEditable = true;
                                  });
                                },
                                controller: engineerRemarksController,
                                focusNode: engineerRemarksFocusNode,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                ),
                                style: TextStyle(
                                  fontSize: 15.0,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Helpers.checkIfEditableByJobStatus(selectedJob,
                              (selectedJob?.isMainEngineer ?? true))
                          ? GestureDetector(
                              onTap: () async {
                                if (isEngineerRemarksEditable) {
                                  var res =
                                      await Repositories.updateEngineerRemarks(
                                          selectedJob!.serviceRequestid ?? "0",
                                          engineerRemarksController.text
                                              .toString());

                                  setState(() {
                                    isEngineerRemarksEditable = false;
                                  });
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  await refreshJobDetails();
                                } else {
                                  setState(() {
                                    isEngineerRemarksEditable = true;
                                  });

                                  Future.delayed(Duration.zero, () {
                                    engineerRemarksFocusNode.requestFocus();
                                  });
                                }
                              },
                              child: isEngineerRemarksEditable
                                  ? Icon(
                                      // <-- Icon
                                      Icons.check,
                                      color: Colors.black54,
                                      size: 25.0,
                                    )
                                  : Icon(
                                      // <-- Icon
                                      Icons.edit,
                                      color: Colors.black54,
                                      size: 25.0,
                                    ))
                          : new Container()
                    ],
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderForm() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Form(
        key: _formKey,
        child: Column(children: [
          Container(
            child: Column(children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                      child: Container(
                    child: Padding(
                      padding: const EdgeInsets.all(0.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                RichText(
                                  text: const TextSpan(
                                      style: TextStyle(
                                        fontSize: 25.0,
                                        color: Colors.black,
                                      ),
                                      children: <TextSpan>[
                                        const TextSpan(
                                          text: 'Job',
                                        ),
                                      ]),
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.005,
                                ),
                                RichText(
                                  text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 25.0,
                                        color: Colors.blue,
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: '#' +
                                              (selectedJob?.serviceJobNo ?? ""),
                                        ),
                                      ]),
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.005,
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      // <-- Icon
                                      Icons.circle,
                                      color:
                                          Helpers.getForegroundColorByJobStatus(
                                              selectedJob?.serviceJobStatus ??
                                                  ""),

                                      size: 18.0,
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    RichText(
                                      text: TextSpan(
                                          style: TextStyle(
                                            fontSize: 15.0,
                                            color: Colors.black54,
                                          ),
                                          children: <TextSpan>[
                                            TextSpan(
                                              text:
                                                  selectedJob?.serviceJobStatus,
                                            ),
                                          ]),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.005,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF242A38),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Center(
                                      child: Text(
                                        selectedJob?.serviceType ?? "",
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
                                  width:
                                      MediaQuery.of(context).size.width * 0.005,
                                ),
                                imageUrls.length > 0
                                    ? Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.1,
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.03,
                                        child: Stack(
                                          children: List.generate(
                                              imageUrls.length, (index) {
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
                                                            imageUrls[index] ??
                                                                ""),
                                                  )),
                                            );
                                          }),
                                        ),
                                      )
                                    : new Container()

                                //Pending REPAIR
                              ]),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.005,
                          ),
                          RichText(
                            text: TextSpan(
                                style: TextStyle(
                                  fontSize: 15.0,
                                  color: Colors.black54,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text:
                                          '${selectedJob?.serviceDate} ${selectedJob?.serviceTime == null ? "" : selectedJob?.serviceTime}'),
                                ]),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  )),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      checkActionsEnabled("cancel")
                          ? ElevatedButton(
                              child: Padding(
                                  padding: const EdgeInsets.all(0.0),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        // <-- Icon
                                        Icons.cancel,
                                        color: Colors.white,
                                        size: 18.0,
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      const Text(
                                        'Cancel Job',
                                        style: TextStyle(
                                            fontSize: 15, color: Colors.white),
                                      )
                                    ],
                                  )),
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
                                              BorderRadius.circular(4.0),
                                          side: const BorderSide(
                                              color: Colors.red)))),
                              onPressed: () async {
                                var res = validateIfEditedValuesAreSaved();

                                if (res) {
                                  Helpers.showAlert(context,
                                      title:
                                          "Are you sure you want to cancel this job?",
                                      child: Column(children: [
                                        SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              .03,
                                        ),
                                        Container(
                                            child:
                                                DropdownButtonFormField<String>(
                                          isExpanded: true,
                                          items: cancellationReasons
                                              ?.map((Reason value) {
                                            return DropdownMenuItem<String>(
                                              value: value.reason,
                                              child: Text(value.reason ?? ""),
                                            );
                                          }).toList(),
                                          onChanged: (element) async {
                                            if (isErrorCancellationReason) {
                                              setState(() {
                                                isErrorCancellationReason =
                                                    false;
                                              });
                                            }

                                            var index = cancellationReasons
                                                ?.map((e) => e.reason)
                                                .toList()
                                                .indexOf(element.toString());

                                            setState(() {
                                              selectedCancellationReason =
                                                  cancellationReasons?[
                                                          index ?? 0]
                                                      .id;
                                            });
                                            // var res = Repositories
                                            //     .cancelJob(selectedJob?.serviceRequestid , );
                                            // await refreshJobDetails();
                                          },
                                          decoration: InputDecoration(
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      vertical: 7,
                                                      horizontal: 3),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    const BorderRadius.all(
                                                  const Radius.circular(5.0),
                                                ),
                                              ),
                                              filled: true,
                                              hintStyle: TextStyle(
                                                  color: Colors.grey[800]),
                                              hintText:
                                                  "Please Select a Reason",
                                              fillColor: Colors.white),
                                          //value: dropDownValue,
                                        )),
                                        SizedBox(height: 5),
                                      ]),
                                      hasAction: true,
                                      okTitle: "Yes",
                                      noTitle: "No",
                                      customImage: Image(
                                          image: AssetImage(
                                              'assets/images/info.png'),
                                          width: 50,
                                          height: 50),
                                      hasCancel: true, onPressed: () async {
                                    if (selectedCancellationReason != null) {
                                      await pickImage(false, false, true, false,
                                              false, false)
                                          .then((value) =>
                                              Navigator.pop(context));
                                    } else {
                                      Helpers.showAlert(context,
                                          hasAction: true,
                                          type: "error",
                                          title: "A Reason should be selected",
                                          onPressed: () async {
                                        Navigator.pop(context);
                                      });
                                    }
                                  });
                                }
                              })
                          : new Container(),
                      SizedBox(height: 10),
                      checkActionsEnabled("complete")
                          ? ElevatedButton(
                              child: Padding(
                                  padding: const EdgeInsets.all(0.0),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        // <-- Icon
                                        Icons.check,
                                        color: Colors.white,
                                        size: 18.0,
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      const Text(
                                        'Complete Job',
                                        style: TextStyle(
                                            fontSize: 15, color: Colors.white),
                                      )
                                    ],
                                  )),
                              style: ButtonStyle(
                                  foregroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.green),
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.green),
                                  shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4.0),
                                          side: const BorderSide(
                                              color: Colors.green)))),
                              onPressed: () async {
                                setState(() {
                                  isErrorProblemSelection = false;
                                  isErrorEstimatedSolutionSelection = false;
                                  isErrorActualSolutionSelection = false;
                                  isPendingItemsInPickList = false;
                                  isErrorSerialNo = false;
                                });

                                if (selectedJob != null &&
                                    !(selectedJob?.isUnderWarranty ?? true) &&
                                    serialNoController.text == "") {
                                  setState(() {
                                    isErrorSerialNo = true;
                                  });
                                }

                                var res = validateIfEditedValuesAreSaved();

                                var isEmptySolutionOrProblem = false;

                                if (selectedJob?.actualSolutionCode == null) {
                                  setState(() {
                                    isEmptySolutionOrProblem = true;
                                    isErrorActualSolutionSelection = true;
                                  });
                                }

                                if (selectedJob?.actualProblemCode == null) {
                                  setState(() {
                                    isEmptySolutionOrProblem = true;
                                    isErrorProblemSelection = true;
                                  });
                                }

                                if (selectedJob?.estimatedSolutionCode ==
                                    null) {
                                  setState(() {
                                    isEmptySolutionOrProblem = true;
                                    isErrorEstimatedSolutionSelection = true;
                                  });
                                }

                                if (isErrorEstimatedSolutionSelection) {
                                  _scrollController.animateTo(
                                    _scrollController.position.maxScrollExtent,
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                }

                                if (isErrorActualSolutionSelection) {
                                  _scrollController.animateTo(
                                    _scrollController.position.maxScrollExtent,
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );

                                  tabController?.animateTo(2);
                                }

                                if ((selectedJob
                                            ?.picklistNotCollected?.length ??
                                        0) >
                                    0) {
                                  setState(() {
                                    isPendingItemsInPickList = true;
                                  });
                                }

                                if (res &&
                                    !isEmptySolutionOrProblem &&
                                    !isErrorSerialNo &&
                                    !isPendingItemsInPickList) {
                                  Helpers.showAlert(context,
                                      title: "Confirm to Complete Job?",
                                      desc:
                                          "Are you sure you want to complete this job ?",
                                      hasAction: true,
                                      okTitle: "Confirm",
                                      maxWidth: 600.0,
                                      customImage: Image(
                                          image: AssetImage(
                                              'assets/images/info.png'),
                                          width: 50,
                                          height: 50),
                                      hasCancel: true, onPressed: () async {
                                    _renderStepper();
                                  });
                                } else {
                                  Helpers.showAlert(context,
                                      hasAction: true,
                                      title: isPendingItemsInPickList
                                          ? "There are pending items in the picklist. Please collect/remove them before proceeding."
                                          : "Please fill in all the required information",
                                      type: "error", onPressed: () async {
                                    Navigator.pop(context);
                                    await refreshJobDetails();
                                  });
                                }
                              })
                          : new Container(),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.1,
                      ),
                      checkActionsEnabled("payment") &&
                              (selectedJob?.serviceType?.toLowerCase() ==
                                  "home visit") &&
                              rcpCost != null
                          ? ElevatedButton(
                              child: Padding(
                                  padding: const EdgeInsets.all(0.0),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        // <-- Icon
                                        Icons.check,
                                        color: Colors.white,
                                        size: 18.0,
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      const Text(
                                        'Payment',
                                        style: TextStyle(
                                            fontSize: 15, color: Colors.white),
                                      )
                                    ],
                                  )),
                              style: ButtonStyle(
                                  foregroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.green),
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.green),
                                  shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4.0),
                                          side: const BorderSide(
                                              color: Colors.green)))),
                              onPressed: () async {
                                Navigator.pushNamed(context, 'signature',
                                        arguments: [selectedJob, rcpCost])
                                    .then((val) async {
                                  if ((val as bool)) {}
                                });
                              })
                          : new Container(),
                      checkActionsEnabled("complete")
                          ? const SizedBox(
                              height: 10,
                            )
                          : new Container(),
                      checkActionsEnabled("kiv")
                          ? SizedBox(
                              width: MediaQuery.of(context).size.width *
                                  0.2, // <-- match_parent
                              height: MediaQuery.of(context).size.width *
                                  0.05, // <-- match-parent
                              child: true
                                  ? ElevatedButton(
                                      child: Padding(
                                          padding: const EdgeInsets.all(0.0),
                                          child: Row(children: [
                                            const Icon(
                                              // <-- Icon
                                              Icons.camera_alt_outlined,
                                              color: Colors.white,
                                              size: 18.0,
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Text(
                                              'KIV Job ${selectedJob?.currentKIVCount}/${((selectedJob?.maxKIVCount ?? 0) + 1)}',
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.white),
                                            )
                                          ])),
                                      style: ButtonStyle(
                                          foregroundColor:
                                              MaterialStateProperty.all<Color>(
                                                  Colors.lightBlue),
                                          backgroundColor:
                                              MaterialStateProperty.all<Color>(
                                                  Colors.lightBlue),
                                          shape: MaterialStateProperty.all<
                                                  RoundedRectangleBorder>(
                                              RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(
                                                      4.0),
                                                  side: const BorderSide(
                                                      color: Colors.lightBlue)))),
                                      onPressed: () async {
                                        var res =
                                            validateIfEditedValuesAreSaved();

                                        if (res) {
                                          Helpers.showAlert(context,
                                              title:
                                                  "Are you sure you want to move this job to KIV?",
                                              child: Column(children: [
                                                SizedBox(
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      .03,
                                                ),
                                                Container(
                                                    child:
                                                        DropdownButtonFormField<
                                                            String>(
                                                  isExpanded: true,
                                                  items: KIVReasons?.map(
                                                      (Reason value) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: value.reason,
                                                      child: Text(
                                                          value.reason ?? ""),
                                                    );
                                                  }).toList(),
                                                  onChanged: (element) async {
                                                    if (isErrorKIVReason) {
                                                      setState(() {
                                                        isErrorKIVReason =
                                                            false;
                                                      });
                                                    }

                                                    var index = KIVReasons?.map(
                                                            (e) => e.reason)
                                                        .toList()
                                                        .indexOf(
                                                            element.toString());

                                                    setState(() {
                                                      selectedKIVReason =
                                                          KIVReasons?[
                                                                  index ?? 0]
                                                              .id;
                                                    });
                                                    // var res = Repositories
                                                    //     .cancelJob(selectedJob?.serviceRequestid , );
                                                    // await refreshJobDetails();
                                                  },
                                                  decoration: InputDecoration(
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                              vertical: 7,
                                                              horizontal: 3),
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            const BorderRadius
                                                                .all(
                                                          const Radius.circular(
                                                              5.0),
                                                        ),
                                                      ),
                                                      filled: true,
                                                      hintStyle: TextStyle(
                                                          color:
                                                              Colors.grey[800]),
                                                      hintText:
                                                          "Please Select a Reason",
                                                      fillColor: Colors.white),
                                                  //value: dropDownValue,
                                                )),
                                                SizedBox(height: 5),
                                              ]),
                                              hasAction: true,
                                              okTitle: "Yes",
                                              noTitle: "No",
                                              customImage: Image(
                                                  image: AssetImage(
                                                      'assets/images/info.png'),
                                                  width: 50,
                                                  height: 50),
                                              hasCancel: true,
                                              onPressed: () async {
                                            if (selectedKIVReason != null) {
                                              await pickImage(
                                                      true,
                                                      false,
                                                      false,
                                                      false,
                                                      false,
                                                      false)
                                                  .then((value) =>
                                                      Navigator.pop(context));
                                            } else {
                                              Helpers.showAlert(context,
                                                  hasAction: true,
                                                  type: "error",
                                                  title:
                                                      "A Reason should be selected",
                                                  onPressed: () async {
                                                Navigator.pop(context);
                                              });
                                            }
                                          });
                                        }
                                      })
                                  : new Container(),
                            )
                          : new Container(),
                      SizedBox(height: 10),
                      checkActionsEnabled('reject')
                          ? ElevatedButton(
                              child: Padding(
                                  padding: const EdgeInsets.all(0.0),
                                  child: Row(children: [
                                    const Icon(
                                      // <-- Icon
                                      Icons.cancel,
                                      color: Colors.white,
                                      size: 18.0,
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    const Text(
                                      'Reject Job',
                                      style: const TextStyle(
                                          fontSize: 15, color: Colors.white),
                                    )
                                  ])),
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
                                              BorderRadius.circular(4.0),
                                          side: const BorderSide(
                                              color: Colors.red)))),
                              onPressed: () async {
                                var res = validateIfEditedValuesAreSaved();

                                if (res) {
                                  Helpers.showAlert(context,
                                      title:
                                          "Are you sure you want to reject this job ?",
                                      child: Column(children: [
                                        SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              .03,
                                        ),
                                        Container(
                                            child:
                                                DropdownButtonFormField<String>(
                                          isExpanded: true,
                                          items: rejectReasons
                                              ?.map((Reason value) {
                                            return DropdownMenuItem<String>(
                                              value: value.reason,
                                              child: Text(value.reason ?? ""),
                                            );
                                          }).toList(),
                                          onChanged: (element) async {
                                            if (isErrorRejectReason) {
                                              setState(() {
                                                isErrorRejectReason = false;
                                              });
                                            }

                                            var index = rejectReasons
                                                ?.map((e) => e.reason)
                                                .toList()
                                                .indexOf(element.toString());

                                            setState(() {
                                              selectedRejectReason =
                                                  rejectReasons?[index ?? 0].id;
                                            });
                                            var res = Repositories.rejectJob(
                                                selectedJob?.serviceRequestid ??
                                                    "",
                                                selectedRejectReason);
                                            await refreshJobDetails();
                                          },
                                          decoration: InputDecoration(
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      vertical: 7,
                                                      horizontal: 3),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    const BorderRadius.all(
                                                  const Radius.circular(5.0),
                                                ),
                                              ),
                                              filled: true,
                                              hintStyle: TextStyle(
                                                  color: Colors.grey[800]),
                                              hintText:
                                                  "Please Select a Reason",
                                              fillColor: Colors.white),
                                          //value: dropDownValue,
                                        )),
                                        SizedBox(height: 5),
                                      ]),
                                      hasAction: true,
                                      okTitle: "Yes",
                                      noTitle: "No",
                                      customImage: Image(
                                          image: AssetImage(
                                              'assets/images/info.png'),
                                          width: 50,
                                          height: 50),
                                      hasCancel: true, onPressed: () async {
                                    if (selectedRejectReason != null) {
                                      await Repositories.rejectJob(
                                              selectedJob?.serviceRequestid ??
                                                  "",
                                              selectedRejectReason)
                                          .then((value) =>
                                              Navigator.pop(context));
                                    } else {
                                      Helpers.showAlert(context,
                                          hasAction: true,
                                          type: "error",
                                          title: "A Reason should be selected",
                                          onPressed: () async {
                                        Navigator.pop(context);
                                      });
                                    }
                                  });
                                }
                              })
                          : new Container(),
                    ],
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
            ]),
          ),
          Row(children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  isPreviousJobsSelected = false;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: !isPreviousJobsSelected
                      ? Color(0xFFFFF6DF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(15, 9, 15, 9),
                  child: Center(
                      child: Row(children: [
                    Icon(
                      Icons.history,
                      color: !isPreviousJobsSelected
                          ? Color(0xFFFFB700)
                          : Color(0xFFFFDB7F),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      "Current Job",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ])),
                ),
              ),
            ),
            (jobHistory != null && jobHistory.length > 0)
                ? SizedBox(
                    width: 10,
                  )
                : new Container(),
            (jobHistory != null && jobHistory.length > 0)
                ? GestureDetector(
                    onTap: () {
                      setState(() {
                        isPreviousJobsSelected = true;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isPreviousJobsSelected
                            ? Color(0xFFFFF6DF)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(15),
                        child: Center(
                          child: Row(children: [
                            Icon(
                              Icons.history,
                              color: isPreviousJobsSelected
                                  ? Color(0xFFFFB700)
                                  : Color(0xFFFFDB7F),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              "Previous Jobs",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  )
                : new Container(),
          ]),
          Divider(),
          !isPreviousJobsSelected
              ? Container(
                  padding: EdgeInsets.fromLTRB(30, 10, 30, 30),
                  color: Colors.white,
                  child: Column(children: [
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
                                  text: const TextSpan(
                                      style: TextStyle(
                                        fontSize: 20.0,
                                        color: Colors.black,
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: 'Job Description',
                                        ),
                                      ]),
                                ),
                                const SizedBox(height: 10),
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
                    const SizedBox(height: 20),
                    buildProductInfo(),
                    const SizedBox(height: 20),
                    Divider(),
                    const SizedBox(height: 20),
                    buildIssueInfo(),
                    const SizedBox(height: 20),
                    (rcpCost != null && rcpCost?.total != "MYR 0.00")
                        ? Divider()
                        : new Container(),
                    (rcpCost != null && rcpCost?.total != "MYR 0.00")
                        ? const SizedBox(height: 20)
                        : new Container(),
                    (rcpCost != null && rcpCost?.total != "MYR 0.00")
                        ? _renderCost(false)
                        : new Container(),
                    (rcpCost != null && rcpCost?.total != "MYR 0.00")
                        ? const SizedBox(height: 10)
                        : new Container(),
                    Divider(),
                    const SizedBox(height: 20),
                    _renderPickList(false),
                    const SizedBox(height: 10),
                    Divider(),
                    const SizedBox(height: 20),
                    _renderPartsList(false),
                    const SizedBox(height: 10),
                    Divider(),
                    const SizedBox(height: 20),
                    _renderMiscItems(false),
                    isTransportationChargesAvailable &&
                            selectedJob?.serviceType?.toLowerCase() ==
                                "home visit"
                        ? const Divider()
                        : Container(),
                    isTransportationChargesAvailable &&
                            selectedJob?.serviceType?.toLowerCase() ==
                                "home visit"
                        ? const SizedBox(height: 20)
                        : const SizedBox(height: 0),
                    isTransportationChargesAvailable &&
                            selectedJob?.serviceType?.toLowerCase() ==
                                "home visit"
                        ? _renderTransportCharges(false)
                        : new Container(),
                    isTransportationChargesAvailable &&
                            selectedJob?.serviceType?.toLowerCase() ==
                                "home visit"
                        ? const SizedBox(height: 10)
                        : new Container(),
                    Divider(),
                    const SizedBox(height: 20),
                    _renderPickupCharges(false),
                    const SizedBox(height: 20),
                    Divider(),
                    const SizedBox(height: 20),
                    _renderProblems(false),
                    const SizedBox(height: 20),
                    Divider(),
                    const SizedBox(height: 20),
                    _renderSolutions(false),
                    const SizedBox(height: 20),
                    checkActionsEnabled('start') ? Divider() : new Container(),
                    checkActionsEnabled('start')
                        ? const SizedBox(height: 20)
                        : new Container(),
                    checkActionsEnabled('start')
                        ? _renderStartButton()
                        : new Container(),
                    checkActionsEnabled('start')
                        ? const SizedBox(height: 20)
                        : new Container(),
                  ]))
              : (jobHistory != null && jobHistory.length > 0)
                  ? ConstrainedBox(
                      constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * .58,
                          minHeight: MediaQuery.of(context).size.height * .1),
                      child: ReorderableListView.builder(
                        onReorder: ((oldIndex, newIndex) async {}),
                        shrinkWrap: true,
                        itemCount: jobHistory.length,
                        itemBuilder: (BuildContext context, int index) {
                          return GestureDetector(
                            child: JobItem(
                                history: jobHistory,
                                width: MediaQuery.of(context).size.width,
                                job: selectedJob ?? new Job(),
                                index: index),
                            onTap: () async {
                              Helpers.selectedJobIndex = index;

                              Job? job;

                              // if (job != null) {
                              Helpers.selectedJob = job;

                              Navigator.pushNamed(context, 'jobDetails',
                                      arguments:
                                          jobHistory[index].serviceRequestid)
                                  .then((value) async {});
                              // }
                            },
                            key: ValueKey(index),
                          );
                        },
                      ),
                    )
                  : new Container(),
        ]),
      ),
    );
  }

  showActionFailedAlert() {
    Widget okButton = TextButton(
      child: Text("Ok"),
      onPressed: () {},
    );

    AlertDialog alert = AlertDialog(
      title: Text("Error"),
      content: Text("Could not complete the action. Please retry."),
      actions: [okButton],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  showActionEmptyAlert() {
    Widget okButton = TextButton(
      child: Text("Ok"),
      onPressed: () {},
    );

    AlertDialog alert = AlertDialog(
      title: Text("Error"),
      content: Text("Following values cannot be empty."),
      actions: [okButton],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  _renderStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 50.0,
      child: ElevatedButton(
          child: const Padding(
              padding: EdgeInsets.all(0.0),
              child: Text(
                'Job Start',
                style: TextStyle(fontSize: 15, color: Colors.white),
              )),
          style: ButtonStyle(
              foregroundColor:
                  MaterialStateProperty.all<Color>(Color(0xFFffb700)),
              backgroundColor:
                  MaterialStateProperty.all<Color>(Color(0xFFffb700)),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                      side: const BorderSide(color: Color(0xFFffb700))))),
          onPressed: () async {
            var res = validateIfEditedValuesAreSaved();

            if (selectedJob?.estimatedSolutionCode == null) {
              setState(() {
                isErrorEstimatedSolutionSelection = true;
              });
            }

            if (isErrorEstimatedSolutionSelection) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            } else {
              if (res) {
                setState(() {
                  images = [];
                  continuePressed = false;
                  nextImagePressed = false;
                });
                await pickImage(false, false, false, false, true, false);
              }
            }

            if (res) {
              setState(() {
                images = [];
                continuePressed = false;
                nextImagePressed = false;
              });
              // await pickImage(false, false, false, false, true, false);
            }
          }),
    );
  }

  Future<void> pickImage(bool isKIV, bool isComplete, bool isCancel,
      bool isClose, bool isStart, bool isReject) async {
    images = [];

    await showMultipleImagesPromptDialog(
        context, true, isKIV, isComplete, isCancel, isStart, isReject, isClose);
  }

  _renderSolutionComponents(bool isStepper, bool isActual) {
    return Container(
        padding: EdgeInsets.only(bottom: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Helpers.checkIfEditableByJobStatusForSolution(isActual, selectedJob,
                        (selectedJob?.isMainEngineer ?? false)) &&
                    !isStepper
                ? SizedBox(height: 30)
                : new Container(),
            (solutionLabels.contains(isActual
                        ? selectedJob?.actualSolutionDescription
                        : selectedJob?.estimatedSolutionDescription) &&
                    Helpers.checkIfEditableByJobStatusForSolution(isActual,
                        selectedJob, (selectedJob?.isMainEngineer ?? false)) &&
                    !isStepper)
                ? DropdownButtonFormField<String>(
                    isExpanded: true,
                    items: solutionLabels.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (element) async {
                      var index = solutions
                          .indexWhere((e) => e.solution == element.toString());
                      var res = await Repositories.addSolutionToJob(
                          selectedJob!.serviceRequestid ?? "0",
                          solutions[index].solutionId ?? 0,
                          !isActual);
                      //show error if error
                      await refreshJobDetails();
                    },
                    decoration: InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 7, horizontal: 3),
                        border: OutlineInputBorder(
                          borderRadius: const BorderRadius.all(
                            const Radius.circular(5.0),
                          ),
                        ),
                        filled: true,
                        hintStyle: TextStyle(color: Colors.grey[800]),
                        hintText: "Please Select a Solution",
                        fillColor: Colors.white),
                    value: solutionLabels.contains(isActual
                            ? selectedJob?.actualSolutionDescription
                            : selectedJob?.estimatedSolutionDescription)
                        ? isActual
                            ? selectedJob?.actualSolutionDescription
                            : selectedJob?.estimatedSolutionDescription
                        : "",
                  )
                : Helpers.checkIfEditableByJobStatusForSolution(
                            isActual,
                            selectedJob,
                            (selectedJob?.isMainEngineer ?? false)) &&
                        !isStepper
                    ? DropdownButtonFormField<String>(
                        isExpanded: true,
                        items: solutionLabels.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (element) async {
                          var index =
                              solutionLabels.indexOf(element.toString());
                          var res = await Repositories.addSolutionToJob(
                              selectedJob!.serviceRequestid ?? "0",
                              solutions[index].solutionId ?? 0,
                              !isActual);
                          //show error if error
                          await refreshJobDetails();
                        },
                        decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 7, horizontal: 3),
                            border: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(
                                const Radius.circular(5.0),
                              ),
                            ),
                            filled: true,
                            hintStyle: TextStyle(color: Colors.grey[800]),
                            hintText: "Please Select a Solution",
                            fillColor: Colors.white),
                        //value: dropDownValue,
                      )
                    : new Container(),
            Helpers.checkIfEditableByJobStatusForSolution(isActual, selectedJob,
                        (selectedJob?.isMainEngineer ?? false)) &&
                    !isStepper
                ? SizedBox(height: 20)
                : new Container(),
            ((isActual
                        ? selectedJob?.actualSolutionCode
                        : selectedJob?.estimatedSolutionCode) !=
                    null)
                ? Container(
                    padding: EdgeInsets.only(
                        bottom: Helpers.checkIfEditableByJobStatusForSolution(
                                    isActual,
                                    selectedJob,
                                    (selectedJob?.isMainEngineer ?? false)) &&
                                !isStepper
                            ? 0
                            : 40),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ((isActual
                                    ? selectedJob?.actualSolutionCode
                                    : selectedJob?.estimatedSolutionCode) !=
                                null)
                            ? Container(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 12.0,
                                          color: Colors.black54,
                                        ),
                                        children: <TextSpan>[
                                          TextSpan(
                                            text: (isActual
                                                ? 'ACTUAL SOLUTION CODE'
                                                : 'ESTIMATED SOLUTION CODE'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.black,
                                        ),
                                        children: <TextSpan>[
                                          TextSpan(
                                            text: isActual
                                                ? selectedJob
                                                    ?.actualSolutionCode
                                                : selectedJob
                                                    ?.estimatedSolutionCode,
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              )
                            : new Container(),
                        ((isActual
                                    ? selectedJob?.actualSolutionCode
                                    : selectedJob?.estimatedSolutionCode) !=
                                null)
                            ? Container(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 12.0,
                                          color: Colors.black54,
                                        ),
                                        children: <TextSpan>[
                                          TextSpan(
                                            text: isActual
                                                ? 'ACTUAL SOLUTION'
                                                : 'ESTIMATED SOLUTION',
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.black,
                                        ),
                                        children: <TextSpan>[
                                          TextSpan(
                                            text: isActual
                                                ? selectedJob
                                                    ?.actualSolutionDescription
                                                : selectedJob
                                                    ?.estimatedSolutionDescription,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : new Container(),
                        (isActual
                                    ? selectedJob?.actualSolutionCharges
                                    : selectedJob?.estimatedSolutionCharges) !=
                                null
                            ? Container(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    RichText(
                                      text: const TextSpan(
                                        style: TextStyle(
                                          fontSize: 12.0,
                                          color: Colors.black54,
                                        ),
                                        children: <TextSpan>[
                                          const TextSpan(
                                            text: 'COST',
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.black,
                                        ),
                                        children: <TextSpan>[
                                          TextSpan(
                                            text: isActual
                                                ? selectedJob
                                                    ?.actualSolutionCharges
                                                : selectedJob
                                                    ?.estimatedSolutionCharges,
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              )
                            : new Container(),
                        (isActual
                                    ? selectedJob?.actualSolutionCharges
                                    : selectedJob?.estimatedSolutionCharges) !=
                                null
                            ? Container(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    RichText(
                                      text: const TextSpan(
                                        style: TextStyle(
                                          fontSize: 12.0,
                                          color: Colors.black54,
                                        ),
                                        children: <TextSpan>[
                                          const TextSpan(
                                            text: 'COST (Incl. Tax)',
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.black,
                                        ),
                                        children: <TextSpan>[
                                          TextSpan(
                                            text:
                                                'MYR ${isActual ? selectedJob?.actualSolutionTotalLineVal : selectedJob?.estimatedSolutionTotalLineVal}',
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              )
                            : new Container(),
                        Helpers.checkIfEditableByJobStatusForSolution(
                                    isActual,
                                    selectedJob,
                                    (selectedJob?.isMainEngineer ?? false)) &&
                                !isStepper
                            ? SizedBox(
                                width: 70,
                                height: 40.0,
                                child: ElevatedButton(
                                    child: const Padding(
                                        padding: EdgeInsets.all(0.0),
                                        child: Text(
                                          'Clear',
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.white),
                                        )),
                                    style: ButtonStyle(
                                        foregroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Color(0xFF242A38)),
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Color(0xFF242A38)),
                                        shape: MaterialStateProperty.all<
                                                RoundedRectangleBorder>(
                                            RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4.0),
                                                side: const BorderSide(
                                                    color:
                                                        Color(0xFF242A38))))),
                                    onPressed: () async {
                                      await Repositories.addSolutionToJob(
                                          selectedJob!.serviceRequestid ?? "0",
                                          null,
                                          !isActual);

                                      await refreshJobDetails();
                                    }),
                              )
                            : new Container()
                      ],
                    ))
                : (isActual
                        ? isErrorActualSolutionSelection
                        : isErrorEstimatedSolutionSelection)
                    ? Container(
                        child: Row(children: [
                        Container(
                            child: Row(children: [
                          Icon(
                            Icons.warning,
                            color: Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          RichText(
                            text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 15.0,
                                  color: Colors.red,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: (isActual
                                        ? "Please select the Actual solution before proceeding."
                                        : "Please select the Estimated solution before proceeding."),
                                  ),
                                ]),
                          ),
                        ]))
                      ]))
                    : new Container()
          ],
        ));
  }

  _renderSolutions(bool isStepper) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            RichText(
              text: const TextSpan(
                  style: TextStyle(
                    fontSize: 20.0,
                    color: Colors.black,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Select Solution',
                    ),
                  ]),
            ),
            Spacer(),
            FlutterSwitch(
              activeColor: Helpers.checkIfEditableByJobStatus(
                          selectedJob, (selectedJob?.isMainEngineer ?? true)) &&
                      !isStepper
                  ? Colors.green
                  : Colors.grey,
              inactiveColor: Helpers.checkIfEditableByJobStatus(
                          selectedJob, (selectedJob?.isMainEngineer ?? true)) &&
                      !isStepper
                  ? Colors.red
                  : Colors.grey,
              activeTextColor: Colors.white,
              inactiveTextColor: Colors.white,
              activeText: "Chargeable",
              inactiveText: "Not Chargeable",
              value: isChargeableSolutionCharges,
              valueFontSize: 14.0,
              width: MediaQuery.of(context).size.width * 0.2,
              borderRadius: 30.0,
              showOnOff: true,
              onToggle: (val) async {
                if (Helpers.checkIfEditableByJobStatus(
                        selectedJob, (selectedJob?.isMainEngineer ?? false)) &&
                    !isStepper &&
                    (selectedJob?.isMainEngineer ?? false)) {
                  var result = await Repositories.updateChargeable(
                      selectedJob!.serviceRequestid ?? "0",
                      isChargeablePickupCharges,
                      isChargeableTransportCharges,
                      !isChargeableSolutionCharges,
                      isChargeableMiscellaneousCharges,
                      isDiscountApplied,
                      (selectedJob?.chargeableSparepartIds ?? []));

                  await refreshJobDetails();
                }
              },
            )
          ]),
          SizedBox(
            height: 20,
          ),
          tabController != null && (selectedJob?.isMainEngineer ?? false)
              ? Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(0),
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.03,
                          width: selectedJob?.serviceJobStatus?.toLowerCase() ==
                                  "pending job start"
                              ? MediaQuery.of(context).size.width * 0.25
                              : MediaQuery.of(context).size.width * 0.5,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white),
                          child: TabBar(
                            controller: tabController,
                            indicator: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.black,
                            // ignore: prefer_const_literals_to_create_immutables
                            tabs:
                                selectedJob?.serviceJobStatus?.toLowerCase() ==
                                        "pending job start"
                                    ? [
                                        Tab(
                                          text: "Estimated Solution",
                                        )
                                      ]
                                    : [
                                        Tab(
                                          text: "Estimated Solution",
                                        ),
                                        Tab(
                                          text: "Actual Solution",
                                        )
                                      ],
                          ),
                        ),
                      ),
                      ConstrainedBox(
                          constraints: BoxConstraints(
                              minWidth: MediaQuery.of(context).size.width * 1,
                              maxWidth: MediaQuery.of(context).size.width * 1,
                              maxHeight:
                                  MediaQuery.of(context).size.height * .13,
                              minHeight:
                                  MediaQuery.of(context).size.height * .1),
                          child: TabBarView(
                              controller: tabController,
                              children: (selectedJob?.serviceJobStatus
                                          ?.toLowerCase() ==
                                      "pending job start"
                                  ? ([
                                      Container(
                                        child: _renderSolutionComponents(
                                            isStepper, false),
                                      ),
                                    ])
                                  : ([
                                      Container(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.15,
                                        width:
                                            MediaQuery.of(context).size.width *
                                                1,
                                        child: _renderSolutionComponents(
                                            isStepper, false),
                                      ),
                                      Container(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.15,
                                        width:
                                            MediaQuery.of(context).size.width *
                                                1,
                                        child: _renderSolutionComponents(
                                            isStepper, true),
                                      ),
                                    ])))),
                    ],
                  ),
                )
              : new Container()
        ]);
  }

  Widget _renderProblems(bool isStepper) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
              style: TextStyle(
                fontSize: 20.0,
                color: Colors.black,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: 'Select Actual Problem',
                ),
              ]),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 30),
            (selectedJob?.actualProblemCode != null ||
                        selectedJob?.actualProblemDescription != null) &&
                    Helpers.checkIfEditableByJobStatus(
                        selectedJob, (selectedJob?.isMainEngineer ?? true)) &&
                    !isStepper
                ? DropdownButtonFormField<String>(
                    isExpanded: true,
                    items: problemLabels.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (element) async {
                      var index =
                          problems.indexWhere((e) => e.problem == element);
                      if (index != -1) {
                        var res = await Repositories.addProblemToJob(
                            (selectedJob?.serviceRequestid ?? ""),
                            problems[index].problemId ?? 0,
                            false);
                        //show error if error
                        await refreshJobDetails();
                      }
                    },
                    decoration: InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 7, horizontal: 3),
                        border: OutlineInputBorder(
                          borderRadius: const BorderRadius.all(
                            const Radius.circular(5.0),
                          ),
                        ),
                        filled: true,
                        hintStyle: TextStyle(color: Colors.grey[800]),
                        hintText: "Please Select a Problem",
                        fillColor: Colors.white),
                    value: problemLabels
                            .contains(selectedJob?.actualProblemDescription)
                        ? selectedJob?.actualProblemDescription
                        : "",
                  )
                : Helpers.checkIfEditableByJobStatus(selectedJob,
                            (selectedJob?.isMainEngineer ?? true)) &&
                        !isStepper
                    ? DropdownButtonFormField<String>(
                        isExpanded: true,
                        items: problemLabels.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (element) async {
                          var index = problemLabels.indexOf(element.toString());
                          var res = await Repositories.addProblemToJob(
                              (selectedJob?.serviceRequestid ?? ""),
                              problems[index].problemId ?? 0,
                              false);
                          //show error if error
                          await refreshJobDetails();
                        },
                        decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 7, horizontal: 3),
                            border: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(
                                const Radius.circular(5.0),
                              ),
                            ),
                            filled: true,
                            hintStyle: TextStyle(color: Colors.grey[800]),
                            hintText: "Please Select a Problem",
                            fillColor: Colors.white),
                        //value: dropDownValue,
                      )
                    : new Container(),
            SizedBox(height: 20),
            selectedJob?.actualProblemCode != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.black54,
                                ),
                                children: <TextSpan>[
                                  const TextSpan(
                                    text: 'PROBLEM CODE',
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.black,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: selectedJob?.actualProblemCode),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      Container(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.black54,
                                ),
                                children: <TextSpan>[
                                  const TextSpan(
                                    text: 'PROBLEM CODE',
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.black,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: selectedJob?.actualProblemDescription,
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      Helpers.checkIfEditableByJobStatus(selectedJob,
                                  (selectedJob?.isMainEngineer ?? true)) &&
                              !isStepper
                          ? SizedBox(
                              width: 70,
                              height: 40.0,
                              child: ElevatedButton(
                                  child: const Padding(
                                      padding: EdgeInsets.all(0.0),
                                      child: Text(
                                        'Clear',
                                        style: TextStyle(
                                            fontSize: 15, color: Colors.white),
                                      )),
                                  style: ButtonStyle(
                                      foregroundColor:
                                          MaterialStateProperty.all<Color>(
                                              Color(0xFF242A38)),
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                              Color(0xFF242A38)),
                                      shape: MaterialStateProperty.all<
                                              RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4.0),
                                              side: const BorderSide(
                                                  color: Color(0xFF242A38))))),
                                  onPressed: () async {
                                    await Repositories.addProblemToJob(
                                        selectedJob!.serviceRequestid ?? "0",
                                        null,
                                        selectedJob?.serviceJobStatus
                                                ?.toLowerCase() ==
                                            "pending job start");

                                    await refreshJobDetails();
                                  }),
                            )
                          : new Container()
                    ],
                  )
                : isErrorProblemSelection
                    ? Container(
                        child: Row(children: [
                        Icon(
                          Icons.warning,
                          color: Colors.red,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        RichText(
                          text: TextSpan(
                              style: const TextStyle(
                                fontSize: 15.0,
                                color: Colors.red,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text:
                                      "Please select the Actual problem before proceeding.",
                                ),
                              ]),
                        ),
                      ]))
                    : new Container()
          ],
        ),
      ],
    );
  }

  _renderErrorUpdateValues() {
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () {},
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Error"),
      content: Text("Values could not be updated"),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<bool> deleteItemFromPickList(
      int id, bool isDeleteAll, int quantity) async {
    List<SparePart> ids = [];

    // var ids = addedSparePartQuantities.map((e) => e.id).toList();

    selectedJob?.picklistNotCollected?.forEach((element) {
      if (element.id == id) {
        element.quantity = isDeleteAll ? 0 : quantity;
      }
      ids.add(element);
    });

    ids.forEach((element) {
      element.from = "warehouse";
    });

    return await Repositories.addItemsToPickList(
        (selectedJob!.serviceRequestid ?? "0"), ids ?? []);
  }

  Widget _renderPickList(bool isStepper) {
    return Column(
      children: [
        Row(
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.black,
                ),
                children: <TextSpan>[
                  const TextSpan(
                    text: 'Pick List',
                  ),
                ],
              ),
            ),
            Spacer(),
            Helpers.checkIfEditableByJobStatus(
                        selectedJob, (selectedJob?.isMainEngineer ?? true)) &&
                    !isStepper
                //&&
                // (selectedJob?.picklistNotCollected?.length ?? 0) == 0 &&
                // rcpCost != null
                ? ElevatedButton(
                    child: const Padding(
                        padding: EdgeInsets.all(0.0),
                        child: Text(
                          'Add Parts',
                          style: TextStyle(fontSize: 15, color: Colors.white),
                        )),
                    style: ButtonStyle(
                        foregroundColor:
                            MaterialStateProperty.all<Color>(Color(0xFF242A38)),
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Color(0xFF242A38)),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4.0),
                                    side: const BorderSide(
                                        color: Color(0xFF242A38))))),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AddItemsFromBagDialog(
                              bag: userBag,
                              existingJobSpareParts: [],
                              ticketNo: selectedJob?.serviceJobNo,
                              jobId: (selectedJob?.serviceRequestid ?? ""));
                        },
                      ).then((value) async {
                        await refreshJobDetails();
                      });
                    })
                : new Container(),
          ],
        ),
        SizedBox(
          height: 20,
        ),
        (selectedJob?.picklistNotCollected != null &&
                    (selectedJob?.picklistNotCollected!.length ?? 0) > 0) &&
                Helpers.checkIfEditableByJobStatus(
                    selectedJob, (selectedJob?.isMainEngineer ?? true)) &&
                rcpCost != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  (!isPickListPartsEditable &&
                          selectedJob?.serviceJobStatus != "COMPLETED")
                      ? ElevatedButton(
                          child: const Padding(
                              padding: EdgeInsets.all(0.0),
                              child: Text(
                                'Edit',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.white),
                              )),
                          style: ButtonStyle(
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  Color(0xFF242A38)),
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Color(0xFF242A38)),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                      side: const BorderSide(
                                          color: Color(0xFF242A38))))),
                          onPressed: () => {
                                setState(() {
                                  isPickListPartsEditable = true;
                                })
                              })
                      : new Container(),
                  isPickListPartsEditable
                      ? ElevatedButton(
                          child: const Padding(
                              padding: EdgeInsets.all(0.0),
                              child: Text(
                                'Save Changes',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.white),
                              )),
                          style: ButtonStyle(
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  Color(0xFF242A38)),
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Color(0xFF242A38)),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                      side: const BorderSide(
                                          color: Color(0xFF242A38))))),
                          onPressed: () async {
                            pickListIndexToQuantityTemp.keys?.map((e) async {
                              await deleteItemFromPickList(
                                  selectedJob!.picklistNotCollected?[e].id ?? 0,
                                  false,
                                  pickListIndexToQuantityTemp[e] ?? 0);

                              await refreshJobDetails();
                            });
                          })
                      : new Container(),
                  isPickListPartsEditable
                      ? SizedBox(
                          width: 30,
                        )
                      : new Container(),
                  isPickListPartsEditable
                      ? ElevatedButton(
                          child: const Padding(
                              padding: EdgeInsets.all(0.0),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.white),
                              )),
                          style: ButtonStyle(
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  Color(0xFF242A38)),
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Color(0xFF242A38)),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                      side: const BorderSide(
                                          color: Color(0xFF242A38))))),
                          onPressed: () async {
                            setState(() {
                              pickListIndexToQuantityTemp = {};
                            });
                            await refreshJobDetails();
                            setState(() {
                              isPickListPartsEditable = false;
                            });
                          })
                      : new Container(),
                ],
              )
            : new Container(),
        SizedBox(
          height: 25,
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: (selectedJob?.picklistNotCollected?.length ?? 0) > 0
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * .58,
                          minHeight: MediaQuery.of(context).size.height * .1),
                      child: ListView.builder(
                        // physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        // shrinkWrap: false,
                        itemCount: selectedJob?.picklistNotCollected?.length,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (BuildContext context, int index) {
                          return PickListItem(
                              aggregatedSpareParts:
                                  selectedJob?.aggregatedSpareparts ?? [],
                              isDiscountApplied: isDiscountApplied,
                              width: MediaQuery.of(context).size.width * 0.5,
                              part: (selectedJob!.picklistNotCollected!
                                  .elementAt(index)),
                              onQuantityChanged:
                                  (String newQuantity, int index) {
                                setState(() {
                                  pickListIndexToQuantityTemp[index] =
                                      newQuantity != ""
                                          ? int.parse(newQuantity)
                                          : 0;
                                });
                              },
                              index: index,
                              rcpCost: rcpCost,
                              jobId: (selectedJob!.serviceRequestid ?? ""),
                              editable: isPickListPartsEditable ? true : false,
                              partList:
                                  (selectedJob!.picklistNotCollected ?? []),
                              onDeletePressed: (var id) async {
                                await deleteItemFromPickList(id, true, 0);
                                await refreshJobDetails();
                              },
                              job: selectedJob ?? new Job());
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Container(
                      alignment: Alignment.centerLeft,
                      child: (selectedJob?.picklistNotCollected != null &&
                                  (selectedJob?.picklistNotCollected!.length ?? 0) >
                                      0) &&
                              Helpers.checkIfEditableByJobStatus(selectedJob,
                                  (selectedJob?.isMainEngineer ?? true)) &&
                              !isStepper
                          ? ElevatedButton(
                              child: Padding(
                                  padding: EdgeInsets.all(0.0),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.add_circle,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                        SizedBox(
                                          width: 5,
                                        ),
                                        Text(
                                          'Add More Parts ',
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.white),
                                        )
                                      ])),
                              style: ButtonStyle(
                                  foregroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Color(0xFF242A38)),
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Color(0xFF242A38)),
                                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4.0),
                                          side: const BorderSide(color: Color(0xFF242A38))))),
                              onPressed: () async {
                                await fetchBag(selectedJob?.serviceRequestid);
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AddItemsFromBagDialog(
                                        bag: userBag,
                                        existingJobSpareParts: [],
                                        ticketNo: selectedJob?.serviceJobNo,
                                        jobId: (selectedJob?.serviceRequestid ??
                                            ""));
                                  },
                                ).then((value) async {
                                  await refreshJobDetails();
                                });
                              })
                          : new Container(),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            SizedBox(
                              height: 50,
                            ),
                            Icon(
                              // <-- Icon
                              Icons.indeterminate_check_box,
                              color: Colors.grey,
                              size: 130.0,
                            ),
                            RichText(
                              text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 30.0,
                                    color: Colors.black,
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: 'No data found',
                                    ),
                                  ]),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Container(
                              alignment: Alignment.center,
                              width: 400,
                              child: RichText(
                                text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 15.0,
                                      color: Colors.black,
                                    ),
                                    children: <TextSpan>[
                                      TextSpan(
                                        text:
                                            'There is currently no parts listed selected.',
                                      ),
                                    ]),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                          ],
                        ))
                  ],
                ),
        )
      ],
    );
  }

  Widget _renderCost(bool isStepper) {
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          Row(
            children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.black,
                  ),
                  children: <TextSpan>[
                    const TextSpan(
                      text: 'Total Charges',
                    ),
                  ],
                ),
              ),
              Spacer(),
              (rcpCost?.isRCPValid ?? false) &&
                      rcpCost?.discountPercentage != "0%"
                  ? FlutterSwitch(
                      activeColor: Helpers.checkIfEditableByJobStatus(
                                  selectedJob,
                                  (selectedJob?.isMainEngineer ?? true)) &&
                              !isStepper
                          ? Colors.green
                          : Colors.grey,
                      inactiveColor: Helpers.checkIfEditableByJobStatus(
                                  selectedJob,
                                  (selectedJob?.isMainEngineer ?? true)) &&
                              !isStepper
                          ? Colors.red
                          : Colors.grey,
                      activeTextColor: Colors.white,
                      inactiveTextColor: Colors.white,
                      activeText: "Discount added",
                      inactiveText: "Discount removed",
                      value: isDiscountApplied,
                      valueFontSize: 14.0,
                      width: MediaQuery.of(context).size.width * 0.225,
                      borderRadius: 30.0,
                      showOnOff: true,
                      onToggle: (val) async {
                        if (Helpers.checkIfEditableByJobStatus(selectedJob,
                                (selectedJob?.isMainEngineer ?? true)) &&
                            !isStepper) {
                          var result = await Repositories.updateChargeable(
                              selectedJob!.serviceRequestid ?? "0",
                              isChargeablePickupCharges,
                              isChargeableTransportCharges,
                              isChargeableSolutionCharges,
                              isChargeableMiscellaneousCharges,
                              !isDiscountApplied,
                              (selectedJob?.chargeableSparepartIds ?? []));

                          await refreshJobDetails();
                        }
                      },
                    )
                  : new Container(),
            ],
          ),
          const SizedBox(height: 40),
          ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * .2,
                  minHeight: MediaQuery.of(context).size.height * .1),
              child: Container(
                child: ListView(
                  children: [
                    rcpCost?.sparePartCost != "MYR 0.00"
                        ? _buildChargeItem("Picklist charges (Estimated)",
                            rcpCost?.pickListCost ?? "MYR 0.00", false)
                        : new Container(),
                    rcpCost?.sparePartCost != "MYR 0.00" &&
                            (selectedJob?.aggregatedSpareparts?.length ?? 0) > 0
                        ? _buildChargeItem("Sparepart charges",
                            rcpCost?.sparePartCost ?? "MYR 0.00", false)
                        : new Container(),
                    rcpCost?.solutionCost != "MYR 0.00"
                        ? _buildChargeItem("Solution charges",
                            rcpCost?.solutionCost ?? "MYR 0.00", false)
                        : new Container(),
                    rcpCost?.miscCost != "MYR 0.00"
                        ? _buildChargeItem("Miscellaneous charges",
                            rcpCost?.miscCost ?? "MYR 0.00", false)
                        : new Container(),
                    rcpCost?.transportCost != "MYR 0.00"
                        ? _buildChargeItem("Transport charges",
                            rcpCost?.transportCost ?? "MYR 0.00", false)
                        : new Container(),
                    rcpCost?.pickupCost != "MYR 0.00"
                        ? _buildChargeItem("Pickup charges",
                            rcpCost?.pickupCost ?? "MYR 0.00", false)
                        : new Container(),
                    rcpCost?.totalSSTRCP != "MYR 0.00"
                        ? _buildChargeItem("Total SST",
                            rcpCost?.totalSSTRCP ?? "MYR 0.00", false)
                        : new Container(),
                    SizedBox(
                      height: 5,
                    ),
                    _buildChargeItem(
                        (rcpCost?.isDiscountValid ?? false) &&
                                rcpCost?.discountPercentage != "0%"
                            ? "Total"
                            : "Grand Total",
                        'MYR ${((rcpCost?.totalAmount ?? 0) + (rcpCost?.totalAmountSST ?? 0)).toStringAsFixed(2)}',
                        true),
                    (rcpCost?.isDiscountValid ?? false) &&
                            rcpCost?.discountPercentage != "0%"
                        ? _buildChargeItem(
                            '${rcpCost?.discountPercentage} Discount applied',
                            rcpCost?.discount ?? "MYR 0.00",
                            true)
                        : new Container(),
                    (rcpCost?.isDiscountValid ?? false) &&
                            rcpCost?.discountPercentage != "0%"
                        ? Divider()
                        : new Container(),
                    (rcpCost?.isDiscountValid ?? false) &&
                            rcpCost?.discountPercentage != "0%"
                        ? _buildChargeItem(
                            "Grand Total",
                            'MYR ${((rcpCost?.totalAmountRCP ?? 0) + (rcpCost?.totalAmountSSTRCP ?? 0)).toStringAsFixed(2)}',
                            true)
                        : new Container(),
                  ],
                ),
              ))
        ]));
  }

  Widget _renderPartsList(bool isStepper) {
    return Column(
      children: [
        Row(
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.black,
                ),
                children: <TextSpan>[
                  const TextSpan(
                    text: 'Job Bag',
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(
          height: 5,
        ),
        (selectedJob?.aggregatedSpareparts != null &&
                    (selectedJob?.aggregatedSpareparts!.length ?? 0) > 0) &&
                Helpers.checkIfEditableByJobStatus(
                    selectedJob, (selectedJob?.isMainEngineer ?? true)) &&
                !isStepper
            ? Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  (!isPartsEditable &&
                          selectedJob?.serviceJobStatus != "COMPLETED")
                      ? ElevatedButton(
                          child: const Padding(
                              padding: EdgeInsets.all(0.0),
                              child: Text(
                                'Edit',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.white),
                              )),
                          style: ButtonStyle(
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  Color(0xFF242A38)),
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Color(0xFF242A38)),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                      side: const BorderSide(
                                          color: Color(0xFF242A38))))),
                          onPressed: () {
                            setState(() {
                              Helpers.editableJobSpareParts = [];
                              var arr = SparePart.cloneArray(
                                  selectedJob?.aggregatedSpareparts ?? []);
                              Helpers.editableJobSpareParts.addAll(arr);
                              isPartsEditable = true;
                            });
                          })
                      : new Container(),
                  isPartsEditable
                      ? ElevatedButton(
                          child: const Padding(
                              padding: EdgeInsets.all(0.0),
                              child: Text(
                                'Save Changes',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.white),
                              )),
                          style: ButtonStyle(
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  Color(0xFF242A38)),
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Color(0xFF242A38)),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                      side: const BorderSide(
                                          color: Color(0xFF242A38))))),
                          onPressed: () async {
                            var arr = Helpers?.editableJobSpareParts;
                            var brr = selectedJob?.aggregatedSpareparts;
                            await removeItemsBasedOnPriority(
                                Helpers.editableJobSpareParts);
                            setState(() {
                              isPartsEditable = false;
                            });
                            await refreshJobDetails();
                          })
                      : new Container(),
                  isPartsEditable
                      ? SizedBox(
                          width: 30,
                        )
                      : new Container(),
                  isPartsEditable
                      ? ElevatedButton(
                          child: const Padding(
                              padding: EdgeInsets.all(0.0),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.white),
                              )),
                          style: ButtonStyle(
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  Color(0xFF242A38)),
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Color(0xFF242A38)),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                      side: const BorderSide(
                                          color: Color(0xFF242A38))))),
                          onPressed: () async {
                            await refreshJobDetails();
                            setState(() {
                              isPartsEditable = false;
                            });
                          })
                      : new Container(),
                ],
              )
            : new Container(),
        SizedBox(
          height: 5,
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: (selectedJob?.aggregatedSpareparts?.length ?? 0) > 0 &&
                  rcpCost != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * .58,
                          minHeight: MediaQuery.of(context).size.height * .09),
                      child: ListView.builder(
                        // physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        // shrinkWrap: false,
                        itemCount: selectedJob?.aggregatedSpareparts?.length,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (BuildContext context, int index) {
                          return AddPartItem(
                              isDiscountApplied: isDiscountApplied,
                              isStepper: isStepper,
                              rcpCost: rcpCost,
                              width: MediaQuery.of(context).size.width * 0.5,
                              key: ValueKey(index),
                              part: (selectedJob!.aggregatedSpareparts!
                                  .elementAt(index)),
                              isChargeable: !(selectedJob
                                      ?.chargeableSparepartIds
                                      ?.contains(selectedJob
                                          ?.aggregatedSpareparts?[index].id
                                          .toString()) ??
                                  false),
                              onChargeablePressed:
                                  (int id, bool chargeable) async {
                                List<String> ids = [];
                                ids.addAll(
                                    selectedJob?.chargeableSparepartIds ?? []);

                                if (chargeable) {
                                  ids.remove(id.toString());
                                } else {
                                  ids.add(id.toString());
                                }
                                var result =
                                    await Repositories.updateChargeable(
                                        selectedJob!.serviceRequestid ?? "0",
                                        isChargeablePickupCharges,
                                        isChargeableTransportCharges,
                                        isChargeableSolutionCharges,
                                        isChargeableMiscellaneousCharges,
                                        isDiscountApplied,
                                        ids);

                                await refreshJobDetails();
                              },
                              index: index,
                              jobId: (selectedJob!.serviceRequestid ?? ""),
                              editable: isPartsEditable,
                              partList:
                                  (selectedJob!.aggregatedSpareparts ?? []),
                              onDeletePressed: (id) async {
                                var arr = Helpers?.editableJobSpareParts;

                                Helpers.editableJobSpareParts
                                    .removeWhere((element) => element.id == id);

                                await removeItemsBasedOnPriority(
                                    Helpers.editableJobSpareParts);
                                Navigator.pop(context);
                                await refreshJobDetails();

                                setState(() {
                                  isPartsEditable = false;
                                });
                              },
                              job: selectedJob ?? new Job());
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            SizedBox(
                              height: 50,
                            ),
                            Icon(
                              Icons.indeterminate_check_box,
                              color: Colors.grey,
                              size: 130.0,
                            ),
                            RichText(
                              text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 30.0,
                                    color: Colors.black,
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: 'No data found',
                                    ),
                                  ]),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Container(
                              alignment: Alignment.center,
                              width: 400,
                              child: RichText(
                                text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 15.0,
                                      color: Colors.black,
                                    ),
                                    children: <TextSpan>[
                                      TextSpan(
                                        text:
                                            'There is currently no parts listed selected.',
                                      ),
                                    ]),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                          ],
                        ))
                  ],
                ),
        )
      ],
    );
  }

  Widget _renderMiscItems(bool isStepper) {
    return Column(
      children: [
        Row(
          children: [
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.black,
                ),
                children: <TextSpan>[
                  const TextSpan(
                    text: 'Miscellaneous',
                  ),
                ],
              ),
            ),
            Spacer(),
            FlutterSwitch(
              activeColor: Helpers.checkIfEditableByJobStatus(
                          selectedJob, (selectedJob?.isMainEngineer ?? true)) &&
                      !isStepper
                  ? Colors.green
                  : Colors.grey,
              inactiveColor: Helpers.checkIfEditableByJobStatus(
                          selectedJob, (selectedJob?.isMainEngineer ?? true)) &&
                      !isStepper
                  ? Colors.red
                  : Colors.grey,
              activeTextColor: Colors.white,
              inactiveTextColor: Colors.white,
              activeText: "Chargeable",
              inactiveText: "Not Chargeable",
              value: isChargeableMiscellaneousCharges,
              valueFontSize: 14.0,
              width: 150,
              borderRadius: 30.0,
              showOnOff: true,
              onToggle: (val) async {
                if (Helpers.checkIfEditableByJobStatus(
                        selectedJob, (selectedJob?.isMainEngineer ?? true)) &&
                    !isStepper) {
                  var result = await Repositories.updateChargeable(
                      selectedJob!.serviceRequestid ?? "0",
                      isChargeablePickupCharges,
                      isChargeableTransportCharges,
                      isChargeableSolutionCharges,
                      !isChargeableMiscellaneousCharges,
                      isDiscountApplied,
                      (selectedJob?.chargeableSparepartIds ?? []));

                  await refreshJobDetails();
                }
              },
            ),
          ],
        ),
        SizedBox(
          height: 5,
        ),
        (selectedJob?.miscCharges != null &&
                    (selectedJob?.miscCharges!.length ?? 0) > 0) &&
                Helpers.checkIfEditableByJobStatus(
                    selectedJob, (selectedJob?.isMainEngineer ?? true)) &&
                !isStepper
            ? Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  (!isMiscItemsEditable &&
                          selectedJob?.serviceJobStatus != "COMPLETED")
                      ? ElevatedButton(
                          child: const Padding(
                              padding: EdgeInsets.all(0.0),
                              child: Text(
                                'Edit',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.white),
                              )),
                          style: ButtonStyle(
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  Color(0xFF242A38)),
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Color(0xFF242A38)),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                      side: const BorderSide(
                                          color: Color(0xFF242A38))))),
                          onPressed: () => {
                                setState(() {
                                  isMiscItemsEditable = true;
                                })
                              })
                      : new Container(),
                  isMiscItemsEditable
                      ? ElevatedButton(
                          child: const Padding(
                              padding: EdgeInsets.all(0.0),
                              child: Text(
                                'Save Changes',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.white),
                              )),
                          style: ButtonStyle(
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  Color(0xFF242A38)),
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Color(0xFF242A38)),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                      side: const BorderSide(
                                          color: Color(0xFF242A38))))),
                          onPressed: () async {
                            bool isError = false;
                            var abc = Helpers.editableMiscItems;
                            var abcdd = await Repositories.updateMiscItems(
                                selectedJob?.serviceRequestid ?? "",
                                Helpers.editableMiscItems);
                            setState(() {
                              isMiscItemsEditable = false;
                            });
                            await refreshJobDetails();
                          })
                      : new Container(),
                  isMiscItemsEditable
                      ? SizedBox(
                          width: 30,
                        )
                      : new Container(),
                  isMiscItemsEditable
                      ? ElevatedButton(
                          child: const Padding(
                              padding: EdgeInsets.all(0.0),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.white),
                              )),
                          style: ButtonStyle(
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  Color(0xFF242A38)),
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Color(0xFF242A38)),
                              shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                      side: const BorderSide(
                                          color: Color(0xFF242A38))))),
                          onPressed: () async {
                            await refreshJobDetails();
                            setState(() {
                              isMiscItemsEditable = false;
                            });
                          })
                      : new Container(),
                ],
              )
            : new Container(),
        SizedBox(
          height: 45,
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: (selectedJob?.miscCharges?.length ?? 0) > 0
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * .58,
                          minHeight: MediaQuery.of(context).size.height * .07),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: selectedJob?.miscCharges?.length,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (BuildContext context, int index) {
                          return MiscItem(
                              width: MediaQuery.of(context).size.width * 0.5,
                              miscItem:
                                  (selectedJob!.miscCharges!.elementAt(index)),
                              index: index,
                              jobId: (selectedJob!.serviceRequestid ?? ""),
                              editable: (isMiscItemsEditable &&
                                      Helpers.checkIfEditableByJobStatus(
                                          selectedJob,
                                          (selectedJob?.isMainEngineer ??
                                                  true) &&
                                              !isStepper))
                                  ? true
                                  : false,
                              partList:
                                  (selectedJob!.aggregatedSpareparts ?? []),
                              onDeletePressed: (miscChargeId) async {
                                var res = await Repositories.deleteMiscItem(
                                    jobId, miscChargeId);
                                await refreshJobDetails();
                              },
                              job: selectedJob ?? new Job());
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          alignment: Alignment.centerLeft,
                          child: new Container(),
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: new Container(),
                        ),
                      ],
                    )
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            SizedBox(
                              height: 50,
                            ),
                            Icon(
                              Icons.indeterminate_check_box,
                              color: Colors.grey,
                              size: 130.0,
                            ),
                            RichText(
                              text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 30.0,
                                    color: Colors.black,
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: 'No data found',
                                    ),
                                  ]),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Container(
                              alignment: Alignment.center,
                              width: 400,
                              child: RichText(
                                text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 15.0,
                                      color: Colors.black,
                                    ),
                                    children: <TextSpan>[
                                      TextSpan(
                                        text:
                                            'There is currently no parts listed selected.',
                                      ),
                                    ]),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Helpers.checkIfEditableByJobStatus(
                                        selectedJob,
                                        (selectedJob?.isMainEngineer ??
                                            true)) &&
                                    !isStepper
                                ? ElevatedButton(
                                    child: const Padding(
                                        padding: EdgeInsets.all(0.0),
                                        child: Text(
                                          'Add Parts',
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.white),
                                        )),
                                    style: ButtonStyle(
                                        foregroundColor: MaterialStateProperty.all<Color>(
                                            Color(0xFF242A38)),
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Color(0xFF242A38)),
                                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                            RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4.0),
                                                side: const BorderSide(
                                                    color: Color(0xFF242A38))))),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AddMiscItemsPopup(newItemAdded:
                                              (String remarks, int quantity,
                                                  String charges) async {
                                            var res =
                                                await Repositories.addMiscItem(
                                                        selectedJob
                                                                ?.serviceRequestid ??
                                                            "",
                                                        remarks,
                                                        double.parse(charges),
                                                        quantity,
                                                        null)
                                                    .then((value) {
                                              Navigator.pop(context);
                                            });
                                            await refreshJobDetails();
                                          });
                                        },
                                      );
                                    })
                                : new Container(),
                          ],
                        ))
                  ],
                ),
        ),
        Helpers.checkIfEditableByJobStatus(
                    selectedJob, (selectedJob?.isMainEngineer ?? true)) &&
                !isStepper &&
                (selectedJob?.miscCharges?.length ?? 0) > 0
            ? Container(
                alignment: Alignment.centerLeft,
                child: selectedJob?.serviceJobStatus != "COMPLETED"
                    ? ElevatedButton(
                        child: Padding(
                            padding: EdgeInsets.all(0.0),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(
                                Icons.add_circle,
                                size: 18,
                                color: Colors.white,
                              ),
                              SizedBox(
                                width: 5,
                              ),
                              Text(
                                'Add More Parts',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.white),
                              )
                            ])),
                        style: ButtonStyle(
                            foregroundColor: MaterialStateProperty.all<Color>(
                                Color(0xFF242A38)),
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Color(0xFF242A38)),
                            shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4.0),
                                    side: const BorderSide(
                                        color: Color(0xFF242A38))))),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AddMiscItemsPopup(newItemAdded:
                                  (String remarks, int quantity,
                                      String charges) async {
                                var res = await Repositories.addMiscItem(
                                        selectedJob?.serviceRequestid ?? "",
                                        remarks,
                                        double.parse(charges),
                                        quantity,
                                        null)
                                    .then((value) {
                                  Navigator.pop(context);
                                });
                                //show error if error
                                await refreshJobDetails();
                              });
                            },
                          );
                        })
                    : new Container(),
              )
            : new Container(),
      ],
    );
  }

  Widget _renderTransportCharges(bool isStepper) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            RichText(
              text: const TextSpan(
                  style: TextStyle(
                    fontSize: 20.0,
                    color: Colors.black,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Transport Charges',
                    ),
                  ]),
            ),
            Spacer(),
            FlutterSwitch(
              activeColor: Helpers.checkIfEditableByJobStatus(
                          selectedJob, (selectedJob?.isMainEngineer ?? true)) &&
                      !isStepper
                  ? Colors.green
                  : Colors.grey,
              inactiveColor: Helpers.checkIfEditableByJobStatus(
                          selectedJob, (selectedJob?.isMainEngineer ?? true)) &&
                      !isStepper
                  ? Colors.red
                  : Colors.grey,
              activeTextColor: Colors.white,
              inactiveTextColor: Colors.white,
              activeText: "Chargeable",
              inactiveText: "Not Chargeable",
              value: isChargeableTransportCharges,
              valueFontSize: 14.0,
              width: 150,
              borderRadius: 30.0,
              showOnOff: true,
              onToggle: (val) async {
                if (Helpers.checkIfEditableByJobStatus(
                        selectedJob, (selectedJob?.isMainEngineer ?? true)) &&
                    !isStepper) {
                  var result = await Repositories.updateChargeable(
                      selectedJob!.serviceRequestid ?? "0",
                      isChargeablePickupCharges,
                      !isChargeableTransportCharges,
                      isChargeableSolutionCharges,
                      isChargeableMiscellaneousCharges,
                      isDiscountApplied,
                      (selectedJob?.chargeableSparepartIds ?? []));
                  await refreshJobDetails();
                }
              },
            ),
          ]),
          allTransportCharges == null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                      Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 30,
                            ),
                            Container(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: LoadingAnimationWidget.staggeredDotsWave(
                                  color: Color(0xFF000000),
                                  size:
                                      MediaQuery.of(context).size.height * 0.03,
                                ),
                              ),
                            )
                          ])
                    ])
              : Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 25),
                    SizedBox(height: 10),
                    (isNewTransportCharge ||
                                selectedJob?.transportCharge != null) &&
                            Helpers.checkIfEditableByJobStatus(selectedJob,
                                (selectedJob?.isMainEngineer ?? true)) &&
                            !isStepper
                        ? DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: selectedJob?.transportCharge?.description,
                            items: allTransportCharges
                                ?.map((TransportCharge value) {
                              return DropdownMenuItem<String>(
                                value: value.description,
                                child: Text(value.description ?? ""),
                              );
                            }).toList(),
                            onChanged: (element) async {
                              var index = allTransportCharges
                                  ?.map((e) => e.description)
                                  .toList()
                                  .indexOf(element.toString());
                              var res =
                                  await Repositories.addTransportChargesToJob(
                                selectedJob!.serviceRequestid ?? "0",
                                selectedJob?.productModelId ?? 0,
                                allTransportCharges?[index ?? 0].id ?? 0,
                              );
                              await refreshJobDetails();
                            },
                            decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 7, horizontal: 3),
                                border: OutlineInputBorder(
                                  borderRadius: const BorderRadius.all(
                                    const Radius.circular(5.0),
                                  ),
                                ),
                                filled: true,
                                hintStyle: TextStyle(color: Colors.grey[800]),
                                hintText: "Please Select a Solution",
                                fillColor: Colors.white),
                            //value: dropDownValue,
                          )
                        : Helpers.checkIfEditableByJobStatus(selectedJob,
                                    (selectedJob?.isMainEngineer ?? true)) &&
                                !isStepper
                            ? DropdownButtonFormField<String>(
                                isExpanded: true,
                                items: allTransportCharges
                                    ?.map((TransportCharge value) {
                                  return DropdownMenuItem<String>(
                                    child: Text(value.description ?? ""),
                                    value: value.description ?? "",
                                  );
                                }).toList(),
                                onChanged: (element) async {
                                  var index = allTransportCharges
                                      ?.map((e) => e.description)
                                      .toList()
                                      .indexOf(element.toString());
                                  var res = await Repositories
                                      .addTransportChargesToJob(
                                    selectedJob!.serviceRequestid ?? "0",
                                    selectedJob?.productModelId ?? 0,
                                    allTransportCharges?[index ?? 0].id ?? 0,
                                  );
                                  await refreshJobDetails();
                                },
                                decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 7, horizontal: 3),
                                    border: OutlineInputBorder(
                                      borderRadius: const BorderRadius.all(
                                        const Radius.circular(5.0),
                                      ),
                                    ),
                                    filled: true,
                                    hintStyle:
                                        TextStyle(color: Colors.grey[800]),
                                    hintText: "Please Select Transport charges",
                                    fillColor: Colors.white),
                                //value: dropDownValue,
                              )
                            : new Container(),
                    SizedBox(height: 20),
                    (isNewTransportCharge ||
                            selectedJob?.transportCharge != null)
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    selectedJob?.transportCharge != null
                                        ? RichText(
                                            text: const TextSpan(
                                              style: TextStyle(
                                                fontSize: 12.0,
                                                color: Colors.black54,
                                              ),
                                              children: <TextSpan>[
                                                const TextSpan(
                                                  text: 'CHARGE CODE',
                                                ),
                                              ],
                                            ),
                                          )
                                        : new Container(),
                                    selectedJob?.transportCharge != null
                                        ? SizedBox(
                                            height: 5,
                                          )
                                        : new Container(),
                                    selectedJob?.transportCharge != null
                                        ? RichText(
                                            text: TextSpan(
                                              style: TextStyle(
                                                fontSize: 14.0,
                                                color: Colors.black,
                                              ),
                                              children: <TextSpan>[
                                                TextSpan(
                                                  text: selectedJob
                                                      ?.transportCharge?.code,
                                                ),
                                              ],
                                            ),
                                          )
                                        : new Container(),
                                  ],
                                ),
                              ),
                              Container(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    selectedJob?.transportCharge != null
                                        ? RichText(
                                            text: const TextSpan(
                                              style: TextStyle(
                                                fontSize: 12.0,
                                                color: Colors.black54,
                                              ),
                                              children: <TextSpan>[
                                                const TextSpan(
                                                  text: 'CHARGE',
                                                ),
                                              ],
                                            ),
                                          )
                                        : new Container(),
                                    selectedJob?.transportCharge != null
                                        ? SizedBox(
                                            height: 5,
                                          )
                                        : new Container(),
                                    selectedJob?.transportCharge != null
                                        ? RichText(
                                            text: TextSpan(
                                              style: TextStyle(
                                                fontSize: 14.0,
                                                color: Colors.black,
                                              ),
                                              children: <TextSpan>[
                                                TextSpan(
                                                  text: selectedJob
                                                      ?.transportCharge
                                                      ?.description
                                                      ?.trim(),
                                                ),
                                              ],
                                            ),
                                          )
                                        : new Container(),
                                  ],
                                ),
                              ),
                              Container(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    selectedJob?.transportCharge != null
                                        ? RichText(
                                            text: const TextSpan(
                                              style: TextStyle(
                                                fontSize: 12.0,
                                                color: Colors.black54,
                                              ),
                                              children: <TextSpan>[
                                                const TextSpan(
                                                  text: 'COST',
                                                ),
                                              ],
                                            ),
                                          )
                                        : new Container(),
                                    selectedJob?.transportCharge != null
                                        ? SizedBox(
                                            height: 5,
                                          )
                                        : new Container(),
                                    selectedJob?.transportCharge != null
                                        ? RichText(
                                            text: TextSpan(
                                              style: TextStyle(
                                                fontSize: 14.0,
                                                color: Colors.black,
                                              ),
                                              children: <TextSpan>[
                                                TextSpan(
                                                  text: selectedJob
                                                      ?.transportCharge
                                                      ?.priceFormatted,
                                                ),
                                              ],
                                            ),
                                          )
                                        : new Container(),
                                  ],
                                ),
                              ),
                              Container(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    selectedJob?.transportCharge != null
                                        ? RichText(
                                            text: const TextSpan(
                                              style: TextStyle(
                                                fontSize: 12.0,
                                                color: Colors.black54,
                                              ),
                                              children: <TextSpan>[
                                                const TextSpan(
                                                  text: 'COST (Incl. SST)',
                                                ),
                                              ],
                                            ),
                                          )
                                        : new Container(),
                                    selectedJob?.transportCharge != null
                                        ? SizedBox(
                                            height: 5,
                                          )
                                        : new Container(),
                                    selectedJob?.transportCharge != null
                                        ? RichText(
                                            text: TextSpan(
                                              style: TextStyle(
                                                fontSize: 14.0,
                                                color: Colors.black,
                                              ),
                                              children: <TextSpan>[
                                                TextSpan(
                                                  text:
                                                      'MYR ${selectedJob?.transportCharge?.lineTotal?.toStringAsFixed(2).trim()}',
                                                ),
                                              ],
                                            ),
                                          )
                                        : new Container(),
                                  ],
                                ),
                              ),
                              Helpers.checkIfEditableByJobStatus(
                                          selectedJob,
                                          (selectedJob?.isMainEngineer ??
                                              true)) &&
                                      !isStepper
                                  ? SizedBox(
                                      width: 70,
                                      height: 40.0,
                                      child: ElevatedButton(
                                          child: const Padding(
                                              padding: EdgeInsets.all(0.0),
                                              child: Text(
                                                'Clear',
                                                style: TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.white),
                                              )),
                                          style: ButtonStyle(
                                              foregroundColor:
                                                  MaterialStateProperty.all<Color>(
                                                      Color(0xFF242A38)),
                                              backgroundColor:
                                                  MaterialStateProperty.all<Color>(
                                                      Color(0xFF242A38)),
                                              shape: MaterialStateProperty.all<
                                                      RoundedRectangleBorder>(
                                                  RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(
                                                          4.0),
                                                      side: const BorderSide(
                                                          color: Color(0xFF242A38))))),
                                          onPressed: () async {
                                            await Repositories
                                                .addTransportChargesToJob(
                                                    selectedJob!
                                                            .serviceRequestid ??
                                                        "0",
                                                    (selectedJob
                                                            ?.productModelId ??
                                                        0),
                                                    null);

                                            await refreshJobDetails();
                                          }),
                                    )
                                  : new Container(),
                            ],
                          )
                        : new Container(),
                  ],
                ),
        ]);
  }

  Widget _renderPickupCharges(bool isStepper) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          RichText(
            text: const TextSpan(
                style: TextStyle(
                  fontSize: 20.0,
                  color: Colors.black,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: 'Pickup Charges',
                  ),
                ]),
          ),
          Spacer(),
          FlutterSwitch(
            activeColor: ((Helpers.checkIfEditableByJobStatus(
                        selectedJob, (selectedJob?.isMainEngineer ?? true)) &&
                    !isStepper)
                ? Colors.green
                : Colors.grey),
            inactiveColor: ((Helpers.checkIfEditableByJobStatus(
                        selectedJob, (selectedJob?.isMainEngineer ?? true)) &&
                    !isStepper)
                ? Colors.red
                : Colors.grey),
            activeTextColor: Colors.white,
            inactiveTextColor: Colors.white,
            activeText: "Chargeable",
            inactiveText: "Not Chargeable",
            value: isChargeablePickupCharges,
            valueFontSize: 14.0,
            width: 150,
            borderRadius: 30.0,
            showOnOff: true,
            onToggle: (val) async {
              if (Helpers.checkIfEditableByJobStatus(
                      selectedJob, (selectedJob?.isMainEngineer ?? true)) &&
                  !isStepper) {
                var result = await Repositories.updateChargeable(
                    selectedJob!.serviceRequestid ?? "0",
                    !isChargeablePickupCharges,
                    isChargeableTransportCharges,
                    isChargeableSolutionCharges,
                    isChargeableMiscellaneousCharges,
                    isDiscountApplied,
                    (selectedJob?.chargeableSparepartIds ?? []));

                await refreshJobDetails();
              }
            },
          ),
        ]),
        allPickupCharges == null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                    Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 30,
                          ),
                          Container(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: LoadingAnimationWidget.staggeredDotsWave(
                                color: Color(0xFF000000),
                                size: MediaQuery.of(context).size.height * 0.03,
                              ),
                            ),
                          )
                        ])
                  ])
            : Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  selectedJob?.pickupCharge != null &&
                          Helpers.checkIfEditableByJobStatus(selectedJob,
                              (selectedJob?.isMainEngineer ?? true)) &&
                          !isStepper
                      ? DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: selectedJob != null
                              ? selectedJob?.pickupCharge?.pickupDescription
                              : allPickupCharges != null
                                  ? (allPickupCharges ?? [])[0]
                                      .pickupDescription
                                  : "",
                          items: allPickupCharges?.map((PickupCharge? value) {
                            return DropdownMenuItem<String>(
                              value: value?.pickupDescription.toString(),
                              child: Text(value?.pickupDescription ?? ""),
                            );
                          }).toList(),
                          onChanged: (element) async {
                            var index = allPickupCharges
                                ?.map((e) => e.pickupDescription)
                                .toList()
                                .indexOf(element.toString());
                            var res = await Repositories.addPickupCharges(
                              selectedJob!.serviceRequestid ?? "0",
                              allPickupCharges?[index ?? 0].id ?? 0,
                            );
                            await refreshJobDetails();
                          },
                          decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 7, horizontal: 3),
                              border: OutlineInputBorder(
                                borderRadius: const BorderRadius.all(
                                  const Radius.circular(5.0),
                                ),
                              ),
                              filled: true,
                              hintStyle: TextStyle(color: Colors.grey[800]),
                              hintText: "Please Select a Pickup charge type",
                              fillColor: Colors.white),
                        )
                      : Helpers.checkIfEditableByJobStatus(selectedJob,
                                  (selectedJob?.isMainEngineer ?? true)) &&
                              !isStepper
                          ? DropdownButtonFormField<String>(
                              isExpanded: true,

                              items:
                                  allPickupCharges?.map((PickupCharge? value) {
                                return DropdownMenuItem<String>(
                                  value: value?.pickupDescription.toString(),
                                  child: Text(value?.pickupDescription ?? ""),
                                );
                              }).toList(),
                              onChanged: (element) async {
                                var index = allPickupCharges
                                    ?.map((e) => e.pickupDescription)
                                    .toList()
                                    .indexOf(element.toString());
                                var res = await Repositories.addPickupCharges(
                                  selectedJob!.serviceRequestid ?? "0",
                                  allPickupCharges?[index ?? 0].id ?? 0,
                                );
                                await refreshJobDetails();
                              },
                              decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 7, horizontal: 3),
                                  border: OutlineInputBorder(
                                    borderRadius: const BorderRadius.all(
                                      const Radius.circular(5.0),
                                    ),
                                  ),
                                  filled: true,
                                  hintStyle: TextStyle(color: Colors.grey[800]),
                                  hintText:
                                      "Please Select a Pickup charge type",
                                  fillColor: Colors.white),
                              //value: dropDownValue,
                            )
                          : new Container(),
                  SizedBox(height: 20),
                  selectedJob?.pickupCharge != null
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  selectedJob?.pickupCharge != null
                                      ? RichText(
                                          text: const TextSpan(
                                            style: TextStyle(
                                              fontSize: 12.0,
                                              color: Colors.black54,
                                            ),
                                            children: <TextSpan>[
                                              const TextSpan(
                                                text: 'CHARGE CODE',
                                              ),
                                            ],
                                          ),
                                        )
                                      : new Container(),
                                  selectedJob?.pickupCharge != null
                                      ? SizedBox(
                                          height: 5,
                                        )
                                      : new Container(),
                                  selectedJob?.pickupCharge != null
                                      ? RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              color: Colors.black,
                                            ),
                                            children: <TextSpan>[
                                              TextSpan(
                                                text: selectedJob
                                                    ?.pickupCharge?.code,
                                              ),
                                            ],
                                          ),
                                        )
                                      : new Container(),
                                ],
                              ),
                            ),
                            Container(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  selectedJob?.pickupCharge != null
                                      ? RichText(
                                          text: const TextSpan(
                                            style: TextStyle(
                                              fontSize: 12.0,
                                              color: Colors.black54,
                                            ),
                                            children: <TextSpan>[
                                              const TextSpan(
                                                text: 'CHARGE',
                                              ),
                                            ],
                                          ),
                                        )
                                      : new Container(),
                                  selectedJob?.pickupCharge != null
                                      ? SizedBox(
                                          height: 5,
                                        )
                                      : new Container(),
                                  selectedJob?.pickupCharge != null
                                      ? RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              color: Colors.black,
                                            ),
                                            children: <TextSpan>[
                                              TextSpan(
                                                text: selectedJob?.pickupCharge
                                                    ?.pickupDescription,
                                              ),
                                            ],
                                          ),
                                        )
                                      : new Container(),
                                ],
                              ),
                            ),
                            Container(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  selectedJob?.pickupCharge != null
                                      ? RichText(
                                          text: const TextSpan(
                                            style: TextStyle(
                                              fontSize: 12.0,
                                              color: Colors.black54,
                                            ),
                                            children: <TextSpan>[
                                              const TextSpan(
                                                text: 'COST',
                                              ),
                                            ],
                                          ),
                                        )
                                      : new Container(),
                                  selectedJob?.pickupCharge != null
                                      ? SizedBox(
                                          height: 5,
                                        )
                                      : new Container(),
                                  selectedJob?.pickupCharge != null
                                      ? RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              color: Colors.black,
                                            ),
                                            children: <TextSpan>[
                                              TextSpan(
                                                text: selectedJob?.pickupCharge
                                                    ?.priceFormatted,
                                              ),
                                            ],
                                          ),
                                        )
                                      : new Container(),
                                ],
                              ),
                            ),
                            Container(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  selectedJob?.pickupCharge != null
                                      ? RichText(
                                          text: const TextSpan(
                                            style: TextStyle(
                                              fontSize: 12.0,
                                              color: Colors.black54,
                                            ),
                                            children: <TextSpan>[
                                              const TextSpan(
                                                text: 'COST (Incl. SST)',
                                              ),
                                            ],
                                          ),
                                        )
                                      : new Container(),
                                  selectedJob?.pickupCharge != null
                                      ? SizedBox(
                                          height: 5,
                                        )
                                      : new Container(),
                                  selectedJob?.pickupCharge != null
                                      ? RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              color: Colors.black,
                                            ),
                                            children: <TextSpan>[
                                              TextSpan(
                                                text:
                                                    ' MYR ${selectedJob?.pickupCharge?.lineTotal?.toStringAsFixed(2)}',
                                              ),
                                            ],
                                          ),
                                        )
                                      : new Container(),
                                ],
                              ),
                            ),
                            selectedJob?.pickupCharge != null &&
                                    Helpers.checkIfEditableByJobStatus(
                                        selectedJob,
                                        (selectedJob?.isMainEngineer ??
                                            true)) &&
                                    !isStepper
                                ? SizedBox(
                                    width: 70,
                                    height: 40.0,
                                    child: ElevatedButton(
                                        child: const Padding(
                                            padding: EdgeInsets.all(0.0),
                                            child: Text(
                                              'Clear',
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.white),
                                            )),
                                        style: ButtonStyle(
                                            foregroundColor:
                                                MaterialStateProperty.all<Color>(
                                                    Color(0xFF242A38)),
                                            backgroundColor:
                                                MaterialStateProperty.all<Color>(
                                                    Color(0xFF242A38)),
                                            shape: MaterialStateProperty.all<
                                                    RoundedRectangleBorder>(
                                                RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(
                                                        4.0),
                                                    side: const BorderSide(
                                                        color: Color(0xFF242A38))))),
                                        onPressed: () async {
                                          await Repositories.addPickupCharges(
                                              selectedJob!.serviceRequestid ??
                                                  "0",
                                              null);
                                          await refreshJobDetails();
                                        }),
                                  )
                                : new Container(),
                          ],
                        )
                      : new Container(),
                ],
              ),
      ],
    );
  }

  showMultipleImagesPromptDialog(
      BuildContext context,
      bool initial,
      bool isKIV,
      bool isComplete,
      bool isCancel,
      bool isStart,
      bool isReject,
      bool isClose) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return MultiImageUploadDialog(
            isKiv: isKIV,
            isCancel: isCancel,
            isComplete: isComplete,
            isReject: isReject,
            isClose: isClose,
            isStart: isStart,
            reasonId: (isKIV
                    ? selectedKIVReason
                    : (isReject
                        ? selectedRejectReason
                        : selectedCancellationReason)) ??
                0,
            selectedJob: selectedJob ?? new Job());
      },
    ).then((value) async {
      if (isComplete) {
        await refreshJobDetails();

        if (selectedJob?.serviceJobStatus?.toLowerCase() != "repairing") {
          if (selectedJob?.serviceType?.toLowerCase() == "home visit") {
            Navigator.pushNamed(context, 'signature',
                arguments: [selectedJob, rcpCost]).then((val) async {});
          } else {
            Navigator.pushNamed(context, 'feedback_confirmation',
                    arguments: selectedJob)
                .then((value) => null);
            await refreshJobDetails();
          }
        } else {
          Helpers.showAlert(context,
              hasAction: true,
              title: "Could not complete the Job",
              type: "error", onPressed: () async {
            Navigator.pop(context);
            await refreshJobDetails();
          });
        }
      } else {
        await refreshJobDetails();
      }
    });
  }

  _renderError() {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      // SizedBox(height: 10),
      const SizedBox(height: 20),
    ]);
  }

  Future<bool> _onWillPop() async {
    if (isExpanded) {
      setState(() {
        isExpanded = false;
      });
      return false;
    } else {
      var res = validateIfEditedValuesAreSaved();
      if (res) {
        return true;
      } else {
        return false;
      }
    }
  }

  refreshJobDetails() async {
    await fetchJobDetails();
    await fetchRCPCost();
  }

  fetchBag(String? selected) async {
    BagMetaData? res = await Repositories.fetchUserBag(selected ?? "");

    if (mounted) {
      setState(() {
        userBag = res;
      });
    }
  }

  Future<void> fetchRCPCost() async {
    RCPCost? res = await Repositories.fetchPaymentRCP(
        selectedJob!.serviceRequestid ?? "0",
        isChargeablePickupCharges,
        isChargeableTransportCharges,
        isChargeableSolutionCharges,
        isChargeableMiscellaneousCharges,
        isDiscountApplied,
        (selectedJob?.chargeableSparepartIds ?? []));

    if (mounted) {
      setState(() {
        rcpCost = res;
      });
    }
  }

  Future<void> fetchJobDetails() async {
    if (mounted) {
      Helpers.showAlert(context);
    }
    Job? job = await Repositories.fetchJobDetails(jobId: jobId);
    if (mounted) {
      Navigator.pop(context);
    }

    if (job?.secondaryEngineers != null &&
        job?.secondaryEngineers?.length != 0) {
      var urls = job?.secondaryEngineers?.map((e) => e.profileImage).toList();

      if (mounted) {
        setState(() {
          imageUrls = urls ?? [];
        });
      }
    }

    if (mounted) {
      setState(() {
        selectedJob = job;
        Helpers.editableMiscItems = job?.miscCharges ?? [];
        Helpers.editableJobSpareParts = [];
        var arr = SparePart.cloneArray(selectedJob?.aggregatedSpareparts ?? []);
        Helpers.editableJobSpareParts.addAll(arr);
        isChargeableTransportCharges =
            selectedJob?.isChargeableTransport ?? false;
        isChargeablePickupCharges = selectedJob?.isChargeablePickup ?? false;
        isChargeableSolutionCharges =
            selectedJob?.isChargeableSolution ?? false;
        isChargeableMiscellaneousCharges =
            selectedJob?.isChargeableMisc ?? false;
        isDiscountApplied = selectedJob?.isDiscountApplied ?? false;
        tabController = TabController(
          initialIndex: 0,
          length: selectedJob?.serviceJobStatus?.toLowerCase() ==
                  "pending job start"
              ? 1
              : 2,
          vsync: this,
        );
      });
    }

    await fetchBag(jobId);
  }

  Future<void> fetchJobHistory() async {
    List<Job>? history =
        await Repositories.fetchJobHistory(selectedJob?.serviceRequestid ?? "");

    if (mounted) {
      setState(() {
        jobHistory = history ?? [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onWillPop,
        child: RefreshIndicator(
            key: _refreshKey,
            onRefresh: () async {
              await this.refreshJobDetails();
            },
            child: Scaffold(
                backgroundColor: Colors.white,
                key: _scaffoldKey,
                appBar: Helpers.customAppBar(context, _scaffoldKey,
                    title: "Job Details",
                    isBack: true,
                    isAppBarTranparent: true,
                    hasActions: false, handleBackPressed: () {
                  Navigator.pop(context);
                }),
                body: ExpandableBottomSheet(
                  key: key,
                  onIsContractedCallback: () => print('contracted'),
                  onIsExtendedCallback: () => print('extended'),
                  animationDurationExtend: Duration(milliseconds: 500),
                  animationDurationContract: Duration(milliseconds: 250),
                  animationCurveContract: Curves.ease,
                  persistentContentHeight:
                      isExpanded ? MediaQuery.of(context).size.height * .8 : 0,
                  background: Stack(children: [
                    CustomPaint(
                        child: Stack(children: [
                      SingleChildScrollView(
                          controller: _scrollController,
                          primary: false,
                          physics: AlwaysScrollableScrollPhysics(),
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 10),
                              decoration:
                                  new BoxDecoration(color: Colors.white),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    errorMsg != ""
                                        ? _renderError()
                                        : Container(),
                                    _renderForm(),
                                    const SizedBox(height: 10),
                                  ]))),
                    ])),
                    isExpanded
                        ? GestureDetector(
                            onTap: () {
                              setState(() {
                                isExpanded = false;
                              });
                            },
                            child: IgnorePointer(
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                                child: Container(
                                  width: 200.0,
                                  height: 200.0,
                                  color: Colors.transparent,
                                  child: Center(
                                    child: Text(
                                      'Blurred Content',
                                      style: TextStyle(
                                        fontSize: 20.0,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ))
                        : new Container(),
                  ]),
                  expandableContent: isExpanded
                      ? Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            border:
                                Border.all(color: Colors.grey[400]!, width: 1),
                            color: Colors.white,
                          ),
                          width: MediaQuery.of(context).size.width * 1,
                          child: SingleChildScrollView(
                            child: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 30),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    checklistAttachments != null &&
                                            checklistAttachments.length > 0
                                        ? Container(
                                            alignment: Alignment.centerLeft,
                                            child: RichText(
                                              text: TextSpan(
                                                  style: const TextStyle(
                                                    fontSize: 20.0,
                                                    color: Colors.black,
                                                  ),
                                                  children: <TextSpan>[
                                                    TextSpan(
                                                        text:
                                                            'Checklist Attachment',
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                  ]),
                                            ),
                                          )
                                        : new Container(),
                                    checklistAttachments != null &&
                                            checklistAttachments.length > 0
                                        ? SizedBox(
                                            height: 25,
                                          )
                                        : new Container(),
                                    Container(
                                        alignment: Alignment.centerLeft,
                                        child: checklistAttachments != null &&
                                                checklistAttachments.length > 0
                                            ? DataTable(
                                                headingRowHeight: 50.0,
                                                dataRowHeight: 80,
                                                headingRowColor:
                                                    MaterialStateColor
                                                        .resolveWith((states) =>
                                                            Colors.black87),
                                                columns: [
                                                  DataColumn(
                                                      label: Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            .05,
                                                    child: Padding(
                                                        padding:
                                                            EdgeInsets.fromLTRB(
                                                                10, 0, 0, 0),
                                                        child: Text('#',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white))),
                                                  )),
                                                  DataColumn(
                                                      label: Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            .4,
                                                    child: Padding(
                                                        padding:
                                                            EdgeInsets.fromLTRB(
                                                                10, 0, 0, 0),
                                                        child: Text('Question',
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white))),
                                                  )),
                                                  DataColumn(
                                                      label: Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            .3,
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.fromLTRB(
                                                              10, 0, 0, 0),
                                                      child: Text('Answer',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white)),
                                                    ),
                                                  )),
                                                ],
                                                rows:
                                                    checklistAttachments // Loops through dataColumnText, each iteration assigning the value to element
                                                        .map(
                                                          ((element) => DataRow(
                                                                cells: <
                                                                    DataCell>[
                                                                  DataCell(Text((checklistAttachments.indexOf(element) +
                                                                              1)
                                                                          .toString() ??
                                                                      "1")), //Extracting from Map element the value
                                                                  DataCell(Text(
                                                                      element.question ??
                                                                          "")),
                                                                  DataCell(Text(
                                                                      (element.answer ??
                                                                          "")))
                                                                ],
                                                              )),
                                                        )
                                                        .toList())
                                            : new Container()),
                                    SizedBox(
                                      height: 20,
                                    ),
                                    Container(
                                      alignment: Alignment.centerLeft,
                                      child: RichText(
                                        textAlign: TextAlign.left,
                                        text: TextSpan(
                                            style: const TextStyle(
                                              fontSize: 20.0,
                                              color: Colors.black,
                                            ),
                                            children: <TextSpan>[
                                              TextSpan(
                                                  text: 'Comments',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ]),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 20,
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        border: Border.all(
                                            color: Colors.grey[400]!, width: 1),
                                        color: Colors.white,
                                      ),
                                      alignment: Alignment.centerLeft,
                                      child: Column(children: [
                                        Container(
                                            padding: EdgeInsets.fromLTRB(
                                                20, 0, 20, 0),
                                            child: TextFormField(
                                              controller: commentTextController,
                                              maxLines: 5,
                                              textInputAction:
                                                  TextInputAction.newline,
                                              // focusNode: focusEmail,
                                              keyboardType:
                                                  TextInputType.multiline,
                                              validator: (value) {},
                                              // controller: emailCT,
                                              onFieldSubmitted: (val) {
                                                FocusScope.of(context)
                                                    .requestFocus(
                                                        new FocusNode());
                                              },
                                              style: TextStyle(fontSize: 15),
                                            )),
                                        Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 10),
                                            child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Container(
                                                    color: Colors.white,
                                                    height: 40,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.1,
                                                    child: ElevatedButton(
                                                        child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(5.0),
                                                            child: Text(
                                                              'Send',
                                                              style: TextStyle(
                                                                  fontSize: 11,
                                                                  color: Colors
                                                                      .white),
                                                            )),
                                                        style: ButtonStyle(
                                                            foregroundColor:
                                                                MaterialStateProperty
                                                                    .all<Color>(
                                                          Color(0xFF),
                                                        )),
                                                        onPressed: () async {
                                                          await Repositories
                                                              .addComment(
                                                                  jobId,
                                                                  commentTextController
                                                                      .text
                                                                      .toString());
                                                          setState(() {
                                                            commentTextController
                                                                .text = "";
                                                          });
                                                          await fetchComments();
                                                        }),
                                                  )
                                                ])),
                                      ]),
                                    ),
                                    SizedBox(
                                      height: 20,
                                    ),
                                    comments != null && comments.length > 0
                                        ? SizedBox(
                                            width: double.infinity,
                                            height: 50.0,
                                            child: ElevatedButton(
                                                child: Padding(
                                                    padding:
                                                        EdgeInsets.all(0.0),
                                                    child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons.refresh,
                                                            size: 25,
                                                            color: Color(
                                                                0xFFE18549),
                                                          ),
                                                          SizedBox(
                                                            width: 10,
                                                          ),
                                                          Text(
                                                            'Refresh Comments',
                                                            style: TextStyle(
                                                                fontSize: 18,
                                                                color: Color(
                                                                    0xFFE18549)),
                                                          )
                                                        ])),
                                                style: ButtonStyle(
                                                    foregroundColor:
                                                        MaterialStateProperty.all<Color>(
                                                            Color(0xFFF5DFD0)),
                                                    backgroundColor:
                                                        MaterialStateProperty.all<Color>(
                                                            Color(0xFFF5DFD0)),
                                                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(4.0),
                                                            side: const BorderSide(color: Color(0xFFF5DFD0))))),
                                                onPressed: () async {}),
                                          )
                                        : new Container(),
                                    comments != null && comments.length > 0
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.8,
                                            child: ListView.builder(
                                              shrinkWrap: false,
                                              // shrinkWrap: false,
                                              itemCount: comments.length,
                                              itemBuilder:
                                                  (BuildContext context,
                                                      int index) {
                                                return CommentItem(
                                                  focusNodes: commentFocusNodes,
                                                  ctx: context,
                                                  // textEditingControllers:
                                                  //     commentTextEditingControllers,
                                                  comments: comments,
                                                  loggedInUserId:
                                                      loggedInUserId ?? "",
                                                  index: index,
                                                  isCurrentSelectedindex:
                                                      currentlyEditingCommentIndex,
                                                  onDeletePressed:
                                                      (index) async {
                                                    var res = await Repositories
                                                        .deleteComment(
                                                            comments[index]
                                                                    .id ??
                                                                0);
                                                    await fetchComments();
                                                  },
                                                  onUpdate: (index) async {
                                                    setState(() {
                                                      commentFocusNodes
                                                          .forEach((element) {
                                                        element.unfocus();
                                                      });
                                                      currentlyEditingCommentIndex =
                                                          null;
                                                    });
                                                    await fetchComments();
                                                  },
                                                  onEditPressed: (index) {
                                                    setState(() {
                                                      commentFocusNodes
                                                          .forEach((element) {
                                                        element.unfocus();
                                                      });
                                                      currentlyEditingCommentIndex =
                                                          index;
                                                      commentFocusNodes[index]
                                                          .requestFocus();
                                                    });
                                                  },
                                                );
                                              },
                                            ),
                                          )
                                        : new Container(),
                                  ]),
                            ),
                          ),
                        )
                      : new Container(),
                ),
                floatingActionButton:
                    (!isExpanded && (selectedJob?.isRTOOrder ?? false)
                        ? FloatingActionButton.large(
                            onPressed: () {
                              setState(() {
                                isExpanded = true;
                              });
                            },
                            foregroundColor: Color(0xFF005FF5),
                            backgroundColor: Color(0xFFFDFDFD),
                            child: const Icon(Icons.chat_outlined),
                          )
                        : new Container()))));
  }
}

Widget _buildChargeItem(String chargeType, String cost, bool isTotal) {
  return Padding(
      padding: EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(chargeType,
              style: TextStyle(
                  fontSize: 16.0,
                  color: isTotal ? Colors.black : Colors.black54)),
          Text(cost,
              style: TextStyle(
                  fontSize: 16.0,
                  color: isTotal ? Colors.black : Colors.black54)),
        ],
      ));
}
