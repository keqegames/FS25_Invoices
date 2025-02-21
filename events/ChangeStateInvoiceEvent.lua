--
-- FS22 - Invoices - ChangeStateInvoiceEvent
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

ChangeStateInvoiceEvent = {}
local ChangeStateInvoiceEvent_mt = Class(ChangeStateInvoiceEvent, Event)

InitEventClass(ChangeStateInvoiceEvent, "ChangeStateInvoiceEvent")

function ChangeStateInvoiceEvent.emptyNew()
	local self = Event.new(ChangeStateInvoiceEvent_mt)

	return self
end

function ChangeStateInvoiceEvent.new(id, state, deleteInvoice)
	local self = ChangeStateInvoiceEvent.emptyNew()
	self.id = id
	self.state = state
	self.deleteInvoice = deleteInvoice

	return self
end

function ChangeStateInvoiceEvent:readStream(streamId, connection)
	self.id = streamReadInt32(streamId)
	self.state = streamReadInt8(streamId)
	self.deleteInvoice = streamReadBool(streamId)

	self:run(connection)
end

function ChangeStateInvoiceEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.id)
	streamWriteInt8(streamId, self.state)
	streamWriteBool(streamId, self.deleteInvoice)	
end

function ChangeStateInvoiceEvent:run(connection)
    local invoice = g_currentMission.invoices:getInvoiceById(self.id)

    if invoice ~= nil then
        if not connection:getIsServer() then
            if not self.deleteInvoice then
                if not g_currentMission.missionDynamicInfo.isMultiplayer then
                    g_currentMission:addMoney(-invoice.fullAmount, invoice.currentFarmId, MoneyType.TRANSFER, true, true)
                else
                    g_currentMission:addMoney(-invoice.fullAmount, invoice.farmId, MoneyType.TRANSFER, true, true)
                end
                g_currentMission:addMoney(invoice.fullAmount, invoice.currentFarmId, MoneyType.TRANSFER, true, true)
            end
        
            g_server:broadcastEvent(self, false)
        end
    
        if self.deleteInvoice then
            g_currentMission.invoices:deleteInvoiceById(self.id)
        else        
            invoice:setState(self.state)
        end           			
        if g_currentMission.invoicesUi ~= nil then
            g_currentMission.invoicesUi:updateContent()
        end
    end
end