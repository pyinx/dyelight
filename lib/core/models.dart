import 'dart:typed_data';

import 'providers_preset.dart';

enum EndpointStyle { imagesEdits, imagesGenerations, chatCompletions }

class AppSettings {
  const AppSettings({
    this.providerId = 'openai',
    this.baseUrl = 'https://api.openai.com/v1',
    this.model = 'gpt-image-1',
    this.visionModel = '',
    this.timeoutSeconds = 60,
    this.headers = const {},
    this.temperature = 0.7,
    this.endpointStyle,
    this.localeCode,
    this.debug = false,
  });

  /// A [ProviderPreset] id or [kCustomProviderId].
  final String providerId;
  final String baseUrl;
  final String model;

  /// Chat model that reads the photo for Smart mode; empty = image model only.
  final String visionModel;
  final int timeoutSeconds;
  final Map<String, String> headers;
  final double temperature;

  /// null until detected from the server (cleared when provider/model change).
  final EndpointStyle? endpointStyle;

  /// null follows the system language.
  final String? localeCode;

  /// Records a request/response trace viewable in Settings.
  final bool debug;

  AppSettings copyWith({
    String? providerId,
    String? baseUrl,
    String? model,
    String? visionModel,
    int? timeoutSeconds,
    Map<String, String>? headers,
    double? temperature,
    EndpointStyle? endpointStyle,
    String? localeCode,
    bool? debug,
    bool clearLocale = false,
    bool clearEndpoint = false,
  }) => AppSettings(
    providerId: providerId ?? this.providerId,
    baseUrl: baseUrl ?? this.baseUrl,
    model: model ?? this.model,
    visionModel: visionModel ?? this.visionModel,
    timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
    headers: headers ?? this.headers,
    temperature: temperature ?? this.temperature,
    endpointStyle: clearEndpoint ? null : (endpointStyle ?? this.endpointStyle),
    localeCode: clearLocale ? null : (localeCode ?? this.localeCode),
    debug: debug ?? this.debug,
  );

  Map<String, dynamic> toJson() => {
    'providerId': providerId,
    'baseUrl': baseUrl,
    'model': model,
    'visionModel': visionModel,
    'timeoutSeconds': timeoutSeconds,
    'headers': headers,
    'temperature': temperature,
    'endpointStyle': endpointStyle?.name,
    'localeCode': localeCode,
    'debug': debug,
  };

  factory AppSettings.fromJson(Map<dynamic, dynamic> j) {
    const d = AppSettings();
    return AppSettings(
      providerId:
          j['providerId'] as String? ??
          (j['baseUrl'] == null ? d.providerId : kCustomProviderId),
      baseUrl: j['baseUrl'] as String? ?? d.baseUrl,
      model: j['model'] as String? ?? d.model,
      visionModel: j['visionModel'] as String? ?? d.visionModel,
      timeoutSeconds: j['timeoutSeconds'] as int? ?? d.timeoutSeconds,
      headers: ((j['headers'] as Map?) ?? const {}).map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      ),
      temperature: (j['temperature'] as num?)?.toDouble() ?? d.temperature,
      endpointStyle: EndpointStyle.values
          .where((e) => e.name == j['endpointStyle'])
          .firstOrNull,
      localeCode: j['localeCode'] as String?,
      debug: j['debug'] as bool? ?? false,
    );
  }
}

class EditRequest {
  const EditRequest({
    required this.imageBytes,
    required this.mimeType,
    required this.prompt,
  });

  final Uint8List imageBytes;
  final String mimeType;
  final String prompt;
}

class EditResult {
  const EditResult(this.bytes);
  final Uint8List bytes;
}

class ConnectionReport {
  const ConnectionReport({
    required this.reachable,
    required this.authOk,
    this.modelListed,
    this.statusCode,
    this.detail,
  });

  final bool reachable;
  final bool authOk;

  /// null when the server does not expose a model list.
  final bool? modelListed;
  final int? statusCode;
  final String? detail;
}
