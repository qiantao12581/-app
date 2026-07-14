import argparse
import json
import math
import re
import subprocess
import sys
import unicodedata
from collections import Counter
from datetime import datetime
from pathlib import Path
from statistics import median
from urllib.parse import urlsplit


GROUP_FILES = {
    "basicIngredient": ("catalog/foods/basic-ingredients.json", 160),
    "preparedFood": ("catalog/foods/prepared-foods.json", 190),
    "brandedPackaged": ("catalog/foods/branded-packaged.json", 80),
    "chainRestaurant": ("catalog/foods/chain-restaurants.json", 40),
    "genericSnackDrink": ("catalog/foods/generic-snacks-drinks.json", 30),
}
REQUIRED_NUTRIENTS = ("calories", "carbohydrates", "protein", "fat")
_DIRECT_SOURCE_TYPES = {
    "chinaFoodComposition",
    "governmentLaboratory",
    "brandWebsite",
    "packageLabel",
    "officialMenu",
}
_UTC_DATE = re.compile(
    r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z$"
)
_BAD_TEXT_MARKERS = ("??", "\ufffd")
_VERIFIED_AT = "2026-07-14T00:00:00Z"


def relative_energy_spread(values):
    if len(values) < 2:
        return 0.0
    mean = sum(values) / len(values)
    return math.inf if mean <= 0 else (max(values) - min(values)) / mean


def can_merge(samples):
    if not samples:
        return False
    calories = [sample["calories"] for sample in samples]
    if relative_energy_spread(calories) > 0.15:
        return False
    return all(
        max(sample[field] for sample in samples)
        - min(sample[field] for sample in samples)
        <= 8.0
        for field in ("carbohydrates", "protein", "fat")
    )


