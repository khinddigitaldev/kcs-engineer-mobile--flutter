class TransportCharge {
  int? id;
  String? code;
  String? description;
  String? amount;
  String? currency;
  String? priceFormatted;

  TransportCharge(
      {this.id,
      this.code,
      this.amount,
      this.currency,
      this.priceFormatted,
      this.description});

  TransportCharge.fromJson(Map<String, dynamic> json) {
    this.id = json["transport_charges_group_id"];
    this.code = json["transport_charges_code"];
    this.amount = json["transport_charges"]?["amount"];
    this.currency = json["transport_charges"]?["currency"];
    this.priceFormatted = json["transport_charges"]?["formatted"];
    this.description = json['transport_charges_group_description'];
  }
}
