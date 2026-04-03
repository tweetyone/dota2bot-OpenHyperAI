local Fu = require(GetScriptDirectory()..'/FuncLib/func_utils')
local U = require(GetScriptDirectory()..'/FuncLib/hero/minion_lib/utils')

local X = {}

function X.Think(bot, hMinionUnit)
	local thisMinionAttackRange = bot:GetAttackRange()

	local target = U.GetWeakestHero(thisMinionAttackRange, hMinionUnit)
	if target == nil
	then
		target = U.GetWeakestCreep(thisMinionAttackRange, hMinionUnit)
		if target == nil
		then
			target = U.GetWeakestTower(thisMinionAttackRange, hMinionUnit)
		end
	end

	if target ~= nil and not U.IsNotAllowedToAttack(target)
	then
		hMinionUnit:Action_AttackUnit(target, true)
		return
	end
end

return X