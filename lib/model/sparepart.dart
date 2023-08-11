import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';

class SparePart {
  String? type;
  String? sparepartsId;
  String? sparepartsCode;
  String? description;
  String? stock;
  num quantity = 0;
  double discount = 0.0;
  String? price;
  String? remarks;
  int? maxpage;

  SparePart(
      {this.type,
      this.sparepartsId,
      this.sparepartsCode,
      this.description,
      this.stock,
      this.quantity = 0,
      this.discount = 0.0,
      this.price,
      this.remarks,
      this.maxpage});

  SparePart.fromJson(Map<String, dynamic> json) {
    this.type = json["type"];
    this.sparepartsId = json["spareparts_id"];
    this.sparepartsCode = json["attributes"]?["spareparts_code"];
    this.description = json["attributes"]?["description"];
    this.stock = json["attributes"]?["quantity"];
    this.price = json["attributes"]?["price"];
    this.remarks = json["attributes"]?["remarks"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["type"] = this.type;
    data["spareparts_id"] = this.sparepartsId;
    data["spareparts_code"] = this.sparepartsCode;
    data["description"] = this.description;
    data["quantity"] = this.stock;
    data["price"] = this.price;
    data["remarks"] = this.remarks;

    return data;
  }
}
