class PickupCharge {
  int? id;
  String? code;
  String? amount;
  String? currency;
  String? priceFormatted;
  String? pickupDescription;
  int? sstPercentage;
  double? sstTotal;
  double? lineTotal;

  PickupCharge(
      {this.id,
      this.code,
      this.amount,
      this.currency,
      this.priceFormatted,
      this.pickupDescription,
      this.sstPercentage,
      this.sstTotal,
      this.lineTotal});

  PickupCharge.fromJson(Map<String, dynamic> json) {
    this.id = json["pickup_charges_id"];
    this.code = json["pickup_charges_code"];
    this.amount = json["pickup_charges"]?["amount"];
    this.currency = json["pickup_charges"]?["currency"];
    this.priceFormatted = json["pickup_charges"]?["formatted"];
    this.pickupDescription = json["pickup_description"];
    this.sstPercentage = (((json["sst_percentage"] ?? 1) as num) * 100).toInt();
    this.sstTotal = (((this.sstPercentage ?? 0.0) / 100) *
        (double.parse(this.amount ?? "1")) /
        100);
    this.lineTotal = double.parse(
        ((double.parse(this.amount ?? "1") / 100) + (this.sstTotal ?? 1))
            .toStringAsFixed(2));
  }
}
