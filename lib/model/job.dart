import 'dart:convert';

import 'package:kcs_engineer/model/general_code.dart';
import 'package:kcs_engineer/model/jobGeneralCodes.dart';
import 'package:kcs_engineer/model/user_sparepart.dart';

Job jobFromJson(String str) => Job.jobListfromJson(json.decode(str));

class Job {
  int? id;
  String? date;
  String? time;
  String? dateTime;
  String? status;
  List<dynamic>? paymentMethod;
  String? address;
  String? postcode;
  String? problem;
  String? purchaseDate;
  int? solutionId;
  String? solutionCode;
  String? solution;
  String? comment;
  String? customerName;
  String? customerContactNo;
  String? customerAddress1;
  String? customerAddress2;
  String? customerEmail;
  String? customerPostCode;
  String? productDescription;
  String? productModel;
  String? productCode;
  String? location;
  String? serialNo;
  String? refNo;
  String? sequence;
  bool? isProductsAdded;
  bool? isUnderWarranty;
  bool? isChargeable;
  num? sumSubTotal;
  num? sumDiscount;
  num? sumTotal;
  bool? jobOrderHasPayment;

  List<JobSparePart>? jobSpareParts;
  List<JobGeneralCode>? generalCodes;

  Map<String, dynamic>? attachments;

  Job(
      {this.id,
      this.date,
      this.time,
      this.dateTime,
      this.status,
      this.postcode,
      this.address,
      this.problem,
      this.solutionId,
      this.purchaseDate,
      this.paymentMethod,
      this.solutionCode,
      this.solution,
      this.comment,
      this.customerName,
      this.customerContactNo,
      this.customerAddress1,
      this.customerAddress2,
      this.customerEmail,
      this.customerPostCode,
      this.productDescription,
      this.productModel,
      this.productCode,
      this.location,
      this.serialNo,
      this.refNo,
      this.sequence,
      this.isProductsAdded,
      this.isUnderWarranty,
      this.jobSpareParts,
      this.generalCodes,
      this.isChargeable,
      this.sumSubTotal,
      this.sumDiscount,
      this.sumTotal,
      this.jobOrderHasPayment,
      this.attachments});

  Job.jobListfromJson(Map<String, dynamic> json) {
    this.id = json["job_order_id"];
    this.date = json["attributes"]?["service_date"];
    this.time =
        json["relationships"]?["service_slot"]?["attributes"]?["description"];
    this.dateTime =
        '${(this.date != null ? this.date.toString() : "-")} ${(this.time != null ? this.time.toString() : "")}';
    this.status = json["relationships"]?["job_order_status"]?["attributes"]
        ["job_order_desc"];
    this.address =
        json["relationships"]?["shipping_address"]?["attributes"]?["street"];
    this.problem = json["attributes"]?["problems"];

    this.purchaseDate = json["relationships"]?["warranty_registration"]
        ?["attributes"]?["purchase_date"];

    this.solutionId = json["relationships"]?["solution"]?["solution_id"];
    this.solutionCode =
        json["relationships"]?["solution"]?["attributes"]?["solution_code"];
    this.solution =
        json["relationships"]?["solution"]?["attributes"]?["solution"];
    this.comment = json["attributes"]?["comments"];
    this.paymentMethod = json["attributes"]?["payment_transactions"];
    this.customerName =
        json["relationships"]?["customer"]?["attributes"]?["full_name"];
    this.customerContactNo =
        json["relationships"]?["customer"]?["attributes"]?["mobile"];
    this.customerAddress1 =
        json["relationships"]?["shipping_address"]?["attributes"]?["street"];
    this.customerAddress2 = json["relationships"]?["shipping_address"]
        ?["attributes"]?["address_name1"];
    this.customerEmail =
        json["relationships"]?["customer"]?["attributes"]?["email"];
    this.postcode = json["relationships"]?["shipping_address"]?["relationships"]
        ?["post_code"]?["attributes"]?["postcode"];
    this.customerPostCode = json["relationships"]?["shipping_address"]
        ?["relationships"]?["post_code"]?["attributes"]?["postcode"];
    this.productDescription = json["relationships"]?["product"]?["attributes"]
        ?["product_description"];
    this.productModel = json["relationships"]?["product"]?["relationships"]
        ?["productModel"]?["attributes"]?["product_model"];
    this.productCode =
        json["relationships"]?["product"]?["attributes"]?["product_code"];
    this.productCode =
        json["relationships"]?["product"]?["attributes"]?["product_code"];
    this.location =
        json["relationships"]?["product"]?["attributes"]?["brand_id"];
    this.serialNo = json["relationships"]?["warranty_registration"]
        ?["attributes"]?["serial_no"];
    this.refNo = json["attributes"]?["reference_job_order_no"];
    this.isProductsAdded = json["relationships"]?["product"] != null;
    this.sequence = json["attributes"]?["sequence"];
    this.isChargeable =
        json["attributes"]?["chargerable"] == "1" ? true : false;
    this.isChargeable =
        json["attributes"]?["chargerable"] == "1" ? true : false;
  }

