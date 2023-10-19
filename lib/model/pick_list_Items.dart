class PickListItems {
  List<PickListItemMetaData>? notCollected;
  List<PickListItemMetaData>? collected;

  PickListItems({
    this.notCollected,
    this.collected,
  });

  PickListItems.fromJson(Map<String, dynamic> json) {
    this.notCollected = json['not_collected'] != null
        ? (json['not_collected'] as List)
            .map((i) => PickListItemMetaData.fromJson(i))
            .toList()
        : null;
    this.collected = json['collected'] != null
        ? (json['collected'] as List)
            .map((i) => PickListItemMetaData.fromJson(i))
            .toList()
        : null;
  }
}

class PickListItemMetaData {
  int? id;
  String? serviceRequestId;
  int? sparePartId;
  String? sparePartCode;
  String? sparePartsDescription;
  String? quantityTaken;
  String? collectedAt;

  PickListItemMetaData(
      {this.id,
      this.serviceRequestId,
      this.sparePartId,
      this.sparePartCode,
      this.sparePartsDescription,
      this.quantityTaken,
      this.collectedAt});

  PickListItemMetaData.fromJson(Map<String, dynamic> json) {
    this.id = json["bag_pick_list_id"];
    this.serviceRequestId = json["service_request_id"];
    this.sparePartId = json["spareparts_id"];
    this.sparePartCode = json["spareparts_code"];
    this.sparePartsDescription = json["spareparts_description"];
    this.quantityTaken = json["quantity_taken"];
    this.collectedAt = json["collected_at"];
  }
}
