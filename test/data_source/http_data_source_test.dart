import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:status_card_list/data_source/http_data_source.dart';
import 'package:status_card_list/data_source/items_page.dart';
import 'package:status_card_list/models/item.dart';
import 'package:status_card_list/models/list_config.dart';

class TestMapper implements HttpResponseMapper {
  @override
  ItemsPage parseItemsPage(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>)
        .map((j) => Item.fromJson(j as Map<String, dynamic>))
        .toList();
    return ItemsPage(
      items: items,
      totalCount: json['total'] as int,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }

  @override
  Item parseItemDetail(Map<String, dynamic> json) {
    return Item.fromJson(json);
  }

  @override
  List<ListConfig> parseListConfigs(List<dynamic> json) {
    return json
        .map((j) => ListConfig.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Map<String, dynamic> parseStatus(Map<String, dynamic> json) {
    return json;
  }
}

void main() {
  const baseUrl = 'https://api.example.com';
  const defaultListId = 'list-1';
  late TestMapper mapper;

  setUp(() {
    mapper = TestMapper();
  });

  group('HttpDataSource', () {
    group('initialize', () {
      test('completes without error', () async {
        final ds = HttpDataSource(
          baseUrl: baseUrl,
          mapper: mapper,
          defaultListId: defaultListId,
          client: MockClient((_) async => http.Response('', 200)),
        );
        await ds.initialize();
        // No-op, should complete
      });
    });

    group('defaultListId', () {
      test('returns the configured default list ID', () {
        final ds = HttpDataSource(
          baseUrl: baseUrl,
          mapper: mapper,
          defaultListId: defaultListId,
          client: MockClient((_) async => http.Response('', 200)),
        );
        expect(ds.defaultListId, defaultListId);
      });
    });

    group('loadItems', () {
      test('sends GET request with correct query parameters', () async {
        Uri? capturedUri;
        final client = MockClient((request) async {
          capturedUri = request.url;
          return http.Response(jsonEncode({
            'items': [
              {
                'id': '1',
                'title': 'Test Item',
                'subtitle': 'Sub',
                'status': 'Open',
              },
            ],
            'total': 1,
            'has_more': false,
          }), 200);
        });

        final ds = HttpDataSource(
          baseUrl: baseUrl,
          mapper: mapper,
          defaultListId: defaultListId,
          client: client,
        );

        final page = await ds.loadItems(listId: 'list-1');
        expect(capturedUri!.queryParameters['list_id'], 'list-1');
        expect(capturedUri!.queryParameters['sort'], 'dateAscending');
        expect(page.items.length, 1);
        expect(page.items[0].title, 'Test Item');
        expect(page.totalCount, 1);
      });

      test('throws on HTTP error', () async {
        final client = MockClient((_) async =>
            http.Response('Not found', 404));

        final ds = HttpDataSource(
          baseUrl: baseUrl,
          mapper: mapper,
          defaultListId: defaultListId,
          client: client,
        );

        expect(
          () => ds.loadItems(listId: 'list-1'),
          throwsA(isA<HttpDataSourceException>()),
        );
      });
    });

    group('loadItemDetail', () {
      test('sends GET request and parses item', () async {
        final client = MockClient((request) async {
          expect(request.url.path, '/notices/item-1');
          return http.Response(jsonEncode({
            'id': 'item-1',
            'title': 'Detail Item',
            'subtitle': 'Sub',
            'html': '<p>Content</p>',
            'status': 'Open',
          }), 200);
        });

        final ds = HttpDataSource(
          baseUrl: baseUrl,
          mapper: mapper,
          defaultListId: defaultListId,
          client: client,
        );

        final item = await ds.loadItemDetail('item-1');
        expect(item.id, 'item-1');
        expect(item.html, '<p>Content</p>');
      });
    });

    group('moveItem', () {
      test('sends PUT request with target list ID', () async {
        String? capturedBody;
        final client = MockClient((request) async {
          capturedBody = request.body;
          expect(request.method, 'PUT');
          expect(request.url.path, '/notices/item-1/list');
          return http.Response('', 200);
        });

        final ds = HttpDataSource(
          baseUrl: baseUrl,
          mapper: mapper,
          defaultListId: defaultListId,
          client: client,
        );

        final success = await ds.moveItem(
          itemId: 'item-1',
          fromListId: 'list-1',
          targetListId: 'list-2',
        );

        expect(success, isTrue);
        expect(jsonDecode(capturedBody!)['list_id'], 'list-2');
      });
    });

    group('updateItemPosition', () {
      test('sends PUT request with new position', () async {
        String? capturedBody;
        final client = MockClient((request) async {
          capturedBody = request.body;
          expect(request.method, 'PUT');
          expect(request.url.path, '/notices/item-1/position');
          return http.Response('', 200);
        });

        final ds = HttpDataSource(
          baseUrl: baseUrl,
          mapper: mapper,
          defaultListId: defaultListId,
          client: client,
        );

        await ds.updateItemPosition(
          listId: 'list-1',
          itemId: 'item-1',
          newPosition: 3,
        );

        expect(jsonDecode(capturedBody!)['position'], 3);
      });
    });

    group('loadLists', () {
      test('sends GET request and parses list configs', () async {
        final client = MockClient((request) async {
          expect(request.url.path, '/lists');
          return http.Response(jsonEncode([
            {
              'uuid': 'list-1',
              'name': 'Review',
              'swipeActions': {},
              'buttons': {},
            },
            {
              'uuid': 'list-2',
              'name': 'Saved',
              'swipeActions': {},
              'buttons': {},
            },
          ]), 200);
        });

        final ds = HttpDataSource(
          baseUrl: baseUrl,
          mapper: mapper,
          defaultListId: defaultListId,
          client: client,
        );

        final configs = await ds.loadLists();
        expect(configs.length, 2);
        expect(configs[0].name, 'Review');
        expect(configs[1].name, 'Saved');
      });
    });

    group('updateList', () {
      test('sends PUT request with config JSON', () async {
        String? capturedBody;
        final client = MockClient((request) async {
          capturedBody = request.body;
          expect(request.method, 'PUT');
          expect(request.url.path, '/lists/list-1');
          return http.Response('', 200);
        });

        final ds = HttpDataSource(
          baseUrl: baseUrl,
          mapper: mapper,
          defaultListId: defaultListId,
          client: client,
        );

        final config = ListConfig(
          uuid: 'list-1',
          name: 'Updated Review',
          swipeActions: {},
          buttons: {},
        );

        await ds.updateList('list-1', config);
        expect(jsonDecode(capturedBody!)['name'], 'Updated Review');
      });
    });

    group('findListContainingItem', () {
      test('returns list ID from response', () async {
        final client = MockClient((request) async {
          return http.Response(jsonEncode({
            'id': 'item-1',
            'title': 'Test',
            'subtitle': '',
            'status': 'Open',
            'list_id': 'list-2',
          }), 200);
        });

        final ds = HttpDataSource(
          baseUrl: baseUrl,
          mapper: mapper,
          defaultListId: defaultListId,
          client: client,
        );

        final listId = await ds.findListContainingItem('item-1');
        expect(listId, 'list-2');
      });

      test('returns null when list_id not in response', () async {
        final client = MockClient((request) async {
          return http.Response(jsonEncode({
            'id': 'item-1',
            'title': 'Test',
            'subtitle': '',
            'status': 'Open',
          }), 200);
        });

        final ds = HttpDataSource(
          baseUrl: baseUrl,
          mapper: mapper,
          defaultListId: defaultListId,
          client: client,
        );

        final listId = await ds.findListContainingItem('item-1');
        expect(listId, isNull);
      });
    });

    group('getStatus', () {
      test('sends GET request and parses status', () async {
        final client = MockClient((request) async {
          expect(request.url.path, '/status');
          return http.Response(jsonEncode({
            'counts': {'list-1': 5, 'list-2': 3},
          }), 200);
        });

        final ds = HttpDataSource(
          baseUrl: baseUrl,
          mapper: mapper,
          defaultListId: defaultListId,
          client: client,
        );

        final status = await ds.getStatus();
        final counts = status['counts'] as Map<String, dynamic>;
        expect(counts['list-1'], 5);
        expect(counts['list-2'], 3);
      });
    });

    group('headersBuilder', () {
      test('uses custom headers when provided', () async {
        Map<String, String>? capturedHeaders;
        final client = MockClient((request) async {
          capturedHeaders = request.headers;
          return http.Response(jsonEncode({
            'counts': {},
          }), 200);
        });

        final ds = HttpDataSource(
          baseUrl: baseUrl,
          mapper: mapper,
          defaultListId: defaultListId,
          client: client,
          headersBuilder: () => {
            'Authorization': 'Bearer test-token',
            'Content-Type': 'application/json',
          },
        );

        await ds.getStatus();
        expect(capturedHeaders!['Authorization'], 'Bearer test-token');
      });
    });

    group('dispose', () {
      test('closes the client without error', () async {
        final client = MockClient((request) async {
          return http.Response('', 200);
        });
        final ds = HttpDataSource(
          baseUrl: baseUrl,
          mapper: mapper,
          defaultListId: defaultListId,
          client: client,
        );
        await ds.dispose();
        // Verify no exception thrown
      });
    });
  });

  group('HttpDataSourceException', () {
    test('toString includes status code and message', () {
      final exception = HttpDataSourceException(
        statusCode: 404,
        message: 'Not found',
      );
      expect(exception.toString(), 'HttpDataSourceException(404): Not found');
    });
  });
}
