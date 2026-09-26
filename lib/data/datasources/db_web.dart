import 'package:drift/drift.dart';

// Mock simple para Web que satisface la interfaz de Drift sin usar dart:ffi
QueryExecutor openConnection() {
  return _WebMockExecutor();
}

class _WebMockExecutor extends QueryExecutor {
  @override
  SqlDialect get dialect => SqlDialect.sqlite;

  @override
  Future<bool> ensureOpen(QueryExecutorUser user) async => true;

  @override
  Future<void> runCustom(String statement, [List<Object?>? args]) async {}

  @override
  Future<int> runDelete(String statement, List<Object?> args) async => 0;

  @override
  Future<int> runInsert(String statement, List<Object?> args) async => 0;

  @override
  Future<List<Map<String, Object?>>> runSelect(String statement, List<Object?> args) async => [];

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async => 0;

  @override
  TransactionExecutor beginTransaction() => throw UnimplementedError();

  @override
  Future<void> runBatched(BatchedStatements statements) async {}

  TransactionExecutor beginExclusive() => throw UnimplementedError();
}
