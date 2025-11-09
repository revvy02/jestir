--!strict

local fs = require("@lune/fs")
local process = require("@lune/process")
local types = require("./types")

type OnceConfig = types.OnceConfig

local TEMP_DIR = ".jestir"

local function runTestsOnce(scriptContent: string, config: OnceConfig): number
	local placePath = config.placePath

	if not fs.isFile(placePath) then
		error(`Place file not found at path: {placePath}`)
	end

	if not fs.isDir(TEMP_DIR) then
		fs.writeDir(TEMP_DIR)
	end

	local timestamp = os.time()
	local tempPlaceName = `test-{timestamp}.rbxl`
	local tempPlacePath = `{TEMP_DIR}/{tempPlaceName}`
	local placeContent = fs.readFile(placePath)
	fs.writeFile(tempPlacePath, placeContent)

	local tempScriptPath = "temp_test_runner.luau"
	fs.writeFile(tempScriptPath, scriptContent)

	local result = process.exec("rir3", {
		"once",
		tempScriptPath,
		"--place",
		tempPlacePath,
	}, {
		stdio = "forward",
	})

	if fs.isFile(tempScriptPath) then
		fs.removeFile(tempScriptPath)
	end
	if fs.isFile(tempPlacePath) then
		fs.removeFile(tempPlacePath)
	end

	return result.code
end

return runTestsOnce
