class MiscellaneousItem {
  int? miscChargesId;
  String? remarks;
  String? amount;
  String? currency;
  String? formattedPrice;
  int? quantity;

  MiscellaneousItem(
      {this.miscChargesId,
      this.remarks,
      this.amount,
      this.currency,
      this.formattedPrice,
      this.quantity});

  MiscellaneousItem.fromJson(Map<String, dynamic> json) {
    this.miscChargesId = json["misc_charges_id"];
    this.remarks = json["remarks"];
    this.amount = json["charges"]?["amount"];
    this.currency = json["charges"]?["currency"];
    this.formattedPrice = json["charges"]?["formatted"];
    this.quantity = json["quantity"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["misc_charges_id"] = this.miscChargesId;
    data["remarks"] = this.remarks;
    data["amount"] = this.amount;

    return data;
  }
}
