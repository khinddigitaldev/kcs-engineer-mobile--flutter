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

  List<Map<String, dynamic>> ListOfbjectsToListofMaps(
      List<MiscellaneousItem> items) {
    List<Map<String, dynamic>> listOfMaps = [];
    items.forEach((element) {
      Map<String, dynamic> data;
      data = new Map<String, dynamic>();
      data["remarks"] = element.remarks;
      data["misc_charges"] = element.formattedPrice?.split("MYR")[1].trim();
      data["misc_charges_id"] = element.miscChargesId;
      data["quantity"] = element.quantity;

      listOfMaps.add(data);
    });

    return listOfMaps;
  }
}
