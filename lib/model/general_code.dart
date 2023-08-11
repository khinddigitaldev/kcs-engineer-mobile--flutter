import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';

class GeneralCode {
  String? type;
  String? generalCodeId;
  String? itemCode;
  String? description;
  String? price;
  int? stock;
  String? transactionId;
  int? maxpage;

  GeneralCode(
      {this.type,
      this.generalCodeId,
      this.itemCode,
      this.description,
      this.stock,
      this.price,
      this.transactionId,
      this.maxpage});

  GeneralCode.fromJson(Map<String, dynamic> json) {
    this.type = json["type"];
    this.generalCodeId = json["general_code_id"];
    this.itemCode = json["attributes"]?["item_code"];
    this.description = json["attributes"]?["description"];
    this.price = json["attributes"]?["price"];
    stock = 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["type"] = this.type;
    data["general_code_id"] = this.generalCodeId;
    data["item_code"] = this.itemCode;
    data["description"] = this.description;
    data["price"] = this.price;

    return data;
  }
}