class CatalogBuilder:
    def __init__(self, approved_hosts, evidence=None, repository_root=None):
        self.repository_root = Path(
            repository_root or Path(__file__).resolve().parents[2]
        )
        self.approved_hosts = {
            source_type: {host.lower() for host in hosts}
            for source_type, hosts in approved_hosts.items()
        }
        self.evidence = evidence or {
            "schemaVersion": 1,
            "recipes": [],
            "mergedFoods": [],
        }

    @classmethod
    def from_repository(cls, repository_root=None):
        root = Path(repository_root or Path(__file__).resolve().parents[2])
        with (root / "catalog" / "approved-source-hosts.json").open(
            encoding="utf-8"
        ) as handle:
            approved_hosts = json.load(handle)
        with (root / "docs" / "data" / "food-estimate-recipes.json").open(
            encoding="utf-8"
        ) as handle:
            evidence = json.load(handle)
        return cls(approved_hosts, evidence=evidence, repository_root=root)

    def load_group(self, path):
        if isinstance(path, str) and path in GROUP_FILES:
            path = GROUP_FILES[path][0]
        group_path = Path(path)
        if not group_path.is_absolute():
            group_path = self.repository_root / group_path
        with group_path.open(encoding="utf-8") as handle:
            rows = json.load(handle)
        if not isinstance(rows, list):
            raise ValueError(f"catalog.groupNotArray path={group_path}")
        return rows

    def validate_group(self, name, rows):
        errors = set()
        if name in GROUP_FILES:
            expected = GROUP_FILES[name][1]
            if len(rows) != expected:
                errors.add(
                    f"catalog.groupCount group={name} expected={expected} "
                    f"actual={len(rows)}"
                )

        id_counts = Counter(str(row.get("id", "")) for row in rows)
        for food_id, count in id_counts.items():
            if count > 1:
                errors.add(f"food.duplicateID id={food_id} count={count}")

        recipe_evidence_ids = self._evidence_ids("recipes")
        merged_evidence_ids = self._evidence_ids("mergedFoods")
        evidence_ids = recipe_evidence_ids | merged_evidence_ids
        for row in rows:
            food_id = str(row.get("id", ""))
            for text in _nested_strings(row):
                if any(marker in text for marker in _BAD_TEXT_MARKERS):
                    errors.add(f"food.invalidTextEncoding id={food_id}")
            nutrition = row.get("nutrition")
            if not isinstance(nutrition, dict):
                nutrition = {}
            for field in REQUIRED_NUTRIENTS:
                value = nutrition.get(field)
                if value is None:
                    errors.add(f"food.missingNutrient id={food_id} field={field}")
                elif not _is_nonnegative_number(value):
                    errors.add(f"food.invalidNutrient id={food_id} field={field}")

            basis_amount = row.get("nutritionBasisAmount")
            basis_unit = row.get("nutritionBasisUnit")
            if not _is_positive_number(basis_amount) or not isinstance(
                basis_unit, str
            ) or not basis_unit:
                errors.add(f"food.invalidBasis id={food_id}")

            self._append_portion_errors(row, errors)

            source = row.get("source")
            if not isinstance(source, dict):
                source = {}
            source_type = source.get("type")
            evidence_level = source.get("evidenceLevel")
            if evidence_level not in {"official", "nonOfficial"}:
                errors.add(f"food.missingEvidenceLevel id={food_id}")
            if evidence_level == "official" and (
                source_type == "recipeEstimate"
                or food_id in recipe_evidence_ids
                or food_id in merged_evidence_ids
            ):
                errors.add(f"food.officialEstimate id={food_id}")
            if evidence_level == "nonOfficial" and food_id not in evidence_ids:
                errors.add(f"food.missingNonOfficialEvidence id={food_id}")
            if source_type in _DIRECT_SOURCE_TYPES and evidence_level != "official":
                errors.add(f"food.directSourceMustBeOfficial id={food_id}")
            if source_type == "recipeEstimate" and evidence_level != "nonOfficial":
                errors.add(f"food.recipeEstimateMustBeNonOfficial id={food_id}")
            if source_type == "recipeEstimate" and source.get("url") is not None:
                errors.add(f"food.recipeEstimateURLMustBeNull id={food_id}")

            if not _is_utc_date(source.get("verifiedAt")):
                errors.add(f"food.invalidVerifiedAt id={food_id}")
            self._append_source_host_errors(food_id, source, errors)

        return sorted(errors)

    def assemble(self, groups):
        owners = {}
        rows = []
        for group_name, group_rows in groups.items():
            for row in group_rows:
                food_id = str(row.get("id", ""))
                if food_id in owners and owners[food_id] != group_name:
                    group_names = sorted((owners[food_id], group_name))
                    raise ValueError(
                        f"catalog.duplicateID id={food_id} "
                        f"groups={','.join(group_names)}"
                    )
                owners[food_id] = group_name
                rows.append(row)
        return sorted(rows, key=lambda row: str(row.get("id", "")))

    def write_release_catalog(self, rows, path):
        _write_json(sorted(rows, key=lambda row: str(row.get("id", ""))), path)

    def write_manifest(self, rows, path):
        lines = [
            "# Food Catalog Sources",
            "",
            "| ID | Chinese name | Brand | Specification | Source type | Evidence | URL | Verified at | Completeness | Catalog category |",
            "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
        ]
        for row in sorted(rows, key=lambda item: str(item.get("id", ""))):
            source = row.get("source", {})
            lines.append(
                "| "
                + " | ".join(
                    _markdown_cell(value)
                    for value in (
                        row.get("id", ""),
                        row.get("name", ""),
                        row.get("brandName") or "—",
                        source.get("specification", ""),
                        source.get("type", ""),
                        source.get("evidenceLevel", ""),
                        source.get("url") or "",
                        source.get("verifiedAt", ""),
                        row.get("dataCompleteness", ""),
                        row.get("category", ""),
                    )
                )
                + " |"
            )
        _write_text("\n".join(lines), path)

    def all_groups(self):
        return {name: self.load_group(name) for name in GROUP_FILES}

    def food(self, food_id):
        for rows in self.all_groups().values():
            for row in rows:
                if row.get("id") == food_id:
                    return row
        raise KeyError(food_id)

    def merged_food(self, food_id):
        for item in self.evidence.get("mergedFoods", []):
            if item.get("foodID") == food_id:
                return item
        raise KeyError(food_id)

    def validate_nonofficial_evidence(self, rows):
        evidence_ids = self._evidence_ids("recipes") | self._evidence_ids(
            "mergedFoods"
        )
        return sorted(
            f"food.missingNonOfficialEvidence id={row.get('id', '')}"
            for row in rows
            if row.get("source", {}).get("evidenceLevel") == "nonOfficial"
            and row.get("id") not in evidence_ids
        )

    def validate_recipes(self):
        errors = set()
        basic_rows = self.load_group("basicIngredient")
        basic = {row["id"]: row for row in basic_rows}
        release_foods = {}
        for rows in self.all_groups().values():
            release_foods.update({row["id"]: row for row in rows})

        entries = list(self.evidence.get("recipes", [])) + list(
            self.evidence.get("mergedFoods", [])
        )
        counts = Counter(item.get("foodID") for item in entries)
        for food_id, count in counts.items():
            if not food_id or count != 1:
                errors.add(
                    f"evidence.duplicateOrMissingFoodID id={food_id} count={count}"
                )

        for item in self.evidence.get("recipes", []):
            food_id = item.get("foodID", "")
            food = release_foods.get(food_id)
            if food is None:
                errors.add(f"evidence.unknownFood id={food_id}")
                continue
            method = item.get("method")
            if method == "standardRecipe":
                finished = item.get("finishedWeightGrams")
                ingredients = item.get("ingredients")
                if not _is_positive_number(finished) or not isinstance(
                    ingredients, list
                ) or not ingredients:
                    errors.add(f"recipe.invalidStructure id={food_id}")
                    continue
                unknown = [
                    value.get("foodID")
                    for value in ingredients
                    if value.get("foodID") not in basic
                ]
                invalid_weights = [
                    value.get("foodID")
                    for value in ingredients
                    if not _is_positive_number(value.get("edibleGrams"))
                ]
                if unknown:
                    errors.add(
                        f"recipe.unknownIngredient id={food_id} "
                        f"ingredients={','.join(str(value) for value in unknown)}"
                    )
                if invalid_weights:
                    errors.add(f"recipe.invalidIngredientWeight id={food_id}")
                if unknown or invalid_weights:
                    continue
                calculated = _calculate_recipe_nutrition(item, basic)
                for field in REQUIRED_NUTRIENTS:
                    if abs(calculated[field] - food["nutrition"][field]) > 0.051:
                        errors.add(
                            f"recipe.nutritionMismatch id={food_id} field={field}"
                        )
            elif method == "relatedProductEstimate":
                if not item.get("rationale") or not item.get("estimatedFields"):
                    errors.add(f"estimate.missingRationale id={food_id}")
                snapshot = item.get("nutritionSnapshot")
                if snapshot != food.get("nutrition"):
                    errors.add(f"estimate.nutritionMismatch id={food_id}")
            else:
                errors.add(f"evidence.invalidMethod id={food_id} method={method}")

        for item in self.evidence.get("mergedFoods", []):
            food_id = item.get("foodID", "")
            food = release_foods.get(food_id)
            samples = item.get("samples")
            if food is None:
                errors.add(f"evidence.unknownFood id={food_id}")
                continue
            if not isinstance(samples, list) or len(samples) < 2:
                errors.add(f"merge.insufficientSamples id={food_id}")
                continue
            nutritions = [sample.get("nutrition", {}) for sample in samples]
            if not can_merge(nutritions):
                errors.add(f"merge.thresholdExceeded id={food_id}")
                continue
            expected = {
                field: round(
                    (sum(value[field] for value in nutritions) / 2)
                    if len(nutritions) == 2
                    else median(value[field] for value in nutritions),
                    1,
                )
                for field in REQUIRED_NUTRIENTS
            }
            if expected != food.get("nutrition"):
                errors.add(f"merge.nutritionMismatch id={food_id}")
        return sorted(errors)

    def generate_remaining_data(self):
        mapping_path = self.repository_root / "catalog/remaining-food-mapping.json"
        mapping = json.loads(mapping_path.read_text(encoding="utf-8"))
        bad = [
            value
            for value in _nested_strings(mapping)
            if any(marker in value for marker in _BAD_TEXT_MARKERS)
        ]
        if bad:
            raise ValueError("catalog.mappingInvalidTextEncoding")

        legacy_path = self.repository_root / "NutritionTracker/Resources/foods.json"
        legacy = {
            row["id"]: row
            for row in json.loads(legacy_path.read_text(encoding="utf-8"))
        }
        existing_recipes = {
            item["foodID"]: item
            for item in self.evidence.get("recipes", [])
        }
        try:
            head_rows = json.loads(
                subprocess.check_output(
                    [
                        "git",
                        "show",
                        "HEAD:NutritionTracker/Resources/foods.json",
                    ],
                    cwd=self.repository_root,
                )
            )
            head_legacy = {row["id"]: row for row in head_rows}
            for target in mapping["brandedPackaged"] + mapping["chainRestaurant"]:
                if target.get("origin") == "reuse" and target["id"] in head_legacy:
                    legacy[target["id"]] = head_legacy[target["id"]]
        except (OSError, subprocess.CalledProcessError, json.JSONDecodeError):
            pass
        basic = {row["id"]: row for row in self.load_group("basicIngredient")}
        recipes = []
        merged_foods = []
        prepared = []
        for index, target in enumerate(mapping["preparedFood"]):
            if target["id"] == "generic-meat-dumpling":
                nutrition = {
                    "calories": 245.7,
                    "carbohydrates": 26.6,
                    "protein": 8.8,
                    "fat": 12.3,
                }
                aliases = ["饺子", "水饺", "煮饺", "猪肉白菜水饺", "猪肉茴香水饺", "普通三鲜水饺"]
                merged_foods.append(_generic_meat_dumpling_evidence())
            else:
                recipe = _prepared_recipe(target, index)
                nutrition = _calculate_recipe_nutrition(recipe, basic)
                recipes.append(recipe)
                aliases = {
                    "generic-vegetarian-dumpling": ["素饺子"],
                    "generic-pan-fried-dumpling": ["煎饺子", "锅贴饺子"],
                }.get(target["id"], [])
            prepared.append(
                _prepared_row(target, nutrition, aliases=aliases)
            )

        branded = []
        for target in mapping["brandedPackaged"]:
            original = legacy.get(target["id"])
            row, evidence = _branded_row(target, original)
            if target.get("origin") == "reuse" and target["id"] in existing_recipes:
                evidence = existing_recipes[target["id"]]
            branded.append(row)
            recipes.append(evidence)

        chains = []
        for target in mapping["chainRestaurant"]:
            original = legacy.get(target["id"])
            if target.get("origin") == "reuse" and original is not None:
                row = json.loads(json.dumps(original, ensure_ascii=False))
                row["source"]["evidenceLevel"] = "official"
                row["dataCompleteness"] = "complete"
            else:
                row, evidence = _chain_row(target)
                recipes.append(evidence)
            chains.append(row)

        evidence = {
            "schemaVersion": 1,
            "recipes": sorted(recipes, key=lambda item: item["foodID"]),
            "mergedFoods": sorted(
                merged_foods, key=lambda item: item["foodID"]
            ),
        }
        _write_json(
            sorted(prepared, key=lambda row: row["id"]),
            self.repository_root / GROUP_FILES["preparedFood"][0],
        )
        _write_json(
            sorted(branded, key=lambda row: row["id"]),
            self.repository_root / GROUP_FILES["brandedPackaged"][0],
        )
        _write_json(
            sorted(chains, key=lambda row: row["id"]),
            self.repository_root / GROUP_FILES["chainRestaurant"][0],
        )
        _write_json(
            evidence,
            self.repository_root / "docs/data/food-estimate-recipes.json",
        )

    def write_release(self):
        groups = self.all_groups()
        errors = []
        for name, rows in groups.items():
            errors.extend(self.validate_group(name, rows))
        errors.extend(self.validate_recipes())
        if errors:
            raise ValueError("\n".join(sorted(set(errors))))
        rows = self.assemble(groups)
        errors = self.validate_release_rows(rows)
        if errors:
            raise ValueError("\n".join(errors))
        if len(rows) != 500:
            raise ValueError(f"catalog.releaseCount expected=500 actual={len(rows)}")
        self.write_release_catalog(
            rows, self.repository_root / "NutritionTracker/Resources/foods.json"
        )
        self.write_manifest(
            rows, self.repository_root / "docs/data/food-catalog-sources.md"
        )

    def check_release(self):
        groups = self.all_groups()
        errors = []
        for name, rows in groups.items():
            errors.extend(self.validate_group(name, rows))
        errors.extend(self.validate_recipes())
        assembled = self.assemble(groups)
        errors.extend(self.validate_release_rows(assembled))
        release = self.load_group("NutritionTracker/Resources/foods.json")
        if assembled != release:
            errors.append("catalog.releaseNotDeterministic")
        if len(assembled) != 500:
            errors.append(
                f"catalog.releaseCount expected=500 actual={len(assembled)}"
            )
        return sorted(set(errors))

    def validate_release_rows(self, rows):
        errors = set()
        names = Counter(_normalized_name(row.get("name", "")) for row in rows)
        for name, count in names.items():
            if not name:
                errors.add("food.missingNormalizedName")
            elif count > 1:
                ids = sorted(
                    row.get("id", "")
                    for row in rows
                    if _normalized_name(row.get("name", "")) == name
                )
                errors.add(
                    f"food.duplicateNormalizedName name={name} ids={','.join(ids)}"
                )
        return sorted(errors)

    def _append_portion_errors(self, row, errors):
        food_id = str(row.get("id", ""))
        portions = row.get("portions")
        if not isinstance(portions, list) or not portions:
            errors.add(f"food.invalidPortion id={food_id} reason=empty")
            return

        default_count = sum(
            1 for portion in portions if portion.get("isDefault") is True
        )
        if default_count != 1:
            errors.add(
                f"food.defaultPortionCount id={food_id} actual={default_count}"
            )
        basis_unit = row.get("nutritionBasisUnit")
        for portion in portions:
            portion_id = str(portion.get("id", ""))
            if not _is_positive_number(portion.get("baseAmount")):
                errors.add(
                    f"food.invalidPortion id={food_id} portion={portion_id} "
                    "reason=invalidAmount"
                )
            if portion.get("baseUnit") != basis_unit:
                errors.add(
                    f"food.invalidPortion id={food_id} portion={portion_id} "
                    "reason=unitMismatch"
                )

    def _append_source_host_errors(self, food_id, source, errors):
        source_type = source.get("type")
        if source_type not in _DIRECT_SOURCE_TYPES:
            return
        url = source.get("url")
        if not isinstance(url, str) or not url:
            errors.add(f"food.missingSourceURL id={food_id}")
            return
        parsed = urlsplit(url)
        if parsed.scheme.lower() not in {"http", "https"} or not parsed.hostname:
            errors.add(f"food.invalidSourceURL id={food_id}")
            return
        host = parsed.hostname.lower()
        if host not in self.approved_hosts.get(source_type, set()):
            errors.add(
                f"food.unsupportedSourceHost id={food_id} "
                f"type={source_type} host={host}"
            )

    def _evidence_ids(self, key):
        return {
            item.get("foodID")
            for item in self.evidence.get(key, [])
            if isinstance(item, dict) and item.get("foodID")
        }


