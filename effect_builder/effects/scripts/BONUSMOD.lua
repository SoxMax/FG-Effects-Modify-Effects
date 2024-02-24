function createEffectString()
    local effectString = parentcontrol.window.effect.getStringValue() .. ": " .. effect_modifier.getValue()
    local descriptors = {}
    if not effect_bonus_type.isEmpty() then
        table.insert(descriptors, effect_bonus_type.getValue())
    end
    local effectGeneration = effect_generation.getStringValue()
    if effectGeneration ~= "" then
        table.insert(descriptors, effectGeneration)
    end

    if #descriptors > 0 then
        effectString = effectString .. " " .. table.concat(descriptors, ",")
    end
    return effectString
end
