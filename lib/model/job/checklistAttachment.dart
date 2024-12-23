class ChecklistAttachment {
  String? question;
  String? answer;

  ChecklistAttachment({
    this.question,
    this.answer,
  });

  ChecklistAttachment.fromJson(Map<String, dynamic> json) {
    this.question = json["question"];
    this.answer = (json["answer"] as List<dynamic>).join("\n");
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data["name"] = this.question;
    data["model"] = this.answer;

    return data;
  }
}
