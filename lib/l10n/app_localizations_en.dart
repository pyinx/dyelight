// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Dyelight';

  @override
  String get tabCreate => 'Create';

  @override
  String get tabHistory => 'History';

  @override
  String get tabSettings => 'Settings';

  @override
  String get emptyTitle => 'Bring your photos to life';

  @override
  String get emptyHint =>
      'Pick a photo and let AI fix the exposure and colors.';

  @override
  String get pickPhoto => 'Choose Photo';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseSource => 'Add a photo';

  @override
  String get fromGallery => 'Photo Library';

  @override
  String get cancel => 'Cancel';

  @override
  String get replacePhoto => 'Change Photo';

  @override
  String get modeAuto => 'Smart';

  @override
  String get modeCustom => 'Custom';

  @override
  String get autoModeHint =>
      'Reads the photo first, then edits with priorities: the subject stands out, key areas are enhanced, clutter is toned down.';

  @override
  String get promptPlaceholder =>
      'Describe the look, e.g. golden hour backlight';

  @override
  String get autoPrompt =>
      'Act as a senior photo editor. First read the image: identify the main subject (person, animal, building, landscape or object) and where it is, the scene, light and time of day, whether it is a black-and-white/faded old photo or a color photo, and what hurts it most. Then edit with clear priorities instead of treating every area equally: 1. The subject is the focal point: give it true, natural color and skin tones, more clarity, texture and depth so it stands out; 2. Areas that support the subject (sky, water, foliage, key surroundings) get moderately richer color and depth in harmony with the subject; 3. Cluttered or distracting background and edges get less saturation and contrast, softened or slightly blurred where needed, to lead the eye back to the subject; 4. Colorize black-and-white or faded photos plausibly for the scene and era; correct white balance and color casts in color photos; 5. Recover shadow and highlight detail and remove noise, scratches and stains. Keep the composition, the subject\'s identity and facial features unchanged, and do not add or remove objects.';

  @override
  String get smartAnalysisPrompt =>
      'You are a senior photo editor writing instructions for an AI image-editing model. Study this photo first: what the main subject is and where it sits in the frame; the scene, light and time of day; whether it is a black-and-white/faded old photo or a color photo; and what hurts it most (color cast, exposure, noise, scratches, blur, cluttered background, etc.). Then write one editing instruction for this specific photo, with clear priorities: how to treat the subject as the focal point (color, skin tones, clarity, texture, depth); which areas to enhance and to what effect; which areas to tone down, desaturate or softly blur so the subject stands out; and, for black-and-white or faded photos, which colors each part should get (specific and plausible for the scene and era). Name the actual objects and places in this photo instead of speaking in generalities. Output only the instruction, at most 120 words, with no explanation, headings or Markdown.';

  @override
  String get smartKeepPrompt =>
      'Keep the composition, the subject\'s identity and facial features unchanged, and do not add or remove objects.';

  @override
  String get start => 'Start';

  @override
  String get generating1 => 'AI is composing colors…';

  @override
  String get generating2 => 'Balancing light and shadow…';

  @override
  String get generating3 => 'Polishing the details…';

  @override
  String get analyzingPhoto => 'Reading your photo…';

  @override
  String get cancelGeneration => 'Cancel';

  @override
  String get emptyPromptError => 'Enter a prompt or switch to Smart mode.';

  @override
  String get resultTitle => 'Result';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved to your photo library';

  @override
  String get saveFailed => 'Could not save the photo';

  @override
  String get tweak => 'Tweak';

  @override
  String get holdForOriginal => 'Hold to see the original';

  @override
  String get original => 'Original';

  @override
  String get historyEmpty => 'No creations yet';

  @override
  String get delete => 'Delete';

  @override
  String get deleteConfirm => 'Delete this item?';

  @override
  String get sectionServer => 'Model Service';

  @override
  String get baseUrl => 'API Base URL';

  @override
  String get apiKey => 'API Key';

  @override
  String get modelId => 'Model ID';

  @override
  String get visionModel => 'Vision model';

  @override
  String get visionModelNone => 'None';

  @override
  String get visionModelHint =>
      'Smart mode first asks a vision model (a chat model that can see images, e.g. gpt-4o-mini, gemini-2.5-flash, qwen-vl-max) to read the photo and decide what to focus on. Without one, the image model analyzes on its own and results depend on its abilities.';

  @override
  String get endpointStyle => 'Interface';

  @override
  String get endpointImagesEdits => '/images/edits';

  @override
  String get endpointChat => '/chat/completions';

  @override
  String get sectionAdvanced => 'Advanced';

  @override
  String get timeout => 'Timeout (seconds)';

  @override
  String get customHeaders => 'Custom headers (Key: Value per line)';

  @override
  String get temperature => 'Temperature';

  @override
  String get language => 'Language';

  @override
  String get langSystem => 'System';

  @override
  String get langZh => '简体中文';

  @override
  String get langEn => 'English';

  @override
  String get testConnection => 'Test Connection';

  @override
  String get testing => 'Testing…';

  @override
  String get testOk =>
      'Connected. Server is reachable and the key was accepted.';

  @override
  String testModelListed(String model) {
    return 'Model “$model” is available.';
  }

  @override
  String testModelMissing(String model) {
    return 'Connected, but model “$model” is not in the server\'s list.';
  }

  @override
  String get testNoModelList =>
      'Connected. The server does not provide a model list.';

  @override
  String get testAuthFailed =>
      'Server reachable, but the API key was rejected.';

  @override
  String get testUnreachable =>
      'Cannot reach the server. Check the Base URL and that the device is on the same network.';

  @override
  String testStatus(String code) {
    return 'HTTP $code';
  }

  @override
  String get errTimeoutTitle => 'Request timed out';

  @override
  String get errTimeoutBody =>
      'The model is taking a long time to respond. Retry, or check your network and the model service status.';

  @override
  String get errSafetyTitle => 'Request rejected';

  @override
  String get errSafetyBody =>
      'The image or prompt did not pass the model\'s safety review, or the request was invalid. Adjust and try again.';

  @override
  String get errAuthTitle => 'Authentication failed';

  @override
  String get errAuthBody => 'Check your API key in Settings.';

  @override
  String get errNetworkTitle => 'Network error';

  @override
  String get errNetworkBody =>
      'Could not reach the service. Check the Base URL and your network or LAN connection.';

  @override
  String get errBadTitle => 'Unexpected response';

  @override
  String get errBadBody => 'The service did not return a usable image.';

  @override
  String get errGenericTitle => 'Something went wrong';

  @override
  String get errImageTitle => 'Cannot read this image';

  @override
  String get retry => 'Retry';

  @override
  String get ok => 'OK';

  @override
  String get permTitle => 'Permission needed';

  @override
  String get permCameraBody =>
      'Allow camera access in Settings to take photos.';

  @override
  String get permMicBody =>
      'Allow microphone and speech recognition access in Settings to use voice input.';

  @override
  String get permPhotosBody =>
      'Allow photo library access in Settings to save results.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get voiceUnavailable => 'Voice input is not available on this device.';

  @override
  String get listening => 'Listening…';

  @override
  String get interfaceAuto => 'Auto-detected on first use';

  @override
  String interfaceDetected(String path) {
    return 'Detected $path';
  }

  @override
  String get interfaceUndetected =>
      'Could not detect a supported image API at this URL.';

  @override
  String get provider => 'Provider';

  @override
  String get providerCustom => 'Custom (OpenAI-compatible)';

  @override
  String get selectModel => 'Select Model';

  @override
  String get searchModels => 'Search or type a model ID';

  @override
  String useModel(String model) {
    return 'Use “$model”';
  }

  @override
  String get fetchingModels => 'Fetching models…';

  @override
  String get modelsFailed =>
      'Could not load the model list. You can type a model ID above.';

  @override
  String get noModelsFound => 'No models found.';

  @override
  String get endpointImagesGenerations => '/images/generations';

  @override
  String get debugSection => 'Debug';

  @override
  String get debugMode => 'Debug mode';

  @override
  String get debugModeHint =>
      'Records requests and responses (API key hidden, images shortened) so you can copy them for troubleshooting. Cleared when the app restarts.';

  @override
  String get debugLogView => 'View debug log';

  @override
  String get debugTitle => 'Debug Log';

  @override
  String get debugCopy => 'Copy All';

  @override
  String get debugCopied => 'Copied to clipboard';

  @override
  String get debugClear => 'Clear';

  @override
  String get debugEmpty =>
      'No entries yet. Run Test Connection or generate a photo.';

  @override
  String get modeRecolor => 'Recolor';

  @override
  String get modeCollage => 'Collage';

  @override
  String get collageEmptyTitle => 'Combine photos into one image';

  @override
  String get collageEmptyHint =>
      'Pick up to 9 photos, then choose a layout and a style.';

  @override
  String get collageAddPhotos => 'Add Photos';

  @override
  String get collageLayout => 'Layout';

  @override
  String get collageStyle => 'Style';

  @override
  String get collageTitleHint => 'Title (optional)';

  @override
  String get collageSubtitleHint => 'Subtitle (optional)';

  @override
  String collageNeedMore(int n) {
    return 'Add $n more to fill this layout';
  }

  @override
  String get collageExtraUnused => 'Photos past the last cell are not used';

  @override
  String get collageCreate => 'Create Collage';

  @override
  String get collageBackground => 'Background';

  @override
  String get collageGap => 'Spacing';

  @override
  String get collageRadius => 'Corners';

  @override
  String get collageRatio => 'Ratio';

  @override
  String get replace => 'Replace';

  @override
  String get remove => 'Remove';

  @override
  String get moveEarlier => 'Move Earlier';

  @override
  String get historyCollage => 'Collage';

  @override
  String get adjustFromResult => 'Continue from this result';

  @override
  String get adjustFromOriginal => 'Start over from the original';

  @override
  String get collageSmart => 'Smart';

  @override
  String get collageDragHint =>
      'Long-press a photo and drag it onto another to swap places';

  @override
  String get aboutSection => 'About';

  @override
  String get appVersion => 'Version';

  @override
  String get homeTagline => 'Give every photo its light';

  @override
  String get homeIntro =>
      'Dyelight recolors and restores photos with the AI model you bring, and turns many photos into one shareable collage.';

  @override
  String get homeRecolorTitle => 'Recolor';

  @override
  String homeRecolorDesc(int n) {
    return 'One tap to colorize, repair and restyle, with $n built-in looks: restore, filters, art, landscape, portrait and scenes.';
  }

  @override
  String get homeRecolorCta => 'Start recoloring';

  @override
  String get homeCollageTitle => 'Collage';

  @override
  String get homeCollageDesc =>
      'Smart layouts for up to 9 photos: side by side, stacked, 4 or 9 grid. Styles for Xiaohongshu, Moments, Editorial, Swiss or your own.';

  @override
  String get homeCollageCta => 'Start a collage';

  @override
  String get homeFeaturesTitle => 'Why Dyelight';

  @override
  String get featByokTitle => 'Bring your own model';

  @override
  String get featByokDesc =>
      'Use your own API key with OpenAI, Doubao, Gemini and more. The interface type is detected for you.';

  @override
  String get featPrivacyTitle => 'Private by design';

  @override
  String get featPrivacyDesc =>
      'Your key stays encrypted on this device. Photos go only to the service you set up.';

  @override
  String get featLocalTitle => 'Collages stay on your phone';

  @override
  String get featLocalDesc =>
      'Collages are composed locally: no AI calls and no cost.';

  @override
  String get featHistoryTitle => 'Keep refining';

  @override
  String get featHistoryDesc =>
      'Every result is saved. Reopen it to rename, adjust or start over from the original.';

  @override
  String get rename => 'Rename';

  @override
  String get renameHint => 'Name';

  @override
  String get historyAll => 'All';

  @override
  String get rangeAll => 'All time';

  @override
  String get rangeToday => 'Today';

  @override
  String get range7 => 'Last 7 days';

  @override
  String get range30 => 'Last 30 days';

  @override
  String get rangeCustom => 'Custom range…';

  @override
  String get rangeStart => 'From';

  @override
  String get rangeEnd => 'To';

  @override
  String get done => 'Done';

  @override
  String get historyNoMatch => 'No creations match these filters';

  @override
  String get resetFilters => 'Clear filters';
}
