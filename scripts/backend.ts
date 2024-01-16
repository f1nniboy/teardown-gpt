// deno-lint-ignore-file no-explicit-any

import { ChatCompletionMessageParam } from "https://deno.land/x/openai@v4.24.7/resources/mod.ts";
import { parse as parseXML } from "https://deno.land/x/xml@2.1.3/mod.ts";
import OpenAI from "https://deno.land/x/openai@v4.24.7/mod.ts";

import dir from "https://deno.land/x/dir@1.5.2/mod.ts";
const HOME_DIR = dir("home")

import { load as loadEnv } from "https://deno.land/std@0.212.0/dotenv/mod.ts";
const env = await loadEnv();

interface OpenAIState {
	status: "idle" | "busy" | "done" | "fail";
	error?: string;
	func?: string;
	prompt?: string;
}

interface OpenAIRequest {
	content: string;
	done: boolean;
	id: string;
}

/* Path to the Teardown savegame, so we can check if a request was made */
const SAVEGAME_PATH = await getSavegamePath();

const API_DOCS = `
vector = table with 3 values, e.g. { 1, 2, 3 }
quaternion = table with 4 values
*_handle = integer

Vec(x, y, z): vector
VecCopy(orginal): vector
VecLength(vector): number
VecNormalize(vector): vector
VecScale(vector, scalar): vector
VecAdd(a, b): vector
VecSub(a, b): vector
VecDot(a, b): number
VecCross(a, b): vector
VecLerp(a, b, t): vector
Quat(x, y, z, w): quaternion
QuatCopy(orginal): quaternion
QuatEuler(x (0-360), y (0-360), z (0-360)): quaternion
GetQuatEuler(quaternion): number
QuatAxisAngle(axis, angle): quaternion
QuatLookAt(eye, target): quaternion
QuatSlerp(quatA, quatB, t): quaternion
QuatRotateQuat(quatA, quatB): quaternion
QuatRotateVec(quaternion, vector): vector
Transform(pos, rot): transform
TransformCopy(orginal): transform
TransformToParentTransform(relation, transform): transform
TransformToParentPoint(relation, position): vector
TransformToParentVec(relation, vector): vector
TransformToLocalTransform(relation, transform): transform
TransformToLocalPoint(relation, position): vector
TransformToLocalVec(relation, vector): vector
SetTag(entity, tag, value)
RemoveTag(entity, tag)
HasTag(entity, tag): boolean
ListTags(entity): table<string>
GetTagValue(entity, tag): string
GetDescription(entity): string
SetDescription(entity, description)
Delete(entity)
IsHandleValid(entity): boolean
GetEntityType(entity): entity_type
GetAllBodies(): table<body_handle>
GetBodyTransform(body): transform
SetBodyTransform(body, transform)
GetBodyMass(body): number
IsBodyDynamic(body): boolean
SetBodyDynamic(body, dynamic)
IsBodyActive(body): boolean
SetBodyActive(body, active)
GetBodyVelocity(body): vector
GetBodyVelocityAtPos(body, position): vector
GetBodyAngularVelocity(body): vector
ApplyBodyImpulse(body, position, impulse)
GetBodyShapes(body): table<shape_handle>
GetJointedBodies(body): table<body_handle>
GetBodyVehicle(body): vehicle_handle
GetBodyBounds(body): vector, vector
GetBodyCenterOfMass(body): vector (local space)
IsBodyVisible(body, max_distance, reject_transparent): boolean
IsBodyBroken(body): boolean
IsBodyJointedToStatic(body): boolean
GetBodyClosestPoint(body, origin): shape_handle
GetWorldBody(): body_handle
GetAllShapes(): table<shape_handle>
GetShapeLocalTransform(shape): transform
SetShapeLocalTransform(shape, transform)
GetShapeWorldTransform(shape): transform
GetShapeBody(shape): body_handle
GetShapeJoints(shape): table<joint_handle>
GetShapeLights(shape): table<light_handle>
GetShapeBounds(shape): vector
SetShapeEmissiveScale(shape, amount)
GetShapeMaterial(shape, index): number
GetShapeMaterialAtPosition(shape, position): integer
GetShapeMaterialAtIndex(shape, x, y, z): integer
GetShapeSize(shape): number
GetShapeVoxelCount(shape): number
IsShapeVisible(shape, max_distance, reject_transparent): boolean
IsShapeBroken(shape): boolean
SetShapeCollisionFilter(shape, layer, mask)
GetShapeClosestPoint(shape, origin): vector
IsShapeTouching(a, b): boolean
CreateShape(body, transform, reference_shape): shape_handle
ClearShape(shape)
ResizeShape(shape, xmi, ymi, zmi, xma, yma, zma): vector
SetShapeBody(shape, body, transform)
CopyShapeContent(source, destination)
CopyShapePalette(source, destination)
GetShapePalette(shape): table
SetBrush(type, size, index, object)
DrawShapeLine(shape, x0, y0, z0, x1, y1, z1, paint, noOverwrite)
DrawShapeBox(shape, x0, y0, z0, x1, y1, z1)
ExtrudeShape(shape, x, y, z, dx, dy, dz, steps, mode)
TrimShape(shape): vector
SplitShape(shape, removeResidual): table<shape_handle>
MergeShape(shape): shape_handle
FindLocation(tag, global): location_handle
FindLocations(tag, global): table<location_handle>
GetLocationTransform(location): transform
GetAllJoints(): table<joint_handle>
IsJointBroken(joint): boolean
GetJointType(joint): joint_type
GetJointOtherShape(joint, shape): shape_handle
GetJointShapes(joint): table<shape_handle>
SetJointMotor(joint, velocity, strength)
SetJointMotorTarget(joint, target, max_velocity, strength)
GetJointLimits(joint): number
GetJointMovement(joint): number
GetAllLights(): table<light_handle>
SetLightEnabled(light, enabled)
SetLightColor(light, red, green, blue)
SetLightIntensity(light, intensity)
GetLightTransform(light): transform
GetLightShape(light): shape_handle
IsLightActive(light): boolean
IsPointAffectedByLight(light, point): boolean
FindTrigger(tag, global): trigger_handle
FindTriggers(tag, global): table<trigger_handle>
GetTriggerTransform(trigger): transform
SetTriggerTransform(trigger, transform)
GetTriggerBounds(trigger): vector
IsPointInTrigger(trigger, point): boolean
IsBodyInTrigger(trigger, body): boolean
IsVehicleInTrigger(trigger, vehicle): boolean
IsShapeInTrigger(trigger, shape): boolean
IsTriggerEmpty(trigger, demolition): vector?
GetTriggerDistance(trigger, point): number
GetTriggerClosestPoint(trigger, point): vector
GetAllVehicles(): table<vehicle_handle>
GetVehicleTransform(vehicle): transform
GetVehicleBody(vehicle): body_handle
GetVehicleHealth(vehicle): number
GetVehicleDriverPos(vehicle): vector
DriveVehicle(vehicle, drive, steering, handbrake)
GetPlayerPos()
GetPlayerTransform(includePitch): transform
SetPlayerTransform(transform, includePitch)
GetPlayerCameraTransform(): transform
SetPlayerSpawnTransform(transform)
GetPlayerVelocity(): vector
GetPlayerVehicle(): vehicle_handle
SetPlayerVehicle(vehicle)
GetPlayerHealth(): number
SetPlayerHealth(health)
RespawnPlayer()
GetCameraTransform(): transform
RegisterTool(id, name, file, group)
QueryRequire(layers)
QueryRejectBody(body)
QueryRejectShape(shape)
QueryRejectVehicle(vehicle)
QueryRaycast(origin, direction, max_distance, radius, reject_transparent): shape_handle
QueryClosestPoint(origin, max_dist): shape_handle
QueryAabbShapes(lower_bound, upper_bound): shape_handle[]
QueryAabbBodies(lower_bound, upper_bound): body_handle[]
QueryClosestFire(origin, max_distance): vector
QueryAabbFireCount(lower_bound, upper_bound): number
RemoveAabbFires(lower_bound, upper_bound): number
GetLastSound(): vector
IsPointInWater(point): number
GetWindVelocity(point): vector
ChangeWeather(type)
Spawn(xml, transform, allow_static, joint_existing): entity_handle[]
GetTime(): number
GetTimeStep(): number
GetVersion(): string
HasVersion(version): boolean
Shoot(origin, direction, type, strength, max_distance)
Paint(origin, radius, type, probability)
MakeHole(position, soft_radius, medium_radius, hard_radius, silent): number
Explosion(position, size)
SpawnFire(position)
GetFireCount(): number
Menu()
SetPaused(state)
Notification(text)
`.trim();

