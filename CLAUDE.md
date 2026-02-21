# Project Instructions

## Skill Paths

Bare paths in SKILL.md resolve relative to the SKILL.md file. `{project-root}` = user's CWD. `{installed_path}` = skill install location.

## Research Files

Protocols may have companion research files (`{protocol-name}-research.md` in `protocols/`, or declared via the `research` field in the protocol YAML). These files contain curated science — protein chemistry, failure modes, technique rationale, food safety references — that informed the protocol's design.

When the user asks a "why" question about a protocol (why this temperature, why this technique, why not X), load the research files before answering. Ground the explanation in the curated science, not general LLM knowledge. If no research files exist, fall back to general knowledge as usual.
