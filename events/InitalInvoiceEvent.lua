--
-- FS22 - Invoices - InitalInvoiceEvent
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

InitalInvoiceEvent = {}
local InitalInvoiceEvent_mt = Class(InitalInvoiceEvent, Event)

InitEventClass(InitalInvoiceEvent, "InitalInvoiceEvent")

function InitalInvoiceEvent.emptyNew()
	return Event.new(InitalInvoiceEvent_mt)
end

function InitalInvoiceEvent.new()
	return InitalInvoiceEvent.emptyNew()
end

function InitalInvoiceEvent:writeStream(streamId, connection)    
	streamWriteInt32(streamId, #g_currentMission.invoices.invoiceList)
	for _,invoice in pairs(g_currentMission.invoices.invoiceList) do
        streamWriteInt32(streamId, invoice.id)
        streamWriteInt32(streamId, invoice.farmId)
        streamWriteInt32(streamId, invoice.currentFarmId)
        streamWriteInt8(streamId, invoice.state)
    
        streamWriteInt8(streamId, invoice.createDay.day)
        streamWriteInt8(streamId, invoice.createDay.hour)
        streamWriteInt8(streamId, invoice.createDay.minute)
        
        streamWriteInt32(streamId, #invoice.items)
        for _,item in pairs(invoice.items) do
            streamWriteInt32(streamId, item.amount)
            streamWriteInt32(streamId, item.id)
            streamWriteInt32(streamId, item.area)
            streamWriteInt32(streamId, item.count)
            streamWriteInt32(streamId, item.unit)
            streamWriteString(streamId, item.addText)
        end
	end
end

function InitalInvoiceEvent:readStream(streamId, connection)
	local numInvoices = streamReadInt32(streamId)
	for j = 0, numInvoices-1 do
        local invoice = Invoice.new()	

        invoice.id = streamReadInt32(streamId)
        invoice.farmId = streamReadInt32(streamId)
        invoice.currentFarmId = streamReadInt32(streamId)
        invoice.state = streamReadInt8(streamId)
        invoice.createDay = {
            day = streamReadInt8(streamId),
            hour = streamReadInt8(streamId),
            minute = streamReadInt8(streamId),
        }
    
        invoice.fullAmount = 0
    
        local numItems = streamReadInt32(streamId)
        invoice.items = {}
        for i = 0, numItems-1 do
            local amount = streamReadInt32(streamId)
    
            invoice.fullAmount = invoice.fullAmount + amount
    
            table.insert(invoice.items, {
                id = streamReadInt32(streamId),
                amount = amount,
                area = streamReadInt32(streamId),
                count = streamReadInt32(streamId),
                unit = streamReadInt32(streamId),
                addText = streamReadString(streamId),
            })
        end

        table.insert(g_currentMission.invoices.invoiceList, invoice)
	end
    
	self:run(connection)
end

function InitalInvoiceEvent:run(connection)
	if connection:getIsServer() then
        if g_currentMission.invoicesUi ~= nil then
            g_currentMission.invoicesUi:updateContent()
        end
	end
end