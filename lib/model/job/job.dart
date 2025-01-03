import 'package:kcs_engineer/model/spareparts/miscellaneousItem.dart';
import 'package:kcs_engineer/model/payment/pickup_charges.dart';
import 'package:kcs_engineer/model/user/secondaryEngineer.dart';
import 'package:kcs_engineer/model/spareparts/sparepart.dart';
import 'package:kcs_engineer/model/job/general/transportCharge.dart';

class JobData {
  List<Job>? jobs;
  JobMetaData? meta;

  JobData({
    this.jobs,
    this.meta,
  });

  JobData.selectedJobFromJson(Map<String, dynamic> json) {
    this.jobs = (json['data'] as List).map((i) => Job.fromJson(i)).toList();
    this.meta = JobMetaData.fromJson(json["meta"]);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["id"] = "LALA";
    return data;
  }
}

class Job {
  String? serviceRequestid;
  String? serviceJobNo;
  String? serviceType;
  int? serviceTypeId;
  String? serviceJobStatus;
  String? serviceDate;
  String? serviceTime;
  String? customerName;
  String? customerTelephone;
  String? customerEmail;
  String? customerAddressName;
  String? serviceAddressStreet;
  String? serviceAddressCity;
  String? serviceAddressPostcode;
  String? serviceAddressState;
  String? reportedProblemCode;
  String? reportedProblemDescription;
  String? actualProblemCode;
  String? actualProblemDescription;
  String? estimatedSolutionCode;
  String? estimatedSolutionDescription;
  String? estimatedSolutionCharges;
  String? estimatedSolutionChargesAmount;
  String? estimatedSolutionSSTPercentage;
  String? estimatedSolutionTotalSST;
  String? estimatedSolutionTotalLineVal;
  String? estimatedSolutionDiscountPercentage;
  String? estimatedSolutionDiscountAmount;
  String? actualSolutionDiscountPercentage;
  String? actualSolutionDiscountAmount;
  String? actualSolutionCode;
  String? actualSolutionDescription;
  String? actualSolutionCharges;
  String? actualSolutionChargesAmount;
  String? actualSolutionSSTPercentage;
  String? actualSolutionTotalSST;
  String? actualSolutionTotalLineVal;
  String? remarks;
  String? adminRemarks;
  String? engineerRemarks;

  String? productCode;
  int? productId;
  int? productGroupdId;
  int? productModelId;
  String? productDescription;
  String? serialNo;
  bool? isPaid;
  bool? isRTOOrder;
  String? purchaseDate;
  String? paymentMethods;
  TransportCharge? transportCharge;
  PickupCharge? pickupCharge;

  bool? isChargeableMisc;
  bool? isUnderWarranty;
  String? warrantyAdditionalInfo;
  bool? isChargeablePickup;
  bool? isChargeableSolution;
  bool? isChargeableTransport;
  List<String>? chargeableSparepartIds;

  List<SecondaryEngineer>? secondaryEngineers;
  List<SparePart>? picklistNotCollected;
  List<SparePart>? picklistCollected;

  List<SparePart>? currentJobSparepartsfromBag;
  List<SparePart>? currentJobSparepartsfromWarehouse;
  List<SparePart>? currentJobSparepartsfromPickList;
  List<SparePart>? aggregatedSpareparts;

  List<MiscellaneousItem>? miscCharges;

  bool? isDiscountApplied;
  bool? isMainEngineer;

  int? currentKIVCount;
  int? maxKIVCount;

  String? jobInsertedDate;

  String? secondaryContactNo;
  String? secondaryContactFullName;
  String? secondaryContactRelationship;

  String? userMobileNo;

