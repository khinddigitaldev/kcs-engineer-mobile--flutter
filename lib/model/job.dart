class JobData {
  List<Job>? jobs;
  JobMetaData? meta;

  JobData({
    this.jobs,
    this.meta,
  });

  JobData.selectedJobFromJson(Map<String, dynamic> json) {
    this.jobs = (json['data'] as List).map((i) => Job.fromJson(i)).toList();
    this.meta = JobMetaData.fromJson(json["meta"]);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["id"] = "LALA";
    return data;
  }
}

class Job {
  int? id;
  String? serviceJobNo;
  String? serviceType;
  String? serviceJobStatus;
  String? serviceDate;
  String? serviceTime;
  String? customerName;
  String? customerTelephone;
  String? customerEmail;
  String? customerAddressName;
  String? serviceAddressStreet;
  String? serviceAddressCity;
  String? serviceAddressPostcode;
  String? serviceAddressState;
  String? problemCode;
  String? problemDescription;
  String? remarks;
  String? adminRemarks;
  String? productCode;
  String? productDescription;

  Job({
    this.id,
    this.serviceJobNo,
    this.serviceType,
    this.serviceJobStatus,
    this.serviceDate,
    this.serviceTime,
    this.customerName,
    this.customerTelephone,
    this.customerEmail,
    this.customerAddressName,
    this.serviceAddressStreet,
    this.serviceAddressCity,
    this.serviceAddressPostcode,
    this.serviceAddressState,
    this.problemCode,
    this.problemDescription,
    this.remarks,
    this.adminRemarks,
    this.productCode,
    this.productDescription,
  });

  Job.fromJson(Map<String, dynamic> json) {
    this.id = json["service_request_id"];
    this.serviceJobNo = json["service_job_no"];
    this.serviceType = json["service_type"];
    this.serviceJobStatus = json["service_job_status"];
    this.serviceDate = json["service_date"];
    this.customerName = json["customer"]?["name"];
    this.customerTelephone = json["customer"]?["telephone"];
    this.customerEmail = json["customer"]?["email"];
    this.customerAddressName = json["customer"]?["address_name"];
    this.serviceAddressStreet = json["service_address"]?["street"];
    this.serviceAddressCity = json["service_address"]?["city"];
    this.serviceAddressPostcode = json["service_address"]?["postcode"];
    this.serviceAddressState = json["service_address"]?["state"];
    this.problemCode = json["problem"]?["code"];
    this.problemDescription = json["problem"]?["description"];
    this.remarks = json["remarks"]?["remarks"];
    this.adminRemarks = json["remarks"]?["admin_remarks"];
    this.productCode = json["product"]?["code"];
    this.productDescription = json["product"]?["description"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["id"] = this.id;

    return data;
  }
}

class JobMetaData {
  int? currentPage;
  int? from;
  int? lastPage;
  int? perPage;
  int? to;
  int? total;
  int? completed;
  int? uncompleted;

  JobMetaData(
      {this.currentPage,
      this.from,
      this.lastPage,
      this.perPage,
      this.to,
      this.total,
      this.completed,
      this.uncompleted});

  JobMetaData.fromJson(Map<String, dynamic> json) {
    this.currentPage = json["current_page"];
    this.from = json["from"];
    this.lastPage = json["last_page"];
    this.perPage = json["per_page"];
    this.to = json["to"];
    this.total = json["total"];
    this.completed = json["completed"];
    this.uncompleted = json["uncompleted"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["id"] = "LALA";
    return data;
  }
}
