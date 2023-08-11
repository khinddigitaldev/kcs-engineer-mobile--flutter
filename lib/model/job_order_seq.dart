import 'dart:convert';

JobOrderSequence jobFromJson(String str) =>
    JobOrderSequence.fromJson(json.decode(str));

class JobOrderSequence {
  int? jobOrderId;
  int? sequence;

  JobOrderSequence({
    this.jobOrderId,
    this.sequence,
  });

  JobOrderSequence.fromJson(Map<String, dynamic> json) {
    this.jobOrderId = json["job_order_id"];
    this.sequence = json["sequence"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["job_order_id"] = this.jobOrderId;
    data["sequence"] = this.sequence;
    return data;
  }
}
