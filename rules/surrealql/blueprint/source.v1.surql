-- AGenNext Blueprint Source Grammar v1
-- Database-native SurrealDB validation for source blueprint records.
-- This file is intended to be applied inside Agent-Graph / SurrealDB.
-- JSON Schema may document the contract, but acceptance is enforced here.

-- -----------------------------------------------------------------------------
-- Grammar lookup tables
-- -----------------------------------------------------------------------------

DEFINE TABLE grammar_context SCHEMAFULL;
DEFINE FIELD key ON TABLE grammar_context TYPE string ASSERT string::len($value) > 0;
DEFINE FIELD iri ON TABLE grammar_context TYPE string ASSERT string::len($value) > 0;
DEFINE FIELD owner ON TABLE grammar_context TYPE string ASSERT $value = "Agent-Graph";
DEFINE FIELD usage ON TABLE grammar_context TYPE string ASSERT $value INSIDE ["source", "published_export"];
DEFINE FIELD allowed_for_source ON TABLE grammar_context TYPE bool DEFAULT false;
DEFINE INDEX grammar_context_key ON TABLE grammar_context FIELDS key UNIQUE;
DEFINE INDEX grammar_context_iri ON TABLE grammar_context FIELDS iri UNIQUE;

DEFINE TABLE blueprint_entity_type SCHEMAFULL;
DEFINE FIELD key ON TABLE blueprint_entity_type TYPE string ASSERT $value INSIDE [
  "agent",
  "team",
  "workflow",
  "protocol",
  "capability",
  "runtime-profile",
  "role"
];
DEFINE FIELD label ON TABLE blueprint_entity_type TYPE string ASSERT $value INSIDE [
  "Agent",
  "Agent Team",
  "Workflow",
  "Protocol",
  "Capability",
  "Runtime Profile",
  "Role"
];
DEFINE FIELD id_suffix ON TABLE blueprint_entity_type TYPE string ASSERT string::len($value) > 0;
DEFINE INDEX blueprint_entity_type_key ON TABLE blueprint_entity_type FIELDS key UNIQUE;
DEFINE INDEX blueprint_entity_type_suffix ON TABLE blueprint_entity_type FIELDS id_suffix UNIQUE;

DEFINE TABLE blueprint_objective SCHEMAFULL;
DEFINE FIELD key ON TABLE blueprint_objective TYPE string ASSERT string::matches($value, "^[a-z0-9]+(_[a-z0-9]+)*$");
DEFINE FIELD label ON TABLE blueprint_objective TYPE string ASSERT string::matches($value, "^[A-Z][A-Za-z0-9]*( [A-Z][A-Za-z0-9]*)*$");
DEFINE INDEX blueprint_objective_key ON TABLE blueprint_objective FIELDS key UNIQUE;

-- -----------------------------------------------------------------------------
-- Source blueprint records
-- -----------------------------------------------------------------------------

DEFINE TABLE blueprint_source_v1 SCHEMAFULL;

DEFINE FIELD context ON TABLE blueprint_source_v1 TYPE record<grammar_context> ASSERT $value.allowed_for_source = true AND $value.owner = "Agent-Graph";
DEFINE FIELD type ON TABLE blueprint_source_v1 TYPE string ASSERT $value INSIDE ["ag:Blueprint", "Blueprint"];
DEFINE FIELD blueprint_id ON TABLE blueprint_source_v1 TYPE string ASSERT string::matches($value, "^[a-z0-9]+(-[a-z0-9]+)*-(agent|agent-team|workflow|protocol|capability|runtime-profile|role)$");
DEFINE FIELD name ON TABLE blueprint_source_v1 TYPE string ASSERT string::matches($value, "^[A-Z][A-Za-z0-9]*( [A-Z][A-Za-z0-9]*)* (Agent|Agent Team|Workflow|Protocol|Capability|Runtime Profile|Role) Blueprint$");
DEFINE FIELD blueprint_type ON TABLE blueprint_source_v1 TYPE record<blueprint_entity_type>;
DEFINE FIELD objective ON TABLE blueprint_source_v1 TYPE record<blueprint_objective>;
DEFINE FIELD description ON TABLE blueprint_source_v1 TYPE string ASSERT string::len($value) > 0;
DEFINE FIELD creator ON TABLE blueprint_source_v1 TYPE any;
DEFINE FIELD publisher ON TABLE blueprint_source_v1 TYPE option<any>;
DEFINE FIELD date_created ON TABLE blueprint_source_v1 TYPE datetime;
DEFINE FIELD date_modified ON TABLE blueprint_source_v1 TYPE option<datetime>;
DEFINE FIELD lifecycle_status ON TABLE blueprint_source_v1 TYPE string ASSERT $value INSIDE ["draft", "reviewed", "approved", "generated", "validated", "deprecated"];

