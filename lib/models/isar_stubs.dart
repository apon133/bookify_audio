typedef Id = int;

const collection = Collection();
class Collection {
  const Collection();
}

const embedded = Embedded();
class Embedded {
  const Embedded();
}

class Index {
  final bool unique;
  final bool replace;
  final IndexType type;
  const Index({this.unique = false, this.replace = false, this.type = IndexType.hash});
}

enum IndexType { hash, hashPressed, value }

const enumerated = Enumerated();
class Enumerated {
  const Enumerated();
}

class Isar {
  static const int autoIncrement = -9223372036854775808;

  static Future<Isar> open(
    List<dynamic> schemas, {
    required String directory,
    String? name,
    int? maxSizeMiB,
    bool? relaxedDurability,
    dynamic inspector,
  }) async {
    return Isar();
  }

  IsarCollection<T> collection<T>() => throw UnimplementedError();
  Future<T?> get<T>(Id id) => throw UnimplementedError();
  Future<List<T>> getAll<T>(List<Id> ids) => throw UnimplementedError();
  Future<Id> put<T>(T object) => throw UnimplementedError();
  Future<List<Id>> putAll<T>(List<T> objects) => throw UnimplementedError();
  Future<bool> delete<T>(Id id) => throw UnimplementedError();
  Future<int> deleteAll<T>(List<Id> ids) => throw UnimplementedError();
  Future<void> clear<T>() => throw UnimplementedError();
  Future<T> txn<T>(Future<T> Function() callback) => throw UnimplementedError();
  Future<T> writeTxn<T>(Future<T> Function() callback) => throw UnimplementedError();
  T txnSync<T>(T Function() callback) => throw UnimplementedError();
  T writeTxnSync<T>(T Function() callback) => throw UnimplementedError();
  
  // Accessors for generated code (use dynamic for web to avoid extension conflicts)
  dynamic get playlistEntitys => throw UnimplementedError();
  dynamic get historyItemEntitys => throw UnimplementedError();
  dynamic get appSettingsEntitys => throw UnimplementedError();
  dynamic get reactionEntitys => throw UnimplementedError();
}

class CollectionSchema<T> {
  final String name;
  final int id;
  final Map<String, PropertySchema> properties;
  final int Function(T, List<int>, Map<Type, List<int>>) estimateSize;
  final void Function(T, IsarWriter, List<int>, Map<Type, List<int>>) serialize;
  final dynamic deserialize;
  final dynamic deserializeProp;
  final String idName;
  final Map<String, IndexSchema> indexes;
  final Map<String, LinkSchema> links;
  final Map<String, dynamic> embeddedSchemas;
  final dynamic getId;
  final dynamic getLinks;
  final dynamic attach;
  final String version;

  const CollectionSchema({
    required this.name,
    required this.id,
    required this.properties,
    required this.estimateSize,
    required this.serialize,
    required this.deserialize,
    this.deserializeProp,
    required this.idName,
    required this.indexes,
    required this.links,
    required this.embeddedSchemas,
    this.getId,
    this.getLinks,
    this.attach,
    required this.version,
  });
}

class Schema<T> {
  final String name;
  final int id;
  final Map<String, PropertySchema> properties;
  final int Function(T, List<int>, Map<Type, List<int>>) estimateSize;
  final void Function(T, IsarWriter, List<int>, Map<Type, List<int>>) serialize;
  final dynamic deserialize;
  final dynamic deserializeProp;
  final Map<String, dynamic>? embeddedSchemas;

  const Schema({
    required this.name,
    required this.id,
    required this.properties,
    required this.estimateSize,
    required this.serialize,
    required this.deserialize,
    this.deserializeProp,
    this.embeddedSchemas,
  });
}

class PropertySchema {
  final int id;
  final String name;
  final IsarType type;
  final String? target;
  final Map<String, dynamic>? enumMap;
  const PropertySchema({required this.id, required this.name, required this.type, this.target, this.enumMap});
}

class IndexSchema {
  final int id;
  final String name;
  final bool unique;
  final bool replace;
  final List<IndexPropertySchema> properties;
  const IndexSchema({required this.id, required this.name, required this.unique, required this.replace, required this.properties});
}

class IndexPropertySchema {
  final String name;
  final IndexType type;
  final bool caseSensitive;
  const IndexPropertySchema({required this.name, required this.type, required this.caseSensitive});
}

class LinkSchema {
  final int id;
  final String name;
  final String target;
  final bool single;
  const LinkSchema({required this.id, required this.name, required this.target, required this.single});
}

