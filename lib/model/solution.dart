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

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["solution_id"] = this.solutionId;
    data["solution_code"] = this.solutionCode;
    data["solution"] = this.solution;

    return data;
  }
}
