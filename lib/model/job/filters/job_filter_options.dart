class JobFilterOptions {
  List<ServiceType>? serviceTypes;
  List<ServiceJobStatus>? serviceJobStatuses;

  JobFilterOptions({
    this.serviceTypes,
    this.serviceJobStatuses,
  });

  JobFilterOptions.fromJson(Map<String, dynamic> json) {
    this.serviceTypes = (json['data']?['service_types'] as List)
        .map((i) => ServiceType.fromJson(i))
        .toList();
    this.serviceJobStatuses = (json['data']?['service_jobs_status'] as List)
        .map((i) => ServiceJobStatus.fromJson(i))
        .toList();
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["id"] = "LALA";
    return data;
  }
}

class ServiceType {
  int? id;
  String? serviceType;
  int? activityDuration;

  ServiceType({
    this.id,
    this.serviceType,
    this.activityDuration,
  });

  ServiceType.fromJson(Map<String, dynamic> json) {
    this.id = json["service_type_id"];
    this.serviceType = json["service_type"];
    this.activityDuration = json["activity_duration"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["id"] = this.id;

    return data;
  }
}

class ServiceJobStatus {
  int? id;
  String? serviceJobStatus;
  String? servieJobDescription;
  int? isAllowedToChangeEngineer;
  int? isAllowedToChangeForDelivery;

  ServiceJobStatus(
      {this.id,
      this.serviceJobStatus,
      this.servieJobDescription,
      this.isAllowedToChangeEngineer,
      this.isAllowedToChangeForDelivery});

  ServiceJobStatus.fromJson(Map<String, dynamic> json) {
    this.id = json["service_job_status_id"];
    this.serviceJobStatus = json["service_job_status"];
    this.servieJobDescription = json["service_job_desc"];
    this.isAllowedToChangeEngineer = json["is_allowed_to_change_engineer"];
    this.isAllowedToChangeForDelivery =
        json["is_allowed_to_change_for_delivery"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["id"] = this.id;

    return data;
  }
}