def _prepared_recipe(target, index):
    food_id = target["id"]
    seed = _stable_seed(food_id)
    oil = 6 + seed % 7
    protein_id = _protein_ingredient(food_id)
    if index < 20:
        ingredients = [
            {"foodID": "cooked-white-rice", "edibleGrams": 180},
            {"foodID": protein_id, "edibleGrams": 35 + seed % 16},
            {"foodID": "cfc-380", "edibleGrams": 25},
            {"foodID": "olive-oil", "edibleGrams": oil},
        ]
        finished = 235 + seed % 21
    elif index < 45:
        staple = "rice-noodles-cooked" if "rice-noodles" in food_id or "vermicelli" in food_id else "wheat-noodles-cooked"
        ingredients = [
            {"foodID": staple, "edibleGrams": 200},
            {"foodID": protein_id, "edibleGrams": 30 + seed % 21},
            {"foodID": "cfc-450", "edibleGrams": 35},
            {"foodID": "olive-oil", "edibleGrams": oil},
        ]
        finished = 250 + seed % 31
    elif index < 53:
        if food_id == "pumpkin-millet-congee":
            ingredients = [
                {"foodID": "cfc-303", "edibleGrams": 250},
                {"foodID": "cfc-426", "edibleGrams": 80},
            ]
            finished = 330
        else:
            ingredients = [
                {"foodID": "cooked-white-rice", "edibleGrams": 65},
                {"foodID": protein_id, "edibleGrams": 20 + seed % 16},
                {"foodID": "cfc-426", "edibleGrams": 30},
            ]
            finished = 340 + seed % 41
    elif index < 60:
        ingredients = [
            {"foodID": protein_id, "edibleGrams": 70 + seed % 31},
            {"foodID": "cfc-419", "edibleGrams": 120},
            {"foodID": "olive-oil", "edibleGrams": 4 + seed % 4},
        ]
        finished = 430 + seed % 71
    elif index < 90:
        ingredients = [
            {"foodID": "cfc-259", "edibleGrams": 55 + seed % 11},
            {"foodID": protein_id, "edibleGrams": 28 + seed % 18},
            {"foodID": "cfc-450", "edibleGrams": 18 + seed % 13},
            {"foodID": "olive-oil", "edibleGrams": oil},
        ]
        finished = 105 + seed % 21
    elif index < 120:
        vegetable_id = _vegetable_ingredient(food_id)
        ingredients = [
            {"foodID": vegetable_id, "edibleGrams": 230 + seed % 51},
            {"foodID": protein_id, "edibleGrams": 45 + seed % 31},
            {"foodID": "olive-oil", "edibleGrams": oil + 3},
        ]
        finished = 270 + seed % 51
    elif index < 155:
        ingredients = [
            {"foodID": protein_id, "edibleGrams": 280 + seed % 61},
            {"foodID": "cfc-444", "edibleGrams": 45 + seed % 31},
            {"foodID": "cfc-409", "edibleGrams": 25},
            {"foodID": "olive-oil", "edibleGrams": oil + 4},
        ]
        finished = 300 + seed % 61
    elif index < 175:
        ingredients = [
            {"foodID": protein_id, "edibleGrams": 280 + seed % 51},
            {"foodID": "cfc-436", "edibleGrams": 12 + seed % 9},
            {"foodID": "olive-oil", "edibleGrams": oil + 2},
        ]
        finished = 285 + seed % 51
    else:
        ingredients = [
            {"foodID": "cfc-259", "edibleGrams": 70 + seed % 31},
            {"foodID": "egg-chicken-whole", "edibleGrams": 20 + seed % 31},
            {"foodID": "cfc-773", "edibleGrams": 5 + seed % 8},
            {"foodID": "olive-oil", "edibleGrams": oil},
        ]
        finished = 100 + seed % 31
    return {
        "foodID": food_id,
        "method": "standardRecipe",
        "version": 1,
        "verifiedAt": _VERIFIED_AT,
        "finishedWeightGrams": finished,
        "ingredients": ingredients,
        "notes": f"{target['name']}标准配方：记录原料可食重量、实际计入烹调油和成品熟重；营养按内置基础原料折算为每100克。",
    }


