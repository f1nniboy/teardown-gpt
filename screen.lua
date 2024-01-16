--[[
#include "request.lua"
#include "api.lua"
]]--

---@class error
---@field message string|nil
error = nil

---@class history
---@field open boolean
---Which request is open, nil if player is in overview
---@field key string|nil
history = {
	open = false,
	request = nil
}

function drawButton(width, height, label, alpha)
	alpha = alpha or 1

	UiButtonImageBox("ui/common/box-solid-6.png", 6, 6, 1, 1, 1, alpha)
	UiColor(0, 0, 0)

	return UiTextButton(label, width, height)
end

function init()
	buffer = ""
end

function draw(dt)
	local interactive = GetPlayerScreen() ~= 0
	local state = GetResponseState()

	local hasHistory = #ListKeys(REGISTRY_PATH .. ".history") > 0
	local canGenerate = #buffer > 0

	-- Parsing the temporary Lua file parsed
	if state.status == "fail" then
		error = { message = state.error }
	end

	if state.status == "done" then
		local success, err = ExecuteResponse(state)
		UiSound("MOD/snd/vibrate-short.ogg")

		if success then
			buffer = ""
		elseif err ~= nil then
			error = { message = err }
		end
	end

	UiColorFilter(0.43, 0.87, 0.87)
	UiColor(1, 1, 1)

	UiFont("font/pixeloid.ttf", 48)
	UiAlign("middle center")

	-- History
	if history.open and not history.key then
		UiPush()
			local size = 520

			UiTranslate(UiCenter(), UiMiddle())
			UiImageBox("ui/common/box-outline-6.png", size + 30, size, 12, 12)

			-- Title
			UiPush()
				UiTranslate(0, -size / 2)
				UiColor(0, 0, 0)
				UiRect(220, 48)
				UiColor(1, 1, 1)
				UiText("HISTORY")
			UiPop()

			-- Entries
			UiPush()
				UiAlign("left middle")
				UiButtonImageBox("ui/common/box-solid-6.png", 6, 6, 1, 1, 1, 1)
				UiColor(0, 0, 0)
				UiFont("font/pixeloid.ttf", 38)

				local length = #ListKeys(REGISTRY_PATH .. ".history")
				local maxLength = 6

				for i = math.max(1, length - maxLength), length do
					local path = REGISTRY_PATH .. ".history." .. i .. "."
					local prompt = GetString(path .. "prompt")

					if #prompt > 25 then
						prompt = prompt:sub(0, 25) .. "..."
					end

					UiPush()
						UiTranslate(-size / 2, -size / 2 + 18 + 60 * (i - length + maxLength + 1))
						UiFont("font/pixeloid.ttf", 26)

						-- View code
						if UiTextButton(prompt, size, 50) then
							UiSound("MOD/snd/button-beep.ogg")
							history.key = tostring(i)
						end
					UiPop()
				end
			UiPop()

			-- Back button
			UiPush()
				UiTranslate(0, size / 2)
				UiColor(0, 0, 0)
				UiRect(215, 48)
				UiColor(1, 1, 1)

				UiFont("font/pixeloid.ttf", 38)

				if drawButton(190, 50, "Back") then
					UiSound("MOD/snd/button-beep.ogg")
					history.open = false
				end
			UiPop()
		UiPop()

	elseif history.open and history.key then
		UiPush()
			local path = REGISTRY_PATH .. ".history." .. history.key .. "."
			local size = 520

			UiTranslate(UiCenter(), UiMiddle())
			UiImageBox("ui/common/box-outline-6.png", size + 30, size, 12, 12)

			-- Title
			UiPush()
				UiTranslate(0, -size / 2)
				UiColor(0, 0, 0)
				UiRect(170, 48)
				UiColor(1, 1, 1)
				UiText("CODE")
			UiPop()

			-- Code
			UiPush()
				UiFont("font/pixeloid.ttf", 26)
				UiAlign("left top")
				UiTranslate(-size / 2 + 23, -size / 2 + 28)
				UiWordWrap(size - 45)
				UiText(GetString(path .. "code"))
			UiPop()

			-- Back button
			UiPush()
				UiTranslate(0, size / 2)
				UiColor(0, 0, 0)
				UiRect(215, 48)
				UiColor(1, 1, 1)

				UiFont("font/pixeloid.ttf", 38)

				if drawButton(190, 50, "Back") then
					UiSound("MOD/snd/button-beep.ogg")
					history.key = nil
				end
			UiPop()
		UiPop()
	end

	-- Input UI
	if error == nil and not history.open then
		if state.status == "idle" then
			local size = 520

			UiTranslate(UiCenter(), UiMiddle())
			UiImageBox("ui/common/box-outline-6.png", size + 30, size, 12, 12)

			-- Icon
			UiPush()
				UiTranslate(0, -size / 2)
				UiColor(0, 0, 0)
				UiRect(170, 48)
				UiColor(1, 1, 1)
				UiImage("MOD/img/icon.png")
			UiPop()

			-- Input box
			UiPush()
				local width = 450

				UiWordWrap(width - 20)
				UiFont("font/pixeloid.ttf", 38)

				UiPush()
					local display = buffer

					if #buffer == 0 then
						UiAlign("center middle")
						display = "..."
					else
						UiAlign("left middle")
						UiTranslate(-width / 2, 0)
					end

					local textWidth, textHeight = UiText(display)

					textHeight = math.max(60, textHeight)
					textWidth = math.max(width, textWidth)
				UiPop()

				UiColor(1, 1, 1, 0.8)
				UiImageBox("ui/common/box-outline-7.png", textWidth + 10 * 2, textHeight + 10 * 2, 12, 12)

				if interactive and state.status == "idle" then
					UiTranslate(1000, 1000)

					local temp = UiTextInput(buffer, width, 50, "")
					textWidth, textHeight = UiGetTextSize(temp)

					if textHeight < 400 or #temp < #buffer then
						buffer = temp
					end
				end
			UiPop()

			-- Generate button
			UiPush()
				UiTranslate(0, size / 2)

				UiColor(0, 0, 0)
				UiRect(440, 48)
				UiColor(1, 1, 1)

				if not canGenerate then
					UiDisableInput()
				end

				UiAlign("left middle")
				UiTranslate(-size / 2 + 50)

				if drawButton(300, 70, "Generate", canGenerate and 1 or 0.5) or InputPressed("return") then
					UiSound("MOD/snd/button-beep.ogg")
					GenerateResponse({ content = buffer })
				end
			UiPop()

			-- History button
			UiPush()
				UiAlign("right middle")
				UiTranslate(size / 2 - 50, size / 2)

				UiButtonImageBox("ui/common/box-solid-6.png", 6, 6, 1, 1, 1, hasHistory and 1 or 0.5)
				if not hasHistory then UiDisableInput() end

				if UiTextButton("", 70, 70) then
					UiSound("MOD/snd/button-beep.ogg")
					history.open = true
				end

				UiTranslate(-35)
				UiAlign("center middle")
				UiImage("MOD/img/history.png")
			UiPop()

		-- Loading screen
		elseif state.status == "busy" then
			UiPush()
				UiTranslate(UiCenter(), UiMiddle())
				UiRotate((GetTime() % 1) * 360)
				UiImage("MOD/img/circle.png")
			UiPop()
		end
	end

	-- Error message
	if error ~= nil then
		UiPush()
			local size = 510

			UiTranslate(UiCenter(), UiMiddle())
			UiImageBox("ui/common/box-outline-6.png", size, size, 12, 12)

			-- Title
			UiPush()
				UiTranslate(0, -size / 2)
				UiColor(0, 0, 0)
				UiRect(170, 48)
				UiColor(1, 1, 1)
				UiText("ERROR")
			UiPop()

			-- Message
			UiPush()
				UiFont("font/pixeloid.ttf", 32)
				UiAlign("left top")
				UiTranslate(-size / 2 + 23, -size / 2 + 28)
				UiWordWrap(size - 45)
				UiText(error.message)
			UiPop()

			-- Close button
			UiPush()
				UiTranslate(0, size / 2)
				UiColor(0, 0, 0)
				UiRect(215, 48)
				UiColor(1, 1, 1)

				UiFont("font/pixeloid.ttf", 38)

				if drawButton(190, 50, "Close") then
					UiSound("MOD/snd/button-beep.ogg")
					error = nil
				end
			UiPop()
		UiPop()
	end

	-- Raster
	UiPush()
		UiColor(1, 1, 1, 0.5)
		UiScale(4)
		UiImage("MOD/img/raster.png")
	UiPop()
end
