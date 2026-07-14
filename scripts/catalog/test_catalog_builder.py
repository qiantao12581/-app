import json
import math
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
        self.assertIn("| Food ID | Name | Source Type | Evidence | URL |", content)


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


if __name__ == "__main__":
    unittest.main()
