---@class request_message
---@field content string

---@class request_state
---@field status "idle"|"busy"|"fail"|"done"
---@field error string|nil
---@field func function|nil
---@field code string|nil
---@field prompt string|nil

--- Name of the mod, can vary
MOD_NAME = "local-teargpt"

--- Where to save the current request in the registry
REGISTRY_PATH = "savegame.mod.teargpt"

---Generate a response using OpenAI to the input messages asynchronously.
---@param message request_message
function GenerateResponse(message)
	ClearKey(REGISTRY_PATH .. ".request")

	SetString(REGISTRY_PATH .. ".request.id", tostring(math.random()))
	SetString(REGISTRY_PATH .. ".request.content", message.content)
	SetBool(REGISTRY_PATH .. ".request.done", false)
end

---Get the status of the currently running request, if applicable.
---@return request_state
function GetResponseState()
	local path = GetString("mods.available." .. MOD_NAME .. ".path") .. "/_.lua"

	if not HasFile("RAW:" .. path) or not HasKey(REGISTRY_PATH .. ".request") or GetBool(REGISTRY_PATH .. ".request.done") then
		return { status = "idle" }
	end

	local func, error = loadfile(path, "t")

	if func ~= nil and error == nil then
		---@type request_state
		local response = func()

		if response.status == "done" or response.status == "fail" then
			SetBool(REGISTRY_PATH .. ".request.done", true)
		end

		-- Save the request & response to the history
		if response.status == "done" then
			local index = #ListKeys(REGISTRY_PATH .. ".history") + 1
			local registryPath = REGISTRY_PATH .. ".history." .. index .. "."

			SetString(registryPath .. "prompt", response.prompt)
			SetString(registryPath .. "code", response.code)
		end

		return response
	else
		SetBool(REGISTRY_PATH .. ".done", true)
		return { status = "fail", error = error }
	end
end

---@param state request_state
---@return boolean success
---@return string|nil error
function ExecuteResponse(state)
	local success, error = pcall(state.func)
	return success, error
end