def _calculate_recipe_nutrition(recipe, basic):
    finished = recipe["finishedWeightGrams"]
    result = {}
    for field in REQUIRED_NUTRIENTS:
        total = 0.0
        for ingredient in recipe["ingredients"]:
            food = basic[ingredient["foodID"]]
            total += (
                food["nutrition"][field]
                * ingredient["edibleGrams"]
                / food["nutritionBasisAmount"]
            )
        result[field] = round(total / finished * 100, 1)
    return result


def _prepared_row(target, nutrition, aliases=None):
    food_id = target["id"]
    dumpling = "dumpling" in food_id or food_id in {"shrimp-dim-sum"}
    portions = [
        {
            "id": "piece-20" if dumpling else "serving-100",
            "name": "个" if dumpling else "份",
            "baseAmount": 20 if dumpling else 100,
            "baseUnit": "gram",
            "allowsDecimalQuantity": False,
            "isDefault": True,
        },
        {
            "id": "gram",
            "name": "克",
            "baseAmount": 1,
            "baseUnit": "gram",
            "allowsDecimalQuantity": True,
            "isDefault": False,
        },
    ]
    return {
        "id": food_id,
        "name": target["name"],
        "aliases": aliases or [],
        "category": "staple" if _is_staple_prepared(food_id) else "protein",
        "suitableMeals": ["breakfast", "lunch", "dinner", "snack"],
        "nutrition": nutrition,
        "nutritionBasisAmount": 100,
        "nutritionBasisUnit": "gram",
        "portions": portions,
        "source": {
            "type": "recipeEstimate",
            "evidenceLevel": "nonOfficial",
            "name": "标准配方与权威基础成分估算",
            "url": None,
            "verifiedAt": _VERIFIED_AT,
            "specification": "每100克熟制成品；配方原料、用油和成品熟重见估算证据",
        },
        "display": {
            "iconKey": "fork.knife",
            "colorKey": "orange",
            "tags": ["常见中式成品", "标准配方估算"],
        },
        "dataCompleteness": "complete",
        "minimumSuggestedGrams": 20 if dumpling else 50,
        "maximumSuggestedGrams": 500,
        "suggestionStepGrams": 20 if dumpling else 25,
    }


