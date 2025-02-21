--
-- FS22 - Invoices
--
-- @Interface: 1.5.0.0 b17296
-- @Author: KR-Softwares
-- @Date: 18.06.2022
-- @Version: 1.1.0.0
--
-- @Support: kr-softwares.com
--
-- Changelog:
-- 	v1.0.0.0 (29.01.2022):
--      - Convert from from FS19 to FS22
-- 	v1.1.0.0 (18.06.2022):
--      - Own text can be defined for each entry
--		- Own price can be defined for each entry
--		- Position "Goods" with unit liter added
--

Invoices = {}
Invoices.dir = g_currentModDirectory
Invoices.modName = g_currentModName

source(Invoices.dir .. "KrSoftwareUtils.lua")
source(Invoices.dir .. "Invoice.lua")
source(Invoices.dir .. "events/InitalInvoiceEvent.lua")
source(Invoices.dir .. "events/CreateInvoiceEvent.lua")
source(Invoices.dir .. "events/ChangeStateInvoiceEvent.lua")
source(Invoices.dir .. "gui/InGameMenuInvoices.lua")
source(Invoices.dir .. "gui/NewInvoice.lua")
source(Invoices.dir .. "gui/InvoiceDetails.lua")
source(Invoices.dir .. "gui/SelectField.lua")

function Invoices:loadMap()
	KrSoftwareUtils.loadTextFromMod(Invoices.modName, Invoices.dir)
	KrSoftwareUtils.mergeModTranslations(g_i18n)

	local ui = g_currentMission.inGameMenu

    g_gui:loadProfiles(Invoices.dir .. "gui/guiProfiles.xml")

	local guiInvoices = InGameMenuInvoices.new(g_i18n, g_messageCenter) 
	g_gui:loadGui(Invoices.dir .. "gui/InGameMenuInvoices.xml", "ingameMenuInvoices", guiInvoices, true)
	
	local newInvoice = NewInvoice.new(g_i18n) 
	g_gui:loadGui(Invoices.dir .. "gui/NewInvoice.xml", "NewInvoice", newInvoice)

	local invoiceDetails = InvoiceDetails.new(g_i18n) 
	g_gui:loadGui(Invoices.dir .. "gui/InvoiceDetails.xml", "InvoiceDetails", invoiceDetails)

	local selectField = SelectField.new(g_i18n) 
	g_gui:loadGui(Invoices.dir .. "gui/SelectField.xml", "SelectField", selectField)

	Invoices.fixInGameMenu(guiInvoices,"ingameMenuInvoices", {0,0,1024,1024}, 2, Invoices:makeIsInvoicesEnabledPredicate())

	g_currentMission.invoices = self

	self.invoiceId = 0
	self.invoiceList = {}
	self.works = {}
		
	self:loadDataFromFile()

	FSBaseMission.saveSavegame = Utils.appendedFunction(FSBaseMission.saveSavegame, Invoices.saveToXmlFile)
	self:loadFromXMLFile()

	guiInvoices:initialize()	
end

function Invoices:makeIsInvoicesEnabledPredicate()
	return function ()
		return true
	end
end

function Invoices:delete()
	
end

function Invoices:saveToXmlFile()
	if(not g_currentMission:getIsServer()) then return end

	local savegameFolderPath = g_currentMission.missionInfo.savegameDirectory.."/"
	if savegameFolderPath == nil then
		savegameFolderPath = ('%ssavegame%d'):format(getUserProfileAppPath(), g_currentMission.missionInfo.savegameIndex.."/")
	end

	local key = "invoices";
	local xmlFile = createXMLFile(key, savegameFolderPath.."invoices.xml", key);

	local i = 0	
	for _,invoice in pairs(g_currentMission.invoices.invoiceList) do
        local keyInvoice = string.format("%s.invoice(%d)", key, i)
		invoice:saveToXmlFile(xmlFile, keyInvoice)		
		i = i + 1
	end
    
	saveXMLFile(xmlFile);

	delete(xmlFile);
end

function Invoices:loadFromXMLFile()
	if(not g_currentMission:getIsServer()) then return end
	
	local savegameFolderPath = g_currentMission.missionInfo.savegameDirectory;
	if savegameFolderPath == nil then
		savegameFolderPath = ('%ssavegame%d'):format(getUserProfileAppPath(), g_currentMission.missionInfo.savegameIndex)
	end
	savegameFolderPath = savegameFolderPath.."/"
	local key = "invoices"

	if fileExists(savegameFolderPath.."invoices.xml") then
		local xmlFile = loadXMLFile(key, savegameFolderPath.."invoices.xml");
		
		local i = 0	
		while true do
			local keyInvoice = string.format(key .. ".invoice(%d)", i)

			if not hasXMLProperty(xmlFile, keyInvoice) then
				break
			end

			local newInvoice = Invoice.new()
			newInvoice.id = g_currentMission.invoices:getNextId()
			newInvoice:loadFromXMLFile(xmlFile, keyInvoice)
		
			table.insert(g_currentMission.invoices.invoiceList, newInvoice)
			
			i = i + 1
		end

		delete(xmlFile)
	end
end

function Invoices:getNextId()
	self.invoiceId = self.invoiceId + 1
	return self.invoiceId
