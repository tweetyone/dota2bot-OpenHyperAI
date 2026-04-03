local X = {}
local bDebugMode = ( 1 == 10 )
local bot = GetBot()

local Fu = require( GetScriptDirectory()..'/FuncLib/func_utils' )
local Minion = dofile( GetScriptDirectory()..'/FuncLib/hero/minion' )
local sTalentList = Fu.Skill.GetTalentList( bot )
local sAbilityList = Fu.Skill.GetAbilityList( bot )
local sRole = Fu.Item.GetRoleItemsBuyList( bot )

local tTalentTreeList = {
						['t25'] = {0, 10},
						['t20'] = {10, 0},
						['t15'] = {0, 10},
						['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
						{3,1,3,2,3,6,3,2,2,2,6,1,1,1,6},--pos1
}

local nAbilityBuildList = Fu.Skill.GetRandomBuild( tAllAbilityBuildList )

local nTalentBuildList = Fu.Skill.GetTalentBuild( tTalentTreeList )

local sRoleItemsBuyList = {}

sRoleItemsBuyList['pos_1'] = {
	"item_tango",
    "item_double_branches",
    "item_faerie_fire",
    "item_quelling_blade",
	"item_circlet",

    "item_magic_wand",
    "item_phase_boots",
	"item_diffusal_blade",
    -- "item_bfury",--
    "item_blink",
    "item_basher",
    "item_black_king_bar",--
    "item_abyssal_blade",--
    "item_ultimate_scepter",
	"item_disperser",--
    "item_satanic",--
    "item_swift_blink",--
    "item_ultimate_scepter_2",
    "item_moon_shard",
    "item_travel_boots",
    "item_aghanims_shard",
    "item_travel_boots_2",--
}

sRoleItemsBuyList['pos_2'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_4'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_5'] = sRoleItemsBuyList['pos_1']

sRoleItemsBuyList['pos_3'] = sRoleItemsBuyList['pos_1']

X['sBuyList'] = sRoleItemsBuyList[sRole]

X['sSellList'] = {

	"item_black_king_bar",
	"item_quelling_blade",

}

if Fu.Role.IsPvNMode() or Fu.Role.IsAllShadow() then X['sBuyList'], X['sSellList'] = { 'PvN_antimage' }, {} end

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = Fu.SetUserHeroInit( nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] )

X['sSkillList'] = Fu.Skill.GetSkillList( sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList )

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = false

function X.MinionThink(hMinionUnit)

	if Minion.IsValidUnit( hMinionUnit )
	then
		if Fu.IsValidHero(hMinionUnit) and hMinionUnit:IsIllusion()
		then
			Minion.IllusionThink( hMinionUnit )
		end
	end

end

local Earthshock    = bot:GetAbilityByName( "ursa_earthshock" )
local Overpower     = bot:GetAbilityByName( "ursa_overpower" )
local Enrage        = bot:GetAbilityByName( "ursa_enrage" )

local EarthshockDesire
local OverpowerDesire
local EnrageDesire

function X.SkillsComplement()
    if Fu.CanNotUseAbility(bot) then return end

	EnrageDesire = X.ConsiderEnrage()
    if EnrageDesire > 0
	then
		bot:Action_UseAbility(Enrage)
		return
	end

	OverpowerDesire = X.ConsiderOverpower()
	if OverpowerDesire > 0
	then
		bot:Action_UseAbility(Overpower)
		return
	end

	EarthshockDesire = X.ConsiderEarthshock()
	if EarthshockDesire > 0
	then
		bot:Action_UseAbility(Earthshock)
		return
	end
end

