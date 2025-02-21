--
-- FS22 - Invoice
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
--      - Convert from from FS19 to FS22
--


Invoice = {}
local Invoice_mt = Class(Invoice)

Invoice.STATE_UNPAID = 1
Invoice.STATE_PAID = 2

Invoice.UNIT_STK = 1
Invoice.UNIT_STD = 2
Invoice.UNIT_HA = 3
Invoice.UNIT_L = 4

function Invoice.new(customMt)
	local self = {}

	setmetatable(self, customMt or Invoice_mt)

    self.id = 0
    self.items = {}
    self.state = Invoice.STATE_UNPAID


    return self
end

--[[
id = work.id,
title = title,
amount = amount,
area = area,
count = self.currentNewEntry.count,
unit = work.unit,
]]--
function Invoice:loadFromUi(id, items, farmId, currentFarmId)
    self.id = id
    self.farmId = farmId
    self.currentFarmId = currentFarmId

    self.fullAmount = 0
    for _,item in pairs(items) do
        self.fullAmount = self.fullAmount + item.amount
    end

    self.items = items
  
    self.createDay = {
        day = g_currentMission.environment.currentDay,
        hour = g_currentMission.environment.currentHour,
        minute = g_currentMission.environment.currentMinute,
    }
end

function Invoice:delete()
    
end

function Invoice:saveToXmlFile(xmlFile, key)    
	--setXMLInt(xmlFile, key.."#id", self.id)
	setXMLInt(xmlFile, key.."#farmId", self.farmId)
	setXMLInt(xmlFile, key.."#currentFarmId", self.currentFarmId)
	setXMLInt(xmlFile, key.."#state", self.state)
	setXMLInt(xmlFile, key..".createDay#day", self.createDay.day)
	setXMLInt(xmlFile, key..".createDay#hour", self.createDay.hour)
	setXMLInt(xmlFile, key..".createDay#minute", self.createDay.minute)

    local count = 0
    for _,item in pairs(self.items) do
        local itemKey = string.format("%s.items.item(%d)", key, count)
        setXMLInt(xmlFile, itemKey.."#id", item.id)
        setXMLInt(xmlFile, itemKey.."#amount", item.amount)
        setXMLInt(xmlFile, itemKey.."#area", item.area)
        setXMLFloat(xmlFile, itemKey.."#count", item.count)
        setXMLInt(xmlFile, itemKey.."#unit", item.unit)      
        setXMLString(xmlFile, itemKey.."#addText", item.addText)      
        count = count + 1
    end
end

function Invoice:loadFromXMLFile(xmlFile, key)
    self.farmId = getXMLInt(xmlFile, key.."#farmId")
    self.currentFarmId = getXMLInt(xmlFile, key.."#currentFarmId")
    self.state = getXMLInt(xmlFile, key .. "#state")

    self.createDay = {
        day = getXMLInt(xmlFile, key..".createDay#day"),
        hour = getXMLInt(xmlFile, key..".createDay#hour"),
        minute = getXMLInt(xmlFile, key..".createDay#minute"),
    }

    self.fullAmount = 0

    self.items = {}
    local count = 0
    while true do
        local itemKey = string.format("%s.items.item(%d)", key, count)

        if not hasXMLProperty(xmlFile, itemKey) then
            break
        end

        local amount = getXMLInt(xmlFile, itemKey.."#amount")
        table.insert(self.items, {
            id = getXMLInt(xmlFile, itemKey.."#id"),
            amount = amount,
            area = getXMLInt(xmlFile, itemKey.."#area"),
            count = getXMLFloat(xmlFile, itemKey.."#count"),
            unit = getXMLInt(xmlFile, itemKey.."#unit"),
            addText = Utils.getNoNil(getXMLString(xmlFile, itemKey .. "#addText"), "")
        })
        self.fullAmount = self.fullAmount + amount

        count = count + 1
    end    
end

function Invoice:setState(newState)
    self.state = newState
end
