class PaymentMethod {
  int? id;
  String? method;
  bool? hasQr;
  String? qrText;

  PaymentMethod({this.id, this.method, this.hasQr});

  PaymentMethod.fromJson(Map<String, dynamic> json) {
    this.id = json["payment_method_id"];
    this.method = json["payment_method"];
    this.hasQr = json["has_qr"];
    this.qrText = json["qr_string"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["payment_method_id"] = this.id;
    data["payment_method"] = this.method;
    data["has_qr"] = this.hasQr;
    data["qr_string"] = this.qrText;
    return data;
  }
}
