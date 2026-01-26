---
name: stfilepath
description: "Developer-facing skill for working with the STFilePath Swift library. Use when you need to read, modify, build, test, or produce examples for STFilePath (repository contains Swift package, macOS/iOS support, file-watching, hashing, and DownloadableFile utilities)."
---


# STFilePath Skill

Concise developer-facing guidance and quick references for working with the STFilePath Swift package. Use this skill when you need to read, modify, explain, test, or produce examples that use STFilePath features (file operations, hashing, folder watching, DownloadableFile patterns).

Trigger signals (when to use this skill)
- User asks about STFilePath internals or how to implement/patch features in Sources/STFilePath
- User asks for example code, README snippets, or sample apps using STFilePath APIs
- User requests CI/build/test guidance, or to add unit tests to Tests/STFilePathTests

Quick start
- Build locally: `swift build`
- Run tests: `swift test`
- CI workflow: see `.github/workflows/swift.yml` for an example using macOS and swift build/test
- Example snippet for README: use `scripts/example_usage.swift` as canonical sample code

What this skill provides
- Quick start snippets for the most common tasks (create/read/write/move/delete, hashing, folder watcher)
- Pointer files mapping core sources and where to add or change code (references/FILES.md)
- Example code for basic and advanced patterns (references/EXAMPLES.md and scripts/example_usage.swift)
- Short API quick reference to locate types and commonly-used methods (references/API_REFERENCE.md)
- Troubleshooting guide for common runtime issues (references/TROUBLESHOOTING.md)
- CI, packaging, and release notes (references/CI_AND_PACKAGING.md)
- Test suggestions and where to add them (references/TESTS.md)

Progressive disclosure (what to open when)
- Look at references/FILES.md first to locate the implementation file you need to change.
- Open references/API_REFERENCE.md when you need method signatures and short usage snippets.
- Open references/EXAMPLES.md for copy-pasteable examples (basic + advanced).
- Open references/TROUBLESHOOTING.md when encountering runtime issues (watcher permissions, file locks, path errors).

Minimal expectations and conventions
- This repo is a Swift Package (Package.swift present) and targets macOS/iOS.
- Follow existing naming and API conventions in Sources/STFilePath.
- Tests live under Tests/STFilePathTests; add unit tests alongside related features.

Safety and change guidance
- Avoid breaking public APIs without tests and README updates.
- For platform-specific behavior (macOS vs iOS), include platform guards and run tests on macOS CI.

Packaging the skill
- To package this skill as a distributable .skill, bundle the skills/stfilepath directory. Tell me if you want me to produce that .skill archive.

Contacts and maintenance
- When renaming or moving files, update references/FILES.md.
- Keep examples in references/EXAMPLES.md sync'd with README.md snippets.