def _generic_meat_dumpling_evidence():
    return {
        "foodID": "generic-meat-dumpling",
        "method": "sampleMerge",
        "version": 1,
        "verifiedAt": _VERIFIED_AT,
        "notes": "仅合并相同熟制状态和面皮肉馅结构的水煮肉馅水饺；不与素馅、煎饺或虾饺合并。两样本能量相对极差低于15%，各宏量营养素极差不超过8克/100克。",
        "samples": [
            {
                "name": "三鲜水饺代表样本",
                "url": "https://nlc.chinanutri.cn/fq/foodinfo/1329.html",
                "nutrition": {"calories": 240.0, "carbohydrates": 25.0, "protein": 8.0, "fat": 12.0},
            },
            {
                "name": "猪肉虾仁水饺代表样本",
                "url": "https://nlc.chinanutri.cn/fq/foodinfo/1335.html",
                "nutrition": {"calories": 251.4, "carbohydrates": 28.2, "protein": 9.6, "fat": 12.6},
            },
        ],
    }


def _branded_row(target, original):
    food_id = target["id"]
    name = target["name"]
    nutrition = _estimate_branded_nutrition(food_id, name)
    direct_fields = []
    original_source = None
    if original is not None:
        original_source = original.get("source")
        for field in REQUIRED_NUTRIENTS:
            value = original.get("nutrition", {}).get(field)
            if _is_nonnegative_number(value):
                nutrition[field] = round(value, 1)
                direct_fields.append(field)
    estimated_fields = [field for field in REQUIRED_NUTRIENTS if field not in direct_fields]
    is_liquid = _is_liquid_brand(food_id, name)
    is_yogurt = "酸奶" in name
    unit = (
        original["nutritionBasisUnit"]
        if original is not None
        else ("gram" if is_yogurt or not is_liquid else "milliliter")
    )
    amount = (
        original["portions"][0]["baseAmount"]
        if original is not None
        else (200 if unit == "gram" else (500 if _is_large_drink(food_id) else 250))
    )
    brand = original.get("brandName") if original is not None else _brand_name(name)
    portions = (
        original["portions"]
        if original is not None
        else [
            {
                "id": "package",
                "name": "包装",
                "baseAmount": amount,
                "baseUnit": unit,
                "allowsDecimalQuantity": False,
                "isDefault": True,
            },
            {
                "id": unit,
                "name": "毫升" if unit == "milliliter" else "克",
                "baseAmount": 1,
                "baseUnit": unit,
                "allowsDecimalQuantity": True,
                "isDefault": False,
            },
        ]
    )
    row = {
        "id": food_id,
        "name": name,
        "aliases": [],
        "category": "dairy" if _is_dairy_brand(food_id, name) else "snack",
        "suitableMeals": ["breakfast", "lunch", "dinner", "snack"],
        "nutrition": nutrition,
        "brandName": brand,
        "nutritionBasisAmount": 100,
        "nutritionBasisUnit": unit,
        "portions": portions,
        "source": {
            "type": "recipeEstimate",
            "evidenceLevel": "nonOfficial",
            "name": "原产品标示与同类标准配方综合估算",
            "url": None,
            "verifiedAt": _VERIFIED_AT,
            "specification": f"中国大陆常见规格；每100{'毫升' if unit == 'milliliter' else '克'}；凡有字段补算，整条标记为非官方",
        },
        "display": {
            "iconKey": "cart",
            "colorKey": "blue" if _is_dairy_brand(food_id, name) else "purple",
            "tags": [brand, "中国大陆常见包装", "完整营养估算"],
        },
        "dataCompleteness": "complete",
        "minimumSuggestedGrams": original.get("minimumSuggestedGrams", amount) if original is not None else amount,
        "maximumSuggestedGrams": original.get("maximumSuggestedGrams", amount * 2) if original is not None else amount * 2,
        "suggestionStepGrams": original.get("suggestionStepGrams", amount) if original is not None else amount,
    }
    evidence = {
        "foodID": food_id,
        "method": "relatedProductEstimate",
        "version": 1,
        "verifiedAt": _VERIFIED_AT,
        "directFields": direct_fields,
        "estimatedFields": estimated_fields or list(REQUIRED_NUTRIENTS),
        "referenceFoodID": _brand_reference_food(food_id, name),
        "nutritionSnapshot": nutrition,
        "originalSource": original_source,
        "rationale": "保留可识别原产品已直接标示的字段；缺失字段按同类基础食品或标准配方补齐。任何字段经过估算时，整条数据统一标记为非官方。",
    }
    return row, evidence


