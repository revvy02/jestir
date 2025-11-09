# jestir

Test runner for Roblox projects using Jest.

## Features

- Run tests in Roblox Studio via `rir3 once` (one-time execution)
- Run tests in Roblox Studio via `rir3 serve/exec` (persistent connection)
- Run tests in Roblox Cloud via Open Cloud API
- Filter tests by name or path patterns
- Support for multiple project configurations
- Configuration via `jestir.toml` and environment variables

## Usage

Jestir requires an explicit `--target` flag to specify how tests should be executed.

### Targets

#### `--target once`
Clones the place file to `.jestir/` temp directory and runs tests via `rir3 once`.
Always opens a fresh Studio instance. **Note:** You must build/maintain the place file yourself - jestir does not build it.

```bash
# Run all tests via rir3 once
jestir --target once

# Run with test filtering
jestir --target once --test-name-pattern "async" --project shared

# Specify custom place file
jestir --target once --place my-test.rbxl
```

#### `--target serve`
Assumes `rir3 serve` is already running and connected. Uses `rir3 exec` to run tests in the connected Studio instance. Does not build or clone place files.

```bash
# Run all tests via rir3 exec
jestir --target serve

# Run specific tests
jestir --target serve --test-path-pattern "use_async"
```

#### `--target cloud`
Runs tests in Roblox Cloud using the Open Cloud Luau Execution API. Requires universe ID, place ID, place version, and API key.

```bash
# Run tests in cloud (using jestir.toml config)
jestir --target cloud

# Publish and run tests in cloud (uses latest published version)
jestir --target cloud --publish

# Override config with CLI flags
jestir --target cloud --universe-id <id> --place-id <id> --place-version <version> --api-key <key>

# Run specific project in cloud
jestir --target cloud --project shared
```

**Cloud Configuration:**
- API key: `--api-key` flag or `JESTIR_API_KEY` environment variable
- Universe ID: `--universe-id` flag or `jestir.toml` `[cloud]` section
- Place ID: `--place-id` flag or `jestir.toml` `[cloud]` section
- Place Version: `--place-version` flag or `jestir.toml` `[cloud]` section (optional if `--publish` is used)
- Publish: `--publish` flag or `jestir.toml` `[cloud]` section (publishes place before running tests)

### Filtering Tests

```bash
# Filter by test name (matches test descriptions)
jestir --target once --test-name-pattern "should handle errors"

# Filter by test file path
jestir --target serve --test-path-pattern "use_async"

# Combine filters
jestir --target once --test-name-pattern "user" --test-path-pattern "auth"
```

### Project Configuration

Create a `jestir.toml` file in your project root:

```toml
[once]
place_file = "test.rbxl"

[cloud]
place_id = 72824109308551
universe_id = 8612861022
place_version = 51
publish = false

[projects]
shared = "src/shared"
client = "src/client"
server = "src/server"
hooks = "src/client/app/hooks"
```

**Configuration Details:**
- `[once].place_file`: Path to your built place file for `--target once`
- `[cloud].place_id`: Roblox place ID for cloud execution
- `[cloud].universe_id`: Roblox universe ID for cloud execution
- `[cloud].place_version`: Specific place version to run tests against (optional if publish is true)
- `[cloud].publish`: Publish the place before running tests (default: false)
- `[projects]`: Named project paths that can be referenced with `--project` flag

**Environment Variables:**
- `JESTIR_API_KEY`: Roblox Open Cloud API key (alternative to `--api-key` flag)

Then use project names to run specific projects:

```bash
jestir --target once --project shared
```

### Examples

```bash
# Run all tests via rir3 once
jestir --target once

# Run tests in serve mode
jestir --target serve

# Run tests in cloud (using jestir.toml)
jestir --target cloud

# Publish place and run tests in cloud
jestir --target cloud --publish

# Run specific project
jestir --target serve --project shared

# Filter by test name
jestir --target once --test-name-pattern "async"

# Filter by file path
jestir --target serve --test-path-pattern "use_async"

# Verbose output
jestir --target once --verbose

# CI mode
jestir --target cloud --ci
```

