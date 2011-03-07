local Zugslist = LibStub("AceAddon-3.0"):NewAddon("Zugslist", "AceConsole-3.0", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local ScrollTable = LibStub("ScrollingTable")
local wholib = LibStub:GetLibrary("LibWho-2.0"):Library()

local realm = GetRealmName()
local faction = UnitFactionGroup("player")
local player = UnitName("player")

local ZugsTradeDB = {}

local tabs_list = {
	["buy"] = {
		{ value="buy_port", text="Mage Port" },
		{ value="buy_item", text="Items" },
		
		["default"] = "buy_port",
	},
	["sell"] = {
		{ value="sell_item", text="Items" },
		
		["default"] = "sell_item",
	}
}

local table_columns = {
	["item"] = { "Item", "Price", "Player" },
	["port"] = { "Player", "Price", "Level" },
	["tank"] = { "Player", "Price", "Level" },
}

local table_filters = {
	["buy_port"] =
		function(self, row)
			if GetOnlineUsersFilterState() then
				if string.find(strupper(row[1]), strupper(GetSearchText())) and FilterRowByOnlineUsers(row) then
					return true;
				else
					return false; 
				end
			else
				if string.find(strupper(row[1]), strupper(GetSearchText())) then
					return true;
				else
					return false; 
				end
			end			
		end,
	["buy_item"] =
		function(self, row)
			if GetOnlineUsersFilterState() then	
				if ((not GetSearchText() or GetSearchText() == "") or (ParseItemID(GetSearchText()) and ParseItemID(row[1]) == ParseItemID(GetSearchText())) or string.find(strupper(row[1]), strupper(GetSearchText())) or string.find(strupper(row[3]), strupper(GetSearchText()))) and FilterRowByOnlineUsers(row) then
					return true;
				else
					return false;
				end
			else
				if (not GetSearchText() or GetSearchText() == "") or (ParseItemID(row[1]) == ParseItemID(GetSearchText())) or string.find(strupper(row[1]), strupper(GetSearchText())) or (string.find(strupper(row[3]), strupper(GetSearchText()))) then
					return true;
				else
					return false;
				end
			end
		end,
	["sell_item"] =
		function(self, row)
			if GetOnlineUsersFilterState() then	
				if ((not GetSearchText() or GetSearchText() == "") or (ParseItemID(GetSearchText()) and ParseItemID(row[1]) == ParseItemID(GetSearchText())) or string.find(strupper(row[1]), strupper(GetSearchText())) or string.find(strupper(row[3]), strupper(GetSearchText()))) and FilterRowByOnlineUsers(row) then
					return true;
				else
					return false;
				end
			else
				if (not GetSearchText() or GetSearchText() == "") or (ParseItemID(row[1]) == ParseItemID(GetSearchText())) or string.find(strupper(row[1]), strupper(GetSearchText())) or (string.find(strupper(row[3]), strupper(GetSearchText()))) then
					return true;
				else
					return false;
				end
			end
		end,
}

local search_box_text = ""

local default_tabs_list = tabs_list["buy"]
local default_table_columns = table_columns["port"]

local tables = {}
local tab_groups = {}
local current_tab = nil
local users_online_table = {}
local table_data = {}
local filter_by_online_users = false
local master_header = nil
local sell_tab_frame = nil
local buy_tab_frame = nil
local master_frame = nil
local frame_label = nil

function Zugslist:OnInitialize()
	if ZugslistData and ZugslistData[realm] and ZugslistData[realm][faction] then
		ZugsTradeDB = ZugslistData[realm][faction]
	end
	if not ZugsTradeDB then
		ZugsTradeDB = {
			["ports"] = {},
			["wtb"] = {},
			["wts"] = {},
			["wanted"] = {},
		}
	end
	if not ZugsTradeDB["ports"] then ZugsTradeDB["ports"] = {} end
	if not ZugsTradeDB["wtb"] then ZugsTradeDB["wtb"] = {} end
	if not ZugsTradeDB["wts"] then ZugsTradeDB["wts"] = {} end
	if not ZugsTradeDB["wanted"] then ZugsTradeDB["wanted"] = {} end
	if not ZugslistBuyList then ZugslistBuyList = {} end
	if not ZugslistOptions then
		ZugslistOptions = {
			min_alert_value = 50000,
			last_selected_tab = "item",
		}
	end
	current_tab = "buy_port"

	self:RegisterChatCommand("wtb", "ParseWTB")
	self:RegisterChatCommand("wts", "ParseWTS")
	self:RegisterChatCommand("zugslist", "OpenFrameFromConsole")
	self:RegisterChatCommand("zugs", "OpenFrameFromConsole")
	self:RegisterChatCommand("zug", "OpenFrameFromConsole")
end

function Zugslist:OnEnable()
	self:RegisterEvent("CHAT_MSG_LOOT")
end

function Zugslist:OnDisable()
	-- stuff
end

function Zugslist:AddBuyRequest(item_id, user, offer)
	item_index = "i"..item_id
	if ZugslistBuyList[item_index] then
		table.insert(ZugslistBuyList[item_index], { user, offer })
	else
		ZugslistBuylist[item_index] = { { user, offer } }
	end
end

function Zugslist:ParseWTB(arg)
	self:ToggleBuyFrameOn()
	master_frame.children[2]:SelectTab("buy_item")
	search_box_text = arg
	ExecuteSearch()
end

function Zugslist:ParseWTS(arg)
	self:ToggleSellFrameOn()
	master_frame.children[2]:SelectTab("sell_item")
	search_box_text = arg
	ExecuteSearch()
end

function Zugslist:OpenFrameFromConsole(arg)
	if arg == "reload" then ReloadUI()
	elseif arg == "" then
		if not master_frame then
			self:ToggleBuyFrameOn()
		else
			if master_frame:IsVisible() then
				master_frame:Hide()
			else
				master_frame:Show()
			end
		end
	else
		self:ParseWTB(arg)
	end
end

function Zugslist:ToggleBuyFrameOn()
	if not master_frame then
		self:GenerateNewMasterFrame()
	end
	sell_tab_frame.frame:Hide()
  frame_label:SetText("Buying")
	if not buy_tab_frame:IsVisible() then
		master_frame.children[2] = buy_tab_frame
		buy_tab_frame.frame:Show()
		buy_tab_frame:SelectTab(tabs_list["buy"]["default"])
		master_frame:Show()
	end
end

function Zugslist:ToggleSellFrameOn()
	if not master_frame then
		self:GenerateNewMasterFrame()
		self:ToggleSellFrameOn()
	end
	buy_tab_frame.frame:Hide()
  frame_label:SetText("Selling")
	if not sell_tab_frame:IsVisible() then
		master_frame.children[2] = sell_tab_frame
		sell_tab_frame.frame:Show()
		sell_tab_frame:SelectTab(tabs_list["sell"]["default"])
		master_frame:Show()
	end
end

function Zugslist:GenerateNewMasterFrame()
	master_frame = AceGUI:Create("Frame")
	master_frame:SetTitle("Zugslist")
	master_frame:SetStatusText("(www.zugslist.com)")
	master_frame:SetLayout("List")
	master_frame:SetWidth(700)
	master_frame:SetHeight(535)

	frame_label = AceGUI:Create("Label")
	frame_label:SetText("Buying")
	frame_label:SetWidth(100)
	frame_label:SetFont("Fonts\\FRIZQT__.TTF", 20)

	local buysell = AceGUI:Create("Button")
	buysell:SetWidth(60)
	buysell:SetText("Sell")
	buysell:SetCallback("OnClick", function(object) 
		if buy_tab_frame:IsVisible() then
			Zugslist:ToggleSellFrameOn()
			object:SetText("Buy")
		elseif sell_tab_frame:IsVisible() then
			Zugslist:ToggleBuyFrameOn()
			object:SetText("Sell")
		end
	end)
	
	local zugslist_search_box = AceGUI:Create("EditBox")
	zugslist_search_box:SetWidth(200)
	zugslist_search_box:SetHeight(40)
	zugslist_search_box:SetLabel("Search")
	zugslist_search_box:DisableButton(true)
	zugslist_search_box:SetCallback("OnTextChanged", function (object, event, text) search_box_text = text end)
	zugslist_search_box:SetCallback("OnEnterPressed", function () ExecuteSearch() end)

	local search_button = AceGUI:Create("Button")
	search_button:SetText("Search")
	search_button:SetWidth(75)
	search_button:SetCallback("OnClick", ExecuteSearch)
	
	local online_users_checkbox = AceGUI:Create("CheckBox")
	online_users_checkbox:SetValue(false)
	online_users_checkbox:SetDescription("Show online users only")
	online_users_checkbox:SetCallback("OnValueChanged", function (object, event) filter_by_online_users = object.checked ExecuteSearch() end)
	
	local header_group = AceGUI:Create("SimpleGroup")
	header_group:SetLayout("Flow")
	header_group:SetRelativeWidth(1)
	header_group:SetHeight(40)
	header_group:AddChildren(frame_label, zugslist_search_box, search_button, online_users_checkbox, buysell)

	sell_tab_frame = AceGUI:Create("TabGroup")
	sell_tab_frame:SetLayout("Fill")
	sell_tab_frame:SetWidth(650)
	sell_tab_frame:SetHeight(390)
	sell_tab_frame:SetTabs(tabs_list["sell"])
	sell_tab_frame:SetCallback("OnGroupSelected", TabChange)

	buy_tab_frame = AceGUI:Create("TabGroup")
	buy_tab_frame:SetLayout("Fill")
	buy_tab_frame:SetWidth(650)
	buy_tab_frame:SetHeight(390)
	buy_tab_frame:SetTabs(tabs_list["buy"])
	buy_tab_frame:SetCallback("OnGroupSelected", TabChange)
	
	instruction_label = AceGUI:Create("Label")
	instruction_label:SetText("Right click on an entry to send a message to that user.")
	instruction_label:SetWidth(300)

	master_frame:AddChildren(header_group, sell_tab_frame)
	table.remove(master_frame.children, 2)
	sell_tab_frame.frame:Hide()
	master_frame:AddChild(buy_tab_frame)
	master_frame:AddChild(instruction_label)
	buy_tab_frame:SelectTab(tabs_list["buy"]["default"])
end

function Zugslist:BuildNewTable(column_headers, containing_frame)
	return SetTableClickHook(ScrollTable:CreateST(
	{
		{
			["name"] = column_headers[1],
			["width"] = 200,
			["align"] = "LEFT",
			["defaultsort"] = dsc, 
			-- ["sortnext"] = 2,
			["DoCellUpdate"] = nil,
		},
		{
			["name"] = column_headers[2],
			["width"] = 150,
			["align"] = "LEFT",
			["defaultsort"] = asc, 
			["DoCellUpdate"] = nil,
		},
		{
			["name"] = column_headers[3],
			["width"] = 150,
			["align"] = "LEFT",
			["defaultsort"] = dsc, 
			["sortnext"] = 2,
			["DoCellUpdate"] = nil,
		},
	} , 20, nil, nil, containing_frame.frame ))
end

function Zugslist:BuildTabGroup(group, tab)
	local tab_group = AceGUI:Create("TabGroup")
	tab_group:SetLayout("Fill")
	tab_group:SetTabs(group)
	tab_group:SetCallback("OnGroupSelected", TabChange)
	tab_group:SelectTab(default_tabs_list["default"])
	return tab_group
end

function TabChange(container, event, tab_clicked)
	_, _, column = string.find(tab_clicked, "_(%a-)$")
	if not tables[tab_clicked] then
		tables[tab_clicked] = Zugslist:BuildNewTable(table_columns[column], container)
		tables[tab_clicked].frame:SetPoint("BOTTOMLEFT",15,15)
		tables[tab_clicked].frame:SetPoint("TOP",0,-55)
		tables[tab_clicked].frame:SetPoint("RIGHT",-15,0)
		tables[tab_clicked]:EnableSelection(false)
	end
	if tab_clicked == "buy_port" then
		table_data[tab_clicked] = Zugslist:CurrencyConversion(ZugsTradeDB["ports"], 2)
	elseif tab_clicked == "buy_item" then
		table_data[tab_clicked] = Zugslist:CurrencyConversion(ZugsTradeDB["wts"], 2)
	elseif tab_clicked == "sell_item" then
		table_data[tab_clicked] = Zugslist:CurrencyConversion(ZugsTradeDB["wtb"], 2)
	end
	if table_data[tab_clicked] then
		tables[tab_clicked]:SetData(table_data[tab_clicked], 1)
	end
	for k in pairs(tables) do
		tables[k]:Hide()
	end
	tables[tab_clicked]:Show()
	current_tab = tab_clicked
	ExecuteSearch()
end

function Zugslist:CurrencyConversion(convert_me, index_col)
	if convert_me then
		if index_col then
			local temp_table = {}
			for i = 1, table.getn(convert_me) do
				local temp_sub_table = {}
				for j = 1, table.getn(convert_me[i]) do
					if j == index_col then
						local gold, silver, copper = Zugslist:ConvertToSubCurrencies(convert_me[i][index_col])
						local cost_as_string = ""
						if gold  then cost_as_string = cost_as_string..gold.."g " end
						if silver  then cost_as_string = cost_as_string..silver.."s " end
						if copper  then cost_as_string = cost_as_string..copper.."c " end
						table.insert(temp_sub_table, cost_as_string)
					else
						table.insert(temp_sub_table, convert_me[i][j])
					end
				end
				table.insert(temp_table, temp_sub_table)
			end
			return temp_table
		else
			local gold, silver, copper = Zugslist:ConvertToSubCurrencies(convert_me[i][index_col])
			local cost_as_string = ""
			if gold  then cost_as_string = cost_as_string..gold.."g " end
			if silver  then cost_as_string = cost_as_string..silver.."s " end
			if copper  then cost_as_string = cost_as_string..copper.."c " end
			return cost_as_string
		end
	end
end

function Zugslist:CHAT_MSG_LOOT(event, msg)
	item_id = ParseItemID(msg)
	if item_id then
		if ZugsTradeDB["wanted"][item_id] then
			if best_price >= ZugslistOptions["min_alert_value"] then
				print_string = "Someone on Zugslist wants to buy it for"..CurrencyConversion(ZugslistTradeDB["wanted"][item_id]).."."
				print(print_string)
			end
		end
	end
end

function ParseItemLink(msg)
	if string.find(msg, '|Hitem:') then
		x, y = string.find(msg, "|c%x%x%x%x%x%x%x%x|Hitem:.-|r")
		return string.sub(msg, x, y)
	else
		return nil
	end		
end

function ParseItemID(item_link)
	_, _, id = string.find(item_link, "|Hitem:(%x-):")
	if id then
		return "i"..id
	else
		return nil
	end
end

function Zugslist:ConvertToSubCurrencies(cost_in_copper)
	copper = cost_in_copper % 100
	silver = ((cost_in_copper - copper) % 10000) / 100
	gold = (cost_in_copper - copper - (silver * 100)) / 10000
	return gold, silver, copper
end

function GetSearchText()
	return search_box_text
end

function ExecuteSearch()
	if GetOnlineUsersFilterState() then Zugslist:PopulateOnlineUsers() end
	ApplyTableFilters()
end

function ApplyTableFilters()
	tables[current_tab]:SetFilter(table_filters[current_tab])
end

function FilterRowByOnlineUsers(row)
	if not row then return false end
	local name_index = GetNameIndexForCurrentTab()
	return user_in_table(row[name_index], users_online_table)
end

function GetNameIndexForCurrentTab()
	if current_tab == "buy_item" or current_tab == "sell_item" then
		return 3
	elseif current_tab == "buy_port" then
		return 1
	end
end

function Zugslist:PopulateOnlineUsers()
	local now = GetTime()
	for i, v in ipairs(users_online_table) do
		if (v["time"] + 300) < now then
			table.remove(users_online_table, i)
		end
	end
	local name_index = GetNameIndexForCurrentTab()
	for _, v in ipairs(table_data[current_tab]) do
		if not user_in_table(v[name_index], users_online_table) then
			wholib:Who("n-"..v[name_index], { callback =
				function (query, results, complete)
					if table.getn(results) == 1 then
						local name_already_in_table = false
						for i, v in ipairs(users_online_table) do
							if v["name"] == results[1].Name then
								name_already_in_table = true
								v["time"] = GetTime()
							end
						end
						if not name_already_in_table then
							table.insert(users_online_table, { ["name"] = results[1].Name, ["time"] = GetTime() })
						end
						ApplyTableFilters()
					end
				end
				, queue = wholib.WHOLIB_QUIET_QUEUE }
			)
		end
	end
end

function user_in_table(item, list)
	for _, v in ipairs(list) do
		if item == v["name"] then return true end
	end
	return false
end

function GetOnlineUsersFilterState()
	return filter_by_online_users
end

function ShowTooltip(link)
	ItemRefTooltip:SetOwner(master_frame.frame, "ANCHOR_Preserve")
	ItemRefTooltip:SetHyperlink(link)
	ShowUIPanel(ItemRefTooltip)
end

function ClickForLink(link)
	local chatbox = ChatEdit_GetActiveWindow()
	if chatbox then
		ChatEdit_InsertLink(link)
	else
		ShowTooltip(link)
	end
end

function SetTableClickHook(set_this_table)
	local table_events = set_this_table.DefaultEvents
	local old_table_click = table_events["OnClick"]
	table_events["OnClick"] = function (...)
		_, _, _, _, _, realrow, _, _, button = ...
		return TableClickHook(realrow, button, old_table_click(...))
	end
	set_this_table:RegisterEvents(table_events, true)
	return set_this_table
end

function TableClickHook(realrow, button, ...)
	local item_index
	local player_index
	if current_tab == "buy_item" or current_tab == "sell_item" then
		item_index = 1
		player_index = 3
	elseif current_tab == "buy_port" then
		player_index = 1
	end
	if button == "LeftButton" and IsShiftKeyDown() and item_index then
		ClickForLink(tables[current_tab]:GetRow(realrow)[item_index])
	elseif button == "RightButton" and player_index then
		OpenTell(tables[current_tab]:GetRow(realrow)[player_index])
	end
	return ...
end

function OpenTell(player_name)
	if ChatEdit_GetActiveWindow() then
		ChatEdit_DeactivateChat(ChatEdit_GetActiveWindow())
	end
	ChatEdit_ActivateChat(ChatEdit_GetLastActiveWindow())
	ChatEdit_GetActiveWindow():Insert("/w "..player_name.." ")
	-- test_me = ChatEdit_GetActiveWindow()
	-- for k, v in pairs(test_me) do
		-- print(k)
		-- print(v)
	-- end
end
