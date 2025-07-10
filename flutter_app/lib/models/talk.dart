class Talk {
  final String id;
  final String title;
  final String details;
  final String mainSpeaker;
  final String url;
  final List<String> keyPhrases;
  List<String> likes;

  Talk.fromJSON(Map<String, dynamic> jsonMap)
      : title = jsonMap['title'] ?? '',
        id = jsonMap['_id'] ?? '',
        details = jsonMap['description'] ?? '',
        mainSpeaker = (jsonMap['speakers'] ?? ""),
        url = (jsonMap['url'] ?? ""),
        likes = List<String>.from(jsonMap['likes'] ?? []),
        keyPhrases = (jsonMap['comprehend_analysis']['KeyPhrases'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
}

class Talk2 {
  final String id;
  final String title;
  final String details;
  final String mainSpeaker;
  final String url;
  List<String> likes;

  Talk2.fromJSON(Map<String, dynamic> jsonMap)
      : id = jsonMap['_id'] ?? '',
        title = jsonMap['title'] ?? '',
        details = jsonMap['description'] ?? '',
        mainSpeaker = (jsonMap['speakers'] ?? ""),
        url = (jsonMap['url'] ?? ""),
        likes = List<String>.from(jsonMap['likes'] ?? []);
}