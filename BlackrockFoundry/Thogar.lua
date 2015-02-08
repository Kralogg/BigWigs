
--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Operator Thogar", 988, 1147)
if not mod then return end
mod:RegisterEnableMob(76906, 80791) -- Operator Thogar, Grom'kar Man-at-Arms
mod.engageId = 1692

--------------------------------------------------------------------------------
-- Locals
--

local bombTargets = {}
local engageTime = 0
-- times are for when the train is about to enter the room, ~5s after the door opens
--[[
	17 4
	27 2
	32 1
	47 3
	52 4
	77 2
	82 3
	107 1
	122 2&3
	162 1&4
	172 1
	187 2
	197 4
	217 3
	227 2
	237 1
	252 2&4
	272 1
	277 3
	307 1&4
	317 2
	342 2
	372 2&3
	387 4
	407 1
	417 1&4
	433 2
	442 3
	459 2&3
	467 4
]]
local trainData = {
	-- heroic data, covers 7:46 of the fight
	[1] = {
		{ 32, "adds_train"},
		{107, "train"},
		{162, "train"},
		{172, "cannon_train"},
		{237, "train"},
		{272, "train"},
		{307, "cannon_train", 4},
		{407, "train"},
		{417, "cannon_train", 4},
	},
	[2] = {
		{ 27, "train"},
		{ 77, "train"},
		{122, "adds_train", 3},
		{187, "train"},
		{227, "train"},
		{252, "big_add_train", 4},
		{317, "train"},
		{342, "train"},
		{372, "adds_train", 3},
		{433, "train"},
		{457, "train"},
		{459, "big_add_train", 3},
	},
	[3] = {
		{ 47, "train"},
		{ 82, "big_add_train"},
		{122, "adds_train", 2},
		{217, "train"},
		{277, "train"},
		{372, "big_add_train", 2},
		{442, "train"},
		{459, "big_add_train", 2},
	},
	[4] = {
		{ 17, "train"},
		{ 52, "cannon_train"},
		{162, "train"},
		{197, "adds_train"},
		{252, "cannon_train", 2},
		{307, "cannon_train", 1},
		{387, "train"},
		{417, "adds_train", 1},
		{467, "train"},
	},
}

local trainDataMythic = {
	-- covers 3min of the fight
	[1] = {
		{ 18, "deforester"},
		{ 62, "random"},
		{ 78, "cannon_train", 4},
		{158, "train"},
		{173, "random"},
		{194, "random"},
	},
	[2] = {
		{ 23, "train"},
		{ 62, "random"},
		{ 83, "train"},
		{113, "train"},
		{133, "adds_train", 3},
		{173, "random"},
		{194, "random"},
	},
	[3] = {
		{ 37, "train"},
		{ 62, "random"},
		{ 98, "train"},
		{133, "adds_train", 2},
		{173, "random"},
		{194, "random"},
	},
	[4] = {
		{ 12, "big_add_train"},
		{ 62, "random"},
		{ 78, "cannon_train", 1},
		{158, "train"},
		{173, "random"},
		{194, "random"},
	},
}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.custom_off_firemender_marker = "Grom'kar Firemender marker"
	L.custom_off_firemender_marker_desc = "Marks Firemenders with {rt1}{rt2}, requires promoted or leader.\n|cFFFF0000Only 1 person in the raid should have this enabled to prevent marking conflicts.|r\n|cFFADFF2FTIP: If the raid has chosen you to turn this on, quickly mousing over the mobs is the fastest way to mark them.|r"
	L.custom_off_firemender_marker_icon = 1

	-- XXX suggest marking lanes using star, circle, diamond, triangle? could put the the charm in the bar and message to help identify
	L.trains = "Train warnings"
	L.trains_desc = "Shows timers and messages for each lane for when the next train is coming. Lanes are numbered from the boss to the entrace, ie, Boss 1 2 3 4 Entrance."
	L.trains_icon = "achievement_dungeon_blackrockdepot"

	L.lane = "Lane %s: %s"
	L.train = "Train"
	L.train_icon = "achievement_dungeon_blackrockdepot" -- chooo chooooo
	L.adds_train = "Adds train"
	L.adds_train_icon = "warrior_talent_icon_furyintheblood" -- angry orc face
	L.big_add_train = "Big add train"
	L.big_add_train_icon = "warrior_talent_icon_skirmisher" -- one dude standing alone
	L.cannon_train = "Cannon train"
	L.cannon_train_icon = "ability_vehicle_siegeenginecannon" -- cannon ball
	L.deforester = -10329 -- Deforester
	L.deforester_icon = "spell_shaman_lavasurge"
	L.random = "Random trains"
	L.random_icon = "ability_foundryraid_traindeath"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		--[[ Mythic ]]--
		--156494,
		--164380,
		--[[ Reinforcements ]]--
		163753, -- Iron Bellow
		160140, -- Cauterizing Bolt
		{159481, "ICON", "FLASH", "SAY"}, -- Delayed Siege Bomb
		--"custom_off_firemender_marker",
		--[[ General ]]--
		{155921, "TANK"}, -- Enkindle
		{155864, "FLASH"}, -- Prototype Pulse Grenade
		{"trains", "FLASH"},
		"bosskill",
	}, {
		--[156494] = "mythic",
		[163753] = -9537, -- Reinforcements
		[155921] = "general",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Enkindle", 155921)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Enkindle", 155921)
	self:Log("SPELL_CAST_SUCCESS", "PulseGrenade", 155864)
	self:Log("SPELL_AURA_APPLIED", "PulseGrenadeDamage", 165195)
	self:Log("SPELL_AURA_APPLIED_DOSE", "PulseGrenadeDamage", 165195)
	self:Log("SPELL_CAST_START", "IronBellow", 163753)
	self:Log("SPELL_CAST_START", "CauterizingBolt", 160140)
	self:Log("SPELL_AURA_APPLIED", "DelayedSiegeBomb", 159481)
	self:Log("SPELL_AURA_REMOVED", "DelayedSiegeBombRemoved", 159481)
	-- Mythic
	--self:Log("SPELL_AURA_APPLIED", "ObliterationDamage", 156494)
	--self:Log("SPELL_AURA_APPLIED_DOSE", "ObliterationDamage", 156494)

	self:Death("Deaths", 80791) -- Grom'kar Man-at-Arms
