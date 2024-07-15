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

  static Map<String, dynamic> toJson(Problem problem) {
    Map<String, dynamic> map = {};
    map["id"] = problem.problemId;
    map["code"] = problem.problemCode;
    map["description"] = problem.problem;

    return map;
  }
}
