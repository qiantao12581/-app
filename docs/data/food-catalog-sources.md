# Food catalog source manifest

## Methodology

- Grain: one row is one nutritionally distinct generic food or one exact mainland-China product/menu specification.
- Source priority: China CDC Institute of Nutrition and Health / China Food Composition Table first; then exact mainland brand product pages or official product images; then official mainland menu nutrition pages.
- Energy: official kJ values are retained in each specification; catalog kcal is computed with 1 kcal = 4.184 kJ and is not rounded during conversion.
- Missingness: an unreported official calories/carbohydrates/protein/fat field is JSON null; the row is missingOfficialFields and is ineligible for complete-only recommendations.
- Chain variants: each McDonald's size/product is an independent official serving record. No small/medium/large multiplier is used. KFC contributes zero rows because a current exact mainland official nutrition source could not be retrieved; no third-party or overseas values were substituted.
- Current batch: 65 foods (65 China CDC generic, 0 mainland branded dairy, 0 McDonald's China, 0 KFC China).

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
| cfc-326 | 黄豆[大豆] | — | 中国食物成分表每100克可食部；原始能量1629kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/326.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-327 | 黑豆[黑大豆](干) | — | 中国食物成分表每100克可食部；原始能量1680kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/327.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-333 | 豆腐(均值) | — | 中国食物成分表每100克可食部；原始能量342kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/333.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-334 | 豆腐(北) | — | 中国食物成分表每100克可食部；原始能量415kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/334.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-335 | 豆腐(南)[南豆腐] | — | 中国食物成分表每100克可食部；原始能量240kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/335.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-336 | 豆腐(内酯) | — | 中国食物成分表每100克可食部；原始能量208kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/336.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-338 | 豆浆 | — | 中国食物成分表每100克可食部；原始能量65kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/338.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-342 | 豆腐皮 | — | 中国食物成分表每100克可食部；原始能量1720kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/342.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-344 | 腐竹 | — | 中国食物成分表每100克可食部；原始能量1931kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/344.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-350 | 绿豆(干) | — | 中国食物成分表每100克可食部；原始能量1393kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/350.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-779 | 猪肉(肥瘦)(均值) | — | 中国食物成分表每100克可食部；原始能量1634kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/779.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-784 | 猪肉(里脊) | — | 中国食物成分表每100克可食部；原始能量648kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/784.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-788 | 猪肉(瘦) | — | 中国食物成分表每100克可食部；原始能量600kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/788.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-789 | 猪肉(腿) | — | 中国食物成分表每100克可食部；原始能量792kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/789.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-823 | 牛肉(肥瘦)(均值) | — | 中国食物成分表每100克可食部；原始能量528kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/823.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-827 | 牛肉(里脊) | — | 中国食物成分表每100克可食部；原始能量451kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/827.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-830 | 牛肉(瘦) | — | 中国食物成分表每100克可食部；原始能量449kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/830.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-844 | 羊肉(肥瘦)(均值) | — | 中国食物成分表每100克可食部；原始能量845kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/844.html> | 2026-07-12T00:00:00Z | missingOfficialFields | protein |
| cfc-847 | 羊肉(里脊) | — | 中国食物成分表每100克可食部；原始能量435kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/847.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-850 | 羊肉(瘦) | — | 中国食物成分表每100克可食部；原始能量496kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/850.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-875 | 兔肉 | — | 中国食物成分表每100克可食部；原始能量432kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/875.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-876 | 鸡(均值) | — | 中国食物成分表每100克可食部；原始能量698kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/876.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-880 | 鸡胸脯肉 | — | 中国食物成分表每100克可食部；原始能量557kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/880.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-881 | 鸡翅 | — | 中国食物成分表每100克可食部；原始能量811kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/881.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-882 | 鸡腿 | — | 中国食物成分表每100克可食部；原始能量753kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/882.html> | 2026-07-12T00:00:00Z | missingOfficialFields | protein |
| cfc-891 | 鸭(均值) | — | 中国食物成分表每100克可食部；原始能量996kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/891.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-892 | 鸭胸脯肉 | — | 中国食物成分表每100克可食部；原始能量379kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/892.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-978 | 蛋（鸡蛋，均值) | — | 中国食物成分表每100克可食部；原始能量599kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/978.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-982 | 鸡蛋白 | — | 中国食物成分表每100克可食部；原始能量254kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/982.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-990 | 蛋（鸭蛋） | — | 中国食物成分表每100克可食部；原始能量748kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/990.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-1003 | 草鱼[白鲩，草包鱼] | — | 中国食物成分表每100克可食部；原始能量475kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/1003.html> | 2026-07-12T00:00:00Z | missingOfficialFields | protein |
| cfc-1012 | 鲤鱼[鲤拐子] | — | 中国食物成分表每100克可食部；原始能量459kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/1012.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-1013 | 罗非鱼 | — | 中国食物成分表每100克可食部；原始能量416kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/1013.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-1021 | 鲫鱼[喜头鱼，海附鱼] | — | 中国食物成分表每100克可食部；原始能量455kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/1021.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-1023 | 鳊鱼[鲂鱼，武昌鱼] | — | 中国食物成分表每100克可食部；原始能量565kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/1023.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-1025 | 鳙鱼[胖头鱼，摆佳鱼，花鲢鱼] | — | 中国食物成分表每100克可食部；原始能量421kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/1025.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-1030 | 带鱼[白带鱼，刀鱼] | — | 中国食物成分表每100克可食部；原始能量535kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/1030.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-1037 | 黄鱼(大黄花鱼) | — | 中国食物成分表每100克可食部；原始能量407kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/1037.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-1038 | 黄鱼(小黄花鱼) | — | 中国食物成分表每100克可食部；原始能量417kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/1038.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-1050 | 鲈鱼[鲈花] | — | 中国食物成分表每100克可食部；原始能量442kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/1050.html> | 2026-07-12T00:00:00Z | missingOfficialFields | protein |
| cfc-1062 | 鳕鱼[鳕狭，明太鱼] | — | 中国食物成分表每100克可食部；原始能量374kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/1062.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-1091 | 虾（海虾） | — | 中国食物成分表每100克可食部；原始能量333kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/1091.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-1092 | 虾（河虾） | — | 中国食物成分表每100克可食部；原始能量368kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/1092.html> | 2026-07-12T00:00:00Z | missingOfficialFields | protein |
| cfc-1103 | 蟹（河蟹） | — | 中国食物成分表每100克可食部；原始能量433kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/1103.html> | 2026-07-12T00:00:00Z | complete | protein |
| cfc-1114 | 扇贝(鲜) | — | 中国食物成分表每100克可食部；原始能量255kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/1114.html> | 2026-07-12T00:00:00Z | complete | protein |
