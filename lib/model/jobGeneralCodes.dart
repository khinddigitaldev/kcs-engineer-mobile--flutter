import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';

class JobGeneralCode {
  String? type;
  String? generalCodeId;
  int? generalCodeTransactonId;
  String? itemCode;
  String? description;
  String? price;
  int? stock;

  JobGeneralCode(
      {this.type,
      this.generalCodeId,
      this.generalCodeTransactonId,
      this.itemCode,
      this.description,
      this.stock,
      this.price});

  JobGeneralCode.fromJson(Map<String, dynamic> json) {
    this.type = json["type"];
    this.generalCodeTransactonId = json["general_code_transaction_id"];
    this.generalCodeId =
        json["relationships"]?["general_code"]?["general_code_id"];
    this.itemCode = this.itemCode =
        json["relationships"]?["general_code"]?["attributes"]?["item_code"];
    this.description =
        json["relationships"]?["general_code"]?["attributes"]?["description"];
    this.price = json["attributes"]?["price"];
    stock = 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["general_code_transaction_id"] = this.generalCodeTransactonId;
    data["type"] = this.type;
    data["general_code_id"] = this.generalCodeId;
    data["item_code"] = this.itemCode;
    data["description"] = this.description;
    data["price"] = this.price;

    return data;
  }
}
