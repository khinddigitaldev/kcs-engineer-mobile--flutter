import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:after_layout/after_layout.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:expandable_bottom_sheet/expandable_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kcs_engineer/model/bag.dart';
import 'package:kcs_engineer/model/checklistAttachment.dart';
import 'package:kcs_engineer/model/comment.dart';
import 'package:kcs_engineer/model/job.dart';
import 'package:kcs_engineer/model/miscellaneousItem.dart';
import 'package:kcs_engineer/model/pickup_charges.dart';
import 'package:kcs_engineer/model/problem.dart';
import 'package:kcs_engineer/model/rcpCost.dart';
import 'package:kcs_engineer/model/reason.dart';
import 'package:kcs_engineer/model/solution.dart';
import 'package:kcs_engineer/model/sparepart.dart';
import 'package:kcs_engineer/model/transportCharge.dart';
import 'package:kcs_engineer/util/components/add_items_bag.dart';
import 'package:kcs_engineer/util/full_screen_image.dart';
import 'package:kcs_engineer/util/helpers.dart';
import 'package:kcs_engineer/util/key.dart';
import 'package:kcs_engineer/util/repositories.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:readmore/readmore.dart';
import 'package:url_launcher/url_launcher.dart';

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

  bool isLoading = false;
  bool isSerialNoEditable = false;
  bool isRemarksEditable = false;
  bool isAdminRemarksEditable = false;
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
  @override
  FutureOr<void> afterFirstLayout(BuildContext context) async {
    jobId = widget.id ?? "";

    await fetchJobDetails();
    await fetchRCPCost();
    await fetchTransportCharges();
    await fetchPickUpCharges();
    await fetchCancellationReasons();
    await fetchRejecReasons();

    if (solutionLabels.length == 0 && selectedJob != null) {
      fetchSolutionsByProduct();
    }
    if (problemLabels.length == 0) {
      fetchProblems();
    }
    await fetchKIVReasons();
    await fetchJobHistory();
    await fetchChecklistAttachments();
    await fetchComments();
    loggedInUserId = await storage.read(key: USERID);

    if (selectedJob != null && mounted) {
      setState(() {
        serialNoController.text = selectedJob?.serialNo ?? "-";
        remarksController.text = selectedJob?.remarks ?? "";
        adminRemarksController.text = selectedJob?.adminRemarks ?? "";
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

  fetchKIVReasons() async {
    isLoading = true;
    var reasons = await Repositories.fetchKIVReasons();
    isLoading = false;

    if (mounted) {
      setState(() {
        KIVReasons = reasons;
      });
    }
  }

  fetchTransportCharges() async {
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

  fetchPickUpCharges() async {
    isLoading = true;
    var pickupCharges = await Repositories.fetchPickListCharges();
    isLoading = false;
    if (mounted) {
      setState(() {
        allPickupCharges = pickupCharges;
      });
    }
  }

  bool checkActionsEnabled(String action) {
    List<String> res = [];

    switch (selectedJob?.serviceJobStatus?.toLowerCase()) {
      case "pending job start":
        res.addAll(["cancel", "reject", "kiv", "start"]);
        break;
      case "repairing":
        res.addAll(["kiv", "complete"]);
        break;
      case "kiv":
        res.addAll(["complete"]);
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

    if (solutionLabels.length == 0 && selectedJob != null) {
      fetchSolutionsByProduct();
    }

    if (problemLabels.length == 0) {
      fetchProblems();
    }

    _loadVersion();
    //_loadToken();
    //_checkPermisions();
  }

  fetchChecklistAttachments() async {
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

  fetchComments() async {
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

  void fetchSolutionsByProduct() async {
    solutions = await Repositories.fetchSolutions(
        selectedJob?.productId.toString() ?? "",
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

  void fetchProblems() async {
    problems = await Repositories.fetchProblems();

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

  void fetchCurrentPrice() async {
    problems = await Repositories.fetchProblems();

    problems.forEach((element) {
      problemLabels.add(element.problem ?? "");
    });

    if (mounted) {
      setState(() {
        problemLabels = problemLabels;
      });
    }
  }

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
                                    });
                                  },
                                  enabled: true,
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
                            ],
                          ),
                          const SizedBox(
                            width: 30,
                          ),
                          Helpers.checkIfEditableByJobStatus(selectedJob)
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
                          child: new Container()

                          // RichText(
                          //   //textAlign: TextAlign.justify,
                          //   text: TextSpan(
                          //       style: TextStyle(
                          //         fontSize: 15.0,
                          //         color: Colors.black54,
                          //       ),
                          //       children: <TextSpan>[
                          //         TextSpan(
                          //           text: selectedJob?.serviceAddressPostcode,
                          //         ),
                          //       ]),
                          // ),
                          ),
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
                                // Note: Styles for TextSpans must be explicitly defined.
                                // Child text spans will inherit styles from parent
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
                                              // Note: Styles for TextSpans must be explicitly defined.
                                              // Child text spans will inherit styles from parent
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
                                              // Note: Styles for TextSpans must be explicitly defined.
                                              // Child text spans will inherit styles from parent
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
                                      // Note: Styles for TextSpans must be explicitly defined.
                                      // Child text spans will inherit styles from parent
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
                                // Note: Styles for TextSpans must be explicitly defined.
                                // Child text spans will inherit styles from parent
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
                                // Note: Styles for TextSpans must be explicitly defined.
                                // Child text spans will inherit styles from parent
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
                                  // Note: Styles for TextSpans must be explicitly defined.
                                  // Child text spans will inherit styles from parent
                                  style: TextStyle(
                                    fontSize: 15.0,
                                    color: Colors.black54,
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                        text: '${selectedJob?.paymentMethods}')

                                    //  ((selectedJob
                                    //                 ?.paymentMethod !=
                                    //             null &&
                                    //         (selectedJob?.paymentMethod
                                    //                 ?.isNotEmpty ??
                                    //             false))
                                    //     ? selectedJob?.paymentMethod
                                    //         ?.reduce((value, element) =>
                                    //             value +
                                    //             (element != ""
                                    //                 ? " & "
                                    //                 : "") +
                                    //             element)
                                    //     : "-")),
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
                              // Note: Styles for TextSpans must be explicitly defined.
                              // Child text spans will inherit styles from parent
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
                              // Note: Styles for TextSpans must be explicitly defined.
                              // Child text spans will inherit styles from parent
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
                              // Note: Styles for TextSpans must be explicitly defined.
                              // Child text spans will inherit styles from parent
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
                              // Note: Styles for TextSpans must be explicitly defined.
                              // Child text spans will inherit styles from parent
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
                                // Note: Styles for TextSpans must be explicitly defined.
                                // Child text spans will inherit styles from parent
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
                      // Helpers.checkIfEditableByJobStatus(selectedJob)
                      //     ? GestureDetector(
                      //         onTap: () async {
                      //           if (isRemarksEditable) {
                      //             var res = await Repositories.updateRemarks(
                      //                 selectedJob!.serviceRequestid ?? "0",
                      //                 remarksController.text.toString());
                      //             //TODO
                      //             await refreshJobDetails();
                      //             setState(() {
                      //               isRemarksEditable = false;
                      //             });
                      //             FocusManager.instance.primaryFocus?.unfocus();
                      //           } else {
                      //             setState(() {
                      //               isRemarksEditable = true;
                      //             });

                      //             Future.delayed(Duration.zero, () {
                      //               remarksFocusNode.requestFocus();
                      //             });
                      //           }
                      //         },
                      //         child: isRemarksEditable
                      //             ? Icon(
                      //                 // <-- Icon
                      //                 Icons.check,
                      //                 color: Colors.black54,
                      //                 size: 25.0,
                      //               )
                      //             : Icon(
                      //                 // <-- Icon
                      //                 Icons.edit,
                      //                 color: Colors.black54,
                      //                 size: 25.0,
                      //               ))
                      //     : new Container()
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
                                // Note: Styles for TextSpans must be explicitly defined.
                                // Child text spans will inherit styles from parent
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
                      // Helpers.checkIfEditableByJobStatus(selectedJob)
                      //     ? GestureDetector(
                      //         onTap: () async {
                      //           if (isAdminRemarksEditable) {
                      //             var res =
                      //                 await Repositories.updateAdminRemarks(
                      //                     selectedJob!.serviceRequestid ?? "0",
                      //                     adminRemarksController.text
                      //                         .toString());

                      //             setState(() {
                      //               isAdminRemarksEditable = false;
                      //             });
                      //             FocusManager.instance.primaryFocus?.unfocus();
                      //             await refreshJobDetails();
                      //           } else {
                      //             setState(() {
                      //               isAdminRemarksEditable = true;
                      //             });

                      //             Future.delayed(Duration.zero, () {
                      //               adminRemarksFocusNode.requestFocus();
                      //             });
                      //           }
                      //         },
                      //         child: isAdminRemarksEditable
                      //             ? Icon(
                      //                 // <-- Icon
                      //                 Icons.check,
                      //                 color: Colors.black54,
                      //                 size: 25.0,
                      //               )
                      //             : Icon(
                      //                 // <-- Icon
                      //                 Icons.edit,
                      //                 color: Colors.black54,
                      //                 size: 25.0,
                      //               ))
                      //     : new Container()
                    ],
                  ),
                  // Row(
                  //   //mainAxisAlignment: MainAxisAlignment.spaceAround,
                  //   children: <Widget>[

                  //   ],
                  // ),
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
                                      // Note: Styles for TextSpans must be explicitly defined.
                                      // Child text spans will inherit styles from parent
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
                                      MediaQuery.of(context).size.width * 0.01,
                                ),
                                RichText(
                                  text: TextSpan(
                                      // Note: Styles for TextSpans must be explicitly defined.
                                      // Child text spans will inherit styles from parent
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
                                      MediaQuery.of(context).size.width * 0.01,
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
                                          // Note: Styles for TextSpans must be explicitly defined.
                                          // Child text spans will inherit styles from parent
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
                                  width: 10,
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
                                  width: 10,
                                ),
                                imageUrls.length > 0
                                    ? Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.15,
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
                            width: MediaQuery.of(context).size.width * 0.01,
                          ),
                          RichText(
                            text: TextSpan(
                                // Note: Styles for TextSpans must be explicitly defined.
                                // Child text spans will inherit styles from parent
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
                          // SizedBox(
                          //   width: MediaQuery.of(context).size.width *
                          //       0.15, // <-- match_parent
                          //   height: MediaQuery.of(context).size.width *
                          //       0.05, // <-- match-parent
                          //   child: (selectedJob?.attachments != null &&
                          //           (selectedJob?.attachments?.isNotEmpty ??
                          //               false))
                          //       ? ElevatedButton(
                          //           child: Padding(
                          //               padding: const EdgeInsets.all(0.0),
                          //               child: Row(children: [
                          //                 const Icon(
                          //                   // <-- Icon
                          //                   Icons.image,
                          //                   color: Colors.white,
                          //                   size: 18.0,
                          //                 ),
                          //                 const SizedBox(
                          //                   width: 10,
                          //                 ),
                          //                 const Text(
                          //                   'Media',
                          //                   style: const TextStyle(
                          //                       fontSize: 15,
                          //                       color: Colors.white),
                          //                 )
                          //               ])),
                          //           style: ButtonStyle(
                          //               foregroundColor:
                          //                   MaterialStateProperty.all<Color>(
                          //                       Color(0xFF242A38)),
                          //               backgroundColor:
                          //                   MaterialStateProperty.all<Color>(
                          //                       Color(0xFF242A38)),
                          //               shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          //                   RoundedRectangleBorder(
                          //                       borderRadius:
                          //                           BorderRadius.circular(4.0),
                          //                       side: const BorderSide(
                          //                           color:
                          //                               Color(0xFF242A38))))),
                          //           onPressed: () async {
                          //             setState(() {
                          //               images = [];
                          //               continuePressed = false;
                          //               nextImagePressed = false;
                          //             });
                          //             await showImageViewerPromptDialog(
                          //                 context);
                          //           })
                          //       : new Container(),
                          //),
                        ],
                      ),
                    ),
                  )),
                  Flexible(
                    fit: FlexFit.tight,
                    child: Padding(
                      padding: const EdgeInsets.all(0.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          checkActionsEnabled("cancel")
                              ? SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.25,
                                  height: MediaQuery.of(context).size.width *
                                      0.05, // <-- match-parent
                                  child:
                                      // true
                                      //     ?

                                      ElevatedButton(
                                          child: Padding(
                                              padding:
                                                  const EdgeInsets.all(0.0),
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
                                                        fontSize: 15,
                                                        color: Colors.white),
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
                                                      side: const BorderSide(color: Colors.red)))),
                                          onPressed: () async {
                                            var res =
                                                validateIfEditedValuesAreSaved();

                                            if (res) {
                                              Helpers.showAlert(context,
                                                  title:
                                                      "Are you sure you want to cancel this job?",
                                                  child: Column(children: [
                                                    SizedBox(
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              .03,
                                                    ),
                                                    Container(
                                                        child:
                                                            DropdownButtonFormField<
                                                                String>(
                                                      isExpanded: true,
                                                      items: cancellationReasons
                                                          ?.map((Reason value) {
                                                        return DropdownMenuItem<
                                                            String>(
                                                          value: value.reason,
                                                          child: Text(
                                                              value.reason ??
                                                                  ""),
                                                        );
                                                      }).toList(),
                                                      onChanged:
                                                          (element) async {
                                                        if (isErrorCancellationReason) {
                                                          setState(() {
                                                            isErrorCancellationReason =
                                                                false;
                                                          });
                                                        }

                                                        var index =
                                                            cancellationReasons
                                                                ?.map((e) =>
                                                                    e.reason)
                                                                .toList()
                                                                .indexOf(element
                                                                    .toString());

                                                        setState(() {
                                                          selectedCancellationReason =
                                                              cancellationReasons?[
                                                                      index ??
                                                                          0]
                                                                  .id;
                                                        });
                                                        // var res = Repositories
                                                        //     .cancelJob(selectedJob?.serviceRequestid , );
                                                        // await refreshJobDetails();
                                                      },
                                                      decoration:
                                                          InputDecoration(
                                                              contentPadding:
                                                                  EdgeInsets.symmetric(
                                                                      vertical:
                                                                          7,
                                                                      horizontal:
                                                                          3),
                                                              border:
                                                                  OutlineInputBorder(
                                                                borderRadius:
                                                                    const BorderRadius
                                                                        .all(
                                                                  const Radius
                                                                          .circular(
                                                                      5.0),
                                                                ),
                                                              ),
                                                              filled: true,
                                                              hintStyle: TextStyle(
                                                                  color: Colors
                                                                          .grey[
                                                                      800]),
                                                              hintText:
                                                                  "Please Select a Reason",
                                                              fillColor:
                                                                  Colors.white),
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
                                                if (selectedCancellationReason !=
                                                    null) {
                                                  await pickImage(
                                                          false,
                                                          false,
                                                          true,
                                                          false,
                                                          false,
                                                          false)
                                                      .then((value) =>
                                                          Navigator.pop(
                                                              context));
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

                                                // var result =
                                                //     await Repositories.cancelJob(
                                                //         selectedJob!
                                                //                 .serviceRequestid ??
                                                //             "0");
                                                //

                                                //result
                                                // true  ? Helpers.showAlert(context,
                                                //       hasAction: true,
                                                //       title:
                                                //           "Job has been successfully cancelled ",
                                                //       onPressed: () async {
                                                //       await refreshJobDetails();
                                                //
                                                //     })
                                                //   : Helpers.showAlert(context,
                                                //       hasAction: true,
                                                //       title:
                                                //           "Could not cancel the job",
                                                //       onPressed: () async {
                                                //       await refreshJobDetails();
                                                //
                                                //     });
                                              });
                                            }
                                          })
                                  // : selectedJob?.serviceJobStatus == "IN PROGRESS"
                                  //     ?
                                  // : (selectedJob?.serviceJobStatus == "COMPLETED" && !(selectedJob?.jobOrderHasPayment ?? true))
                                  //     ? ElevatedButton(
                                  //         child: Padding(
                                  //             padding: const EdgeInsets.all(0.0),
                                  //             child: Row(
                                  //               children: [
                                  //                 const Text(
                                  //                   'Complete Payment',
                                  //                   style: TextStyle(
                                  //                       fontSize: 15,
                                  //                       color: Colors.white),
                                  //                 )
                                  //               ],
                                  //             )),
                                  //         style: ButtonStyle(foregroundColor: MaterialStateProperty.all<Color>(Colors.green), backgroundColor: MaterialStateProperty.all<Color>(Colors.green), shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0), side: const BorderSide(color: Colors.green)))),
                                  //         onPressed: () async {
                                  //           var res =
                                  //               validateIfEditedValuesAreSaved();

                                  //           if (res) {
                                  //             Navigator.pushNamed(
                                  //                     context, 'signature',
                                  //                     arguments: selectedJob)
                                  //                 .then((val) async {
                                  //               if ((val as bool)) {
                                  //                 await refreshJobDetails();
                                  //               }
                                  //             });
                                  //           }
                                  //         })
                                  //     : new Container(),
                                  )
                              : new Container(),

                          SizedBox(height: 10),
                          checkActionsEnabled("complete")
                              ? SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      0.2, // <-- match_parent
                                  height: MediaQuery.of(context).size.width *
                                      0.05, // <-- match-parent
                                  child: ElevatedButton(
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
                                                    fontSize: 15,
                                                    color: Colors.white),
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
                                                  side: const BorderSide(color: Colors.green)))),
                                      onPressed: () async {
                                        var res =
                                            validateIfEditedValuesAreSaved();

                                        if (res) {
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
                                              hasCancel: true,
                                              onPressed: () async {
                                            _renderStepper();
                                            // Navigator.pushNamed(
                                            //         context, 'signature',
                                            //         arguments: selectedJob)
                                            //     .then((val) async {
                                            //   if ((val as bool)) {}
                                            // });
                                          });
                                        }
                                      }))
                              : new Container(),
                          checkActionsEnabled("payment") &&
                                  (selectedJob?.serviceType?.toLowerCase() ==
                                      "home visit")
                              ? SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      0.2, // <-- match_parent
                                  height: MediaQuery.of(context).size.width *
                                      0.05, // <-- match-parent
                                  child: ElevatedButton(
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
                                                    fontSize: 15,
                                                    color: Colors.white),
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
                                                  side: const BorderSide(color: Colors.green)))),
                                      onPressed: () async {
                                        Navigator.pushNamed(
                                            context, 'signature', arguments: [
                                          selectedJob,
                                          rcpCost
                                        ]).then((val) async {
                                          if ((val as bool)) {}
                                        });
                                      }))
                              : new Container(),
                          checkActionsEnabled("complete")
                              ? const SizedBox(
                                  height: 10,
                                )
                              : new Container(),
                          checkActionsEnabled("kiv")
                              ? SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      0.15, // <-- match_parent
                                  height: MediaQuery.of(context).size.width *
                                      0.05, // <-- match-parent
                                  child: true
                                      ? ElevatedButton(
                                          child: Padding(
                                              padding:
                                                  const EdgeInsets.all(0.0),
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
                                                const Text(
                                                  'KIV Job',
                                                  style: const TextStyle(
                                                      fontSize: 15,
                                                      color: Colors.white),
                                                )
                                              ])),
                                          style: ButtonStyle(
                                              foregroundColor:
                                                  MaterialStateProperty.all<
                                                      Color>(Colors.lightBlue),
                                              backgroundColor:
                                                  MaterialStateProperty.all<
                                                      Color>(Colors.lightBlue),
                                              shape: MaterialStateProperty.all<
                                                      RoundedRectangleBorder>(
                                                  RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(4.0),
                                                      side: const BorderSide(color: Colors.lightBlue)))),
                                          onPressed: () async {
                                            var res =
                                                validateIfEditedValuesAreSaved();

                                            if (res) {
                                              Helpers.showAlert(context,
                                                  title:
                                                      "Are you sure you want to move this job to KIV?",
                                                  child: Column(children: [
                                                    SizedBox(
                                                      height:
                                                          MediaQuery.of(context)
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
                                                              value.reason ??
                                                                  ""),
                                                        );
                                                      }).toList(),
                                                      onChanged:
                                                          (element) async {
                                                        if (isErrorKIVReason) {
                                                          setState(() {
                                                            isErrorKIVReason =
                                                                false;
                                                          });
                                                        }

                                                        var index = KIVReasons
                                                                ?.map((e) =>
                                                                    e.reason)
                                                            .toList()
                                                            .indexOf(element
                                                                .toString());

                                                        setState(() {
                                                          selectedKIVReason =
                                                              KIVReasons?[
                                                                      index ??
                                                                          0]
                                                                  .id;
                                                        });
                                                        // var res = Repositories
                                                        //     .cancelJob(selectedJob?.serviceRequestid , );
                                                        // await refreshJobDetails();
                                                      },
                                                      decoration:
                                                          InputDecoration(
                                                              contentPadding:
                                                                  EdgeInsets.symmetric(
                                                                      vertical:
                                                                          7,
                                                                      horizontal:
                                                                          3),
                                                              border:
                                                                  OutlineInputBorder(
                                                                borderRadius:
                                                                    const BorderRadius
                                                                        .all(
                                                                  const Radius
                                                                          .circular(
                                                                      5.0),
                                                                ),
                                                              ),
                                                              filled: true,
                                                              hintStyle: TextStyle(
                                                                  color: Colors
                                                                          .grey[
                                                                      800]),
                                                              hintText:
                                                                  "Please Select a Reason",
                                                              fillColor:
                                                                  Colors.white),
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
                                                          Navigator.pop(
                                                              context));
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

                                                // var result =
                                                //     await Repositories.cancelJob(
                                                //         selectedJob!
                                                //                 .serviceRequestid ??
                                                //             "0");
                                                //

                                                //result
                                                // true  ? Helpers.showAlert(context,
                                                //       hasAction: true,
                                                //       title:
                                                //           "Job has been successfully cancelled ",
                                                //       onPressed: () async {
                                                //       await refreshJobDetails();
                                                //
                                                //     })
                                                //   : Helpers.showAlert(context,
                                                //       hasAction: true,
                                                //       title:
                                                //           "Could not cancel the job",
                                                //       onPressed: () async {
                                                //       await refreshJobDetails();
                                                //
                                                //     });
                                              });
                                            }

                                            // if (res) {
                                            //   await pickImage(true, false, false);
                                            // }
                                          })
                                      : new Container(),
                                )
                              : new Container(),
                          SizedBox(height: 10),
                          checkActionsEnabled('reject')
                              ? SizedBox(
                                  width: MediaQuery.of(context).size.width *
                                      0.25, // <-- match_parent
                                  height: MediaQuery.of(context).size.width *
                                      0.05, // <-- match-parent
                                  child: true
                                      ? ElevatedButton(
                                          child: Padding(
                                              padding:
                                                  const EdgeInsets.all(0.0),
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
                                                      fontSize: 15,
                                                      color: Colors.white),
                                                )
                                              ])),
                                          style: ButtonStyle(
                                              foregroundColor:
                                                  MaterialStateProperty.all<
                                                      Color>(Colors.red),
                                              backgroundColor:
                                                  MaterialStateProperty.all<
                                                      Color>(Colors.red),
                                              shape: MaterialStateProperty.all<
                                                      RoundedRectangleBorder>(
                                                  RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(4.0),
                                                      side: const BorderSide(color: Colors.red)))),
                                          onPressed: () async {
                                            var res =
                                                validateIfEditedValuesAreSaved();

                                            if (res) {
                                              Helpers.showAlert(context,
                                                  title:
                                                      "Are you sure you want to reject this job ?",
                                                  child: Column(children: [
                                                    SizedBox(
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              .03,
                                                    ),
                                                    Container(
                                                        child:
                                                            DropdownButtonFormField<
                                                                String>(
                                                      isExpanded: true,
                                                      items: rejectReasons
                                                          ?.map((Reason value) {
                                                        return DropdownMenuItem<
                                                            String>(
                                                          value: value.reason,
                                                          child: Text(
                                                              value.reason ??
                                                                  ""),
                                                        );
                                                      }).toList(),
                                                      onChanged:
                                                          (element) async {
                                                        if (isErrorRejectReason) {
                                                          setState(() {
                                                            isErrorRejectReason =
                                                                false;
                                                          });
                                                        }

                                                        var index = rejectReasons
                                                            ?.map(
                                                                (e) => e.reason)
                                                            .toList()
                                                            .indexOf(element
                                                                .toString());

                                                        setState(() {
                                                          selectedRejectReason =
                                                              rejectReasons?[
                                                                      index ??
                                                                          0]
                                                                  .id;
                                                        });
                                                        var res = Repositories
                                                            .rejectJob(
                                                                selectedJob
                                                                        ?.serviceRequestid ??
                                                                    "",
                                                                selectedRejectReason);
                                                        await refreshJobDetails();
                                                      },
                                                      decoration:
                                                          InputDecoration(
                                                              contentPadding:
                                                                  EdgeInsets.symmetric(
                                                                      vertical:
                                                                          7,
                                                                      horizontal:
                                                                          3),
                                                              border:
                                                                  OutlineInputBorder(
                                                                borderRadius:
                                                                    const BorderRadius
                                                                        .all(
                                                                  const Radius
                                                                          .circular(
                                                                      5.0),
                                                                ),
                                                              ),
                                                              filled: true,
                                                              hintStyle: TextStyle(
                                                                  color: Colors
                                                                          .grey[
                                                                      800]),
                                                              hintText:
                                                                  "Please Select a Reason",
                                                              fillColor:
                                                                  Colors.white),
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
                                                if (selectedRejectReason !=
                                                    null) {
                                                  await Repositories.rejectJob(
                                                          selectedJob
                                                                  ?.serviceRequestid ??
                                                              "",
                                                          selectedRejectReason)
                                                      .then((value) =>
                                                          Navigator.pop(
                                                              context));
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

                                                // var result =
                                                //     await Repositories.cancelJob(
                                                //         selectedJob!
                                                //                 .serviceRequestid ??
                                                //             "0");
                                                //

                                                //result
                                                // true  ? Helpers.showAlert(context,
                                                //       hasAction: true,
                                                //       title:
                                                //           "Job has been successfully cancelled ",
                                                //       onPressed: () async {
                                                //       await refreshJobDetails();
                                                //
                                                //     })
                                                //   : Helpers.showAlert(context,
                                                //       hasAction: true,
                                                //       title:
                                                //           "Could not cancel the job",
                                                //       onPressed: () async {
                                                //       await refreshJobDetails();
                                                //
                                                //     });
                                              });
                                            }

                                            // if (res) {
                                            //   await pickImage(true, false, false);
                                            // }
                                          })
                                      : new Container(),
                                )
                              : new Container(),
                          // SizedBox(height: 10),
                          // SizedBox(
                          //   width: MediaQuery.of(context).size.width *
                          //       0.18, // <-- match_parent
                          //   height: MediaQuery.of(context).size.width *
                          //       0.05, // <-- match-parent
                          //   child: true
                          //       ? ElevatedButton(
                          //           child: Padding(
                          //               padding: const EdgeInsets.all(0.0),
                          //               child: Row(children: [
                          //                 const Icon(
                          //                   // <-- Icon
                          //                   Icons.cancel,
                          //                   color: Colors.white,
                          //                   size: 18.0,
                          //                 ),
                          //                 const SizedBox(
                          //                   width: 10,
                          //                 ),
                          //                 const Text(
                          //                   'Close Job',
                          //                   style: const TextStyle(
                          //                       fontSize: 15,
                          //                       color: Colors.white),
                          //                 )
                          //               ])),
                          //           style: ButtonStyle(
                          //               foregroundColor:
                          //                   MaterialStateProperty.all<Color>(
                          //                       Colors.amber),
                          //               backgroundColor:
                          //                   MaterialStateProperty.all<Color>(
                          //                       Colors.amber),
                          //               shape: MaterialStateProperty.all<
                          //                       RoundedRectangleBorder>(
                          //                   RoundedRectangleBorder(
                          //                       borderRadius:
                          //                           BorderRadius.circular(4.0),
                          //                       side: const BorderSide(
                          //                           color: Colors.amber)))),
                          //           onPressed: () async {
                          //             var res =
                          //                 validateIfEditedValuesAreSaved();

                          //             if (res) {
                          //               Helpers.showAlert(context,
                          //                   title:
                          //                       "Are you sure you want to reject this job ?",
                          //                   child: Column(children: [
                          //                     SizedBox(
                          //                       height: MediaQuery.of(context)
                          //                               .size
                          //                               .height *
                          //                           .03,
                          //                     ),
                          //                     Container(
                          //                         child:
                          //                             DropdownButtonFormField<
                          //                                 String>(
                          //                       isExpanded: true,
                          //                       items: rejectReasons
                          //                           ?.map((Reason value) {
                          //                         return DropdownMenuItem<
                          //                             String>(
                          //                           value: value.reason,
                          //                           child: Text(
                          //                               value.reason ?? ""),
                          //                         );
                          //                       }).toList(),
                          //                       onChanged: (element) async {
                          //                         if (isErrorRejectReason) {
                          //                           setState(() {
                          //                             isErrorRejectReason =
                          //                                 false;
                          //                           });
                          //                         }

                          //                         var index = rejectReasons
                          //                             ?.map((e) => e.reason)
                          //                             .toList()
                          //                             .indexOf(
                          //                                 element.toString());

                          //                         setState(() {
                          //                           selectedRejectReason =
                          //                               rejectReasons?[
                          //                                       index ?? 0]
                          //                                   .id;
                          //                         });
                          //                         // var res = Repositories
                          //                         //     .cancelJob(selectedJob?.serviceRequestid , );
                          //                         // await refreshJobDetails();
                          //                       },
                          //                       decoration: InputDecoration(
                          //                           contentPadding:
                          //                               EdgeInsets.symmetric(
                          //                                   vertical: 7,
                          //                                   horizontal: 3),
                          //                           border: OutlineInputBorder(
                          //                             borderRadius:
                          //                                 const BorderRadius
                          //                                     .all(
                          //                               const Radius.circular(
                          //                                   5.0),
                          //                             ),
                          //                           ),
                          //                           filled: true,
                          //                           hintStyle: TextStyle(
                          //                               color:
                          //                                   Colors.grey[800]),
                          //                           hintText:
                          //                               "Please Select a Reason",
                          //                           fillColor: Colors.white),
                          //                       //value: dropDownValue,
                          //                     )),
                          //                     SizedBox(height: 5),
                          //                   ]),
                          //                   hasAction: true,
                          //                   okTitle: "Yes",
                          //                   noTitle: "No",
                          //                   customImage: Image(
                          //                       image: AssetImage(
                          //                           'assets/images/info.png'),
                          //                       width: 50,
                          //                       height: 50),
                          //                   hasCancel: true,
                          //                   onPressed: () async {
                          //                 if (selectedRejectReason != null) {
                          //                   await pickImage(true, false, false,
                          //                           false, false, false)
                          //                       .then((value) =>
                          //                           Navigator.pop(context));
                          //                 } else {
                          //                   Helpers.showAlert(context,
                          //                       hasAction: true,
                          //                       type: "error",
                          //                       title:
                          //                           "A Reason should be selected",
                          //                       onPressed: () async {
                          //                     Navigator.pop(context);
                          //                   });
                          //                 }

                          //                 // var result =
                          //                 //     await Repositories.cancelJob(
                          //                 //         selectedJob!
                          //                 //                 .serviceRequestid ??
                          //                 //             "0");
                          //                 //

                          //                 //result
                          //                 // true  ? Helpers.showAlert(context,
                          //                 //       hasAction: true,
                          //                 //       title:
                          //                 //           "Job has been successfully cancelled ",
                          //                 //       onPressed: () async {
                          //                 //       await refreshJobDetails();
                          //                 //
                          //                 //     })
                          //                 //   : Helpers.showAlert(context,
                          //                 //       hasAction: true,
                          //                 //       title:
                          //                 //           "Could not cancel the job",
                          //                 //       onPressed: () async {
                          //                 //       await refreshJobDetails();
                          //                 //
                          //                 //     });
                          //               });
                          //             }

                          //             // if (res) {
                          //             //   await pickImage(true, false, false);
                          //             // }
                          //           })
                          //       : new Container(),
                          // ),
                        ],
                      ),
                    ),
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
                                      // Note: Styles for TextSpans must be explicitly defined.
                                      // Child text spans will inherit styles from parent
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
                    isTransportationChargesAvailable
                        ? const Divider()
                        : Container(),
                    isTransportationChargesAvailable
                        ? const SizedBox(height: 20)
                        : const SizedBox(height: 0),
                    isTransportationChargesAvailable
                        ? _renderTransportCharges(false)
                        : new Container(),
                    isTransportationChargesAvailable
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
                        onReorder: ((oldIndex, newIndex) async {
                          // final index =
                          //     newIndex > oldIndex ? newIndex - 1 : newIndex;
                          // final job = Helpers.inProgressJobs.removeAt(oldIndex);
                          // Helpers.inProgressJobs.insert(index, job);
                          //
                          // await updateJobSequence();
                          //
                        }),

                        shrinkWrap: true,
                        // shrinkWrap: false,
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

            if (res) {
              setState(() {
                images = [];
                continuePressed = false;
                nextImagePressed = false;
              });
              await pickImage(false, false, false, false, true, false);
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
            Helpers.checkIfEditableByJobStatusForSolution(
                        isActual, selectedJob) &&
                    !isStepper
                ? SizedBox(height: 30)
                : new Container(),
            (solutionLabels.contains(isActual
                        ? selectedJob?.actualSolutionDescription
                        : selectedJob?.estimatedSolutionDescription) &&
                    Helpers.checkIfEditableByJobStatusForSolution(
                        isActual, selectedJob) &&
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
                          selectedJob?.serviceJobStatus?.toLowerCase() !=
                              "repairing");
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
                            isActual, selectedJob) &&
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
                              selectedJob?.serviceJobStatus?.toLowerCase() !=
                                  "repairing");
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
            Helpers.checkIfEditableByJobStatusForSolution(
                        isActual, selectedJob) &&
                    !isStepper
                ? SizedBox(height: 20)
                : new Container(),
            Container(
                padding: EdgeInsets.only(
                    bottom: Helpers.checkIfEditableByJobStatusForSolution(
                                isActual, selectedJob) &&
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
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                                            ? 'ESTIMATED SOLUTION CODE'
                                            : 'ACTUAL SOLUTION CODE'),
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
                                            ? selectedJob?.actualSolutionCode
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
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                                ? selectedJob?.actualSolutionIndoorCharges
                                : selectedJob
                                    ?.estimatedSolutionIndoorCharges) !=
                            null
                        ? Container(
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
                                        text: 'INDOOR COST',
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
                                                ?.actualSolutionIndoorCharges
                                            : selectedJob
                                                ?.estimatedSolutionIndoorCharges,
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          )
                        : new Container(),
                    (isActual
                                ? selectedJob?.actualSolutionOutdoorCharges
                                : selectedJob
                                    ?.estimatedSolutionOutdoorCharges) !=
                            null
                        ? Container(
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
                                        text: 'OUTDOOR COST',
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
                                                ?.actualSolutionOutdoorCharges
                                            : selectedJob
                                                ?.estimatedSolutionOutdoorCharges,
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          )
                        : new Container(),
                    Helpers.checkIfEditableByJobStatusForSolution(
                                isActual, selectedJob) &&
                            ((isActual
                                    ? selectedJob?.actualSolutionCode
                                    : selectedJob?.estimatedSolutionCode) !=
                                null)
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
                  // Note: Styles for TextSpans must be explicitly defined.
                  // Child text spans will inherit styles from parent
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
              activeColor:
                  Helpers.checkIfEditableByJobStatus(selectedJob) && !isStepper
                      ? Colors.green
                      : Colors.grey,
              inactiveColor:
                  Helpers.checkIfEditableByJobStatus(selectedJob) && !isStepper
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
                if (Helpers.checkIfEditableByJobStatus(selectedJob) &&
                    !isStepper) {
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
          tabController != null
              ? Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(0),
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.03,
                          width: selectedJob?.serviceJobStatus?.toLowerCase() !=
                                  "pending job start"
                              ? MediaQuery.of(context).size.width * 0.5
                              : MediaQuery.of(context).size.width * 0.25,
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
                                selectedJob?.serviceJobStatus?.toLowerCase() !=
                                        "pending job start"
                                    ? [
                                        Tab(
                                          text: "Estimated Solution",
                                        ),
                                        Tab(
                                          text: "Actual Solution",
                                        )
                                      ]
                                    : [
                                        Tab(
                                          text: "Estimated Solution",
                                        ),
                                      ],
                          ),
                        ),
                      ),
                      ConstrainedBox(
                          constraints: BoxConstraints(
                              minWidth: MediaQuery.of(context).size.width * 1,
                              maxWidth: MediaQuery.of(context).size.width * 1,
                              maxHeight:
                                  MediaQuery.of(context).size.height * .12,
                              minHeight:
                                  MediaQuery.of(context).size.height * .1),
                          child: TabBarView(
                              controller: tabController,
                              children: ((selectedJob?.serviceJobStatus
                                          ?.toLowerCase() !=
                                      "pending job start")
                                  ? ([
                                      Container(
                                        child: _renderSolutionComponents(
                                            isStepper, false),
                                      ),
                                      Container(
                                        child: _renderSolutionComponents(
                                            isStepper, true),
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
              // Note: Styles for TextSpans must be explicitly defined.
              // Child text spans will inherit styles from parent
              style: TextStyle(
                fontSize: 20.0,
                color: Colors.black,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: 'Select Problem',
                ),
              ]),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 30),
            (selectedJob?.reportedProblemCode != null ||
                        selectedJob?.reportedProblemDescription != null) &&
                    Helpers.checkIfEditableByJobStatus(selectedJob) &&
                    !isStepper &&
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
                          selectedJob?.serviceJobStatus?.toLowerCase() ==
                              "in-progress");
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
                        hintText: "Please Select a Problem",
                        fillColor: Colors.white),
                    value: problemLabels.contains(
                            selectedJob?.actualProblemDescription != null
                                ? selectedJob?.actualProblemDescription
                                : selectedJob?.reportedProblemDescription)
                        ? selectedJob?.actualProblemDescription != null
                            ? selectedJob?.actualProblemDescription
                            : selectedJob?.reportedProblemDescription
                        : "",
                  )
                : Helpers.checkIfEditableByJobStatus(selectedJob) && !isStepper
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
                              selectedJob?.serviceJobStatus?.toLowerCase() ==
                                  "in-progress");
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
            selectedJob?.reportedProblemCode != null ||
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
                                    text: selectedJob?.actualProblemCode != null
                                        ? selectedJob?.actualProblemCode
                                        : selectedJob?.reportedProblemCode,
                                  ),
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
                                    text: selectedJob?.actualProblemCode != null
                                        ? selectedJob?.actualProblemDescription
                                        : selectedJob
                                            ?.reportedProblemDescription,
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      Helpers.checkIfEditableByJobStatus(selectedJob) &&
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
                                        true);

                                    await refreshJobDetails();
                                  }),
                            )
                          : new Container()
                    ],
                  )
                : new Container(),
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

  Future<bool> deleteItemFromPickList(int id) async {
    List<SparePart> ids = [];

    // var ids = addedSparePartQuantities.map((e) => e.id).toList();

    selectedJob?.picklist?.forEach((element) {
      if (element.id == id) {
        element.quantity = 0;
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
            Helpers.checkIfEditableByJobStatus(selectedJob) &&
                    !isStepper &&
                    (selectedJob?.picklist?.length ?? 0) == 0
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
        (selectedJob?.picklist != null &&
                    (selectedJob?.picklist!.length ?? 0) > 0) &&
                Helpers.checkIfEditableByJobStatus(selectedJob)
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
                            var abc = Helpers.editableMiscItems;
                            print("LALALAL");
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
          child: (selectedJob?.picklist?.length ?? 0) > 0
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
                        itemCount: selectedJob?.picklist?.length,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (BuildContext context, int index) {
                          return PickListItem(
                              width: MediaQuery.of(context).size.width * 0.5,
                              part: (selectedJob!.picklist!.elementAt(index)),
                              index: index,
                              jobId: (selectedJob!.serviceRequestid ?? ""),
                              editable: isPickListPartsEditable ? true : false,
                              partList: (selectedJob!.picklist ?? []),
                              onDeletePressed: (var id) async {
                                await deleteItemFromPickList(id);
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
                      child: (selectedJob?.picklist != null &&
                                  (selectedJob?.picklist!.length ?? 0) > 0) &&
                              Helpers.checkIfEditableByJobStatus(selectedJob) &&
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
                                  shape:
                                      MaterialStateProperty.all<RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4.0),
                                              side: const BorderSide(
                                                  color: Color(0xFF242A38))))),
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
              (rcpCost?.isRCPValid ?? false)
                  ? FlutterSwitch(
                      activeColor:
                          Helpers.checkIfEditableByJobStatus(selectedJob) &&
                                  !isStepper
                              ? Colors.green
                              : Colors.grey,
                      inactiveColor:
                          Helpers.checkIfEditableByJobStatus(selectedJob) &&
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
                        if (Helpers.checkIfEditableByJobStatus(selectedJob) &&
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
                    SizedBox(
                      height: 5,
                    ),
                    _buildChargeItem(
                        "Total", rcpCost?.total ?? "MYR 0.00", true),
                    (rcpCost?.isDiscountValid ?? false)
                        ? _buildChargeItem("10% Discount applied",
                            rcpCost?.discount ?? "MYR 0.00", true)
                        : new Container(),
                    (rcpCost?.isDiscountValid ?? false)
                        ? Divider()
                        : new Container(),
                    (rcpCost?.isDiscountValid ?? false)
                        ? _buildChargeItem("Grand Total",
                            rcpCost?.totalRCP ?? "MYR 0.00", true)
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
        // Row(
        //   children: [
        //     selectedJob != null
        //         ? (true
        //             ? Icon(
        //                 // <-- Icon
        //                 Icons.check_circle,
        //                 color: Colors.green,
        //                 size: 25.0,
        //               )
        //             : Icon(
        //                 // <-- Icon
        //                 Icons.cancel,
        //                 color: Colors.red,
        //                 size: 25.0,
        //               ))
        //         : new Container(),
        //     SizedBox(
        //       width: 5,
        //     ),
        //     // (true)
        //     //     ? RichText(
        //     //         text: const TextSpan(
        //     //             // Note: Styles for TextSpans must be explicitly defined.
        //     //             // Child text spans will inherit styles from parent
        //     //             style: TextStyle(
        //     //               fontSize: 15.0,
        //     //               color: Colors.black,
        //     //             ),
        //     //             children: <TextSpan>[
        //     //               TextSpan(
        //     //                 text: 'Under warranty',
        //     //               ),
        //     //             ]),
        //     //       )
        //     //     : RichText(
        //     //         text: const TextSpan(
        //     //             // Note: Styles for TextSpans must be explicitly defined.
        //     //             // Child text spans will inherit styles from parent
        //     //             style: TextStyle(
        //     //               fontSize: 15.0,
        //     //               color: Colors.black,
        //     //             ),
        //     //             children: <TextSpan>[
        //     //               TextSpan(
        //     //                 text: 'Not under warranty',
        //     //               ),
        //     //             ]),
        //     //       )
        //   ],
        // ),
        SizedBox(
          height: 5,
        ),
        (selectedJob?.aggregatedSpareparts != null &&
                    (selectedJob?.aggregatedSpareparts!.length ?? 0) > 0) &&
                Helpers.checkIfEditableByJobStatus(selectedJob) &&
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
          child: (selectedJob?.aggregatedSpareparts?.length ?? 0) > 0
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
                              isStepper: isStepper,
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
                    // Container(
                    //   alignment: Alignment.centerLeft,
                    //   child: (selectedJob?.aggregatedSpareparts?.length ?? 0) > 0 &&
                    //           Helpers.checkIfEditableByJobStatus(selectedJob) &&
                    //           !isStepper
                    //       ? ElevatedButton(
                    //           child: Padding(
                    //               padding: EdgeInsets.all(0.0),
                    //               child: Row(
                    //                   mainAxisSize: MainAxisSize.min,
                    //                   children: [
                    //                     Icon(
                    //                       Icons.add_circle,
                    //                       size: 18,
                    //                       color: Colors.white,
                    //                     ),
                    //                     SizedBox(
                    //                       width: 5,
                    //                     ),
                    //                     Text(
                    //                       'Add More Parts from Bag',
                    //                       style: TextStyle(
                    //                           fontSize: 15,
                    //                           color: Colors.white),
                    //                     )
                    //                   ])),
                    //           style: ButtonStyle(
                    //               foregroundColor: MaterialStateProperty.all<Color>(
                    //                   Color(0xFF242A38)),
                    //               backgroundColor:
                    //                   MaterialStateProperty.all<Color>(
                    //                       Color(0xFF242A38)),
                    //               shape: MaterialStateProperty.all<
                    //                       RoundedRectangleBorder>(
                    //                   RoundedRectangleBorder(
                    //                       borderRadius:
                    //                           BorderRadius.circular(4.0),
                    //                       side: const BorderSide(
                    //                           color: Color(0xFF242A38))))),
                    //           onPressed: () {

                    //           })
                    //       : new Container(),
                    // ),
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
                            // Helpers.checkIfEditableByJobStatus(selectedJob) &&
                            //         !isStepper
                            //     ? ElevatedButton(
                            //         child: const Padding(
                            //             padding: EdgeInsets.all(0.0),
                            //             child: Text(
                            //               'Add Parts',
                            //               style: TextStyle(
                            //                   fontSize: 15,
                            //                   color: Colors.white),
                            //             )),
                            //         style: ButtonStyle(
                            //             foregroundColor:
                            //                 MaterialStateProperty.all<Color>(
                            //                     Color(0xFF242A38)),
                            //             backgroundColor:
                            //                 MaterialStateProperty.all<Color>(
                            //                     Color(0xFF242A38)),
                            //             shape: MaterialStateProperty.all<
                            //                     RoundedRectangleBorder>(
                            //                 RoundedRectangleBorder(
                            //                     borderRadius:
                            //                         BorderRadius.circular(4.0),
                            //                     side: const BorderSide(
                            //                         color: Color(0xFF242A38))))),
                            //         onPressed: () {
                            //           // Navigator.pushNamed(context, 'warehouse',
                            //           //         arguments: Helpers.selectedJob)
                            //           //     .then((val) async {
                            //           //   await refreshJobDetails();
                            //           // })
                            //           showDialog(
                            //             context: context,
                            //             builder: (BuildContext context) {
                            //               return AddItemsFromBagDialog(
                            //                   bag: userBag,
                            //                   existingJobSpareParts: [],
                            //                   jobId: (selectedJob
                            //                           ?.serviceRequestid ??
                            //                       ""));
                            //             },
                            //           ).then((value) async {
                            //             await refreshJobDetails();
                            //           });
                            //         })
                            //     : new Container(),
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
              activeColor:
                  Helpers.checkIfEditableByJobStatus(selectedJob) && !isStepper
                      ? Colors.green
                      : Colors.grey,
              inactiveColor:
                  Helpers.checkIfEditableByJobStatus(selectedJob) && !isStepper
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
                if (Helpers.checkIfEditableByJobStatus(selectedJob) &&
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
                Helpers.checkIfEditableByJobStatus(selectedJob) &&
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
                            print("LALALAL");
                            // if (isError) {
                            //   showActionEmptyAlert();
                            // } else {
                            //   var res = await this.updateSpareParts();
                            //   await this.refreshJobDetails();
                            //   if (!res) {
                            //     await _renderErrorUpdateValues();
                            //   }
                            //   setState(() {
                            //     isPartsEditable = false;
                            //   });
                            // }
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
                        // physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        // shrinkWrap: false,
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
                                          selectedJob) &&
                                      !isStepper)
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
                            Helpers.checkIfEditableByJobStatus(selectedJob) &&
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
                                            //show error if error
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
        Helpers.checkIfEditableByJobStatus(selectedJob) &&
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
                  // Note: Styles for TextSpans must be explicitly defined.
                  // Child text spans will inherit styles from parent
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
              activeColor:
                  Helpers.checkIfEditableByJobStatus(selectedJob) && !isStepper
                      ? Colors.green
                      : Colors.grey,
              inactiveColor:
                  Helpers.checkIfEditableByJobStatus(selectedJob) && !isStepper
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
                if (Helpers.checkIfEditableByJobStatus(selectedJob) &&
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
                            Helpers.checkIfEditableByJobStatus(selectedJob) &&
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
                        : Helpers.checkIfEditableByJobStatus(selectedJob) &&
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
                                    hintText: "Please Select a Solution",
                                    fillColor: Colors.white),
                                //value: dropDownValue,
                              )
                            : new Container(),
                    SizedBox(height: 20),
                    (isNewTransportCharge ||
                            selectedJob?.transportCharge != null)
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                                  text: 'TRANSPORT CHARGE CODE',
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
                                                  text: 'TRANSPORT CHARGE',
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
                                                      ?.description,
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

                              // Flexible(
                              //   fit: FlexFit.tight,
                              //   child: Padding(
                              //     padding: const EdgeInsets.all(0.0),
                              //     child: Column(
                              //       mainAxisAlignment:
                              //           MainAxisAlignment.spaceAround,
                              //       crossAxisAlignment:
                              //           CrossAxisAlignment.start,
                              //       mainAxisSize: MainAxisSize.min,
                              //       children: [
                              //         true
                              //             ? RichText(
                              //                 text: const TextSpan(
                              //                   style: TextStyle(
                              //                     fontSize: 12.0,
                              //                     color: Colors.black54,
                              //                   ),
                              //                   children: <TextSpan>[
                              //                     const TextSpan(
                              //                       text: 'SOLUTION',
                              //                     ),
                              //                   ],
                              //                 ),
                              //               )
                              //             : new Container(),
                              //         true
                              //             ? SizedBox(
                              //                 height: 5,
                              //               )
                              //             : new Container(),
                              //         true
                              //             ? RichText(
                              //                 text: TextSpan(
                              //                   style: TextStyle(
                              //                     fontSize: 14.0,
                              //                     color: Colors.black,
                              //                   ),
                              //                   children: <TextSpan>[
                              //                     TextSpan(
                              //                       text: "solu",
                              //                     ),
                              //                   ],
                              //                 ),
                              //               )
                              //             : new Container(),
                              //       ],
                              //     ),
                              //   ),
                              // ),
                              SizedBox(
                                width: 50,
                              ),
                              Helpers.checkIfEditableByJobStatus(selectedJob) &&
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
                // Note: Styles for TextSpans must be explicitly defined.
                // Child text spans will inherit styles from parent
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
            activeColor:
                ((Helpers.checkIfEditableByJobStatus(selectedJob) && !isStepper)
                    ? Colors.green
                    : Colors.grey),
            inactiveColor:
                ((Helpers.checkIfEditableByJobStatus(selectedJob) && !isStepper)
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
              if (Helpers.checkIfEditableByJobStatus(selectedJob) &&
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
                          Helpers.checkIfEditableByJobStatus(selectedJob) &&
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
                      : Helpers.checkIfEditableByJobStatus(selectedJob) &&
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
                                                text: 'PICKUP CHARGE CODE',
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
                                                text: 'PICKUP CHARGE',
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
                            selectedJob?.pickupCharge != null &&
                                    Helpers.checkIfEditableByJobStatus(
                                        selectedJob) &&
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

  showImagePrompt() {}

  // showImageViewerPromptDialog(BuildContext context) async {
  //   await showDialog(
  //     context: context,
  //     barrierDismissible: true,
  //     builder: (BuildContext context) {
  //       return ImageViewerDialog(
  //           imgScaffoldKey: _imgScaffoldKey,
  //           attachments: selectedJob?.attachments?.map((key, value) => MapEntry(
  //                   key,
  //                   (value as List).map((item) => item as String).toList())) ??
  //               new Map<String, List<String>>());
  //     },
  //   ).then((value) async {
  //     // if (isComplete) {
  //     //   if (value) {
  //     //     Navigator.pushNamed(context, 'signature', arguments: selectedJob)
  //     //         .then((val) async {
  //     //       if ((val as bool)) {
  //     //
  //     //       }
  //     //     });
  //     //   } else {
  //     //     Helpers.showAlert(context,
  //     //         hasAction: true,
  //     //         title: "Could complete the Job", onPressed: () async {
  //     //       await refreshJobDetails();
  //     //
  //     //     });
  //     //   }
  //     // } else {
  //     //   await this.refreshJobDetails();
  //     // }
  //   });
  // }

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
        if (value != null && value) {
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

  fetchRCPCost() async {
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

  fetchJobDetails() async {
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

    var aa =
        (job?.serviceJobStatus?.toLowerCase() != "pending job start") ? 2 : 1;
    tabController = TabController(
      initialIndex: 0,
      length:
          job?.serviceJobStatus?.toLowerCase() != "pending job start" ? 2 : 1,
      vsync: this,
    );

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
      });
    }

    await fetchBag(jobId);
  }

  fetchJobHistory() async {
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
                  // var res = validateIfEditedValuesAreSaved();
                  // if (res) {
                  // }
                }),
                body: ExpandableBottomSheet(
                  //use the key to get access to expand(), contract() and expansionStatus
                  key: key,

                  onIsContractedCallback: () => print('contracted'),
                  onIsExtendedCallback: () => print('extended'),
                  animationDurationExtend: Duration(milliseconds: 500),
                  animationDurationContract: Duration(milliseconds: 250),
                  // animationCurveExpand: Curves.bounceOut,
                  animationCurveContract: Curves.ease,
                  persistentContentHeight:
                      isExpanded ? MediaQuery.of(context).size.height * .8 : 0,
                  background: Stack(children: [
                    CustomPaint(
                        child: Stack(children: [
                      SingleChildScrollView(
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
                                    //Expanded(child: _renderBottom()),
                                    //version != "" ? _renderVersion() : Container()
                                  ]))),
                      // Positioned(
                      //     left: 5,
                      //     right: 5,
                      //     bottom: 5,
                      //     child: GestureDetector(
                      //       onTap: () {
                      //         setState(() {
                      //           isExpandedTotal = !isExpandedTotal;
                      //         });
                      //       },
                      //       child: Container(
                      //           padding: const EdgeInsets.symmetric(
                      //               horizontal: 20, vertical: 10),
                      //           decoration:
                      //               new BoxDecoration(color: Colors.white),
                      //           child: isExpandedTotal
                      //               ? _renderCost()
                      //               : ListTile(
                      //                   title: Text('Total'),
                      //                   trailing: Text('RM 140.00'),
                      //                 )),
                      //     )),
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

class ImageViewerDialog extends StatefulWidget {
  final Map<String, List<String>> attachments;
  GlobalKey<ScaffoldState> imgScaffoldKey;

  ImageViewerDialog({required this.attachments, required this.imgScaffoldKey});

  @override
  _ImageViewerDialogState createState() => new _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<ImageViewerDialog> {
  List<File> images = [];

  late Map<String, dynamic>? attachments = widget.attachments;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: RichText(
        text: TextSpan(
            style: const TextStyle(
              fontSize: 20.0,
              color: Colors.black,
            ),
            children: <TextSpan>[
              TextSpan(
                  text: 'Media',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
      ),
      content: Container(
        alignment: Alignment.centerLeft,
        height: 800,
        width: 600,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
                alignment: Alignment.centerLeft,
                height: 800,
                width: 600.0,
                child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: attachments?.keys.length,
                    itemBuilder: (BuildContext context, int index) =>
                        Column(children: [
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
                                          text:
                                              attachments?.keys.toList()[index],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ]),
                              )),
                          SizedBox(
                            height: 30,
                          ),
                          Container(
                              alignment: Alignment.centerLeft,
                              height: 150.0,
                              width: 600.0,
                              child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: attachments?[
                                          attachments?.keys.toList()[index]]
                                      .length,
                                  itemBuilder: (BuildContext context,
                                          int subIndex) =>
                                      Row(
                                        children: [
                                          Container(
                                              color: Colors.grey,
                                              child: Stack(
                                                children: <Widget>[
                                                  GestureDetector(
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              Scaffold(
                                                            key: widget
                                                                .imgScaffoldKey,
                                                            backgroundColor:
                                                                Colors.black,
                                                            appBar: Helpers.customAppBar(context,
                                                                widget.imgScaffoldKey,
                                                                title:
                                                                    "Resource Image",
                                                                isBack: true,
                                                                colorsInverted:
                                                                    true,
                                                                isAppBarTranparent:
                                                                    true,
                                                                hasActions:
                                                                    false,
                                                                handleBackPressed:
                                                                    () {
                                                              Navigator.pop(
                                                                  context);
                                                            }),
                                                            body: Center(
                                                              child:
                                                                  ZoomableImage(
                                                                imageUrl: attachments?[
                                                                        attachments
                                                                            ?.keys
                                                                            .toList()[index]]
                                                                    [subIndex],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: Image.network(
                                                        attachments?[attachments
                                                                ?.keys
                                                                .toList()[index]]
                                                            [subIndex],
                                                        fit: BoxFit.cover,
                                                        loadingBuilder:
                                                            (BuildContext
                                                                    context,
                                                                Widget child,
                                                                ImageChunkEvent?
                                                                    loadingProgress) {
                                                      if (loadingProgress ==
                                                          null) return child;
                                                      return Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                          value: loadingProgress
                                                                      .expectedTotalBytes !=
                                                                  null
                                                              ? loadingProgress
                                                                      .cumulativeBytesLoaded /
                                                                  loadingProgress
                                                                      .expectedTotalBytes!
                                                              : null,
                                                        ),
                                                      );
                                                    }),
                                                  ),
                                                ],
                                              )),
                                          SizedBox(
                                            width: 20,
                                          )
                                        ],
                                      ))),
                          SizedBox(
                            height: 30,
                          )
                        ]))),
          ],
        ),
      ),
    );
  }
}