end

function mod:OnEngage()
	wipe(bombTargets)
	self:CDBar(155864, 6, 135592, 155864) -- Pulse Grenade, 135592 = "Grenade"
	self:CDBar(155921, 16) -- Enkindle
	engageTime = GetTime()
	-- bar for each lane seemed to make the most sense
	for i = 1, 4 do
		self:StartTrainTimer(i, 1)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

local function checkLane(warnLane)
	if not UnitAffectingCombat("player") then return end
	-- nice square room!
	local lane = 0
	local pos = UnitPosition("player")
	if pos < 529.7 then lane = 4
	elseif pos > 577.7 then lane = 1
	elseif pos > 553.7 then lane = 2
	elseif pos < 553.8 then	lane = 3 end

	if lane == warnLane then
		mod:PlaySound("trains", "Info")
		mod:Flash("trains", L.trains_icon)
	end
end

function mod:StartTrainTimer(lane, count)
	local data = self:Mythic() and trainDataMythic or trainData
	local info = data and data[lane][count]
	if not info then
		-- all out of lane data, just announce every yell
		self:RegisterEvent("CHAT_MSG_MONSTER_YELL", "TrainYell")
		return
	end

	local time, type = unpack(info)
	local length = floor(time - (GetTime() - engageTime))
	if type ~= "random" or lane == 1 then -- only one bar for random trains
		if type ~= "train" then -- no messages for the non-stop trains
			self:DelayedMessage("trains", length-1, "Neutral", CL.incoming:format(L[type]), false) -- Incoming Adds train!
		end
		self:CDBar("trains", length, L.lane:format(type ~= "random" and lane or "?", L[type]), L[type.."_icon"]) -- Lane 1: Adds train
	end
	self:ScheduleTimer(checkLane, length-1, lane) -- gives you ~2s to move
	self:ScheduleTimer("StartTrainTimer", length, lane, count+1)
end

function mod:TrainYell(_, _, _, _, _, target)
	if target == L.train then
		self:DelayedMessage("trains", 4.5, "Neutral", CL.incoming:format(L.train), false) -- Incoming Train!
	end
end

-- Mythic

function mod:ObliterationDamage(args)
	if self:Me(args.destGUID) then
		self:Message(args.spellId, "Personal", "Alarm", CL.underyou:format(args.spellName)) -- OBLITERATION under YOU! lol
	end
end

-- General

function mod:Enkindle(args)
	self:StackMessage(args.spellId, args.destName, args.amount, "Attention", args.amount and "Warning")
	self:CDBar(args.spellId, 16)
end

function mod:PulseGrenade(args)
	self:Message(args.spellId, "Attention")
	self:CDBar(args.spellId, 16, 135592, args.spellId) -- 135592 = "Grenade"
end

function mod:PulseGrenadeDamage(args)
	if self:Me(args.destGUID) then
		self:Message(155864, "Personal", "Alarm", CL.underyou:format(self:SpellName(135592))) -- 135592 = "Grenade"
		self:Flash(155864)
	end
end

function mod:IronBellow(args)
	self:Message(args.spellId, "Urgent")
	self:CDBar(args.spellId, 12)
end

function mod:CauterizingBolt(args)
	self:Message(args.spellId, "Important", "Alert")
end

function mod:DelayedSiegeBomb(args)
	local icon = next(bombTargets) == "PrimaryIcon" and "SecondaryIcon" or "PrimaryIcon"
	bombTargets[args.destName] = icon
	self[icon](self, args.spellId, args.destName)

	self:TargetMessage(args.spellId, args.destName, "Attention", "Warning")
	if self:Me(args.destGUID) then
		self:Flash(args.spellId)
		self:Say(args.spellId, 119342) -- 119342 = Bombs
	end
end

function mod:DelayedSiegeBombRemoved(args)
	local icon = bombTargets[args.destName]
	if icon then
		self[icon](self, args.spellId)
		bombTargets[args.destName] = nil
	end
end

function mod:Deaths(args)
	if args.mobId == 80791 then
		self:StopBar(163753) -- Iron Bellow
	end
end

