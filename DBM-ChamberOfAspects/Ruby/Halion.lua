local mod	= DBM:NewMod("Halion", "DBM-ChamberOfAspects", 2)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20200405141240")
mod:SetCreatureID(39863)--40142 (twilight form)
mod:SetMinSyncRevision(4358)
mod:SetUsedIcons(7, 8)

mod:RegisterCombat("combat")
--mod:RegisterKill("yell", L.Kill)

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 74806 75954 75955 75956 74525 74526 74527 74528",
	--"SPELL_CAST_SUCCESS 74792 74562",
	"SPELL_AURA_APPLIED 74792 74562",
	"SPELL_AURA_REMOVED 74792 74562",
	"SPELL_DAMAGE 75952 75951 75950 75949 75948 75947 75483 75484 75485 75486",
	"CHAT_MSG_MONSTER_YELL",
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"UNIT_HEALTH"
)
local serverNumber = select(4, DBM:GetMyPlayerInfo()) == 5
-- Общее типо
local berserkTimer					= mod:NewBerserkTimer(480)

mod:AddBoolOption("AnnounceAlternatePhase", true, "announce")

mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(1)..": "..L.PhysicalRealm)

local warnPhase2Soon				= mod:NewPrePhaseAnnounce(2)
local warningFieryBreath			= mod:NewSpellAnnounce(74526, 2, nil, "Tank|Healer")
local warningFieryCombustion		= mod:NewTargetAnnounce(74562, 4)
local warningMeteor					= mod:NewSpellAnnounce(74648, 3)

local specWarnFieryCombustion		= mod:NewSpecialWarningRun(74562, nil, nil, nil, 4, 2)
local specWarnMeteorStrike			= mod:NewSpecialWarningMove(75952, nil, nil, nil, 1, 2)

local yellFieryCombustion			= mod:NewYell(74562)

local timerFieryConsumptionCD		= mod:NewNextTimer(25, 74562, nil, nil, nil, 3)
local timerMeteorCD					= mod:NewNextTimer(40, 74648, nil, nil, nil, 3)
local timerMeteorCast				= mod:NewCastTimer(7, 74648)--7-8 seconds from boss yell the meteor impacts.
local timerFieryBreathCD			= mod:NewCDTimer(19, 74526, nil, "Tank|Healer", nil, 5)--But unique icons are nice pertaining to phase you're in ;)

-- Stage Two - Twilight Realm (75%)
local twilightRealmName = DBM:GetSpellInfo(74807)
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(2)..": "..twilightRealmName)

local warnPhase3Soon				= mod:NewPrePhaseAnnounce(3)
local warnPhase2					= mod:NewPhaseAnnounce(2)
local warningShadowBreath			= mod:NewSpellAnnounce(75954, 2, nil, "Tank|Healer")
local warningTwilightCutter			= mod:NewAnnounce("TwilightCutterCast", 2, 77844)
local warningShadowConsumption		= mod:NewTargetAnnounce(74792, 4)

local specWarnShadowConsumption		= mod:NewSpecialWarningRun(74792, nil, nil, nil, 4, 2)
local specWarnTwilightCutter		= mod:NewSpecialWarningSpell(77844, nil, nil, nil, 3, 2)

local yellShadowconsumption			= mod:NewYell(74792)

local timerShadowConsumptionCD		= mod:NewNextTimer(25, 74792, nil, nil, nil, 3)
local timerTwilightCutterCast		= mod:NewCastTimer(5, 77844)
local timerTwilightCutter			= mod:NewBuffActiveTimer(serverNumber and 9 or 10, 77844, nil, nil, nil, 6)
local timerTwilightCutterCD			= mod:NewNextTimer(serverNumber and 15 or 20, 77844, nil, nil, nil, 6)
local timerShadowBreathCD			= mod:NewCDTimer(19, 75954, nil, "Tank|Healer", nil, 5)--Same as debuff timers, same CD, can be merged into 1.

mod:AddBoolOption("WhisperOnConsumption", false, "announce")
mod:AddBoolOption("SetIconOnConsumption", true)

-- Stage Three - Corporeality (50%)
local warnPhase3					= mod:NewPhaseAnnounce(3)

local warned_preP2 = false
local warned_preP3 = false
local lastflame = 0
local lastshroud = 0
local phases = {}

mod.vb.phase = 1

function mod:LocationChecker()
	if GetTime() - lastshroud < 6 then
		DBM.BossHealth:RemoveBoss(39863)--you took damage from twilight realm recently so remove the physical boss from health frame.
	else
		DBM.BossHealth:RemoveBoss(40142)--you have not taken damage from twilight realm so remove twilight boss health bar.
	end
end

