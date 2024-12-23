import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';

class PaymentHistoryItem {
  String? date;
  String? orderReferenceNo;
  String? orderStatus;
  String? chargeable;
  String? paymentMethod;
  String? paymentAmount;

  PaymentHistoryItem(
      {this.date,
      this.orderReferenceNo,
      this.orderStatus,
      this.chargeable,
      this.paymentMethod,
      this.paymentAmount});

  PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    this.date = json["date"];
    this.orderReferenceNo = json["job_order_reference_no"];
    this.orderStatus = json["job_order_status"];
    this.chargeable = json["chargeable"];
    this.paymentMethod = json["payment_method"];
    this.paymentAmount = json["payment_amount"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["date"] = this.date;
    data["job_order_reference_no"] = this.orderReferenceNo;
    data["job_order_status"] = this.orderStatus;
    data["chargeable"] = this.chargeable;
    data["payment_method"] = this.paymentMethod;
    data["payment_amount"] = this.paymentAmount;

    return data;
  }
}
