import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';

class PaymentMethod {
  int? id;
  String? code;
  String? description;

  PaymentMethod({this.id, this.code, this.description});

  PaymentMethod.fromJson(Map<String, dynamic> json) {
    this.id = json["payment_method_id"];
    this.code = json["attributes"]?["payment_method_code"];
    this.description = json["attributes"]?["payment_description"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["payment_method_id"] = this.id;
    data["payment_method_code"] = this.code;
    data["payment_description"] = this.description;
    return data;
  }
}
