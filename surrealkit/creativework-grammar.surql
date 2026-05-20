-- SurrealKit-managed CreativeWork grammar validation
-- DB-level validation source for Agent-Grammar.

DEFINE TABLE grammar_validation_report SCHEMAFULL;
DEFINE FIELD target_ref ON TABLE grammar_validation_report TYPE string;
DEFINE FIELD target_type ON TABLE grammar_validation_report TYPE string DEFAULT "schema:CreativeWork";
DEFINE FIELD status ON TABLE grammar_validation_report TYPE string ASSERT $value INSIDE ["pass", "fail"];
DEFINE FIELD issues ON TABLE grammar_validation_report TYPE array<object> DEFAULT [];
DEFINE FIELD checked_at ON TABLE grammar_validation_report TYPE datetime DEFAULT time::now();
DEFINE FIELD created_at ON TABLE grammar_validation_report TYPE datetime DEFAULT time::now();

DEFINE INDEX grammar_validation_report_target ON TABLE grammar_validation_report FIELDS target_ref;
DEFINE INDEX grammar_validation_report_status ON TABLE grammar_validation_report FIELDS status;

DEFINE FUNCTION OVERWRITE fn::grammar::action::validate($action: object) -> object {
    LET $issues = [];

    IF $action["@type"] != "Action" {
        LET $issues += [{
            code: "ACTION_TYPE_INVALID",
            path: "potentialAction.@type",
            message: "potentialAction item must be schema:Action",
            expected: "Action",
            actual: $action["@type"]
        }];
    };

    IF type::is_none($action.name) OR $action.name = "" {
        LET $issues += [{
            code: "ACTION_NAME_REQUIRED",
            path: "potentialAction.name",
            message: "Action name is required",
            expected: "non-empty string",
            actual: $action.name
        }];
    };

    RETURN {
        status: IF array::len($issues) = 0 { "pass" } ELSE { "fail" },
        issues: $issues
    };
};

DEFINE FUNCTION OVERWRITE fn::grammar::creativework::validate($work: object) -> object {
    LET $issues = [];

    IF $work["@context"] != "https://schema.org" {
        LET $issues += [{
            code: "CONTEXT_INVALID",
            path: "@context",
            message: "CreativeWork must use schema.org context",
            expected: "https://schema.org",
            actual: $work["@context"]
        }];
    };

    IF $work["@type"] != "CreativeWork" {
        LET $issues += [{
            code: "TYPE_INVALID",
            path: "@type",
            message: "Artifact must be schema:CreativeWork",
            expected: "CreativeWork",
            actual: $work["@type"]
        }];
    };

    IF type::is_none($work.name) OR $work.name = "" {
        LET $issues += [{
            code: "NAME_REQUIRED",
            path: "name",
            message: "CreativeWork name is required",
            expected: "non-empty string",
            actual: $work.name
        }];
    };

    IF !type::is_none($work.potentialAction) {
        LET $actions = IF type::is_array($work.potentialAction) {
            $work.potentialAction
        } ELSE {
            [$work.potentialAction]
        };

        FOR $action IN $actions {
            LET $action_result = fn::grammar::action::validate($action);
            IF $action_result.status = "fail" {
                LET $issues += $action_result.issues;
            };
        };
    };

    RETURN {
        status: IF array::len($issues) = 0 { "pass" } ELSE { "fail" },
        issues: $issues
    };
};

DEFINE FUNCTION OVERWRITE fn::grammar::creativework::report($target_ref: string, $work: object) -> object {
    LET $result = fn::grammar::creativework::validate($work);

    RETURN CREATE ONLY grammar_validation_report CONTENT {
        target_ref: $target_ref,
        target_type: "schema:CreativeWork",
        status: $result.status,
        issues: $result.issues,
        checked_at: time::now(),
        created_at: time::now()
    };
};
