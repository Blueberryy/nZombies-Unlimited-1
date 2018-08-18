print("Yo")

local port_size = 10

local CONNECTION = {}
function CONNECTION:Init()
	self:SetSize(port_size,port_size)
	self:Droppable("nzu_logicmap_connection_in")
	self:SetPaintBackground(false)

	self.Tail = vgui.Create("DPanel")
	self.Tail:SetMouseInputEnabled(false)
	self.Tail:SetPaintBackground(false)
end
function CONNECTION:PaintOver(x,y)
	if IsValid(self.Output) then
		surface.SetDrawColor(0,0,0)
		surface.DrawLine(self.GetPos(), self.Output:GetPos())
	end
end

function CONNECTION:SetPorts(outp, inp)
	self.Tail:SetParent(outp.Panel)
	self:SetParent(inp.Panel)
end

function CONNECTION:SetConnection(c)
	self.m_tConnection = c
end

function CONNECTION:PaintOver(x,y)
	surface.SetDrawColor(0,0,0)
	DisableClipping(true)
	local tx,ty = self:ScreenToLocal(self.Tail:LocalToScreen(self.Tail:GetPos()))
	surface.DrawLine(tx + 5,ty + 5,x - 5,y - 5)
	DisableClipping(false)
end

--[[function CONNECTION:OnMouseReleased(code)
	if not self:IsDragging() then
		print("I'm not here")
		self:Remove()
	end
end]]


local INPUTPORT = {}
function INPUTPORT:Init()
	self:SetBackgroundColor(Color(150,255,150))
	self:SetSize(port_size,port_size)

	self:Receiver("nzu_logicmap_connection", self.DropAction)
end

function INPUTPORT:DropAction(pnls, dropped, menu, x, y)
	if dropped then
		for k,v in pairs(pnls) do
			-- Request a connection
			net.Start("nzu_logicmap_connect")
				net.WriteUInt(v.m_lUnit:Index(), 16)
				net.WriteString(v.m_sPort)
				net.WriteUInt(self.m_lUnit:Index(), 16)
				net.WriteString(self.m_sPort)
				net.WriteString("") -- For now, no arguments. Maybe change later so client can "pre-send" args?
			net.SendToServer()
		end
	end
end

local OUTPUTPORT = {}
function OUTPUTPORT:Init()
	self:SetBackgroundColor(Color(255,150,150))
	self:SetSize(port_size,port_size)

	self:Droppable("nzu_logicmap_connection")
end

local drawwiremouse
function OUTPUTPORT:OnMousePressed(code)
	--drawwiremouse = {500,500}
	--self:MouseCapture(true)
	self:DragMousePress(code)
end

function OUTPUTPORT:OnMouseReleased(code)
	--self:MouseCapture(false)
	drawwiremouse = nil
	self:DragMouseRelease(code)
end

function OUTPUTPORT:PaintOver(x,y)
	if self:IsDragging() then
		surface.SetDrawColor(0,0,0)
		local mx,my = self:LocalCursorPos()
		DisableClipping(true)
		surface.DrawLine(5,5,mx,my)
		DisableClipping(false)
	end
end

derma.DefineControl("DLogicMapUnitConnection", "", CONNECTION, "DPanel")
derma.DefineControl("DLogicMapUnitInput", "", INPUTPORT, "DPanel")
derma.DefineControl("DLogicMapUnitOutput", "", OUTPUTPORT, "DPanel")

local PANEL = {}
AccessorFunc(PANEL,"m_bDisplayPorts", "ShowPorts", FORCE_BOOL)

function PANEL:Init()
	--self:SetPaintBackground(false)

	self.IGNORECHILD = true
	self.LeftPorts = self:Add("Panel")
	self.LeftPorts:SetWide(port_size)
	self.LeftPorts:Dock(LEFT)

	self.RightPorts = self:Add("Panel")
	self.RightPorts:Dock(RIGHT)
	self.RightPorts:SetWide(port_size)

	self.TopPorts = self:Add("Panel")
	self.TopPorts:Dock(TOP)
	self.TopPorts:SetTall(port_size)

	self.BottomPorts = self:Add("Panel")
	self.BottomPorts:Dock(BOTTOM)
	self.BottomPorts:SetTall(port_size)

	--self:DockPadding(port_size,port_size,port_size,port_size) -- The boundaries for logic ports
	self.ChipCanvas = self:Add("Panel")
	self.ChipCanvas:Dock(FILL)
	self.ChipCanvas:SetMouseInputEnabled(false)
	self.IGNORECHILD = nil

	self.m_tOutputPorts = {}
	self.m_tInputPorts = {}
end

function PANEL:AddNonCanvas(p)
	self.IGNORECHILD = true
	local n = self:Add(p)
	self.IGNORECHILD = nil
	return n
end

