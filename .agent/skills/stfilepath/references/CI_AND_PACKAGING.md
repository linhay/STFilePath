CI, build, and packaging notes

Use cases
1) 本地验证（构建 + 测试）
```bash
swift build
swift test
```

2) 只跑 watcher 相关测试（定位 flake/hang）
```bash
swift test --filter STFilePathTests.STFolderWatcherTests --filter STFilePathTests.STWatcherTests
```

3) 打包 skill（生成 `stfilepath.skill`）
```bash
zip -r stfilepath.skill .agent/skills/stfilepath
```

Build & Test
- Local: `swift build` and `swift test`
- CI: .github/workflows/swift.yml currently runs `swift build` and `swift test --enable-code-coverage` on macos-latest with Swift 6.0 in the matrix

Packaging the skill
- To distribute this skill as a `.skill` archive, create a zip of the `.agent/skills/stfilepath` directory and rename to `stfilepath.skill`.
- Ensure SKILL.md frontmatter is present and valid (name + description). The packaging can be automated with a small script:

```bash
zip -r stfilepath.skill .agent/skills/stfilepath
```

Publishing
- If publishing to an internal skill registry, follow that registry's packaging and metadata requirements.
