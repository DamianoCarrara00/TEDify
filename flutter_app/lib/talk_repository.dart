import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/talk.dart';

Future<List<Talk>> initEmptyList() async {

  Iterable list = json.decode("[]");
  var talks = list.map((model) => Talk.fromJSON(model)).toList();
  return talks;

}

Future<List<Talk2>> initEmptyList2() async {
  Iterable list = json.decode("[]");
  var talks = list.map((model) => Talk2.fromJSON(model)).toList();
  return talks;
}

Future<List<Talk>> getTalksByTag(String tag, int page) async {
  var url = Uri.parse('https://xjln8888w6.execute-api.us-east-1.amazonaws.com/default/Get_Talks_By_Tag');

  final http.Response response = await http.post(url,
    headers: <String, String>{
      'Content-Type': 'application/json',
    },
    body: jsonEncode(<String, Object>{
      'tag': tag,
      'page': page,
      'doc_per_page': 6
    }),
  );
  if (response.statusCode == 200) {
    final body = utf8.decode(response.bodyBytes);
    final List<dynamic> jsonList = json.decode(body);
    return jsonList.map((json) => Talk.fromJSON(json)).toList();
  } else {
    throw Exception('Failed to load talks');
  }
      
}

Future<List<Talk2>> getTalksById(String idx, int page) async {
  var url = Uri.parse('https://8bgoebu05i.execute-api.us-east-1.amazonaws.com/default/Get_Watch_Next_by_Idx');

  final http.Response response = await http.post(url,
    headers: <String, String>{
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'idx': idx,
      'page': page,
      'doc_per_page': 6
    }),
  );

  if (response.statusCode == 200) {
    final body = utf8.decode(response.bodyBytes);
    final decoded = json.decode(body);

    // Controlla se è una lista o un oggetto
    if (decoded is List) {
      // Caso: tutto ok, ritorna la lista
      return decoded.map((json) => Talk2.fromJSON(json)).toList();
    } else if (decoded is Map && decoded.containsKey("suggestions")) {
      // Caso: risposta con messaggio e lista vuota
      final suggestions = decoded["suggestions"];
      if (suggestions is List) {
        return suggestions.map((json) => Talk2.fromJSON(json)).toList();
      } else {
        return []; // fallback di sicurezza
      }
    } else {
      throw Exception("Unexpected response format: $decoded");
    }
  } else {
    throw Exception('Failed to load talks: ${response.statusCode}');
  }
}

Future<Map<String, dynamic>> likeUnlikeTalk(String videoId, String userId) async {
  
  final url = Uri.parse('https://w0vv1dpa34.execute-api.us-east-1.amazonaws.com/default/Like_Unlike'); 
  print("Sending like for videoId: $videoId, userId: $userId");

  final response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'videoId': videoId,
      'userId': userId,
    }),
  );

  if (response.statusCode == 200) {
    // Se il server risponde correttamente, restituiamo il corpo della risposta
    return jsonDecode(response.body);
  } else {
    // Se qualcosa va storto, lanciamo un'eccezione
    throw Exception('Failed to update like status.');
  }
}