DEFINE FIELD graph_context_owner ON TABLE blueprint_source_v1 TYPE string ASSERT $value = "Agent-Graph";
DEFINE FIELD semantic_class ON TABLE blueprint_source_v1 TYPE string ASSERT $value = "CreativeWork";
DEFINE FIELD graph_ownership ON TABLE blueprint_source_v1 TYPE string ASSERT $value = "Agent-Graph";
DEFINE FIELD does_not_define_graph_schema ON TABLE blueprint_source_v1 TYPE bool ASSERT $value = true;
DEFINE FIELD published_structured_data_context ON TABLE blueprint_source_v1 TYPE option<record<grammar_context>> ASSERT $value = NONE OR $value.usage = "published_export";

DEFINE FIELD source_repository ON TABLE blueprint_source_v1 TYPE option<string>;
DEFINE FIELD source_path ON TABLE blueprint_source_v1 TYPE option<string>;
DEFINE FIELD source_version ON TABLE blueprint_source_v1 TYPE option<string>;
DEFINE FIELD created_at ON TABLE blueprint_source_v1 TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON TABLE blueprint_source_v1 TYPE datetime DEFAULT time::now();

DEFINE INDEX blueprint_source_v1_blueprint_id ON TABLE blueprint_source_v1 FIELDS blueprint_id UNIQUE;
DEFINE INDEX blueprint_source_v1_name ON TABLE blueprint_source_v1 FIELDS name;
DEFINE INDEX blueprint_source_v1_type ON TABLE blueprint_source_v1 FIELDS blueprint_type;
DEFINE INDEX blueprint_source_v1_objective ON TABLE blueprint_source_v1 FIELDS objective;
DEFINE INDEX blueprint_source_v1_lifecycle_status ON TABLE blueprint_source_v1 FIELDS lifecycle_status;

-- -----------------------------------------------------------------------------
-- Native validation functions
-- -----------------------------------------------------------------------------

DEFINE FUNCTION fn::blueprint_expected_id($objective: record<blueprint_objective>, $blueprint_type: record<blueprint_entity_type>) {
  RETURN string::replace($objective.key, "_", "-") + "-" + $blueprint_type.id_suffix;
};

DEFINE FUNCTION fn::blueprint_expected_name($objective: record<blueprint_objective>, $blueprint_type: record<blueprint_entity_type>) {
  RETURN $objective.label + " " + $blueprint_type.label + " Blueprint";
};

DEFINE FUNCTION fn::blueprint_source_v1_validation_report($record: record<blueprint_source_v1>) {
  LET $doc = SELECT * FROM ONLY $record;
  LET $expected_id = fn::blueprint_expected_id($doc.objective, $doc.blueprint_type);
  LET $expected_name = fn::blueprint_expected_name($doc.objective, $doc.blueprint_type);

  RETURN {
    record: $record,
    expected_id: $expected_id,
    expected_name: $expected_name,
    context_valid: $doc.context.allowed_for_source = true AND $doc.context.owner = "Agent-Graph",
    source_context_not_schema_org: $doc.context.iri != "https://schema.org",
    type_valid: $doc.type INSIDE ["ag:Blueprint", "Blueprint"],
    blueprint_id_matches_grammar: $doc.blueprint_id = $expected_id,
    name_matches_grammar: $doc.name = $expected_name,
    semantic_class_valid: $doc.semantic_class = "CreativeWork",
    graph_owner_valid: $doc.graph_ownership = "Agent-Graph",
    graph_context_owner_valid: $doc.graph_context_owner = "Agent-Graph",
    does_not_define_graph_schema: $doc.does_not_define_graph_schema = true,
    publish_context_valid: $doc.published_structured_data_context = NONE OR $doc.published_structured_data_context.usage = "published_export"
  };
};

