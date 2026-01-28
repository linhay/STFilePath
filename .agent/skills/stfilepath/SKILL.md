---
name: stfilepath
description: "Developer-facing skill for working with the STFilePath Swift library. Use when you need to read, modify, build, test, or generate examples for any STFilePath feature (paths/files/folders, sandbox & containers, watchers, hashing, metadata/permissions/xattrs, mmap/Darwin, search/backup, JSON lines, compression, DownloadableFile, caches/UserDefaults, iOS/macOS integrations)."
---


# STFilePath Skill

Developer-facing guidance for working with the STFilePath Swift package. Use this skill when you need to read, modify, explain, test, or produce examples across the full surface area of the library.

Trigger signals (when to use this skill)
- User asks about STFilePath internals or how to implement/patch features in Sources/STFilePath
- User asks for example code, README snippets, scripts, or sample apps using STFilePath APIs
- User requests CI/build/test guidance, or to add unit tests to Tests/STFilePathTests
- User asks about any of: sandbox/container URLs, iOS document picker, macOS Finder integration, mmap, permissions/xattrs, JSON lines, caching, compression

Quick start
- Build locally: `swift build`
- Run tests: `swift test`
- CI workflow: see `.github/workflows/swift.yml` for an example using macOS and swift build/test
- Example snippets: see `references/EXAMPLES.md` (API-accurate snippets) and `scripts/` (longer, script-like examples)

Capability map (open the referenced file for details)
- “函数教程/直接写代码”：`references/FUNCTION_COOKBOOK.md`
- Core types & path model: `references/API_REFERENCE.md`
- File/folder operations & streaming: `references/FILE_IO.md`
- Sandbox & containers (document/library/cache/app group/iCloud): `references/CORE_PATHS_AND_SANDBOX.md`
- Watchers (file/folder/path, backends): `references/WATCHERS.md`
- Hashing (CryptoKit): `references/HASHING.md`
- Metadata/permissions/xattrs/symlinks/security-scoped: `references/METADATA_PERMISSIONS_XATTR_LINKS.md`
- MMAP & Darwin low-level APIs: `references/MMAP_AND_DARWIN.md`
- Search & backup: `references/SEARCH_AND_BACKUP.md`
- JSON Lines: `references/JSON_LINES.md`
- Compression: `references/COMPRESSION.md`
- DownloadableFile (DFAnyFile/DFFileMap/DFCurrentValueFile): `references/DOWNLOADABLEFILE.md`
- Caching & UserDefaults helpers: `references/CACHING_AND_USERDEFAULTS.md`
- Platform integrations (iOS/macOS): `references/INTEGRATIONS_IOS_MACOS.md`
- Repo map (where to change code/tests): `references/FILES.md`
- Tests guidance (existing tests + adding new): `references/TESTS.md`
- Troubleshooting: `references/TROUBLESHOOTING.md`
- Skill packaging notes: `references/CI_AND_PACKAGING.md`

Progressive disclosure (what to open when)
- If you’re changing behavior: open `references/FILES.md` first to locate the implementation + existing tests.
- If you’re writing usage/docs: open `references/EXAMPLES.md` first; then jump to the matching deep-dive reference file.
- If you’re debugging runtime issues: open `references/TROUBLESHOOTING.md`.
- If you need a quick symbol search: use `rg` with keywords listed at the top of each reference file.

Minimal expectations and conventions
- This repo is a Swift Package (Package.swift present) and targets macOS/iOS.
- Follow existing naming and API conventions in Sources/STFilePath.
- Tests live under Tests/STFilePathTests; add unit tests alongside related features.

Safety and change guidance
- Avoid breaking public APIs without tests and README updates.
- For platform-specific behavior (macOS vs iOS), include platform guards and run tests on macOS CI.

Packaging the skill
- To package this skill as a distributable `.skill`, zip the `.agent/skills/stfilepath` directory (see `references/CI_AND_PACKAGING.md`).

Contacts and maintenance
- When renaming or moving files, update references/FILES.md.
- Keep examples in references/EXAMPLES.md sync'd with README.md snippets.
