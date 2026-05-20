# Schema.org Grounding

Agent-Grammar is grounded in Schema.org.

## Rule

Use the most specific native Schema.org type available.

`CreativeWork` is a base class. Many literary artifacts are specific classes under or related to `CreativeWork`.

Do not force all artifacts to `CreativeWork` when Schema.org defines a more specific class.

## AGenNext Metadata

`artifactKind` is AGenNext routing metadata only.

`artifactKind` must not replace or override Schema.org `@type`.

## Examples

| AGenNext artifact kind | Preferred Schema.org type |
|---|---|
| prompt | `CreativeWork` |
| skill | `CreativeWork` with `potentialAction` |
| blog | `BlogPosting` or `Article` |
| readme | `TechArticle` or `CreativeWork` |
| api-doc | `APIReference` or `TechArticle` |
| course | `Course` |
| tutorial | `HowTo` or `LearningResource` |
| policy | `DigitalDocument` or `CreativeWork` |
| protocol | `TechArticle` or `DigitalDocument` |
| spec | `TechArticle` or `DigitalDocument` |

## Validation Meaning

Agent-Grammar validates that an artifact uses the correct Schema.org type for its artifact kind.

The grammar must not invent replacement types when Schema.org already provides one.
