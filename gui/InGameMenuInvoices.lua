--
-- FS22 - FieldLease - InGameMenuInvoices
--
-- @Interface: 1.2.0.0 b14651
-- @Author: KR-Softwares
-- @Date: 29.01.2022
-- @Version: 1.0.0.0
--
-- @Support: kr-softwares.com
--
-- Changelog:
-- 	v1.0.0.0 (29.01.2022):
--      Release FS22
--

InGameMenuInvoices = {}
InGameMenuInvoices._mt = Class(InGameMenuInvoices, TabbedMenuFrameElement)

InGameMenuInvoices.CONTROLS = {
	TABLE_INCOMING = "invoicesTableIncoming",
	TABLE_OUTGOING = "invoicesTableOutgoing",
	TABLE_INCOMING_TEMPLATE = "invoicesTableIncomingRowTemplate",
	TABLE_OUTGOING_TEMPLATE = "invoicesTableOutgoingRowTemplate",
	TABLE_INCOMING_SLIDER = "tableSliderIncoming",
	TABLE_OUTGOING_SLIDER = "tableSliderOutgoing",
}

function InGameMenuInvoices.new(i18n, messageCenter)
	local self = InGameMenuInvoices:superClass().new(nil, InGameMenuInvoices._mt)

    self.name = "InGameMenuInvoices"
    self.i18n = i18n
    self.messageCenter = messageCenter

	if not g_currentMission:getIsServer() then
        self.messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, self.notifyPlayerFarmChanged, self)
    end
    
    -- self:registerControls(InGameMenuInvoices.CONTROLS)

	local showButtons = not g_currentMission.missionDynamicInfo.isMultiplayer or g_currentMission.inGameMenu.playerFarmId ~= FarmManager.SPECTATOR_FARM_ID

    self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK
	}
	self.btnNewInvoice = {
		text = self.i18n:getText("ui_btn_newInvoice"),
		inputAction = InputAction.MENU_EXTRA_1,
        disabled = not showButtons,
		callback = function ()
			self:onClickNewInvoice()
		end
	}    
	self.btnPayInvoice = {
		text = self.i18n:getText("ui_btn_payInvoice"),
		inputAction = InputAction.MENU_ACCEPT,
        disabled = true,
		callback = function ()
			self:onClickPayInvoice()
		end
	}   
	self.btnDeleteInvoice = {
		text = self.i18n:getText("ui_btn_deleteInvoice"),
		inputAction = InputAction.MENU_EXTRA_2,
        disabled = true,
		callback = function ()
			self:onClickDeleteInvoice()
		end
	}   
    
	self.btnShowInvoiceDetails = {
		text = self.i18n:getText("ui_btn_showInvoiceDetails"),
		inputAction = InputAction.MENU_ACTIVATE,
        disabled = true,
		callback = function ()
			self:onClickShowInvoiceDetails()
		end
	}    
    
    self:setMenuButtonInfo({
        self.backButtonInfo,
        self.btnNewInvoice,
        self.btnPayInvoice,
        self.btnDeleteInvoice,
        self.btnShowInvoiceDetails
    })

    return self
end

function InGameMenuInvoices:notifyPlayerFarmChanged(player)
	local showButtons = not g_currentMission.missionDynamicInfo.isMultiplayer or g_currentMission.inGameMenu.playerFarmId ~= FarmManager.SPECTATOR_FARM_ID
    self.btnNewInvoice.disabled = not showButtons
    self:setMenuButtonInfoDirty()
end

function InGameMenuInvoices:delete()
	InGameMenuInvoices:superClass().delete(self)
end

function InGameMenuInvoices:copyAttributes(src)
    InGameMenuInvoices:superClass().copyAttributes(self, src)
    self.i18n = src.i18n
    self.messageCenter = src.messageCenter
end

function InGameMenuInvoices:onGuiSetupFinished()
	InGameMenuInvoices:superClass().onGuiSetupFinished(self)

	self.invoicesTableIncoming.isIncoming = true
	self.invoicesTableOutgoing.isOutgoing = true

	self.invoicesTableIncoming:setDataSource(self)
	self.invoicesTableIncoming:setDelegate(self)
	self.invoicesTableOutgoing:setDataSource(self)
	self.invoicesTableOutgoing:setDelegate(self)
end

function InGameMenuInvoices:initialize()
end

function InGameMenuInvoices:onFrameOpen()
	InGameMenuInvoices:superClass().onFrameOpen(self)   
    self:updateContent()
	--FocusManager:setFocus(self.fieldLeaseTable)
    g_currentMission.invoicesUi = self
    
	local showButtons = not g_currentMission.missionDynamicInfo.isMultiplayer or g_currentMission.inGameMenu.playerFarmId ~= FarmManager.SPECTATOR_FARM_ID
    self.btnNewInvoice.disabled = not showButtons
    self:setMenuButtonInfoDirty()
