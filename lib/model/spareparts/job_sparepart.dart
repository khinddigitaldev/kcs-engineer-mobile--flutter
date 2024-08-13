

// class JobSparePart {
//   int? transactionId;
//   String? sparePartId;
//   String? quantity;
//   String? discount;
//   String? price;
//   String? sparePartCode;
//   String? description;

//   JobSparePart(
//       {this.transactionId,
//       this.sparePartId,
//       this.quantity,
//       this.discount,
//       this.price,
//       this.sparePartCode,
//       this.description});

//   JobSparePart.fromJson(Map<String, dynamic> json) {
//     this.transactionId = json["bag_transaction_id"];
//     this.sparePartId = json["attributes"]?["spareparts_id"];
//     this.quantity = json["attributes"]?["quantity_taken"];
//     this.discount = json["attributes"]?["discount"];
//     this.price = json["relationships"]?["sparePart"]?["price"];
//     this.sparePartCode =
//         json["relationships"]?["sparePart"]?["spareparts_code"];
//     this.description = json["relationships"]?["sparePart"]?["description"];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data["bag_transaction_id"] = this.transactionId;
//     data["spareparts_id"] = this.sparePartId;
//     data["quantity_taken"] = this.quantity;
//     data["discount"] = this.discount;
//     data["price"] = this.price;
//     data["spareparts_code"] = this.sparePartCode;
//     data["description"] = this.description;
//     return data;
//   }
// }
