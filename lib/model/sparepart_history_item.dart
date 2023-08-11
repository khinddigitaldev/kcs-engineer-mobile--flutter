import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';

class SparePartHistoryItem {
  String? date;
  String? jobId;
  String? jobRefNo;
  String? sparepartsCode;
  String? description;
  String? quantity;
  int? maxpage;

  SparePartHistoryItem(
      {this.date,
      this.jobId,
      this.jobRefNo,
      this.sparepartsCode,
      this.description,
      this.quantity,
      this.maxpage});

  SparePartHistoryItem.fromJson(Map<String, dynamic> json) {
    this.date = json["attributes"]?["created_at"];
    this.jobId = json["relationships"]?["jobOrder"]?["job_order_id"].toString();
    this.jobRefNo = json["relationships"]?["jobOrder"]?["attributes"]
            ?["reference_job_order_no"]
        .toString();
    this.sparepartsCode =
        json["relationships"]?["sparePart"]?["attributes"]?["spareparts_code"];
    this.description =
        json["relationships"]?["sparePart"]?["attributes"]?["description"];
    this.quantity = json["attributes"]?["quantity_taken"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["date"] = this.date;
    data["jobId"] = this.jobId;
    data["spareparts_code"] = this.sparepartsCode;
    data["description"] = this.description;
    data["quantity"] = this.quantity;
    data["reference_job_order_no"] = this.jobRefNo;
    return data;
  }
}
