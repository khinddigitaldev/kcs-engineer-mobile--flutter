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
    this.description = json["transport_charges_group_description"] != null
        ? json["transport_charges_group_description"]
        : json["description"];
    this.amount = json["transport_charges"]?["amount"];
    this.currency = json["transport_charges"]?["currency"];
    this.priceFormatted = json["transport_charges"]?["formatted"];
  }

  static Map<String, dynamic> toJson(TransportCharge charge) {
    Map<String, dynamic> map = {};
    map["id"] = charge.id;
    map["code"] = charge.code;
    map["description"] = charge.description;
    map["amount"] = charge.amount;
    map["currency"] = charge.currency;
    map["priceFormatted"] = charge.priceFormatted;

    return map;
  }
}
