--
-- FS22 - KrSoftwareUtils
--
-- @Interface: 1.2.0.0 b14651
-- @Author: KR-Softwares
-- @Date: 29.01.2022
-- @Version: 1.0.0.2
--
-- @Support: kr-softwares.com
--
-- Changelog:
-- 	v1.0.0.2 (29.01.2022):
--		- Add function getStringIsInteger
--      - Support mod: Invoices 1.0.0.0
-- 	v1.0.0.1 (24.01.2022):
--      - Add function appendedFunction2
--      - Support mod: FieldLease 1.0.0.0
-- 	v1.0.0.0 (23.01.2022):
--      - First Release
--      - Support mod: FieldCalculator 1.0.0.0
--

KrSoftwareUtils = {}

KrSoftwareUtils.fallbackText = {}

function KrSoftwareUtils.loadTextFromMod(modName, loadingDirectory)
	if loadingDirectory ~= nil then
		local baseLanguageFullPath = KrSoftwareUtils.getLanguagesFullPath(loadingDirectory)
		KrSoftwareUtils.loadLanguagesEntries(modName, baseLanguageFullPath, "l10n.elements.e(%d)")

		local fallbackPath = string.gsub(baseLanguageFullPath, "l10n" .. g_languageSuffix, "l10n_en")
		KrSoftwareUtils.loadLanguagesEntries(modName, fallbackPath, "l10n.elements.e(%d)", KrSoftwareUtils.fallbackText)
        
        --print("Standard language XML file has been loaded successfully.")
	end
end

function KrSoftwareUtils.getLanguagesFullPath(modPath)
	local languageSuffixs = {g_languageSuffix, "_en"}
	for i = 1, 2 do
		local fullPath = string.format("%sl10n%s.xml", modPath, languageSuffixs[i])
		if fileExists(fullPath) then
			return fullPath
		else
			fullPath = string.format("%slanguages/l10n%s.xml", modPath, languageSuffixs[i])
			if fileExists(fullPath) then
				return fullPath
			end
		end
	end

	return
end

function KrSoftwareUtils.loadLanguagesEntries(modName, fullPath, baseKey, globalTexts)
	if globalTexts == nil then
		globalTexts = getfenv(0).g_i18n.texts
	end
	
	local duplicateTable = {}
	local rootModName = KrSoftwareUtils.getRootModName(modName)

	local xmlFile = loadXMLFile("TempConfig", fullPath)

	local i = 0
	while true do
		local key = string.format(baseKey, i)
		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local k = getXMLString(xmlFile, key.."#k")
		local v = getXMLString(xmlFile, key.."#v")

		if k ~= nil and v ~= nil then
            if globalTexts[k] == nil then
                globalTexts[k] = v
            else
                table.insert(duplicateTable, k)
            end
		end

		i = i + 1
	end

	delete(xmlFile)

	if #duplicateTable > 0 then
		local text = "The following duplicate text entries have been found in '%s' (%s)! Please remove these."
		--g_debug:printWarning(self.scriptDebugId, text, fullPath, modName)

		for i = 1, #duplicateTable do
			local name = duplicateTable[i]
			--g_debug:printWarning(self.scriptDebugId, "      %d: %s", i, name)
		end

		duplicateTable = nil
	end
end

function KrSoftwareUtils.getText(textName, endText, backup)
	if textName ~= nil then
		local text = backup or ""

		if textName:sub(1, 6) == "$l10n_" then
			local subText = textName:sub(7)
			if g_i18n:hasText(subText) then
				text = g_i18n:getText(subText)
			end
		elseif g_i18n:hasText(textName) then
			text = g_i18n:getText(textName)
		end

		if text ~= "" then
			if endText ~= nil then
				return text .. tostring(endText)
			end

			return text
		end

		if KrSoftwareUtils.fallbackText[textName] ~= nil then
			return KrSoftwareUtils.fallbackText[textName]
		end

		return g_i18n:getText(textName)
	end

	return ""
end

function KrSoftwareUtils.getRootModName(modName)
	if modName:sub(1, 5) == "FS22_" then
		if modName:sub(-7) == "_update" then
			return modName:sub(6, modName:len() - 7)
		else
			return modName:sub(6)
		end
	else
		if modName:sub(-7) == "_update" then
			return modName:sub(1, modName:len() - 7)
		else
			return modName:sub(1)
		end
	end
end

-- Copy from Gps-Mod :)
function KrSoftwareUtils.mergeModTranslations(i18n)
    -- We can copy all our translations to the global table because we prefix everything with guidanceSteering_
    -- Thanks for blocking the getfenv Giants..
    local modEnvMeta = getmetatable(_G)
    local env = modEnvMeta.__index

    local global = env.g_i18n.texts
    for key, text in pairs(i18n.texts) do
        global[key] = text
    end
end

function KrSoftwareUtils.appendedFunction2(oldFunc, newFunc)
    if oldFunc ~= nil then
        return function (s, ...)
            local val = oldFunc(s, ...)
			newFunc(s, ...)
			return val
        end
    else
        return newFunc
    end
end

--https://www.codegrepper.com/code-examples/whatever/lua+check+if+string+is+number
function KrSoftwareUtils.getStringIsInteger(str)
	return not (str == "" or str:find("%D"))
end