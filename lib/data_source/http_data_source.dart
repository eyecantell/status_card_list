import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/item.dart';
import '../models/list_config.dart';
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
  final Map<String, String>? extraQueryParams;

  HttpDataSource({
    required this.baseUrl,
    required this.mapper,
    required String defaultListId,
    this.headersBuilder,
    this.extraQueryParams,
    http.Client? client,
  })  : _client = client ?? http.Client(),
        _defaultListId = defaultListId;

  /// Builds a URI from a path, merging [params] with [extraQueryParams].
  Uri _buildUri(String path, [Map<String, String>? params]) {
    final merged = <String, String>{
      ...?extraQueryParams,
      ...?params,
    };
    final uri = Uri.parse('$baseUrl/$path');
    return merged.isEmpty ? uri : uri.replace(queryParameters: merged);
  }

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
    String sortMode = 'manual',
    int limit = 50,
    int offset = 0,
    String? searchQuery,
  }) async {
    final params = {
      'list_id': listId,
      'sort': sortMode,
      'limit': '$limit',
      'offset': '$offset',
    };
    if (searchQuery != null && searchQuery.isNotEmpty) {
      params['search'] = searchQuery;
    }
    final uri = _buildUri('notices', params);
    final resp = await _client.get(uri, headers: _headers);
    _checkResponse(resp);
    return mapper.parseItemsPage(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  @override
  Future<Item> loadItemDetail(String itemId) async {
    final uri = _buildUri('notices/$itemId');
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
    final uri = _buildUri('notices/$itemId/list');
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
    final uri = _buildUri('notices/$itemId/position');
    final resp = await _client.put(
      uri,
      headers: _headers,
      body: jsonEncode({'position': newPosition}),
    );
    _checkResponse(resp);
  }

  @override
  Future<List<ListConfig>> loadLists() async {
    final uri = _buildUri('lists');
    final resp = await _client.get(uri, headers: _headers);
    _checkResponse(resp);
    return mapper.parseListConfigs(jsonDecode(resp.body) as List<dynamic>);
  }

  @override
  Future<void> updateList(String listId, ListConfig config) async {
    final uri = _buildUri('lists/$listId');
    final resp = await _client.put(
      uri,
      headers: _headers,
      body: jsonEncode(config.toJson()),
    );
    _checkResponse(resp);
  }

  @override
  Future<String?> findListContainingItem(String itemId) async {
    final uri = _buildUri('notices/$itemId');
    final resp = await _client.get(uri, headers: _headers);
    _checkResponse(resp);
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return json['list_id'] as String?;
  }

  @override
  Future<Map<String, dynamic>> getStatus() async {
    final uri = _buildUri('status');
    final resp = await _client.get(uri, headers: _headers);
    _checkResponse(resp);
    return mapper.parseStatus(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  @override
  Future<ListConfig> createList({required String name, String? iconName, String? color}) async {
    final uri = _buildUri('lists');
    final body = <String, dynamic>{'name': name};
    if (iconName != null) body['icon'] = iconName;
    if (color != null) body['color'] = color;
    final resp = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );
    _checkResponse(resp);
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return mapper.parseListConfigs([json]).first;
  }

  @override
  Future<void> deleteList(String listId) async {
    final uri = _buildUri('lists/$listId');
    final resp = await _client.delete(uri, headers: _headers);
    _checkResponse(resp);
  }

  @override
  Future<int> bulkMoveItems({
    required String sourceListId,
    required String targetListId,
    String? searchQuery,
  }) async {
    final uri = _buildUri('notices/bulk-move');
    final body = <String, dynamic>{
      'source_list_id': sourceListId,
      'target_list_id': targetListId,
    };
    if (searchQuery != null && searchQuery.isNotEmpty) {
      body['search'] = searchQuery;
    }
    final resp = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );
    _checkResponse(resp);
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return json['moved_count'] as int? ?? 0;
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
