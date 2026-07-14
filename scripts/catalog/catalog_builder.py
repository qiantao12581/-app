import argparse
import json
import math
import re
import sys
from collections import Counter
from datetime import datetime
from pathlib import Path
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
            "| Food ID | Name | Source Type | Evidence | URL |",
            "| --- | --- | --- | --- | --- |",
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
                        source.get("type", ""),
                        source.get("evidenceLevel", ""),
                        source.get("url") or "",
                    )
                )
                + " |"
            )
        _write_text("\n".join(lines), path)

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
    arguments = parser.parse_args(argv)
    if arguments.validate_group is None or arguments.expected is None:
        parser.error("--validate-group and --expected are required")
    return _validate_group_command(arguments.validate_group, arguments.expected)


if __name__ == "__main__":
    raise SystemExit(main())
