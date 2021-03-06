--[[-------------------------------------------------------------------------
Config Loading
---------------------------------------------------------------------------]]
if CLIENT then
	local configpaneltall = 60

	hook.Add("nzu_MenuCreated", "LoadConfig", function(menu)
		local function doconfigclick(cfg)
			if cfg then
				net.Start("nzu_menu_loadconfigs")
					net.WriteString(cfg.Codename)
					net.WriteString(cfg.Type)
				net.SendToServer()
			end
		end
		
		local l = vgui.Create("nzu_ConfigList")
		local sub = menu:AddPanel(translate.Get("load_config").." ...", 3, l, true)
		l:Dock(FILL)
		l:SetPaintBackground(true)
		l:SetSelectable(true)

		sub.BackButton:SetWide(math.Min(sub.BackButton:GetWide(), ScrW()/3.2 - 250))

		-- Access the config in Sandbox!
		local sand = sub:GetTopBar():Add("DButton")
		sand:Dock(RIGHT)
		sand:SetText(translate.Get("edit_selected_sandbox"))
		sand:SetWide(120)
		sand:DockMargin(0,10,0,0)
		sand:SetEnabled(menu:GetConfig() and true or false)
		sand.DoClick = function()
			Derma_Query(translate.Get("are_you_sure_sb"), translate.Get("mode_confirmation"), translate.Get("change_gamemode"), function()
				if menu:GetConfig() then
					nzu.RequestEditConfig(menu:GetConfig())
				end
			end, translate.Get("cancel")):SetSkin("nZombies Unlimited")
		end

		-- Access the config in Sandbox!
		local sand2 = sub:GetTopBar():Add("DButton")
		sand2:Dock(RIGHT)
		sand2:SetText(translate.Get("switch_sandbox"))
		sand2:SetWide(100)
		sand2:DockMargin(0,10,10,0)
		sand2.DoClick = function()
			Derma_Query(translate.Get("are_you_sure_sb"), translate.Get("mode_confirmation"), translate.Get("change_gamemode"), nzu.RequestEditConfig, translate.Get("cancel")):SetSkin("nZombies Unlimited")
		end

		l.OnConfigClicked = function(s,cfg,pnl)
			doconfigclick(cfg)
			if cfg then sand:SetEnabled(true) else sand:SetEnabled(false) end
		end
		
		function sub:OnShown()
			l:LoadConfigs()
			l:SelectConfig(menu:GetConfig())
		end
		function sub:OnHid()
			l:Clear()
		end

		net.Receive("nzu_menu_loadconfigs", function()
			local c = {}
			c.Codename = net.ReadString()
			c.Type = net.ReadString()
			c.Name = net.ReadString()
			c.Map = net.ReadString()
			c.Authors = net.ReadString()

			menu:SetConfig(c)
		end)

		-- Add a function to the Ready Button to load the config
		local function readybuttonload(self)
			if menu:GetConfig() then
				nzu.RequestLoadConfig(menu:GetConfig())
			end
		end

		menu:AddReadyButtonFunction(translate.Get("load_selected_config"), 70, function()
			if menu:GetConfig() then
				local cfg = menu:GetConfig()
				return not nzu.CurrentConfig or cfg.Codename ~= nzu.CurrentConfig.Codename or cfg.Type ~= nzu.CurrentConfig.Type
			end
		end, readybuttonload, true)

	end)
end

if SERVER then
	util.AddNetworkString("nzu_menu_loadconfigs")

	local configtoload
	local function writeconfigtoload()
		net.WriteString(configtoload.Codename)
		net.WriteString(configtoload.Type)
		net.WriteString(configtoload.Name)
		net.WriteString(configtoload.Map)
		net.WriteString(configtoload.Authors)
	end

	net.Receive("nzu_menu_loadconfigs", function(len, ply)
		if not nzu.IsAdmin(ply) then return end

		local codename = net.ReadString()
		local ctype = net.ReadString()

		local config = nzu.GetConfig(codename, ctype)
		if config then
			configtoload = config
			net.Start("nzu_menu_loadconfigs")
				writeconfigtoload()
			net.Broadcast()
		end
	end)

	-- Players that join should see this on the menu
	hook.Add("PlayerInitialSpawn", "nzu_MenuLoadedConfig", function(ply)
		if configtoload then
			net.Start("nzu_menu_loadconfigs")
				writeconfigtoload()
			net.Send(ply)
		end
	end)
end