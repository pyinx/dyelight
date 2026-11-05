const String kCustomProviderId = 'custom';

class ProviderPreset {
  const ProviderPreset(this.id, this.name, this.baseUrl, this.defaultModel);
  final String id;
  final String name;
  final String baseUrl;

  /// Only a starting suggestion; the user picks from the fetched list.
  final String defaultModel;
}

/// OpenAI-compatible endpoints. Keep this list under 10 entries.
const List<ProviderPreset> kProviderPresets = [
  ProviderPreset(
    'openai',
    'OpenAI',
    'https://api.openai.com/v1',
    'gpt-image-1',
  ),
  ProviderPreset(
    'google',
    'Google Gemini',
    'https://generativelanguage.googleapis.com/v1beta/openai',
    'gemini-2.5-flash-image',
  ),
  ProviderPreset(
    'openrouter',
    'OpenRouter',
    'https://openrouter.ai/api/v1',
    'google/gemini-2.5-flash-image',
  ),
  ProviderPreset('xai', 'xAI', 'https://api.x.ai/v1', 'grok-2-image'),
  ProviderPreset(
    'siliconflow',
    '硅基流动 SiliconFlow',
    'https://api.siliconflow.cn/v1',
    'Qwen/Qwen-Image-Edit',
  ),
  ProviderPreset(
    'volcengine',
    '火山方舟 Volcengine Ark',
    'https://ark.cn-beijing.volces.com/api/v3',
    'doubao-seedream-4-0-250828',
  ),
  ProviderPreset(
    'dashscope',
    '阿里云百炼 DashScope',
    'https://dashscope.aliyuncs.com/compatible-mode/v1',
    'qwen-image-edit',
  ),
  ProviderPreset(
    'zhipu',
    '智谱 Zhipu',
    'https://open.bigmodel.cn/api/paas/v4',
    'cogview-4',
  ),
];

ProviderPreset? presetById(String id) {
  for (final p in kProviderPresets) {
    if (p.id == id) return p;
  }
  return null;
}