class MultiImageUploadDialog extends StatefulWidget {
  final bool isKiv;
  final bool isCancel;
  final bool isStart;
  final bool isClose;
  final bool isComplete;
  final bool isReject;
  final int reasonId;
  final Job selectedJob;

  MultiImageUploadDialog(
      {required this.isKiv,
      required this.isCancel,
      required this.isComplete,
      required this.isReject,
      required this.isClose,
      required this.isStart,
      required this.reasonId,
      required this.selectedJob});

  @override
  _MultiImageUploadDialogState createState() =>
      new _MultiImageUploadDialogState();
}

class _MultiImageUploadDialogState extends State<MultiImageUploadDialog> {
  List<File> images = [];

  bool nextPressed = false;
  bool continuePressed = false;
  late bool isKiv = widget.isKiv;
  late bool isComplete = widget.isComplete;
  late bool isCancel = widget.isCancel;
  late bool isStart = widget.isStart;
  late bool isReject = widget.isReject;
  late bool isClose = widget.isClose;
  late Job selectedJob = widget.selectedJob;
  bool isImagesEmpty = false;

  processAction(bool isKIV, bool isComplete, bool isCancel, bool isStart,
      bool isReject, bool isClose) async {
    var res;
    if (isKIV) {
      res = await Repositories.uploadKIV(
          images, this.selectedJob!.serviceRequestid ?? "0", widget.reasonId);
    } else if (isCancel) {
      res = await Repositories.cancelJob(
          images, this.selectedJob!.serviceRequestid ?? "0", widget.reasonId);
    } else if (isComplete) {
      res = await Repositories.completeJob(
          images, selectedJob!.serviceRequestid ?? "0", selectedJob);
    } else if (isStart) {
      res = await Repositories.startJob(
          images, selectedJob!.serviceRequestid ?? "0", selectedJob);
    } else if (isReject) {
      // res = await Repositories.rejectJob(
      //     images, selectedJob!.serviceRequestid ?? "0", widget.reasonId);

      // Navigator.pop(context, res);
    } else if (isClose) {
      res = await Repositories.closeJob(
          images, selectedJob!.serviceRequestid ?? "0");
    } else {
      // res = await Repositories.startJob(
      //     images, selectedJob!.serviceRequestid ?? "0");
    }
    Navigator.pop(context, res);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: RichText(
        text: TextSpan(
            style: const TextStyle(
              fontSize: 20.0,
              color: Colors.black,
            ),
            children: <TextSpan>[
              TextSpan(
                  text: 'Image Upload',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
      ),
      content: Container(
        alignment: Alignment.centerLeft,
        height: 320,
        width: 600,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              alignment: Alignment.bottomLeft,
              child: RichText(
                text: TextSpan(
                    style: const TextStyle(
                      fontSize: 17.0,
                      color: Colors.black,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Please select images that you want to upload',
                      ),
                    ]),
              ),
            ),
            SizedBox(
              height: 40,
            ),
            Container(
                alignment: Alignment.centerLeft,
                height: 195.0,
                width: 600.0,
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount:
                        images.length != 3 ? images.length + 1 : images.length,
                    itemBuilder: (BuildContext context, int index) =>
                        (index <= images.length - 1)
                            ? Row(
                                children: [
                                  Container(
                                      height: 195,
                                      width: 150,
                                      color: Colors.grey,
                                      child: Stack(
                                        children: <Widget>[
                                          Image.file(
                                            images[index],
                                            height: 195.0,
                                            width: 150.0,
                                          ),
                                          Align(
                                            alignment: Alignment.topRight,
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  this.images.removeAt(index);
                                                });
                                              },
                                              child: Icon(
                                                Icons.cancel,
                                                color: Colors.red,
                                                size: 35,
                                              ),
                                            ),
                                          )
                                        ],
                                      )),
                                  SizedBox(
                                    width: 20,
                                  )
                                ],
                              )
                            : GestureDetector(
                                onTap: () async {
                                  setState(() {
                                    nextPressed = true;
                                    continuePressed = false;
                                  });
                                  await ImagePicker()
                                      .pickImage(source: ImageSource.camera)
                                      .then((value) async {
                                    if (value != null) {
                                      setState(() {
                                        this.images.add(File(value.path));
                                      });
                                      //showMultipleImagesPromptDialog(context,false,isKIV,isComplete);
                                    }
                                  });
                                },
                                child: Container(
                                  height: 195.0,
                                  width: 150.0,
                                  color: Colors.grey,
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    size: 25,
                                    color: Colors.white,
                                  ),
                                )))),
            isImagesEmpty
                ? SizedBox(
                    height: 40,
                  )
                : new Container(),
            isImagesEmpty
                ? Row(children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    RichText(
                      text: TextSpan(
                          style: const TextStyle(
                            fontSize: 18.0,
                            color: Colors.red,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'You need to add at least 1 Image',
                            ),
                          ]),
                    ),
                  ])
                : new Container()
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: 100,
          height: 50.0,
          child: ElevatedButton(
              child: const Padding(
                  padding: EdgeInsets.all(0.0),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  )),
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
                setState(() {
                  nextPressed = false;
                  continuePressed = false;
                });
                setState(() {
                  images = [];
                });
                Navigator.pop(context);
              }),
        ),
        SizedBox(
          width: 100,
          height: 50.0,
          child: ElevatedButton(
              child: const Padding(
                  padding: EdgeInsets.all(0.0),
                  child: Text(
                    'Continue',
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  )),
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
                if (images.isEmpty) {
                  setState(() => isImagesEmpty = true);
                } else {
                  setState(() {
                    nextPressed = false;
                    continuePressed = true;
                  });
                  await processAction(
                      isKiv, isComplete, isCancel, isStart, isReject, isClose);
                }
              }),
        ),
      ],
    );
  }
}

