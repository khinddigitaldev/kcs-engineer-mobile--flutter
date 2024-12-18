import 'package:kcs_engineer/model/spareparts/sparepart.dart';

class RCPCost {
  bool? isDiscountValid;
  String? sparePartCost;
  String? pickListCost;
  SolutionCost? solutionCost;
  String? transportCost;
  String? pickupCost;
  String? miscCost;
  String? total;
  String? totalRCP;
  num? totalAmount;
  num? totalAmountRCP;
  String? totalSST;
  String? totalSSTRCP;
  num? totalAmountSST;
  num? totalAmountSSTRCP;
  String? discount;
  bool? isRCPValid;
  num? discountPercentage;
  List<RCPSparePart>? spareParts;
  List<RCPSparePart>? pickListItems;

  num? discountTotalSumVal;
  num? rcpDiscountTotalSumVal;

  String? discountTotalSumFormatted;
  String? rcpDiscountTotalSumFormatted;

  RCPCost(
      {this.sparePartCost,
      this.solutionCost,
      this.pickListCost,
      this.transportCost,
      this.pickupCost,
      this.miscCost,
      this.isDiscountValid,
      this.total,
      this.spareParts,
      this.pickListItems,
      this.discount,
      this.isRCPValid,
      this.totalRCP,
      this.totalSSTRCP,
      this.totalSST,
      this.totalAmount,
      this.totalAmountRCP,
      this.totalAmountSST,
      this.totalAmountSSTRCP,
      this.discountTotalSumVal,
      this.rcpDiscountTotalSumVal,
      this.discountTotalSumFormatted,
      this.rcpDiscountTotalSumFormatted});

