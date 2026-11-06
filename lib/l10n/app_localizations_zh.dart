// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '染光';

  @override
  String get tabCreate => '创作';

  @override
  String get tabHistory => '历史';

  @override
  String get tabSettings => '设置';

  @override
  String get emptyTitle => '让旧照片重焕生机';

  @override
  String get emptyHint => '选一张照片，让 AI 修复曝光与色彩。';

  @override
  String get pickPhoto => '选择照片';

  @override
  String get takePhoto => '拍照';

  @override
  String get chooseSource => '添加照片';

  @override
  String get fromGallery => '相册';

  @override
  String get cancel => '取消';

  @override
  String get replacePhoto => '更换照片';

  @override
  String get modeAuto => '智能';

  @override
  String get modeCustom => '自定义';

  @override
  String get autoModeHint => '先读懂照片内容，再分主次处理：突出主体，增强关键区域，弱化杂乱背景。';

  @override
  String get promptPlaceholder => '描述想要的色调，如“日落逆光黄金时刻”';

  @override
  String get autoPrompt =>
      '请作为资深修图师处理这张照片。先读懂画面：判断主体（人物、动物、建筑、风景或物品）及其位置，场景、光线与时间，是黑白/褪色老照片还是彩色照片，以及最影响观感的问题。然后分主次处理，不要全图平均用力：1. 主体是视觉重点：还原真实自然的色彩与肤色，提升清晰度、质感与立体感，让主体从画面中凸显；2. 衬托主体的区域（天空、水面、植被、关键环境）适度增强色彩与层次，色调与主体协调；3. 杂乱或抢眼的次要背景与边缘区域降低饱和度与对比，必要时轻微柔化虚化，把视线引回主体；4. 黑白或褪色照片按场景与年代合理上色，彩色照片校正白平衡与偏色；5. 恢复暗部与高光细节，去除噪点、划痕与污渍。保持构图、主体身份和人脸五官不变，不要增删物体。';

  @override
  String get smartAnalysisPrompt =>
      '你是资深修图师，要为一个 AI 图片编辑模型写修图指令。先仔细看这张照片：主体是什么、在画面哪个位置；场景、光线与时间；是黑白/褪色老照片还是彩色照片；最影响观感的问题（偏色、曝光、噪点、划痕、模糊、杂乱背景等）。然后写一段针对这张照片的修图指令，分主次说明：主体如何重点处理（色彩、肤色、清晰度、质感、立体感）；哪些区域需要增强，目标效果是什么；哪些区域需要弱化、降饱和或轻微虚化来突出主体；如果是黑白或褪色照片，各部分应上什么颜色（结合场景与年代给出具体合理的颜色）。必须点名这张照片里的具体对象和位置，不要泛泛而谈。只输出指令本身，不超过 200 字，不要解释、标题或 Markdown。';

  @override
  String get smartKeepPrompt => '保持构图、主体身份和人脸五官不变，不要增删物体。';

  @override
  String get start => '开始生成';

  @override
  String get generating1 => 'AI 正在构思色彩…';

  @override
  String get generating2 => '正在平衡光影…';

  @override
  String get generating3 => '正在打磨细节…';

  @override
  String get analyzingPhoto => '正在读懂照片…';

  @override
  String get cancelGeneration => '取消';

  @override
  String get emptyPromptError => '请输入提示词，或切换到智能模式。';

  @override
  String get resultTitle => '效果';

  @override
  String get save => '保存';

  @override
  String get saved => '已保存到相册';

  @override
  String get saveFailed => '保存失败';

  @override
  String get tweak => '微调';

  @override
  String get holdForOriginal => '长按查看原图';

  @override
  String get original => '原图';

  @override
  String get historyEmpty => '还没有作品';

  @override
  String get delete => '删除';

  @override
  String get deleteConfirm => '确定删除这条记录吗？';

  @override
  String get sectionServer => '模型服务';

  @override
  String get baseUrl => 'API Base URL';

  @override
  String get apiKey => 'API Key';

  @override
  String get modelId => '模型 ID';

  @override
  String get visionModel => '图片理解模型';

  @override
  String get visionModelNone => '不使用';

  @override
  String get visionModelHint =>
      '智能模式会先用图片理解模型（能看图的对话模型，如 gpt-4o-mini、gemini-2.5-flash、qwen-vl-max）分析照片，再决定处理重点；不设置时由图片模型自行分析，效果取决于模型能力。';

  @override
  String get endpointStyle => '接口类型';

  @override
  String get endpointImagesEdits => '/images/edits';

  @override
  String get endpointChat => '/chat/completions';

  @override
  String get sectionAdvanced => '高级设置';

  @override
  String get timeout => '请求超时（秒）';

  @override
  String get customHeaders => '自定义 Headers（每行 Key: Value）';

  @override
  String get temperature => 'Temperature';

  @override
  String get language => '语言';

  @override
  String get langSystem => '跟随系统';

  @override
  String get langZh => '简体中文';

  @override
  String get langEn => 'English';

  @override
  String get testConnection => '测试连接';

  @override
  String get testing => '测试中…';

  @override
  String get testOk => '连接成功，服务可达且密钥有效。';

  @override
  String testModelListed(String model) {
    return '模型“$model”可用。';
  }

  @override
  String testModelMissing(String model) {
    return '已连接，但服务的模型列表中没有“$model”。';
  }

  @override
  String get testNoModelList => '已连接，服务未提供模型列表。';

  @override
  String get testAuthFailed => '服务可达，但 API Key 被拒绝。';

  @override
  String get testUnreachable => '无法连接服务。请检查 Base URL，并确认设备在同一局域网。';

  @override
  String testStatus(String code) {
    return 'HTTP $code';
  }

  @override
  String get errTimeoutTitle => '请求超时';

  @override
  String get errTimeoutBody => '大模型生成耗时较长。可重试，或检查网络与模型服务状态。';

  @override
  String get errSafetyTitle => '请求被拒绝';

  @override
  String get errSafetyBody => '图片或提示词未通过模型安全审查，或请求无效，请调整后重试。';

  @override
  String get errAuthTitle => '认证失败';

  @override
  String get errAuthBody => '请在设置中检查 API Key。';

  @override
  String get errNetworkTitle => '网络错误';

  @override
  String get errNetworkBody => '无法连接服务，请检查 Base URL 以及网络或局域网连通性。';

  @override
  String get errBadTitle => '响应异常';

  @override
  String get errBadBody => '服务没有返回可用的图片。';

  @override
  String get errGenericTitle => '出错了';

  @override
  String get errImageTitle => '无法读取这张图片';

  @override
  String get retry => '重试';

  @override
  String get ok => '好';

  @override
  String get permTitle => '需要权限';

  @override
  String get permCameraBody => '请在系统设置中允许访问相机以拍照。';

  @override
  String get permMicBody => '请在系统设置中允许麦克风与语音识别权限以使用语音输入。';

  @override
  String get permPhotosBody => '请在系统设置中允许访问相册以保存结果。';

  @override
  String get openSettings => '前往设置';

  @override
  String get voiceUnavailable => '此设备不支持语音输入。';

  @override
  String get listening => '正在聆听…';

  @override
  String get interfaceAuto => '首次使用时自动识别';

  @override
  String interfaceDetected(String path) {
    return '已识别 $path';
  }

  @override
  String get interfaceUndetected => '该地址下未识别到可用的图片接口。';

  @override
  String get provider => '服务商';

  @override
  String get providerCustom => '自定义（OpenAI 兼容）';

  @override
  String get selectModel => '选择模型';

  @override
  String get searchModels => '搜索或输入模型 ID';

  @override
  String useModel(String model) {
    return '使用“$model”';
  }

  @override
  String get fetchingModels => '正在获取模型列表…';

  @override
  String get modelsFailed => '无法获取模型列表，可在上方直接输入模型 ID。';

  @override
  String get noModelsFound => '没有找到模型。';

  @override
  String get endpointImagesGenerations => '/images/generations';

  @override
  String get debugSection => '调试';

  @override
  String get debugMode => '调试模式';

  @override
  String get debugModeHint =>
      '记录请求与响应（隐藏 API Key，图片内容会被截断），可一键复制用于排查问题。应用重启后清空。';

  @override
  String get debugLogView => '查看调试日志';

  @override
  String get debugTitle => '调试日志';

  @override
  String get debugCopy => '一键复制';

  @override
  String get debugCopied => '已复制到剪贴板';

  @override
  String get debugClear => '清空';

  @override
  String get debugEmpty => '暂无记录。请先点“测试连接”或生成一张照片。';

  @override
  String get modeRecolor => '上色';

  @override
  String get modeCollage => '拼图';

  @override
  String get collageEmptyTitle => '把多张照片拼成一张';

  @override
  String get collageEmptyHint => '最多选 9 张照片，再挑选布局和风格。';

  @override
  String get collageAddPhotos => '添加照片';

  @override
  String get collageLayout => '布局';

  @override
  String get collageStyle => '风格';

  @override
  String get collageTitleHint => '标题（可选）';

  @override
  String get collageSubtitleHint => '副标题（可选）';

  @override
  String collageNeedMore(int n) {
    return '还需添加 $n 张才能填满此布局';
  }

  @override
  String get collageExtraUnused => '超出格子数的照片不会被使用';

  @override
  String get collageCreate => '生成拼图';

  @override
  String get collageBackground => '背景';

  @override
  String get collageGap => '间距';

  @override
  String get collageRadius => '圆角';

  @override
  String get collageRatio => '比例';

  @override
  String get replace => '替换';

  @override
  String get remove => '移除';

  @override
  String get moveEarlier => '前移一位';

  @override
  String get historyCollage => '拼图';

  @override
  String get adjustFromResult => '基于当前结果继续调整';

  @override
  String get adjustFromOriginal => '基于原图重新调整';

  @override
  String get collageSmart => '智能';

  @override
  String get collageDragHint => '长按照片并拖到另一格，可交换位置';

  @override
  String get aboutSection => '关于';

  @override
  String get appVersion => '版本';

  @override
  String get homeTagline => '让每张照片重新有光';

  @override
  String get homeIntro => '染光用你自己的 AI 模型给照片上色、修复、换风格，也能把多张照片拼成一张适合分享的图。';

  @override
  String get homeRecolorTitle => '上色';

  @override
  String homeRecolorDesc(int n) {
    return '一键上色、修复、换风格，内置 $n 个模板：上色修复、风格滤镜、艺术、风景、人像、场景换景。';
  }

  @override
  String get homeRecolorCta => '开始上色';

  @override
  String get homeCollageTitle => '拼图';

  @override
  String get homeCollageDesc =>
      '最多 9 张照片智能布局：左右、上下、四宫格、九宫格，支持小红书、朋友圈、杂志、瑞士和自定义风格。';

  @override
  String get homeCollageCta => '开始拼图';

  @override
  String get homeFeaturesTitle => '为什么选染光';

  @override
  String get featByokTitle => '自带模型';

  @override
  String get featByokDesc => '使用你自己的 API Key，支持 OpenAI、豆包、Gemini 等，接口类型自动识别。';

  @override
  String get featPrivacyTitle => '隐私优先';

  @override
  String get featPrivacyDesc => '密钥加密保存在本机，照片只发送到你配置的服务。';

  @override
  String get featLocalTitle => '拼图完全本地';

  @override
  String get featLocalDesc => '拼图在手机上合成，不调用 AI，不产生费用。';

  @override
  String get featHistoryTitle => '随时继续调整';

  @override
  String get featHistoryDesc => '每次结果都会保存，可随时重命名、继续调整，或从原图重来。';

  @override
  String get rename => '重命名';

  @override
  String get renameHint => '名称';

  @override
  String get historyAll => '全部';

  @override
  String get rangeAll => '全部时间';

  @override
  String get rangeToday => '今天';

  @override
  String get range7 => '近 7 天';

  @override
  String get range30 => '近 30 天';

  @override
  String get rangeCustom => '自定义时间…';

  @override
  String get rangeStart => '开始';

  @override
  String get rangeEnd => '结束';

  @override
  String get done => '完成';

  @override
  String get historyNoMatch => '没有符合条件的记录';

  @override
  String get resetFilters => '清除筛选';
}
