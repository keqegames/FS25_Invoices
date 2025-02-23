--
-- FS25 - InvoiceManager
--
-- @Interface: 1.0.0.0
-- @Author: Keqe Games
-- @Date: 22.02.2022
-- @Version: 1.0.0.0
--
-- Changelog:
-- 	v1.0.0.0 (25.02.2022):
--      - Initial Release

InvoiceManagerStart = {}
InvoiceManagerStart.dir = g_currentModDirectory
InvoiceManagerStart.modName = g_currentModName

source(InvoiceManagerStart.dir .. "scripts/InGameMenuInvoices.lua")

function InvoiceManagerStart:loadMap()
	local ui = g_currentMission.inGameMenu

	-- if InvoiceManagerStart.debug then
	-- 	print("INVOICES---- InvoiceManagerStart "..g_currentMission.missionInfo.savegameDirectory.."/guiProfiles.xml")
	-- 	local xmlFile = loadXMLFile("Temp", "dataS/guiProfiles.xml")
	-- 	saveXMLFileTo(xmlFile, g_currentMission.missionInfo.savegameDirectory.."/guiProfiles.xml")
	-- 	delete(xmlFile);
	-- end

    g_gui:loadProfiles(InvoiceManagerStart.dir .. "gui/guiProfiles.xml")

	local guiInvoiceManagerStart = InGameMenuInvoices.new(g_i18n) 
	g_gui:loadGui(InvoiceManagerStart.dir .. "gui/InGameMenuInvoices.xml", "inGameMenuInvoices", guiInvoiceManagerStart, true)
	
	-- local locationFrame = LocationFrame.new(g_i18n) 
	-- g_gui:loadGui(InvoiceManagerStart.dir .. "gui/StorageLocationFrame.xml", "StorageLocationFrame", locationFrame)

	-- local allSellPointsFrame = AllSellPointFrame.new(g_i18n) 
	-- g_gui:loadGui(InvoiceManagerStart.dir .. "gui/AllSellPointFrame.xml", "AllSellPointFrame", allSellPointsFrame)
	
	InvoiceManagerStart.fixInGameMenu(guiInvoiceManagerStart,"inGameMenuInvoices", {0,0,1024,1024}, 2, InvoiceManagerStart:makeIsInvoiceManagerStartEnabledPredicate())

	guiInvoiceManagerStart:initialize()

end

function InvoiceManagerStart:makeIsInvoiceManagerStartEnabledPredicate()
	return function () return true end
end

-- from Courseplay
function InvoiceManagerStart.fixInGameMenu(frame,pageName,uvs,position,predicateFunc)
	local inGameMenu = g_gui.screenControllers[InGameMenu]
	local abovePrices = 0;

	if InvoiceManagerStart.debug then
		print("INVOICES---- InvoiceManagerStart.fixInGameMenu")
		DebugUtil.printTableRecursively(inGameMenu.pagingElement)
	end

	-- remove all to avoid warnings
	for k, v in pairs({pageName}) do
		inGameMenu.controlIDs[v] = nil
	end

	for i = 1, #inGameMenu.pagingElement.elements do
		local child = inGameMenu.pagingElement.elements[i]
		if child == inGameMenu["pageStatistics"] then
			abovePrices = i;
			if InvoiceManagerStart.debug then
				print("INVOICES---- posição estatística encontrada - "..tostring(abovePrices))
			end
		end
	end

	if abovePrices == 0 then
		abovePrices = position
	end
	
	inGameMenu[pageName] = frame
	inGameMenu.pagingElement:addElement(inGameMenu[pageName])

	inGameMenu:exposeControlsAsFields(pageName)

	for i = 1, #inGameMenu.pagingElement.elements do
		local child = inGameMenu.pagingElement.elements[i]
		if child == inGameMenu[pageName] then
			table.remove(inGameMenu.pagingElement.elements, i)
			table.insert(inGameMenu.pagingElement.elements, abovePrices, child)
			break
		end
	end

	for i = 1, #inGameMenu.pagingElement.pages do
		local child = inGameMenu.pagingElement.pages[i]
		if child.element == inGameMenu[pageName] then
			table.remove(inGameMenu.pagingElement.pages, i)
			table.insert(inGameMenu.pagingElement.pages, abovePrices, child)
			break
		end
	end

	inGameMenu.pagingElement:updateAbsolutePosition()
	inGameMenu.pagingElement:updatePageMapping()
	
	inGameMenu:registerPage(inGameMenu[pageName], position, predicateFunc)
	local iconFileName = Utils.getFilename('images/iconMenu.dds', InvoiceManagerStart.dir)
	inGameMenu:addPageTab(inGameMenu[pageName],iconFileName, GuiUtils.getUVs(uvs))
--	inGameMenu[pageName]:applyScreenAlignment()
--	inGameMenu[pageName]:updateAbsolutePosition()

    print("INVOICES---- Cria Menu")

	for i = 1, #inGameMenu.pageFrames do
		local child = inGameMenu.pageFrames[i]
		if child == inGameMenu[pageName] then
			table.remove(inGameMenu.pageFrames, i)
			table.insert(inGameMenu.pageFrames, abovePrices, child)
			break
		end
	end

	inGameMenu:rebuildTabList()
end

addModEventListener(InvoiceManagerStart)
