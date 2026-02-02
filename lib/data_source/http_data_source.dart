import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/item.dart';
import '../models/list_config.dart';
import '../models/sort_mode.dart';
import 'card_list_data_source.dart';
import 'items_page.dart';

/// Consumer-provided mapper: converts API JSON to engine models.
abstract class HttpResponseMapper {
  ItemsPage parseItemsPage(Map<String, dynamic> json);
  Item parseItemDetail(Map<String, dynamic> json);
  List<ListConfig> parseListConfigs(List<dynamic> json);
  Map<String, dynamic> parseStatus(Map<String, dynamic> json);
}

/// Generic HTTP data source. Consumers provide a mapper for field mapping.
class HttpDataSource implements CardListDataSource {
  final String baseUrl;
  final Map<String, String> Function()? headersBuilder;
  final HttpResponseMapper mapper;
  final http.Client _client;
  final String _defaultListId;

  HttpDataSource({
    required this.baseUrl,
    required this.mapper,
    required String defaultListId,
    this.headersBuilder,
    http.Client? client,
  })  : _client = client ?? http.Client(),
        _defaultListId = defaultListId;

  @override
  String get defaultListId => _defaultListId;

  Map<String, String> get _headers =>
      headersBuilder?.call() ?? {'Content-Type': 'application/json'};

  @override
  Future<void> initialize() async {
    // No initialization needed for HTTP - connection is stateless
  }

  @override
  Future<ItemsPage> loadItems({
    required String listId,
    SortMode sortMode = SortMode.dateAscending,
    int limit = 50,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$baseUrl/notices').replace(queryParameters: {
      'list_id': listId,
      'sort': sortMode.name,
      'limit': '$limit',
      'offset': '$offset',
    });
    final resp = await _client.get(uri, headers: _headers);
    _checkResponse(resp);
    return mapper.parseItemsPage(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  @override
  Future<Item> loadItemDetail(String itemId) async {
    final uri = Uri.parse('$baseUrl/notices/$itemId');
    final resp = await _client.get(uri, headers: _headers);
    _checkResponse(resp);
    return mapper.parseItemDetail(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  @override
  Future<bool> moveItem({
    required String itemId,
    required String fromListId,
    required String targetListId,
  }) async {
    final uri = Uri.parse('$baseUrl/notices/$itemId/list');
    final resp = await _client.put(
      uri,
      headers: _headers,
      body: jsonEncode({'list_id': targetListId}),
    );
    _checkResponse(resp);
    return true;
  }

  @override
  Future<void> updateItemPosition({
    required String listId,
    required String itemId,
    required int newPosition,
  }) async {
    final uri = Uri.parse('$baseUrl/notices/$itemId/position');
    final resp = await _client.put(
      uri,
      headers: _headers,
      body: jsonEncode({'position': newPosition}),
    );
    _checkResponse(resp);
  }

  @override
  Future<List<ListConfig>> loadLists() async {
    final uri = Uri.parse('$baseUrl/lists');
    final resp = await _client.get(uri, headers: _headers);
    _checkResponse(resp);
    return mapper.parseListConfigs(jsonDecode(resp.body) as List<dynamic>);
  }

  @override
  Future<void> updateList(String listId, ListConfig config) async {
    final uri = Uri.parse('$baseUrl/lists/$listId');
    final resp = await _client.put(
      uri,
      headers: _headers,
      body: jsonEncode(config.toJson()),
    );
    _checkResponse(resp);
  }

  @override
  Future<String?> findListContainingItem(String itemId) async {
    final uri = Uri.parse('$baseUrl/notices/$itemId');
    final resp = await _client.get(uri, headers: _headers);
    _checkResponse(resp);
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return json['list_id'] as String?;
  }

  @override
  Future<Map<String, dynamic>> getStatus() async {
    final uri = Uri.parse('$baseUrl/status');
    final resp = await _client.get(uri, headers: _headers);
    _checkResponse(resp);
    return mapper.parseStatus(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  @override
  Future<void> dispose() async {
    _client.close();
  }

  void _checkResponse(http.Response resp) {
    if (resp.statusCode >= 400) {
      throw HttpDataSourceException(
        statusCode: resp.statusCode,
        message: resp.body,
      );
    }
  }
}

class HttpDataSourceException implements Exception {
  final int statusCode;
  final String message;

  HttpDataSourceException({required this.statusCode, required this.message});

  @override
  String toString() => 'HttpDataSourceException($statusCode): $message';
}
