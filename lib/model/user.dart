import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';

class User {
  String? user_id;
  String? email;
  String? reference_user_id;
  String? role_id;
  String? first_name;
  String? middle_name;
  String? last_name;
  String? full_name;
  String? gender;
  String? date_of_birth;
  String? civil_status;
  String? telephone;
  String? telephone2;
  String? fax;
  String? mobile;
  String? is_active;
  String? last_login;
  String? created_at;
  String? updated_at;
  String? last_login_ip;
  String? created_by;
  String? email_verified_at;
  String? updated_by;
  String? role;
  int? uncompletedJobsCount;
  int? completedJobsCount;
  int? allJobsCount;
  String? profileImage;

  User(
      {this.user_id,
      this.email,
      this.reference_user_id,
      this.role_id,
      this.first_name,
      this.middle_name,
      this.last_name,
      this.full_name,
      this.gender,
      this.date_of_birth,
      this.civil_status,
      this.telephone,
      this.telephone2,
      this.fax,
      this.mobile,
      this.is_active,
      this.last_login,
      this.created_at,
      this.updated_at,
      this.last_login_ip,
      this.created_by,
      this.email_verified_at,
      this.updated_by,
      this.role,
      this.uncompletedJobsCount,
      this.completedJobsCount,
      this.profileImage,
      this.allJobsCount});

  User.fromJson(Map<String, dynamic> json) {
    this.user_id = json["attributes"]?["user_id"];
    this.email = json["attributes"]?["email"];
    this.reference_user_id = json["attributes"]?["reference_user_id"];
    this.role_id = json["attributes"]?["role_id"];
    this.first_name = json["attributes"]?["first_name"];
    this.middle_name = json["attributes"]?["middle_name"];
    this.last_name = json["attributes"]?["last_name"];
    this.full_name = json["attributes"]?["full_name"];
    this.gender = json["attributes"]?["gender"];
    this.date_of_birth = json["attributes"]?["date_of_birth"];
    this.civil_status = json["attributes"]?["civil_status"];
    this.telephone = json["attributes"]?["telephone"];
    this.telephone2 = json["attributes"]?["telephone2"];
    this.fax = json["attributes"]?["fax"];
    this.mobile = json["attributes"]?["mobile"];
    this.is_active = json["attributes"]?["is_active"];
    this.last_login = json["attributes"]?["last_login"];
    this.created_at = json["attributes"]?["created_at"];
    this.updated_at = json["attributes"]?["updated_at"];
    this.last_login_ip = json["attributes"]?["last_login_ip"];
    this.created_by = json["attributes"]?["created_by"];
    this.email_verified_at = json["attributes"]?["email_verified_at"];
    this.updated_by = json["attributes"]?["updated_by"];
    this.role = json["relationships"]?["role"]?["attributes"]?["role"];
    this.profileImage = json["attributes"]?["profile_image"];
    this.uncompletedJobsCount = 0;
    this.completedJobsCount = 0;
    this.allJobsCount = 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["user_id"] = this.user_id;
    data["email"] = this.email;
    data["reference_user_id"] = this.reference_user_id;
    data["role_id"] = this.role_id;
    data["first_name"] = this.first_name;
    data["middle_name"] = this.middle_name;
    data["last_name"] = this.last_name;
    data["full_name"] = this.full_name;
    data["gender"] = this.gender;
    data["date_of_birth"] = this.date_of_birth;
    data["civil_status"] = this.civil_status;
    data["telephone"] = this.telephone;
    data["telephone2"] = this.telephone2;
    data["fax"] = this.fax;
    data["mobile"] = this.mobile;
    data["is_active"] = this.is_active;
    data["last_login"] = this.last_login;
    data["created_at"] = this.created_at;
    data["updated_at"] = this.updated_at;
    data["last_login_ip"] = this.last_login_ip;
    data["created_by"] = this.created_by;
    data["email_verified_at"] = this.email_verified_at;
    data["updated_by"] = this.updated_by;
    data["role"] = this.role;
    return data;
  }
}