enum IsarType {
  bool,
  int,
  float,
  double,
  dateTime,
  string,
  byteList,
  boolList,
  intList,
  floatList,
  doubleList,
  dateTimeList,
  stringList,
  object,
  objectList,
  byte,
}

class IsarWriter {
  void writeBool(int offset, bool? value) {}
  void writeInt(int offset, int? value) {}
  void writeFloat(int offset, double? value) {}
  void writeDouble(int offset, double? value) {}
  void writeByte(int offset, int value) {}
  void writeDateTime(int offset, DateTime? value) {}
  void writeString(int offset, String? value) {}
  void writeObject<T>(int offset, Map<Type, List<int>> allOffsets, dynamic serialize, T value) {}
  void writeObjectList<T>(int offset, Map<Type, List<int>> allOffsets, dynamic serialize, List<T> value) {}
}

class IsarReader {
  bool readBool(int offset) => false;
  bool? readBoolOrNull(int offset) => null;
  int readInt(int offset) => 0;
  int? readIntOrNull(int offset) => null;
  double readFloat(int offset) => 0.0;
  double? readFloatOrNull(int offset) => null;
  double readDouble(int offset) => 0.0;
  double? readDoubleOrNull(int offset) => null;
  int readByte(int offset) => 0;
  int? readByteOrNull(int offset) => null;
  DateTime readDateTime(int offset) => DateTime.now();
  DateTime? readDateTimeOrNull(int offset) => null;
  String readString(int offset) => '';
  String? readStringOrNull(int offset) => null;
  T? readObject<T>(int offset, dynamic deserialize, Map<Type, List<int>> allOffsets, T defaultValue) => null;
  T? readObjectOrNull<T>(int offset, dynamic deserialize, Map<Type, List<int>> allOffsets) => null;
  List<T>? readObjectList<T>(int offset, dynamic deserialize, Map<Type, List<int>> allOffsets, T defaultValue) => null;
}

class IsarLinkBase<T> {
  T? value;
  void load() {}
  void save() {}
}
class IsarLink<T> extends IsarLinkBase<T> {}
class IsarLinks<T> extends IsarLinkBase<T> {
  final Set<T> _items = {};
  void add(T item) => _items.add(item);
  void remove(T item) => _items.remove(item);
}

class IsarCollection<T> {
  dynamic where() => throw UnimplementedError();
  dynamic filter() => throw UnimplementedError();
  Future<Id> put(T object) => throw UnimplementedError();
  Future<List<Id>> putAll(List<T> objects) => throw UnimplementedError();
  Future<T?> get(Id id) => throw UnimplementedError();
  Future<List<T?>> getAll(List<Id> ids) => throw UnimplementedError();
  Future<bool> delete(Id id) => throw UnimplementedError();
  Future<int> deleteAll(List<Id> ids) => throw UnimplementedError();
  List<T> findAllSync() => throw UnimplementedError();
  T? getSync(Id id) => throw UnimplementedError();
  Id putSync(T object) => throw UnimplementedError();
  bool deleteSync(Id id) => throw UnimplementedError();
  int deleteAllSync(List<Id> ids) => throw UnimplementedError();
  void clearSync() => throw UnimplementedError();
  Future<void> clear() => throw UnimplementedError();
  Future<int> count() => throw UnimplementedError();
  int countSync() => throw UnimplementedError();
  
  // Index methods
  dynamic getByIndex(String indexName, List<dynamic> values) => throw UnimplementedError();
  dynamic getByIndexSync(String indexName, List<dynamic> values) => throw UnimplementedError();
  dynamic deleteByIndex(String indexName, List<dynamic> values) => throw UnimplementedError();
  dynamic deleteByIndexSync(String indexName, List<dynamic> values) => throw UnimplementedError();
  dynamic getAllByIndex(String indexName, List<dynamic> values) => throw UnimplementedError();
  dynamic getAllByIndexSync(String indexName, List<dynamic> values) => throw UnimplementedError();
  dynamic deleteAllByIndex(String indexName, List<dynamic> values) => throw UnimplementedError();
  dynamic deleteAllByIndexSync(String indexName, List<dynamic> values) => throw UnimplementedError();
  dynamic putByIndex(String indexName, T object) => throw UnimplementedError();
  dynamic putByIndexSync(String indexName, T object, {bool saveLinks = true}) => throw UnimplementedError();
  dynamic putAllByIndex(String indexName, List<T> objects) => throw UnimplementedError();
  dynamic putAllByIndexSync(String indexName, List<T> objects, {bool saveLinks = true}) => throw UnimplementedError();
}