class AddPartItem extends StatefulWidget {
  double? width;
  SparePart? part;
  bool? isStepper;
  Job? job;
  String? jobId;
  int? index;
  bool? isChargeable;
  Function? onDeletePressed;
  Function? onChargeablePressed;
  bool? editable;
  List<SparePart>? partList;

  AddPartItem(
      {Key? key,
      required this.width,
      required this.part,
      required this.isChargeable,
      required this.job,
      required this.isStepper,
      required this.jobId,
      required this.index,
      required this.onDeletePressed,
      required this.onChargeablePressed,
      required this.editable,
      required this.partList});

  @override
  AddPartItemState createState() => new AddPartItemState();
}

class AddPartItemState extends State<AddPartItem> {
  double? width;
  // SparePart? part;
  // Job? job;
  // String? jobId;
  // int? index;
  // Function? onDeletePressed;
  // Function? onChargeablePressed;
  // List<SparePart>? partList;

  int? selectedQuantity;

  @override
  void initState() {
    super.initState();

    setState(() {
      width = widget.width;

      selectedQuantity = widget.part?.quantity;
    });
  }

  showAlertDialog(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () async {
        await widget.onDeletePressed?.call(widget.part?.id);
      },
    );

    Widget cancelButton = TextButton(
      child: Text("Cancel"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text("Confirm"),
      content: Text("Are you sure to delete the selected spare part ?"),
      actions: [
        cancelButton,
        okButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // var transactionId = this.part.transactionId;
    setState(() {});
    var sparePartId = widget.part?.id;
    var quantity = widget.part?.quantity;
    // var discount = this.part.discount;
    var price = widget.part?.priceFormatted;
    var sparePartCode = widget.part?.code;
    var description = widget.part?.description;

    // var total = (((double.parse(price ?? '0') *
    //         double.parse((quantity != "" ? quantity : "0") ?? "0")) *
    //     (100 - double.parse(discount ?? '0')) /
    //     100));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        widget.job?.serviceJobStatus != "COMPLETED" &&
                (widget.editable ?? false)
            ? Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 40),
                child: GestureDetector(
                    onTap: () async {
                      await showAlertDialog(context);
                    },
                    child: Icon(
                      // <-- Icon
                      Icons.delete,
                      color: Colors.black54,
                      size: 25.0,
                    )),
              )
            : new Container(),
        SizedBox(
          width: 5,
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.25,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                child: RichText(
                  text: TextSpan(
                      style: const TextStyle(
                        fontSize: 15.0,
                        color: Colors.black,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: '$sparePartCode',
                        ),
                      ]),
                ),
              ),
              RichText(
                text: TextSpan(
                    // Note: Styles for TextSpans must be explicitly defined.
                    // Child text spans will inherit styles from parent
                    style: const TextStyle(
                      fontSize: 15.0,
                      color: Colors.black54,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: '$description',
                      ),
                    ]),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 30),
          child: FlutterSwitch(
            activeColor: (Helpers.checkIfEditableByJobStatus(widget.job) &&
                    !(widget.isStepper ?? false))
                ? Colors.green
                : Colors.grey,
            inactiveColor: (Helpers.checkIfEditableByJobStatus(widget.job) &&
                    !(widget.isStepper ?? false))
                ? Colors.red
                : Colors.grey,
            activeTextColor: Colors.white,
            inactiveTextColor: Colors.white,
            activeText: "Chargeable",
            inactiveText: "Not Chargeable",
            value: widget.isChargeable ?? false,
            valueFontSize: 12.0,
            width: MediaQuery.of(context).size.width * 0.2,
            borderRadius: 30.0,
            showOnOff: true,
            onToggle: (val) async {
              if (Helpers.checkIfEditableByJobStatus(widget.job) &&
                  !(widget.isStepper ?? false)) {
                await widget.onChargeablePressed
                    ?.call(sparePartId, !(widget.isChargeable ?? true));
              }
            },
          ),
        ),
        !(widget.editable ?? false)
            ? SizedBox(
                width: 90,
                child: Container(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: RichText(
                    text: TextSpan(
                        // Note: Styles for TextSpans must be explicitly defined.
                        // Child text spans will inherit styles from parent
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.black54,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: quantity == 1
                                ? '$quantity Unit'
                                : '$quantity Units',
                          ),
                        ]),
                  ),
                ),
              )
            : Row(children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 30),
                  child: IconButton(
                    onPressed: () {
                      if (Helpers.editableJobSpareParts[widget.index ?? 0]
                              .quantity !=
                          0) {
                        setState(() {
                          Helpers.editableJobSpareParts[widget.index ?? 0]
                              .quantity = (Helpers
                                      .editableJobSpareParts[widget.index ?? 0]
                                      .quantity ??
                                  0) -
                              1;
                        });
                      }
                    },
                    icon: Icon(
                      Icons.remove,
                      size: 15,
                      color: Helpers.editableJobSpareParts[widget.index ?? 0]
                                  .quantity !=
                              0
                          ? Colors.black
                          : Colors.black45,
                    ),
                  ),
                ),
                Container(
                  width: 60,
                  padding: EdgeInsets.only(bottom: 32),
                  child: RichText(
                    text: TextSpan(
                        // Note: Styles for TextSpans must be explicitly defined.
                        // Child text spans will inherit styles from parent
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.black54,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text:
                                '${(Helpers.editableJobSpareParts[widget.index ?? 0].quantity ?? 0)}',
                          ),
                        ]),
                  ),
                ),
              ]),
        SizedBox(
          width: 10,
        ),
        SizedBox(
          width: 90,
          child: Container(
            padding: const EdgeInsets.only(bottom: 30),
            child: RichText(
              text: TextSpan(
                  // Note: Styles for TextSpans must be explicitly defined.
                  // Child text spans will inherit styles from parent
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.black54,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: price,
                    ),
                  ]),
            ),
          ),
        ),
      ],
    );
  }
}