  RCPCost.fromJson(Map<String, dynamic> json) {
    this.isDiscountValid = json["meta"]?["discount_valid"] == "1";
    // this.discountPercentage = json["meta"]?["discount_percentage"];
    // var list1 = (json['spareparts'] as List)
    //     .map((i) => RCPSparePart.fromJson(i))
    //     .toList();
    // var list2 = list1
    //     .map((e) => num.parse((this.isDiscountValid ?? false)
    //         ? e.rcpAmountVal ?? "0"
    //         : e.amountVal ?? "0"))
    //     .toList();

    // var list3 = list2.reduce((value, element) => value + element);
    this.sparePartCost =
        json['spareparts'] != null && (json['spareparts'] as List).length > 0
            ? convertToCurrency(((((json['spareparts'] as List)
                        .map((i) => RCPSparePart.fromJson(i))
                        .toList())
                    .map((e) => num.parse(e.amountVal ?? "0"))
                    .toList())
                .reduce((value, element) => value + element)).toString())
            : convertToCurrency(null);

    this.pickListCost =
        json['picklist'] != null && (json['picklist'] as List).length > 0
            ? convertToCurrency(((((json['picklist'] as List)
                        .map((i) => RCPSparePart.fromJson(i))
                        .toList())
                    .map((e) => num.parse(e.amountVal ?? "0"))
                    .toList())
                .reduce((value, element) => value + element)).toString())
            : convertToCurrency(null);

    this.spareParts =
        json['spareparts'] != null && (json['spareparts'] as List).length > 0
            ? (json['spareparts'] as List)
                .map((i) => RCPSparePart.fromJson(i))
                .toList()
            : [];

    this.pickListItems =
        json['picklist'] != null && (json['picklist'] as List).length > 0
            ? (json['picklist'] as List)
                .map((i) => RCPSparePart.fromJson(i))
                .toList()
            : [];

    this.miscCost = convertToCurrency(json['misc'] != null
        ? ((json['misc'] as List)
            .map((i) => RCPSparePart.fromJson(i))
            .toList()
            .map((e) => num.parse(e.amountVal ?? "0"))
            .reduce((value, element) => value + element)).toString()
        : "0.0");

    this.transportCost = convertToCurrency(json["transport"] != null
        ? (json["transport"]?["amount"]?["amount"].toString())
        : null);

    this.pickupCost = convertToCurrency(json["pickup"] != null
        ? (json["pickup"]?["amount"]?["amount"].toString())
        : null);

    this.total = convertToCurrency(json["meta"] != null
        ? ((json["meta"]?["total_sum"]?["amount"].toString()))
        : "0");

    this.totalRCP = convertToCurrency(json["meta"] != null
        ? (json["meta"]?["total_sum_rcp"]?["amount"].toString())
        : "0");

    this.isRCPValid =
        json["meta"] != null ? (json["meta"]?["is_rcp_valid"]) : null;

    this.discount = (num.parse(
                    json["meta"]?["total_sum"]?["amount"].toString() ?? "0") >
                0) &&
            (num.parse(json["meta"]?["total_sum_rcp"]?["amount"].toString() ??
                    "0") >
                0)
        ? '- MYR ${((num.parse(json["meta"]?["total_sum"]?["amount"].toString() ?? "0") - num.parse(json["meta"]?["total_sum_rcp"]?["amount"].toString() ?? "0")) / 100).toStringAsFixed(2)}'
        : "MYR 0.00";

    this.solutionCost = json["solution"] != null
        ? SolutionCost.fromJson(json["solution"])
        : null;

    this.totalSSTRCP = convertToCurrency(json["meta"] != null
        ? ((json["meta"]?["rcp_sst_total_sum"]?["amount"].toString()))
        : "0");

    this.totalSST = convertToCurrency(json["meta"] != null
        ? (json["meta"]?["sst_total_sum"]?["amount"].toString())
        : "0");
    this.totalAmount = json["meta"] != null
        ? ((num.parse(json["meta"]?["total_sum"]?["amount"] ?? "0")) / 100)
        : 0;
    this.totalAmountRCP = json["meta"] != null
        ? ((num.parse(json["meta"]?["total_sum_rcp"]?["amount"] ?? "0") / 100))
        : 0;
    this.totalAmountSST = json["meta"] != null
        ? ((num.parse(json["meta"]?["sst_total_sum"]?["amount"] ?? "0") / 100))
        : 0;
    this.totalAmountSSTRCP = json["meta"] != null
        ? ((num.parse(json["meta"]?["rcp_sst_total_sum"]?["amount"] ?? "0") /
            100))
        : 0;

    this.discountTotalSumVal = json["meta"] != null
        ? ((num.parse(
                json["meta"]?["cf_discount_total_sum"]?["amount"] ?? "0") /
            100))
        : 0;
    this.rcpDiscountTotalSumVal = json["meta"] != null
        ? ((num.parse(
                json["meta"]?["rcp_cf_discount_total_sum"]?["amount"] ?? "0") /
            100))
        : 0;
    this.discountTotalSumFormatted =
        json["meta"]?["cf_discount_total_sum"]?["formatted"];
    this.rcpDiscountTotalSumFormatted =
        json["meta"]?["rcp_cf_discount_total_sum"]?["formatted"];
  }

  String convertToCurrency(String? input) {
    if (input != null && input != "0" && input != "0.0") {
      input = input?.replaceFirst(RegExp('^0+'), '');
      input = 'MYR $input';
      int length = input.length;
      input =
          input.substring(0, length - 2) + '.' + input.substring(length - 2);
      return input;
    } else {
      return 'MYR 0.00';
    }
  }
}

class RCPSparePart {
  int? sparepartsId;
  String? amountVal;
  String? amountFormatted;
  String? rcpAmountFormatted;
  String? rcpAmountVal;
  String? unitPrice;
  String? unitPriceFormatted;
  String? rcpUnitPriceFormatted;
  String? rcpUnitPriceVal;
  int? quantity;
  String? description;
  String? code;

  double? rcpAmountValAfterProcessing;
  String? rcpAmountFormatterAfterProcessing;

  double? amountValAfterProcessing;
  String? amountFormattedAfterProcessing;

  num? discountPercentage;

  double? rcpDiscountValAmount;
  String? rcpDiscountValFormatted;

