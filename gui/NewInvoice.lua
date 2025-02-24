--
-- FS22 - Invoice - NewInvoice
--
-- @Interface: 1.2.0.0 b14651
-- @Author: KR-Softwares
-- @Date: 23.01.2022
-- @Version: 1.0.0.0
--
-- @Support: kr-softwares.com
--
-- Changelog:
-- 	v1.0.0.0 (23.01.2022):
--      - Release FS22
--

NewInvoice = {
	CONTROLS = {
		TABLE_FULLLIST = "newInvoiceFullList",
		TABLE_FULLLIST_TEMPLATE = "newInvoiceFullListRowTemplate",
		TABLE_FULLLIST_SLIDER = "newInvoiceFullListSlider",
		TABLE_CHOOSELIST = "newInvoiceListChooseWork",
		TABLE_CHOOSELIST_TEMPLATE = "newInvoiceListChooseWorkRowTemplate",
		TABLE_CHOOSELIST_SLIDER = "newInvoiceListChooseWorkSlider",
		BTN_ADDITEM = "btnAddItem",
		TEXT_SELECTFARM = "textSelectFarm",
		BTN_SELECTFARM = "btnSelectFarm",
		TEXT_SELECTFIELD = "textSelectField",
		BTN_SELECTFIELD = "btnSelectField",
		TEXT_COUNT = "textEntryCount",
		INPUT_COUNT = "inputEntryCount",
		TEXT_ENTRYAMOUNT = "textEntryAmount",
		TEXT_FULLCOST = "textFullCost",
		BTN_DELETEENTRY = "btnDeleteEntry",
		BTN_CREATEINVOICE = "btnCreateInvoice",
		INPUT_ADDITIONAL = "inputAdditional",
		INPUT_OWNPRICE = "inputOwnPrice",
		TEXT_UNIT = "textOwnPriceUnit",
	}
}
local NewInvoice_mt = Class(NewInvoice, MessageDialog)

function NewInvoice.new(target, custom_mt)
	local self = MessageDialog.new(target, custom_mt or NewInvoice_mt)

	-- self:registerControls(NewInvoice.CONTROLS)

	return self
end

function NewInvoice:onCreate()
	NewInvoice:superClass().onCreate(self)    
end

function NewInvoice:onGuiSetupFinished()
	NewInvoice:superClass().onGuiSetupFinished(self)
    
	self.newInvoiceFullList:setDataSource(self)
	self.newInvoiceFullList:setDelegate(self)
	self.newInvoiceFullList.isListFull = true

	self.newInvoiceListChooseWork:setDataSource(self)
	self.newInvoiceListChooseWork:setDelegate(self)
	self.newInvoiceListChooseWork.isListChooseWork = true
end

function NewInvoice:onOpen()
	NewInvoice:superClass().onOpen(self)
	self.currentNewEntry = {}
	self:resetNewEntry()	
	
	self.worksToChoose = {}
	self.fullList = {
		{
			items = {}
		}
	}

	self.selectedFarm = nil
	self.selectedFarmName = nil

	self:updateContentWorksToChoose()
    self:updateContentFullList()	
	self:updateFullCostText()
	self.btnDeleteEntry:setDisabled(true)
	self.btnCreateInvoice:setDisabled(true)
	self.btnSelectFarm:setText(g_i18n:getText("ui_newInvoice_noFarm"))

	self.textOwnPriceUnit:setText(g_i18n:getCurrencySymbol(true))
end

function NewInvoice:onClose()
	NewInvoice:superClass().onClose(self)
end

function NewInvoice:updateContentWorksToChoose()	
	self.worksToChoose = {
		{
			title = "",
			items = {}
		}
	}

	for _,entry in pairs(g_currentMission.invoices.works) do
		table.insert(self.worksToChoose[1].items, entry)
	end
	
	self.newInvoiceListChooseWork:reloadData() 
end

function NewInvoice:updateContentFullList()	
	self.newInvoiceFullList:reloadData() 
end

function NewInvoice:getNumberOfSections(list)
	if list.isListChooseWork then
		return #self.worksToChoose
	elseif list.isListFull then
		return #self.fullList
	end
	return 0
end

function NewInvoice:getNumberOfItemsInSection(list, section)
	if list.isListChooseWork then
		return #self.worksToChoose[section].items
	elseif list.isListFull then
		return #self.fullList[section].items
	end
	return 0
end

function NewInvoice:getTitleForSectionHeader(list, section)
	return ""
end

