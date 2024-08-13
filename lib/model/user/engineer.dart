class Engineer {
  String? engineerId;
  String? fullName;
  String? employeeCode;
  String? role;
  String? email;
  String? contactNo;
  String? hubLocation;
  String? serviceCenterName;
  String? operatingHours;
  String? profileImage;

  Engineer({
    this.engineerId,
    this.fullName,
    this.employeeCode,
    this.role,
    this.email,
    this.contactNo,
    this.hubLocation,
    this.serviceCenterName,
    this.operatingHours,
    this.profileImage,
  });

  Engineer.fromJson(Map<String, dynamic> json) {
    this.engineerId = json["engineer_id"];
    this.fullName = json["full_name"];
    this.employeeCode = json["employee_code"];
    this.role = json["role"];
    this.email = json["email"];
    this.contactNo = json["contact_no"];
    this.hubLocation = json["hub_location"];
    this.serviceCenterName = json["service_center_name"];
    this.operatingHours = json["operating_hours"];
    this.profileImage = json["profile_image"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["engineer_id"] = this.engineerId;
    data["full_name"] = this.fullName;
    data["employee_code"] = this.employeeCode;
    data["role"] = this.role;
    data["email"] = this.email;
    data["contact_no"] = this.contactNo;
    data["hub_location"] = this.hubLocation;
    data["service_center_name"] = this.serviceCenterName;
    data["operating_hours"] = this.operatingHours;
    data["profile_image"] = this.profileImage;

    return data;
  }
}
