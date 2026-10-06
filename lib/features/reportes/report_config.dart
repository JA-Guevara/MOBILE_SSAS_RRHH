class ReportFilter {
  const ReportFilter({
    required this.field,
    required this.operator,
    required this.value,
  });

  final String field;
  final String operator;
  final Object value;

  Map<String, Object> toJson() => {
    'campo': field,
    'operador': operator,
    'valor': value,
  };

  factory ReportFilter.fromJson(Map<String, dynamic> json) => ReportFilter(
    field: json['campo'] as String,
    operator: json['operador'] as String,
    value: json['valor'] as Object,
  );
}

class ReportOrder {
  const ReportOrder({required this.field, required this.direction});

  final String field;
  final String direction;

  Map<String, String> toJson() => {'campo': field, 'direccion': direction};

  factory ReportOrder.fromJson(Map<String, dynamic> json) => ReportOrder(
    field: json['campo'] as String,
    direction: json['direccion'] as String,
  );
}

class ReportConfig {
  const ReportConfig({
    required this.source,
    required this.columns,
    this.filters = const [],
    this.order = const [],
  });

  final String source;
  final List<String> columns;
  final List<ReportFilter> filters;
  final List<ReportOrder> order;

  Map<String, Object> toJson() => {
    'fuente': source,
    'columnas': columns,
    'filtros': filters.map((filter) => filter.toJson()).toList(),
    'orden': order.map((item) => item.toJson()).toList(),
  };

  factory ReportConfig.fromJson(Map<String, dynamic> json) => ReportConfig(
    source: json['fuente'] as String,
    columns: (json['columnas'] as List).cast<String>(),
    filters: (json['filtros'] as List? ?? const [])
        .map((item) => ReportFilter.fromJson(item as Map<String, dynamic>))
        .toList(),
    order: (json['orden'] as List? ?? const [])
        .map((item) => ReportOrder.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}