function NewInvoice:populateCellForItemInSection(list, section, index, cell)
	if list.isListChooseWork then
		local work = self.worksToChoose[section].items[index]    
		cell:getAttribute("workName"):setText(work.title)
		if work.unit == Invoice.UNIT_L then
			cell:getAttribute("workPrice"):setText(g_i18n:formatMoney(work.amount, 1, true, false) .. " / " .. g_i18n:getText("unit_liter"))
		else
			cell:getAttribute("workPrice"):setText(g_i18n:formatMoney(work.amount, 0, true, false) .. " / " .. work.unitStr)
		end
	elseif list.isListFull then
		local entry = self.fullList[section].items[index]    
		cell:getAttribute("workName"):setText(entry.title)
		cell:getAttribute("addText"):setText(entry.addText)
		cell:getAttribute("workPrice"):setText(g_i18n:formatMoney(entry.amount, 0, true, false))
	end
end

function NewInvoice:onClickBack(sender)
	self:close()
end

function NewInvoice:onClickSend(sender)
    local currentFarmId = -1
    local farm = g_farmManager:getFarmByUserId(g_currentMission.playerUserId)
    if farm ~= nil then
        currentFarmId = farm.farmId
    end

    g_currentMission.invoices:createNewInvoice(self.fullList[1].items, self.selectedFarm, currentFarmId)
	self:close()
end

