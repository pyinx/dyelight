import '../models.dart';
import 'api_client.dart';
import 'chat_completions_provider.dart';
import 'image_edit_provider.dart';
import 'images_edits_provider.dart';
import 'images_generations_provider.dart';

ImageEditProvider createProvider(AppSettings settings, String apiKey) {
  final dio = createDio(settings, apiKey);
  // Undetected only matters for testConnection, which is style-independent.
  switch (settings.endpointStyle ?? EndpointStyle.imagesEdits) {
    case EndpointStyle.imagesEdits:
      return ImagesEditsProvider(dio, settings);
    case EndpointStyle.imagesGenerations:
      return ImagesGenerationsProvider(dio, settings);
    case EndpointStyle.chatCompletions:
      return ChatCompletionsProvider(dio, settings);
  }
}
