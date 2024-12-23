class SecondaryEngineer {
  String? email;
  String? fullname;
  String? mobilePhone;
  String? employeeCode;
  String? profileImage;

  SecondaryEngineer({
    this.email,
    this.fullname,
    this.mobilePhone,
    this.employeeCode,
    this.profileImage,
  });

  SecondaryEngineer.fromJson(Map<String, dynamic> json) {
    this.email = json["email"];
    this.fullname = json["full_name"];
    this.mobilePhone = json["mobile_phone"];
    this.employeeCode = json["employee_code"];
    this.profileImage = json["profile_image"] == null
        ? "https://www.pngitem.com/pimgs/m/30-307416_profile-icon-png-image-free-download-searchpng-employee.png"
        : json["profile_image"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["email"] = this.email;
    data["full_name"] = this.fullname;
    data["mobile_phone"] = this.mobilePhone;
    data["employee_code"] = this.employeeCode;
    data["profile_image"] = this.profileImage;
    return data;
  }
}
