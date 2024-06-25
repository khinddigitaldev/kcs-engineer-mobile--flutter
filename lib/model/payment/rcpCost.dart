import 'package:kcs_engineer/model/spareparts/sparepart.dart';

class RCPCost {
  bool? isDiscountValid;
  String? sparePartCost;
  String? pickListCost;
  String? solutionCost;
  String? transportCost;
  String? pickupCost;
  String? miscCost;
  String? total;
  String? totalRCP;
  String? totalSST;
  String? totalSSTRCP;
  String? discount;
  bool? isRCPValid;
  String? discountPercentage;
  List<RCPSparePart>? spareParts;
  List<RCPSparePart>? pickListItems;

  RCPCost({
    this.sparePartCost,
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
  });

  RCPCost.fromJson(Map<String, dynamic> json) {
    this.isDiscountValid = json["meta"]?["discount_valid"] == "1";
    this.discountPercentage = json["meta"]?["discount_percentage"];
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

    this.solutionCost = convertToCurrency((json["solution"] != null)
        ? (json["solution"]?["amount"]?["amount"].toString())
        : "0");

    this.totalSSTRCP = convertToCurrency(json["meta"] != null
        ? ((json["meta"]?["rcp_sst_total_sum"]?["amount"].toString()))
        : "0");

    this.totalSST = convertToCurrency(json["meta"] != null
        ? (json["meta"]?["sst_total_sum"]?["amount"].toString())
        : "0");
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

  RCPSparePart({
    this.sparepartsId,
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
  });

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
