function onInit()
    addEffect = EffectManager.addEffect
    EffectManager.addEffect = modifyEffectOnAdd
end

function modifyEffectOnAdd(sUser, sIdentity, nodeCT, rNewEffect, bShowMsg, ...)
    local actor = ActorManager.resolveActor(nodeCT)
    local bonusMods = getBonusMods(actor)
    if next(bonusMods) then
        local effectStringComps = EffectManager.parseEffect(rNewEffect.sName)
        for index, effectStringComp in ipairs(effectStringComps) do
            effectComp = EffectManager.parseEffectCompSimple(effectStringComp)
            if effectComp.type ~= '' and effectComp.type ~= "BONUSMOD" and next(effectComp.remainder) then
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

function getBonusMods(rActor)
    local bonusModsEffects = EffectManager35E.getEffectsByType(rActor, "BONUSMOD")
    local bonusSum = {}
    for _, bonusMod in ipairs(bonusModsEffects) do
        local bonus = (bonusMod.remainder[1] or "any")
        bonusSum[bonus] = (bonusSum[bonus] or 0) + bonusMod.mod
    end
    return bonusSum
end