end

function Invoices:createNewInvoice(dataFromUi, farmId, currentFarmId)
	local newInvoice = Invoice.new()	
	newInvoice:loadFromUi(0, dataFromUi, farmId, currentFarmId)

	if not g_currentMission.missionDynamicInfo.isMultiplayer then
	
		table.insert(self.invoiceList, newInvoice)
		
		if g_currentMission.invoicesUi ~= nil then
			g_currentMission.invoicesUi:updateContent()
		end
	else
		g_client:getServerConnection():sendEvent(CreateInvoiceEvent.new(newInvoice)) 
	end
end

function Invoices:getInvoiceById(id)
	for _,invoice in pairs(self.invoiceList) do
		if invoice.id == id then
			return invoice
		end
	end
end

function Invoices:deleteInvoiceById(id)
	local deleteKey = -1
	for k,invoice in pairs(self.invoiceList) do
		if invoice.id == id then
			deleteKey = k
			break
		end
	end
	if deleteKey > 0 then
		table.remove(self.invoiceList, deleteKey)
	end
end

function Invoices:getWorkData(id)
	for _,work in pairs(self.works) do
		if work.id == id then
			return work
		end
	end
end

function Invoices:loadDataFromFile()
	local savegameFolderPath = g_currentMission.missionInfo.savegameDirectory;
	if savegameFolderPath == nil then
		savegameFolderPath = ('%ssavegame%d'):format(getUserProfileAppPath(), g_currentMission.missionInfo.savegameIndex);
	end;
	local xmlPath = Invoices.dir .. "data.xml"
	local key = "data";

	if fileExists(xmlPath) then
		local xmlFile = loadXMLFile(key, xmlPath);
		
		local i = 0	
		while true do
			local keyWork = string.format(key .. ".works.work(%d)", i)

			if not hasXMLProperty(xmlFile, keyWork) then
				break
			else

				local unitStr = getXMLString(xmlFile, keyWork .. "#unit")
				
				local unit = Invoice.UNIT_STK
				if unitStr:lower() == "std" then
					unit = Invoice.UNIT_STD
				elseif unitStr:lower() == "ha" then
					unit = Invoice.UNIT_HA
				elseif unitStr:lower() == "l" then
					unit = Invoice.UNIT_L
				end

				local name = getXMLString(xmlFile, keyWork .. "#name")

				local work = {
					id = i + 1,
					name = name,
					title = g_i18n:getText(name),
					amount = getXMLFloat(xmlFile, keyWork .. "#amount") * g_i18n:getCurrencyFactor(),
					unit = unit,
					unitStr = g_i18n:getText("invoiceUnit_" .. unitStr:lower()),
				}
				
				table.insert(self.works, work)
			end
			i = i + 1
		end
		
		delete(xmlFile)
	end
end


-- from Courseplay
function Invoices.fixInGameMenu(frame,pageName,uvs,position,predicateFunc)
	local inGameMenu = g_gui.screenControllers[InGameMenu]

	-- remove all to avoid warnings
	for k, v in pairs({pageName}) do
		inGameMenu.controlIDs[v] = nil
	end

	-- inGameMenu:registerControls({pageName})

	
	inGameMenu[pageName] = frame
	inGameMenu.pagingElement:addElement(inGameMenu[pageName])

	inGameMenu:exposeControlsAsFields(pageName)

	for i = 1, #inGameMenu.pagingElement.elements do
		local child = inGameMenu.pagingElement.elements[i]
		if child == inGameMenu[pageName] then
			table.remove(inGameMenu.pagingElement.elements, i)
			table.insert(inGameMenu.pagingElement.elements, position, child)
			break
		end
	end

	for i = 1, #inGameMenu.pagingElement.pages do
		local child = inGameMenu.pagingElement.pages[i]
		if child.element == inGameMenu[pageName] then
			table.remove(inGameMenu.pagingElement.pages, i)
			table.insert(inGameMenu.pagingElement.pages, position, child)
			break
		end
	end

	inGameMenu.pagingElement:updateAbsolutePosition()
	inGameMenu.pagingElement:updatePageMapping()
	
	inGameMenu:registerPage(inGameMenu[pageName], position, predicateFunc)
	local iconFileName = Utils.getFilename('images/menuIcon.dds', Invoices.dir)
	inGameMenu:addPageTab(inGameMenu[pageName],iconFileName, GuiUtils.getUVs(uvs))
	-- inGameMenu[pageName]:applyScreenAlignment()
	-- inGameMenu[pageName]:updateAbsolutePosition()

	for i = 1, #inGameMenu.pageFrames do
		local child = inGameMenu.pageFrames[i]
		if child == inGameMenu[pageName] then
			table.remove(inGameMenu.pageFrames, i)
			table.insert(inGameMenu.pageFrames, position, child)
			break
		end
	end

	inGameMenu:rebuildTabList()
end

addModEventListener(Invoices)

-- call init event

function Invoices:sendInitialClientState(connection, user, farm)
	connection:sendEvent(InitalInvoiceEvent.new())
end

FSBaseMission.sendInitialClientState = Utils.appendedFunction(FSBaseMission.sendInitialClientState, Invoices.sendInitialClientState)