local function updateHealthFrame(phase)
	if phases[phase] then
		return
	end
	phases[phase] = true
	mod.vb.phase = phase

	if phase == 1 then
		DBM.BossHealth:Clear()
		DBM.BossHealth:AddBoss(39863, L.NormalHalion)
	elseif phase == 2 then
		DBM.BossHealth:Clear()
		DBM.BossHealth:AddBoss(40142, L.TwilightHalion)
	elseif phase == 3 then
		DBM.BossHealth:AddBoss(39863, L.NormalHalion)--Add 1st bar back on. you have two bars for time being.
		mod:ScheduleMethod(20, "LocationChecker")--we remove the extra bar in 20 seconds depending on where you are at when check is run.
	end
end

function mod:OnCombatStart(delay)--These may still need retuning too, log i had didn't have pull time though.
	DBM:FireCustomEvent("DBM_EncounterStart", 39863, "Halion")
	table.wipe(phases)
	warned_preP2 = false
	warned_preP3 = false
	lastflame = 0
	lastshroud = 0
	berserkTimer:Start(-delay)
	timerMeteorCD:Start(20-delay)
	timerFieryConsumptionCD:Start(15-delay)
	timerFieryBreathCD:Start(10-delay)
	updateHealthFrame(1)
end

function mod:OnCombatEnd(wipe)
	DBM:FireCustomEvent("DBM_EncounterEnd", 39863, "Halion", wipe)
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(74806, 75954, 75955, 75956) then
		warningShadowBreath:Show()
		timerShadowBreathCD:Start()
	elseif args:IsSpellID(74525, 74526, 74527, 74528) then
		warningFieryBreath:Show()
		timerFieryBreathCD:Start()
	end
end

--[[function mod:SPELL_CAST_SUCCESS(args)--We use spell cast success for debuff timers in case it gets resisted by a player we still get CD timer for next one
	if args:IsSpellID(74792) then
		if mod:IsDifficulty("heroic10") or mod:IsDifficulty("heroic25") then
			timerShadowConsumptionCD:Start(20)
		else
			timerShadowConsumptionCD:Start()
		end
		if mod:LatencyCheck() then
			self:SendSync("ShadowCD")
		end
	elseif args:IsSpellID(74562) then
		if mod:IsDifficulty("heroic10") or mod:IsDifficulty("heroic25") then
			timerFieryConsumptionCD:Start(20)
		else
			timerFieryConsumptionCD:Start()
		end
	end
end]]

function mod:SPELL_AURA_APPLIED(args)--We don't use spell cast success for actual debuff on >player< warnings since it has a chance to be resisted.
	if args:IsSpellID(74792) then
		if not self.Options.AnnounceAlternatePhase then
			warningShadowConsumption:Show(args.destName)
			if DBM:GetRaidRank() >= 1 and self.Options.WhisperOnConsumption then
				SendChatMessage(L.WhisperConsumption, "WHISPER", "COMMON", args.destName)
			end
		end
		if mod:IsDifficulty("heroic10") or mod:IsDifficulty("heroic25") then
			timerShadowConsumptionCD:Start(20)
		else
			timerShadowConsumptionCD:Start()
		end
		if mod:LatencyCheck() then
			self:SendSync("ShadowTarget", args.destName)
			self:SendSync("ShadowCD")
		end
		if args:IsPlayer() then
			specWarnShadowConsumption:Show()
			specWarnShadowConsumption:Play("runout")
			yellShadowconsumption:Yell()
		end
		if self.Options.SetIconOnConsumption then
			self:SetIcon(args.destName, 7)
		end
	elseif args:IsSpellID(74562) then
		if mod:IsDifficulty("heroic10") or mod:IsDifficulty("heroic25") then
			timerFieryConsumptionCD:Start(20)
		else
			timerFieryConsumptionCD:Start()
		end
		if not self.Options.AnnounceAlternatePhase then
			warningFieryCombustion:Show(args.destName)
			if DBM:GetRaidRank() >= 1 and self.Options.WhisperOnConsumption then
				SendChatMessage(L.WhisperCombustion, "WHISPER", "COMMON", args.destName)
			end
		end
		if mod:LatencyCheck() then
			self:SendSync("FieryTarget", args.destName)
			self:SendSync("FieryCD")
		end
		if args:IsPlayer() then
			specWarnFieryCombustion:Show()
			specWarnFieryCombustion:Play("runout")
			yellFieryCombustion:Yell()
		end
		if self.Options.SetIconOnConsumption then
			self:SetIcon(args.destName, 8)
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(74792) then
		if self.Options.SetIconOnConsumption then
			self:RemoveIcon(args.destName)
		end
	elseif args:IsSpellID(74562) then
		if self.Options.SetIconOnConsumption then
			self:RemoveIcon(args.destName)
		end
	end
end

local spellIDs = {
	["75952"] = true,
	["75951"] = true,
	["75950"] = true,
	["75949"] = true,
	["75948"] = true,
	["75947"] = true,

}
local spellIDs2 = {
	["75483"] = true,
	["75484"] = true,
	["75485"] = true,
	["75486"] = true,

}

local bband = bit.band