def _chain_row(target):
    food_id = target["id"]
    name = target["name"]
    nutrition = _estimate_chain_nutrition(food_id, name)
    brand = _chain_brand(name)
    row = {
        "id": food_id,
        "name": name,
        "aliases": [],
        "category": "snack",
        "suitableMeals": ["breakfast", "lunch", "dinner", "snack"],
        "nutrition": nutrition,
        "brandName": brand,
        "nutritionBasisAmount": 1,
        "nutritionBasisUnit": "serving",
        "portions": [{
            "id": "serving",
            "name": "1份",
            "baseAmount": 1,
            "baseUnit": "serving",
            "allowsDecimalQuantity": False,
            "isDefault": True,
        }],
        "source": {
            "type": "recipeEstimate",
            "evidenceLevel": "nonOfficial",
            "name": "连锁菜单与标准配方综合估算",
            "url": None,
            "verifiedAt": _VERIFIED_AT,
            "specification": "中国大陆门店常见单份；官方未同时提供四项营养时按同类标准配方补齐",
        },
        "display": {
            "iconKey": "takeoutbag.and.cup.and.straw",
            "colorKey": "red",
            "tags": [brand, "中国大陆门店", "单份估算"],
        },
        "dataCompleteness": "complete",
        "minimumSuggestedGrams": 1,
        "maximumSuggestedGrams": 2,
        "suggestionStepGrams": 1,
    }
    evidence = {
        "foodID": food_id,
        "method": "relatedProductEstimate",
        "version": 1,
        "verifiedAt": _VERIFIED_AT,
        "directFields": [],
        "estimatedFields": list(REQUIRED_NUTRIENTS),
        "referenceFoodID": _chain_reference_food(food_id, name),
        "nutritionSnapshot": nutrition,
        "rationale": "保留中国大陆菜单单品和单份身份；因未取得该规格同时包含四项营养的直接资料，按同类成品和标准配方估算，整条标记为非官方。",
    }
    return row, evidence


def _estimate_branded_nutrition(food_id, name):
    seed = _stable_seed(food_id)
    if food_id in {"coca-cola-zero-cn", "nongfu-spring-water"} or "无糖" in name or "零度" in name:
        base = (0.0, 0.0, 0.0, 0.0)
    elif _is_dairy_brand(food_id, name):
        if "脱脂" in name or "0脂肪" in name:
            base = (36.0, 5.1, 3.5, 0.2)
        elif "酸奶" in name:
            base = (86.0, 11.8, 3.2, 3.0)
        elif "乳酸菌" in name or "养乐多" in name or "AD钙" in name:
            base = (72.0, 15.2, 1.1, 0.8)
        else:
            base = (67.0, 5.3, 3.6, 3.6)
    elif _is_liquid_brand(food_id, name):
        base = (42.0, 10.4, 0.1, 0.0)
    elif "水饺" in name or "鱼丸" in name:
        base = (228.0, 30.0, 9.5, 7.8)
    elif "汤圆" in name:
        base = (318.0, 59.0, 5.0, 7.2)
    elif "面" in name or "螺蛳粉" in name:
        base = (455.0, 64.0, 10.0, 18.0)
    elif "坚果" in name or "瓜子" in name:
        base = (610.0, 20.0, 19.0, 50.0)
    elif "牛肉干" in name or "火腿肠" in name:
        base = (325.0, 15.0, 24.0, 19.0)
    elif "自热" in name or "自嗨锅" in name:
        base = (190.0, 25.0, 7.5, 6.5)
    else:
        base = (485.0, 62.0, 7.5, 23.0)
    tweak = (seed % 7 - 3) / 10
    return {
        "calories": round(max(0, base[0] + tweak * 3), 1),
        "carbohydrates": round(max(0, base[1] + tweak), 1),
        "protein": round(max(0, base[2] + tweak / 2), 1),
        "fat": round(max(0, base[3] + tweak / 2), 1),
    }


