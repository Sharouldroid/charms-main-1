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
  IndemnityResponse({
    this.userid = 0,
    required this.answers,
    this.confirmnum = 0,
    this.indemcount = 0,
  });

  final int userid;
  final String answers;
  final int confirmnum;
  final int indemcount;
}