function PANEL:OnChildAdded(p)
	if not self.IGNORECHILD then
		p:SetParent(self.ChipCanvas)
		p:SetDragParent(self)
	end
end

function PANEL:SetLogicUnit(unit)
	if unit.CustomPanel then
		self:Clear()
		unit:CustomPanel(self)
	else
		if not self.Icon then self.Icon = self:Add("DImage") end
		self.Icon:SetImage(unit.Icon)
		--self.Icon:Dock(FILL)
		--self.Icon:DockMargin(10,10,10,10)
		self.Icon:SetKeepAspect(true)
	end
	self.m_lUnit = unit

	-- Update the ports
	for k,v in pairs(self.m_tOutputPorts) do if IsValid(v.Panel) then v.Panel:Remove() end end
	for k,v in pairs(self.m_tInputPorts) do if IsValid(v.Panel) then v.Panel:Remove() end end
	self.m_tOutputPorts = {}
	self.m_tInputPorts = {}

	if unit.Outputs then
		for k,v in pairs(unit.Outputs) do
			if v.Port then
				self.m_tOutputPorts[k] = v.Port
			end
		end
	end
	if unit.Inputs then
		for k,v in pairs(unit.Inputs) do
			if v.Port then
				self.m_tInputPorts[k] = v.Port
			end
		end
	end

	self:UpdatePorts()
end

function PANEL:PerformLayout()
	if IsValid(self.Icon) then
		local x,y = self.ChipCanvas:GetSize()
		local min = math.Min(x,y)
		self.Icon:SetSize(min,min)
		self.Icon:SetPos(x/2 - min/2, y/2 - min/2)
	end
end

local postypes = {
	[LEFT] = function(s,p,x) p:SetParent(s.LeftPorts) p:SetPos(0,x) end,
	[RIGHT] = function(s,p,x) p:SetParent(s.RightPorts) p:SetPos(0,x) end,
	[TOP] = function(s,p,x) p:SetParent(s.TopPorts) p:SetPos(x,0) end,
	[BOTTOM] = function(s,p,x) p:SetParent(s.BottomPorts) p:SetPos(x,0) end,
}
local function doport(self, name, inout, side, pos)
	local port
	if inout then
		if not self.m_tInputPorts[name] then self.m_tInputPorts[name] = {} end
		port = self.m_tInputPorts[name]
	else
		if not self.m_tOutputPorts[name] then self.m_tOutputPorts[name] = {} end
		port = self.m_tOutputPorts[name]
	end
	local panel = port and port.Panel or vgui.Create(inout and "DLogicMapUnitInput" or "DLogicMapUnitOutput")
	panel.m_lUnit = self.m_lUnit
	panel.m_sPort = name

	postypes[side](self, panel, pos)
	--panel:SetPortSide(side)

	--[[local name = self:AddNonCanvas("DLabel")
	name:SetText(name)
	name:SetVisible(false)
	name:DisableClipping(true)]]

	port.Side = side
	port.Pos = pos
	port.Connections = port.Connections or {}
	port.Panel = panel
end
function PANEL:UpdatePorts()
	if self:GetShowPorts() then
		for k,v in pairs(self.m_tInputPorts) do
			doport(self, k, true, v.Side, v.Pos)
		end

		for k,v in pairs(self.m_tOutputPorts) do
			doport(self, k, false, v.Side, v.Pos)
		end
	else
		for k,v in pairs(self.m_tInputPorts) do if IsValid(v.Panel) then v.Panel:Remove() end end
		for k,v in pairs(self.m_tOutputPorts) do if IsValid(v.Panel) then v.Panel:Remove() end end
	end
end

function PANEL:AddOutputPort(name, side, pos)
	doport(self, name, false, side, pos)
end

function PANEL:AddInputPort(name, side, pos)
	doport(self, name, true, side, pos)
end

function PANEL:OnDropIntoMap(x,y)
	-- Override me!
end
derma.DefineControl("DLogicMapUnit", "", PANEL, "DPanel")

local logicmapchips = {}
local logicmapconnections = {}

local MAP = {}
local ssheet = baseclass.Get("DScrollSheet")
local playermat = Material("icon16/arrow_right.png") -- Change this
function MAP:Init()
	ssheet.Init(self)
	self:MakeDroppable("nzu_logicmap")

	--[[self.Canvas.PaintOver = function(s,x,y)
		if drawwiremouse then
			surface.SetDrawColor(0,0,0)
			local mx,my = s:LocalCursorPos()
			surface.DrawLine(unpack(drawwiremouse), mx,my)
		end
	end]]
end
function MAP:Paint(x,y)
	local ply = LocalPlayer()
	local pos = ply:GetPos()
	local x,y = self:GetAbsoluteFramePosition(pos.x,pos.y)

	surface.SetMaterial(playermat)
	surface.SetDrawColor(255,255,255)
	surface.DrawTexturedRectRotated(x-25,y-25,50,50,ply:GetAngles()[2])