  double? discountValAmount;
  String? discountFormattedAmount;

  RCPSparePart(
      {this.sparepartsId,
      this.amountFormatted,
      this.rcpAmountFormatted,
      this.rcpAmountVal,
      this.amountVal,
      this.quantity,
      this.description,
      this.code,
      this.unitPrice,
      this.unitPriceFormatted,
      this.rcpUnitPriceFormatted,
      this.rcpUnitPriceVal,
      this.rcpAmountValAfterProcessing,
      this.rcpAmountFormatterAfterProcessing,
      this.amountValAfterProcessing,
      this.amountFormattedAfterProcessing,
      this.discountPercentage,
      this.rcpDiscountValAmount,
      this.rcpDiscountValFormatted,
      this.discountValAmount,
      this.discountFormattedAmount});

  RCPSparePart.fromJson(Map<String, dynamic> json) {
    this.sparepartsId = json["spareparts_id"];

    this.amountFormatted = json["amount"]?["formatted"];
    this.rcpAmountFormatted = json["rcp_amount"]?["formatted"];
    this.rcpAmountVal = json["rcp_amount"]?["amount"];
    this.amountVal = json["amount"]?["amount"];

    this.quantity = (json["quantity"] is String)
        ? int.parse(json["quantity"])
        : json["quantity"];
    this.description = json["desc"];
    this.code = json["code"];
    this.unitPrice = json["unit_price"]?["amount"];
    this.unitPriceFormatted = json["unit_price"]?["formatted"];
    this.rcpUnitPriceFormatted = json["unit_rcp_price"]?["formatted"];
    this.rcpUnitPriceVal = json["unit_rcp_price"]?["amount"];

    this.rcpAmountValAfterProcessing =
        json["rcp_amount_after_processing"]?["amount"] != null
            ? double.parse(json["rcp_amount_after_processing"]?["amount"]) / 100
            : null;
    this.rcpAmountFormatterAfterProcessing =
        json["rcp_amount_after_processing"]?["formatted"] != null
            ? (json["rcp_amount_after_processing"]?["formatted"])
            : null;
    this.amountValAfterProcessing =
        json["amount_after_processing"]?["amount"] != null
            ? double.parse(json["amount_after_processing"]?["amount"]) / 100
            : null;
    this.amountFormattedAfterProcessing =
        json["amount_after_processing"]?["amount"] != null
            ? (json["amount_after_processing"]?["amount"])
            : null;
    this.discountPercentage = json["cf_discount_percentage"] != null
        ? json["cf_discount_percentage"] is int
            ? json["cf_discount_percentage"]
            : num.parse(json["cf_discount_percentage"]) * 100
        : null;
    this.rcpDiscountValAmount =
        json["rcp_cf_discount_amount"]?["amount"] != null
            ? double.parse(json["rcp_cf_discount_amount"]?["amount"]) / 100
            : null;
    this.rcpDiscountValFormatted = json["rcp_cf_discount_amount"]?["formatted"];
    this.discountValAmount = json["cf_discount_amount"]?["amount"] != null
        ? double.parse(json["cf_discount_amount"]?["amount"]) / 100
        : null;
    this.discountFormattedAmount = json["cf_discount_amount"]?["formatted"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();

    return data;
  }
}

class RCPMiscItem {
  int? miscChargesId;
  String? amountVal;
  String? amountFormatted;
  String? rcpAmountFormatted;
  String? rcpAmountVal;
  int? quantity;

  RCPMiscItem({
    this.amountFormatted,
    this.rcpAmountFormatted,
    this.rcpAmountVal,
    this.amountVal,
    this.quantity,
  });

  RCPMiscItem.fromJson(Map<String, dynamic> json) {
    this.miscChargesId = json["misc_charges_id"];
    this.amountFormatted = json["amount"]?["formatted"];
    this.rcpAmountFormatted = json["rcp_amount"]?["formatted"];
    this.rcpAmountVal = json["rcp_amount"]?["amount"];
    this.amountVal = json["amount"]?["amount"];
    this.quantity = json["quantity"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();

    return data;
  }
}

class SolutionCost {
  int? solutionId;
  double? amountVal;
  String? amountFormatted;
  String? rcpAmountFormatted;
  double? rcpAmountVal;
  int? quantity;

