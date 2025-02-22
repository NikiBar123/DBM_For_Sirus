local mod	= DBM:NewMod("Supremus", "DBM-BlackTemple")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("2023".."11".."22".."10".."00".."00") --fxpw check
mod:SetCreatureID(22898)

mod:SetModelID(21145)
mod:SetUsedIcons(8)

mod:RegisterCombat("combat")
mod:RegisterEventsInCombat(
	"SPELL_CAST_START 322301 322297 322292 322294",
	"SPELL_AURA_APPLIED 322294"
)

local berserkTimer		= mod:NewBerserkTimer(900)
--[[
["SPELL_CAST_START"] = {
	"Возгорание-322301-npc:22898 = pull:0.0, 0.0, -0.0, 0.0, -0.0, -0.0, 0.0, -0.0, 0.0", -- [1]
	"Потусторонняя метка-322292-npc:22898 = pull:0.0", -- [2]
	"Призрачный обстрел-322297-npc:22898 = pull:-0.0, 0.0, 0.0, 0.0, 0.0, -0.0, 0.0, 0.0, 0.0", -- [3]
	"Связующий удар-322294-npc:22898 = pull:-0.0, 0.0, -0.0, 0.0, -0.0", -- [4]
},
]]
-- start fight 21 32 s=20
local warnStack      		= mod:NewStackAnnounce(322294, 1, nil, "Tank")

local specwarnTank			= mod:NewSpecialWarningSoon(322294, "Tank", nil, nil, 1, 3)
--local specwarnShellingSoon	= mod:NewSpecialWarningSoon(322297, "SpellCaster", nil, nil, 1, 3)
local specWarnGTFO          = mod:NewSpecialWarningGTFO(322297, "SpellCaster", nil, nil, 4, 8)
local specWarnKick			= mod:NewSpecialWarningInterrupt(322301, "HasInterrupt", nil, nil, 1, 2)

local vozgoranie			= mod:NewCDTimer(17, 322301) --SPELL_CAST_START (s)20 (1)36 (2)53
local prizrachnii_obstrel	= mod:NewCDTimer(17, 322297, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON)
local potustoron_metka		= mod:NewCDTimer(20, 322292, nil, nil, nil, 2, nil, DBM_COMMON_L.IMPORTANT_ICON) --SPELL_CAST_START (s)20 40
local svyaz_udar			= mod:NewCDTimer(20, 322294, nil, nil, nil, 2, nil, DBM_COMMON_L.TANK_ICON) --SPELL_CAST_START (s)0:20 (1)0:45 (2)1:04

function mod:OnCombatStart(delay)
	berserkTimer:Start(-delay)
	vozgoranie:Start(16)
	prizrachnii_obstrel:Start(15)
	potustoron_metka:Start()
end

function mod:OnCombatEnd()
	berserkTimer:Stop()
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(322301) then
		vozgoranie:Start()
		specWarnKick:Show(args.sourceName)
	elseif args:IsSpellID(322297) and self:AntiSpam(2) then
		prizrachnii_obstrel:Start()
		specWarnGTFO:Show(args.spellName)
	elseif args:IsSpellID(322294) then
		specwarnTank:Schedule(18)
		svyaz_udar:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	args:IsSpellID(322294)
	warnStack:Show(args.destName, args.amount or 1)
end
-- function mod:SPELL_CAST_SUCCESS(args)
-- 	if args:IsSpellID(vodyanoe_proklyatie.spellid) then
-- 		vodyanoe_proklyatie:Start()
-- 	elseif args:IsSpellID(pronzayous_ship.spellid) then
-- 		pronzayous_ship:Start()
-- 	end
-- end