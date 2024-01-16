--[[
#include "request.lua"
#include "api.lua"
]]--

---@class notif
---@field scale number
---@field time number
---@field text string|nil
notif = {
	scale = 0,
	time = 0,
	text = nil
}

---@class error
---@field message string|nil
error = nil

function drawButton(width, height, label, alpha)
	alpha = alpha or 1

	UiButtonImageBox("ui/common/box-solid-6.png", 6, 6, 1, 1, 1, alpha)
	UiColor(0, 0, 0)

	return UiTextButton(label, width, height)
end

function notify(text)
	SetValueInTable(notif, "scale", 1, "cosine", 0.2)
	UiSound("MOD/snd/vibrate-short.ogg")

	notif.text = text
	notif.time = 0
end

function init()
	buffer = ""
end

function draw(dt)
	local interactive = GetPlayerScreen() ~= 0
	local canGenerate = #buffer > 0

	local state = GetResponseState()
	local padding = 40

	if notif.scale == 1 and notif.time > 5 then SetValueInTable(notif, "scale", 0, "cosine", 0.2) end
	if notif.scale > 0 then notif.time = notif.time + dt end

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

	-- Input UI
	if error == nil then
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
				UiRect(350, 48)
				UiColor(1, 1, 1)

				if not canGenerate then
					UiDisableInput()
				end

				if drawButton(300, 70, "Generate", canGenerate and 1 or 0.5) or InputPressed("return") then
					UiSound("MOD/snd/button-beep.ogg")
					GenerateResponse({ content = buffer })
				end
			UiPop()

		-- Loading screen
		elseif state.status == "busy" then
			UiPush()
				UiTranslate(UiCenter(), UiMiddle())
				UiRotate((GetTime() % 1) * 360)
				UiImage("MOD/img/circle.png")
			UiPop()
		end

	-- Error message
	else
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

	-- Notification
	if notif.scale > 0 then
		UiPush()
			local scale = math.max(0, math.min(1, 1 - (notif.time / 0.5)))
			local width = UiGetTextSize(notif.text)

			UiTranslate(UiCenter() + math.sin(notif.time * 500) * scale * 10, -30 + (30 + padding * 1.5) * notif.scale)

			UiColorFilter(1, 1, 1)
			UiImageBox("ui/common/box-solid-6.png", width + 10 * 2, 60, 6, 6)

			UiColor(0, 0, 0)
			UiText(notif.text)
		UiPop()
	end

	-- Raster
	UiPush()
		UiColor(1, 1, 1, 0.5)
		UiScale(4)
		UiImage("MOD/img/raster.png")
	UiPop()
end
