class Solution {
  int? solutionId;
  String? solutionCode;
  String? solution;
  String? solutionGroupCode;

  Solution({
    this.solutionId,
    this.solutionCode,
    this.solution,
  });

  Solution.fromJson(Map<String, dynamic> json) {
    this.solutionId = json["solution_id"];
    this.solutionCode = json["solution_code"];
    this.solution = json["solution"];
  }

  static Map<String, dynamic> toJson(Solution solution) {
    Map<String, dynamic> map = {};
    map["id"] = solution.solutionId;
    map["code"] = solution.solutionCode;
    map["description"] = solution.solution;

    return map;
  }
}