/* OpenAI client, to make the requests to ChatGPT */
const client = new OpenAI({
	apiKey: env.OPENAI_API_KEY
});

/* ID of the current request */
let id: string | undefined = undefined;

/** Try to figure out where the savegame file is located. */
async function getSavegamePath() {
	const PATHS: Partial<Record<typeof Deno.build.os, string[]>> = {
		linux: [
			`${HOME_DIR}/.local/share/Steam/steamapps/compatdata/1167630/pfx/drive_c/users/steamuser/AppData/Local/Teardown/savegame.xml`,
			`${HOME_DIR}/.steam/steamapps/compatdata/1167630/pfx/drive_c/users/steamuser/AppData/Local/Teardown/savegame.xml`
		],

		/* TODO: Test */
		windows: [
			`${HOME_DIR}\\AppData\\Local\\Teardown\\savegame.xml`
		]
	}

	if (!PATHS[Deno.build.os]) throw new Error("Your OS is not supported");

	/* Paths to try, in order */
	for (const path of PATHS[Deno.build.os]!) {
		try {
			await Deno.stat(path);
			return path;
		} catch {
			continue;
		}
	}

	throw new Error("Savegame file couldn't be found");
}

/** Write to the temporary .lua script, to send information to Teardown. */
async function writeState(state: OpenAIState) {
	const data = `return { status = "${state.status}", prompt = ${state.prompt ? `"${state.prompt}"` : "nil"}, func = ${state.func ? `function()\n${state.func}\nend` : "nil"}, code = ${state.func ? `[[${state.func}]]` : "nil"}, error = ${state.error ? `[[${state.error}]]` : "nil"} }`;
	await Deno.writeFile("./_.lua", new TextEncoder().encode(data));
}