end

function InGameMenuInvoices:onFrameClose()
	InGameMenuInvoices:superClass().onFrameClose(self)   
    g_currentMission.invoicesUi = nil
end

function InGameMenuInvoices:updateContent()  
    self.selectInvoice = nil
    self.currentIncoming = nil
    self.currentOutgoing = nil

	local incomingInvoices = {}    
	local outgoingInvoices = {}    

    local currentFarmId = -1
    local farm = g_farmManager:getFarmByUserId(g_currentMission.playerUserId)
    if farm ~= nil then
        currentFarmId = farm.farmId
    end

	for _, invoice in pairs(g_currentMission.invoices.invoiceList) do
        --incomingInvoices
        if invoice.farmId == currentFarmId or not g_currentMission.missionDynamicInfo.isMultiplayer then
            table.insert(incomingInvoices, invoice)
        end

        --outgoingInvoices
        if invoice.currentFarmId == currentFarmId then
            table.insert(outgoingInvoices, invoice)            
        end		
	end

	self:sortList(incomingInvoices, outgoingInvoices)
	self.invoicesTableIncoming:reloadData()    
	self.invoicesTableOutgoing:reloadData()    

    self.btnPayInvoice.disabled = self.btnPayInvoice.disabled or #incomingInvoices == 0
    self.btnDeleteInvoice.disabled = self.btnDeleteInvoice.disabled or #outgoingInvoices == 0
    self.btnShowInvoiceDetails.disabled = self.btnShowInvoiceDetails.disabled or self.selectInvoice == nil
    self:setMenuButtonInfoDirty()
end

function InGameMenuInvoices:sortList(incomingInvoices, outgoingInvoices)
	self.incomingInvoices = {
		{
            title = g_i18n:getText("ui_invoiceState_unpaid"),
			items = {}
		},
        {
            title = g_i18n:getText("ui_invoiceState_paid"),
			items = {}
		},
	}

    self.outgoingInvoices = {
		{
            title = g_i18n:getText("ui_invoiceState_unpaid"),
			items = {}
		},
        {
            title = g_i18n:getText("ui_invoiceState_paid"),
			items = {}
		},
	}
    
    table.sort(incomingInvoices, function(a, b) 
        if a.createDay.day == b.createDay.day then
            if a.createDay.hour == b.createDay.hour then
                return a.createDay.minute < b.createDay.minute
            else
                return a.createDay.hour < b.createDay.hour
            end
        else
            return a.createDay.day < b.createDay.day
        end

        return a < b     
    end)
    
    table.sort(outgoingInvoices, function(a, b) 
        if a.createDay.day == b.createDay.day then
            if a.createDay.hour == b.createDay.hour then
                return a.createDay.minute < b.createDay.minute
            else
                return a.createDay.hour < b.createDay.hour
            end
        else
            return a.createDay.day < b.createDay.day
        end

        return a < b     
    end)

	for _, invoice in ipairs(incomingInvoices) do
        if invoice.state == Invoice.STATE_UNPAID then
            table.insert(self.incomingInvoices[1].items, invoice) 
        else
            table.insert(self.incomingInvoices[2].items, invoice) 
        end  
    end

	for _, invoice in ipairs(outgoingInvoices) do
        if invoice.state == Invoice.STATE_UNPAID then
            table.insert(self.outgoingInvoices[1].items, invoice) 
        else
            table.insert(self.outgoingInvoices[2].items, invoice) 
        end  
    end 
end

function InGameMenuInvoices:getNumberOfSections(list)
    if list.isIncoming then
        return #self.incomingInvoices
    else
        return #self.outgoingInvoices
    end
end

function InGameMenuInvoices:getNumberOfItemsInSection(list, section)
    if list.isIncoming then
        return #self.incomingInvoices[section].items
    else
        return #self.outgoingInvoices[section].items
    end
end

function InGameMenuInvoices:getTitleForSectionHeader(list, section)
    if list.isIncoming then
        return self.incomingInvoices[section].title
    else
        return self.outgoingInvoices[section].title
    end
end

