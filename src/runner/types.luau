--!strict

export type RunTarget = "cloud" | "once" | "serve"

export type CloudConfig = {
	target: "cloud",
	universeId: string,
	placeId: string,
	placeVersion: string?,
	apiKey: string,
	publish: boolean?,
}

export type OnceConfig = {
	target: "once",
	placePath: string,
	sourcemapPath: string?,
}

export type ServeConfig = {
	target: "serve",
	sourcemapPath: string?,
}

export type RunTargetConfig = CloudConfig | OnceConfig | ServeConfig

return nil
