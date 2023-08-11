import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';

class Part {
  String? name;
  String? model;
  String? noOfUnits;

  Part({this.name, this.model, this.noOfUnits});

  Part.fromJson(Map<String, dynamic> json) {
    this.name = json["name"];
    this.model = json["model"];
    this.noOfUnits = json["noOfUnits"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["name"] = this.name;
    data["model"] = this.model;
    data["noOfUnits"] = this.noOfUnits;

    return data;
  }
}
