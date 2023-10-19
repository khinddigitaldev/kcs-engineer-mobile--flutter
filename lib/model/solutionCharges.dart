class SolutionCharges {
  int? laberChargesProductId;
  int? productModelId;
  String? indoorCharges;
  String? outdoorCharges;
  String? labourGroupCode;
  String? description;

  SolutionCharges({
    this.laberChargesProductId,
    this.productModelId,
    this.indoorCharges,
    this.outdoorCharges,
    this.labourGroupCode,
    this.description,
  });

  SolutionCharges.fromJson(Map<String, dynamic> json) {
    this.laberChargesProductId = json["labour_charges_product_id"];
    this.productModelId = json["product_model_id"];
    this.indoorCharges = json["indoor_charges"];
    this.outdoorCharges = json["outdoor_charges"];
    this.labourGroupCode = json["labour_group_code"];
    this.description = json["description"];
  }
}