typedef FilterQuery<T> = dynamic Function(QueryBuilder<T, T, QAfterFilterCondition>);

class QueryBuilder<T, R, S> {
  static dynamic apply<T, R, S>(QueryBuilder<T, R, S> query, dynamic Function(QueryBuilder<T, R, S>) function) => query;
  dynamic addWhereClause(dynamic clause) => throw UnimplementedError();
  dynamic addFilterCondition(dynamic condition) => throw UnimplementedError();
  dynamic listLength(String property, int lower, bool includeLower, int upper, bool includeUpper) => throw UnimplementedError();
  
  dynamic get whereSort => throw UnimplementedError();
  dynamic object(dynamic q, String property) => throw UnimplementedError();
  dynamic addSortBy(String property, Sort sort) => throw UnimplementedError();
  dynamic addDistinctBy(String property, {bool caseSensitive = true}) => throw UnimplementedError();
  dynamic addPropertyName(String propertyName) => throw UnimplementedError();
  
  // Common generated methods to satisfy compiler
  dynamic sortByCreatedAt() => throw UnimplementedError();
  dynamic sortByCreatedAtDesc() => throw UnimplementedError();
  dynamic sortByLastPlayed() => throw UnimplementedError();
  dynamic sortByLastPlayedDesc() => throw UnimplementedError();
  
  Future<List<R>> findAll() => throw UnimplementedError();
  List<R> findAllSync() => throw UnimplementedError();
  Future<R?> findFirst() => throw UnimplementedError();
  R? findFirstSync() => throw UnimplementedError();
  Future<int> count() => throw UnimplementedError();
  int countSync() => throw UnimplementedError();
  Future<bool> deleteFirst() => throw UnimplementedError();
  bool deleteFirstSync() => throw UnimplementedError();
  Future<int> deleteAll() => throw UnimplementedError();
  int deleteAllSync() => throw UnimplementedError();
}

class QWhere {}
class QAfterWhere {}
class QWhereClause {}
class QAfterWhereClause {}

class QSortBy {}
class QAfterSortBy {}
class QSortThenBy {}
class QDistinct {}
class QQueryProperty {}
class QQueryOperations {}

class IdWhereClause {
  const IdWhereClause.any();
  const IdWhereClause.between({required dynamic lower, required dynamic upper, bool includeLower = true, bool includeUpper = true});
  const IdWhereClause.lessThan({required dynamic upper, bool includeUpper = true});
  const IdWhereClause.greaterThan({required dynamic lower, bool includeLower = true});
}

class IndexWhereClause {
  static dynamic equalTo({required String indexName, required List<dynamic> value}) => null;
  static dynamic between({required String indexName, required List<dynamic> lower, bool includeLower = true, required List<dynamic> upper, bool includeUpper = true}) => null;
}

enum Sort { asc, desc }

class Query {
  static const double epsilon = 0.0000000001;
}

class FilterCondition {
  const FilterCondition.isNull({required String property});
  const FilterCondition.isNotNull({required String property});

  static dynamic equalTo({required String property, required dynamic value, bool caseSensitive = true, double? epsilon}) => null;
  static dynamic greaterThan({required String property, required dynamic value, bool include = false, bool caseSensitive = true, double? epsilon}) => null;
  static dynamic lessThan({required String property, required dynamic value, bool include = false, bool caseSensitive = true, double? epsilon}) => null;
  static dynamic between({required String property, required dynamic lower, bool includeLower = true, required dynamic upper, bool includeUpper = true, bool caseSensitive = true, double? epsilon}) => null;
  static dynamic startsWith({required String property, required String value, bool caseSensitive = true}) => null;
  static dynamic endsWith({required String property, required String value, bool caseSensitive = true}) => null;
  static dynamic contains({required String property, required String value, bool caseSensitive = true}) => null;
  static dynamic matches({required String property, String? value, bool caseSensitive = true, String? wildcard}) => null;
}

class QFilterCondition {}
class QAfterFilterCondition {}

class IsarError {
  final String message;
  const IsarError(this.message);
}
extension QueryBuilderStub<T, R, S> on QueryBuilder<T, R, S> {
  QueryBuilder<T, R, QAfterFilterCondition> originalIdEqualTo(String value) => throw UnimplementedError();
  QueryBuilder<T, R, QAfterFilterCondition> episodeIdEqualTo(String value) => throw UnimplementedError();
  Stream<List<R>> watch({bool fireImmediately = false}) => throw UnimplementedError();
}
