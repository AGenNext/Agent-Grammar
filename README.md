# Agent-Grammar

Agent-Grammar is the validation layer for AGenNext `schema:CreativeWork` artifacts.

It defines the rules an artifact must pass before it can be accepted into a content repository such as `Prompt-Library`, skill repositories, documentation repositories, or other CreativeWork stores.

## Core Separation

```text
Agent-Vocabulary
  = words the agent understands
  = schema:DefinedTermSet / schema:DefinedTerm seed data

Agent-Graph
  = relationships between vocabulary words, entities, actions, context, memory, and runtime objects

Agent-Grammar
  = validation rules for whether a schema:CreativeWork is valid for a given use

Prompt-Library / docs / skills
  = accepted schema:CreativeWork artifacts
```

## Rule

A file is not accepted as an AGenNext prompt, skill, API doc, blog post, README, policy, protocol, tutorial, or other literary artifact unless it passes the relevant Agent-Grammar rules.

## Initial Scope

```text
rules/json-schema/creativework/base.schema.json
rules/json-schema/creativework/prompt.schema.json
```

## Meaning

- A vocabulary word is a `schema:DefinedTerm`.
- A prompt artifact is a `schema:CreativeWork`.
- A prompt is valid only when its `schema:CreativeWork` passes Agent-Grammar validation.
- Work requested by a valid prompt is represented as `schema:Action` through `potentialAction`.

## Not Owned Here

Agent-Grammar does not store vocabulary words. That belongs in `Agent-Vocabulary`.

Agent-Grammar does not store relationships between terms. That belongs in `Agent-Graph`.

Agent-Grammar does not store accepted prompt files. That belongs in `Prompt-Library`.
