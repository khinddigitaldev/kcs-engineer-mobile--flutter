import 'package:kcs_engineer/model/sparepart.dart';

class BagMetaData {
  List<SparePart>? partOfBom;
  List<SparePart>? notPartOfBom;

  BagMetaData({
    this.partOfBom,
    this.notPartOfBom,
  });

  BagMetaData.selectedJobFromJson(Map<String, dynamic> json) {
    this.partOfBom = json['part_of_bom'] != null
        ? (json['part_of_bom'] as List)
            .map((i) => SparePart.fromJson(i))
            .toList()
        : [];
    this.notPartOfBom = json['not_part_of_bom'] != null
        ? (json['not_part_of_bom'] as List)
            .map((i) => SparePart.fromJson(i))
            .toList()
        : [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();

    return data;
  }
}
