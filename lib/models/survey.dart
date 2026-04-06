class Survey {
  final int id;
  final String question;
  final int questiontype;
  final int ratingcount;
  final int surveytype;
  final int surveyfor;
  final int status;

  const Survey({
    required this.id,
    required this.question,
    required this.questiontype,
    required this.ratingcount,
    required this.surveytype,
    required this.surveyfor,
    this.status = 1,
  });
}

class SurveyAnswer {
  final int id;
  final int userid;
  final int eventid;
  final String surveyanswer;
  final String questionText;

  const SurveyAnswer({
    required this.id,
    required this.userid,
    required this.eventid,
    required this.surveyanswer,
    this.questionText = '',
  });
}