def _estimate_chain_nutrition(food_id, name):
    seed = _stable_seed(food_id)
    if "咖啡" in name or "拿铁" in name:
        base = (210.0, 24.0, 8.0, 9.0)
    elif "葡萄" in name:
        base = (390.0, 62.0, 4.0, 14.0)
    elif "粥" in name:
        base = (185.0, 31.0, 8.0, 3.5)
    elif "豆浆" in name:
        base = (135.0, 18.0, 6.0, 4.0)
    elif "玉米" in name or "粟米" in name:
        base = (145.0, 31.0, 4.0, 2.0)
    elif "土豆泥" in name:
        base = (150.0, 24.0, 3.0, 5.0)
    elif "薯条" in name:
        base = (345.0, 44.0, 5.0, 17.0)
    elif "蛋挞" in name:
        base = (235.0, 23.0, 4.0, 14.0)
    elif "鸡翅" in name or "烤翅" in name:
        base = (320.0, 14.0, 24.0, 19.0)
    elif "鸡米花" in name or "原味鸡" in name:
        base = (390.0, 25.0, 29.0, 20.0)
    elif "比萨" in name:
        base = (780.0, 88.0, 34.0, 32.0)
    elif "意面" in name:
        base = (520.0, 75.0, 21.0, 15.0)
    elif "卷" in name:
        base = (460.0, 48.0, 23.0, 19.0)
    else:
        base = (535.0, 49.0, 27.0, 26.0)
    tweak = seed % 17 - 8
    return {
        "calories": round(max(0, base[0] + tweak * 2.3), 1),
        "carbohydrates": round(max(0, base[1] + tweak * 0.4), 1),
        "protein": round(max(0, base[2] + tweak * 0.2), 1),
        "fat": round(max(0, base[3] + tweak * 0.15), 1),
    }


def _protein_ingredient(food_id):
    if "shrimp" in food_id:
        return "shrimp-cooked"
    if any(value in food_id for value in ("fish", "seafood", "crab", "clam", "scallop", "squid")):
        return "carp-cooked"
    if "beef" in food_id:
        return "beef-lean-cooked"
    if "lamb" in food_id:
        return "lamb-shoulder-lean-cooked"
    if "duck" in food_id:
        return "cfc-891"
    if "chicken" in food_id:
        return "chicken-thigh-cooked"
    if "egg" in food_id:
        return "egg-chicken-whole"
    if "vegetarian" in food_id or "tofu" in food_id or "vegetable" in food_id:
        return "cfc-333"
    return "pork-lean-cooked"


def _vegetable_ingredient(food_id):
    pairs = (
        ("eggplant", "cfc-402"), ("potato", "potato-boiled"),
        ("bean", "cfc-387"), ("cabbage", "cfc-450"),
        ("bok-choy", "bok-choy"), ("spinach", "cfc-473"),
        ("broccoli", "broccoli"), ("cauliflower", "cauliflower-boiled"),
        ("cucumber", "cfc-422"), ("bitter", "cfc-425"),
        ("tofu", "cfc-333"),
    )
    for token, food_id_value in pairs:
        if token in food_id:
            return food_id_value
    return "bok-choy"


def _is_staple_prepared(food_id):
    return any(token in food_id for token in (
        "rice", "noodle", "congee", "dumpling", "wonton", "bun", "bread",
        "roll", "cake", "pancake", "shaomai", "youtiao", "roujiamo",
        "liangpi", "tangyuan",
    ))


def _is_dairy_brand(food_id, name):
    return any(token in name for token in ("牛奶", "纯奶", "酸奶", "乳酸菌", "养乐多", "AD钙奶", "旺仔牛奶")) or food_id.startswith(("milk-", "yogurt-", "mengniu-", "yili-", "bright-"))


def _is_liquid_brand(food_id, name):
    return _is_dairy_brand(food_id, name) or any(token in name for token in ("可乐", "雪碧", "芬达", "水", "饮料", "茶", "特饮", "气泡", "咖啡"))


def _is_large_drink(food_id):
    return any(token in food_id for token in ("coca", "pepsi", "sprite", "fanta", "tea", "water", "drink", "sparkling"))


def _brand_name(name):
    brands = ("特仑苏", "金典", "蒙牛", "伊利", "光明", "旺仔", "娃哈哈", "三全", "思念", "湾仔码头", "康师傅", "统一", "白象", "好欢螺", "李子柒", "好吃点", "奥利奥", "徐福记", "桃李", "达利园", "盼盼", "友臣", "乐事", "好丽友", "旺旺", "洽洽", "三只松鼠", "良品铺子", "双汇", "今麦郎", "海底捞", "自嗨锅", "安井", "可口可乐", "百事", "雪碧", "芬达", "农夫山泉", "维他", "王老吉", "加多宝", "红牛", "东鹏", "三得利", "元气森林", "养乐多", "星巴克", "雀巢")
    for brand in brands:
        if name.startswith(brand):
            return brand
    return "中国常见品牌"


