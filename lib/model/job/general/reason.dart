class Reason {
  int? id;
  int? statusId;
  String? reason;

  Reason({
    this.id,
    this.statusId,
    this.reason,
  });

  Reason.fromJson(Map<String, dynamic> json) {
    this.id = json["service_request_cancellation_reason_id"];
    this.statusId = json["service_request_status_id"];
    this.reason = json["reason"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["email"] = this.id;
    data["full_name"] = this.statusId;
    data["mobile_phone"] = this.reason;
    return data;
  }
}
