ZugsTradeParser = LibStub("AceAddon-3.0"):NewAddon("ZugslistTradeParser", "AceConsole-3.0", "AceEvent-3.0")
local ZugsTradeParser = _G.ZugsTradeParser

-- local variables
local player = UnitName("player")
local guid = UnitGUID("player")
local faction = UnitFactionGroup("player")
local realmName = GetRealmName()

-- initialize the database structure
function ZugsTradeParser:OnInitialize()
	if not ZugslistTradeParser then ZugslistTradeParser = {} end
end

-- register event handlers
function ZugsTradeParser:OnEnable()
	self:RegisterEvent("CHAT_MSG_CHANNEL", "ChatEvent")
	self:RegisterEvent("CHAT_MSG_SAY", "ChatEvent")
	self:RegisterEvent("CHAT_MSG_WHISPER", "ChatEvent")
	self:RegisterEvent("CHAT_MSG_YELL", "ChatEvent")
	self:RegisterEvent("CHAT_MSG_GUILD", "ChatEvent")
	self:RegisterEvent("TRADE_SKILL_SHOW", "WindowEvent")
end

-- get user trade data from tradeskill window
function ZugsTradeParser:WindowEvent(event)
	if not IsTradeSkillLinked() then
		local tradelink = GetTradeSkillListLink()
		local guid = string.match(UnitGUID("player"), "0x0([0-9A-F]+)")	
		if tradelink then
			ParseEvent(event, tradelink, player, guid)
		end
	end
end 

-- get other users' trade window from links posted in chat channels
function ZugsTradeParser:ChatEvent(event, message, character, _, _, _, _, _, _, _, _, _, guid )
	-- if (arg9 == "TCForwarder2IIll") then 
	-- 	local parsedCharname = string.match(message, "^_\$%d+([A-Za-z]+)_\$.*")
	-- 	ParseEvent(event,message,parsedCharname)
	-- else 
	local parsedGUID = string.match(guid, "0x0([0-9A-F]+)")
	ParseEvent(event, message, character, parsedGUID)
	-- end
end

-- parse trade info and store in global saved var ZugslistTradeParser
function ParseEvent(event, message, character, guid)
	--refer to http://www.wowwiki.com/UI_escape_sequences for info on escape sequences
	--|Htrade:TradeSpellID:CurrentLevel:MaxLevel:PlayerID:Recipes|hLinktext|h
	if string.find(message, "|Htrade:") then
		for link in string.gmatch(message, "|c%x+|Htrade:%d+:%d+:%d+:[0-9a-fA-F]+:[A-Za-z0-9+/]+|h%[[^]]+%]|h|r") do
			local TradeSpellID,CurrentLevel,PlayerID,Recipes, LinkText = string.match(link,"|Htrade:(%d+):(%d+):%d+:([0-9a-fA-F]+):([A-Za-z0-9+/]+)|h%[([^]]+)%]|h|r")
			-- store values
			local profession = matchSpecialization(LinkText)
			-- ZugsError:Print("Player id = "..PlayerID)
			-- ZugsError:Print ("Player GUID = "..guid)

--			local PlayerID_check = string.match(UnitGUID(character), "0x0([0-9A-F]+)")			
			if guid == PlayerID then 
				if (string.len(profession) > 1) then
					if not ZugslistTradeParser[realmName] then ZugslistTradeParser[realmName] = {} end
					ZugslistTradeParser[realmName][character.."-"..profession]={
						["server"] = realmName,
						["faction"] = faction,
						["character"] = character,
						["playerid"] = PlayerID,
						["tradespellid"] = TradeSpellID,
						["level"] = CurrentLevel,
						["recipes"] = Recipes,
						["profession"] = profession,
						["time_stamp"] = time(),	
						["link"] = link,							
					}
				end
			end
		end
	end	
end

function matchSpecialization(LinkText)
	if isProfession(LinkText) then
		return LinkText
	elseif isAlchemySpecialization(LinkText) then
		return "Alchemy"
	elseif isBlacksmithingSpecialization(LinkText) then
		return "Blacksmithing"
	elseif isEngineeringSpecialization(LinkText) then
		return "Engineering"
	elseif isLeatherworkingSpecialization(LinkText) then
		return "Leatherworking"
	elseif isTailoringSpecialization(LinkText) then
		return "Tailoring"
	else
		return ""	
	end
end

function isProfession(LinkText)
	if (in_table(LinkText,{'Alchemy','Blacksmithing','Enchanting','Engineering', 'Herbalism', 'Inscription', 'Jewelcrafting', 'Leatherworking', 'Mining', 'Skinning', 'Tailoring', 'Cooking','First Aid'})) then
 		return true
	else
		return false
	end
end

function isAlchemySpecialization(LinkText)
	if (in_table(LinkText,{"Potion Master", "Transmutation Master", "Elixir Master"})) then
		return true
	else
		return false
	end
end

function isBlacksmithingSpecialization(LinkText)
	if (in_table(LinkText,{"Armorsmith", "Hammersmith", "Swordsmith"})) then
		return true
	else
		return false
	end
end

function isEngineeringSpecialization(LinkText)
	if (string.match(LinkText,"Engineer")) then
		return true
	else
		return false
	end
end

function isLeatherworkingSpecialization(LinkText)
	if (string.match(LinkText,"Leatherworking")) then
		return true
	else
		return false
	end
end

function isTailoringSpecialization(LinkText)
	if (string.match(LinkText,"Tailoring")) then
		return true
	else
		return false
	end
end

function in_table ( e, t ) 
 	for _,v in pairs(t) do
		if (v==e) then return true end
	end
	return false
end
