Testing guidance and suggested unit tests

Run existing tests:
- `swift test`

Suggested small unit tests to add (place under Tests/STFilePathTests)

1) Basic CRUD test
- Create folder, create file with known contents, read back, append, move, delete. Assert contents and existence at each step.

2) Hashing test
- Write a small file with known bytes and assert SHA256 matches expected value.

3) Watcher integration test (flaky — mark as integration)
- Start watcher on a temp folder, create a file, assert watcher reports create event. Run with retry/timeout.

4) DownloadableFile codable test
- Use DFAnyFile with an in-repo test file and test fetch() and save() for a Codable struct.

Notes on flaky tests
- Watcher tests can be timing-sensitive. Use small timeouts and retries and mark them as integration or provide environment variable to skip on slow CI.
