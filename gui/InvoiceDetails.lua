--
-- FS22 - Invoice - InvoiceDetails
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

InvoiceDetails = {
	CONTROLS = {
		DIALOG_TITLE = "dialogTitleElement",
		CLOSE_BUTTON = "closeButton",
		TEXT_FROM = "textInvoiceFrom",
		TEXT_To = "textInvoiceTo",
		TEXT_FULLCOST = "textFullCost",
		TBL = "invoiceDetailFullList",
		TBL_TMPL = "invoiceDetailFullListRowTemplate",
		TBL_SLIDER = "invoiceDetailFullListSlider",
	}
}
local InvoiceDetails_mt = Class(InvoiceDetails, MessageDialog)

function InvoiceDetails.new(target, custom_mt)
	local self = MessageDialog.new(target, custom_mt or InvoiceDetails_mt)

	-- self:registerControls(InvoiceDetails.CONTROLS)

	return self
end

function InvoiceDetails:onCreate()
	InvoiceDetails:superClass().onCreate(self)    
end

function InvoiceDetails:setInvoice(invoice)
	self.invoice = invoice
	self:updateContent()
end

function InvoiceDetails:onGuiSetupFinished()
	InvoiceDetails:superClass().onGuiSetupFinished(self)
    
	self.invoiceDetailFullList:setDataSource(self)
	self.invoiceDetailFullList:setDelegate(self)
end

function InvoiceDetails:onOpen()
	InvoiceDetails:superClass().onOpen(self)    
end

function InvoiceDetails:onClose()
	InvoiceDetails:superClass().onClose(self)
end

function InvoiceDetails:updateContent()
	local farmFrom = g_farmManager:getFarmById(self.invoice.currentFarmId)
	local farmTo = g_farmManager:getFarmById(self.invoice.farmId)
	if farmFrom ~= nil then
		self.textInvoiceFrom:setText(farmFrom.name)
	end
	if farmTo ~= nil then
		self.textInvoiceTo:setText(farmTo.name)
	end

	self.textFullCost:setText(g_i18n:formatMoney(self.invoice.fullAmount, 0, true, false))

	self.workItems = {
		{
			title = "",
			items = {}
		}
	}

	for _,work in pairs(self.invoice.items) do
		table.insert(self.workItems[1].items, work)
	end
	
	self.invoiceDetailFullList:reloadData() 
end

function InvoiceDetails:getNumberOfSections(list)
	return #self.workItems
end

function InvoiceDetails:getNumberOfItemsInSection(list, section)
	return #self.workItems[section].items
end

function InvoiceDetails:getTitleForSectionHeader(list, section)
	return ""
end

function InvoiceDetails:populateCellForItemInSection(list, section, index, cell)
	local item = self.workItems[section].items[index]    
	local work = g_currentMission.invoices:getWorkData(item.id)
	cell:getAttribute("workName"):setText(work.title)
	cell:getAttribute("addText"):setText(item.addText)
	cell:getAttribute("workPrice"):setText(g_i18n:formatMoney(item.amount, 0, true, false) .. " / " .. work.unitStr)
end

function InvoiceDetails:onListSelectionChanged(list, section, index)

end

function InvoiceDetails:onClickBack(sender)
	self:close()
end