  Job(
      {this.serviceRequestid,
      this.serviceJobNo,
      this.serviceType,
      this.serviceJobStatus,
      this.serviceDate,
      this.serviceTime,
      this.customerName,
      this.customerTelephone,
      this.customerEmail,
      this.customerAddressName,
      this.serviceAddressStreet,
      this.serviceAddressCity,
      this.serviceAddressPostcode,
      this.serviceAddressState,
      this.reportedProblemCode,
      this.reportedProblemDescription,
      this.actualProblemCode,
      this.actualProblemDescription,
      this.estimatedSolutionCode,
      this.estimatedSolutionDescription,
      this.estimatedSolutionCharges,
      this.estimatedSolutionChargesAmount,
      this.estimatedSolutionSSTPercentage,
      this.estimatedSolutionTotalLineVal,
      this.estimatedSolutionTotalSST,
      this.estimatedSolutionDiscountPercentage,
      this.estimatedSolutionDiscountAmount,
      this.actualSolutionDiscountPercentage,
      this.actualSolutionDiscountAmount,
      this.actualSolutionCode,
      this.actualSolutionDescription,
      this.actualSolutionCharges,
      this.actualSolutionChargesAmount,
      this.actualSolutionSSTPercentage,
      this.actualSolutionTotalLineVal,
      this.actualSolutionTotalSST,
      this.remarks,
      this.paymentMethods,
      this.adminRemarks,
      this.productCode,
      this.productDescription,
      this.serialNo,
      this.purchaseDate,
      this.productId,
      this.serviceTypeId,
      this.picklistNotCollected,
      this.currentJobSparepartsfromBag,
      this.currentJobSparepartsfromWarehouse,
      this.currentJobSparepartsfromPickList,
      this.aggregatedSpareparts,
      this.miscCharges,
      this.transportCharge,
      this.isPaid,
      this.isUnderWarranty,
      this.warrantyAdditionalInfo,
      this.isRTOOrder,
      this.pickupCharge,
      this.secondaryEngineers,
      this.productModelId,
      this.isChargeableMisc,
      this.isChargeablePickup,
      this.isChargeableSolution,
      this.isChargeableTransport,
      this.chargeableSparepartIds,
      this.currentKIVCount,
      this.maxKIVCount,
      this.engineerRemarks,
      this.isDiscountApplied,
      this.productGroupdId,
      this.picklistCollected,
      this.isMainEngineer,
      this.secondaryContactNo,
      this.secondaryContactFullName,
      this.secondaryContactRelationship,
      this.jobInsertedDate,
      this.userMobileNo});