function NewInvoice:onClickCreateItem()
	local work = self.currentNewEntry.selectedWork
	local title = work.title
	local amount = 0
	local area = 0
		
	if work.unit == Invoice.UNIT_STK or work.unit == Invoice.UNIT_STD or work.unit == Invoice.UNIT_L then
		if work.unit == Invoice.UNIT_STK then
			title = string.format("%s (%sx)", title, self.currentNewEntry.count)	
		elseif work.unit == Invoice.UNIT_L then
			title = string.format("%s (%.0f %s)", title, self.currentNewEntry.count, g_i18n:getText("unit_liter"))	
		else
			title = string.format("%s (%sx)", title, self.currentNewEntry.count)	
		end
		amount = self.currentNewEntry.ownPrice * self.currentNewEntry.count
	elseif work.unit == Invoice.UNIT_HA then
		if self.currentNewEntry.selectedFieldArea ~= nil then		
			area = 	self.currentNewEntry.selectedFieldArea
			title = string.format("%s (%s HA)", title, g_i18n:formatNumber(self.currentNewEntry.selectedFieldArea, 2))	
			amount = work.amount * self.currentNewEntry.selectedFieldArea				
		end
	end
	
	table.insert(self.fullList[1].items, {
		id = work.id,
		title = title,
		amount = amount,
		area = area,
		count = self.currentNewEntry.count,
		ownPrice = self.currentNewEntry.ownPrice,
		addText = self.inputAdditional.text,
		unit = work.unit,
	})

	self:updateContentFullList()
	self:resetNewEntry()
	self:updateFullCostText()
	self.btnCreateInvoice:setDisabled(#self.fullList[1].items == 0 or self.selectedFarm == nil)
end

function NewInvoice:onClickSelectField()
    local dialog = g_gui:showDialog("SelectField")
    if dialog ~= nil then
        dialog.target:setMode(SelectField.MODE_FIELD)
        dialog.target:setTargetScreen(self)
    end
end

function NewInvoice:selectField(field)
	self.currentNewEntry.selectedFieldArea = field.area
	self.btnSelectField:setText(string.format(g_i18n:getText("ui_selectField_fieldArea"), field.id, g_i18n:formatNumber(field.area, 2)))
	self:updateEntryAmount()
	self:updateAddButton()
end

function NewInvoice:onClickSelectFarm()
    local dialog = g_gui:showDialog("SelectField")
    if dialog ~= nil then
        dialog.target:setMode(SelectField.MODE_FARM)
        dialog.target:setTargetScreen(self)
    end
end

function NewInvoice:selectFarm(farm)
	if farm ~= nil then
		self.selectedFarm = farm.farmId
		self.selectedFarmName = farm.name
		self.btnSelectFarm:setText(string.format(g_i18n:getText("ui_newInvoice_farmX"), farm.name))
	end
	self.btnCreateInvoice:setDisabled(#self.fullList[1].items == 0 or self.selectedFarm == nil)
end

function NewInvoice:onEnterPressedField()
	local newCount = self.inputEntryCount.text

	if KrSoftwareUtils.getStringIsInteger(newCount) then
		self.currentNewEntry.count = tonumber(newCount)
		self:updateEntryAmount()
		self:updateAddButton()
	else 
		self.inputEntryCount:setText(tostring(self.currentNewEntry.count))
	end
end

function NewInvoice:onEnterPressedFieldPrice()
	local ownPrice = self.inputOwnPrice.text

	if tonumber(ownPrice) ~= nil then
		self.currentNewEntry.ownPrice = tonumber(ownPrice)
		self:updateEntryAmount()
		self:updateAddButton()
	else 
		self.inputOwnPrice:setText(tostring(self.currentNewEntry.ownPrice))
	end
end

function NewInvoice:resetNewEntry(ignoreUiElements)	
	self.currentNewEntry.count = 1
	self.currentNewEntry.ownPrice = 0

	self.inputAdditional:setText("")

	if ignoreUiElements == nil or not ignoreUiElements then
		self.inputEntryCount:setText("1")
		self.btnSelectField:setText(g_i18n:getText("ui_newInvoice_noField"))
	end
	self:updateEntryAmount()
	self:updateAddButton()
end

function NewInvoice:onListSelectionChanged(list, section, index)
	if list.isListChooseWork then
		local work = self.worksToChoose[section].items[index] 
		
		self.currentNewEntry.selectedWork = work
		self.currentNewEntry.ownPrice = work.amount
		self.inputOwnPrice:setText(tostring(work.amount))
		
		if work.unit == Invoice.UNIT_STK then
			self.textSelectField:setDisabled(true)
			self.btnSelectField:setDisabled(true)
			self.textEntryCount:setDisabled(false)
			self.inputEntryCount:setDisabled(false)
			self.textEntryCount:setText(g_i18n:getText("ui_newInvoice_countStk"))
		elseif work.unit == Invoice.UNIT_STD then
			self.textSelectField:setDisabled(true)
			self.btnSelectField:setDisabled(true)
			self.textEntryCount:setDisabled(false)
			self.inputEntryCount:setDisabled(false)
			self.textEntryCount:setText(g_i18n:getText("ui_newInvoice_countStd"))
		elseif work.unit == Invoice.UNIT_HA then
			self.textSelectField:setDisabled(false)
			self.btnSelectField:setDisabled(false)
			self.textEntryCount:setDisabled(true)
			self.inputEntryCount:setDisabled(true)
		elseif work.unit == Invoice.UNIT_L then
			self.textSelectField:setDisabled(true)
			self.btnSelectField:setDisabled(true)
			self.textEntryCount:setDisabled(false)
			self.inputEntryCount:setDisabled(false)
			self.textEntryCount:setText(g_i18n:getText("ui_newInvoice_countL"))
		end
	elseif list.isListFull then
		self.currentFullEntryIndex = index
		self.btnDeleteEntry:setDisabled(false)
	end

	self:updateEntryAmount()
	self:updateAddButton()
end

function NewInvoice:updateEntryAmount()
	local amount = 0
local ownPrice = self.inputOwnPrice.text


    if tonumber(ownPrice) ~= nil then
       self.currentNewEntry.ownPrice = tonumber(ownPrice)
end
	if self.currentNewEntry.selectedWork ~= nil then
		local work = self.currentNewEntry.selectedWork

		if work.unit == Invoice.UNIT_STK or work.unit == Invoice.UNIT_STD or work.unit == Invoice.UNIT_L then			
			amount = math.ceil(self.currentNewEntry.ownPrice * self.currentNewEntry.count)
		elseif work.unit == Invoice.UNIT_HA then
			if self.currentNewEntry.selectedFieldArea ~= nil then								
				amount = self.currentNewEntry.ownPrice * self.currentNewEntry.selectedFieldArea	
			end
		end
	end

	self.textEntryAmount:setText(g_i18n:formatMoney(amount, 0, true, false))
end

function NewInvoice:updateAddButton()
	local state = self.currentNewEntry.selectedWork == nil
	if self.currentNewEntry.selectedWork ~= nil then		
		local work = self.currentNewEntry.selectedWork
		if work.unit == Invoice.UNIT_STK or work.unit == Invoice.UNIT_STD or work.unit == Invoice.UNIT_L then
			state = self.currentNewEntry.count == 0
		elseif work.unit == Invoice.UNIT_HA then
			state = self.currentNewEntry.selectedFieldArea == nil
		end
	end

	self.btnAddItem:setDisabled(state)
end

function NewInvoice:updateFullCostText()
	local amount = 0
	for _,item in pairs(self.fullList[1].items) do
		amount = amount + item.amount
	end
	self.textFullCost:setText(g_i18n:formatMoney(amount, 0, true, false))
end

function NewInvoice:onClickDeleteEntry()
	if self.currentFullEntryIndex > 0 then
		table.remove(self.fullList[1].items, self.currentFullEntryIndex)
		self.currentFullEntryIndex = -1		
		self.btnDeleteEntry:setDisabled(true)
		self:updateContentFullList()
		self:updateFullCostText()
		self.btnCreateInvoice:setDisabled(#self.fullList[1].items == 0)
	end
end