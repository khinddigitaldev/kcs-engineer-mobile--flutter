class PaymentHistoryMeta {
  String? engineerId;
  String? insertedDate;
  num? totalAmount;
  String? currency;
  String? formatted;
  String? paymentStatus;

  PaymentHistoryMeta(
      {this.engineerId,
      this.insertedDate,
      this.totalAmount,
      this.currency,
      this.formatted,
      this.paymentStatus});

  PaymentHistoryMeta.fromJson(Map<String, dynamic> json) {
    this.engineerId = json["engineer_id"];
    this.insertedDate = json["inserted_date"];
    this.totalAmount = num.parse(json["total"]?["amount"] ?? "0") != "0"
        ? (num.parse(json["total"]?["amount"] ?? "0") / 100)
        : 0;
    this.currency = json["total"]?["currency"];
    this.formatted = json["total"]?["formatted"];
    this.paymentStatus = json["payment_status"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["engineer_id"] = this.engineerId;
    data["inserted_date"] = this.insertedDate;
    data["amount"] = this.totalAmount;
    data["currency"] = this.currency;
    data["formatted"] = this.formatted;
    data["payment_status"] = this.paymentStatus;
    return data;
  }
}