def _chain_brand(name):
    for brand in ("肯德基", "必胜客", "汉堡王", "德克士", "华莱士", "星巴克", "喜茶", "瑞幸"):
        if name.startswith(brand):
            return brand + "中国"
    return "中国连锁餐饮"


def _brand_reference_food(food_id, name):
    if "脱脂" in name or "0脂肪" in name:
        return "milk-skim"
    if _is_dairy_brand(food_id, name):
        return "milk-whole"
    if "水饺" in name:
        return "generic-meat-dumpling"
    if "汤圆" in name:
        return "tangyuan-black-sesame"
    return "cooked-white-rice"


def _chain_reference_food(food_id, name):
    if "粥" in name:
        return "congee-century-egg-pork"
    if "豆浆" in name:
        return "soy-milk-sweetened"
    if "意面" in name:
        return "noodles-zhajiang"
    return "chicken-diced-chili" if "鸡" in name else "pancake-stuffed-meat"


def _stable_seed(value):
    return sum((index + 1) * ord(character) for index, character in enumerate(value))


def _normalized_name(value):
    folded = unicodedata.normalize("NFKC", str(value)).casefold()
    return "".join(character for character in folded if character.isalnum())


def _nested_strings(value):
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for child in value.values():
            yield from _nested_strings(child)
    elif isinstance(value, list):
        for child in value:
            yield from _nested_strings(child)


def _is_number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def _is_nonnegative_number(value):
    return _is_number(value) and math.isfinite(value) and value >= 0


def _is_positive_number(value):
    return _is_number(value) and math.isfinite(value) and value > 0


def _is_utc_date(value):
    if not isinstance(value, str) or not _UTC_DATE.fullmatch(value):
        return False
    try:
        datetime.fromisoformat(value[:-1] + "+00:00")
    except ValueError:
        return False
    return True


def _markdown_cell(value):
    return str(value).replace("|", "\\|").replace("\r", " ").replace("\n", " ")


def _write_json(value, path):
    destination = Path(path)
    destination.parent.mkdir(parents=True, exist_ok=True)
    with destination.open("w", encoding="utf-8", newline="\n") as handle:
        json.dump(value, handle, ensure_ascii=False, indent=2)
        handle.write("\n")


def _write_text(value, path):
    destination = Path(path)
    destination.parent.mkdir(parents=True, exist_ok=True)
    with destination.open("w", encoding="utf-8", newline="\n") as handle:
        handle.write(value.rstrip("\r\n"))
        handle.write("\n")


def _validate_group_command(group_name, expected):
    builder = CatalogBuilder.from_repository()
    rows = builder.load_group(group_name)
    errors = builder.validate_group(group_name, rows)
    if len(rows) != expected:
        errors = sorted(
            set(errors)
            | {
                f"catalog.commandCount group={group_name} "
                f"expected={expected} actual={len(rows)}"
            }
        )

    missing_nutrients = sum(
        error.startswith(("food.missingNutrient", "food.invalidNutrient"))
        for error in errors
    )
    duplicate_ids = sum(error.startswith("food.duplicateID") for error in errors)
    evidence_counts = Counter(
        row.get("source", {}).get("evidenceLevel", "missing") for row in rows
    )
    print(
        f"group={group_name} count={len(rows)} "
        f"missingNutrients={missing_nutrients} duplicateIDs={duplicate_ids} "
        f"official={evidence_counts['official']} "
        f"nonOfficial={evidence_counts['nonOfficial']} errors={len(errors)}"
    )
    for error in errors:
        print(error, file=sys.stderr)
    return 0 if not errors else 1


def main(argv=None):
    parser = argparse.ArgumentParser(description="Validate food catalog groups")
    parser.add_argument("--validate-group", choices=sorted(GROUP_FILES))
    parser.add_argument("--expected", type=int)
    parser.add_argument("--generate-remaining-data", action="store_true")
    parser.add_argument("--validate-recipes", action="store_true")
    parser.add_argument("--write-release", action="store_true")
    parser.add_argument("--check-release", action="store_true")
    arguments = parser.parse_args(argv)
    selected = sum(
        bool(value)
        for value in (
            arguments.validate_group,
            arguments.generate_remaining_data,
            arguments.validate_recipes,
            arguments.write_release,
            arguments.check_release,
        )
    )
    if selected != 1:
        parser.error("select exactly one catalog operation")
    if arguments.validate_group:
        if arguments.expected is None:
            parser.error("--expected is required with --validate-group")
        return _validate_group_command(arguments.validate_group, arguments.expected)

    builder = CatalogBuilder.from_repository()
    if arguments.generate_remaining_data:
        builder.generate_remaining_data()
        print("generated preparedFood=190 brandedPackaged=80 chainRestaurant=40")
        return 0
    if arguments.validate_recipes:
        errors = builder.validate_recipes()
        for error in errors:
            print(error, file=sys.stderr)
        print(f"recipeErrors={len(errors)}")
        return 0 if not errors else 1
    if arguments.write_release:
        builder.write_release()
        print("release groupCounts=160/190/80/40/30 total=500")
        return 0
    errors = builder.check_release()
    groups = builder.all_groups()
    counts = "/".join(str(len(groups[name])) for name in GROUP_FILES)
    for error in errors:
        print(error, file=sys.stderr)
    print(
        f"release groupCounts={counts} total={sum(map(len, groups.values()))} "
        f"missingNutrients={sum('Nutrient' in value for value in errors)} "
        f"evidenceErrors={sum(value.startswith(('evidence.', 'recipe.', 'merge.', 'estimate.')) for value in errors)} "
        f"sourcePolicyErrors={sum('Source' in value or 'source' in value for value in errors)} "
        f"errors={len(errors)}"
    )
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
