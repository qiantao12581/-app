import json
import math
import subprocess
import sys
import tempfile
import unittest
from copy import deepcopy
from pathlib import Path

from scripts.catalog.catalog_builder import (
    GROUP_FILES,
    CatalogBuilder,
    can_merge,
    relative_energy_spread,
)


class CatalogBuilderTests(unittest.TestCase):
    def test_basic_and_generic_groups_have_exact_counts_and_required_foods(self):
        builder = CatalogBuilder.from_repository()
        basic = builder.load_group("basicIngredient")
        generic = builder.load_group("genericSnackDrink")

        self.assertEqual(len(basic), 160)
        self.assertEqual(len(generic), 30)
        required = {
            "cooked-white-rice",
            "wheat-noodles-cooked",
            "steamed-sweet-potato",
            "potato-boiled",
            "egg-chicken-whole",
            "chicken-breast-cooked",
            "pork-lean-cooked",
            "beef-lean-cooked",
            "milk-whole",
            "banana",
            "apple",
            "bok-choy",
            "broccoli",
        }
        self.assertTrue(required.issubset({row["id"] for row in basic}))
        self.assertEqual(builder.validate_group("basicIngredient", basic), [])
        self.assertEqual(builder.validate_group("genericSnackDrink", generic), [])

    def test_group_validator_cli_reports_expected_counts(self):
        repository_root = Path(__file__).resolve().parents[2]
        script = repository_root / "scripts" / "catalog" / "catalog_builder.py"

        for group, expected in (
            ("basicIngredient", 160),
            ("genericSnackDrink", 30),
        ):
            completed = subprocess.run(
                [
                    sys.executable,
                    "-B",
                    str(script),
                    "--validate-group",
                    group,
                    "--expected",
                    str(expected),
                ],
                cwd=repository_root,
                capture_output=True,
                text=True,
                encoding="utf-8",
                check=False,
            )
            self.assertEqual(completed.returncode, 0, completed.stderr)
            self.assertIn(f"group={group}", completed.stdout)
            self.assertIn(f"count={expected}", completed.stdout)
            self.assertIn("missingNutrients=0", completed.stdout)
            self.assertIn("duplicateIDs=0", completed.stdout)

    def test_repository_catalog_text_has_no_encoding_replacement_markers(self):
        builder = CatalogBuilder.from_repository()

        for group in GROUP_FILES:
            for row in builder.load_group(group):
                for text in nested_strings(row):
                    self.assertNotIn("??", text, f"{group}:{row.get('id')}")
                    self.assertNotIn("\ufffd", text, f"{group}:{row.get('id')}")

        for text in nested_strings(builder.evidence):
            self.assertNotIn("??", text, "recipe evidence")
            self.assertNotIn("\ufffd", text, "recipe evidence")

    def test_prepared_group_has_exact_count_and_chinese_staple_coverage(self):
        builder = CatalogBuilder.from_repository()
        rows = builder.load_group("preparedFood")
        self.assertEqual(len(rows), 190)
        ids = {row["id"] for row in rows}
        required = {
            "generic-meat-dumpling",
            "generic-vegetarian-dumpling",
            "generic-pan-fried-dumpling",
            "shrimp-dim-sum",
            "generic-meat-bun",
            "generic-vegetarian-bun",
            "wonton-boiled",
            "fried-rice-egg",
            "tomato-scrambled-egg",
            "mapo-tofu",
            "kung-pao-chicken",
            "braised-pork",
            "beef-noodle-soup",
        }
        self.assertTrue(required.issubset(ids))
        self.assertEqual(builder.validate_group("preparedFood", rows), [])
        self.assertEqual(builder.validate_nonofficial_evidence(rows), [])

    def test_generic_meat_dumpling_evidence_respects_merge_threshold(self):
        builder = CatalogBuilder.from_repository()
        evidence = builder.merged_food("generic-meat-dumpling")
        self.assertGreaterEqual(len(evidence["samples"]), 2)
        self.assertTrue(
            can_merge([sample["nutrition"] for sample in evidence["samples"]])
        )
        food = builder.food("generic-meat-dumpling")
        self.assertEqual(food["source"]["evidenceLevel"], "nonOfficial")
        self.assertEqual(
            food["nutrition"],
            {
                "calories": 245.7,
                "carbohydrates": 26.6,
                "protein": 8.8,
                "fat": 12.3,
            },
        )
        self.assertIn("水饺", food["aliases"])
        self.assertIn("猪肉白菜水饺", food["aliases"])

    def test_recipe_and_estimate_evidence_graph_is_valid(self):
        builder = CatalogBuilder.from_repository()
        self.assertEqual(builder.validate_recipes(), [])
        prepared = builder.load_group("preparedFood")
        branded = builder.load_group("brandedPackaged")
        chains = builder.load_group("chainRestaurant")
        nonofficial = [
            row
            for row in prepared + branded + chains
            if row["source"]["evidenceLevel"] == "nonOfficial"
        ]
        evidence_ids = {
            item["foodID"]
            for key in ("recipes", "mergedFoods")
            for item in builder.evidence[key]
        }
        self.assertEqual({row["id"] for row in nonofficial}, evidence_ids)

    def test_brand_and_chain_groups_have_exact_counts(self):
        builder = CatalogBuilder.from_repository()
        branded = builder.load_group("brandedPackaged")
        chains = builder.load_group("chainRestaurant")
        self.assertEqual(len(branded), 80)
        self.assertEqual(len(chains), 40)
        self.assertEqual(builder.validate_group("brandedPackaged", branded), [])
        self.assertEqual(builder.validate_group("chainRestaurant", chains), [])

    def test_required_china_market_products_and_chains_are_present(self):
        builder = CatalogBuilder.from_repository()
        branded = {row["id"]: row for row in builder.load_group("brandedPackaged")}
        chains = {row["id"]: row for row in builder.load_group("chainRestaurant")}
        self.assertTrue(
            {
                "mengniu-telunsu-pure-36",
                "milk-skimmed-branded",
                "yogurt-plain-branded",
                "sanquan-celery-pork-dumpling",
            }.issubset(branded)
        )
        self.assertIn("mcd-cn-big-mac", chains)
        self.assertIn("kfc-cn-original-chicken", chains)
        self.assertEqual(
            branded["mengniu-telunsu-pure-36"]["source"]["evidenceLevel"],
            "nonOfficial",
        )
        self.assertEqual(
            chains["mcd-cn-big-mac"]["source"]["evidenceLevel"], "official"
        )
        self.assertEqual(
            chains["kfc-cn-original-chicken"]["source"]["evidenceLevel"],
            "nonOfficial",
        )

    def test_release_catalog_is_exact_complete_and_deterministic(self):
        builder = CatalogBuilder.from_repository()
        groups = builder.all_groups()
        self.assertEqual(
            [len(groups[name]) for name in GROUP_FILES], [160, 190, 80, 40, 30]
        )
        release = builder.load_group("NutritionTracker/Resources/foods.json")
        self.assertEqual(len(release), 500)
        self.assertEqual(release, builder.assemble(groups))
        self.assertEqual(builder.check_release(), [])
        self.assertTrue(
            all(
                row["source"]["evidenceLevel"] in {"official", "nonOfficial"}
                and all(
                    isinstance(row["nutrition"][field], (int, float))
                    and math.isfinite(row["nutrition"][field])
                    and row["nutrition"][field] >= 0
                    for field in ("calories", "carbohydrates", "protein", "fat")
                )
                for row in release
            )
        )
        normalized_names = [
            "".join(character for character in row["name"] if character.isalnum())
            for row in release
        ]
        self.assertEqual(len(normalized_names), len(set(normalized_names)))

    def test_release_gate_rejects_duplicate_normalized_names(self):
        first = valid_food("first")
        second = valid_food("second")
        first["name"] = "小米粥"
        second["name"] = "小 米 粥"

        errors = CatalogBuilder({}).validate_release_rows([first, second])

        self.assertEqual(
            errors,
            ["food.duplicateNormalizedName name=小米粥 ids=first,second"],
        )

    def test_mapping_has_exact_counts_unique_ids_and_clean_utf8(self):
        root = Path(__file__).resolve().parents[2]
        mapping = json.loads(
            (root / ".superpowers/sdd/fast-data-mapping.json").read_text(
                encoding="utf-8"
            )
        )
        self.assertEqual(
            [
                len(mapping["preparedFood"]),
                len(mapping["brandedPackaged"]),
                len(mapping["chainRestaurant"]),
            ],
            [190, 80, 40],
        )
        ids = [
            row["id"]
            for key in ("preparedFood", "brandedPackaged", "chainRestaurant")
            for row in mapping[key]
        ]
        self.assertEqual(len(ids), len(set(ids)))
        for text in nested_strings(mapping):
            self.assertNotIn("??", text)
            self.assertNotIn("\ufffd", text)
        self.assertEqual(mapping["preparedFood"][60]["name"], "肉馅水饺")

    def test_usda_rows_have_chinese_source_metadata(self):
        builder = CatalogBuilder.from_repository()
        rows = builder.load_group("basicIngredient") + builder.load_group(
            "genericSnackDrink"
        )
        usda_rows = [
            row
            for row in rows
            if row.get("source", {}).get("type") == "governmentLaboratory"
        ]

        self.assertEqual(len(usda_rows), 82)
        for row in usda_rows:
            specification = row["source"]["specification"]
            self.assertIn("原始描述：", specification, row["id"])
            self.assertIn("每100克", specification, row["id"])
            self.assertIn("政府实验室数据", row["display"]["tags"], row["id"])

    def test_basic_group_prefers_specific_egg_and_milk_and_includes_livers(self):
        builder = CatalogBuilder.from_repository()
        basic = builder.load_group("basicIngredient")
        ids = {row["id"] for row in basic}

        self.assertNotIn("cfc-978", ids)
        self.assertNotIn("cfc-916", ids)
        self.assertIn("egg-chicken-whole", ids)
        self.assertIn("milk-whole", ids)
        self.assertIn("chicken-liver-simmered", ids)
        self.assertIn("pork-liver-braised", ids)
        self.assertEqual(builder.validate_group("basicIngredient", basic), [])

    def test_group_files_define_exact_release_partitions(self):
        self.assertEqual(
            GROUP_FILES,
            {
                "basicIngredient": ("catalog/foods/basic-ingredients.json", 160),
                "preparedFood": ("catalog/foods/prepared-foods.json", 190),
                "brandedPackaged": ("catalog/foods/branded-packaged.json", 80),
                "chainRestaurant": ("catalog/foods/chain-restaurants.json", 40),
                "genericSnackDrink": (
                    "catalog/foods/generic-snacks-drinks.json",
                    30,
                ),
            },
        )

    def test_relative_energy_spread_uses_mean_denominator(self):
        self.assertAlmostEqual(
            relative_energy_spread([230.0, 248.0, 267.0]),
            37.0 / 248.33333333333334,
        )
        self.assertEqual(relative_energy_spread([]), 0.0)
        self.assertEqual(relative_energy_spread([100.0]), 0.0)
        self.assertTrue(math.isinf(relative_energy_spread([-1.0, 1.0])))

    def test_merge_accepts_exact_boundaries_and_rejects_outliers(self):
        mergeable = [
            {
                "calories": 185.0,
                "carbohydrates": 25.0,
                "protein": 8.0,
                "fat": 6.0,
            },
            {
                "calories": 215.0,
                "carbohydrates": 33.0,
                "protein": 9.0,
                "fat": 10.0,
            },
        ]
        macro_outlier = [mergeable[0], {**mergeable[1], "fat": 14.1}]
        energy_outlier = [mergeable[0], {**mergeable[1], "calories": 215.1}]
        self.assertTrue(can_merge(mergeable))
        self.assertFalse(can_merge(macro_outlier))
        self.assertFalse(can_merge(energy_outlier))
        self.assertFalse(can_merge([]))

    def test_validator_rejects_missing_macro_and_official_estimate(self):
        row = valid_food()
        row["nutrition"]["fat"] = None
        row["source"]["evidenceLevel"] = "official"
        errors = CatalogBuilder({}).validate_group("preparedFood", [row])
        self.assertIn("food.missingNutrient id=fixture field=fat", errors)
        self.assertIn("food.officialEstimate id=fixture", errors)

    def test_validator_reports_all_required_error_types_in_sorted_order(self):
        row = valid_food()
        row["nutrition"]["protein"] = -1
        row["nutritionBasisAmount"] = 0
        row["portions"] = []
        row["source"].pop("evidenceLevel")
        row["source"]["verifiedAt"] = "2026-07-14T08:00:00+08:00"
        errors = CatalogBuilder({}).validate_group("preparedFood", [row, row])

        self.assertEqual(errors, sorted(errors))
        self.assertIn("food.duplicateID id=fixture count=2", errors)
        self.assertIn("food.invalidNutrient id=fixture field=protein", errors)
        self.assertIn("food.invalidBasis id=fixture", errors)
        self.assertIn("food.invalidPortion id=fixture reason=empty", errors)
        self.assertIn("food.missingEvidenceLevel id=fixture", errors)
        self.assertIn("food.invalidVerifiedAt id=fixture", errors)

    def test_nonofficial_food_requires_recipe_or_merge_evidence(self):
        row = valid_food()
        without_evidence = CatalogBuilder({}).validate_group("preparedFood", [row])
        self.assertIn("food.missingNonOfficialEvidence id=fixture", without_evidence)

        evidence = {
            "schemaVersion": 1,
            "recipes": [{"foodID": "fixture"}],
            "mergedFoods": [],
        }
        with_evidence = CatalogBuilder({}, evidence=evidence).validate_group(
            "preparedFood", [row]
        )
        self.assertNotIn("food.missingNonOfficialEvidence id=fixture", with_evidence)

    def test_validator_rejects_official_food_with_merged_evidence(self):
        row = valid_food()
        row["source"] = {
            "type": "governmentLaboratory",
            "evidenceLevel": "official",
            "name": "USDA FoodData Central",
            "url": "https://fdc.nal.usda.gov/fdc-app.html#/food-details/1",
            "verifiedAt": "2026-07-14T00:00:00Z",
            "specification": "每100克",
        }
        evidence = {
            "schemaVersion": 1,
            "recipes": [],
            "mergedFoods": [{"foodID": "fixture", "samples": []}],
        }
        errors = CatalogBuilder(
            {"governmentLaboratory": ["fdc.nal.usda.gov"]},
            evidence=evidence,
        ).validate_group("basicIngredient", [row])
        self.assertIn("food.officialEstimate id=fixture", errors)

    def test_validator_requires_valid_matching_portions(self):
        row = valid_food()
        row["portions"] = [
            {
                "id": "serving",
                "name": "份",
                "baseAmount": 0,
                "baseUnit": "serving",
                "allowsDecimalQuantity": False,
                "isDefault": False,
            }
        ]
        errors = CatalogBuilder({}).validate_group("preparedFood", [row])
        self.assertIn(
            "food.invalidPortion id=fixture portion=serving reason=invalidAmount",
            errors,
        )
        self.assertIn(
            "food.invalidPortion id=fixture portion=serving reason=unitMismatch",
            errors,
        )
        self.assertIn("food.defaultPortionCount id=fixture actual=0", errors)

    def test_source_host_must_match_allowlist_exactly(self):
        approved = {"governmentLaboratory": ["fdc.nal.usda.gov"]}
        row = valid_food()
        row["source"] = {
            "type": "governmentLaboratory",
            "evidenceLevel": "official",
            "name": "USDA FoodData Central",
            "url": "https://fdc.nal.usda.gov/fdc-app.html#/food-details/1",
            "verifiedAt": "2026-07-14T00:00:00Z",
            "specification": "每100克",
        }
        builder = CatalogBuilder(approved)
        self.assertNotIn(
            "food.unsupportedSourceHost id=fixture "
            "type=governmentLaboratory host=fdc.nal.usda.gov",
            builder.validate_group("basicIngredient", [row]),
        )

        row["source"]["url"] = "https://fdc.nal.usda.gov.evil.example/food"
        self.assertIn(
            "food.unsupportedSourceHost id=fixture "
            "type=governmentLaboratory host=fdc.nal.usda.gov.evil.example",
            builder.validate_group("basicIngredient", [row]),
        )

    def test_assemble_rejects_cross_group_ids_and_sorts_rows(self):
        first = valid_food("z-last")
        second = valid_food("a-first")
        builder = CatalogBuilder({})
        self.assertEqual(
            [row["id"] for row in builder.assemble({"preparedFood": [first, second]})],
            ["a-first", "z-last"],
        )
        with self.assertRaisesRegex(
            ValueError,
            "catalog.duplicateID id=z-last groups=basicIngredient,preparedFood",
        ):
            builder.assemble(
                {"preparedFood": [first], "basicIngredient": [deepcopy(first)]}
            )

    def test_load_group_requires_a_json_array(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "group.json"
            path.write_text('{"not": "an array"}', encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "catalog.groupNotArray"):
                CatalogBuilder({}).load_group(path)

    def test_release_writer_sorts_rows_for_deterministic_unicode_output(self):
        rows = [valid_food("z-last"), valid_food("a-first")]
        with tempfile.TemporaryDirectory() as directory:
            first_path = Path(directory) / "foods-first.json"
            second_path = Path(directory) / "foods-second.json"
            builder = CatalogBuilder({})
            builder.write_release_catalog(rows, first_path)
            builder.write_release_catalog(list(reversed(rows)), second_path)
            content = first_path.read_bytes()
            reversed_content = second_path.read_bytes()

        self.assertEqual(content, reversed_content)
        self.assertTrue(content.endswith(b"\n"))
        self.assertFalse(content.endswith(b"\n\n"))
        self.assertIn("测试食物".encode("utf-8"), content)
        self.assertEqual(
            [row["id"] for row in json.loads(content)],
            ["a-first", "z-last"],
        )

    def test_manifest_writer_sorts_rows_and_ends_with_one_newline(self):
        rows = [valid_food("z-last"), valid_food("a-first")]
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "food-catalog-sources.md"
            CatalogBuilder({}).write_manifest(rows, path)
            content = path.read_text(encoding="utf-8")

        self.assertLess(content.index("a-first"), content.index("z-last"))
        self.assertTrue(content.endswith("\n"))
        self.assertFalse(content.endswith("\n\n"))
        self.assertIn("| ID | Chinese name | Brand | Specification | Source type | Evidence | URL |", content)


def valid_food(food_id="fixture"):
    return {
        "id": food_id,
        "name": "测试食物",
        "aliases": [],
        "category": "staple",
        "suitableMeals": ["lunch"],
        "nutrition": {
            "calories": 100.0,
            "carbohydrates": 10.0,
            "protein": 5.0,
            "fat": 4.0,
        },
        "nutritionBasisAmount": 100.0,
        "nutritionBasisUnit": "gram",
        "portions": [
            {
                "id": "gram",
                "name": "克",
                "baseAmount": 1.0,
                "baseUnit": "gram",
                "allowsDecimalQuantity": True,
                "isDefault": True,
            }
        ],
        "source": {
            "type": "recipeEstimate",
            "evidenceLevel": "nonOfficial",
            "name": "标准配方估算",
            "url": None,
            "verifiedAt": "2026-07-14T00:00:00Z",
            "specification": "每100克熟制成品",
        },
        "display": {"iconKey": "fork.knife", "colorKey": "orange", "tags": []},
        "dataCompleteness": "complete",
        "minimumSuggestedGrams": 50.0,
        "maximumSuggestedGrams": 300.0,
        "suggestionStepGrams": 25.0,
    }


def nested_strings(value):
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for child in value.values():
            yield from nested_strings(child)
    elif isinstance(value, list):
        for child in value:
            yield from nested_strings(child)


if __name__ == "__main__":
    unittest.main()