DEFINE FUNCTION fn::blueprint_source_v1_is_valid($record: record<blueprint_source_v1>) {
  LET $r = fn::blueprint_source_v1_validation_report($record);

  RETURN $r.context_valid
    AND $r.source_context_not_schema_org
    AND $r.type_valid
    AND $r.blueprint_id_matches_grammar
    AND $r.name_matches_grammar
    AND $r.semantic_class_valid
    AND $r.graph_owner_valid
    AND $r.graph_context_owner_valid
    AND $r.does_not_define_graph_schema
    AND $r.publish_context_valid;
};

-- -----------------------------------------------------------------------------
-- Publication review gate
-- -----------------------------------------------------------------------------

DEFINE TABLE blueprint_publication_review_v1 SCHEMAFULL;
DEFINE FIELD blueprint ON TABLE blueprint_publication_review_v1 TYPE record<blueprint_source_v1>;
DEFINE FIELD grammar_report ON TABLE blueprint_publication_review_v1 TYPE object DEFAULT fn::blueprint_source_v1_validation_report($this.blueprint);
DEFINE FIELD grammar_passed ON TABLE blueprint_publication_review_v1 TYPE bool DEFAULT fn::blueprint_source_v1_is_valid($this.blueprint) ASSERT $value = true;
DEFINE FIELD reviewer ON TABLE blueprint_publication_review_v1 TYPE option<string>;
DEFINE FIELD recommendation ON TABLE blueprint_publication_review_v1 TYPE string ASSERT $value INSIDE ["publish", "reject", "revise"];
DEFINE FIELD reviewed_at ON TABLE blueprint_publication_review_v1 TYPE datetime DEFAULT time::now();
DEFINE INDEX blueprint_publication_review_v1_blueprint ON TABLE blueprint_publication_review_v1 FIELDS blueprint;

-- -----------------------------------------------------------------------------
-- Seed grammar data
-- -----------------------------------------------------------------------------

UPSERT grammar_context:agent_graph_content SET
  key = "agent_graph_content",
  iri = "agennext:agent-graph",
  owner = "Agent-Graph",
  usage = "source",
  allowed_for_source = true;

UPSERT grammar_context:agent_graph_jsonld SET
  key = "agent_graph_jsonld",
  iri = "https://github.com/AGenNext/Agent-Graph/context/agent-graph.jsonld",
  owner = "Agent-Graph",
  usage = "source",
  allowed_for_source = true;

UPSERT grammar_context:schema_org_export SET
  key = "schema_org_export",
  iri = "https://schema.org",
  owner = "Agent-Graph",
  usage = "published_export",
  allowed_for_source = false;

UPSERT blueprint_entity_type:agent SET key = "agent", label = "Agent", id_suffix = "agent";
UPSERT blueprint_entity_type:team SET key = "team", label = "Agent Team", id_suffix = "agent-team";
UPSERT blueprint_entity_type:workflow SET key = "workflow", label = "Workflow", id_suffix = "workflow";
UPSERT blueprint_entity_type:protocol SET key = "protocol", label = "Protocol", id_suffix = "protocol";
UPSERT blueprint_entity_type:capability SET key = "capability", label = "Capability", id_suffix = "capability";
UPSERT blueprint_entity_type:runtime_profile SET key = "runtime-profile", label = "Runtime Profile", id_suffix = "runtime-profile";
UPSERT blueprint_entity_type:role SET key = "role", label = "Role", id_suffix = "role";

UPSERT blueprint_objective:product_launch SET key = "product_launch", label = "Product Launch";
UPSERT blueprint_objective:cloud_architecture SET key = "cloud_architecture", label = "Cloud Architecture";