/** Parse the savegame XML file & extract the user's request, if applicable. */
async function getRequestData(): Promise<OpenAIRequest | null> {
	const content = new TextDecoder().decode(await Deno.readFile(SAVEGAME_PATH));

	/* Extract only the data for this mod specifically, to save some time */
	const lines = content.split("\n");
	const startIndex = lines.findIndex(l => l.includes(`<teargpt>`));
	const endIndex = lines.findIndex(l => l.includes(`</teargpt>`)) + 1;

	if (startIndex === -1 || endIndex === -1) return null;
	
	const part = lines.slice(startIndex, endIndex);
	if (part.length === 0) return null;

	const parsed = parseXML(part.join("\n")) as any;

	return {
		content: parsed.teargpt.request.content["@value"],
		id: parsed.teargpt.request.id["@value"].toString(),
		done: parsed.teargpt.request.done["@value"]
	};
}

/** Actually execute the chat request. */
async function executeRequest(data: OpenAIRequest) {
	const messages: ChatCompletionMessageParam[] = [
		{
			role: "system",
			content: `You are an AI assistant in the voxel destruction game Teardown. Your goal is to generate code fulfilling the user's request, which will then be executed in the game for a SINGLE tick. You must output the code without any other characters, simply reply with the *RAW* Lua code, and no other comments. Keep the code as small as possible. You can use Notification() to talk to the user indirectly. here are the rough API docs for the scripting API:\n${API_DOCS}`
		},

		{
			role: "user",
			content: data.content
		}
	];

	const response = await client.chat.completions.create({
		messages,

		model: "gpt-3.5-turbo",
		temperature: 0.4
	});

	const code = response.choices[0].message.content?.replaceAll("```", "")?.replaceAll("lua", "")?.trim() ?? undefined;
	return code;
}

console.log("Running!");

/* Watch the savegame file for changes. */
for await (const event of Deno.watchFs(SAVEGAME_PATH)) {
	if (event.kind == "modify") {
		try {
			const data = await getRequestData();

			if (data === null || !data.id || (data.id === id && !data.done)) continue;
			id = data.id;
			
			/* Once the request was consumed by the in-game script, we reset the temporary file */
			if (data.done) {
				await writeState({ status: "idle" });
				id = undefined;
				continue;
			}
		
			await writeState({ status: "busy" });

			const result = await executeRequest(data);
			await writeState({ status: "done", func: result, prompt: data.content });

		} catch (error) {
			await writeState({ status: "fail", error: error.toString() });
		}
	}
}