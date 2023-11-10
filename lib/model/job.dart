import 'package:kcs_engineer/model/miscellaneousItem.dart';
import 'package:kcs_engineer/model/pickup_charges.dart';
import 'package:kcs_engineer/model/secondaryEngineer.dart';
import 'package:kcs_engineer/model/sparepart.dart';
import 'package:kcs_engineer/model/transportCharge.dart';

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
  String? estimatedSolutionIndoorCharges;
  String? estimatedSolutionOutdoorCharges;
  String? actualSolutionCode;
  String? actualSolutionDescription;
  String? actualSolutionIndoorCharges;
  String? actualSolutionOutdoorCharges;
  String? remarks;
  String? adminRemarks;
  String? productCode;
  int? productId;
  int? productModelId;
  String? productDescription;
  String? serialNo;
  TransportCharge? transportCharge;
  PickupCharge? pickupCharge;

  bool? isChargeableMisc;
  bool? isChargeablePickup;
  bool? isChargeableSolution;
  bool? isChargeableTransport;
  List<String>? chargeableSparepartIds;

  List<SecondaryEngineer>? secondaryEngineers;
  List<SparePart>? picklist;
  List<SparePart>? currentJobSparepartsfromBag;
  List<SparePart>? currentJobSparepartsfromWarehouse;
  List<SparePart>? currentJobSparepartsfromPickList;
  List<SparePart>? aggregatedSpareparts;

  List<MiscellaneousItem>? miscCharges;

  bool? isDiscountApplied;

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
      this.estimatedSolutionIndoorCharges,
      this.estimatedSolutionOutdoorCharges,
      this.actualSolutionCode,
      this.actualSolutionDescription,
      this.actualSolutionIndoorCharges,
      this.actualSolutionOutdoorCharges,
      this.remarks,
      this.adminRemarks,
      this.productCode,
      this.productDescription,
      this.serialNo,
      this.productId,
      this.serviceTypeId,
      this.picklist,
      this.currentJobSparepartsfromBag,
      this.currentJobSparepartsfromWarehouse,
      this.currentJobSparepartsfromPickList,
      this.aggregatedSpareparts,
      this.miscCharges,
      this.transportCharge,
      this.pickupCharge,
      this.secondaryEngineers,
      this.productModelId,
      this.isChargeableMisc,
      this.isChargeablePickup,
      this.isChargeableSolution,
      this.isChargeableTransport,
      this.chargeableSparepartIds,
      this.isDiscountApplied});

  Job.fromJson(Map<String, dynamic> json) {
    this.serviceRequestid = json["service_request_id"];
    this.serviceJobNo = json["service_job_no"];
    this.serviceType = json["service_type"];
    this.serviceJobStatus = json["service_job_status"];
    this.serviceDate = json["service_date"];
    this.customerName = json["customer"]?["name"];
    this.customerTelephone = json["customer"]?["telephone"];
    this.customerEmail = json["customer"]?["email"];
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
    this.estimatedSolutionIndoorCharges =
        json["solution"]?["estimated"]?["indoor_charges"]?["formatted"];
    this.estimatedSolutionOutdoorCharges =
        json["solution"]?["estimated"]?["outdoor_charges"]?["formatted"];
    this.actualSolutionCode = json["solution"]?["actual"]?["code"];
    this.actualSolutionDescription = json["solution"]?["actual"]?["solution"];
    this.actualSolutionIndoorCharges =
        json["solution"]?["actual"]?["indoor_charges"]?["formatted"];
    this.actualSolutionOutdoorCharges =
        json["solution"]?["actual"]?["outdoor_charges"]?["formatted"];
    this.remarks = json["remarks"]?["remarks"];
    this.adminRemarks = json["remarks"]?["admin_remarks"];
    this.productCode = json["product"]?["code"];
    this.productDescription = json["product"]?["description"];
    this.serialNo = json["warranty_info"]?["serial_no"];
    this.productId = json["product"]?["id"];
    this.serviceTypeId = json["service_type_id"];
    this.productModelId = json["product"]?["model_id"];

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

    this.picklist = json["bag_pick_list"]?['spareparts'] != null
        ? ((json["bag_pick_list"]?['spareparts'] as List)
                .map((e) => SparePart.fromJson(e))
                .toList())
            .where((element) => element.collectedAt == null)
            .toList()
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

    this.aggregatedSpareparts = [];

    this.aggregatedSpareparts?.addAll(currentJobSparepartsfromBag ?? []);

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

    var list = [];
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

  JobMetaData(
      {this.currentPage,
      this.from,
      this.lastPage,
      this.perPage,
      this.to,
      this.total,
      this.completed,
      this.uncompleted});

  JobMetaData.fromJson(Map<String, dynamic> json) {
    this.currentPage = json["current_page"];
    this.from = json["from"];
    this.lastPage = json["last_page"];
    this.perPage = json["per_page"];
    this.to = json["to"];
    this.total = json["total"];
    this.completed = json["completed"];
    this.uncompleted = json["uncompleted"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["id"] = "LALA";
    return data;
  }
}
