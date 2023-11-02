class SparePart {
  int? id;
  String? code;
  String? description;
  String? priceAmount;
  String? priceCurrency;
  String? priceFormatted;
  String? from;
  int? quantity;
  int? selectedQuantity;
  bool? isSparePart;
  String? headingTitle;
  bool? isBomSpecific;
  String? collectedAt;

  SparePart(
      {this.id,
      this.code,
      this.description,
      this.priceAmount,
      this.priceCurrency,
      this.priceFormatted,
      this.from,
      this.quantity,
      this.selectedQuantity,
      this.isSparePart = true,
      this.isBomSpecific = false,
      this.collectedAt,
      this.headingTitle = ""});

  SparePart.fromJson(Map<String, dynamic> json) {
    this.id = json["id"] != null ? json["id"] : json["spareparts_id"];
    this.code = json["code"] != null ? json["code"] : json["spareparts_code"];
    this.description = json["description"];
    this.from = "";
    this.priceAmount =
        (json["price"] != null ? (json["price"]?["amount"]) : null);
    this.priceCurrency =
        (json["price"] != null ? (json["price"]?["currency"]) : null);
    this.priceFormatted =
        (json["price"] != null ? (json["price"]?["formatted"]) : null);

    this.quantity = json["quantity_taken"] != null
        ? json["quantity_taken"]
        : json["quantity"];
    this.selectedQuantity = 0;
    this.isSparePart = true;
    this.isBomSpecific = false;
    this.headingTitle = "";
    this.collectedAt = json["collected_at"];
  }

  SparePart.fromJsonStatusSpecific(Map<String, dynamic> json, String from) {
    this.id = json["spareparts_id"];
    this.code = json["spareparts_code"];
    this.description = json["description"];
    this.from = "";
    this.priceAmount =
        (json["price"] != null ? (json["price"]?["amount"]) : null);
    this.priceCurrency =
        (json["price"] != null ? (json["price"]?["currency"]) : null);
    this.priceFormatted =
        (json["price"] != null ? (json["price"]?["formatted"]) : null);

    this.quantity = json["quantity"];
    this.selectedQuantity = 0;
    this.isSparePart = true;
    this.isBomSpecific = false;
    this.headingTitle = "";

    this.from = from == "bag"
        ? "bag"
        : from == "warehouse"
            ? "warehouse"
            : "picklist";
  }

  static SparePart cloneInstance(SparePart value) {
    SparePart data = new SparePart();
    data.id = value.id;
    data.code = value.code;
    data.description = value.description;
    data.priceAmount = value.priceAmount;
    data.priceCurrency = value.priceCurrency;
    data.priceFormatted = value.priceFormatted;
    data.quantity = value.quantity;
    data.selectedQuantity = value.selectedQuantity;
    data.isSparePart = value.isSparePart;
    data.isBomSpecific = value.isBomSpecific;
    data.headingTitle = value.headingTitle;

    return data;
  }

  static List<SparePart> cloneArray(List<SparePart> value) {
    List<SparePart> data = [];

    value.forEach((element) {
      data.add(cloneInstance(element));
    });

    return data;
  }
}
