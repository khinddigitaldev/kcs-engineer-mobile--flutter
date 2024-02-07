class PickupCharge {
  int? id;
  String? code;
  String? amount;
  String? currency;
  String? priceFormatted;
  String? pickupDescription;

  PickupCharge(
      {this.id,
      this.code,
      this.amount,
      this.currency,
      this.priceFormatted,
      this.pickupDescription});

  PickupCharge.fromJson(Map<String, dynamic> json) {
    this.id = json["pickup_charges_id"];
    this.code = json["pickup_charges_code"];
    this.amount = json["pickup_charges"]?["amount"];
    this.currency = json["pickup_charges"]?["currency"];
    this.priceFormatted = json["pickup_charges"]?["formatted"];
    this.pickupDescription = json["pickup_description"];
  }
}
