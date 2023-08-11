import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';

class Solution {
  int? solutionId;
  String? solutionCode;
  String? solution;
  String? isExpectedSolution;
  String? isActualSolution;

  Solution(
      {this.solutionId,
      this.solutionCode,
      this.solution,
      this.isExpectedSolution,
      this.isActualSolution});

  Solution.fromJson(Map<String, dynamic> json) {
    this.solutionId = json["solution_id"];
    this.solutionCode = json["attributes"]?["solution_code"];
    this.solution = json["attributes"]?["solution"];
    this.isExpectedSolution = json["attributes"]?["is_expected_solution"];
    this.isActualSolution = json["attributes"]?["is_actual_solution"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["solution_id"] = this.solutionId;
    data["solution_code"] = this.solutionCode;
    data["solution"] = this.solution;
    data["is_expected_solution"] = this.isExpectedSolution;
    data["is_actual_solution"] = this.isActualSolution;
    return data;
  }
}
