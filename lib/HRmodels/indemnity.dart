class Indemnity {
  final int id;
  final String indemitems;
  final int type;
  final int? status;

  Indemnity({
    required this.id,
    required this.indemitems,
    required this.type,
    this.status,
  });
}

class IndemnityResponse {
  const IndemnityResponse(
    this.userid,
    this.answers,
  );

  final int userid;
  final List<String> answers;
}
