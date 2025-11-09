local net = require("@lune/net")
local serde = require("@lune/serde")

local createSpinner = require("./createSpinner")
local richPrint = require("./richPrint")

local BASE_URL = "https://apis.roblox.com"

export type PublishPlaceOptions = {
	universeId: number,
	placeId: number,
	apiKey: string,
}

local function publishPlaceAsync(options: PublishPlaceOptions): (boolean, number?)
	local universeId = options.universeId
	local placeId = options.placeId
	local apiKey = options.apiKey

	local spinner = createSpinner()
	spinner.setText("Publishing place...")
	spinner.start()

	local res = net.request({
		url = `{BASE_URL}/universes/v1/{universeId}/places/{placeId}/versions?versionType=Published`,
		method = "POST",
		headers = {
			["x-api-key"] = apiKey,
			["Content-Type"] = "application/json",
			["Accept"] = "application/json",
			["User-Agent"] = "jestir/1.0.0",
		},
	})

	spinner.stop()

	if res.ok then
		local decodedBody = serde.decode("json", res.body)
		local versionNumber = decodedBody.versionNumber
		richPrint("green", "bold", `Place published successfully (version {versionNumber})`)
		return true, versionNumber
	else
		richPrint("red", "bold", `Failed to publish place ({res.statusMessage})`)
		print("Response body:")
		print(res.body)
		return false, nil
	end
end

return publishPlaceAsync
