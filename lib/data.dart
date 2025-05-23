import 'item.dart';
import 'list_config.dart';

class Data {
  final List<Item> items;
  final Map<String, Item> itemMap; // For O(1) lookups
  final List<ListConfig> listConfigs;
  final Map<String, List<String>> itemLists; // List UUID -> Ordered item UUIDs

  Data({
    required this.items,
    required this.itemMap,
    required this.listConfigs,
    required this.itemLists,
  });

  factory Data.initialize() {
    // Initialize items
    final List<Item> items = [
      Item(
        id: '1',
        title: 'Task 1',
        subtitle: 'Due today',
        html: '''
          <h2>Finish Report</h2>
          <p>Complete the following sections:</p>
          <ul>
            <li>Introduction</li>
            <li>Analysis</li>
            <li>Conclusion</li>
          </ul>
        ''',
        dueDate: DateTime(2025, 5, 21),
        status: 'Open',
        relatedItemIds: ['2', '4'], // Related to Task 2 and Client Meeting Notes
      ),
      Item(
        id: '2',
        title: 'Task 2',
        subtitle: 'Due tomorrow',
        html: '''
          <h2>Review Code</h2>
          <p>Check the following files:</p>
          <table border="1">
            <tr>
              <th>File</th>
              <th>Status</th>
            </tr>
            <tr>
              <td>main.dart</td>
              <td>Pending</td>
            </tr>
            <tr>
              <td>status_card_list.dart</td>
              <td>In Progress</td>
            </tr>
          </table>
        ''',
        dueDate: DateTime(2025, 5, 22),
        status: 'Open',
        relatedItemIds: ['1'], // Related to Task 1 (allows navigation loop)
      ),
      Item(
        id: '3',
        title: 'Prepare Presentation',
        subtitle: 'Due in 3 days',
        html: '''
          <h2>Prepare Slides</h2>
          <p>Include the following topics:</p>
          <ul>
            <li>Project Overview</li>
            <li>Key Findings</li>
            <li>Next Steps</li>
          </ul>
        ''',
        dueDate: DateTime(2025, 5, 24),
        status: 'Open',
        relatedItemIds: ['4'], // Related to Client Meeting Notes
      ),
      Item(
        id: '4',
        title: 'Client Meeting Notes',
        subtitle: 'Due next week',
        html: '''
          <h2>Meeting Summary</h2>
          <p>Action items:</p>
          <ul>
            <li>Follow up on contract</li>
            <li>Schedule next meeting</li>
          </ul>
        ''',
        dueDate: DateTime(2025, 5, 28),
        status: 'Awarded',
        relatedItemIds: ['1', '3'], // Related to Task 1 and Prepare Presentation
      ),
      Item(
        id: '5',
        title: 'Old Draft',
        subtitle: 'Expired last week',
        html: '''
          <h2>Draft Report</h2>
          <p>Outdated content:</p>
          <ul>
            <li>Initial findings</li>
            <li>Old data</li>
          </ul>
        ''',
        dueDate: DateTime(2025, 5, 14),
        status: 'Expired',
        relatedItemIds: [], // No related items
      ),
    ];

    // Create item map for O(1) lookup
    final Map<String, Item> itemMap = {for (var item in items) item.id: item};

    // Parse list configs
    final List<ListConfig> listConfigs = parseListConfigs(listConfigJson);

    // Initialize item lists
    final Map<String, List<String>> itemLists = {
      '550e8400-e29b-41d4-a716-446655440000': ['1', '2', '3'], // Review
      'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11': ['4'], // Saved
      'c9e2e8b7-1c4d-4f2a-8b5e-7d9f3c6a2b4e': ['5'], // Trash
    };

    return Data(
      items: items,
      itemMap: itemMap,
      listConfigs: listConfigs,
      itemLists: itemLists,
    );
  }
}