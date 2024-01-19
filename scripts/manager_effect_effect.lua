local addEffect

function onInit()
    addEffect = EffectManager.addEffect
    EffectManager.addEffect = modifyEffect
end


function modifyEffect(sUser, sIdentity, nodeCT, rNewEffect, bShowMsg, ...)
    Debug.chat(sUser, sIdentity, nodeCT, rNewEffect, bShowMsg)

    local actor = ActorManager.resolveActor(nodeCT)
    local bonusModsEffects = EffectManager.getEffectsByType(actor, "BONUSMOD")
    if next(bonusModsEffects) then
        local bonusMods = sumByBonus(bonusModsEffects)
        local effectStringComps = EffectManager.parseEffect(rNewEffect.sName)
        for index, effectStringComp in ipairs(effectStringComps) do
            effectComp = EffectManager.parseEffectCompSimple(effectStringComp)
            if effectComp.type ~= '' and next(effectComp.remainder) then
                for _, bonus in ipairs(effectComp.remainder) do
                    effectComp.mod = effectComp.mod + bonusMods[bonus]
                end
                effectStringComps[index] = EffectManager35E.rebuildParsedEffectComp(effectComp)
            end
        end
        rNewEffect.sName = rebuildParsedEffect(effectStringComps)
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
