--
-- FS22 - Invoices - CreateInvoiceEvent
--
-- @Interface: 1.2.0.0 b14651
-- @Author: KR-Softwares
-- @Date: 03.02.2022
-- @Version: 1.0.0.0
--
-- @Support: kr-softwares.com
--
-- Changelog:
-- 	v1.0.0.0 (03.02.2022):
--		Release fs22
--

CreateInvoiceEvent = {}
local CreateInvoiceEvent_mt = Class(CreateInvoiceEvent, Event)

InitEventClass(CreateInvoiceEvent, "CreateInvoiceEvent")

function CreateInvoiceEvent.emptyNew()
	local self = Event.new(CreateInvoiceEvent_mt)

	return self
end

function CreateInvoiceEvent.new(invoice)
	local self = CreateInvoiceEvent.emptyNew()
	self.invoice = invoice

	return self
end

function CreateInvoiceEvent:readStream(streamId, connection)
	self.invoice = Invoice.new()	

	self.invoice.id = streamReadInt32(streamId)
	self.invoice.farmId = streamReadInt32(streamId)
	self.invoice.currentFarmId = streamReadInt32(streamId)
	self.invoice.state = streamReadInt8(streamId)

	self.invoice.createDay = {
		day = streamReadInt8(streamId),
		hour = streamReadInt8(streamId),
		minute = streamReadInt8(streamId),
	}

    self.invoice.fullAmount = 0

	local numItems = streamReadInt32(streamId)
	self.invoice.items = {}
	for i = 0, numItems -1 do
		local amount = streamReadInt32(streamId)

		self.invoice.fullAmount = self.invoice.fullAmount + amount

		table.insert(self.invoice.items, {
			id = streamReadInt32(streamId),
			amount = amount,
			area = streamReadInt32(streamId),
			count = streamReadInt32(streamId),
			unit = streamReadInt32(streamId),
			addText = streamReadString(streamId),
		})
	end

	self:run(connection)
end

function CreateInvoiceEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.invoice.id)
	streamWriteInt32(streamId, self.invoice.farmId)
	streamWriteInt32(streamId, self.invoice.currentFarmId)
	streamWriteInt8(streamId, self.invoice.state)

	streamWriteInt8(streamId, self.invoice.createDay.day)
	streamWriteInt8(streamId, self.invoice.createDay.hour)
	streamWriteInt8(streamId, self.invoice.createDay.minute)
	
	streamWriteInt32(streamId, #self.invoice.items)
	for _,item in pairs(self.invoice.items) do
		streamWriteInt32(streamId, item.amount)
		streamWriteInt32(streamId, item.id)
		streamWriteInt32(streamId, item.area)
		streamWriteInt32(streamId, item.count)
		streamWriteInt32(streamId, item.unit)
		streamWriteString(streamId, item.addText)
	end
end

function CreateInvoiceEvent:run(connection)
	if not connection:getIsServer() then				
		self.invoice.id = g_currentMission.invoices:getNextId()	
		table.insert(g_currentMission.invoices.invoiceList, self.invoice)
		g_server:broadcastEvent(CreateInvoiceEvent.new(self.invoice))
	else            			
		table.insert(g_currentMission.invoices.invoiceList, self.invoice)
	end
	if g_currentMission.invoicesUi ~= nil then
		g_currentMission.invoicesUi:updateContent()
	end
end