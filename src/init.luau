--!strict

local argparse = require("@pkg/argparse")
local configModule = require("@self/config")
local generateTestScript = require("@self/generateTestScript")
local process = require("@lune/process")
local runTestsCloud = require("@self/runner/runTestsCloud")
local runTestsOnce = require("@self/runner/runTestsOnce")
local runTestsServe = require("@self/runner/runTestsServe")
local sourcemap = require("@self/sourcemap")
local types = require("@self/runner/types")

type RunTarget = types.RunTarget
type RunTargetConfig = types.RunTargetConfig

local function parseArgs()
	local parser: any = argparse():name("test"):description("Run tests")

	parser:flag("--verbose", "Enable verbose output")
	parser:flag("--ci", "Run in CI mode")
	parser:option("--target", "Execution target: once, serve, or cloud (REQUIRED)")
	parser:option("--project", "Project name from jestir.toml to run tests for")
	parser:option("--test-name-pattern", "Pattern to match test names (regex)")
	parser:option("--test-path-pattern", "Pattern to match test file paths (regex)")
	parser:option("--universe-id", "Universe ID for cloud execution")
	parser:option("--place-id", "Place ID for cloud execution")
	parser:option("--place-version", "Place version for cloud execution (optional, uses latest if not specified)")
	parser:option("--api-key", "Roblox Open Cloud API key")
	parser:flag("--publish", "Publish the place before running tests (cloud only)")
	parser:option("--place", "Path to place file (for once target)")
	parser:option("--sourcemap", "Path to sourcemap.json")

	return parser:parse(process.args)
end

local function determineProjects(args, jestirConfig): ({ string }?, string?, string?)
	local projects: { string }? = nil
	local testPathPattern: string? = args.test_path_pattern
	local testNamePattern: string? = args.test_name_pattern

	if args.project then
		if not jestirConfig then
			error("jestir.toml not found. Cannot use --project flag without config file.")
		end

		local projectPath = configModule.getProjectPath(jestirConfig, args.project, sourcemap)
		if not projectPath then
			error(`Project "{args.project}" not found in jestir.toml`)
		end

		projects = { projectPath }
	else
		if jestirConfig then
			projects = configModule.getAllProjectPaths(jestirConfig, sourcemap)
		end
	end

	return projects, testPathPattern, testNamePattern
end

local function buildConfig(target: RunTarget, args, jestirConfig: any): RunTargetConfig
	if target == "cloud" then
		local apiKey: string? = args.api_key
		if not apiKey then
			apiKey = process.env.JESTIR_API_KEY
		end
		if not apiKey then
			error("API key required for --target cloud. Provide via --api-key flag or JESTIR_API_KEY environment variable")
		end

		local universeId: string? = args.universe_id
		if not universeId and jestirConfig and typeof(jestirConfig.cloud) == "table" and typeof(jestirConfig.cloud.universe_id) == "string" then
			universeId = jestirConfig.cloud.universe_id
		elseif not universeId and jestirConfig and typeof(jestirConfig.cloud) == "table" and typeof(jestirConfig.cloud.universe_id) == "number" then
			universeId = tostring(jestirConfig.cloud.universe_id)
		end
		if not universeId then
			error("Universe ID required for --target cloud. Provide via --universe-id flag or jestir.toml [cloud] section")
		end

		local placeId: string? = args.place_id
		if not placeId and jestirConfig and typeof(jestirConfig.cloud) == "table" and typeof(jestirConfig.cloud.place_id) == "string" then
			placeId = jestirConfig.cloud.place_id
		elseif not placeId and jestirConfig and typeof(jestirConfig.cloud) == "table" and typeof(jestirConfig.cloud.place_id) == "number" then
			placeId = tostring(jestirConfig.cloud.place_id)
		end
		if not placeId then
			error("Place ID required for --target cloud. Provide via --place-id flag or jestir.toml [cloud] section")
		end

		local placeVersion: string? = args.place_version
		if not placeVersion and jestirConfig and typeof(jestirConfig.cloud) == "table" and typeof(jestirConfig.cloud.place_version) == "string" then
			placeVersion = jestirConfig.cloud.place_version
		elseif not placeVersion and jestirConfig and typeof(jestirConfig.cloud) == "table" and typeof(jestirConfig.cloud.place_version) == "number" then
			placeVersion = tostring(jestirConfig.cloud.place_version)
		end

		local publish: boolean? = args.publish
		if publish == nil and jestirConfig and typeof(jestirConfig.cloud) == "table" and typeof(jestirConfig.cloud.publish) == "boolean" then
			publish = jestirConfig.cloud.publish
		end

		return {
			target = "cloud" :: "cloud",
			universeId = universeId,
			placeId = placeId,
			placeVersion = placeVersion,
			apiKey = apiKey,
			publish = publish,
		}
	elseif target == "once" then
		local placePath: string
		if typeof(args.place) == "string" then
			placePath = args.place
		elseif jestirConfig and typeof(jestirConfig.once) == "table" and typeof(jestirConfig.once.place_file) == "string" then
			placePath = jestirConfig.once.place_file
		else
			error("Place file path required for --target once. Provide via --place flag or jestir.toml [once] section")
		end

		local sourcemapPath: string? = if typeof(args.sourcemap) == "string" then args.sourcemap else "sourcemap.json"

		return {
			target = "once",
			placePath = placePath,
			sourcemapPath = sourcemapPath,
		}
	else
		local sourcemapPath: string? = if typeof(args.sourcemap) == "string" then args.sourcemap else "sourcemap.json"

		return {
			target = "serve",
			sourcemapPath = sourcemapPath,
		}
	end
end

local function main(): number
	local args = parseArgs()

	if not args.target then
		error("--target is required. Must be one of: once, serve, cloud")
	end

	local target: RunTarget = args.target
	if target ~= "once" and target ~= "serve" and target ~= "cloud" then
		error(`Invalid target "{target}". Must be one of: once, serve, cloud`)
	end

	local jestirConfig = configModule.loadConfig()
	local projects, testPathPattern, testNamePattern = determineProjects(args, jestirConfig)
	local config = buildConfig(target, args, jestirConfig)
	local scriptContent = generateTestScript({
		verbose = args.verbose or false,
		ci = args.ci or false,
		projects = projects,
		testNamePattern = testNamePattern,
		testPathPattern = testPathPattern,
	})

	local exitCode: number
	if config.target == "cloud" then
		exitCode = runTestsCloud(scriptContent, config)
	elseif config.target == "once" then
		exitCode = runTestsOnce(scriptContent, config)
	else
		exitCode = runTestsServe(scriptContent, config)
	end

	return exitCode
end

process.exit(main())
