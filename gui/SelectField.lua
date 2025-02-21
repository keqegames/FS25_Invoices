--
-- FS22 - Invoices - SelectField
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
--      - Convert from from FS19 to FS22
--

SelectField = {
	CONTROLS = {
        TABLE = "selectFieldsTable",
        TABLE_TEMPLATE = "selectFieldsRowTemplate",
        BTN_BACK = "btnBack",
        BTN_FIELDSELECT = "btnFieldSelect",
		DIALOGDATA = "dialogTitle",
		CELLTEXT_FIELD = "cellTextField",
		CELLTEXT_AREA = "cellTextArea",
	}
}
local SelectField_mt = Class(SelectField, MessageDialog)

SelectField.MODE_NONE = 0
SelectField.MODE_FIELD = 1
SelectField.MODE_FARM = 2

function SelectField.new(target, custom_mt)
	local self = MessageDialog.new(target, custom_mt or SelectField_mt)

	-- self:registerControls(SelectField.CONTROLS)
	
	return self
end

function SelectField:onCreate()
	SelectField:superClass().onCreate(self)    
end

function SelectField:onGuiSetupFinished()
	SelectField:superClass().onGuiSetupFinished(self)
	self.selectFieldsTable:setDataSource(self)
	self.selectFieldsTable:setDelegate(self)
end

function SelectField:onOpen()
	SelectField:superClass().onOpen(self)
	self.currentMode = SelectField.MODE_NONE
	FocusManager:setFocus(self.selectFieldsTable)
end

function SelectField:setMode(mode)
	self.currentMode = mode
	if self.currentMode == SelectField.MODE_FIELD then
		self.dialogTitle:setText(g_i18n:getText("ui_selectFieldHeader"))
		self.cellTextArea:setText(g_i18n:getText("ui_selectFieldHeaderArea"))
		self.btnFieldSelect:setText(g_i18n:getText("ui_selectField_chooseField"))
		self.cellTextField:setText(g_i18n:getText("ui_selectFieldHeaderField"))
	elseif self.currentMode == SelectField.MODE_FARM then
		self.dialogTitle:setText(g_i18n:getText("ui_selectFieldHeader2"))
		self.cellTextArea:setText("")
		self.cellTextField:setText(g_i18n:getText("ui_selectFieldHeaderFarm"))
		self.btnFieldSelect:setText(g_i18n:getText("ui_selectField_chooseFarm"))
	end
	self:updateContent()
end

function SelectField:updateContent()   
	self.fields = {
		{
			title = g_i18n:getText("ui_selectField_notOwned"),
			items = {}
		},
		{
			title = g_i18n:getText("ui_selectField_owned"),
			items = {}
		}		
	}

	self.farms = {
		{
			title = g_i18n:getText("ui_selectField_allFarms"),
			items = {}
		}
	}

	local currentFarmId = -1
	local farm = g_farmManager:getFarmByUserId(g_currentMission.playerUserId)
	if farm ~= nil then
		currentFarmId = farm.farmId
	end

	if self.currentMode == SelectField.MODE_FIELD then
		for _,field in pairs(g_fieldManager.fields) do        
			local owner = g_farmlandManager:getFarmlandOwner(field.farmland.id)
	
			if owner == currentFarmId then
				table.insert(self.fields[2].items, { id= field.fieldId, area = field.fieldArea })
			else
				table.insert(self.fields[1].items, { id= field.fieldId, area = field.fieldArea })
			end   
		end
		--- Adds custom fields, if courseplay is used.
		if g_fieldManager.cpCustomFields then
			for _, field in pairs(g_fieldManager.cpCustomFields) do        
				table.insert(self.fields[2].items, { id= field.fieldId, area = field.fieldArea })
			end
		end


	elseif self.currentMode == SelectField.MODE_FARM then
		for _,farm in pairs(g_farmManager.farms) do
			if farm.farmId ~= FarmManager.SPECTATOR_FARM_ID and (farm.farmId ~= currentFarmId or not g_currentMission.missionDynamicInfo.isMultiplayer) then
				table.insert(self.farms[1].items, farm)
			end
		end
	end    
    
	self.selectFieldsTable:reloadData()    
end

function SelectField:getNumberOfSections()
	if self.currentMode == SelectField.MODE_FIELD then
		return #self.fields
	elseif self.currentMode == SelectField.MODE_FARM then
		return #self.farms
	end
end

function SelectField:getNumberOfItemsInSection(list, section)
	if self.currentMode == SelectField.MODE_FIELD then
		return #self.fields[section].items
	elseif self.currentMode == SelectField.MODE_FARM then
		return #self.farms[section].items
	end
end

function SelectField:getTitleForSectionHeader(list, section)
	if self.currentMode == SelectField.MODE_FIELD then
		return self.fields[section].title
	elseif self.currentMode == SelectField.MODE_FARM then
		return self.farms[section].title
	end
end

function SelectField:populateCellForItemInSection(list, section, index, cell)
	if self.currentMode == SelectField.MODE_FIELD then
		local field = self.fields[section].items[index]    
		cell:getAttribute("field"):setText(string.format(g_i18n:getText("ui_selectField_field"), field.id))
		cell:getAttribute("area"):setText(g_i18n:formatNumber(field.area, 2) .. " HA")
	elseif self.currentMode == SelectField.MODE_FARM then
		local farm = self.farms[section].items[index]    
		cell:getAttribute("field"):setText(farm.name)
	end
end

function SelectField:onClose()
	SelectField:superClass().onClose(self)
end

function SelectField:onClickBack(sender)
	self:close()
end

function SelectField:onListSelectionChanged(list, section, index)
	if self.currentMode == SelectField.MODE_FIELD then
		local sectionFields = self.fields[section]    
		if sectionFields ~= nil and sectionFields.items[index] ~= nil then        
			self.currentSelectedField = sectionFields.items[index]
		end
	elseif self.currentMode == SelectField.MODE_FARM then
		local sectionFarm = self.farms[section]    
		if sectionFarm ~= nil and sectionFarm.items[index] ~= nil then        
			self.currentSelectedFarm = sectionFarm.items[index]
		end
	end
end

function SelectField:onDoubleClick(list, section, index, element)
	if self.currentMode == SelectField.MODE_FIELD then
		local sectionFields = self.fields[section]    
		if sectionFields ~= nil and sectionFields.items[index] ~= nil then        
			self.currentSelectedField = sectionFields.items[index]
			self:onClickSelectField()
		end
	elseif self.currentMode == SelectField.MODE_FARM then
		local sectionFarm = self.farms[section]    
		if sectionFarm ~= nil and sectionFarm.items[index] ~= nil then        
			self.currentSelectedFarm = sectionFarm.items[index]
			self:onClickSelectField()
		end
	end	
end

function SelectField:setTargetScreen(screen)
    self.targetScreen = screen
end

function SelectField:onClickSelectField()
    if self.targetScreen ~= nil then 
		if self.currentMode == SelectField.MODE_FIELD then
			self.targetScreen:selectField(self.currentSelectedField)
		elseif self.currentMode == SelectField.MODE_FARM then
			self.targetScreen:selectFarm(self.currentSelectedFarm)
		end
	end
	self:close()
end