  Job.selectedJobFromJson(Map<String, dynamic> json) {
    this.id = json["data"]?["job_order_id"];
    this.date = json["data"]?["attributes"]?["service_date"];
    this.time = json["data"]?["time"];

    this.time = json["data"]?["relationships"]?["service_slot"]?["attributes"]
        ?["description"];
    this.dateTime =
        '${(this.date != null ? this.date.toString() : "-")} ${(this.time != null ? this.time.toString() : "")}';

    this.status = json["data"]?["relationships"]?["job_order_status"]
        ?["attributes"]?["job_order_desc"];
    this.address = json["data"]?["relationships"]?["shipping_address"]
        ["attributes"]?["street"];
    this.problem = json["data"]?["attributes"]?["problems"];
    this.comment = json["data"]?["attributes"]?["comments"];
    this.paymentMethod = json["data"]?["attributes"]?["payment_transactions"];
    this.isChargeable =
        json["data"]?["attributes"]?["chargerable"] == "1" ? true : false;
    this.customerName = json["data"]?["relationships"]?["customer"]
        ?["attributes"]?["full_name"];
    this.purchaseDate = json["data"]?["relationships"]?["warranty_registration"]
        ?["attributes"]?["purchase_date"];
    this.customerContactNo =
        json["data"]?["relationships"]?["customer"]?["attributes"]?["mobile"];
    this.customerAddress1 = json["data"]?["relationships"]?["shipping_address"]
        ["attributes"]?["street"];
    this.customerAddress2 = json["data"]?["relationships"]?["shipping_address"]
        ["attributes"]?["address_name1"];
    this.customerEmail =
        json["data"]?["relationships"]?["customer"]?["attributes"]?["email"];
    this.customerPostCode = json["data"]?["relationships"]?["shipping_address"]
        ["relationships"]?["post_code"]?["attributes"]?["postcode"];
    this.productDescription =
        json["data"]?["relationships"]?["product"]?["product_description"];
    this.productModel = json["data"]?["relationships"]?["product"]
        ?["product_model"]?["product_model"];
    this.productCode = json["data"]["relationships"]?["product"]?["attributes"]
        ?["product_code"];
    this.location = json["data"]?["relationships"]?["product"]?["brand_id"];
    this.serialNo = json["data"]?["relationships"]?["warranty_registration"]
        ?["attributes"]?["serial_no"];
    this.postcode = json["data"]?["relationships"]?["shipping_address"]
        ?["relationships"]?["post_code"]?["attributes"]?["postcode"];
    this.refNo = json["data"]?["attributes"]?["reference_job_order_no"];
    this.isProductsAdded = json["data"]?["relationships"]?["product"] != null;
    this.isUnderWarranty = json["meta"]?["underWarranty"];
    this.jobOrderHasPayment = json["meta"]?["jobOrderHasPayment"];

    this.productModel = json['data']?["relationships"]?["product"]
        ?["relationships"]?["productModel"]?["attributes"]?["product_model"];
    this.productCode = json['data']?["relationships"]?["product"]?["attributes"]
        ?["product_code"];
    this.productDescription = json['data']?["relationships"]?["product"]
        ?["attributes"]?["product_description"];
    this.solution =
        json['data']?["relationships"]?["solution"]?["attributes"]?["solution"];
    this.solutionCode = json['data']?["relationships"]?["solution"]
        ?["attributes"]?["solution_code"];
    this.solutionId =
        json['data']?["relationships"]?["solution"]?["solution_id"];
    this.attachments = json['data']?["relationships"]?["attachments"];
    print('asdasd');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["id"] = this.id;
    data["date"] = this.date;
    data["time"] = this.time;
    data["status"] = this.status;
    data["address"] = this.address;
    data["problem"] = this.problem;
    data["comment"] = this.comment;
    data["payment_transactions"] = this.paymentMethod;
    data["customerName"] = this.customerName;
    data["customerContactNo"] = this.customerContactNo;
    data["customerAddress1"] = this.customerAddress1;
    data["customerAddress2"] = this.customerAddress2;
    data["customerEmail"] = this.customerEmail;
    data["customerPostCode"] = this.customerPostCode;
    data["productDescription"] = this.productDescription;
    data["productModel"] = this.productModel;
    data["location"] = this.location;
    data["serialNo"] = this.serialNo;
    data["refNo"] = this.refNo;
    data["isProductsAdded"] = this.isProductsAdded;
    data["isUnderWarranty"] = this.isUnderWarranty;
    data["jobOrderHasPayment"] = this.jobOrderHasPayment;
    data["sequence"] = this.sequence;
    return data;
  }
}
