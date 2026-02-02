import 'card_list_data_source.dart';

class DataContext {
  final String id;
  final String name;
  final String? description;
  const DataContext({required this.id, required this.name, this.description});
}

abstract class MultiContextDataSource implements CardListDataSource {
  Future<List<DataContext>> loadContexts();
  Future<void> switchContext(String contextId);
  DataContext get currentContext;
}
