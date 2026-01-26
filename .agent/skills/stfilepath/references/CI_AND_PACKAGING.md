CI, build, and packaging notes

Build & Test
- Local: `swift build` and `swift test`
- CI: .github/workflows/swift.yml currently runs `swift build` and `swift test --enable-code-coverage` on macos-latest with Swift 6.0 in the matrix

Packaging the skill
- To distribute this skill as a .skill archive, create a zip of the skills/stfilepath directory and rename to `stfilepath.skill`.
- Ensure SKILL.md frontmatter is present and valid (name + description). The packaging can be automated with a small script:

```bash
zip -r stfilepath.skill skills/stfilepath
```

Publishing
- If publishing to an internal skill registry, follow that registry's packaging and metadata requirements.