end
derma.DefineControl("DLogicMap", "", MAP, "DScrollSheet")

local logicmap
local addunittomap
local function addconnection(unit, outp, cid, c, chip)
	local outputport = chip.m_tOutputPorts[outp]
	if outputport then
		if outputport.Connections[cid] then return end -- It already exists. Maybe update?
		local target = c.Target
		if not IsValid(target) then return elseif not logicmapchips[target:Index()] then addunittomap(target) end

		local inputport = logicmapchips[target:Index()].m_tInputPorts[c.Input]
		if inputport then
			local p = vgui.Create("DLogicMapUnitConnection", logicmap)
			p:SetPorts(outputport, inputport)
			p:SetConnection(c)
		end		
	end
end
addunittomap = function(unit)
	if IsValid(logicmapchips[unit:Index()]) then return end

	if IsValid(logicmap) then
		local chip = vgui.Create("DLogicMapUnit", logicmap)
		chip:SetShowPorts(true)
		chip:SetLogicUnit(unit)
		chip:SetSize(50,50)
		local pos = unit:GetPos()
		logicmap:SetChildPos(chip, pos.x,pos.y)

		chip:Droppable("nzu_logicmap")
		chip.OnDropIntoMap = function(x,y)
			net.Start("nzu_logicmap_move")
				net.WriteUInt(unit:Index(), 16)
				net.WriteVector(Vector(x,y,0))
			net.SendToServer()
		end

		for k,v in pairs(unit:GetOutputConnections()) do
			for k2,v2 in pairs(v) do
				addconnection(unit, k, k2, v2, chip)
			end
		end

		logicmapchips[unit:Index()] = chip
	end
end

nzu.AddSpawnmenuTab("Logic Map", "DPanel", function(panel)
	panel:SetSkin("nZombies Unlimited")
	panel:SetBackgroundColor(Color(100,100,100))

	local toolbarwidth = 150
	
	local sidebar = panel:Add("DCategoryList")
	sidebar:SetWide(toolbarwidth)
	sidebar:Dock(RIGHT)
	function sidebar:ReloadLogicUnits()
		sidebar:Clear()
		local cats = {}
		for k,v in pairs(nzu.GetLogicUnitList()) do
			if v.Spawnable then
				local cat = v.Category or "Uncategorized"
				if not cats[cat] then cats[cat] = {} end
				cats[cat][k] = v
			end
		end

		for k,v in pairs(cats) do
			local c = sidebar:Add(k)
			for k2,v2 in pairs(v) do
				local pnl = vgui.Create("DPanel", c)
				pnl:SetSize(140,75)
				pnl:DockMargin(5,5,5,5)
				pnl:Dock(TOP)

				local name = pnl:Add("DLabel")
				name:SetText(v2.Name)
				name:Dock(BOTTOM)
				name:SetTextColor(color_black)
				name:SetContentAlignment(5)

				local icon = pnl:Add("DLogicMapUnit")
				icon:SetLogicUnit(v2)
				icon:SetSize(50,50)
				icon:SetPos(42.5,5)
				icon:Droppable("nzu_logicmap")
				icon.OnDropIntoMap = function(s,x,y)
					net.Start("nzu_logicmap_create")
						net.WriteString(k2)
						net.WriteVector(Vector(x,y,0))
					net.SendToServer()
					return true -- Don't drop into map
				end

				c:UpdateAltLines()
			end
		end
	end
	sidebar:ReloadLogicUnits()

	local map = panel:Add("DLogicMap")
	map:Dock(FILL)
	map:SetBackgroundColor(Color(100,100,100))

	local mapcontrol = panel:Add("DPanel")
	mapcontrol:SetTall(50)
	mapcontrol:DockPadding(5,5,5,5)

	local snaptoply = mapcontrol:Add("DButton")
	snaptoply:SetWide(40)
	snaptoply:Dock(RIGHT)
	snaptoply:SetText("Snap")
	snaptoply.DoClick = function(s)
		local p = LocalPlayer():GetPos()
		map:SnapTo(p.x,p.y)
	end

	panel.PerformLayout = function(s)
		local w,w2 = s:GetWide(), mapcontrol:GetWide()
		mapcontrol:SetPos(w - toolbarwidth - w2, 0)
	end

	logicmap = map
	for k,v in pairs(nzu.GetAllLogicUnits()) do
		addunittomap(v)
	end
end, "icon16/arrow_switch.png", "Create and connect Config Logic")

hook.Add("nzu_LogicUnitCreated", "nzu_LogicMapCreate", function(u) addunittomap(u) end)
hook.Add("nzu_LogicUnitConnected", "nzu_LogicMapConnected", function(u, outp, cid, c)
	local chip = logicmapchips[u:Index()]
	if not chip then addunittomap(u) end
	addconnection(u, outp, cid, c, chip)
end)