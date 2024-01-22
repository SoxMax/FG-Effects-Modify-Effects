local addEffect

function onInit()
    addEffect = EffectManager.addEffect
    EffectManager.addEffect = modifyEffectOnAdd
end

function modifyEffectOnAdd(sUser, sIdentity, nodeCT, rNewEffect, bShowMsg, ...)
    local actor = ActorManager.resolveActor(nodeCT)
    local effectStringComps = EffectManager.parseEffect(rNewEffect.sName)
    local bonusMods = {}
    for index, effectStringComp in ipairs(effectStringComps) do
        effectComp = EffectManager.parseEffectCompSimple(effectStringComp)
        if effectComp.type ~= '' and effectComp.type ~= "BONUSMOD" and next(effectComp.remainder) then
            combineBonusMods(bonusMods, getBonusMods(actor, effectComp.remainder))
            for _, bonusType in ipairs(effectComp.remainder) do
                if bonusMods[bonusType] then
                    effectComp.mod = effectComp.mod + bonusMods[bonusType]
                    effectStringComps[index] = EffectManager35E.rebuildParsedEffectComp(effectComp)
                end
            end
        end
    end
    rNewEffect.sName = EffectManager.rebuildParsedEffect(effectStringComps)

    addEffect(sUser, sIdentity, nodeCT, rNewEffect, bShowMsg, ...)
end

function getBonusMods(rActor, bonusTypeFilter)
    local bonusModsEffects = EffectManager35E.getEffectsByType(rActor, "BONUSMOD", bonusTypeFilter)
    local bonusSum = {}
    for _, bonusMod in ipairs(bonusModsEffects) do
        local bonus = (bonusMod.remainder[1] or "any")
        bonusSum[bonus] = (bonusSum[bonus] or 0) + bonusMod.mod
    end
    return bonusSum
end

function combineBonusMods(existingMods, newMods)
    for bonusType, bonus in pairs(newMods) do
        if not existingMods[bonusType] then
            existingMods[bonusType] = bonus
        end
    end
end
