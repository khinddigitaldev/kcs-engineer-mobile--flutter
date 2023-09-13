class Problem {
  int? problemId;
  String? problemCode;
  String? problem;

  Problem({
    this.problemId,
    this.problemCode,
    this.problem,
  });

  Problem.fromJson(Map<String, dynamic> json) {
    this.problemId = json["problem_id"];
    this.problemCode = json["problem_code"];
    this.problem = json["problem"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["problem_id"] = this.problemId;
    data["problem_code"] = this.problemCode;
    data["problem"] = this.problem;

    return data;
  }
}
