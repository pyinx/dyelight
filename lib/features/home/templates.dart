/// Built-in one-tap looks for the Custom recolor mode. Names and prompts are
/// bilingual data (not UI chrome), so they live here instead of the ARB files.
class Template {
  const Template(this.icon, this.zh, this.en, this.zhPrompt, this.enPrompt);
  final String icon;
  final String zh, en, zhPrompt, enPrompt;

  String name(bool isZh) => isZh ? zh : en;
  String prompt(bool isZh) => isZh ? zhPrompt : enPrompt;
}

class TemplateCategory {
  const TemplateCategory(this.zh, this.en, this.items);
  final String zh, en;
  final List<Template> items;
  String name(bool isZh) => isZh ? zh : en;
}

const kTemplateCategories = <TemplateCategory>[
  TemplateCategory('上色修复', 'Restore', [
    Template(
      '🎨',
      '老照片上色',
      'Colorize',
      '给这张黑白老照片上色，肤色自然、衣物与环境色彩真实协调，保留原有构图、人物与细节，不增删物体。',
      'Colorize this black-and-white photo with natural skin tones and realistic, harmonious colors for clothing and surroundings. Keep composition, people and details unchanged; add or remove nothing.',
    ),
    Template(
      '🩹',
      '老照片修复',
      'Repair',
      '修复这张老照片：去除划痕、折痕、污渍和噪点，恢复清晰度与层次，保持人物面貌不变。',
      'Repair this old photo: remove scratches, creases, stains and noise, restore sharpness and tonal range, and keep faces unchanged.',
    ),
    Template(
      '🔍',
      '清晰增强',
      'Sharpen',
      '提升这张照片的清晰度和细节，降噪，恢复纹理，保持真实自然，不改变内容。',
      'Enhance clarity and detail, reduce noise and recover texture while staying natural. Do not change the content.',
    ),
    Template(
      '☀️',
      '曝光校正',
      'Fix exposure',
      '校正曝光与白平衡，找回高光和暗部细节，色彩平衡自然。',
      'Correct exposure and white balance, recover highlight and shadow detail, with natural balanced color.',
    ),
  ]),
  TemplateCategory('风格滤镜', 'Looks', [
    Template(
      '🎞️',
      '复古胶片',
      'Vintage film',
      '复古胶片质感，温暖颗粒，高光轻微褪色，暗部微微提亮。',
      'Retro film look, warm grain, gently faded highlights and lifted blacks.',
    ),
    Template(
      '🌸',
      '日系清新',
      'Japanese fresh',
      '日系清新风格，明亮通透的曝光，柔和的马卡龙色调，低对比度，干净的白色。',
      'Japanese fresh style, bright airy exposure, soft pastel tones, low contrast, clean whites.',
    ),
    Template(
      '🌃',
      '赛博朋克',
      'Cyberpunk',
      '赛博朋克夜景，品红与青色霓虹光，深邃阴影，高对比度。',
      'Cyberpunk night look, neon magenta and cyan lighting, deep shadows, high contrast.',
    ),
    Template(
      '✨',
      '黑金夜景',
      'Black & gold',
      '黑金夜景质感，深邃的黑色，丰富的金色高光，奢华温暖的光晕。',
      'Black and gold night look, deep blacks, rich golden highlights, luxurious warm glow.',
    ),
    Template(
      '🎬',
      '电影青橙',
      'Teal & orange',
      '电影感青橙色调，高光偏暖、阴影偏青，对比适中，轻微颗粒。',
      'Cinematic teal-and-orange grade: warm highlights, teal shadows, moderate contrast, subtle grain.',
    ),
    Template(
      '🌿',
      '莫兰迪',
      'Morandi',
      '莫兰迪低饱和色调，灰调柔和，质感高级安静。',
      'Morandi palette: muted, dusty, low-saturation tones with a calm refined feel.',
    ),
    Template(
      '🍑',
      '奶油肌',
      'Creamy',
      '奶油色调，肤色细腻通透，柔光，暖白，轻盈的 ins 风。',
      'Creamy tones with smooth luminous skin, soft light, warm whites and an airy ins-style feel.',
    ),
    Template(
      '🌇',
      '黄昏暖光',
      'Golden hour',
      '黄昏金色逆光，暖橙色光晕，长长的柔和阴影，氛围浪漫。',
      'Golden-hour backlight, warm orange glow, long soft shadows, romantic mood.',
    ),
  ]),
  TemplateCategory('艺术风格', 'Art', [
    Template(
      '💧',
      '水彩画',
      'Watercolor',
      '转为水彩画风格，柔和晕染的色块，纸张纹理，保留主体与构图。',
      'Turn into a watercolor painting with soft washes, paper texture, keeping subject and composition.',
    ),
    Template(
      '🖼️',
      '油画',
      'Oil painting',
      '转为厚涂油画风格，可见笔触，丰富的色彩层次，保留主体与构图。',
      'Turn into an impasto oil painting with visible brushstrokes and rich color layers, keeping subject and composition.',
    ),
    Template(
      '🌈',
      '日漫',
      'Anime',
      '转为日本动漫风格，干净的线稿，明快的赛璐璐上色，保留人物特征。',
      'Turn into Japanese anime style with clean line art and bright cel shading, keeping the person recognizable.',
    ),
    Template(
      '🧸',
      '3D 卡通',
      '3D cartoon',
      '转为 3D 动画电影风格，圆润可爱的造型，细腻柔和的光影，保留人物特征。',
      'Turn into a 3D animated-film style with rounded cute forms and soft lighting, keeping the person recognizable.',
    ),
    Template(
      '✏️',
      '铅笔素描',
      'Pencil sketch',
      '转为铅笔素描，细腻排线与明暗层次，白色纸面。',
      'Turn into a pencil sketch with fine hatching and tonal shading on white paper.',
    ),
    Template(
      '👾',
      '像素风',
      'Pixel art',
      '转为复古像素画风格，有限色板，清晰的像素颗粒。',
      'Turn into retro pixel art with a limited palette and crisp pixels.',
    ),
  ]),
  TemplateCategory('风景', 'Landscape', [
    Template(
      '🌅',
      '日出日落',
      'Sunrise/sunset',
      '增强日出日落的天空：金橙渐变的云层，通透的光线，层次丰富，景物保持不变。',
      'Enhance the sunrise/sunset sky: golden-orange gradient clouds, luminous light and rich depth; keep the scene unchanged.',
    ),
    Template(
      '☁️',
      '蓝天白云',
      'Blue sky',
      '让天空更通透湛蓝，白云更有层次，整体清新明亮，地面景物自然不变。',
      'Make the sky a clearer deeper blue with defined white clouds, fresh and bright overall; keep the ground scene natural and unchanged.',
    ),
    Template(
      '🏔️',
      '山川云海',
      'Misty mountains',
      '突出山峦与云海的层次，薄雾缭绕，远景通透，冷暖光影对比自然。',
      'Emphasize layered mountains and a sea of clouds, drifting mist, clear distance and natural warm-cool light contrast.',
    ),
    Template(
      '🌲',
      '森林晨雾',
      'Forest mist',
      '清晨森林的薄雾与丁达尔光束，绿色清透，空气感强，景物保持不变。',
      'Morning forest with soft mist and light rays, fresh translucent greens and an airy feel; keep the scene unchanged.',
    ),
    Template(
      '🏞️',
      '湖面倒影',
      'Lake reflection',
      '增强湖面如镜的倒影，水面平静清澈，色彩饱满自然，构图不变。',
      'Enhance mirror-like lake reflections, calm clear water and rich natural color; keep the composition.',
    ),
    Template(
      '🌻',
      '花海',
      'Flower field',
      '让花田色彩更鲜艳饱满，明亮的阳光，通透的空气，保持真实自然。',
      'Make the flower field more vivid and saturated with bright sunlight and clear air, staying realistic.',
    ),
    Template(
      '🌌',
      '极光',
      'Aurora',
      '在夜空加入绿色与紫色的极光，星光点点，地面景物保持不变，光色协调。',
      'Add green and violet aurora to the night sky with scattered stars; keep the ground scene unchanged and the light consistent.',
    ),
    Template(
      '🌧️',
      '雨后清新',
      'After rain',
      '雨后清新氛围：路面与叶片湿润反光，空气通透，色彩饱和度略升，景物保持不变。',
      'After-rain mood: wet reflective ground and leaves, clear air, slightly richer color; keep the scene unchanged.',
    ),
  ]),
  TemplateCategory('人像', 'Portrait', [
    Template(
      '💆',
      '自然美颜',
      'Soft retouch',
      '自然的人像美颜：均匀肤色，轻度磨皮并保留皮肤纹理，提亮眼神，五官和脸型不变。',
      'Natural portrait retouch: even skin tone, light smoothing that keeps texture, brighter eyes. Do not alter facial features or face shape.',
    ),
    Template(
      '🪪',
      '证件照·蓝底',
      'ID photo, blue',
      '换成纯蓝色背景的证件照，人物居中，光线均匀，边缘干净，五官不变。',
      'Make an ID photo on a solid blue background, subject centered, even lighting, clean edges, unchanged facial features.',
    ),
    Template(
      '🪪',
      '证件照·白底',
      'ID photo, white',
      '换成纯白色背景的证件照，人物居中，光线均匀，边缘干净，五官不变。',
      'Make an ID photo on a solid white background, subject centered, even lighting, clean edges, unchanged facial features.',
    ),
    Template(
      '💼',
      '职业形象照',
      'Business headshot',
      '职业形象照：干净的浅灰渐变背景，专业柔和的影棚光，着装整洁，五官不变。',
      'Professional headshot: clean light-gray gradient backdrop, soft studio lighting, tidy attire, unchanged facial features.',
    ),
  ]),
  TemplateCategory('场景换景', 'Scenes', [
    Template(
      '🏖️',
      '海边',
      'Beach',
      '把背景换成阳光明媚的海滩，保留前景人物与光线协调，边缘自然。',
      'Replace the background with a sunny beach, keeping the foreground subject with matching light and natural edges.',
    ),
    Template(
      '🌌',
      '星空',
      'Starry sky',
      '把背景换成璀璨的银河星空，人物保持不变，整体光色协调。',
      'Replace the background with a brilliant Milky Way sky; keep the subject unchanged with matching color and light.',
    ),
    Template(
      '🌸',
      '樱花季',
      'Cherry blossom',
      '加入盛开的樱花与飘落花瓣，春日柔光，主体保持不变。',
      'Add blooming cherry trees and drifting petals in soft spring light; keep the subject unchanged.',
    ),
    Template(
      '🍂',
      '深秋',
      'Autumn',
      '转为深秋景色：金黄与橙红的落叶，温暖的光线，主体保持不变。',
      'Turn into deep autumn: golden and russet foliage, warm light; keep the subject unchanged.',
    ),
    Template(
      '❄️',
      '雪景',
      'Snow',
      '转为冬日雪景：地面与景物覆盖白雪，冷调柔光，主体保持不变。',
      'Turn into a winter snow scene: snow-covered ground and objects, cool soft light; keep the subject unchanged.',
    ),
    Template(
      '🌙',
      '白天变夜景',
      'Day to night',
      '把白天场景改为夜景：深蓝天空，灯光亮起，光影真实，构图不变。',
      'Turn this daytime scene into night: deep blue sky, lights glowing, realistic lighting, same composition.',
    ),
  ]),
];
