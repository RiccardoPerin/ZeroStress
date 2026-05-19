import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Impact{
  
  static final patient = "Jpefaq6m58"; 

  static final baseUrl = "https://impact.dei.unipd.it/bwthw/";
  static final gateUrl = "gate/v1/";
  static final dataUrl = "data/v1/";


  static Future<int> getTokens(String username, String password) async {
    // 1. create url
    final url = Impact.baseUrl + Impact.gateUrl + 'token/';
    final formattedUrl = Uri.parse(url);
    // 2. call the method
    final body = {'username' : username, 'password' : password};
    final response = await http.post(formattedUrl, body: body,);

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final sp = await SharedPreferences.getInstance();
      await sp.setString("access", responseBody["access"]);
      await sp.setString("refresh", responseBody["refresh"]);
    }

    return response.statusCode; // per verificare che abbia funzionato
  }





  static Future<int> refreshTokens(String refresh) async {

    // 1. create url
    final url = Impact.baseUrl + Impact.gateUrl + 'refresh/';
    final formattedUrl = Uri.parse(url);
    // 2. call the method
    final body = {"refresh" : refresh};
    final response = await http.post(formattedUrl, body: body,);

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final sp = await SharedPreferences.getInstance();
      await sp.setString("access", responseBody["access"]);
      await sp.setString("refresh", responseBody["refresh"]);
    } 

    return response.statusCode; // per verificare che abbia funzionato
  }
}

