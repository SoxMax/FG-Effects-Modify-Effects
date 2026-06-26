local onEffect

function onInit()
	onEffect = ActionEffect.onEffect
	ActionEffect.onEffect = onEffectModify
end

function onEffectModify(rSource, rTarget, rRoll, ...)
	modifyEffect(rSource, rTarget, rRoll)
	onEffect(rSource, rTarget, rRoll, ...)
end

function modifyEffect(rSource, rTarget, rRoll)
    local rEffect = EffectManager.decodeEffect(rRoll)
    local effectsModified = false
    local effectStringComps = EffectManager.parseEffect(rEffect.sName)
    local bonusMods = {}
    for index, effectStringComp in ipairs(effectStringComps) do
        effectComp = EffectManager.parseEffectCompSimple(effectStringComp)
        if effectComp.type ~= '' and effectComp.type ~= "BONUSMOD" then
			local bonusTypes = extractBonusTypes(effectComp.remainder)
			if  #bonusTypes > 0 then
				updateBonusMods(bonusMods, bonusTypes, rSource, rTarget)
				for _, bonusType in ipairs(bonusTypes) do
					if bonusMods[bonusType] then
						effectComp.mod = effectComp.mod + bonusMods[bonusType]
						effectStringComps[index] = EffectManager.rebuildParsedEffectCompSimple(effectComp)
						effectsModified = true
					end
				end
			end
        end
    end
    if effectsModified then
        rEffect.sName = EffectManager.rebuildParsedEffect(effectStringComps)
        rRoll.sDesc = EffectManager.encodeEffect(rEffect).sDesc
    end
	return true
end

function getBonusMods(rActor, bonusTypeFilter, rFilterActor)
    local bonusModsEffects = EffectManager.getCompsDataByTag(rActor, "BONUSMOD",
        { rTarget = rFilterActor, tFilter = bonusTypeFilter })
    local bonusSum = {}
    for _, bonusMod in ipairs(bonusModsEffects) do
		local bonus = getBonusModKeys(bonusMod.remainder)
        bonusSum[bonus] = (bonusSum[bonus] or 0) + bonusMod.mod
    end
    return bonusSum
end

function getBonusModKeys(effectRemainder)
	local bonusTypes = extractBonusTypes(effectRemainder)
	if #bonusTypes == 0 then
		return "any"
	elseif #bonusTypes == 1 then
		return bonusTypes[1]
	else
		return table.sort(bonusTypes)
	end
end

function extractBonusTypes(effectRemainder)
	local bonusTypes = {}
	for _, entry in ipairs(effectRemainder) do
		if StringManager.contains(DataCommon and DataCommon.bonustypes or {}, entry) then
			table.insert(bonusTypes, entry)
		end
	end
	return bonusTypes
end

function updateBonusMods(bonusMods, bonusTypes, rSource, rTarget)
	local newBonusTypes = {}
	for _, bonusType in ipairs(bonusTypes) do
		if bonusMods[bonusType] == nil then
			table.insert(newBonusTypes, bonusType)
		end
	end
	if #newBonusTypes == 0 then
		return
	end
	combineBonusMods(bonusMods, getBonusMods(rSource, createEffectFilter("create", newBonusTypes), rTarget))
	combineBonusMods(bonusMods, getBonusMods(rTarget, createEffectFilter("receive", newBonusTypes), rSource))
end

function combineBonusMods(existingMods, newMods)
    for bonusType, bonus in pairs(newMods) do
		existingMods[bonusType] = (existingMods[bonusType] or 0) + bonus
    end
end

function createEffectFilter(effectModType, effectBonusTypes)
    local filter = {effectModType}
	for _, entry in ipairs(effectBonusTypes) do
			table.insert(filter, entry)
	end
    return filter
end
