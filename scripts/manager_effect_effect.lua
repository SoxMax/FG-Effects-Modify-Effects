local addEffect
local onEffect

function onInit()
    addEffect = EffectManager.addEffect
    -- EffectManager.addEffect = modifyEffectOnAdd

    ActionsManager.registerModHandler("effect", modifyEffect);
end

function modifyEffect(rSource, rTarget, rRoll)
    -- Debug.chat(rSource, rTarget, rRoll)
    local rEffect = EffectManager.decodeEffect(rRoll);
    local effectsModified = false
    local effectStringComps = EffectManager.parseEffect(rEffect.sName)
    local bonusMods = {}
    for index, effectStringComp in ipairs(effectStringComps) do
        effectComp = EffectManager.parseEffectCompSimple(effectStringComp)
        if effectComp.type ~= '' and effectComp.type ~= "BONUSMOD" and next(effectComp.remainder) then
            combineBonusMods(bonusMods, getBonusMods(rTarget, effectComp.remainder))
            for _, bonusType in ipairs(effectComp.remainder) do
                if bonusMods[bonusType] then
                    effectComp.mod = effectComp.mod + bonusMods[bonusType]
                    effectStringComps[index] = EffectManager35E.rebuildParsedEffectComp(effectComp)
                    effectsModified = true
                end
            end
        end
    end
    if effectsModified then
        rEffect.sName = EffectManager.rebuildParsedEffect(effectStringComps)
        rRoll.sDesc = EffectManager.encodeEffect(rEffect).sDesc
    end
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
    local bonusModsEffects = getEffectsByType(rActor, "BONUSMOD", bonusTypeFilter)
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

-- Cloned from manger_effect_35E.lua (EffectManager35E)
function getEffectsByType(rActor, sEffectType, aFilter, rFilterActor, bTargetedOnly)
	if not rActor then
		return {};
	end
	local results = {};
	
	-- Set up filters
	local aRangeFilter = {};
	local aOtherFilter = {};
	if aFilter then
		for _,v in pairs(aFilter) do
			if type(v) ~= "string" then
				table.insert(aOtherFilter, v);
			elseif StringManager.contains(DataCommon.rangetypes, v) then
				table.insert(aRangeFilter, v);
			else
				table.insert(aOtherFilter, v);
			end
		end
	end
	
	-- Determine effect type targeting
	local bTargetSupport = StringManager.isWord(sEffectType, DataCommon.targetableeffectcomps);
	
	-- Iterate through effects
	for _,v in ipairs(DB.getChildList(ActorManager.getCTNode(rActor), "effects")) do
		-- Check active
		local nActive = DB.getValue(v, "isactive", 0);
		if (nActive ~= 0) then
			-- Check targeting
			local bTargeted = EffectManager.isTargetedEffect(v);
			if not bTargeted or EffectManager.isEffectTarget(v, rFilterActor) then
				local sLabel = DB.getValue(v, "label", "");
				local aEffectComps = EffectManager.parseEffect(sLabel);
				
				-- Look for type/subtype match
				local nMatch = 0;
				for kEffectComp, sEffectComp in ipairs(aEffectComps) do
					local rEffectComp = EffectManager35E.parseEffectComp(sEffectComp);
					-- Handle conditionals
					if rEffectComp.type == "IF" then
						if not EffectManager35E.checkConditional(rActor, v, rEffectComp.remainder) then
							break;
						end
					elseif rEffectComp.type == "IFT" then
						if not rFilterActor then
							break;
						end
						if not EffectManager35E.checkConditional(rFilterActor, v, rEffectComp.remainder, rActor) then
							break;
						end
						bTargeted = true;
					
					-- Compare other attributes
					else
						-- Strip energy/bonus types for subtype comparison
						local aEffectRangeFilter = {};
						local aEffectOtherFilter = {};
						
						local aComponents = {};
						for _,vPhrase in ipairs(rEffectComp.remainder) do
							local nTempIndexOR = 0;
							local aPhraseOR = {};
							repeat
								local nStartOR, nEndOR = vPhrase:find("%s+or%s+", nTempIndexOR);
								if nStartOR then
									table.insert(aPhraseOR, vPhrase:sub(nTempIndexOR, nStartOR - nTempIndexOR));
									nTempIndexOR = nEndOR;
								else
									table.insert(aPhraseOR, vPhrase:sub(nTempIndexOR));
								end
							until nStartOR == nil;
							
							for _,vPhraseOR in ipairs(aPhraseOR) do
								local nTempIndexAND = 0;
								repeat
									local nStartAND, nEndAND = vPhraseOR:find("%s+and%s+", nTempIndexAND);
									if nStartAND then
										local sInsert = StringManager.trim(vPhraseOR:sub(nTempIndexAND, nStartAND - nTempIndexAND));
										table.insert(aComponents, sInsert);
										nTempIndexAND = nEndAND;
									else
										local sInsert = StringManager.trim(vPhraseOR:sub(nTempIndexAND));
										table.insert(aComponents, sInsert);
									end
								until nStartAND == nil;
							end
						end
						local j = 1;
						while aComponents[j] do
							if StringManager.contains(DataCommon.dmgtypes, aComponents[j]) or
                                    -- StringManager.contains(DataCommon.bonustypes, aComponents[j]) or
									aComponents[j] == "all" then
								-- Skip
							elseif StringManager.contains(DataCommon.rangetypes, aComponents[j]) then
								table.insert(aEffectRangeFilter, aComponents[j]);
							else
								table.insert(aEffectOtherFilter, aComponents[j]);
							end
							
							j = j + 1;
						end
					
						-- Check for match
						local comp_match = false;
						if rEffectComp.type == sEffectType then

							-- Check effect targeting
							if bTargetedOnly and not bTargeted then
								comp_match = false;
							else
								comp_match = true;
							end
						
							-- Check filters
							if #aEffectRangeFilter > 0 then
								local bRangeMatch = false;
								for _,v2 in pairs(aRangeFilter) do
									if StringManager.contains(aEffectRangeFilter, v2) then
										bRangeMatch = true;
										break;
									end
								end
								if not bRangeMatch then
									comp_match = false;
								end
							end
							if #aEffectOtherFilter > 0 then
								local bOtherMatch = false;
								for _,v2 in pairs(aOtherFilter) do
									if type(v2) == "table" then
										local bOtherTableMatch = true;
										for k3, v3 in pairs(v2) do
											if not StringManager.contains(aEffectOtherFilter, v3) then
												bOtherTableMatch = false;
												break;
											end
										end
										if bOtherTableMatch then
											bOtherMatch = true;
											break;
										end
									elseif StringManager.contains(aEffectOtherFilter, v2) then
										bOtherMatch = true;
										break;
									end
								end
								if not bOtherMatch then
									comp_match = false;
								end
							end
						end

						-- Match!
						if comp_match then
							nMatch = kEffectComp;
							if nActive == 1 then
								table.insert(results, rEffectComp);
							end
						end
					end
				end -- END EFFECT COMPONENT LOOP

				-- Remove one shot effects
				if nMatch > 0 then
					if nActive == 2 then
						DB.setValue(v, "isactive", "number", 1);
					else
						local sApply = DB.getValue(v, "apply", "");
						if sApply == "action" then
							EffectManager.notifyExpire(v, 0);
						elseif sApply == "roll" then
							EffectManager.notifyExpire(v, 0, true);
						elseif sApply == "single" then
							EffectManager.notifyExpire(v, nMatch, true);
						end
					end
				end
			end -- END TARGET CHECK
		end  -- END ACTIVE CHECK
	end  -- END EFFECT LOOP
	
	return results;
end