class PickListItem extends StatelessWidget {
  PickListItem(
      {Key? key,
      required this.width,
      required this.part,
      required this.job,
      required this.jobId,
      required this.index,
      required this.onDeletePressed,
      required this.editable,
      required this.partList})
      : super(key: key);

  final double width;
  final SparePart part;
  final Job job;
  final String jobId;
  final int index;
  Function onDeletePressed;

  final bool editable;
  final List<SparePart> partList;
  var isRecordEditable = false;

  showAlertDialog(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () async {
        // List<JobSparePart> finalArr = [];
        // for (int i = 0; i < partList.length; i++) {
        //   if (partList[i].id == part.id) {
        //     partList[i].quantity = 0;
        //   }
        // }
        // await _AddSparePartsToJob(partList);
        await onDeletePressed.call(part.id);
      },
    );

    Widget cancelButton = TextButton(
      child: Text("Cancel"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text("Confirm"),
      content: Text("Are you sure to delete the selected spare part ?"),
      actions: [
        cancelButton,
        okButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<bool> _AddSparePartsToJob(List<SparePart> jobSpareparts) async {
    SparePart sparePart;
    List<SparePart> spareParts = [];
    jobSpareparts.forEach((element) {
      sparePart = new SparePart();
      sparePart.id = element!.id;
      sparePart.quantity = element!.quantity;
      spareParts.add(sparePart);
    });

    return await Repositories.addSparePartsToJob(jobId, spareParts);
  }

  @override
  Widget build(BuildContext context) {
    // var transactionId = this.part.transactionId;
    var sparePartId = this.part.id;
    var quantity = this.part.quantity.toString();
    // var discount = this.part.discount;
    var price = this.part.priceFormatted;
    var sparePartCode = this.part.code;
    var description = this.part.description;

    // var total = (((double.parse(price ?? '0') *
    //         double.parse((quantity != "" ? quantity : "0") ?? "0")) *
    //     (100 - double.parse(discount ?? '0')) /
    //     100));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        job.serviceJobStatus != "COMPLETED" && editable
            ? Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 40),
                child: GestureDetector(
                    onTap: () async {
                      await showAlertDialog(context);
                    },
                    child: Icon(
                      // <-- Icon
                      Icons.delete,
                      color: Colors.black54,
                      size: 25.0,
                    )),
              )
            : new Container(),
        SizedBox(
          width: 5,
        ),
        SizedBox(
          width: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 200,
                child: RichText(
                  text: TextSpan(
                      style: const TextStyle(
                        fontSize: 15.0,
                        color: Colors.black,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: '$sparePartCode',
                        ),
                      ]),
                ),
              ),
              RichText(
                text: TextSpan(
                    // Note: Styles for TextSpans must be explicitly defined.
                    // Child text spans will inherit styles from parent
                    style: const TextStyle(
                      fontSize: 15.0,
                      color: Colors.black54,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: '$description',
                      ),
                    ]),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
        new Spacer(),
        !editable
            ? SizedBox(
                width: 90,
                child: Container(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: RichText(
                    text: TextSpan(
                        // Note: Styles for TextSpans must be explicitly defined.
                        // Child text spans will inherit styles from parent
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.black54,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: quantity == 1
                                ? '$quantity Unit'
                                : '$quantity Units',
                          ),
                        ]),
                  ),
                ),
              )
            : Container(
                width: 80,
                padding: EdgeInsets.only(bottom: 50),
                child: TextFormField(
                    //focusNode: focusEmail,
                    keyboardType: TextInputType.number,
                    onChanged: (str) {
                      Helpers.editableJobSpareParts[index].quantity =
                          int.parse(str);
                    },
                    onEditingComplete: () {},
                    onFieldSubmitted: (val) {
                      FocusScope.of(context).requestFocus(new FocusNode());
                    },
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp("[0-9a-zA-Z]")),
                    ],
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.black54,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      //suffixText: quantity == 1 ? ' Unit' : ' Units',
                      hintText: '$quantity'.split(".")[0],
                      hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7)),
                      contentPadding: EdgeInsets.fromLTRB(20, 5, 0, 0),
                    )),
              ),
      ],
    );
  }
}

