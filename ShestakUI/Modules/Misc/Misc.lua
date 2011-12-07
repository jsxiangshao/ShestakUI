local T, C, L = unpack(select(2, ...))

----------------------------------------------------------------------------------------
--	Force readycheck warning
----------------------------------------------------------------------------------------
local ShowReadyCheckHook = function(self, initiator, timeLeft)
	if initiator ~= "player" then
		PlaySound("ReadyCheck", "Master")
	end
end
hooksecurefunc("ShowReadyCheck", ShowReadyCheckHook)

----------------------------------------------------------------------------------------
--	Force other warning
----------------------------------------------------------------------------------------
local ForceWarning = CreateFrame("Frame")
ForceWarning:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
ForceWarning:RegisterEvent("LFG_PROPOSAL_SHOW")
ForceWarning:RegisterEvent("PARTY_INVITE_REQUEST")
ForceWarning:SetScript("OnEvent", function(self, event)
	if event == "UPDATE_BATTLEFIELD_STATUS" and StaticPopup_Visible("CONFIRM_BATTLEFIELD_ENTRY") then
		PlaySound("ReadyCheck", "Master")
	elseif event == "LFG_PROPOSAL_SHOW" or event == "PARTY_INVITE_REQUEST" then
		PlaySound("ReadyCheck", "Master")
	end
end)

----------------------------------------------------------------------------------------
--	ALT+Click to buy a stack
----------------------------------------------------------------------------------------
hooksecurefunc("MerchantItemButton_OnModifiedClick", function(self, button)
	if MerchantFrame.selectedTab == 1 then
		if IsAltKeyDown() then
			local id = self:GetID()
			local quantity = select(4, GetMerchantItemInfo(id))
			local extracost = select(7, GetMerchantItemInfo(id))
			if not extracost then
				local stack
				if quantity > 1 then
					stack = quantity * GetMerchantItemMaxStack(id)
				else
					stack = GetMerchantItemMaxStack(id)
				end
				local amount = 1
				if self.count < stack then
					amount = stack / self.count
				end
				if self.numInStock ~= -1 and self.numInStock < amount then
					amount = self.numInStock
				end
				local money = GetMoney()
				if (self.price * amount) > money then
					amount = floor(money / self.price)
				end
				if amount > 0 then
					BuyMerchantItem(id, amount)
				end
			end
		end
	end
end)

local function IsMerchantButtonOver()
	return GetMouseFocus():GetName() and GetMouseFocus():GetName():find("MerchantItem%d")
end

GameTooltip:HookScript("OnTooltipSetItem", function(self)
	if MerchantFrame:IsShown() and IsMerchantButtonOver() then
		for i = 2, GameTooltip:NumLines() do
			if _G["GameTooltipTextLeft"..i]:GetText():find(ITEM_VENDOR_STACK_BUY) then
				GameTooltip:AddLine("|cff00ff00<"..L_MISC_BUY_STACK..">|r")
			end
		end
	end
end)

----------------------------------------------------------------------------------------
--	Auto decline duels
----------------------------------------------------------------------------------------
if C.misc.auto_decline_duel == true then
	local dd = CreateFrame("Frame")
	dd:RegisterEvent("DUEL_REQUESTED")
	dd:SetScript("OnEvent", function(self, event, name)
		HideUIPanel(StaticPopup1)
		CancelDuel()
		T.InfoTextShow(L_INFO_DUEL..name)
		print(format("|cffffff00"..L_INFO_DUEL..name.."."))
	end)
end

