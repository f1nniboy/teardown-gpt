---@class openai_message
---@field content string

---@class openai_state
---@field status "idle"|"busy"|"fail"|"done"
---@field error string|nil
---@field func function|nil

--- Name of the mod, can vary
local MOD_NAME = "local-teargpt"

---Generate a response using OpenAI to the input messages asynchronously.
---@param message openai_message
function GenerateResponse(message)
	ClearKey("savegame.mod.request")

	SetString("savegame.mod.request.id", tostring(math.random()))
	SetString("savegame.mod.request.content", message.content)
	SetBool("savegame.mod.request.done", false)
end

---Get the status of the currently running request, if applicable.
---@return openai_state
function GetResponseState()
	local path = GetString("mods.available." .. MOD_NAME .. ".path") .. "/_.lua"

	if not HasFile("RAW:" .. path) or not HasKey("savegame.mod.request") or GetBool("savegame.mod.request.done") then
		return { status = "idle" }
	end

	local func, error = loadfile(path, "t")

	if func ~= nil and error == nil then
		local response = func()

		if response.status == "done" or response.status == "fail" then
			SetBool("savegame.mod.request.done", true)
		end

		return response
	else
		SetBool("savegame.mod.request.done", true)
		return { status = "fail", error = error }
	end
end

---@param state openai_state
---@return boolean success
---@return string|nil error
function ExecuteResponse(state)
	local success, error = pcall(state.func)
	return success, error
end