class CommentItem extends StatefulWidget {
  CommentItem(
      {Key? key,
      required this.comments,
      required this.loggedInUserId,
      required this.index,
      required this.onDeletePressed,
      // required this.textEditingControllers,
      required this.ctx,
      required this.focusNodes,
      required this.onUpdate,
      required this.onEditPressed,
      required this.isCurrentSelectedindex})
      : super(key: key);

  final List<Comment> comments;
  final List<FocusNode> focusNodes;
  // final List<TextEditingController> textEditingControllers;

  final int index;
  final int? isCurrentSelectedindex;
  final String loggedInUserId;
  Function onDeletePressed;
  Function onUpdate;
  Function onEditPressed;
  BuildContext ctx;

  @override
  _CommentItemState createState() => new _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  bool isFocused = false;
  bool isCurrentUIEditable = false;

  TextEditingController commentTextController = new TextEditingController();
  showAlertDialog(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () async {
        await widget.onDeletePressed.call(widget.index);
      },
    );

    Widget cancelButton = TextButton(
      child: Text("Cancel"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text("Confirm"),
      content: Text("Are you sure to delete the selected spare part ?"),
      actions: [
        cancelButton,
        okButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  void initState() {
    super.initState();

    setState(() {
      var oo = widget.comments;
      var abc = widget.comments[widget.index].remarks ?? "";
      var indwwwex = widget.index;

      this.commentTextController.text =
          widget.comments[widget.index].remarks ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      // mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        widget.comments != null && widget.comments.length > 0
            ? SizedBox(
                height: 20,
              )
            : new Container(),
        widget.comments != null && widget.comments.length > 0
            ? Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * .2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  border: Border.all(
                    width: 0.4,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                        blurRadius: 5,
                        color: Colors.grey[100]!,
                        offset: Offset(0, 10)),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 20,
                      left: MediaQuery.of(context).size.width * 0.06,
                      child: Container(
                        child: Image(
                          image:
                              AssetImage('assets/images/inverted_commas.png'),
                        ),
                      ),
                    ),
                    Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.fromLTRB(70, 50, 70, 5),
                            child: Row(
                              children: [
                                RichText(
                                  text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.black,
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                            text: widget.comments[widget.index]
                                                .customerName,
                                            style: const TextStyle(
                                                color: Color(0xFF888888),
                                                fontWeight: FontWeight.bold)),
                                      ]),
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Icon(
                                  Icons.circle,
                                  size: 5,
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                RichText(
                                  text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        color: Color(0xFF888888),
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                            text: widget.comments[widget.index]
                                                .insertedAtInAgoAnnotation,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ]),
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFFDBF0F9),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Center(
                                      child: Text(
                                        widget.comments[widget.index].role ??
                                            "",
                                        style: TextStyle(
                                          color: Color(0xFF5ACEFF),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.fromLTRB(70, 5, 70, 30),
                            child: widget.isCurrentSelectedindex == widget.index
                                ? TextFormField(
                                    keyboardType: TextInputType.multiline,
                                    minLines: 1,
                                    maxLines: 2,
                                    onChanged: (str) {
                                      // setState(() {
                                      //   isSerialNoEditable = true;
                                      // });
                                    },
                                    enabled: true,
                                    controller: this.commentTextController,
                                    //     readOnly: isSerialNoEditable,
                                    focusNode: widget.focusNodes[widget.index],
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                    ),
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold))
                                : RichText(
                                    textAlign: TextAlign.left,
                                    text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 16.0,
                                          color: Colors.black,
                                        ),
                                        children: <TextSpan>[
                                          TextSpan(
                                              text: widget
                                                      .comments[widget.index]
                                                      .remarks ??
                                                  "",
                                              style: const TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold)),
                                        ]),
                                  ),
                          ),
                          widget.loggedInUserId ==
                                  widget.comments[widget.index].userId
                              ? Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () async {
                                        var comme =
                                            widget.comments[widget.index];
                                        var loggewd = widget.loggedInUserId;

                                        if (!(widget.isCurrentSelectedindex ==
                                            widget.index)) {
                                          await widget
                                              .onEditPressed(widget.index);
                                        } else {
                                          var res =
                                              await Repositories.updateComment(
                                                  widget.comments[widget.index]
                                                          .id ??
                                                      0,
                                                  this
                                                      .commentTextController
                                                      .text
                                                      .toString());
                                          await widget.onUpdate(widget.index);
                                        }
                                      },
                                      child: !(widget.isCurrentSelectedindex ==
                                              widget.index)
                                          ? Container(
                                              padding: EdgeInsets.fromLTRB(
                                                  70, 5, 10, 30),
                                              child: Row(
                                                children: [
                                                  Icon(Icons
                                                      .edit_calendar_outlined),
                                                  SizedBox(width: 5),
                                                  RichText(
                                                    text: TextSpan(
                                                        style: const TextStyle(
                                                          fontSize: 16.0,
                                                          color: Colors.black,
                                                        ),
                                                        children: <TextSpan>[
                                                          TextSpan(
                                                              text: 'Edit',
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .black,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                        ]),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : Container(
                                              padding: EdgeInsets.fromLTRB(
                                                  70, 5, 10, 30),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.check_box_sharp),
                                                  SizedBox(width: 5),
                                                  RichText(
                                                    text: TextSpan(
                                                        style: const TextStyle(
                                                          fontSize: 16.0,
                                                          color: Colors.black,
                                                        ),
                                                        children: <TextSpan>[
                                                          TextSpan(
                                                              text: 'Save',
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .black,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                        ]),
                                                  ),
                                                ],
                                              ),
                                            ),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    GestureDetector(
                                        onTap: () async {
                                          showAlertDialog(widget.ctx);
                                        },
                                        child: Container(
                                          padding:
                                              EdgeInsets.fromLTRB(0, 5, 70, 30),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete_forever,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 3),
                                              RichText(
                                                text: TextSpan(
                                                    style: const TextStyle(
                                                      fontSize: 16.0,
                                                      color: Colors.red,
                                                    ),
                                                    children: <TextSpan>[
                                                      TextSpan(
                                                          text: 'Delete',
                                                          style: const TextStyle(
                                                              color: Colors.red,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                    ]),
                                              ),
                                            ],
                                          ),
                                        ))
                                  ],
                                )
                              : new Container()
                        ]),
                  ],
                ))
            : new Container()
      ],
    );
  }
}