function X.ConsiderEarthshock()
	if not Earthshock:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE
	end

	local nRadius = Earthshock:GetSpecialValueInt('shock_radius')
	local nLeapDuration = Earthshock:GetSpecialValueInt('hop_duration')
	local nDamage = Earthshock:GetAbilityDamage()
	local nMana = bot:GetMana() / bot:GetMaxMana()
	local botTarget = Fu.GetProperTarget(bot)

	local nEnemyHeroes = Fu.GetNearbyHeroes(bot,nRadius, true, BOT_MODE_NONE)
	local nEnemyTowers = bot:GetNearbyTowers(nRadius * 2, true)

	for _, enemyHero in pairs(nEnemyHeroes)
	do
		if Fu.IsValidHero(enemyHero)
		and Fu.CanCastOnNonMagicImmune(enemyHero)
		and Fu.IsInRange(bot, enemyHero, nRadius)
		and not Fu.IsSuspiciousIllusion(enemyHero)
		and not enemyHero:HasModifier('modifier_enigma_black_hole_pull')
		and not enemyHero:HasModifier('modifier_faceless_void_chronosphere_freeze')
		then
			if bot:IsFacingLocation(enemyHero:GetExtrapolatedLocation(nLeapDuration), 15)
			then
				local nTargetInRangeAlly = Fu.GetNearbyHeroes(enemyHero, nRadius + 100, true, BOT_MODE_NONE)

				if nTargetInRangeAlly ~= nil and #nTargetInRangeAlly <= 1
				and Fu.CanKillTarget(enemyHero, nDamage, DAMAGE_TYPE_MAGICAL)
				then
					return BOT_ACTION_DESIRE_HIGH
				end
			end
		end
	end

	if Fu.IsGoingOnSomeone(bot)
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,nRadius + 200, false, BOT_MODE_NONE)
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nRadius, true, BOT_MODE_NONE)

		if Fu.IsValidTarget(botTarget)
		and Fu.IsInRange(bot, botTarget, nRadius)
		and not Fu.IsSuspiciousIllusion(botTarget)
		and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
		and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
		and not bot:HasModifier('modifier_ursa_earthshock_move')
		and nInRangeAlly ~= nil and nInRangeEnemy ~= nil
		and #nInRangeAlly >= #nInRangeEnemy
		then
			if bot:IsFacingLocation(botTarget:GetExtrapolatedLocation(nLeapDuration), 15)
			then
				return BOT_ACTION_DESIRE_HIGH
			end
		end
	end

	if Fu.IsRetreating(bot)
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,nRadius * 2.5, false, BOT_MODE_NONE)
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nRadius * 2, true, BOT_MODE_NONE)

		if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
		and ((#nInRangeEnemy > #nInRangeAlly)
			or (Fu.GetHP(bot) < 0.55 and bot:WasRecentlyDamagedByAnyHero(2.5)))
		and Fu.IsValidHero(nInRangeEnemy[1])
		and Fu.IsInRange(bot, nInRangeEnemy[1], nRadius)
		and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
		and not Fu.IsDisabled(nInRangeEnemy[1])
		and not Fu.IsRealInvisible(bot)
		then
			if bot:IsFacingLocation(Fu.GetEscapeLoc(), 30)
			then
				return BOT_ACTION_DESIRE_HIGH
			end
		end
	end

	if Fu.IsLaning(bot)
	and nEnemyHeroes ~= nil and nEnemyTowers ~= nil
	and #nEnemyHeroes == 0 and #nEnemyTowers == 0
	then
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nRadius, true)
		for _, creep in pairs(nEnemyLaneCreeps)
		do
			if Fu.IsValid(creep)
			and Fu.CanBeAttacked(creep)
			and (Fu.IsKeyWordUnit('ranged', creep) or Fu.IsKeyWordUnit('siege', creep))
			and bot:IsFacingLocation(creep:GetLocation(), 15)
			then
				if Fu.WillKillTarget(creep, nDamage, DAMAGE_TYPE_PHYSICAL, 0.25)
				then
					bot:SetTarget(creep)
					return BOT_ACTION_DESIRE_HIGH
				end
			end
		end

		if nMana > 0.89
		and bot:DistanceFromFountain() > 100
		and bot:DistanceFromFountain() < 6000
		then
			local nLane = bot:GetAssignedLane()
			local nLaneFrontLocation = GetLaneFrontLocation(GetTeam(), nLane, 0)
			local nDistFromLane = GetUnitToLocationDistance(bot, nLaneFrontLocation)

			if nDistFromLane > 1600
			then
				local loc = Fu.Site.GetXUnitsTowardsLocation(bot, nLaneFrontLocation, nRadius)

				if IsLocationPassable(loc)
				and bot:IsFacingLocation(loc, 30)
				then
					return BOT_ACTION_DESIRE_HIGH
				end
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderOverpower()
	if not Overpower:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE
	end

	local nAttackRange = bot:GetAttackRange()
	local nMana = bot:GetMana() / bot:GetMaxMana()
	local botTarget = Fu.GetProperTarget(bot)

	if Fu.IsGoingOnSomeone(bot)
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,nAttackRange * 3, false, BOT_MODE_NONE)
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,nAttackRange * 2, true, BOT_MODE_NONE)

		if Fu.IsValidTarget(botTarget)
		and Fu.IsInRange(bot, botTarget, nAttackRange * 2)
		and bot:IsFacingLocation(botTarget:GetLocation(), 30)
		and not Fu.IsSuspiciousIllusion(botTarget)
		and not botTarget:HasModifier('modifier_abaddon_aphotic_shield')
		and not botTarget:HasModifier('modifier_abaddon_borrowed_time')
		and not botTarget:HasModifier('modifier_dazzle_shallow_grave')
		and not botTarget:HasModifier('modifier_templar_assassin_refraction_absorb')
		and nInRangeAlly ~= nil and nInRangeEnemy ~= nil
		and #nInRangeAlly >= #nInRangeEnemy
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if Fu.IsPushing(bot)
	and nMana > 0.45
	then
		local nEnemyLaneCreeps = bot:GetNearbyLaneCreeps(nAttackRange, true)
		local nEnemyTowers = bot:GetNearbyTowers(600, true)

		if (nEnemyLaneCreeps ~= nil and #nEnemyLaneCreeps >= 3)
		or (nEnemyTowers ~= nil and #nEnemyTowers >= 1)
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if Fu.IsFarming(bot)
	and nMana > 0.25
	then
		local nCreeps = bot:GetNearbyNeutralCreeps(400)

		if nCreeps ~= nil and #nCreeps >= 2
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if Fu.IsDoingRoshan(bot)
	then
		if Fu.IsRoshan(botTarget)
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

    if Fu.IsDoingTormentor(bot) then
		if Fu.IsTormentor(botTarget)
        and Fu.IsInRange(botTarget, bot, 600)
        and bAttacking
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

function X.ConsiderEnrage()
	if not Enrage:IsFullyCastable()
	then
		return BOT_ACTION_DESIRE_NONE
	end

	local nAttackRange = bot:GetAttackRange()
	local botTarget = Fu.GetProperTarget(bot)

	if Fu.IsGoingOnSomeone(bot)
	then
		local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,600, true, BOT_MODE_NONE)

		if Fu.IsValidTarget(botTarget)
		and Fu.IsInRange(bot, botTarget, nAttackRange + 75)
		and not Fu.IsSuspiciousIllusion(botTarget)
		and not Fu.IsDisabled(botTarget)
		and not bot:IsMagicImmune()
		and not botTarget:HasModifier('modifier_faceless_void_chronosphere_freeze')
		and not botTarget:HasModifier('modifier_enigma_black_hole_pull')
		and nInRangeAlly ~= nil and nInRangeEnemy ~= nil
		and #nInRangeAlly >= #nInRangeEnemy
		then
			if bot:WasRecentlyDamagedByAnyHero(1)
			and Fu.GetHP(bot) < 0.75
			then
				return BOT_ACTION_DESIRE_HIGH
			end
		end
	end

	if Fu.IsRetreating(bot)
	then
		if Fu.GetHP(bot) < 0.3 and bot:WasRecentlyDamagedByAnyHero(1) then
			return BOT_ACTION_DESIRE_HIGH
		end

		local nInRangeAlly = Fu.GetNearbyHeroes(bot,800, false, BOT_MODE_NONE)
		local nInRangeEnemy = Fu.GetNearbyHeroes(bot,600, true, BOT_MODE_NONE)

		if nInRangeAlly ~= nil and nInRangeEnemy ~= nil
		and ((#nInRangeEnemy > #nInRangeAlly)
			or (Fu.GetHP(bot) < 0.5 and bot:WasRecentlyDamagedByAnyHero(1.5)))
		and Fu.IsValidHero(nInRangeEnemy[1])
		and Fu.IsInRange(bot, nInRangeEnemy[1], nAttackRange + 100)
		and not Fu.IsSuspiciousIllusion(nInRangeEnemy[1])
		and not Fu.IsDisabled(nInRangeEnemy[1])
		and not bot:IsMagicImmune()
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	if Fu.IsFarming(bot)
	and Fu.GetHP(bot) < 0.25
	then
		if Fu.IsValid(botTarget)
		and botTarget:IsCreep()
		and Fu.IsInRange(bot, botTarget, nAttackRange)
		then
			return BOT_ACTION_DESIRE_MODERATE
		end
	end

	if Fu.IsDoingRoshan(bot)
	and Fu.GetHP(bot) < 0.33
	then
		if Fu.IsRoshan(botTarget)
		then
			return BOT_ACTION_DESIRE_MODERATE
		end
	end

	if Fu.IsDoingTormentor(bot) then
		if Fu.IsTormentor(botTarget)
		and botHP < 0.3
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end

	return BOT_ACTION_DESIRE_NONE
end

return X