  Job.fromJson(Map<String, dynamic> json) {
    this.serviceRequestid = json["service_request_id"];
    this.serviceJobNo = json["service_job_no"];
    this.serviceType = json["service_type"];
    this.serviceJobStatus = json["service_job_status"];
    this.serviceDate = json["service_date"] == null
        ? ""
        : DateTime.parse(json["service_date"])
            .toLocal()
            .toString()
            .split(" ")[0];
    this.customerName = json["customer"]?["name"];
    this.customerTelephone = json["customer"]?["telephone"];
    this.customerEmail = json["customer"]?["email"];
    this.secondaryContactNo =
        json["customer"]?["additional_info"]?["contact_number"] ?? "";
    this.secondaryContactFullName =
        json["customer"]?["additional_info"]?["full_name"] ?? "";
    this.secondaryContactRelationship =
        json["customer"]?["additional_info"]?["relationship"] ?? "";

    // this.customerAddressName = json["customer"]?["address_name"];
    this.serviceAddressStreet = json["service_address"]?["street"];
    this.serviceAddressCity = json["service_address"]?["city"];
    this.serviceAddressPostcode = json["service_address"]?["postcode"];
    this.serviceAddressState = json["service_address"]?["state"];
    this.reportedProblemCode = json["problem"]?["reported"]?["code"];
    this.reportedProblemDescription =
        json["problem"]?["reported"]?["description"];
    this.actualProblemCode = json["problem"]?["actual"]?["code"];
    this.actualProblemDescription = json["problem"]?["actual"]?["description"];
    this.estimatedSolutionCode = json["solution"]?["estimated"]?["code"];
    this.estimatedSolutionDescription =
        json["solution"]?["estimated"]?["solution"];
    this.estimatedSolutionCharges =
        json["solution"]?["estimated"]?["charges"]?["formatted"];
    this.estimatedSolutionChargesAmount = (double.parse(
                json["solution"]?["estimated"]?["charges"]?["amount"] ?? "1") /
            100)
        .toStringAsFixed(2);
    this.estimatedSolutionSSTPercentage = json["solution"]?["estimated"]
                        ?["sst_percentage"]
                    .toString() !=
                "0" &&
            json["solution"]?["estimated"]?["sst_percentage"] != null
        ? '${(json["solution"]?["estimated"]?["sst_percentage"] as num) * 100}'
        : "0";
    this.estimatedSolutionTotalSST = json["solution"]?["estimated"] != null
        ? ((double.parse(this.estimatedSolutionSSTPercentage ?? "0.0") / 100) *
                double.parse(this.estimatedSolutionChargesAmount ?? "0.0"))
            .toStringAsFixed(2)
        : "-";
    this.estimatedSolutionTotalLineVal = json["solution"]?["estimated"] != null
        ? (double.parse(this.estimatedSolutionTotalSST ?? "0.0") +
                double.parse(this.estimatedSolutionChargesAmount ?? "0.0"))
            .toStringAsFixed(2)
        : "-";

    this.actualSolutionCode = json["solution"]?["actual"]?["code"];
    this.actualSolutionDescription = json["solution"]?["actual"]?["solution"];
    this.actualSolutionCharges =
        json["solution"]?["actual"]?["charges"]?["formatted"];
    this.actualSolutionChargesAmount = (double.parse(
                json["solution"]?["actual"]?["charges"]?["amount"] ?? "1") /
            100)
        .toStringAsFixed(2);
    this.actualSolutionSSTPercentage =
        json["solution"]?["actual"]?["sst_percentage"].toString() != "0" &&
                json["solution"]?["actual"]?["sst_percentage"] != null
            ? '${(json["solution"]?["actual"]?["sst_percentage"] as num) * 100}'
            : "0";
    this.actualSolutionTotalSST = json["solution"]?["actual"] != null
        ? ((double.parse(this.actualSolutionSSTPercentage ?? "0.0") / 100) *
                double.parse(this.actualSolutionChargesAmount ?? "0.0"))
            .toStringAsFixed(2)
        : "-";
    this.actualSolutionTotalLineVal = json["solution"]?["actual"] != null
        ? (double.parse(this.actualSolutionTotalSST ?? "0.0") +
                double.parse(this.actualSolutionChargesAmount ?? "0.0"))
            .toStringAsFixed(2)
        : "-";
    this.remarks = json["remarks"]?["remarks"];
    this.adminRemarks = json["remarks"]?["admin_remarks"];
    this.engineerRemarks = json["remarks"]?["engineer_remarks"];
    this.productCode = json["product"]?["code"];
    this.productDescription = json["product"]?["description"];
    this.serialNo = json["warranty_info"]?["serial_no"];
    this.purchaseDate = json["warranty_info"]?["purchase_date"];
    this.isPaid = json["payment"] != null && json["payment"]?["is_paid"];
    this.paymentMethods =
        (json["payment"] != null && json["payment"]?["payment_method"] != null)
            ? (json["payment"]?["payment_method"] as List<dynamic>).join(",")
            : null;
    this.isRTOOrder = json["has_sales_order_connection"];
    this.productId = json["product"]?["id"];
    this.serviceTypeId = json["service_type_id"];
    this.productModelId = json["product"]?["model_id"];
    this.productGroupdId = json["product"]?["group_id"];
    this.isUnderWarranty = json["warranty_info"] != null
        ? (json["warranty_info"]?["is_warranty_valid"])
        : null;
    this.warrantyAdditionalInfo = json["warranty_info"] != null
        ? (json["warranty_info"]?["additional_warranty_info"])
        : null;
    this.isChargeableMisc =
        json["saved_states"]?["is_chargeable"]?["misc"] == "1";
    this.isChargeablePickup =
        json["saved_states"]?["is_chargeable"]?["pickup"] == "1";
    this.isChargeableSolution =
        json["saved_states"]?["is_chargeable"]?["solution"] == "1";
    this.isChargeableTransport =
        json["saved_states"]?["is_chargeable"]?["transport"] == "1";
    this.isDiscountApplied =
        (json["saved_states"]?['is_discount_applied'] != null
            ? (json["saved_states"]?['is_discount_applied']) == "1"
            : false);
    this.maxKIVCount = json["kiv_info"]?["max_kiv_count"];
    this.currentKIVCount = json["kiv_info"]?["current_kiv_count"];
    this.chargeableSparepartIds =
        json["saved_states"]?["list_of_spareparts_not_chargeable"] != null
            ? (json["saved_states"]?["list_of_spareparts_not_chargeable"]
                    as List<dynamic>)
                .map((e) => e.toString())
                .toList()
            : [];

    this.secondaryEngineers = json["secondary_engineers"] != null
        ? (json["secondary_engineers"] as List)
            .map((e) => SecondaryEngineer.fromJson(e))
            .toList()
        : [];

    this.picklistNotCollected = json["bag_pick_list"]?['spareparts'] != null
        ? ((json["bag_pick_list"]?['spareparts'] as List)
                .map((e) => SparePart.fromJson(e))
                .toList())
            .where((element) => element.collectedAt == null)
            .toList()
        : [];

    this.picklistCollected = json["bag_pick_list"]?['spareparts'] != null
        ? ((json["bag_pick_list"]?['spareparts'] as List)
            .map((e) => SparePart.fromJson(e))
            .toList())
        : [];

    this.miscCharges = json["misc_charges"] != null
        ? (json["misc_charges"] as List)
            .map((e) => MiscellaneousItem.fromJson(e))
            .toList()
        : [];

    this.pickupCharge = json['pickup_charge'] != null
        ? PickupCharge.fromJson(json['pickup_charge'])
        : null;

    this.transportCharge = json['transport_charge'] != null
        ? TransportCharge.fromJson(json['transport_charge'])
        : null;

    this.currentJobSparepartsfromBag =
        json["current_spareparts_in_job"]?['from_bag'] != null
            ? (json["current_spareparts_in_job"]?['from_bag'] as List)
                .map((e) => SparePart.fromJsonStatusSpecific(e, "bag"))
                .toList()
            : [];
    this.currentJobSparepartsfromWarehouse =
        json["current_spareparts_in_job"]?['from_warehouse'] != null
            ? (json["current_spareparts_in_job"]?['from_warehouse'] as List)
                .map((e) => SparePart.fromJsonStatusSpecific(e, "warehouse"))
                .toList()
            : [];
    this.currentJobSparepartsfromPickList =
        json["current_spareparts_in_job"]?['from_picklist'] != null
            ? (json["current_spareparts_in_job"]?['from_picklist'] as List)
                .map((e) => SparePart.fromJsonStatusSpecific(e, 'picklist'))
                .toList()
            : [];

    this.estimatedSolutionDiscountPercentage = json["solution"]?["estimated"]
                ?["cf_info"]?["cf_discount_amount"] !=
            null
        ? ((num.parse(json["solution"]?["estimated"]?["cf_info"]
                    ?["cf_discount_percentage"]) *
                100))
            .toStringAsFixed(2)
        : "-";

    this.estimatedSolutionDiscountAmount = json["solution"]?["estimated"]
                ?["cf_info"]?["cf_discount_amount"] !=
            null
        ? ((num.parse(json["solution"]?["estimated"]?["cf_info"]
                        ?["cf_discount_amount"]?["amount"]) /
                    100) +
                (estimatedSolutionDiscountPercentage == "100.00"
                    ? num.parse(this.estimatedSolutionTotalSST ?? "0")
                    : 0))
            .toStringAsFixed(2)
        : "-";

    this.actualSolutionDiscountPercentage =
        json["solution"]?["actual"]?["cf_info"]?["cf_discount_amount"] != null
            ? ((num.parse(json["solution"]?["actual"]?["cf_info"]
                        ?["cf_discount_percentage"]) *
                    100))
                .toStringAsFixed(2)
            : "-";
    this.actualSolutionDiscountAmount =
        json["solution"]?["actual"]?["cf_info"]?["cf_discount_amount"] != null
            ? ((num.parse(json["solution"]?["actual"]?["cf_info"]
                            ?["cf_discount_amount"]?["amount"]) /
                        100) +
                    (actualSolutionDiscountPercentage == "100.00"
                        ? num.parse(this.actualSolutionTotalSST ?? "0")
                        : 0))
                .toStringAsFixed(2)
            : "-";

    this.aggregatedSpareparts = [];

    if ((currentJobSparepartsfromBag?.length ?? 0) > 0) {
      this.aggregatedSpareparts?.addAll(currentJobSparepartsfromBag ?? []);
    }

    if ((currentJobSparepartsfromWarehouse?.length ?? 0) > 0) {
      currentJobSparepartsfromWarehouse?.forEach((element) {
        var index =
            this.aggregatedSpareparts?.indexWhere((e) => e.id == element.id);
        if (index != -1) {
          this.aggregatedSpareparts?[index ?? 0].quantity =
              (this.aggregatedSpareparts?[index ?? 0].quantity ?? 0) +
                  (element.quantity ?? 0);
        } else {
          this.aggregatedSpareparts?.add(element);
        }
      });
    }

    if ((currentJobSparepartsfromPickList?.length ?? 0) > 0) {
      currentJobSparepartsfromPickList?.forEach((element) {
        var index =
            this.aggregatedSpareparts?.indexWhere((e) => e.id == element.id);
        if (index != -1) {
          this.aggregatedSpareparts?[index ?? 0].quantity =
              (this.aggregatedSpareparts?[index ?? 0].quantity ?? 0) +
                  (element.quantity ?? 0);
        } else {
          this.aggregatedSpareparts?.add(element);
        }
      });
    }
    this.isMainEngineer = json["is_main_engineer"];

    this.jobInsertedDate =
        (json["inserted_at"] ?? "T").toString().split("T")[0];

    var list = [];

    this.userMobileNo = json["user"]?["mobile"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["id"] = this.serviceRequestid;

    return data;
  }
}

class JobMetaData {
  int? currentPage;
  int? from;
  int? lastPage;
  int? perPage;
  int? to;
  int? total;
  int? completed;
  int? uncompleted;

  String? insertedDate;
  int? jobsCompleted;
  String? cashCollected;
  String? crRemark;

  JobMetaData(
      {this.currentPage,
      this.from,
      this.lastPage,
      this.perPage,
      this.to,
      this.total,
      this.completed,
      this.uncompleted,
      this.insertedDate,
      this.jobsCompleted,
      this.cashCollected,
      this.crRemark});

  JobMetaData.fromJson(Map<String, dynamic> json) {
    this.currentPage = json["current_page"];
    this.from = json["from"];
    this.lastPage = json["last_page"];
    this.perPage = json["per_page"];
    this.to = json["to"];
    this.total = json["total"];
    this.completed = json["completed"];
    this.uncompleted = json["uncompleted"];

    this.insertedDate = json["inserted_date"];
    this.jobsCompleted = json["jobs_completed_count"];
    this.cashCollected = json["cash_collected"]?["formatted"];
    this.crRemark = json["cr_remark"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["id"] = "LALA";
    return data;
  }
}