class JobItem extends StatefulWidget {
  final double width;
  final Job job;
  final int index;
  final List<Job>? history;

  JobItem(
      {required this.width,
      required this.job,
      required this.index,
      required this.history});

  @override
  _JobItemState createState() => new _JobItemState();
}

class _JobItemState extends State<JobItem> {
  Job? job;
  int? index;
  double? width;
  List<Job>? history;

  @override
  void initState() {
    super.initState();
    job = widget.job;
    index = widget.index;
    history = widget.history;
    width = widget.width;
  }

  final imageUrls = [
    "https://www.pngitem.com/pimgs/m/30-307416_profile-icon-png-image-free-download-searchpng-employee.png",
    "https://www.pngitem.com/pimgs/m/30-307416_profile-icon-png-image-free-download-searchpng-employee.png",
    "https://www.pngitem.com/pimgs/m/30-307416_profile-icon-png-image-free-download-searchpng-employee.png",
    "https://www.pngitem.com/pimgs/m/30-307416_profile-icon-png-image-free-download-searchpng-employee.png"
  ];

  Color getColor() {
    if (job?.serviceJobStatus?.toLowerCase() == "request created" ||
        job?.serviceJobStatus == "PENDING REPAIR") {
      return Colors.red;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(width: 0.1),
        color: getColor(),
        boxShadow: [
          BoxShadow(
              blurRadius: 5, color: Colors.grey[200]!, offset: Offset(0, 10)),
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
                                          ? '# ${job?.serviceJobNo}'.toString()
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
                              width: MediaQuery.of(context).size.width * 0.2,
                              height: MediaQuery.of(context).size.height * 0.03,
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
                                    '${job != null ? job?.serviceType : ""}',
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
                                    '${job?.serviceJobStatus}',
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
                                        text: job?.serviceDate != null
                                            ? job?.serviceDate
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
                                          ? '${job?.serviceAddressStreet},${job?.serviceAddressCity},${job?.serviceAddressPostcode},${job?.serviceAddressState}, '
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
                                    ? '${job?.customerName} (${job?.customerTelephone})'
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
                                text:
                                    job != null ? job?.productDescription : '-',
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
                                text: job != null ? job?.productCode : '',
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
                                this.job?.serviceAddressStreet != ""
                                    ? GestureDetector(
                                        onTap: () async {
                                          var address = this
                                              .job
                                              ?.serviceAddressStreet
                                              ?.replaceAll("\n", "");
                                          launch(
                                              "https://www.google.com/maps/search/?api=1&query=${'${job?.serviceAddressStreet},${job?.serviceAddressCity},${job?.serviceAddressPostcode},${job?.serviceAddressState},'}");
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
                        ? job?.remarks
                                .toString()
                                .toLowerCase()
                                .replaceAll("\n", " ") ??
                            "-"
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
                    moreStyle:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                        (job?.actualProblemCode != null
                            ? job?.actualProblemDescription != null
                                ? (job?.actualProblemDescription
                                        .toString()
                                        .toLowerCase() ??
                                    "")
                                : (job?.reportedProblemCode != null
                                    ? job?.reportedProblemCode
                                            .toString()
                                            .toLowerCase() ??
                                        ""
                                    : "-")
                            : ""),
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

class MiscItem extends StatelessWidget {
  MiscItem(
      {Key? key,
      required this.width,
      required this.miscItem,
      required this.job,
      required this.jobId,
      required this.index,
      required this.onDeletePressed,
      required this.editable,
      required this.partList})
      : super(key: key);

  final double width;
  final MiscellaneousItem miscItem;
  final Job job;
  final String jobId;
  final int index;
  Function onDeletePressed;
  final bool editable;
  final List<SparePart> partList;
  var isRecordEditable = false;
  final RegExp priceRegex = RegExp(r'^\d+(\.\d{0,2})?$');

  TextEditingController quantityCT = new TextEditingController();
  TextEditingController priceCT = new TextEditingController();

  showAlertDialog(BuildContext context, int id) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () async {
        await onDeletePressed.call(id);
        Navigator.pop(context);
      },
    );

    Widget cancelButton = TextButton(
      child: Text("Cancel"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text("Confirm"),
      content: Text("Are you sure to delete the selected miscellaneous item ?"),
      actions: [
        cancelButton,
        okButton,
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<bool> _AddSparePartsToJob(List<SparePart> jobSpareparts) async {
    SparePart sparePart;
    List<SparePart> spareParts = [];
    jobSpareparts.forEach((element) {
      sparePart = new SparePart();
      sparePart.id = element!.id;
      sparePart.quantity = element!.quantity;
      spareParts.add(sparePart);
    });

    return await Repositories.addSparePartsToJob(jobId, spareParts);
  }

  @override
  Widget build(BuildContext context) {
    var miscItemId = this.miscItem.miscChargesId;
    var quantity = this.miscItem.quantity;
    var description = this.miscItem.remarks;
    var price = this.miscItem.formattedPrice;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        editable
            ? Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 40),
                child: GestureDetector(
                    onTap: () async {
                      await showAlertDialog(context, miscItemId ?? 0);
                    },
                    child: Icon(
                      // <-- Icon
                      Icons.delete,
                      color: Colors.black54,
                      size: 25.0,
                    )),
              )
            : new Container(),
        SizedBox(
          width: 5,
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.35,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              RichText(
                text: TextSpan(
                    style: const TextStyle(
                      fontSize: 18.0,
                      color: Colors.black54,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: '$description',
                      ),
                    ]),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
        SizedBox(
          width: 10,
        ),
        !editable
            ? SizedBox(
                width: MediaQuery.of(context).size.width * 0.1,
                child: Container(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: RichText(
                    text: TextSpan(
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.black54,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: quantity == 1
                                ? '$quantity Unit'
                                : '$quantity Units',
                          ),
                        ]),
                  ),
                ),
              )
            : Container(
                width: 80,
                padding: EdgeInsets.only(bottom: 20),
                child: TextFormField(
                    //focusNode: focusEmail,
                    keyboardType: TextInputType.number,
                    onChanged: (str) {
                      Helpers.editableMiscItems[index].quantity =
                          int.parse(str);
                    },
                    onEditingComplete: () {},
                    onFieldSubmitted: (val) {
                      FocusScope.of(context).requestFocus(new FocusNode());
                    },
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp((r'^[0-9]*$'))),
                    ],
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.black54,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7)),
                      hintText: quantity.toString(),
                      contentPadding: EdgeInsets.fromLTRB(20, 5, 0, 0),
                    )),
              ),
        SizedBox(
          width: 10,
        ),
        !editable
            ? SizedBox(
                width: MediaQuery.of(context).size.width * 0.15,
                child: Container(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: RichText(
                    text: TextSpan(
                        // Note: Styles for TextSpans must be explicitly defined.
                        // Child text spans will inherit styles from parent
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.black54,
                        ),
                        children: <TextSpan>[
                          TextSpan(text: price),
                        ]),
                  ),
                ),
              )
            : Container(
                width: 80,
                padding: EdgeInsets.only(bottom: 20),
                child: TextFormField(
                    //focusNode: focusEmail,
                    keyboardType: TextInputType.number,
                    onChanged: (str) {
                      Helpers.editableMiscItems[index].formattedPrice =
                          'MYR ${str}';
                    },
                    onEditingComplete: () {},
                    onFieldSubmitted: (val) {
                      FocusScope.of(context).requestFocus(new FocusNode());
                    },
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(
                          RegExp((r"^[0-9a-zA-Z]*\.?[0-9a-zA-Z]*$"))),
                    ],
                    style: TextStyle(
                      fontSize: 18.0,
                      color: Colors.black54,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7)),
                      hintText: price?.split("MYR")[1],
                      contentPadding: EdgeInsets.fromLTRB(20, 5, 0, 0),
                    )),
              ),
      ],
    );
  }
}

