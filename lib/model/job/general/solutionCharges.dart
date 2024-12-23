class SolutionCharges {
  int? laberChargesProductId;
  int? productModelId;
  String? charges;
  String? labourGroupCode;
  String? description;

  SolutionCharges({
    this.laberChargesProductId,
    this.productModelId,
    this.charges,
    this.labourGroupCode,
    this.description,
  });

  SolutionCharges.fromJson(Map<String, dynamic> json) {
    this.laberChargesProductId = json["labour_charges_product_id"];
    this.productModelId = json["product_model_id"];
    this.charges = json["charges"];
    this.labourGroupCode = json["labour_group_code"];
    this.description = json["description"];
  }
}