  double? rcpAmountValAfterProcessing;
  String? rcpAmountFormatterAfterProcessing;

  double? amountValAfterProcessing;
  String? amountFormattedAfterProcessing;

  num? discountPercentage;

  double? rcpDiscountValAmount;
  String? rcpDiscountValFormatted;

  double? discountValAmount;
  String? discountFormattedAmount;

  num? sstValAmount;
  num? rcpSSTValAmount;

  String? sstFormattedAmount;
  String? rcpSSTFormattedAmount;

  SolutionCost({
    this.solutionId,
    this.amountVal,
    this.sstValAmount,
    this.rcpSSTValAmount,
    this.sstFormattedAmount,
    this.rcpSSTFormattedAmount,
    this.amountFormatted,
    this.rcpAmountFormatted,
    this.rcpAmountVal,
    this.quantity,
    this.rcpAmountValAfterProcessing,
    this.rcpAmountFormatterAfterProcessing,
    this.amountValAfterProcessing,
    this.amountFormattedAfterProcessing,
    this.discountPercentage,
    this.rcpDiscountValAmount,
    this.rcpDiscountValFormatted,
    this.discountValAmount,
    this.discountFormattedAmount,
  });

  SolutionCost.fromJson(Map<String, dynamic> json) {
    this.solutionId = json["solution_id"];
    this.amountVal = json["amount"]?["amount"] != null
        ? double.parse(json["amount"]?["amount"]) / 100
        : null;
    this.amountFormatted = json["amount"]?["formatted"];
    this.rcpAmountFormatted = json["rcp_amount"]?["formatted"];
    this.rcpAmountVal = json["rcp_amount"]?["amount"] != null
        ? double.parse(json["rcp_amount"]?["amount"]) / 100
        : null;
    this.quantity = json["quantity"];
    this.rcpAmountValAfterProcessing =
        json["rcp_amount_after_processing"]?["amount"] != null
            ? double.parse(json["rcp_amount_after_processing"]?["amount"]) / 100
            : null;
    this.rcpAmountFormatterAfterProcessing =
        json["rcp_amount_after_processing"]?["formatted"];
    this.amountValAfterProcessing =
        json["amount_after_processing"]?["amount"] != null
            ? double.parse(json["amount_after_processing"]?["amount"]) / 100
            : null;
    this.amountFormattedAfterProcessing =
        json["amount_after_processing"]?["amount"];
    this.discountPercentage = json["cf_discount_percentage"] is String
        ? (double.parse(json["cf_discount_percentage"]) * 100)
        : json["cf_discount_percentage"];
    this.rcpDiscountValAmount =
        json["rcp_cf_discount_amount"]?["amount"] != null
            ? double.parse(json["rcp_cf_discount_amount"]?["amount"]) / 100
            : null;
    this.rcpDiscountValFormatted = json["rcp_cf_discount_amount"]?["formatted"];
    this.discountValAmount = json["cf_discount_amount"]?["amount"] != null
        ? double.parse(json["cf_discount_amount"]?["amount"]) / 100
        : null;
    this.discountFormattedAmount = json["cf_discount_amount"]?["formatted"];
    this.sstValAmount = json["sst_amount"]?["amount"] != null
        ? num.parse(json["sst_amount"]?["amount"]) / 100
        : null;
    this.rcpSSTValAmount = json["rcp_sst_amount"]?["amount"] != null
        ? num.parse(json["rcp_sst_amount"]?["amount"]) / 100
        : null;
    this.sstFormattedAmount = json["sst_amount"]?["formatted"];
    this.rcpSSTFormattedAmount = json["rcp_sst_amount"]?["formatted"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();

    return data;
  }
}
