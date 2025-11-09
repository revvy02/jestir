--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local types = require("./types")

type ServeConfig = types.ServeConfig

local function writeScriptToTempFile(scriptContent: string): string
	local tempPath = `/tmp/jestir-script-{os.time()}.luau`
	fs.writeFile(tempPath, scriptContent)
	return tempPath
end

local function runTestsServe(scriptContent: string, config: ServeConfig): number
	local scriptPath = writeScriptToTempFile(scriptContent)

	local args = { "exec", scriptPath }

	if config.sourcemapPath then
		table.insert(args, "--sourcemap")
		table.insert(args, config.sourcemapPath)
	end

	local result = process.exec("rir3", args, {
		stdio = "forward",
	})

	if fs.isFile(scriptPath) then
		fs.removeFile(scriptPath)
	end

	return result.code
end

return runTestsServe
