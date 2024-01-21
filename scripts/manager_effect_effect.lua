local addEffect
local getEffectsBonusByType

function onInit()
    addEffect = EffectManager.addEffect
    EffectManager.addEffect = modifyEffectOnAdd

    getEffectsBonusByType = EffectManager35E.getEffectsBonusByType
    EffectManager35E.getEffectsBonusByType = modifyEffectsOnRetrieval
end

function modifyEffectOnAdd(sUser, sIdentity, nodeCT, rNewEffect, bShowMsg, ...)
    local actor = ActorManager.resolveActor(nodeCT)
    local bonusModsEffects = EffectManager.getEffectsByType(actor, "BONUSMOD")
    if next(bonusModsEffects) then
        local bonusMods = sumByBonus(bonusModsEffects)
        local effectStringComps = EffectManager.parseEffect(rNewEffect.sName)
        for index, effectStringComp in ipairs(effectStringComps) do
            effectComp = EffectManager.parseEffectCompSimple(effectStringComp)
            if effectComp.type ~= '' and next(effectComp.remainder) then
                for _, bonus in ipairs(effectComp.remainder) do
                    if bonusMods[bonus] then
                        effectComp.mod = effectComp.mod + bonusMods[bonus]
                        effectStringComps[index] = EffectManager35E.rebuildParsedEffectComp(effectComp)
                    end
                end
            end
        end
        rNewEffect.sName = EffectManager.rebuildParsedEffect(effectStringComps)
    end

    addEffect(sUser, sIdentity, nodeCT, rNewEffect, bShowMsg, ...)
end

function sumByBonus(bonusMods)
    local bonusSum = {}
    for _, bonusMod in ipairs(bonusMods) do
        local bonus = bonusMod.remainder[1]
        bonusSum[bonus] = (bonusSum[bonus] or 0) + bonusMod.mod
    end
    return bonusSum
end

function getBonusMods(rActor)
    local bonusModsEffects = EffectManager35E.getEffectsByType(rActor, "BONUSMOD")
    local bonusSum = {}
    for _, bonusMod in ipairs(bonusModsEffects) do
        local bonus = bonusMod.remainder[1]
        bonusSum[bonus] = (bonusSum[bonus] or 0) + bonusMod.mod
    end
    return bonusSum
end

function modifyEffectsOnRetrieval(rActor, aEffectType, bAddEmptyBonus, aFilter, rFilterActor, bTargetedOnly, ...)
    local effects, effectsCount = getEffectsBonusByType(rActor, aEffectType, bAddEmptyBonus, aFilter, rFilterActor, bTargetedOnly, ...)
    if effectsCount > 0 then
        bonusMods = getBonusMods(rActor)
        for bonusType, effect in pairs(effects) do
            local bonusMod = bonusMods[bonusType]
            if bonusMod then
                effect.mod = effect.mod + bonusMod
            end
        end
    end
    return effects, effectsCount
end