class AddMiscItemsPopup extends StatefulWidget {
  Function? newItemAdded;

  AddMiscItemsPopup({required this.newItemAdded}) {}

  @override
  _AddMiscItemsPopupState createState() => _AddMiscItemsPopupState();
}

class _AddMiscItemsPopupState extends State<AddMiscItemsPopup> {
  TextEditingController itemNameController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  Function? newItemAdded;
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

    newItemAdded = widget.newItemAdded;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Miscellaneous item'),
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
                    text: 'Item Name: ',
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
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s.]')),
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
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.only(bottom: 50),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: decrement,
                        icon: Icon(
                          Icons.remove,
                          color: Colors.black,
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width * .07,
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          controller: TextEditingController(text: '$quantity'),
                          readOnly: true,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(vertical: 1.0),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: increment,
                        icon: Icon(Icons.add, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                Row(children: [
                  Container(
                      padding: EdgeInsets.only(bottom: 50),
                      decoration: BoxDecoration(
                        boxShadow: [],
                      ),
                      child: Text("RM")),
                  Container(
                      width: MediaQuery.of(context).size.width * 0.2,
                      padding: EdgeInsets.only(bottom: 50, left: 20),
                      child: TextFormField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        onChanged: (str) {},
                        onEditingComplete: () {},
                        onFieldSubmitted: (val) {
                          FocusScope.of(context).requestFocus(new FocusNode());
                        },
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9a-zA-Z.]'),
                          ),
                        ],
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.black54,
                        ),
                        decoration: InputDecoration(
                          hintText: "0.00",
                          border: OutlineInputBorder(),
                          hintStyle:
                              TextStyle(color: Colors.grey.withOpacity(0.7)),
                          contentPadding: EdgeInsets.fromLTRB(15, 5, 5, 5),
                        ),
                      )),
                ])
              ])
        ],
      ),
      actions: [
        ElevatedButton(
            child: Padding(
                padding: EdgeInsets.all(0.0),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    'Add Items',
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
              await newItemAdded?.call(
                  itemNameController.text.toString(),
                  quantity,
                  num.parse(priceController.text.toString())
                      .toStringAsFixed(2));
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

class StepperAlertDialog extends StatefulWidget {
  Widget content;
  int? stepperCounter;
  Function isStepperCountChanged;
  Function isConfirmPressed;

  StepperAlertDialog(
      {required this.content,
      required this.stepperCounter,
      required this.isStepperCountChanged,
      required this.isConfirmPressed}) {}

  @override
  _StepperAlertDialogState createState() => _StepperAlertDialogState();
}

class _StepperAlertDialogState extends State<StepperAlertDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text('Job Summary'),
        content: Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
            width: MediaQuery.of(context).size.height * 0.5,
            child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * .4,
                    minHeight: MediaQuery.of(context).size.height * .1),
                child: Column(children: [
                  SizedBox(height: 50),
                  widget.content,
                ]))),
        actions: <Widget>[
          SizedBox(
              width:
                  MediaQuery.of(context).size.width * 0.18, // <-- match_parent
              height:
                  MediaQuery.of(context).size.width * 0.05, // <-- match-parent
              child: widget.stepperCounter == 0
                  ? new Container()
                  : ElevatedButton(
                      child: Padding(
                          padding: const EdgeInsets.all(0.0),
                          child: Row(
                            children: [
                              const Text(
                                'Previous',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.white),
                              )
                            ],
                          )),
                      style: ButtonStyle(
                          foregroundColor:
                              MaterialStateProperty.all<Color>(Colors.black),
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.black),
                          shape:
                              MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                      side: const BorderSide(
                                          color: Colors.black)))),
                      onPressed: () async {
                        await widget.isStepperCountChanged.call(false);
                      })),
          SizedBox(width: 20),
          SizedBox(
              width:
                  MediaQuery.of(context).size.width * 0.18, // <-- match_parent
              height:
                  MediaQuery.of(context).size.width * 0.05, // <-- match-parent
              child: widget.stepperCounter == 5
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
                                'Confirm',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.white),
                              )
                            ],
                          )),
                      style: ButtonStyle(
                          foregroundColor:
                              MaterialStateProperty.all<Color>(Colors.black),
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.black),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                  side:
                                      const BorderSide(color: Colors.black)))),
                      onPressed: () async {
                        await widget.isConfirmPressed();
                      })
                  : ElevatedButton(
                      child: Padding(
                          padding: const EdgeInsets.all(0.0),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 10,
                              ),
                              const Text(
                                'Next',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.white),
                              )
                            ],
                          )),
                      style: ButtonStyle(
                          foregroundColor:
                              MaterialStateProperty.all<Color>(Colors.black),
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.black),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                  side: const BorderSide(color: Colors.black)))),
                      onPressed: () async {
                        await widget.isStepperCountChanged.call(true);
                      })),
        ]);
  }
}
