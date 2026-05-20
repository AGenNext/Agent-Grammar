-- AGenNext Blueprint Source Grammar v1
-- Validates source blueprint records using Agent-Graph context.
-- Source documents must NOT use plain https://schema.org as @context.
-- Published/export HTML may emit Schema.org JSON-LD separately.

DEFINE TABLE blueprint_source_grammar_v1 SCHEMAFULL;

DEFINE FIELD context ON TABLE blueprint_source_grammar_v1 TYPE string ASSERT $value INSIDE [
  "agennext:agent-graph",
  "https://github.com/AGenNext/Agent-Graph/context/agent-graph.jsonld"
];

DEFINE FIELD type ON TABLE blueprint_source_grammar_v1 TYPE string ASSERT $value INSIDE [
  "ag:Blueprint",
  "Blueprint"
];

DEFINE FIELD blueprint_id ON TABLE blueprint_source_grammar_v1 TYPE string ASSERT string::matches($value, "^[a-z0-9]+(-[a-z0-9]+)*-(agent|agent-team|workflow|protocol|capability|runtime-profile|role)$");

DEFINE FIELD name ON TABLE blueprint_source_grammar_v1 TYPE string ASSERT string::matches($value, "^[A-Z][A-Za-z0-9]*( [A-Z][A-Za-z0-9]*)* (Agent|Agent Team|Workflow|Protocol|Capability|Runtime Profile|Role) Blueprint$");

DEFINE FIELD blueprint_type ON TABLE blueprint_source_grammar_v1 TYPE string ASSERT $value INSIDE [
  "agent",
  "team",
  "workflow",
  "protocol",
  "capability",
  "runtime-profile",
  "role"
];

DEFINE FIELD objective ON TABLE blueprint_source_grammar_v1 TYPE string ASSERT string::matches($value, "^[a-z0-9]+(_[a-z0-9]+)*$");

DEFINE FIELD description ON TABLE blueprint_source_grammar_v1 TYPE string ASSERT string::len($value) > 0;
DEFINE FIELD creator ON TABLE blueprint_source_grammar_v1 TYPE any;
DEFINE FIELD dateCreated ON TABLE blueprint_source_grammar_v1 TYPE string ASSERT string::matches($value, "^[0-9]{4}-[0-9]{2}-[0-9]{2}$");

DEFINE FIELD agentGraphAlignment ON TABLE blueprint_source_grammar_v1 TYPE object;
DEFINE FIELD agentGraphAlignment.contextOwner ON TABLE blueprint_source_grammar_v1 TYPE string ASSERT $value = "Agent-Graph";
DEFINE FIELD agentGraphAlignment.semanticClass ON TABLE blueprint_source_grammar_v1 TYPE string ASSERT $value = "CreativeWork";
DEFINE FIELD agentGraphAlignment.graphOwnership ON TABLE blueprint_source_grammar_v1 TYPE string ASSERT $value = "Agent-Graph";
DEFINE FIELD agentGraphAlignment.doesNotDefineGraphSchema ON TABLE blueprint_source_grammar_v1 TYPE bool ASSERT $value = true;
DEFINE FIELD agentGraphAlignment.publishedStructuredDataContext ON TABLE blueprint_source_grammar_v1 TYPE option<string> ASSERT $value = NONE OR $value = "https://schema.org";

DEFINE FIELD created_at ON TABLE blueprint_source_grammar_v1 TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON TABLE blueprint_source_grammar_v1 TYPE datetime DEFAULT time::now();

DEFINE INDEX blueprint_source_grammar_v1_blueprint_id ON TABLE blueprint_source_grammar_v1 FIELDS blueprint_id UNIQUE;
DEFINE INDEX blueprint_source_grammar_v1_type ON TABLE blueprint_source_grammar_v1 FIELDS blueprint_type;
DEFINE INDEX blueprint_source_grammar_v1_objective ON TABLE blueprint_source_grammar_v1 FIELDS objective;

-- Cross-field validation helpers.
-- These functions are intended for Agent-Graph / Agent-Review validation pipelines.

DEFINE FUNCTION fn::blueprint_entity_suffix($blueprint_type: string) {
  RETURN IF $blueprint_type = "team" THEN "agent-team"
    ELSE IF $blueprint_type = "agent" THEN "agent"
    ELSE IF $blueprint_type = "workflow" THEN "workflow"
    ELSE IF $blueprint_type = "protocol" THEN "protocol"
    ELSE IF $blueprint_type = "capability" THEN "capability"
    ELSE IF $blueprint_type = "runtime-profile" THEN "runtime-profile"
    ELSE IF $blueprint_type = "role" THEN "role"
    ELSE "" END;
};

DEFINE FUNCTION fn::blueprint_entity_label($blueprint_type: string) {
  RETURN IF $blueprint_type = "team" THEN "Agent Team"
    ELSE IF $blueprint_type = "agent" THEN "Agent"
    ELSE IF $blueprint_type = "workflow" THEN "Workflow"
    ELSE IF $blueprint_type = "protocol" THEN "Protocol"
    ELSE IF $blueprint_type = "capability" THEN "Capability"
    ELSE IF $blueprint_type = "runtime-profile" THEN "Runtime Profile"
    ELSE IF $blueprint_type = "role" THEN "Role"
    ELSE "" END;
};

DEFINE FUNCTION fn::validate_blueprint_source_v1($doc: object) {
  LET $entity_suffix = fn::blueprint_entity_suffix($doc.blueprint_type);
  LET $entity_label = fn::blueprint_entity_label($doc.blueprint_type);

  RETURN {
    context_valid: $doc.context INSIDE ["agennext:agent-graph", "https://github.com/AGenNext/Agent-Graph/context/agent-graph.jsonld"],
    schema_org_not_source_context: $doc.context != "https://schema.org",
    type_valid: $doc.type INSIDE ["ag:Blueprint", "Blueprint"],
    blueprint_id_valid: string::matches($doc.blueprint_id, "^[a-z0-9]+(-[a-z0-9]+)*-(agent|agent-team|workflow|protocol|capability|runtime-profile|role)$"),
    blueprint_id_matches_type: string::ends_with($doc.blueprint_id, "-" + $entity_suffix),
    name_valid: string::matches($doc.name, "^[A-Z][A-Za-z0-9]*( [A-Z][A-Za-z0-9]*)* (Agent|Agent Team|Workflow|Protocol|Capability|Runtime Profile|Role) Blueprint$"),
    name_matches_type: string::ends_with($doc.name, " " + $entity_label + " Blueprint"),
    objective_valid: string::matches($doc.objective, "^[a-z0-9]+(_[a-z0-9]+)*$"),
    semantic_class_valid: $doc.agentGraphAlignment.semanticClass = "CreativeWork",
    graph_owner_valid: $doc.agentGraphAlignment.graphOwnership = "Agent-Graph",
    does_not_define_graph_schema: $doc.agentGraphAlignment.doesNotDefineGraphSchema = true
  };
};

DEFINE FUNCTION fn::blueprint_source_v1_is_valid($doc: object) {
  LET $result = fn::validate_blueprint_source_v1($doc);

  RETURN $result.context_valid
    AND $result.schema_org_not_source_context
    AND $result.type_valid
    AND $result.blueprint_id_valid
    AND $result.blueprint_id_matches_type
    AND $result.name_valid
    AND $result.name_matches_type
    AND $result.objective_valid
    AND $result.semantic_class_valid
    AND $result.graph_owner_valid
    AND $result.does_not_define_graph_schema;
};
