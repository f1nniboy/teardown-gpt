--[[
#include "script/common.lua"
]]--

interactive = false
interactiveScale = 0
interactiveTransform = Transform()
toolTransform = Transform()
pullBack = 0

function init()
	RegisterTool("ai", "Cellphone", "MOD/vox/cellphone-stub.vox", 2)

	SetBool("game.tool.ai.enabled", true)
	SetString("game.tool.ai.ammo.display", "")

	-- Spawn the actual phone model, with the screen
	entities = Spawn("MOD/prefab/cellphone.xml", Transform(Vec(0, -10, 0)), true)

	phoneBody = entities[1]
	phoneScreen = entities[3]
end

function tick()
	local selected = GetString("game.player.tool") == "ai"
	local fovScale = GetInt("options.gfx.fov") / 90

	if selected or interactive then
		SetToolTransform(Transform(Vec(0.6, -0.7, -1)))

		if GetBool("game.player.canusetool") and InputPressed("usetool") and not interactive and GetPlayerScreen() ~= phoneScreen then
			SetValue("interactiveScale", 1, "cosine", 0.35)
			SetPlayerScreen(phoneScreen)

			interactive = true

		elseif interactive and (GetPlayerScreen() ~= phoneScreen or (InputPressed("rmb") or InputPressed("esc")) or GetPlayerVehicle() ~= 0) then
			SetValue("interactiveScale", 0, "bounce", 0.6)
			SetPlayerScreen(0)

			interactive = false
		end

		interactiveTransform = TransformToParentTransform(GetPlayerCameraTransform(), Transform(Vec(0.0, -0.28, -0.2 / fovScale), QuatEuler(-15, -2, -2)))

		local t = Transform(
			VecLerp(toolTransform.pos, interactiveTransform.pos, interactiveScale),
			QuatSlerp(toolTransform.rot, interactiveTransform.rot, interactiveScale)
		)

		SetBodyTransform(phoneBody, t)
	end

	if selected and interactive then
		SetBool("game.player.disableinput", true)
	end

	if selected and not interactive then
		local body = GetToolBody()
		local shapes = GetBodyShapes(body)

		for i = 1, #shapes do
			SetTag(shapes[i], "invisible")
		end

		toolTransform = GetBodyTransform(body)
	end

	if not selected and not interactive then
		SetBodyTransform(phoneBody, Transform(Vec(0, -10, 0)))
	end
end