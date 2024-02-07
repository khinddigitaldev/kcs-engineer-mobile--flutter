import 'package:kcs_engineer/model/spareparts/sparepart.dart';

class AppVersion {
  String? version;
  String? buildNo;
  String? apkUrl;
  List<String>? releaseNotes;
  bool? isForceUpdate;

  AppVersion({
    this.version,
    this.buildNo,
    this.apkUrl,
    this.releaseNotes,
    this.isForceUpdate,
  });

  AppVersion.fromJson(Map<String, dynamic> json) {
    this.version = json["latestVersion"];
    this.buildNo = json["latestVersionCode"];
    this.apkUrl = json["url"];
    this.releaseNotes = json["releaseNotes"] != null
        ? (json["releaseNotes"] as List).map((e) => e.toString()).toList()
        : [];

    this.isForceUpdate = json["is_force_update"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();

    return data;
  }
}
