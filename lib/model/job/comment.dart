import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';

class Comment {
  int? id;
  String? userId;
  String? customerName;
  String? insertedAt;
  String? insertedAtInAgoAnnotation;
  String? remarks;
  String? role;
  String? textColor;
  String? backgroundColor;

  Comment(
      {this.id,
      this.userId,
      this.customerName,
      this.insertedAt,
      this.insertedAtInAgoAnnotation,
      this.remarks,
      this.role,
      this.textColor,
      this.backgroundColor});

  Comment.fromJson(Map<String, dynamic> json) {
    this.id = json["cust_remarks_id"];
    this.userId = json["user_id"];
    this.customerName = json["customer_name"];
    this.insertedAt = json["inserted_at"];
    this.insertedAtInAgoAnnotation = json["inserted_at_human"];
    this.remarks = json["remarks"];
    this.role = json["role"];
    this.textColor = json["color"]?["text"];
    this.backgroundColor = json["color"]?["background"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["name"] = this.id;
    data["model"] = this.userId;
    data["noOfUnits"] = this.customerName;

    return data;
  }
}
