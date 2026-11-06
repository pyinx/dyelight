import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Dyelight'**
  String get appTitle;

  /// No description provided for @tabCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get tabCreate;

  /// No description provided for @tabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tabHistory;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Bring your photos to life'**
  String get emptyTitle;

  /// No description provided for @emptyHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a photo and let AI fix the exposure and colors.'**
  String get emptyHint;

  /// No description provided for @pickPhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose Photo'**
  String get pickPhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseSource.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get chooseSource;

  /// No description provided for @fromGallery.
  ///
  /// In en, this message translates to:
  /// **'Photo Library'**
  String get fromGallery;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @replacePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get replacePhoto;

  /// No description provided for @modeAuto.
  ///
  /// In en, this message translates to:
  /// **'Smart'**
  String get modeAuto;

  /// No description provided for @modeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get modeCustom;

  /// No description provided for @autoModeHint.
  ///
  /// In en, this message translates to:
  /// **'Reads the photo first, then edits with priorities: the subject stands out, key areas are enhanced, clutter is toned down.'**
  String get autoModeHint;

  /// No description provided for @promptPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Describe the look, e.g. golden hour backlight'**
  String get promptPlaceholder;

  /// No description provided for @autoPrompt.
  ///
  /// In en, this message translates to:
  /// **'Act as a senior photo editor. First read the image: identify the main subject (person, animal, building, landscape or object) and where it is, the scene, light and time of day, whether it is a black-and-white/faded old photo or a color photo, and what hurts it most. Then edit with clear priorities instead of treating every area equally: 1. The subject is the focal point: give it true, natural color and skin tones, more clarity, texture and depth so it stands out; 2. Areas that support the subject (sky, water, foliage, key surroundings) get moderately richer color and depth in harmony with the subject; 3. Cluttered or distracting background and edges get less saturation and contrast, softened or slightly blurred where needed, to lead the eye back to the subject; 4. Colorize black-and-white or faded photos plausibly for the scene and era; correct white balance and color casts in color photos; 5. Recover shadow and highlight detail and remove noise, scratches and stains. Keep the composition, the subject\'s identity and facial features unchanged, and do not add or remove objects.'**
  String get autoPrompt;

  /// No description provided for @smartAnalysisPrompt.
  ///
  /// In en, this message translates to:
  /// **'You are a senior photo editor writing instructions for an AI image-editing model. Study this photo first: what the main subject is and where it sits in the frame; the scene, light and time of day; whether it is a black-and-white/faded old photo or a color photo; and what hurts it most (color cast, exposure, noise, scratches, blur, cluttered background, etc.). Then write one editing instruction for this specific photo, with clear priorities: how to treat the subject as the focal point (color, skin tones, clarity, texture, depth); which areas to enhance and to what effect; which areas to tone down, desaturate or softly blur so the subject stands out; and, for black-and-white or faded photos, which colors each part should get (specific and plausible for the scene and era). Name the actual objects and places in this photo instead of speaking in generalities. Output only the instruction, at most 120 words, with no explanation, headings or Markdown.'**
  String get smartAnalysisPrompt;

  /// No description provided for @smartKeepPrompt.
  ///
  /// In en, this message translates to:
  /// **'Keep the composition, the subject\'s identity and facial features unchanged, and do not add or remove objects.'**
  String get smartKeepPrompt;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @generating1.
  ///
  /// In en, this message translates to:
  /// **'AI is composing colors…'**
  String get generating1;

  /// No description provided for @generating2.
  ///
  /// In en, this message translates to:
  /// **'Balancing light and shadow…'**
  String get generating2;

  /// No description provided for @generating3.
  ///
  /// In en, this message translates to:
  /// **'Polishing the details…'**
  String get generating3;

  /// No description provided for @analyzingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Reading your photo…'**
  String get analyzingPhoto;

  /// No description provided for @cancelGeneration.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelGeneration;

  /// No description provided for @emptyPromptError.
  ///
  /// In en, this message translates to:
  /// **'Enter a prompt or switch to Smart mode.'**
  String get emptyPromptError;

  /// No description provided for @resultTitle.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get resultTitle;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved to your photo library'**
  String get saved;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the photo'**
  String get saveFailed;

  /// No description provided for @tweak.
  ///
  /// In en, this message translates to:
  /// **'Tweak'**
  String get tweak;

  /// No description provided for @holdForOriginal.
  ///
  /// In en, this message translates to:
  /// **'Hold to see the original'**
  String get holdForOriginal;

  /// No description provided for @original.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get original;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No creations yet'**
  String get historyEmpty;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this item?'**
  String get deleteConfirm;

  /// No description provided for @sectionServer.
  ///
  /// In en, this message translates to:
  /// **'Model Service'**
  String get sectionServer;

  /// No description provided for @baseUrl.
  ///
  /// In en, this message translates to:
  /// **'API Base URL'**
  String get baseUrl;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKey;

  /// No description provided for @modelId.
  ///
  /// In en, this message translates to:
  /// **'Model ID'**
  String get modelId;

  /// No description provided for @visionModel.
  ///
  /// In en, this message translates to:
  /// **'Vision model'**
  String get visionModel;

  /// No description provided for @visionModelNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get visionModelNone;

  /// No description provided for @visionModelHint.
  ///
  /// In en, this message translates to:
  /// **'Smart mode first asks a vision model (a chat model that can see images, e.g. gpt-4o-mini, gemini-2.5-flash, qwen-vl-max) to read the photo and decide what to focus on. Without one, the image model analyzes on its own and results depend on its abilities.'**
  String get visionModelHint;

  /// No description provided for @endpointStyle.
  ///
  /// In en, this message translates to:
  /// **'Interface'**
  String get endpointStyle;

  /// No description provided for @endpointImagesEdits.
  ///
  /// In en, this message translates to:
  /// **'/images/edits'**
  String get endpointImagesEdits;

  /// No description provided for @endpointChat.
  ///
  /// In en, this message translates to:
  /// **'/chat/completions'**
  String get endpointChat;

  /// No description provided for @sectionAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get sectionAdvanced;

  /// No description provided for @timeout.
  ///
  /// In en, this message translates to:
  /// **'Timeout (seconds)'**
  String get timeout;

  /// No description provided for @customHeaders.
  ///
  /// In en, this message translates to:
  /// **'Custom headers (Key: Value per line)'**
  String get customHeaders;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @langSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get langSystem;

  /// No description provided for @langZh.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get langZh;

  /// No description provided for @langEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEn;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get testConnection;

  /// No description provided for @testing.
  ///
  /// In en, this message translates to:
  /// **'Testing…'**
  String get testing;

  /// No description provided for @testOk.
  ///
  /// In en, this message translates to:
  /// **'Connected. Server is reachable and the key was accepted.'**
  String get testOk;

  /// No description provided for @testModelListed.
  ///
  /// In en, this message translates to:
  /// **'Model “{model}” is available.'**
  String testModelListed(String model);

  /// No description provided for @testModelMissing.
  ///
  /// In en, this message translates to:
  /// **'Connected, but model “{model}” is not in the server\'s list.'**
  String testModelMissing(String model);

  /// No description provided for @testNoModelList.
  ///
  /// In en, this message translates to:
  /// **'Connected. The server does not provide a model list.'**
  String get testNoModelList;

  /// No description provided for @testAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Server reachable, but the API key was rejected.'**
  String get testAuthFailed;

  /// No description provided for @testUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the server. Check the Base URL and that the device is on the same network.'**
  String get testUnreachable;

  /// No description provided for @testStatus.
  ///
  /// In en, this message translates to:
  /// **'HTTP {code}'**
  String testStatus(String code);

  /// No description provided for @errTimeoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Request timed out'**
  String get errTimeoutTitle;

  /// No description provided for @errTimeoutBody.
  ///
  /// In en, this message translates to:
  /// **'The model is taking a long time to respond. Retry, or check your network and the model service status.'**
  String get errTimeoutBody;

  /// No description provided for @errSafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Request rejected'**
  String get errSafetyTitle;

  /// No description provided for @errSafetyBody.
  ///
  /// In en, this message translates to:
  /// **'The image or prompt did not pass the model\'s safety review, or the request was invalid. Adjust and try again.'**
  String get errSafetyBody;

  /// No description provided for @errAuthTitle.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get errAuthTitle;

  /// No description provided for @errAuthBody.
  ///
  /// In en, this message translates to:
  /// **'Check your API key in Settings.'**
  String get errAuthBody;

  /// No description provided for @errNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get errNetworkTitle;

  /// No description provided for @errNetworkBody.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the service. Check the Base URL and your network or LAN connection.'**
  String get errNetworkBody;

  /// No description provided for @errBadTitle.
  ///
  /// In en, this message translates to:
  /// **'Unexpected response'**
  String get errBadTitle;

  /// No description provided for @errBadBody.
  ///
  /// In en, this message translates to:
  /// **'The service did not return a usable image.'**
  String get errBadBody;

  /// No description provided for @errGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errGenericTitle;

  /// No description provided for @errImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot read this image'**
  String get errImageTitle;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @permTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission needed'**
  String get permTitle;

  /// No description provided for @permCameraBody.
  ///
  /// In en, this message translates to:
  /// **'Allow camera access in Settings to take photos.'**
  String get permCameraBody;

  /// No description provided for @permMicBody.
  ///
  /// In en, this message translates to:
  /// **'Allow microphone and speech recognition access in Settings to use voice input.'**
  String get permMicBody;

  /// No description provided for @permPhotosBody.
  ///
  /// In en, this message translates to:
  /// **'Allow photo library access in Settings to save results.'**
  String get permPhotosBody;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @voiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice input is not available on this device.'**
  String get voiceUnavailable;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get listening;

  /// No description provided for @interfaceAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto-detected on first use'**
  String get interfaceAuto;

  /// No description provided for @interfaceDetected.
  ///
  /// In en, this message translates to:
  /// **'Detected {path}'**
  String interfaceDetected(String path);

  /// No description provided for @interfaceUndetected.
  ///
  /// In en, this message translates to:
  /// **'Could not detect a supported image API at this URL.'**
  String get interfaceUndetected;

  /// No description provided for @provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// No description provided for @providerCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom (OpenAI-compatible)'**
  String get providerCustom;

  /// No description provided for @selectModel.
  ///
  /// In en, this message translates to:
  /// **'Select Model'**
  String get selectModel;

  /// No description provided for @searchModels.
  ///
  /// In en, this message translates to:
  /// **'Search or type a model ID'**
  String get searchModels;

  /// No description provided for @useModel.
  ///
  /// In en, this message translates to:
  /// **'Use “{model}”'**
  String useModel(String model);

  /// No description provided for @fetchingModels.
  ///
  /// In en, this message translates to:
  /// **'Fetching models…'**
  String get fetchingModels;

  /// No description provided for @modelsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the model list. You can type a model ID above.'**
  String get modelsFailed;

  /// No description provided for @noModelsFound.
  ///
  /// In en, this message translates to:
  /// **'No models found.'**
  String get noModelsFound;

  /// No description provided for @endpointImagesGenerations.
  ///
  /// In en, this message translates to:
  /// **'/images/generations'**
  String get endpointImagesGenerations;

  /// No description provided for @debugSection.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get debugSection;

  /// No description provided for @debugMode.
  ///
  /// In en, this message translates to:
  /// **'Debug mode'**
  String get debugMode;

  /// No description provided for @debugModeHint.
  ///
  /// In en, this message translates to:
  /// **'Records requests and responses (API key hidden, images shortened) so you can copy them for troubleshooting. Cleared when the app restarts.'**
  String get debugModeHint;

  /// No description provided for @debugLogView.
  ///
  /// In en, this message translates to:
  /// **'View debug log'**
  String get debugLogView;

  /// No description provided for @debugTitle.
  ///
  /// In en, this message translates to:
  /// **'Debug Log'**
  String get debugTitle;

  /// No description provided for @debugCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy All'**
  String get debugCopy;

  /// No description provided for @debugCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get debugCopied;

  /// No description provided for @debugClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get debugClear;

  /// No description provided for @debugEmpty.
  ///
  /// In en, this message translates to:
  /// **'No entries yet. Run Test Connection or generate a photo.'**
  String get debugEmpty;

  /// No description provided for @modeRecolor.
  ///
  /// In en, this message translates to:
  /// **'Recolor'**
  String get modeRecolor;

  /// No description provided for @modeCollage.
  ///
  /// In en, this message translates to:
  /// **'Collage'**
  String get modeCollage;

  /// No description provided for @collageEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Combine photos into one image'**
  String get collageEmptyTitle;

  /// No description provided for @collageEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Pick up to 9 photos, then choose a layout and a style.'**
  String get collageEmptyHint;

  /// No description provided for @collageAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get collageAddPhotos;

  /// No description provided for @collageLayout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get collageLayout;

  /// No description provided for @collageStyle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get collageStyle;

  /// No description provided for @collageTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Title (optional)'**
  String get collageTitleHint;

  /// No description provided for @collageSubtitleHint.
  ///
  /// In en, this message translates to:
  /// **'Subtitle (optional)'**
  String get collageSubtitleHint;

  /// No description provided for @collageNeedMore.
  ///
  /// In en, this message translates to:
  /// **'Add {n} more to fill this layout'**
  String collageNeedMore(int n);

  /// No description provided for @collageExtraUnused.
  ///
  /// In en, this message translates to:
  /// **'Photos past the last cell are not used'**
  String get collageExtraUnused;

  /// No description provided for @collageCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Collage'**
  String get collageCreate;

  /// No description provided for @collageBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get collageBackground;

  /// No description provided for @collageGap.
  ///
  /// In en, this message translates to:
  /// **'Spacing'**
  String get collageGap;

  /// No description provided for @collageRadius.
  ///
  /// In en, this message translates to:
  /// **'Corners'**
  String get collageRadius;

  /// No description provided for @collageRatio.
  ///
  /// In en, this message translates to:
  /// **'Ratio'**
  String get collageRatio;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @moveEarlier.
  ///
  /// In en, this message translates to:
  /// **'Move Earlier'**
  String get moveEarlier;

  /// No description provided for @historyCollage.
  ///
  /// In en, this message translates to:
  /// **'Collage'**
  String get historyCollage;

  /// No description provided for @adjustFromResult.
  ///
  /// In en, this message translates to:
  /// **'Continue from this result'**
  String get adjustFromResult;

  /// No description provided for @adjustFromOriginal.
  ///
  /// In en, this message translates to:
  /// **'Start over from the original'**
  String get adjustFromOriginal;

  /// No description provided for @collageSmart.
  ///
  /// In en, this message translates to:
  /// **'Smart'**
  String get collageSmart;

  /// No description provided for @collageDragHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press a photo and drag it onto another to swap places'**
  String get collageDragHint;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get appVersion;

  /// No description provided for @homeTagline.
  ///
  /// In en, this message translates to:
  /// **'Give every photo its light'**
  String get homeTagline;

  /// No description provided for @homeIntro.
  ///
  /// In en, this message translates to:
  /// **'Dyelight recolors and restores photos with the AI model you bring, and turns many photos into one shareable collage.'**
  String get homeIntro;

  /// No description provided for @homeRecolorTitle.
  ///
  /// In en, this message translates to:
  /// **'Recolor'**
  String get homeRecolorTitle;

  /// No description provided for @homeRecolorDesc.
  ///
  /// In en, this message translates to:
  /// **'One tap to colorize, repair and restyle, with {n} built-in looks: restore, filters, art, landscape, portrait and scenes.'**
  String homeRecolorDesc(int n);

  /// No description provided for @homeRecolorCta.
  ///
  /// In en, this message translates to:
  /// **'Start recoloring'**
  String get homeRecolorCta;

  /// No description provided for @homeCollageTitle.
  ///
  /// In en, this message translates to:
  /// **'Collage'**
  String get homeCollageTitle;

  /// No description provided for @homeCollageDesc.
  ///
  /// In en, this message translates to:
  /// **'Smart layouts for up to 9 photos: side by side, stacked, 4 or 9 grid. Styles for Xiaohongshu, Moments, Editorial, Swiss or your own.'**
  String get homeCollageDesc;

  /// No description provided for @homeCollageCta.
  ///
  /// In en, this message translates to:
  /// **'Start a collage'**
  String get homeCollageCta;

  /// No description provided for @homeFeaturesTitle.
  ///
  /// In en, this message translates to:
  /// **'Why Dyelight'**
  String get homeFeaturesTitle;

  /// No description provided for @featByokTitle.
  ///
  /// In en, this message translates to:
  /// **'Bring your own model'**
  String get featByokTitle;

  /// No description provided for @featByokDesc.
  ///
  /// In en, this message translates to:
  /// **'Use your own API key with OpenAI, Doubao, Gemini and more. The interface type is detected for you.'**
  String get featByokDesc;

  /// No description provided for @featPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Private by design'**
  String get featPrivacyTitle;

  /// No description provided for @featPrivacyDesc.
  ///
  /// In en, this message translates to:
  /// **'Your key stays encrypted on this device. Photos go only to the service you set up.'**
  String get featPrivacyDesc;

  /// No description provided for @featLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'Collages stay on your phone'**
  String get featLocalTitle;

  /// No description provided for @featLocalDesc.
  ///
  /// In en, this message translates to:
  /// **'Collages are composed locally: no AI calls and no cost.'**
  String get featLocalDesc;

  /// No description provided for @featHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep refining'**
  String get featHistoryTitle;

  /// No description provided for @featHistoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Every result is saved. Reopen it to rename, adjust or start over from the original.'**
  String get featHistoryDesc;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @renameHint.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get renameHint;

  /// No description provided for @historyAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get historyAll;

  /// No description provided for @rangeAll.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get rangeAll;

  /// No description provided for @rangeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get rangeToday;

  /// No description provided for @range7.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get range7;

  /// No description provided for @range30.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get range30;

  /// No description provided for @rangeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom range…'**
  String get rangeCustom;

  /// No description provided for @rangeStart.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get rangeStart;

  /// No description provided for @rangeEnd.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get rangeEnd;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @historyNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No creations match these filters'**
  String get historyNoMatch;

  /// No description provided for @resetFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get resetFilters;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