function mod:SPELL_DAMAGE(_, _, _, _, _, destFlags, spellId)
	if spellIDs[spellId] and  bband(destFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= 0 and bband(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) ~= 0 and GetTime() - lastflame > 2 then
		specWarnMeteorStrike:Show()
		specWarnMeteorStrike:Play("runaway")
		lastflame = GetTime()
	elseif spellIDs2[spellId] and bband(destFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= 0 and bband(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) ~= 0 then
		lastshroud = GetTime()--keeps a time stamp for twilight realm damage to determin if you're still there or not for bosshealth frame.
	end
end

function mod:UNIT_HEALTH(uId)
	if not warned_preP2 and self:GetUnitCreatureId(uId) == 39863 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.79 then
		warned_preP2 = true
		warnPhase2Soon:Show()
	elseif not warned_preP3 and self:GetUnitCreatureId(uId) == 40142 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.54 then
		warned_preP3 = true
		warnPhase3Soon:Show()
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.Phase2 or msg:find(L.Phase2) then
		updateHealthFrame(2)
		timerFieryBreathCD:Cancel()
		timerMeteorCD:Cancel()
		timerFieryConsumptionCD:Cancel()
		warnPhase2:Show()
		timerShadowBreathCD:Start(20)
		timerShadowConsumptionCD:Start(20)--not exact, 15 seconds from tank aggro, but easier to add 5 seconds to it as a estimate timer than trying to detect this
		if mod:IsDifficulty("heroic10") or mod:IsDifficulty("heroic25") then --These i'm not sure if they start regardless of drake aggro, or if it should be moved too.
			timerTwilightCutterCD:Start(40)
		else
			timerTwilightCutterCD:Start(35)
		end
	elseif msg == L.Phase3 or msg:find(L.Phase3) then
		self:SendSync("Phase3")
	elseif msg == L.MeteorCast or msg:find(L.MeteorCast) then--There is no CLEU cast trigger for meteor, only yell
		if not self.Options.AnnounceAlternatePhase then
			warningMeteor:Show()
			timerMeteorCast:Start()--7 seconds from boss yell the meteor impacts.
			timerMeteorCD:Start()
		end
		if mod:LatencyCheck() then
			self:SendSync("Meteor")
		end
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if msg == L.twilightcutter or msg:find(L.twilightcutter) then
			specWarnTwilightCutter:Schedule(5)
		if not self.Options.AnnounceAlternatePhase then
			warningTwilightCutter:Show()
			timerTwilightCutterCast:Start()
			timerTwilightCutter:Schedule(5)--Delay it since it happens 5 seconds after the emote
			timerTwilightCutterCD:Schedule(serverNumber and 15 or 20)
		end
		if mod:LatencyCheck() then
			self:SendSync("TwilightCutter")
		end
	end
end

function mod:OnSync(msg, target)
	if msg == "TwilightCutter" then
		if self.Options.AnnounceAlternatePhase then
			warningTwilightCutter:Show()
			timerTwilightCutterCast:Start()
			timerTwilightCutter:Schedule(5)--Delay it since it happens 5 seconds after the emote
			timerTwilightCutterCD:Schedule(serverNumber and 15 or 20)
		end
	elseif msg == "Meteor" then
		if self.Options.AnnounceAlternatePhase then
			warningMeteor:Show()
			timerMeteorCast:Start()
			timerMeteorCD:Start()
		end
	elseif msg == "ShadowTarget" then
		if self.Options.AnnounceAlternatePhase then
			warningShadowConsumption:Show(target)
			if DBM:GetRaidRank() >= 1 and self.Options.WhisperOnConsumption then
				SendChatMessage(L.WhisperConsumption, "WHISPER", "COMMON", target)
			end
		end
	elseif msg == "FieryTarget" then
		if self.Options.AnnounceAlternatePhase then
			warningFieryCombustion:Show(target)
			if DBM:GetRaidRank() >= 1 and self.Options.WhisperOnConsumption then
				SendChatMessage(L.WhisperCombustion, "WHISPER", "COMMON", target)
			end
		end
	elseif msg == "ShadowCD" then
		if self.Options.AnnounceAlternatePhase then
			if mod:IsDifficulty("heroic10") or mod:IsDifficulty("heroic25") then
				timerShadowConsumptionCD:Start(20)
			else
				timerShadowConsumptionCD:Start()
			end
		end
	elseif msg == "FieryCD" then
		if self.Options.AnnounceAlternatePhase then
			if mod:IsDifficulty("heroic10") or mod:IsDifficulty("heroic25") then
				timerFieryConsumptionCD:Start(20)
			else
				timerFieryConsumptionCD:Start()
			end
		end
	elseif msg == "Phase3" then
		updateHealthFrame(3)
		warnPhase3:Show()
		timerMeteorCD:Start(30) --These i'm not sure if they start regardless of drake aggro, or if it varies as well.
		timerFieryConsumptionCD:Start(20)--not exact, 15 seconds from tank aggro, but easier to add 5 seconds to it as a estimate timer than trying to detect this
	end
end
