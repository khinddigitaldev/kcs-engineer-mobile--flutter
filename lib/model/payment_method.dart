class PaymentMethod {
  int? id;
  String? method;
  bool? hasQr;

  PaymentMethod({this.id, this.method, this.hasQr});

  PaymentMethod.fromJson(Map<String, dynamic> json) {
    this.id = json["payment_method_id"];
    this.method = json["payment_method"];
    this.hasQr = json["has_qr"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["payment_method_id"] = this.id;
    data["payment_method"] = this.method;
    data["has_qr"] = this.hasQr;
    return data;
  }
}
