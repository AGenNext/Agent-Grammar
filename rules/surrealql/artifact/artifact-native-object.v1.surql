-- AGenNext Native Artifact Object Grammar v1
-- All accepted AGenNext artifacts are persisted and enforced as native database records.
-- Source files are authoring/import representations only.
-- Published files/pages are export representations only.

DEFINE TABLE artifact_kind SCHEMAFULL;
DEFINE FIELD key ON TABLE artifact_kind TYPE string ASSERT string::matches($value, "^[a-z0-9]+(-[a-z0-9]+)*$");
DEFINE FIELD label ON TABLE artifact_kind TYPE string ASSERT string::len($value) > 0;
DEFINE FIELD owning_repo ON TABLE artifact_kind TYPE string ASSERT string::len($value) > 0;
DEFINE FIELD native_table ON TABLE artifact_kind TYPE string ASSERT string::matches($value, "^[a-z0-9_]+(_v[0-9]+)?$");
DEFINE FIELD semantic_class ON TABLE artifact_kind TYPE string ASSERT string::len($value) > 0;
DEFINE FIELD context_owner ON TABLE artifact_kind TYPE string ASSERT $value = "Agent-Graph";
DEFINE FIELD grammar_owner ON TABLE artifact_kind TYPE string ASSERT $value = "Agent-Grammar";
DEFINE FIELD review_owner ON TABLE artifact_kind TYPE string ASSERT $value = "Agent-Review";
DEFINE INDEX artifact_kind_key ON TABLE artifact_kind FIELDS key UNIQUE;
DEFINE INDEX artifact_kind_native_table ON TABLE artifact_kind FIELDS native_table UNIQUE;

DEFINE TABLE artifact_representation SCHEMAFULL;
DEFINE FIELD key ON TABLE artifact_representation TYPE string ASSERT $value INSIDE ["source_import", "native_record", "published_export"];
DEFINE FIELD label ON TABLE artifact_representation TYPE string ASSERT string::len($value) > 0;
DEFINE FIELD is_canonical ON TABLE artifact_representation TYPE bool DEFAULT false;
DEFINE INDEX artifact_representation_key ON TABLE artifact_representation FIELDS key UNIQUE;

DEFINE TABLE artifact_contract_v1 SCHEMAFULL;
DEFINE FIELD artifact_kind ON TABLE artifact_contract_v1 TYPE record<artifact_kind>;
DEFINE FIELD canonical_representation ON TABLE artifact_contract_v1 TYPE record<artifact_representation> ASSERT $value.key = "native_record" AND $value.is_canonical = true;
DEFINE FIELD source_representation ON TABLE artifact_contract_v1 TYPE record<artifact_representation> ASSERT $value.key = "source_import";
DEFINE FIELD published_representation ON TABLE artifact_contract_v1 TYPE option<record<artifact_representation>> ASSERT $value = NONE OR $value.key = "published_export";
DEFINE FIELD source_files_are_canonical ON TABLE artifact_contract_v1 TYPE bool ASSERT $value = false;
DEFINE FIELD native_database_record_required ON TABLE artifact_contract_v1 TYPE bool ASSERT $value = true;
DEFINE FIELD grammar_validation_required ON TABLE artifact_contract_v1 TYPE bool ASSERT $value = true;
DEFINE FIELD review_required_before_publish ON TABLE artifact_contract_v1 TYPE bool ASSERT $value = true;
DEFINE FIELD created_at ON TABLE artifact_contract_v1 TYPE datetime DEFAULT time::now();
DEFINE INDEX artifact_contract_v1_kind ON TABLE artifact_contract_v1 FIELDS artifact_kind UNIQUE;

DEFINE FUNCTION fn::artifact_contract_v1_is_valid($contract: record<artifact_contract_v1>) {
  LET $doc = SELECT * FROM ONLY $contract;

  RETURN $doc.canonical_representation.key = "native_record"
    AND $doc.canonical_representation.is_canonical = true
    AND $doc.source_representation.key = "source_import"
    AND $doc.source_files_are_canonical = false
    AND $doc.native_database_record_required = true
    AND $doc.grammar_validation_required = true
    AND $doc.review_required_before_publish = true;
};

UPSERT artifact_representation:source_import SET
  key = "source_import",
  label = "Source/import representation",
  is_canonical = false;

UPSERT artifact_representation:native_record SET
  key = "native_record",
  label = "Native database record",
  is_canonical = true;

UPSERT artifact_representation:published_export SET
  key = "published_export",
  label = "Published/export representation",
  is_canonical = false;

UPSERT artifact_kind:blueprint SET
  key = "blueprint",
  label = "Blueprint",
  owning_repo = "Agent-Blueprint",
  native_table = "blueprint_source_v1",
  semantic_class = "CreativeWork",
  context_owner = "Agent-Graph",
  grammar_owner = "Agent-Grammar",
  review_owner = "Agent-Review";

UPSERT artifact_contract_v1:blueprint SET
  artifact_kind = artifact_kind:blueprint,
  canonical_representation = artifact_representation:native_record,
  source_representation = artifact_representation:source_import,
  published_representation = artifact_representation:published_export,
  source_files_are_canonical = false,
  native_database_record_required = true,
  grammar_validation_required = true,
  review_required_before_publish = true;
