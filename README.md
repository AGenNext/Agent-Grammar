# Agent-Grammar

Agent-Grammar is the validation layer for AGenNext CreativeWork-compatible artifacts.

It defines the rules an artifact must pass before it can be accepted into a content repository such as `Prompt-Library`, skill repositories, documentation repositories, blueprint repositories, or other CreativeWork stores.

## Core Separation

```text
Agent-Vocabulary
  = words the agent understands
  = schema:DefinedTermSet / schema:DefinedTerm seed data

Agent-Graph
  = relationships between vocabulary words, entities, actions, context, memory, and runtime objects
  = operational context owner

Agent-Grammar
  = validation rules for whether a CreativeWork-compatible artifact is valid for a given use

Prompt-Library / docs / skills / blueprints
  = accepted CreativeWork-compatible artifacts
```

## Critical Context Rule

AGenNext source artifacts use Agent-Graph context.

Correct:

```json
{
  "@context": "agennext:agent-graph"
}
```

Incorrect for source artifacts:

```json
{
  "@context": "https://schema.org"
}
```

Plain Schema.org context is reserved for published/export HTML representations intended for SEO, search engines, or external interoperability.

## Rule

A file is not accepted as an AGenNext prompt, skill, API doc, blog post, README, policy, protocol, tutorial, blueprint, or other CreativeWork-compatible artifact unless it passes the relevant Agent-Grammar rules.

## Initial Scope

```text
rules/json-schema/context/agent-graph-source.schema.json
rules/json-schema/creativework/base.schema.json
rules/json-schema/creativework/prompt.schema.json
rules/json-schema/blueprint/naming.v1.schema.json
```

## Meaning

- A vocabulary word is a `schema:DefinedTerm`.
- A blueprint or prompt artifact is CreativeWork-compatible.
- Source artifacts are validated against Agent-Graph context rules.
- Published/export HTML may emit Schema.org JSON-LD.
- Work requested by a valid artifact may be represented as `schema:Action` through `potentialAction`.

## Blueprint Naming Grammar

Blueprint names are validated through Agent-Grammar.

Canonical format:

```text
<Objective> <Entity Type> Blueprint
```

Example:

```text
Product Launch Agent Team Blueprint
```

Constraints, frameworks, environments, providers, and implementation details belong in metadata — not in the blueprint display name.

## Not Owned Here

Agent-Grammar does not store vocabulary words. That belongs in `Agent-Vocabulary`.

Agent-Grammar does not store relationships between terms. That belongs in `Agent-Graph`.

Agent-Grammar does not store accepted prompt files or blueprints. That belongs in their respective repositories.
