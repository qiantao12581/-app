# Food catalog source manifest

## Methodology

- Grain: one row is one nutritionally distinct generic food or one exact mainland-China product/menu specification.
- Source priority: China CDC Institute of Nutrition and Health / China Food Composition Table first; then exact mainland brand product pages or official product images; then official mainland menu nutrition pages.
- Energy: official kJ values are retained in each specification; catalog kcal is computed with 1 kcal = 4.184 kJ and is not rounded during conversion.
- Missingness: an unreported official calories/carbohydrates/protein/fat field is JSON null; the row is missingOfficialFields and is ineligible for complete-only recommendations.
- Chain variants: each McDonald's size/product is an independent official serving record. No small/medium/large multiplier is used. KFC contributes zero rows because a current exact mainland official nutrition source could not be retrieved; no third-party or overseas values were substituted.
- Current batch: 20 foods (20 China CDC generic, 0 mainland branded dairy, 0 McDonald's China, 0 KFC China).

## Sources

| ID | Chinese name | brand | official specification | source type | official URL | verified date | completeness | catalog category |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| cfc-259 | 小麦粉(标准粉) | — | 中国食物成分表每100克可食部；原始能量1478kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/259.html> | 2026-07-12T00:00:00Z | complete | staple |
| cfc-261 | 挂面(均值) | — | 中国食物成分表每100克可食部；原始能量1476kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/261.html> | 2026-07-12T00:00:00Z | complete | staple |
| cfc-264 | 面条(均值) | — | 中国食物成分表每100克可食部；原始能量1212kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/264.html> | 2026-07-12T00:00:00Z | complete | staple |
| cfc-269 | 花卷 | — | 中国食物成分表每100克可食部；原始能量908kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/269.html> | 2026-07-12T00:00:00Z | complete | staple |
| cfc-272 | 馒头(均值) | — | 中国食物成分表每100克可食部；原始能量947kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/272.html> | 2026-07-12T00:00:00Z | complete | staple |
| cfc-280 | 稻米(均值) | — | 中国食物成分表每100克可食部；原始能量1473kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/280.html> | 2026-07-12T00:00:00Z | complete | staple |
| cfc-283 | 香大米 | — | 中国食物成分表每100克可食部；原始能量1475kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/283.html> | 2026-07-12T00:00:00Z | complete | staple |
| cfc-285 | 糯米[江米](均值) | — | 中国食物成分表每100克可食部；原始能量1485kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/285.html> | 2026-07-12T00:00:00Z | complete | staple |
| cfc-287 | 米饭(蒸)(均值) | — | 中国食物成分表每100克可食部；原始能量493kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/287.html> | 2026-07-12T00:00:00Z | complete | staple |
| cfc-288 | 粳米粥 | — | 中国食物成分表每100克可食部；原始能量197kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/288.html> | 2026-07-12T00:00:00Z | complete | staple |
| cfc-289 | 籼米粉[排米粉] | — | 中国食物成分表每100克可食部；原始能量1512kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/289.html> | 2026-07-12T00:00:00Z | complete | staple |
| cfc-292 | 玉米(鲜) | — | 中国食物成分表每100克可食部；原始能量474kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/292.html> | 2026-07-12T00:00:00Z | complete | staple |
| cfc-295 | 玉米面(白) | — | 中国食物成分表每100克可食部；原始能量1489kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/295.html> | 2026-07-12T00:00:00Z | complete | staple |
| cfc-296 | 玉米面(黄) | — | 中国食物成分表每100克可食部；原始能量1488kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/296.html> | 2026-07-12T00:00:00Z | complete | staple |
| cfc-301 | 小米 | — | 中国食物成分表每100克可食部；原始能量1530kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/301.html> | 2026-07-12T00:00:00Z | complete | staple |
| cfc-303 | 小米粥 | — | 中国食物成分表每100克可食部；原始能量193kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/303.html> | 2026-07-12T00:00:00Z | complete | staple |
| cfc-309 | 荞麦 | — | 中国食物成分表每100克可食部；原始能量1426kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/309.html> | 2026-07-12T00:00:00Z | complete | staple |
| cfc-311 | 薏米[薏仁米，苡米] | — | 中国食物成分表每100克可食部；原始能量1530kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/311.html> | 2026-07-12T00:00:00Z | complete | staple |
| cfc-313 | 马铃薯[土豆，洋芋] | — | 中国食物成分表每100克可食部；原始能量328kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/313.html> | 2026-07-12T00:00:00Z | complete | staple |
| cfc-316 | 甘薯(红心)[山芋，红薯] | — | 中国食物成分表每100克可食部；原始能量432kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/316.html> | 2026-07-12T00:00:00Z | complete | staple |