----------------------------------------------------------------------------------------
--	Spin camera while afk(by Telroth and Eclipse)
----------------------------------------------------------------------------------------
if C.misc.afk_spin_camera == true then
	local SpinCam = CreateFrame("Frame")

	local OnEvent = function(self, event, unit)
		if event == "PLAYER_FLAGS_CHANGED" then
			if unit == "player" then
				if UnitIsAFK(unit) then
					SpinStart()
				else
					SpinStop()
				end
			end
		elseif event == "PLAYER_LEAVING_WORLD" then
			SpinStop()
		end
	end
	SpinCam:RegisterEvent("PLAYER_ENTERING_WORLD")
	SpinCam:RegisterEvent("PLAYER_LEAVING_WORLD")
	SpinCam:RegisterEvent("PLAYER_FLAGS_CHANGED")
	SpinCam:SetScript("OnEvent", OnEvent)

	function SpinStart()
		spinning = true
		MoveViewRightStart(0.1)
		UIParent:Hide()
	end

	function SpinStop()
		if not spinning then return end
		spinning = nil
		MoveViewRightStop()
		UIParent:Show()
	end
end

----------------------------------------------------------------------------------------
--	Custom Lag Tolerance(by Elv22)
----------------------------------------------------------------------------------------
if C.general.custom_lagtolerance == true then
	InterfaceOptionsCombatPanelMaxSpellStartRecoveryOffset:Hide()
	InterfaceOptionsCombatPanelReducedLagTolerance:Hide()

	local customlag = CreateFrame("Frame")
	local int = 5
	local LatencyUpdate = function(self, elapsed)
		int = int - elapsed
		if int < 0 then
			if GetCVar("reducedLagTolerance") ~= tostring(1) then SetCVar("reducedLagTolerance", tostring(1)) end
			if select(3, GetNetStats()) ~= 0 and select(3, GetNetStats()) <= 400 then
				SetCVar("maxSpellStartRecoveryOffset", tostring(select(3, GetNetStats())))
			end
			int = 5
		end
	end
	customlag:SetScript("OnUpdate", LatencyUpdate)
	LatencyUpdate(customlag, 10)
end

----------------------------------------------------------------------------------------
--	Undress button in auction dress-up frame(by Nefarion)
----------------------------------------------------------------------------------------
local strip = CreateFrame("Button", "DressUpFrameUndressButton", DressUpFrame, "UIPanelButtonTemplate")
strip:SetText(L_MISC_UNDRESS)
strip:SetHeight(22)
strip:SetWidth(strip:GetTextWidth() + 40)
strip:SetPoint("RIGHT", DressUpFrameResetButton, "LEFT", -2, 0)
strip:SetScript("OnClick", function(this)
	this.model:Undress()
	PlaySound("gsTitleOptionOK")
end)
strip.model = DressUpModel

strip:RegisterEvent("AUCTION_HOUSE_SHOW")
strip:RegisterEvent("AUCTION_HOUSE_CLOSED")

strip:SetScript("OnEvent", function(this)
	if AuctionFrame:IsVisible() and this.model ~= SideDressUpModel then
		this:SetParent(SideDressUpModel)
		this:ClearAllPoints()
		this:SetPoint("BOTTOM", SideDressUpModelResetButton, "TOP", 0, 3)
		this.model = SideDressUpModel
	elseif this.model ~= DressUpModel then
		this:SetParent(DressUpModel)
		this:ClearAllPoints()
		this:SetPoint("RIGHT", DressUpFrameResetButton, "LEFT", -2, 0)
		this.model = DressUpModel
	end
end)

----------------------------------------------------------------------------------------
--	GuildTab in FriendsFrame
----------------------------------------------------------------------------------------
local n = FriendsFrame.numTabs + 1
local gtframe = CreateFrame("Button", "FriendsFrameTab"..n, FriendsFrame, "FriendsFrameTabTemplate")
gtframe:SetID(n)
gtframe:SetText(GUILD)
gtframe:SetPoint("LEFT", getglobal("FriendsFrameTab"..n-1), "RIGHT", -15, 0)
gtframe:RegisterForClicks("AnyUp")
gtframe:SetScript("OnClick", function() ToggleGuildFrame() end)
PanelTemplates_SetNumTabs(FriendsFrame, n)
PanelTemplates_EnableTab(FriendsFrame, n)

