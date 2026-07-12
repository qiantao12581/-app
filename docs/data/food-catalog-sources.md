# Food catalog source manifest

## Methodology

- Grain: one row is one nutritionally distinct generic food or one exact mainland-China product/menu specification.
- Source priority: China CDC Institute of Nutrition and Health / China Food Composition Table first; then exact mainland brand product pages or official product images; then official mainland menu nutrition pages.
- Energy: official kJ values are retained in each specification; catalog kcal is computed with 1 kcal = 4.184 kJ and is not rounded during conversion.
- Missingness: an unreported official calories/carbohydrates/protein/fat field is JSON null; the row is missingOfficialFields and is ineligible for complete-only recommendations.
- Chain variants: each McDonald's size/product is an independent official serving record. No small/medium/large multiplier is used. KFC contributes zero rows because a current exact mainland official nutrition source could not be retrieved; no third-party or overseas values were substituted.
- Current batch: 135 foods (115 China CDC generic, 20 mainland branded dairy, 0 McDonald's China, 0 KFC China).

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
| cfc-916 | 乳品（牛乳，均值) | — | 中国食物成分表每100克可食部；原始能量227kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/916.html> | 2026-07-12T00:00:00Z | complete | dairy |
| cfc-934 | 乳品（鲜羊乳） | — | 中国食物成分表每100克可食部；原始能量247kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/934.html> | 2026-07-12T00:00:00Z | complete | dairy |
| cfc-958 | 乳品（酸奶，均值) | — | 中国食物成分表每100克可食部；原始能量301kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/958.html> | 2026-07-12T00:00:00Z | complete | dairy |
| cfc-959 | 酸奶(脱脂) | — | 中国食物成分表每100克可食部；原始能量241kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/959.html> | 2026-07-12T00:00:00Z | complete | dairy |
| cfc-962 | 奶酪[干酪] | — | 中国食物成分表每100克可食部；原始能量1366kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/962.html> | 2026-07-12T00:00:00Z | complete | dairy |
| cfc-371 | 白萝卜[莱菔](鲜) | — | 中国食物成分表每100克可食部；原始能量95kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/371.html> | 2026-07-12T00:00:00Z | complete | vegetable |
| cfc-380 | 胡萝卜(红)[金笋，丁香萝卜] | — | 中国食物成分表每100克可食部；原始能量164kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/380.html> | 2026-07-12T00:00:00Z | complete | vegetable |
| cfc-387 | 豆角 | — | 中国食物成分表每100克可食部；原始能量145kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/387.html> | 2026-07-12T00:00:00Z | complete | vegetable |
| cfc-391 | 毛豆[青豆，菜用大豆](鲜) | — | 中国食物成分表每100克可食部；原始能量550kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/391.html> | 2026-07-12T00:00:00Z | complete | vegetable |
| cfc-399 | 黄豆芽 | — | 中国食物成分表每100克可食部；原始能量199kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/399.html> | 2026-07-12T00:00:00Z | complete | vegetable |
| cfc-400 | 绿豆芽 | — | 中国食物成分表每100克可食部；原始能量82kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/400.html> | 2026-07-12T00:00:00Z | complete | vegetable |
| cfc-402 | 茄子(均值) | — | 中国食物成分表每100克可食部；原始能量98kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/402.html> | 2026-07-12T00:00:00Z | complete | vegetable |
| cfc-405 | 番茄[西红柿] | — | 中国食物成分表每100克可食部；原始能量86kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/405.html> | 2026-07-12T00:00:00Z | complete | vegetable |
| cfc-409 | 辣椒(青，尖) | — | 中国食物成分表每100克可食部；原始能量115kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/409.html> | 2026-07-12T00:00:00Z | complete | vegetable |
| cfc-410 | 甜椒[灯笼椒，柿子椒] | — | 中国食物成分表每100克可食部；原始能量104kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/410.html> | 2026-07-12T00:00:00Z | complete | vegetable |
| cfc-419 | 冬瓜 | — | 中国食物成分表每100克可食部；原始能量52kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/419.html> | 2026-07-12T00:00:00Z | complete | vegetable |
| cfc-422 | 黄瓜[胡瓜](鲜) | — | 中国食物成分表每100克可食部；原始能量66kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/422.html> | 2026-07-12T00:00:00Z | complete | vegetable |
| cfc-425 | 苦瓜[凉瓜，癞瓜](鲜) | — | 中国食物成分表每100克可食部；原始能量91kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/425.html> | 2026-07-12T00:00:00Z | complete | vegetable |
| cfc-426 | 南瓜[倭瓜，番瓜](鲜) | — | 中国食物成分表每100克可食部；原始能量99kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/426.html> | 2026-07-12T00:00:00Z | complete | vegetable |
| cfc-429 | 丝瓜 | — | 中国食物成分表每100克可食部；原始能量90kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/429.html> | 2026-07-12T00:00:00Z | complete | vegetable |
| cfc-436 | 大蒜[蒜头](鲜) | — | 中国食物成分表每100克可食部；原始能量543kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/436.html> | 2026-07-12T00:00:00Z | complete | vegetable |
| cfc-444 | 洋葱[葱头](鲜) | — | 中国食物成分表每100克可食部；原始能量171kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/444.html> | 2026-07-12T00:00:00Z | complete | vegetable |
| cfc-450 | 大白菜(均值) | — | 中国食物成分表每100克可食部；原始能量76kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/450.html> | 2026-07-12T00:00:00Z | complete | vegetable |
| cfc-465 | 西兰花[绿菜花] | — | 中国食物成分表每100克可食部；原始能量151kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/465.html> | 2026-07-12T00:00:00Z | complete | vegetable |
| cfc-473 | 菠菜[赤根菜](鲜) | — | 中国食物成分表每100克可食部；原始能量116kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/473.html> | 2026-07-12T00:00:00Z | complete | vegetable |
| cfc-613 | 苹果(均值) | — | 中国食物成分表每100克可食部；原始能量229kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/613.html> | 2026-07-12T00:00:00Z | complete | fruit |
| cfc-630 | 梨(均值) | — | 中国食物成分表每100克可食部；原始能量212kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/630.html> | 2026-07-12T00:00:00Z | complete | fruit |
| cfc-660 | 桃(均值) | — | 中国食物成分表每100克可食部；原始能量215kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/660.html> | 2026-07-12T00:00:00Z | complete | fruit |
| cfc-666 | 李子 | — | 中国食物成分表每100克可食部；原始能量159kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/666.html> | 2026-07-12T00:00:00Z | complete | fruit |
| cfc-674 | 枣(鲜) | — | 中国食物成分表每100克可食部；原始能量531kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/674.html> | 2026-07-12T00:00:00Z | complete | fruit |
| cfc-684 | 葡萄(均值) | — | 中国食物成分表每100克可食部；原始能量187kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/684.html> | 2026-07-12T00:00:00Z | complete | fruit |
| cfc-690 | 石榴(均值) | — | 中国食物成分表每100克可食部；原始能量306kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/690.html> | 2026-07-12T00:00:00Z | complete | fruit |
| cfc-700 | 中华猕猴桃[毛叶猕猴桃] | — | 中国食物成分表每100克可食部；原始能量259kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/700.html> | 2026-07-12T00:00:00Z | complete | fruit |
| cfc-701 | 草莓[洋莓，凤阳草莓] | — | 中国食物成分表每100克可食部；原始能量135kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/701.html> | 2026-07-12T00:00:00Z | complete | fruit |
| cfc-704 | 橙 | — | 中国食物成分表每100克可食部；原始能量204kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/704.html> | 2026-07-12T00:00:00Z | complete | fruit |
| cfc-705 | 柑桔(均值) | — | 中国食物成分表每100克可食部；原始能量218kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/705.html> | 2026-07-12T00:00:00Z | complete | fruit |
| cfc-716 | 菠萝[凤梨，地菠萝] | — | 中国食物成分表每100克可食部；原始能量184kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/716.html> | 2026-07-12T00:00:00Z | complete | fruit |
| cfc-723 | 芒果[抹猛果，望果] | — | 中国食物成分表每100克可食部；原始能量147kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/723.html> | 2026-07-12T00:00:00Z | complete | fruit |
| cfc-726 | 香蕉[甘蕉] | — | 中国食物成分表每100克可食部；原始能量394kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/726.html> | 2026-07-12T00:00:00Z | complete | fruit |
| cfc-739 | 西瓜(均值) | — | 中国食物成分表每100克可食部；原始能量110kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/739.html> | 2026-07-12T00:00:00Z | complete | fruit |
| cfc-743 | 核桃(干)[胡桃] | — | 中国食物成分表每100克可食部；原始能量2668kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/743.html> | 2026-07-12T00:00:00Z | complete | snack |
| cfc-746 | 栗子(鲜)[板栗] | — | 中国食物成分表每100克可食部；原始能量799kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/746.html> | 2026-07-12T00:00:00Z | complete | snack |
| cfc-750 | 松子(炒) | — | 中国食物成分表每100克可食部；原始能量2656kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/750.html> | 2026-07-12T00:00:00Z | complete | snack |
| cfc-756 | 腰果 | — | 中国食物成分表每100克可食部；原始能量2327kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/756.html> | 2026-07-12T00:00:00Z | complete | snack |
| cfc-759 | 开心果(熟) | — | 中国食物成分表每100克可食部；原始能量2610kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/759.html> | 2026-07-12T00:00:00Z | complete | snack |
| cfc-761 | 花生(鲜)[落花生，长生果] | — | 中国食物成分表每100克可食部；原始能量1296kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/761.html> | 2026-07-12T00:00:00Z | complete | snack |
| cfc-762 | 花生(炒) | — | 中国食物成分表每100克可食部；原始能量2493kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/762.html> | 2026-07-12T00:00:00Z | complete | snack |
| cfc-765 | 葵花子(生) | — | 中国食物成分表每100克可食部；原始能量2522kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/765.html> | 2026-07-12T00:00:00Z | complete | snack |
| cfc-769 | 南瓜子(炒)[白瓜子] | — | 中国食物成分表每100克可食部；原始能量2415kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/769.html> | 2026-07-12T00:00:00Z | complete | snack |
| cfc-773 | 芝麻籽(白) | — | 中国食物成分表每100克可食部；原始能量2225kJ，按1 kcal = 4.184 kJ换算 | chinaFoodComposition | <https://nlc.chinanutri.cn/fq/foodinfo/773.html> | 2026-07-12T00:00:00Z | complete | snack |
| mengniu-telunsu-organic-38 | 特仑苏有机纯牛奶（梦幻盖，3.8g蛋白） | 特仑苏 | 250mL/盒；官网产品图标示3.8g蛋白质/100mL | brandWebsite | <https://img.mengniu.com.cn/Uploads/Mnnew/Picture/2023/09/15/s650424095cdac.png> | 2026-07-12T00:00:00Z | missingOfficialFields | dairy |
| mengniu-telunsu-desert-organic | 特仑苏沙漠有机纯牛奶 | 特仑苏 | 250mL/盒；官网产品图标示4.0g蛋白质/100mL | brandWebsite | <https://img.mengniu.com.cn/Uploads/Mnnew/Picture/2023/09/15/s65042414f2ed5.png> | 2026-07-12T00:00:00Z | missingOfficialFields | dairy |
| mengniu-telunsu-organic-36 | 特仑苏有机纯牛奶（苗条砖，3.6g蛋白） | 特仑苏 | 250mL/盒；官网产品图标示3.6g蛋白质/100mL | brandWebsite | <https://img.mengniu.com.cn/Uploads/Mnnew/Picture/2023/09/15/s6504241c771be.png> | 2026-07-12T00:00:00Z | missingOfficialFields | dairy |
| mengniu-milk-supreme-6 | 奶爵6特乳优蛋白牛奶 | 奶爵6特乳 | 250mL/盒；官网当前官方产品图 | brandWebsite | <https://img.mengniu.com.cn/Uploads/Mnnew/Picture/2023/09/15/s65042442b8da5.png> | 2026-07-12T00:00:00Z | missingOfficialFields | dairy |
| mengniu-telunsu-hi-milk-skim | 特仑苏嗨Milk 0脂肪纯牛奶 | 特仑苏 | 250mL/盒；官网产品图明确标示0脂肪 | brandWebsite | <https://img.mengniu.com.cn/Uploads/Mnnew/Picture/2023/09/15/s6504245114c3c.png> | 2026-07-12T00:00:00Z | missingOfficialFields | dairy |
| mengniu-telunsu-grain-milk | 特仑苏谷粒牛奶 | 特仑苏 | 250mL/盒；官网当前官方产品图 | brandWebsite | <https://img.mengniu.com.cn/Uploads/Mnnew/Picture/2023/09/15/s6504245bd90c7.png> | 2026-07-12T00:00:00Z | missingOfficialFields | dairy |
| mengniu-telunsu-cbp-calcium | 特仑苏CBP高钙牛奶 | 特仑苏 | 250mL/盒；官网产品图标示135mg钙/100mL | brandWebsite | <https://img.mengniu.com.cn/Uploads/Mnnew/Picture/2023/09/15/s650424626a9a6.png> | 2026-07-12T00:00:00Z | missingOfficialFields | dairy |
| mengniu-telunsu-pure-36 | 特仑苏纯牛奶（3.6g蛋白） | 特仑苏 | 250mL/盒；官网产品图标示3.6g蛋白质/100mL | brandWebsite | <https://img.mengniu.com.cn/Uploads/Mnnew/Picture/2023/09/15/s65042469a158f.png> | 2026-07-12T00:00:00Z | missingOfficialFields | dairy |
| mengniu-telunsu-pure-38 | 特仑苏纯牛奶（3.8g蛋白） | 特仑苏 | 250mL/盒；官网产品图标示3.8g蛋白质/100mL | brandWebsite | <https://img.mengniu.com.cn/Uploads/Mnnew/Picture/2023/09/15/s6504246fd5a52.png> | 2026-07-12T00:00:00Z | missingOfficialFields | dairy |
| mengniu-telunsu-low-fat | 特仑苏低脂纯牛奶 | 特仑苏 | 250mL/盒；官网产品图明确标示低脂及脂肪减少60% | brandWebsite | <https://img.mengniu.com.cn/Uploads/Mnnew/Picture/2023/09/15/s6504247b92c18.png> | 2026-07-12T00:00:00Z | missingOfficialFields | dairy |
| mengniu-telunsu-mplus | 特仑苏M-PLUS高蛋白牛奶 | 特仑苏 | 250mL/盒；官网产品图标示5.2g蛋白质/100mL | brandWebsite | <https://img.mengniu.com.cn/Uploads/Mnnew/Picture/2023/09/15/s65042482e617c.png> | 2026-07-12T00:00:00Z | missingOfficialFields | dairy |
| yili-satine-pure-cap-38 | 金典纯奶梦幻盖 | 金典 | 官网当前产品名；每100mL标示3.8g蛋白质、125mg钙；官网未列单盒容量 | brandWebsite | <https://www.yili.com/product/1155> | 2026-07-12T00:00:00Z | missingOfficialFields | dairy |
| yili-satine-jersey-organic | 金典娟姗有机纯牛奶 | 金典 | 官网当前产品名；每100mL标示4.0g蛋白质；官网未列单盒容量 | brandWebsite | <https://www.yili.com/product/1155> | 2026-07-12T00:00:00Z | missingOfficialFields | dairy |
| yili-satine-organic-cap | 金典有机纯牛奶（梦幻盖） | 金典 | 官网当前产品名；每100mL标示3.8g蛋白质、125mg钙；官网未列单盒容量 | brandWebsite | <https://www.yili.com/product/1155> | 2026-07-12T00:00:00Z | missingOfficialFields | dairy |
| yili-satine-a2-organic | 金典A2β-酪蛋白有机纯牛奶 | 金典 | 官网当前产品名；每100mL标示3.8g蛋白质、125mg钙；官网未列单盒容量 | brandWebsite | <https://www.yili.com/product/1155> | 2026-07-12T00:00:00Z | missingOfficialFields | dairy |
| yili-satine-organic-slim | 金典有机纯牛奶（苗条砖） | 金典 | 官网当前产品名；每100mL标示3.6g蛋白质、120mg钙；官网未列单盒容量 | brandWebsite | <https://www.yili.com/product/1155> | 2026-07-12T00:00:00Z | missingOfficialFields | dairy |
| yili-satine-organic-skim | 金典有机脱脂纯牛奶 | 金典 | 官网当前产品名；每100mL标示3.8g蛋白质并明确0脂肪；官网未列单盒容量 | brandWebsite | <https://www.yili.com/product/1155> | 2026-07-12T00:00:00Z | missingOfficialFields | dairy |
| yili-satine-organic-200 | 金典200mL有机纯牛奶 | 金典 | 200mL/盒；官网产品名标示容量及3.6g蛋白质/100mL | brandWebsite | <https://www.yili.com/product/1155> | 2026-07-12T00:00:00Z | missingOfficialFields | dairy |
| yili-satine-high-calcium-low-fat | 金典高钙低脂纯牛奶 | 金典 | 官网当前产品名；每100mL标示3.6g蛋白质、120mg钙并称脂肪减少50%；官网未列单盒容量 | brandWebsite | <https://www.yili.com/product/1155> | 2026-07-12T00:00:00Z | missingOfficialFields | dairy |
| yili-satine-pure-200 | 金典200mL纯牛奶 | 金典 | 200mL/盒；官网产品名标示容量及3.6g蛋白质/100mL | brandWebsite | <https://www.yili.com/product/1155> | 2026-07-12T00:00:00Z | missingOfficialFields | dairy |
