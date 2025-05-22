import 'item.dart';
import 'list_config.dart';

Map<String, List<Item>> initializeItemLists(List<ListConfig> listConfigs) {
  final Map<String, List<Item>> itemLists = {
    for (var config in listConfigs) config.name: <Item>[],
  };
  itemLists['Review'] = [
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
    ),
  ];
  return itemLists;
}