----------------------------------------------------------------------------------------
--	Switch layout mouseover button on minimap
----------------------------------------------------------------------------------------
local button = CreateFrame("Button", "SwitchLayout", UIParent)
button:SetTemplate("Transparent")
button:SetBackdropBorderColor(T.color.r, T.color.g, T.color.b)
if C.actionbar.toggle_mode == true then
	button:Point("TOPRIGHT", Minimap, "TOPRIGHT", -21, 0)
else
	button:Point("TOPRIGHT", Minimap, "TOPRIGHT", 0, 0)
end
button:Size(20)
button:SetAlpha(0)

local texture = button:CreateTexture(nil, "OVERLAY")
texture:SetTexture("Interface\\LFGFrame\\LFGROLE")
texture:SetPoint("TOPLEFT", button, 2, -2)
texture:SetPoint("BOTTOMRIGHT", button, -2, 2)

button:SetScript("OnClick", function()
	if IsAddOnLoaded("ShestakUI_DPS") then
		DisableAddOn("ShestakUI_DPS")
		EnableAddOn("ShestakUI_Heal")
		ReloadUI()
	elseif IsAddOnLoaded("ShestakUI_Heal") then
		DisableAddOn("ShestakUI_Heal")
		EnableAddOn("ShestakUI_DPS")
		ReloadUI()
	elseif not IsAddOnLoaded("ShestakUI_Heal") and not IsAddOnLoaded("ShestakUI_DPS") then
		EnableAddOn("ShestakUI_Heal")
		ReloadUI()
	end
end)

button:SetScript("OnEnter", function()
	if InCombatLockdown() then return end
	button:FadeIn()
end)

button:SetScript("OnLeave", function()
	button:FadeOut()
end)

button:RegisterEvent("PLAYER_LOGIN")
button:SetScript("OnEvent", function(self)
	if IsAddOnLoaded("ShestakUI_DPS") then
		texture:SetTexCoord(0.25, 0.5, 0, 1)
	elseif IsAddOnLoaded("ShestakUI_Heal") then
		texture:SetTexCoord(0.75, 1, 0, 1)
	elseif not IsAddOnLoaded("ShestakUI_Heal") and not IsAddOnLoaded("ShestakUI_DPS") then
		texture:SetTexture("Interface\\InventoryItems\\WoWUnknownItem01")
		texture:SetTexCoord(0.2, 0.8, 0.2, 0.8)
	end
end)

----------------------------------------------------------------------------------------
--	Misclicks for same popup
----------------------------------------------------------------------------------------
StaticPopupDialogs.PARTY_INVITE.hideOnEscape = 0
StaticPopupDialogs.CONFIRM_SUMMON.hideOnEscape = 0
StaticPopupDialogs.CONFIRM_BATTLEFIELD_ENTRY.button2 = nil

----------------------------------------------------------------------------------------
--	Fix SearchLFGLeave() taint
----------------------------------------------------------------------------------------
local TaintFix = CreateFrame("Frame")
TaintFix:SetScript("OnUpdate", function(self, elapsed)
	if LFRBrowseFrame.timeToClear then
		LFRBrowseFrame.timeToClear = nil
	end
end)

----------------------------------------------------------------------------------------
--	Fix profanityFilter(by p3lim)(temporarily, until Blizzard fix it)
----------------------------------------------------------------------------------------
local pFilter = CreateFrame("Frame")
pFilter:RegisterEvent("CVAR_UPDATE")
pFilter:RegisterEvent("PLAYER_ENTERING_WORLD")
pFilter:SetScript("OnEvent", function(self, event, cvar)
	SetCVar("profanityFilter", 0)
	BNSetMatureLanguageFilter(false)
end)

----------------------------------------------------------------------------------------
--	Auto SetFilter for AchievementUI
----------------------------------------------------------------------------------------
--[[local AchFilter = CreateFrame("Frame")
AchFilter:RegisterEvent("ADDON_LOADED")
AchFilter:SetScript("OnEvent", function(self, event, addon)
	if addon == "Blizzard_AchievementUI" then
		AchievementFrame_SetFilter(3)
	end
end)]]