function InGameMenuInvoices:populateCellForItemInSection(list, section, index, cell)
    if list.isIncoming then
        local invoice = self.incomingInvoices[section].items[index]   
        cell:getAttribute("incomingDate"):setText(string.format(g_i18n:getText("ui_invoiceDate"), invoice.createDay.day, invoice.createDay.hour, invoice.createDay.minute)) 
        cell:getAttribute("incomingFrom"):setText(g_farmManager:getFarmById(invoice.currentFarmId).name)
        cell:getAttribute("incomingAmount"):setText(g_i18n:formatMoney(invoice.fullAmount))        
    else
        local invoice = self.outgoingInvoices[section].items[index]  
        cell:getAttribute("outgoingDate"):setText(string.format(g_i18n:getText("ui_invoiceDate"), invoice.createDay.day, invoice.createDay.hour, invoice.createDay.minute)) 
        if g_farmManager:getFarmById(invoice.farmId) ~= nil then
            cell:getAttribute("outgoingFrom"):setText(g_farmManager:getFarmById(invoice.farmId).name)
        elseif not g_currentMission.missionDynamicInfo.isMultiplayer then 
            cell:getAttribute("outgoingFrom"):setText(g_farmManager:getFarmById(invoice.currentFarmId).name)
        else
            cell:getAttribute("outgoingFrom"):setText("")
        end
        cell:getAttribute("outgoingAmount"):setText(g_i18n:formatMoney(invoice.fullAmount))   
        
    end	
end

function InGameMenuInvoices:onListSelectionChanged(list, section, index)    
	local showButtons = not g_currentMission.missionDynamicInfo.isMultiplayer or g_currentMission.inGameMenu.playerFarmId ~= FarmManager.SPECTATOR_FARM_ID
    if list.isIncoming then
        local section = self.incomingInvoices[section]    
        if section ~= nil and section.items[index] ~= nil then   
            self.currentIncoming = section.items[index]  
            self.selectInvoice = self.currentIncoming
            self.btnPayInvoice.disabled = self.currentIncoming.state == Invoice.STATE_PAID or not showButtons
        else 
            self.btnPayInvoice.disabled = true
        end
    elseif list.isOutgoing then
        local section = self.outgoingInvoices[section]    
        if section ~= nil and section.items[index] ~= nil then   
            self.currentOutgoing = section.items[index]  
            self.selectInvoice = self.currentOutgoing
            self.btnDeleteInvoice.disabled = self.currentOutgoing.state == Invoice.STATE_UNPAID or not showButtons
        else 
            self.btnDeleteInvoice.disabled = true
        end
    end   
  
    self.btnShowInvoiceDetails.disabled = self.selectInvoice == nil
    self:setMenuButtonInfoDirty()
end

function InGameMenuInvoices:onDoubleClickIncoming(list, section, index, element)
    local section = self.incomingInvoices[section]   
    if section ~= nil and section.items[index] ~= nil then   
        local dialog = g_gui:showDialog("InvoiceDetails")
        if dialog ~= nil then
            dialog.target:setInvoice(section.items[index])
        end  
    end  
end

function InGameMenuInvoices:onDoubleClickOutgoing(list, section, index, element)
    local section = self.outgoingInvoices[section]   
    if section ~= nil and section.items[index] ~= nil then   
        local dialog = g_gui:showDialog("InvoiceDetails")
        if dialog ~= nil then
            dialog.target:setInvoice(section.items[index])
        end  
    end  
end

function InGameMenuInvoices:onClickNewInvoice()
    local dialog = g_gui:showDialog("NewInvoice")
end

function InGameMenuInvoices:onClickShowInvoiceDetails()
    local dialog = g_gui:showDialog("InvoiceDetails")
    if dialog ~= nil then
        dialog.target:setInvoice(self.selectInvoice)
    end    
end

function InGameMenuInvoices:onClickPayInvoice()
    if self.currentIncoming ~= nil then
        local farmname = g_farmManager:getFarmById(self.currentIncoming.currentFarmId).name
        local text = string.format(g_i18n:getText("ui_payInvoiceQuestion"), g_i18n:formatMoney(self.currentIncoming.fullAmount), farmname)
        g_gui:showYesNoDialog({text = text, title = g_i18n:getText("ui_payInvoiceQuestionHeader"), callback = self.onPay, target = self})
    end
end

function InGameMenuInvoices:onPay(confirm)
    if confirm then
		g_client:getServerConnection():sendEvent(ChangeStateInvoiceEvent.new(self.currentIncoming.id, Invoice.STATE_PAID, false))         
    end
end

function InGameMenuInvoices:onClickDeleteInvoice()
    if self.currentOutgoing ~= nil then
        g_gui:showYesNoDialog({text = g_i18n:getText("ui_deleteInvoiceQuestion"), title = g_i18n:getText("ui_deleteInvoiceQuestionHeader"), callback = self.onDelete, target = self})
    end
end

function InGameMenuInvoices:onDelete(confirm)
    if confirm then
		g_client:getServerConnection():sendEvent(ChangeStateInvoiceEvent.new(self.currentOutgoing.id, Invoice.STATE_PAID, true))
    end
end