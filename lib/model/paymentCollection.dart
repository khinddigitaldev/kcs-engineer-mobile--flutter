import 'package:kcs_engineer/model/sparepart.dart';

class PaymentCollection {
  String? amount;
  String? currency;
  String? formatted;

  PaymentCollection({
    this.amount,
    this.currency,
    this.formatted,
  });

  PaymentCollection.fromJson(Map<String, dynamic> json) {
    this.amount = json["amount"];
    this.currency = json["currency"];
    this.formatted = json["formatted"];
  }
}
