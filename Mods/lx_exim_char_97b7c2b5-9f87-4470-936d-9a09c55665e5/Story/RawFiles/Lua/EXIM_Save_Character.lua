function SaveCharacterData(character, charName, tempChar)
	print("Storing character data...")
	local data = {}
	-- Misc
	local misc = {}
	misc["name"] = charName
	misc["attributePoints"] = CharacterGetAttributePoints(character)
	misc["abilityPoints"] = CharacterGetAbilityPoints(character)
	misc["civilPoints"] = CharacterGetCivilAbilityPoints(character)
	misc["talentPoints"] = CharacterGetTalentPoints(character)
	misc["level"] = CharacterGetLevel(character)
	data["misc"] = misc
	
	
	-- Attributes
	local attributes = {}
	local attributeStrings = {
	"Strength", 
	"Finesse", 
	"Intelligence", 
	"Constitution", 
	"Memory", 
	"Wits",
	"Experience"}
	--local attributes = "--Attributes\r\n"
	for ind,att in ipairs(attributeStrings) do
		local cur = ""
		if att == "Experience" then cur = NRD_CharacterGetStatInt(character, "Experience")
		else cur = CharacterGetBaseAttribute(character, att) end
		attributes[att] = cur
		--attributes = attributes..cur.."\r\n"
	end
	attributes["MaxMP"] = GetVarInteger(character, "LX_Max_SP")
	data["attributes"] = attributes
	--attributes = ParseDataList(character, attributeStrings, CharacterGetBaseAttribute(), "--Attributes\r\n")
	
	-- Abilities
	local abilitiesStrings = Abilities()
	local abilities = {}
	for ind,abi in ipairs(abilitiesStrings) do
		local cur = CharacterGetBaseAbility(character, abi)
		if cur ~= nil and cur ~= 0 then
			abilities[abi] = cur
		end
	end
	data["abilities"] = abilities
	
	-- Civil
	local civilStrings = Civil()
	local civil = {}
	for ind,civ in ipairs(civilStrings) do
		local cur = CharacterGetBaseAbility(character, civ)
		if cur ~= 0 then
			civil[civ] = cur
		end
	end
	data["civil"] = civil
	
	-- Talents
	local talentsStrings = Talents()
	
	local talents = {}
	for ind,tal in ipairs(talentsStrings) do
		local cur = CharacterHasTalent(character, tal)
		if cur ~= 0 then
			talents[tal] = 1
		end
	end
	data["talents"] = talents
	
	--SaveEquippedItems(character)
	
	--Save part
	local clearedName = ClearSpecialCharacters(charName)
	local path = clearedName..".charsave"
	print(path)
	local characterData = {}
	--local hotbar = GetHotbar(character)
	characterData["hotbar"] = Ext.JsonParse(GetVarString(character, "LX_Hotbar"))
	characterData["data"] = data
	characterData["inventory"] = inventoryTemplates
	local skills = ParseSkills(tempChar)
	characterData["skills"] = skills
	
	-- Extension data
	local extData = GetVarString(character, "LX_EXIM_Extension_Data")
	if extData ~= nil then 
		extData = Ext.JsonParse(extData)
		Ext.Print(extData)
		ParseExtData(extData)
		characterData["ext"] = extData 
	end
	local jsonData = Ext.JsonStringify(characterData)
	local content = jsonData--..skills--..equipment

	NRD_SaveFile(path, content)
	RemoveTemporaryCharacter(tempChar)
	ReequipCharacter(character)
end

function ParseExtData(data)
	if type(data) ~= "table" then return end
	for i,cont in pairs(data) do
		if type(cont) == "string" then
			local parsed = Ext.JsonParse(cont)
			data[i] = parsed
			ParseExtData(parsed)
		end
	end
end

function ClearSpecialCharacters(str)
	local cleared = ""
	--cleared = str:gsub("%s+", "_")
	--cleared = str:gsub("é", "e")
	cleared = str:gsub("[^%w-_]", "") -- Thanks Zerd. I hate regex so much.
	-- cleared = string.gsub(cleared, "[^%w-]", "_")
	local i = 0
	for word in str:gmatch("[A-Z]*[a-z]*[1-9]*") do
		if i == 0 then
			cleared = word
		else
			cleared = cleared.."_"..word 
		end
		i = i + 1
	end
	cleared = string.gsub(cleared, "_+", "_")
	return cleared
end

function ParseSkills(character)
	skills = GetVarString(character, "LX_Skills_Save")
	if skills ~= nil then
		skills = skills:gsub("<br>", ",")
		skills = SplitString(skills, ",")
		SetVarString(character, "LX_Skills_Save", "")
	else
		return {}
	end
	return skills
end

function GetHotbar(character)
	local hotbar = {}
	local i = 0
	while i < 144 do
		local slot = {"Skill", NRD_SkillBarGetSkill(character, i)}
		if slot[2] == nil then
			local shortcut = NRD_SkillBarGetItem(character, i)
			if shortcut ~= nil then
				local item = GetTemplate(shortcut)
				slot = {"Item", item} 
			end
		end
		if slot[2] ~= nil then hotbar[i] = slot end
		i = i+1
	end
	SetVarString(character, "LX_Hotbar", Ext.JsonStringify(hotbar))
	UnequipCharacter(character)
	return true
end

