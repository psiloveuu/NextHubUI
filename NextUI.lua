if not isfile then
	_G.DebugFileSystem = _G.DebugFileSystem or {}

	function isfile(path)
		return _G.DebugFileSystem[path] ~= nil
	end

	function readfile(path)
		local data = _G.DebugFileSystem[path]
		if not data then
			warn("[NextHub Debug] File not found: " .. path)
		end
		return data or ""
	end

	function writefile(path, content)
		_G.DebugFileSystem[path] = content
		print("[NextHub Debug] Saved: " .. path)
	end
end

local NextHub = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- DEVICE
-- ==========================================
local ScreenW = workspace.CurrentCamera.ViewportSize.X
local ScreenH = workspace.CurrentCamera.ViewportSize.Y
local DeviceType
if UserInputService.TouchEnabled and not UserInputService.MouseEnabled and ScreenW < 760 then
	DeviceType = "Mobile"
elseif UserInputService.TouchEnabled and ScreenW < 1024 then
	DeviceType = "Tablet"
else
	DeviceType = "Desktop"
end

local DSConfig = {
	Mobile = {
		WindowW = 480, WindowH = 300, SidebarW = 126, HeaderH = 38,
		CompH = 25, CompHDesc = 36, FontTitle = 9, FontBase = 9,
		TabFontSz = 9, TabBtnH = 24, SliderH = 38, PanelW = 140,
		LogoSz = 28, FontBadge = 11, FontHeader = 11, NotifyW = 220,
		NotifyH = 45, NotifyIcon = 24, NotifyFontT = 11, NotifyFontC = 10,
		DDHeader = 26, Padding = 6, IconSz = 12, ToggleW = 28,
		ToggleH = 14, InputH = 19, FontDesc = 9, SectionHeaderH = 22,
		ProfAvatar = 24, ProfBtnH = 22, DDInd = 9, DDIndGap = 4,
	},
	Tablet = {
		WindowW = 600, WindowH = 390, SidebarW = 170, HeaderH = 46,
		CompH = 32, CompHDesc = 46, FontTitle = 12, FontBase = 12,
		TabFontSz = 11, TabBtnH = 34, SliderH = 48, PanelW = 175,
		LogoSz = 38, FontBadge = 14, FontHeader = 14, NotifyW = 260,
		NotifyH = 55, NotifyIcon = 28, NotifyFontT = 12, NotifyFontC = 11,
		DDHeader = 40, Padding = 10, IconSz = 16, ToggleW = 36,
		ToggleH = 18, InputH = 24, FontDesc = 11, SectionHeaderH = 28,
		ProfAvatar = 32, ProfBtnH = 27, DDInd = 13, DDIndGap = 5,
	},
	Desktop = {
		WindowW = 700, WindowH = 450, SidebarW = 194, HeaderH = 52,
		CompH = 34, CompHDesc = 50, FontTitle = 14, FontBase = 14,
		TabFontSz = 12, TabBtnH = 38, SliderH = 52, PanelW = 200,
		LogoSz = 42, FontBadge = 16, FontHeader = 16, NotifyW = 300,
		NotifyH = 65, NotifyIcon = 32, NotifyFontT = 14, NotifyFontC = 12,
		DDHeader = 50, Padding = 12, IconSz = 18, ToggleW = 40,
		ToggleH = 20, InputH = 26, FontDesc = 12, SectionHeaderH = 32,
		ProfAvatar = 38, ProfBtnH = 30, DDInd = 16, DDIndGap = 6,
	},
}
local DS = DSConfig[DeviceType] or DSConfig.Desktop

-- ==========================================
-- SAFE AREA CLAMP
-- ==========================================
do
	local topInset, bottomInset = 0, 0
	local ok, gs = pcall(function() return game:GetService("GuiService") end)
	if ok and gs and gs.GetGuiInset then
		local okInset, tl, br = pcall(function() return gs:GetGuiInset() end)
		if okInset and tl and br then
			topInset, bottomInset = tl.Y, br.Y
		end
	end

	local EdgeMargin = (DeviceType == "Mobile" or DeviceType == "Tablet") and 24 or 12
	local MaxWindowH = ScreenH - topInset - bottomInset - (EdgeMargin * 2)

	if MaxWindowH > 100 and DS.WindowH > MaxWindowH then
		DS.WindowH = MaxWindowH
	end
end

-- ==========================================
-- RESPONSIVE SCALE
-- ==========================================
local ResponsiveScale
do
	local RefW  = { Mobile = 700,          Tablet = 850,          Desktop = 1280 }
	local Clamp = { Mobile = {0.8, 1.0},   Tablet = {0.85, 1.2},  Desktop = {0.85, 1.5} }

	local refW = RefW[DeviceType] or 1280
	local minS, maxS = table.unpack(Clamp[DeviceType] or { 0.85, 1.5 })

	ResponsiveScale = math.clamp(ScreenW / refW, minS, maxS)
end

-- ==========================================
-- STYLE
-- ==========================================
local Style = {
	DarkBg = Color3.fromRGB(20, 20, 20),
	SidebarBg = Color3.fromRGB(20, 20, 20),
	InputBg = Color3.fromRGB(30, 30, 30),
	InputStroke = Color3.fromRGB(150, 150, 150),
	Primary = Color3.fromRGB(17, 79, 129),
	Text = Color3.fromRGB(235, 235, 235),
	TextDim = Color3.fromRGB(205, 205, 205),
	HeaderBadge = Color3.fromRGB(100, 180, 255),
	VersionBadge = Color3.fromRGB(255, 232, 25),
	ToggleOff = Color3.fromRGB(70, 70, 70),
	FontBase = "rbxasset://fonts/families/GothamSSm.json",
	ElementBackground = Color3.fromRGB(30, 30, 30),
	Outline = Color3.fromRGB(60, 60, 70),
	Hover = Color3.fromRGB(40, 45, 60),
	CheckboxOn = Color3.fromRGB(100, 180, 255),
	CheckboxOff = Color3.fromRGB(60, 60, 70),
}

local function GetFont(weight)
	return Font.new(Style.FontBase, weight or Enum.FontWeight.Regular)
end

-- ==========================================
-- ICONS
-- ==========================================
local IconCache = {}
local iconInitDone = false

local RawPacks = {
	lucide = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua",
	solar = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/solar/dist/Icons.lua",
	craft = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/craft/dist/Icons.lua",
	geist = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/geist/dist/Icons.lua",
}

local ICON_FALLBACK = {
	["x"] = "rbxassetid://110786993356448",
	["minus"] = "rbxassetid://118026365011536",
	["check"] = "rbxassetid://93898873302694",
	["chevron-right"] = "rbxassetid://92473583511724",
	["chevron-down"] = "rbxassetid://134243273101015",
	["chevron-left"] = "rbxassetid://73780377692148",
	["chevron-up"] = "rbxassetid://122444883127455",
	["bell"] = "rbxassetid://97392696311902",
	["mouse-pointer-2"] = "rbxassetid://117093892862228",
	["info-square-bold"] = "rbxassetid://131995373201472",
	["fish"] = "rbxassetid://124360663785796",
	["repeat-2"] = "rbxassetid://78082218499697",
	["shopping-cart"] = "rbxassetid://121098640829562",
	["arrow-left-right"] = "rbxassetid://131324733048447",
	["map-pin"] = "rbxassetid://100033680381365",
	["activity"] = "rbxassetid://94212016861936",
	["link"] = "rbxassetid://92181172123618",
	["swords"] = "rbxassetid://132405197863294",
	["skull"] = "rbxassetid://74237056000103",
	["user"] = "rbxassetid://95489465399880",
	["calendar"] = "rbxassetid://114792700814035",
	["crown"] = "rbxassetid://127843403295538",
	["sparkles"] = "rbxassetid://138635884129147",
	["settings"] = "rbxassetid://80758916183665",
}

local function InitIcons()
	if iconInitDone then return end
	iconInitDone = true

	if isfile and isfile("nexthub_icons.json") then
		local ok, data = pcall(function()
			return HttpService:JSONDecode(readfile("nexthub_icons.json"))
		end)
		if ok and type(data) == "table" and next(data) then
			IconCache = data
			return
		end
	end

	local fetchOk = false
	for _, url in pairs(RawPacks) do
		local ok, data = pcall(function() 
			return loadstring(game:HttpGet(url))() 
		end)

		if ok and type(data) == "table" then
			for k, v in pairs(data) do
				if type(v) == "table" and v.Image then
					IconCache[k] = v.Image
				elseif type(v) == "string" and v:find("rbxassetid") then
					IconCache[k] = v
				end
			end
			fetchOk = true
		end
	end

	if fetchOk and writefile then
		pcall(function() writefile("nexthub_icons.json", HttpService:JSONEncode(IconCache)) end)
	end
end

local function GetIcon(name)
	if type(name) ~= "string" then 
		return "" 
	end

	local clean = name:match(":(.+)") or name
	if IconCache[clean] then 
		return IconCache[clean] 
	end

	if not iconInitDone then
		InitIcons()
		if IconCache[clean] then 
			return IconCache[clean] 
		end
	end
	return ICON_FALLBACK[clean] or ""
end

-- ==========================================
-- UTILITIES
-- ==========================================
local Connections = {}

local function Create(className, props)
	local inst = Instance.new(className)
	for k, v in pairs(props) do
		inst[k] = v
	end
	return inst
end

local function MakeDraggable(handle, target)
	local dragging = false
	local dragInput, dragStart, startPos

	local function update(input)
		local delta = input.Position - dragStart
		local pos = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
		TweenService:Create(target, TweenInfo.new(0.15, Enum.EasingStyle.Quint), { Position = pos }):Play()
	end

	table.insert(Connections, handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position

			local conn
			conn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if conn then conn:Disconnect() end
				end
			end)
		end
	end))

	table.insert(Connections, handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement 
			or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end))

	table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then update(input) end
	end))
end

--local function MakeResizable(handle, target, opts)
--      local resizing = false
--      local startInputPos, startAbsSize, startLocalSize, startLocalPos

--      local function updateResize(input)
--              local scale = (opts.getScale and opts.getScale()) or 1
--              if not scale or scale <= 0 then scale = 1 end

--              local mouseDelta = input.Position - startInputPos

--              local minW, maxW = opts.minW, math.max(opts.minW, opts.maxW)
--              local minH, maxH = opts.minH, math.max(opts.minH, opts.maxH)

--              local desiredAbsW = math.clamp(startAbsSize.X + mouseDelta.X, minW * scale, maxW * scale)
--              local desiredAbsH = math.clamp(startAbsSize.Y + mouseDelta.Y, minH * scale, maxH * scale)

--              local newLocalW = desiredAbsW / scale
--              local newLocalH = desiredAbsH / scale

--              target.Size = UDim2.new(startLocalSize.X.Scale, newLocalW, startLocalSize.Y.Scale, newLocalH)
--              target.Position = UDim2.new(
--                      startLocalPos.X.Scale, startLocalPos.X.Offset + (desiredAbsW - startAbsSize.X) / 2,
--                      startLocalPos.Y.Scale, startLocalPos.Y.Offset + (desiredAbsH - startAbsSize.Y) / 2
--              )
--      end

--      table.insert(Connections, handle.InputBegan:Connect(function(input)
--              if input.UserInputType == Enum.UserInputType.MouseButton1 
--                      or input.UserInputType == Enum.UserInputType.Touch then
--                      resizing = true
--                      startInputPos = input.Position
--                      startAbsSize = target.AbsoluteSize
--                      startLocalSize = target.Size
--                      startLocalPos = target.Position
--              end
--      end))

--      table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
--              if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement 
--                      or input.UserInputType == Enum.UserInputType.Touch) then
--                      updateResize(input)
--              end
--      end))

--      table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
--              if input.UserInputType == Enum.UserInputType.MouseButton1 
--                      or input.UserInputType == Enum.UserInputType.Touch then
--                      resizing = false
--              end
--      end))
--end

-- ==========================================
-- CONFIG SYSTEM
-- ==========================================
local ConfigData = {}
local ConfigGameName = "Unknown"

local function ConfigFolder() 
	return "NextHub/" .. ConfigGameName 
end

local function ConfigPath(name) 
	return ConfigFolder() .. "/" .. name .. ".json" 
end

local function EnsureFolder()
	if not isfolder then return end
	if not isfolder("NextHub") then pcall(makefolder, "NextHub") end
	if not isfolder(ConfigFolder()) then pcall(makefolder, ConfigFolder()) end
end

local function ListConfigs()
	if not listfiles or not isfolder then return {} end

	EnsureFolder()

	local result = {}

	local ok, files = pcall(listfiles, ConfigFolder())
	if ok and files then
		for _, path in ipairs(files) do
			local name = path:match("([^/\\]+)%.json$")
			if name then table.insert(result, name) end
		end
	end

	return result
end

local function SaveNamedConfig(name)
	if not writefile or not name or name == "" then return false end

	EnsureFolder()

	return pcall(function()
		writefile(ConfigPath(name), HttpService:JSONEncode(ConfigData))
	end)
end

local function LoadNamedConfig(name)
	if not isfile or not readfile or not name or name == "" then return false end

	local path = ConfigPath(name)

	if not isfile(path) then return false end

	local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)

	if ok and type(data) == "table" then
		ConfigData = data
		return true
	end

	return false
end

local function DeleteNamedConfig(name)
	if not isfile or not name or name == "" then return false end

	local path = ConfigPath(name)

	if not isfile(path) then return false end

	return pcall(delfile, path)
end

-- ==========================================
-- THEME SYSTEM
-- ==========================================
local Themes = {
	Original = {
		DarkBg = Color3.fromRGB(20, 20, 20),
		SidebarBg = Color3.fromRGB(20, 20, 20),
		InputBg = Color3.fromRGB(30, 30, 30),
		InputStroke = Color3.fromRGB(150, 150, 150),
		Primary = Color3.fromRGB(17, 79, 129),
		Text = Color3.fromRGB(235, 235, 235),
		TextDim = Color3.fromRGB(205, 205, 205),
		ElementBackground = Color3.fromRGB(30, 30, 30),
		Outline = Color3.fromRGB(60, 60, 70),
		Hover = Color3.fromRGB(40, 45, 60),
		CheckboxOn = Color3.fromRGB(100, 180, 255),
		CheckboxOff = Color3.fromRGB(60, 60, 70),
		ToggleOff = Color3.fromRGB(70, 70, 70),
	},
	Matrix = {
		DarkBg = Color3.fromRGB(10, 14, 12),
		SidebarBg = Color3.fromRGB(10, 14, 12),
		InputBg = Color3.fromRGB(16, 22, 18),
		InputStroke = Color3.fromRGB(40, 80, 55),
		Primary = Color3.fromRGB(72, 168, 108),
		Text = Color3.fromRGB(175, 200, 185),
		TextDim = Color3.fromRGB(150, 175, 160),
		ElementBackground = Color3.fromRGB(16, 22, 18),
		Outline = Color3.fromRGB(28, 44, 34),
		Hover = Color3.fromRGB(20, 34, 26),
		CheckboxOn = Color3.fromRGB(72, 168, 108),
		CheckboxOff = Color3.fromRGB(28, 50, 36),
		ToggleOff = Color3.fromRGB(28, 50, 36),
	},
	Mono = {
		DarkBg = Color3.fromRGB(13, 13, 15),
		SidebarBg = Color3.fromRGB(13, 13, 15),
		InputBg = Color3.fromRGB(22, 22, 26),
		InputStroke = Color3.fromRGB(55, 55, 62),
		Primary = Color3.fromRGB(165, 165, 180),
		Text = Color3.fromRGB(190, 190, 200),
		TextDim = Color3.fromRGB(165, 165, 175),
		ElementBackground = Color3.fromRGB(22, 22, 26),
		Outline = Color3.fromRGB(38, 38, 44),
		Hover = Color3.fromRGB(30, 30, 36),
		CheckboxOn = Color3.fromRGB(165, 165, 180),
		CheckboxOff = Color3.fromRGB(42, 42, 50),
		ToggleOff = Color3.fromRGB(42, 42, 50),
	},
	Violet = {
		DarkBg = Color3.fromRGB(13, 11, 20),
		SidebarBg = Color3.fromRGB(13, 11, 20),
		InputBg = Color3.fromRGB(22, 18, 34),
		InputStroke = Color3.fromRGB(60, 48, 90),
		Primary = Color3.fromRGB(135, 105, 200),
		Text = Color3.fromRGB(195, 188, 215),
		TextDim = Color3.fromRGB(170, 163, 190),
		ElementBackground = Color3.fromRGB(22, 18, 34),
		Outline = Color3.fromRGB(40, 32, 62),
		Hover = Color3.fromRGB(30, 24, 48),
		CheckboxOn = Color3.fromRGB(135, 105, 200),
		CheckboxOff = Color3.fromRGB(44, 34, 68),
		ToggleOff = Color3.fromRGB(44, 34, 68),
	},
	Crimson = {
		DarkBg = Color3.fromRGB(16, 10, 11),
		SidebarBg = Color3.fromRGB(16, 10, 11),
		InputBg = Color3.fromRGB(26, 16, 17),
		InputStroke = Color3.fromRGB(78, 36, 38),
		Primary = Color3.fromRGB(185, 80, 85),
		Text = Color3.fromRGB(205, 190, 190),
		TextDim = Color3.fromRGB(180, 165, 165),
		ElementBackground = Color3.fromRGB(26, 16, 17),
		Outline = Color3.fromRGB(50, 28, 30),
		Hover = Color3.fromRGB(36, 20, 22),
		CheckboxOn = Color3.fromRGB(185, 80, 85),
		CheckboxOff = Color3.fromRGB(52, 28, 30),
		ToggleOff = Color3.fromRGB(52, 28, 30),
	},
	Aurum = {
		DarkBg = Color3.fromRGB(14, 12, 8),
		SidebarBg = Color3.fromRGB(14, 12, 8),
		InputBg = Color3.fromRGB(24, 20, 12),
		InputStroke = Color3.fromRGB(80, 65, 28),
		Primary = Color3.fromRGB(188, 155, 72),
		Text = Color3.fromRGB(215, 205, 175),
		TextDim = Color3.fromRGB(190, 180, 150),
		ElementBackground = Color3.fromRGB(24, 20, 12),
		Outline = Color3.fromRGB(48, 38, 16),
		Hover = Color3.fromRGB(34, 27, 10),
		CheckboxOn = Color3.fromRGB(188, 155, 72),
		CheckboxOff = Color3.fromRGB(50, 40, 14),
		ToggleOff = Color3.fromRGB(50, 40, 14),
	},
	Ocean = {
		DarkBg = Color3.fromRGB(8, 14, 22),
		SidebarBg = Color3.fromRGB(8, 14, 22),
		InputBg = Color3.fromRGB(12, 22, 34),
		InputStroke = Color3.fromRGB(28, 62, 88),
		Primary = Color3.fromRGB(60, 165, 195),
		Text = Color3.fromRGB(175, 200, 215),
		TextDim = Color3.fromRGB(150, 175, 190),
		ElementBackground = Color3.fromRGB(12, 22, 34),
		Outline = Color3.fromRGB(20, 44, 62),
		Hover = Color3.fromRGB(14, 32, 48),
		CheckboxOn = Color3.fromRGB(60, 165, 195),
		CheckboxOff = Color3.fromRGB(18, 48, 65),
		ToggleOff = Color3.fromRGB(18, 48, 65),
	},
	Rose = {
		DarkBg = Color3.fromRGB(18, 11, 15),
		SidebarBg = Color3.fromRGB(18, 11, 15),
		InputBg = Color3.fromRGB(28, 16, 22),
		InputStroke = Color3.fromRGB(78, 42, 58),
		Primary = Color3.fromRGB(188, 105, 138),
		Text = Color3.fromRGB(215, 190, 200),
		TextDim = Color3.fromRGB(190, 165, 175),
		ElementBackground = Color3.fromRGB(28, 16, 22),
		Outline = Color3.fromRGB(50, 28, 38),
		Hover = Color3.fromRGB(36, 20, 28),
		CheckboxOn = Color3.fromRGB(188, 105, 138),
		CheckboxOff = Color3.fromRGB(50, 28, 38),
		ToggleOff = Color3.fromRGB(50, 28, 38),
	},
}

local ThemeOrder = { "Original", "Matrix", "Mono", "Violet", "Crimson", "Aurum", "Ocean", "Rose" }
local CurrentThemeName = "Original"
local ThemeRegistry = {}

local function RegisterTheme(entry)
	table.insert(ThemeRegistry, entry)
end

local function ApplyTheme(themeName)
	local theme = Themes[themeName]
	if not theme then return end

	CurrentThemeName = themeName

	for k, v in pairs(theme) do Style[k] = v end

	local tw = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	for _, entry in ipairs(ThemeRegistry) do
		pcall(function()
			if entry.custom then
				if (not entry.object) or entry.object.Parent then
					entry.custom(theme, tw)
				end
				return
			end

			if entry.object and entry.object.Parent then
				local color = theme[entry.key]

				if color then
					TweenService:Create(entry.object, tw, { [entry.prop] = color }):Play()
				end
			end
		end)
	end
end

-- ==========================================
-- HIDDEN CONTAINER
-- ==========================================
local function GetHiddenContainer()
	if type(gethui) == "function" then
		local ok, c = pcall(gethui)
		if ok and c then
			return c
		end
	end

	local ok, cg = pcall(function()
		return game:GetService("CoreGui")
	end)

	if ok and cg then
		return cg
	end

	if type(syn) == "table" and type(syn.protect_gui) == "function" then
		local sg = Instance.new("ScreenGui")

		pcall(syn.protect_gui, sg)

		sg.Parent = game:GetService("CoreGui")

		return sg
	end

	return LocalPlayer:WaitForChild("PlayerGui")
end

-- ==========================================
-- WINDOW
-- ==========================================
function NextHub:CreateWindow(props)
	props = props or {}

	local title = props.Title or "NextHub"
	local logo = props.Logo or "rbxassetid://111607497408853"
	local version = props.Version or "1.0.0"
	local gameName = props.Game or "Unknown"
	local Mode = props.Mode or "Free"
	local Update = props.Update or "Beta"

	ConfigGameName = gameName

	local ScreenGui = Create("ScreenGui", {
		Name = HttpService:GenerateGUID(false),
		Parent = GetHiddenContainer(),
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
	})

	local InitialSize = UDim2.new(0, DS.WindowW, 0, DS.WindowH)
	local InitialPos = UDim2.new(0.5, 0, 0.5, 0)

	local MainFrame = Create("Frame", {
		Name = "MainFrame",
		Parent = ScreenGui,
		BackgroundColor3 = Style.DarkBg,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = InitialPos,
		Size = InitialSize,
		ClipsDescendants = true,
	})
	local WindowScale = Create("UIScale", { Parent = MainFrame, Scale = ResponsiveScale })
	Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = MainFrame })

	local MainStroke = Create("UIStroke", { 
		Color = Style.Primary, 
		Thickness = 1.7, 
		Transparency = 0.2, 
		Parent = MainFrame 
	})
	RegisterTheme({ object = MainFrame, prop = "BackgroundColor3", key = "DarkBg" })
	RegisterTheme({ object = MainStroke, prop = "Color", key = "Primary" })

	-- ==========================================
	-- RESIZE HANDLE
	-- ==========================================
	--local ResizeHandle = Create("Frame", {
	--      Name = "ResizeHandle",
	--      Parent = MainFrame,
	--      AnchorPoint = Vector2.new(1, 1),
	--      Position = UDim2.new(1, 0, 1, 0),
	--      Size = UDim2.new(0, 20, 0, 20),
	--      BackgroundTransparency = 1,
	--      ZIndex = 999,
	--      Active = true,
	--})
	--for i = 1, 3 do
	--      local grip = Create("Frame", {
	--              Parent = ResizeHandle,
	--              AnchorPoint = Vector2.new(1, 1),
	--              Position = UDim2.new(1, -3 - (i - 1) * 4, 1, -3),
	--              Size = UDim2.new(0, 1.4, 0, i * 4),
	--              Rotation = 45,
	--              BackgroundColor3 = Style.TextDim,
	--              BackgroundTransparency = 0.15,
	--              BorderSizePixel = 0,
	--              ZIndex = 999,
	--      })
	--      RegisterTheme({ object = grip, prop = "BackgroundColor3", key = "TextDim" })
	--end

	--MakeResizable(ResizeHandle, MainFrame, {
	--      minW = DS.WindowW * 0.65,
	--      minH = DS.WindowH * 0.65,
	--      maxW = math.min(DS.WindowW * 1.8, (ScreenW * 0.92) / ResponsiveScale),
	--      maxH = math.min(DS.WindowH * 1.8, (ScreenH * 0.85) / ResponsiveScale),
	--      getScale = function() return WindowScale.Scale end,
	--})

	local Header = Create("Frame", {
		Size = UDim2.new(1, 0, 0, DS.HeaderH),
		BackgroundTransparency = 1,
		Parent = MainFrame,
	})
	MakeDraggable(Header, MainFrame)

	Create("ImageLabel", {
		Image = logo,
		Size = UDim2.fromOffset(DS.LogoSz, DS.LogoSz),
		Position = UDim2.fromOffset(6, (DS.HeaderH - DS.LogoSz) / 2),
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
		Parent = Header,
	})

	local titleRow = Create("Frame", {
		Name = "TitleRow",
		Parent = Header,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 6 + DS.LogoSz + 8, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
	})
	Create("UIListLayout", {
		Parent = titleRow,
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 14),
	})

	local textStack = Create("Frame", {
		Name = "TextStack",
		Parent = titleRow,
		Size = UDim2.new(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
	})
	Create("UIListLayout", {
		Parent = textStack,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 0),
	})

	Create("TextLabel", {
		Text = title,
		Size = UDim2.new(0, 0, 0, DS.FontHeader + 2),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		FontFace = GetFont(Enum.FontWeight.Bold),
		TextSize = DS.FontHeader + 2,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Style.Text,
		LayoutOrder = 1,
		Parent = textStack,
	})

	Create("TextLabel", {
		Text = version,
		Size = UDim2.new(0, 0, 0, DS.FontBadge - 2),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		FontFace = GetFont(Enum.FontWeight.Regular),
		TextSize = DS.FontBadge - 2,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Style.TextDim,
		LayoutOrder = 2,
		Parent = textStack,
	})

	local gameLabel = Create("TextLabel", {
		Name = "GameTitle",
		Parent = titleRow,
		Text = gameName,
		Size = UDim2.new(0, 0, 0, DS.FontBadge + 2),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		FontFace = GetFont(Enum.FontWeight.Bold),
		TextSize = DS.FontBadge - 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Style.TextDim,
		LayoutOrder = 3,
	})
	RegisterTheme({ object = gameLabel, prop = "TextColor3", key = "VersionBadge" })

	-- ==========================================
	-- FPS & PING INDICATOR
	-- ==========================================
	local PerfGood = Color3.fromRGB(88, 200, 120)
	local PerfMid = Color3.fromRGB(255, 232, 25)
	local PerfBad = Color3.fromRGB(240, 90, 90)

	local fpsLabel = Create("TextLabel", {
		Name = "FpsIndicator",
		Parent = titleRow,
		Text = "FPS --",
		Size = UDim2.new(0, 0, 0, DS.FontBadge + 2),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		FontFace = GetFont(Enum.FontWeight.SemiBold),
		TextSize = DS.FontBadge - 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Style.TextDim,
		LayoutOrder = 4,
	})

	local pingLabel = Create("TextLabel", {
		Name = "PingIndicator",
		Parent = titleRow,
		Text = "Ping --",
		Size = UDim2.new(0, 0, 0, DS.FontBadge + 2),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		FontFace = GetFont(Enum.FontWeight.SemiBold),
		TextSize = DS.FontBadge - 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Style.TextDim,
		LayoutOrder = 5,
	})

	do
		task.spawn(function()
			while ScreenGui.Parent do
				task.wait(0.5)

				if not ScreenGui.Parent then break end

				local fps = workspace:GetRealPhysicsFPS()
				fpsLabel.Text = string.format("FPS %d", math.floor(fps + 0.5))
				fpsLabel.TextColor3 = (fps >= 50 and PerfGood) or (fps >= 30 and PerfMid) or PerfBad

				local ping = nil

				local okP, p = pcall(function() return LocalPlayer:GetNetworkPing() end)
				if okP and typeof(p) == "number" and p > 0 then
					ping = (p < 5) and (p * 1000) or p
				else
					local okD, d = pcall(function()
						return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
					end)
					if okD and typeof(d) == "number" then ping = d end
				end

				if ping then
					pingLabel.Text = string.format("Ping %dms", math.floor(ping + 0.5))
					pingLabel.TextColor3 = (ping <= 80 and PerfGood) or (ping <= 150 and PerfMid) or PerfBad
				else
					pingLabel.Text = "Ping --"
					pingLabel.TextColor3 = Style.TextDim
				end
			end
		end)
	end

	local btnSz = 22
	local closeBtn = Create("ImageButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Size = UDim2.fromOffset(btnSz, btnSz),
		Position = UDim2.new(1, -10, 0.5, 0),
		BackgroundTransparency = 1,
		Image = GetIcon("x"),
		ImageColor3 = Color3.fromRGB(190, 220, 255),
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 10,
		Active = true,
		Parent = Header,
	})

	local minimizeBtn = Create("ImageButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Size = UDim2.fromOffset(btnSz, btnSz),
		Position = UDim2.new(1, -(10 + btnSz + 6), 0.5, 0),
		BackgroundTransparency = 1,
		Image = GetIcon("minus"),
		ImageColor3 = Color3.fromRGB(190, 220, 255),
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 10,
		Active = true,
		Parent = Header,
	})

	task.spawn(function()
		task.wait()
		if not gameLabel.Parent then return end

		local scale = WindowScale.Scale
		local rowStart = 6 + DS.LogoSz + 8
		local btnZone = 10 + btnSz + 6 + btnSz + 10
		local availW = DS.WindowW - rowStart - btnZone
		local rowW = titleRow.AbsoluteSize.X / scale

		if rowW > availW then
			local maxGameW = (gameLabel.AbsoluteSize.X / scale) - (rowW - availW)
			if maxGameW > 12 then
				gameLabel.AutomaticSize = Enum.AutomaticSize.None
				gameLabel.Size = UDim2.new(0, maxGameW, 0, DS.FontBadge + 2)
				gameLabel.TextTruncate = Enum.TextTruncate.AtEnd
			end
		end
	end)

	local IsMinimized = false

	local toggleBtn = Create("ImageButton", {
		Name = "ToggleUI", 
		Parent = ScreenGui,
		BackgroundColor3 = Style.DarkBg, 
		BorderSizePixel = 0,
		Position = UDim2.new(0.1, 0, 0.2, 0),
		Size = UDim2.new(0, DS.HeaderH -6, 0, DS.HeaderH -6),
		Image = "rbxassetid://111607497408853",
		ImageColor3 = Style.Text, 
		Visible = true,
		Active = true, 
		AutoButtonColor = false, 
		Selectable = true, 
		ZIndex = 100,
	})
	MakeDraggable(toggleBtn, toggleBtn)
	Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = toggleBtn })

	local toggleStroke = Create("UIStroke", { 
		Color = Style.Primary, 
		Thickness = 1.3, 
		Parent = toggleBtn 
	})
	RegisterTheme({ object = toggleStroke, prop = "Color", key = "Primary"})

	local function ToggleUI()
		IsMinimized = not IsMinimized

		if IsMinimized then
			local tw = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
				Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1,
			})

			TweenService:Create(WindowScale, TweenInfo.new(0.3), { Scale = ResponsiveScale * 0.5 }):Play()
			tw:Play()

			tw.Completed:Connect(function()
				if IsMinimized then MainFrame.Visible = false end
			end)
		else
			MainFrame.Visible = true
			MainFrame.Size = UDim2.new(0, 0, 0, 0)

			TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = InitialSize, BackgroundTransparency = 0,
			}):Play()

			TweenService:Create(WindowScale, TweenInfo.new(0.3), { Scale = ResponsiveScale }):Play()
		end
	end

	local function DoClose()
		local tw = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1,
		})

		tw:Play()
		tw.Completed:Connect(function() ScreenGui:Destroy() end)
	end

	local function ShowCloseConfirm()
		local backdrop = Create("Frame", {
			Name = "CloseConfirmBackdrop",
			Parent = MainFrame,
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 500,
			Active = true,
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = backdrop })
		TweenService:Create(backdrop, TweenInfo.new(0.2), { BackgroundTransparency = 0.45 }):Play()

		local dialogW = math.clamp(DS.WindowW * 0.62, 220, 340)
		local dialog = Create("Frame", {
			Name = "CloseConfirmDialog",
			Parent = backdrop,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0, dialogW, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Style.DarkBg,
			BorderSizePixel = 0,
			ZIndex = 501,
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = dialog })
		local dlgStroke = Create("UIStroke", { Color = Style.Primary, Thickness = 1.5, Transparency = 0.2, Parent = dialog })
		RegisterTheme({ object = dialog, prop = "BackgroundColor3", key = "DarkBg" })
		RegisterTheme({ object = dlgStroke, prop = "Color", key = "Primary" })

		Create("UIPadding", {
			Parent = dialog,
			PaddingTop = UDim.new(0, DS.Padding * 1.5),
			PaddingBottom = UDim.new(0, DS.Padding * 1.5),
			PaddingLeft = UDim.new(0, DS.Padding * 1.5),
			PaddingRight = UDim.new(0, DS.Padding * 1.5),
		})
		local dlgList = Create("UIListLayout", {
			Parent = dialog, SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, DS.Padding), HorizontalAlignment = Enum.HorizontalAlignment.Center,
		})

		local dlgTitle = Create("TextLabel", {
			Parent = dialog, BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, DS.FontHeader + 6),
			FontFace = GetFont(Enum.FontWeight.Bold),
			Text = "Close NextHub?",
			TextColor3 = Style.Text, TextSize = DS.FontHeader,
			LayoutOrder = 1,
		})
		RegisterTheme({ object = dlgTitle, prop = "TextColor3", key = "Text" })

		local dlgDesc = Create("TextLabel", {
			Parent = dialog, BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			FontFace = GetFont(Enum.FontWeight.Regular),
			Text = "The script will close, and you'll need to execute again to bring it back up.",
			TextColor3 = Style.TextDim, TextSize = DS.FontDesc,
			TextWrapped = true, LayoutOrder = 2,
		})
		RegisterTheme({ object = dlgDesc, prop = "TextColor3", key = "TextDim" })

		local btnRow = Create("Frame", {
			Parent = dialog, BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, DS.CompH + 6),
			LayoutOrder = 3,
		})
		Create("UIListLayout", {
			Parent = btnRow, FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, DS.Padding),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		})

		local cancelBtn = Create("TextButton", {
			Parent = btnRow,
			Size = UDim2.new(0.5, -DS.Padding / 2, 1, 0),
			BackgroundColor3 = Style.ElementBackground,
			AutoButtonColor = false,
			Text = "Cancel",
			FontFace = GetFont(Enum.FontWeight.Bold),
			TextColor3 = Style.Text, TextSize = DS.FontBase,
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = cancelBtn })
		RegisterTheme({ object = cancelBtn, prop = "BackgroundColor3", key = "ElementBackground" })
		RegisterTheme({ object = cancelBtn, prop = "TextColor3", key = "Text" })

		local confirmBtn = Create("TextButton", {
			Parent = btnRow,
			Size = UDim2.new(0.5, -DS.Padding / 2, 1, 0),
			BackgroundColor3 = Style.Primary,
			AutoButtonColor = false,
			Text = "Close",
			FontFace = GetFont(Enum.FontWeight.Bold),
			TextColor3 = Color3.fromRGB(235, 235, 235), TextSize = DS.FontBase,
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = confirmBtn })
		RegisterTheme({ object = confirmBtn, prop = "BackgroundColor3", key = "Primary" })

		local function DismissConfirm()
			TweenService:Create(backdrop, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
			task.delay(0.15, function() backdrop:Destroy() end)
		end

		cancelBtn.Activated:Connect(DismissConfirm)
		confirmBtn.Activated:Connect(function()
			backdrop:Destroy()
			DoClose()
		end)
	end

	closeBtn.Activated:Connect(ShowCloseConfirm)

	toggleBtn.Activated:Connect(ToggleUI)
	minimizeBtn.Activated:Connect(ToggleUI)

	-- ==========================================
	-- PROFILE CARD (below sidebar)
	-- ==========================================
	local profPadV = math.max(4, DS.Padding - 2)
	local profNameH = DS.FontBase + 4
	local profStatusH = DS.FontDesc + 2
	local chevSz = DS.IconSz
	local profAvatarSz = DS.ProfAvatar
	local profCardH = profAvatarSz + profPadV * 2

	local Sidebar = Create("Frame", {
		Name = "Sidebar",
		Parent = MainFrame,
		BackgroundColor3 = Style.SidebarBg,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, DS.HeaderH),
		Size = UDim2.new(0, DS.SidebarW, 1, -(DS.HeaderH + profCardH + 12)),
		ZIndex = 50,
	})
	RegisterTheme({ object = Sidebar, prop = "BackgroundColor3", key = "SidebarBg" })

	local profileCard = Create("Frame", {
		Name = "ProfileCard",
		Parent = MainFrame,
		BackgroundColor3 = Style.ElementBackground,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 6, 1, -6),
		Size = UDim2.new(0, DS.SidebarW - 12, 0, profCardH),
		ZIndex = 50,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = profileCard })
	local profStroke = Create("UIStroke", { Color = Style.Outline, Thickness = 1, Transparency = 0.35, Parent = profileCard })
	RegisterTheme({ object = profileCard, prop = "BackgroundColor3", key = "ElementBackground" })
	RegisterTheme({ object = profStroke, prop = "Color", key = "Outline" })

	local avatar = Create("ImageLabel", {
		Name = "Avatar",
		Parent = profileCard,
		BackgroundColor3 = Style.InputBg,
		BackgroundTransparency = 0.4,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, profPadV, 0.5, 0),
		Size = UDim2.new(0, profAvatarSz, 0, profAvatarSz),
		Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=100&h=100",
		ZIndex = 51,
	})
	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = avatar })
	Create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1, Transparency = 0.15, Parent = avatar })
	RegisterTheme({ object = avatar, prop = "BackgroundColor3", key = "InputBg" })

	local profTextX = profPadV + profAvatarSz + profPadV

	local userLabel = Create("TextLabel", {
		Name = "Username",
		Parent = profileCard,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, profTextX, 0, (profCardH - profNameH - profStatusH) / 2),
		Size = UDim2.new(1, -(profTextX + chevSz + profPadV + 6), 0, profNameH),
		FontFace = GetFont(Enum.FontWeight.Bold),
		Text = LocalPlayer.Name,
		TextColor3 = Style.Text,
		TextSize = DS.FontBase,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 51,
	})
	RegisterTheme({ object = userLabel, prop = "TextColor3", key = "Text" })

	local isPremium = tostring(Mode):lower() == "premium"

	local statusLabel = Create("TextLabel", {
		Name = "Membership",
		Parent = profileCard,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, profTextX, 0, (profCardH - profNameH - profStatusH) / 2 + profNameH),
		Size = UDim2.new(1, -(profTextX + chevSz + profPadV + 6), 0, profStatusH),
		FontFace = GetFont(Enum.FontWeight.Medium),
		Text = tostring(Mode),
		TextColor3 = isPremium and Style.VersionBadge or Style.TextDim,
		TextSize = DS.FontDesc - 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 51,
	})
	RegisterTheme({ object = statusLabel, prop = "TextColor3", key = isPremium and "VersionBadge" or "TextDim" })

	local profileChevron = Create("ImageLabel", {
		Name = "ProfileChevron",
		Parent = profileCard,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -profPadV, 0.5, 0),
		Size = UDim2.new(0, chevSz, 0, chevSz),
		Image = GetIcon("chevron-down"),
		ImageColor3 = Style.TextDim,
		Rotation = 180,
		ZIndex = 51,
	})
	RegisterTheme({ object = profileChevron, prop = "ImageColor3", key = "TextDim" })

	local cardBtn = Create("TextButton", {
		Name = "CardClick",
		Parent = profileCard,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Text = "",
		Active = true,
		ZIndex = 52,
	})

	local profBtnH = DS.ProfBtnH
	local toggleClip = Create("Frame", {
		Name = "ProfileToggleClip",
		Parent = MainFrame,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 6, 1, -(6 + profCardH + 6)),
		Size = UDim2.new(0, DS.SidebarW - 12, 0, profBtnH),
		ClipsDescendants = true,
		Visible = false,
		ZIndex = 60,
	})

	local profileToggle = Create("TextButton", {
		Name = "ProfileToggle",
		Parent = toggleClip,
		BackgroundColor3 = Style.ElementBackground,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 1, 0),
		FontFace = GetFont(Enum.FontWeight.SemiBold),
		Text = "Hide Profile",
		TextColor3 = Style.Text,
		TextSize = DS.FontBase - 1,
		AutoButtonColor = false,
		Active = true,
		ZIndex = 61,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = profileToggle })
	local toggleStroke = Create("UIStroke", { Color = Style.Outline, Thickness = 1, Transparency = 0.35, Parent = profileToggle })
	RegisterTheme({ object = profileToggle, prop = "BackgroundColor3", key = "ElementBackground" })
	RegisterTheme({ object = profileToggle, prop = "TextColor3", key = "Text" })
	RegisterTheme({ object = toggleStroke, prop = "Color", key = "Outline" })

	local profTween = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	local toggleOpen = false

	local function SetToggleOpen(open)
		toggleOpen = open

		if open then
			toggleClip.Visible = true
			profileToggle.Position = UDim2.new(0, 0, 1, 0)
			TweenService:Create(profileToggle, profTween, { Position = UDim2.new(0, 0, 0, 0) }):Play()
			TweenService:Create(profileChevron, profTween, { Rotation = 0 }):Play()
		else
			TweenService:Create(profileChevron, profTween, { Rotation = 180 }):Play()

			local tw = TweenService:Create(profileToggle, profTween, { Position = UDim2.new(0, 0, 1, 0) })
			tw:Play()
			tw.Completed:Connect(function()
				if not toggleOpen then toggleClip.Visible = false end
			end)
		end
	end

	local RealAvatar = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=100&h=100"
	local AnonAvatar = "rbxthumb://type=AvatarHeadShot&id=156&w=150&h=150"
	local RealName = LocalPlayer.Name
	local profileAnonymous = false
	local swapping = false

	local function SetAnonymous(anon)
		profileAnonymous = anon
		profileToggle.Text = anon and "Show Profile" or "Hide Profile"

		local fadeOut = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		local twA = TweenService:Create(avatar, fadeOut, { ImageTransparency = 1 })
		local twN = TweenService:Create(userLabel, fadeOut, { TextTransparency = 1 })
		twA:Play()
		twN:Play()
		twA.Completed:Wait()

		if anon then
			avatar.Image = AnonAvatar
			avatar.ImageColor3 = Color3.new(1, 1, 1)
			userLabel.Text = "Anonymous"
		else
			avatar.Image = RealAvatar
			avatar.ImageColor3 = Color3.new(1, 1, 1)
			userLabel.Text = RealName
		end

		local fadeIn = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		TweenService:Create(avatar, fadeIn, { ImageTransparency = 0 }):Play()
		TweenService:Create(userLabel, fadeIn, { TextTransparency = 0 }):Play()
	end

	cardBtn.Activated:Connect(function()
		SetToggleOpen(not toggleOpen)
	end)

	profileToggle.Activated:Connect(function()
		if swapping then return end
		swapping = true
		SetAnonymous(not profileAnonymous)
		swapping = false
	end)

	local TabContainer = Create("ScrollingFrame", {
		Name = "TabContainer", 
		Parent = Sidebar,
		Active = true, 
		BackgroundTransparency = 1, 
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 0), 
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0), 
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y, 
		ScrollBarThickness = 0,
		ScrollBarImageColor3 = Style.Primary,
		ZIndex = 50,
	})

	local ButtonsHolder = Create("Frame", {
		Name = "ButtonsHolder", 
		Parent = TabContainer,
		BackgroundTransparency = 1, 
		Size = UDim2.new(1, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 50,
	})
	Create("UIListLayout", { Parent = ButtonsHolder, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5) })
	Create("UIPadding", { 
		Parent = ButtonsHolder, 
		PaddingLeft = UDim.new(0, 7), 
		PaddingRight = UDim.new(0, 7),
		PaddingTop = UDim.new(0, 2)
	})

	local ContentContainer = Create("Frame", {
		Name = "ContentContainer", 
		Parent = MainFrame,
		BackgroundTransparency = 0, 
		BackgroundColor3 = Style.DarkBg,
		Position = UDim2.new(0, DS.SidebarW, 0, DS.HeaderH),
		Size = UDim2.new(1, -DS.SidebarW, 1, -DS.HeaderH),
		ClipsDescendants = true,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = ContentContainer })
	RegisterTheme({ object = ContentContainer, prop = "BackgroundColor3", key = "DarkBg"})

	local Window = {
		Tabs = {},
		TabButtons = {},
		TabContents = {},
		Elements = {},
		__tabChanged = Instance.new("BindableEvent"),
		__activeTabIndex = 1,
	}

	local NotifHolder = Create("Frame", {
		Name = "NotificationHolder", 
		Parent = ScreenGui,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -20, 1, -20),
		Size = UDim2.new(0, DS.NotifyW, 1, -20),
		AnchorPoint = Vector2.new(1, 1), 
		ZIndex = 100,
	})
	Create("UIScale", { Parent = NotifHolder, Scale = ResponsiveScale })
	Create("UIListLayout", {
		Parent = NotifHolder, 
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom, 
		Padding = UDim.new(0, 8),
	})

	-- ==========================================
	-- NOTIFY
	-- ==========================================
	function Window:Notify(opts)
		opts = opts or {}

		local notifTitle = opts.Title or "Notification"
		local content = opts.Content or "Message"
		local duration = opts.Duration or 3

		local wrapper = Create("Frame", {
			Name = "NotifyWrapper",
			Parent = NotifHolder,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(DS.NotifyW, DS.NotifyH),
			ClipsDescendants = false,
		})

		local frame = Create("Frame", {
			Name = "NotifyFrame",
			Parent = wrapper,
			BackgroundColor3 = Style.DarkBg,
			BackgroundTransparency = 0,
			Size = UDim2.fromOffset(DS.NotifyW, DS.NotifyH),
			Position = UDim2.new(0, DS.NotifyW + 50, 0, 0),
			ClipsDescendants = true,
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = frame })
		Create("UIStroke", { Color = Style.Primary, Transparency = 0.5, Thickness = 1.2, Parent = frame })

		Create("ImageLabel", {
			Parent = frame,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 10, 0.5, 0),
			Size = UDim2.fromOffset(DS.NotifyIcon, DS.NotifyIcon),
			Image = GetIcon("bell"), ImageColor3 = Style.Primary,
		})

		local textBox = Create("Frame", {
			Parent = frame,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, DS.NotifyIcon + 18, 0.5, 0),
			Size = UDim2.new(1, -(DS.NotifyIcon + 25), 1, 0),
		})

		Create("UIListLayout", {
			Parent = textBox,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 0),
		})

		Create("TextLabel", {
			Parent = textBox,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, DS.NotifyFontT + 2),
			FontFace = GetFont(Enum.FontWeight.Bold),
			Text = notifTitle,
			TextColor3 = Style.Text,
			TextSize = DS.NotifyFontT,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			LayoutOrder = 1,
		})

		Create("TextLabel", {
			Parent = textBox,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			FontFace = GetFont(Enum.FontWeight.Regular),
			Text = content,
			TextColor3 = Style.TextDim,
			TextSize = DS.NotifyFontC,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			LayoutOrder = 2,
		})

		local barClip = Create("Frame", {
			Parent = frame,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 6, 1, -3),
			Size = UDim2.new(1, -12, 0, 2),
			ClipsDescendants = true,
		})
		local bar = Create("Frame", {
			Parent = barClip,
			BackgroundColor3 = Style.Primary,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, 0),
		})

		TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0, 0) }):Play()
		TweenService:Create(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 1, 0) }):Play()

		task.delay(duration, function()
			local tw = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
				Position = UDim2.new(0, DS.NotifyW + 50, 0, 0),
			})

			tw:Play()

			tw.Completed:Wait()

			wrapper:Destroy()
		end)
	end

	-- ==========================================
	-- CONFIG API
	-- ==========================================
	local function ApplyConfigToUI()
		local keys = {}

		for key in pairs(Window.Elements) do 
			table.insert(keys, key) 
		end

		task.spawn(function()
			for _, key in ipairs(keys) do
				local data = Window.Elements[key]
				if data and ConfigData[key] ~= nil then
					pcall(function() data.Object:Set(ConfigData[key]) end)
				end
				task.wait(0.05)
			end
		end)
	end

	function Window:SaveConfig(name)
		if not name or name == "" then return false end

		local ok = SaveNamedConfig(name)

		if ok then
			self:Notify({ Title = "Config Saved", Content = name .. " saved" })
		else
			self:Notify({ Title = "Save Failed", Content = "Unable to save config" })
		end

		return ok
	end

	function Window:LoadConfig(name)
		if not name or name == "" then return false end

		local ok = LoadNamedConfig(name)

		if ok then
			ApplyConfigToUI()
			self:Notify({ Title = "Config Loaded", Content = name .. " loaded" })
		else
			self:Notify({ Title = "Load Failed", Content = "Config " .. name .. " not found" })
		end

		return ok
	end

	function Window:OverwriteConfig(name)
		if not name or name == "" then return false end

		local ok = SaveNamedConfig(name)

		if ok then
			self:Notify({ Title = "Config Overwritten", Content = name .. " overwrite" })
		else
			self:Notify({ Title = "Overwrite Failed", Content = "Cannot overwrite config" })
		end

		return ok
	end

	function Window:DeleteConfig(name)
		if not name or name == "" then return false end

		local ok = DeleteNamedConfig(name)

		if ok then
			self:Notify({ Title = "Config Deleted", Content = name .. " deleted" })
		else
			self:Notify({ Title = "Delete Failed", Content = "Config not found" })
		end

		return ok
	end

	function Window:ListConfigs() return ListConfigs() end

	-- ==========================================
	-- THEME API
	-- ==========================================
	function Window:ApplyTheme(themeName)
		ApplyTheme(themeName)

		self:Notify({ Title = "Theme Applied", Content = "Theme " .. themeName .. " activated" })
	end

	function Window:GetThemes() return ThemeOrder end
	function Window:GetCurrentTheme() return CurrentThemeName end

	-- ==========================================
	-- RIGHT PANEL (DROPDOWN)
	-- ==========================================
	local PanelWidth = DS.PanelW
	local PanelMargin = 10
	local HeaderHeight = DS.HeaderH

	local DropPanel = Create("Frame", {
		Name = "InternalDropdownPanel", 
		Parent = MainFrame,
		BackgroundTransparency = 0, 
		BackgroundColor3 = Style.SidebarBg,
		BorderSizePixel = 0, 
		Position = UDim2.new(1, 0, 0, HeaderHeight),
		Size = UDim2.new(0, PanelWidth, 1, -(HeaderHeight + PanelMargin * 2)),
		ZIndex = 50, 
		Visible = false, 
		ClipsDescendants = true,
	})
	Create("UIPadding", { Parent = DropPanel, PaddingBottom = UDim.new(0, 10) })
	Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = DropPanel })
	RegisterTheme({ object = DropPanel, prop = "BackgroundColor3", key = "SidebarBg" })

	local DropPanelStroke = Create("UIStroke", {
		Parent = DropPanel,
		Color = Style.Primary,
		Thickness = 1,
		Transparency = 0.35,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
	RegisterTheme({ object = DropPanelStroke, prop = "Color", key = "Primary" })

	local PanelHeader = Create("Frame", {
		Parent = DropPanel, 
		BackgroundColor3 = Style.DarkBg,
		BackgroundTransparency = 0, 
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, DS.DDHeader),
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = PanelHeader })
	RegisterTheme({ object = PanelHeader, prop = "BackgroundColor3", key = "DarkBg" })

	local PanelTitle = Create("TextLabel", {
		Parent = PanelHeader, 
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -DS.DDHeader, 1, 0), 
		Position = UDim2.new(0, 15, 0, 0),
		FontFace = GetFont(Enum.FontWeight.Bold), 
		TextColor3 = Style.Primary,
		TextSize = DS.FontBase, 
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	RegisterTheme({ object = PanelTitle, prop = "TextColor3", key = "Primary" })

	local PanelCloseSz = DS.IconSz + 2
	local PanelCloseBtn = Create("ImageButton", {
		Parent = PanelHeader,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -DS.Padding, 0.5, 0),
		Size = UDim2.new(0, PanelCloseSz, 0, PanelCloseSz),
		Image = GetIcon("x"),
		ImageColor3 = Style.TextDim, ZIndex = 51,
	})
	RegisterTheme({ object = PanelCloseBtn, prop = "ImageColor3", key = "TextDim" })

	local SearchBox = Create("TextBox", {
		Parent = DropPanel, 
		BackgroundColor3 = Style.InputBg,
		BackgroundTransparency = 0.5, 
		PlaceholderText = "Search...",
		Text = "", 
		PlaceholderColor3 = Style.TextDim, 
		TextColor3 = Style.Text,
		FontFace = GetFont(Enum.FontWeight.Medium), 
		TextSize = DS.FontBase - 1,
		Position = UDim2.new(0, DS.Padding, 0, DS.DDHeader + 5),
		Size = UDim2.new(1, -(DS.Padding * 2), 0, DS.InputH),
		ZIndex = 51, Visible = false,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = SearchBox })
	Create("UIPadding", { Parent = SearchBox, PaddingLeft = UDim.new(0, 8) })

	local MultiApplyBtn = Create("TextButton", {
		Parent = DropPanel, 
		BackgroundColor3 = Style.Primary,
		BackgroundTransparency = 0.1, 
		Position = UDim2.new(0, 10, 1, -24),
		Size = UDim2.new(1, -20, 0, 24), 
		FontFace = GetFont(Enum.FontWeight.Bold),
		Text = "Apply", 
		TextColor3 = Style.Text, 
		TextSize = DS.FontBase,
		ZIndex = 52, 
		Visible = false, 
		Active = true, 
		AutoButtonColor = false,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = MultiApplyBtn })
	RegisterTheme({ object = MultiApplyBtn, prop = "BackgroundColor3", key = "Primary" })
	RegisterTheme({ object = MultiApplyBtn, prop = "TextColor3", key = "Text" })

	local PanelList = Create("ScrollingFrame", {
		Parent = DropPanel, 
		BackgroundTransparency = 1, 
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 45), 
		Size = UDim2.new(1, 0, 1, -45),
		CanvasSize = UDim2.new(0, 0, 0, 0), 
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y, 
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Style.Primary, 
		ZIndex = 51,
	})
	Create("UIListLayout", { Parent = PanelList, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) })
	Create("UIPadding", { Parent = PanelList, PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
	RegisterTheme({ object = PanelList, prop = "ScrollBarImageColor3", key = "Primary" })

	local IsPanelOpen = false
	local CurrentPanelCallback = nil
	local PanelIsMulti = false
	local PanelMultiSelected = {}
	local SelectTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

	local DDIndicatorW = DS.DDInd
	local DDIndicatorGap = DS.DDIndGap
	local DDCheckSz = math.max(5, DDIndicatorW - 4)

	local function CloseDropPanel()
		if not IsPanelOpen then return end

		IsPanelOpen = false
		TweenService:Create(DropPanel, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
			Position = UDim2.new(1, 0, 0, HeaderHeight + PanelMargin),
		}):Play()
		task.wait(0.3)

		DropPanel.Visible = false
		SearchBox.Text = ""
		PanelIsMulti = false

		table.clear(PanelMultiSelected)
	end

	PanelCloseBtn.Activated:Connect(CloseDropPanel)

	UserInputService.InputBegan:Connect(function(input, gp)
		if not gp and IsPanelOpen then
			if input.UserInputType == Enum.UserInputType.MouseButton1 
				or input.UserInputType == Enum.UserInputType.Touch then
				local mp = input.Position
				local pa = DropPanel.AbsolutePosition
				local ps = DropPanel.AbsoluteSize
				if mp.X < pa.X or mp.X > pa.X + ps.X or mp.Y < pa.Y or mp.Y > pa.Y + ps.Y then
					if PanelIsMulti and CurrentPanelCallback then
						CurrentPanelCallback(PanelMultiSelected)
					end
					CloseDropPanel()
				end
			end
		end
	end)

	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local q = SearchBox.Text:lower()
		for _, child in pairs(PanelList:GetChildren()) do
			if child:IsA("Frame") then
				local lbl = child:FindFirstChildWhichIsA("TextLabel")
				if lbl then child.Visible = string.find(lbl.Text:lower(), q, 1, true) ~= nil end
			elseif child:IsA("TextButton") then
				child.Visible = string.find(child.Text:lower(), q, 1, true) ~= nil
			end
		end
	end)

	MultiApplyBtn.Activated:Connect(function()
		if PanelIsMulti and CurrentPanelCallback then
			CurrentPanelCallback(PanelMultiSelected)
		end
		CloseDropPanel()
	end)

	local function OpenPanel()
		if IsPanelOpen then return end
		IsPanelOpen = true
		DropPanel.Visible = true
		DropPanel.Position = UDim2.new(1, 0, 0, HeaderHeight)
		TweenService:Create(DropPanel, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, -(PanelWidth + PanelMargin), 0, HeaderHeight + PanelMargin),
		}):Play()
	end

	function Window:OpenRightDropdown(ddTitle, items, default, callback, searchEnabled)
		for _, child in pairs(PanelList:GetChildren()) do
			if child:IsA("TextButton") or child:IsA("Frame") then
				child:Destroy()
			end
		end

		PanelTitle.Text = ddTitle or "Select"
		CurrentPanelCallback = callback
		PanelIsMulti = false
		MultiApplyBtn.Visible = false
		SearchBox.Visible = searchEnabled or false
		SearchBox.Text = ""

		local listTop = searchEnabled and (DS.DDHeader + DS.InputH + DS.Padding * 2) or DS.DDHeader

		PanelList.Position = UDim2.new(0, 0, 0, listTop)
		PanelList.Size = UDim2.new(1, 0, 1, -(listTop + 14))

		local IndicatorW = DDIndicatorW
		local IndicatorGap = DDIndicatorGap
		local labelRestX = DS.Padding
		local labelSelX = DS.Padding + IndicatorW + IndicatorGap

		local currentSingle = default
		local rows = {}

		local function SetRowSelected(data, selected, animate)
			local tw = animate and SelectTweenInfo or TweenInfo.new(0)
			TweenService:Create(data.Row, tw, {
				BackgroundColor3 = selected and Style.Primary or Style.ElementBackground,
				BackgroundTransparency = selected and 0.2 or 0.5,
			}):Play()
			TweenService:Create(data.Label, tw, {
				Position = UDim2.new(0, selected and labelSelX or labelRestX, 0, 0),
			}):Play()
			TweenService:Create(data.Indicator, tw, {
				BackgroundTransparency = selected and 0 or 1,
				Size = selected and UDim2.new(0, IndicatorW, 0, IndicatorW) or UDim2.new(0, 0, 0, IndicatorW),
			}):Play()
			TweenService:Create(data.Check, tw, {
				ImageTransparency = selected and 0 or 1,
			}):Play()
		end

		for _, item in pairs(items) do
			local selected = (item == default)

			local row = Create("Frame", {
				Name = item,
				Parent = PanelList,
				BackgroundColor3 = selected and Style.Primary or Style.ElementBackground,
				BackgroundTransparency = selected and 0.2 or 0.5,
				Size = UDim2.new(1, 0, 0, DS.TabBtnH - 8),
				ZIndex = 52,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = row })

			local indicator = Create("Frame", {
				Name = "SelectedIndicator",
				Parent = row,
				BackgroundColor3 = Style.Primary,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, DS.Padding, 0.5, 0),
				Size = selected and UDim2.new(0, IndicatorW, 0, IndicatorW) or UDim2.new(0, 0, 0, IndicatorW),
				BackgroundTransparency = selected and 0 or 1,
				ClipsDescendants = true,
				ZIndex = 53,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = indicator })
			RegisterTheme({ object = indicator, prop = "BackgroundColor3", key = "Primary" })

			local check = Create("ImageLabel", {
				Name = "CheckIcon",
				Parent = indicator,
				BackgroundTransparency = 1,
				Size = UDim2.new(0, DDCheckSz, 0, DDCheckSz),
				Position = UDim2.new(0, IndicatorW / 2, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = GetIcon("check"),
				ImageColor3 = Style.Text,
				ImageTransparency = selected and 0 or 1,
				ZIndex = 54,
			})

			local lbl = Create("TextLabel", {
				Name = "ItemLabel",
				Parent = row,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, selected and labelSelX or labelRestX, 0, 0),
				Size = UDim2.new(1, -(labelSelX + DS.Padding), 1, 0),
				FontFace = GetFont(Enum.FontWeight.Medium),
				Text = item,
				TextColor3 = Style.Text,
				TextSize = DS.FontBase - 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 53,
			})

			local rowBtn = Create("TextButton", {
				Parent = row,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Text = "",
				ZIndex = 55,
				Active = true,
			})

			local data = { Row = row, Label = lbl, Indicator = indicator, Check = check }
			rows[item] = data

			rowBtn.Activated:Connect(function()
				if currentSingle == item then return end
				if rows[currentSingle] then SetRowSelected(rows[currentSingle], false, true) end
				currentSingle = item
				SetRowSelected(data, true, true)
				if CurrentPanelCallback then CurrentPanelCallback({ item }) end
			end)

			row.MouseEnter:Connect(function()
				if currentSingle ~= item then
					TweenService:Create(row, SelectTweenInfo, { BackgroundColor3 = Style.Hover }):Play()
				end
			end)

			row.MouseLeave:Connect(function()
				if currentSingle ~= item then
					TweenService:Create(row, SelectTweenInfo, { BackgroundColor3 = Style.ElementBackground }):Play()
				end
			end)
		end
		OpenPanel()
	end

	function Window:OpenRightDropdownMulti(ddTitle, items, currentSel, callback, searchEnabled)
		for _, child in pairs(PanelList:GetChildren()) do
			if child:IsA("TextButton") or child:IsA("Frame") then
				child:Destroy()
			end
		end

		PanelTitle.Text = ddTitle or "Select"
		CurrentPanelCallback = callback
		PanelIsMulti = true
		MultiApplyBtn.Visible = true

		table.clear(PanelMultiSelected)

		for _, v in pairs(currentSel or {}) do table.insert(PanelMultiSelected, v) end

		SearchBox.Visible = searchEnabled or false
		SearchBox.Text = ""

		local listTop = searchEnabled and (DS.DDHeader + DS.InputH + DS.Padding * 2) or DS.DDHeader

		PanelList.Position = UDim2.new(0, 0, 0, listTop)
		PanelList.Size = UDim2.new(1, 0, 1, -(listTop + 40))

		local IndicatorW = DDIndicatorW
		local IndicatorGap = DDIndicatorGap
		local labelRestX = DS.Padding
		local labelSelX = DS.Padding + IndicatorW + IndicatorGap

		local function RefreshRows()
			for _, row in pairs(PanelList:GetChildren()) do
				if row:IsA("Frame") then
					local checked = table.find(PanelMultiSelected, row.Name) ~= nil

					local indicator = row:FindFirstChild("SelectedIndicator")
					local check = indicator and indicator:FindFirstChild("CheckIcon")
					local lbl = row:FindFirstChild("ItemLabel")

					TweenService:Create(row, SelectTweenInfo, {
						BackgroundColor3 = checked and Style.Primary or Style.ElementBackground,
						BackgroundTransparency = checked and 0.2 or 0.5,
					}):Play()

					if indicator then
						TweenService:Create(indicator, SelectTweenInfo, {
							BackgroundTransparency = checked and 0 or 1,
							Size = checked and UDim2.new(0, IndicatorW, 0, IndicatorW) or UDim2.new(0, 0, 0, IndicatorW),
						}):Play()
					end

					if check then
						TweenService:Create(check, SelectTweenInfo, { ImageTransparency = checked and 0 or 1 }):Play()
					end

					if lbl then
						TweenService:Create(lbl, SelectTweenInfo, {
							Position = UDim2.new(0, checked and labelSelX or labelRestX, 0, 0),
						}):Play()
					end
				end
			end
		end

		for _, item in pairs(items) do
			local checked = table.find(PanelMultiSelected, item) ~= nil

			local row = Create("Frame", {
				Name = item,
				Parent = PanelList,
				BackgroundColor3 = checked and Style.Primary or Style.ElementBackground,
				BackgroundTransparency = checked and 0.2 or 0.5,
				Size = UDim2.new(1, 0, 0, DS.TabBtnH - 8),
				ZIndex = 52,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = row })

			local indicator = Create("Frame", {
				Name = "SelectedIndicator",
				Parent = row,
				BackgroundColor3 = Style.Primary,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, DS.Padding, 0.5, 0),
				Size = checked and UDim2.new(0, IndicatorW, 0, IndicatorW) or UDim2.new(0, 0, 0, IndicatorW),
				BackgroundTransparency = checked and 0 or 1,
				ClipsDescendants = true,
				ZIndex = 53,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = indicator })
			RegisterTheme({ object = indicator, prop = "BackgroundColor3", key = "Primary" })

			Create("ImageLabel", {
				Name = "CheckIcon",
				Parent = indicator,
				BackgroundTransparency = 1,
				Size = UDim2.new(0, DDCheckSz, 0, DDCheckSz),
				Position = UDim2.new(0, IndicatorW / 2, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Image = GetIcon("check"),
				ImageColor3 = Style.Text,
				ImageTransparency = checked and 0 or 1,
				ZIndex = 54,
			})

			local lbl = Create("TextLabel", {
				Name = "ItemLabel",
				Parent = row,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, checked and labelSelX or labelRestX, 0, 0),
				Size = UDim2.new(1, -(labelSelX + DS.Padding), 1, 0),
				FontFace = GetFont(Enum.FontWeight.Medium),
				Text = item,
				TextColor3 = Style.Text,
				TextSize = DS.FontBase - 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 53,
			})

			local rowBtn = Create("TextButton", {
				Parent = row,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Text = "",
				ZIndex = 55,
				Active = true,
			})

			rowBtn.Activated:Connect(function()
				local idx = table.find(PanelMultiSelected, item)
				if idx then table.remove(PanelMultiSelected, idx) else table.insert(PanelMultiSelected, item) end
				RefreshRows()
			end)

			row.MouseEnter:Connect(function()
				if not table.find(PanelMultiSelected, item) then
					TweenService:Create(row, SelectTweenInfo, { BackgroundColor3 = Style.Hover }):Play()
				end
			end)

			row.MouseLeave:Connect(function()
				if not table.find(PanelMultiSelected, item) then
					TweenService:Create(row, SelectTweenInfo, { BackgroundColor3 = Style.ElementBackground }):Play()
				end
			end)
		end

		OpenPanel()
	end

	-- ==========================================
	-- TAB
	-- ==========================================
	function Window:AddTab(tabProps)
		tabProps = tabProps or {}

		local tabTitle = tabProps.Title or "Tab"
		local tabIcon = tabProps.Icon
		local index = #self.Tabs + 1
		self.Tabs[index] = tabProps

		local Components = {}
		local ElementIndex = 0
		local CurrentGroup
		local LastElementType = nil
		local BG_TW = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

		local tabBtn = Create("ImageButton", {
			Name = "TabBtn_" .. index, 
			Size = UDim2.new(1, 0, 0, DS.TabBtnH),
			BackgroundColor3 = Style.Primary,
			BackgroundTransparency = 1,
			AutoButtonColor = false, 
			Active = true, 
			Parent = ButtonsHolder,
		})
		self.TabButtons[index] = tabBtn
		Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = tabBtn })

		local tabStroke = Create("UIStroke", {
			Name = "ActiveStroke",
			Color = Style.Primary,
			Thickness = 1.2,
			Transparency = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
			Parent = tabBtn,
		})
		RegisterTheme({ object = tabStroke, prop = "Color", key = "Primary" })
		RegisterTheme({ object = tabBtn, prop = "BackgroundColor3", key = "Primary" })

		local tabIconSz = math.floor(DS.TabBtnH * 0.5)

		if tabIcon then
			Create("ImageLabel", {
				Size = UDim2.fromOffset(tabIconSz, tabIconSz),
				Position = UDim2.new(0, DS.Padding + 4, 0.5, -tabIconSz / 2),
				BackgroundTransparency = 1, 
				Image = GetIcon(tabIcon) or "",
				Parent = tabBtn,
			})
		end

		local tabLabelOffset = (tabIcon and (DS.Padding + tabIconSz + 8)) or DS.Padding
		local tabLabel = Create("TextLabel", {
			Text = tabTitle,
			Size = UDim2.new(1, -(tabLabelOffset + DS.Padding), 1, 0),
			Position = UDim2.new(0, tabLabelOffset, 0, 0),
			BackgroundTransparency = 1, 
			TextColor3 = Style.Text,
			FontFace = GetFont(Enum.FontWeight.Medium), 
			TextSize = DS.TabFontSz,
			TextXAlignment = Enum.TextXAlignment.Left, 
			TextYAlignment = Enum.TextYAlignment.Center, 
			Parent = tabBtn,
		})
		RegisterTheme({ object = tabLabel, prop = "TextColor3", key = "Text" })

		local tabContent = Create("ScrollingFrame", {
			Name = "TabContent_" .. index, 
			Size = UDim2.new(1, 0, 1, 0),
			CanvasSize = UDim2.new(0, 0, 0, 0), 
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 1.7, 
			ScrollBarImageColor3 = Style.Primary,
			ScrollingDirection = Enum.ScrollingDirection.Y, 
			BackgroundTransparency = 1,
			Visible = (index == 1), 
			Parent = ContentContainer,
		})
		self.TabContents[index] = tabContent
		RegisterTheme({ object = tabContent, prop = "ScrollBarImageColor3", key = "Primary" })

		Create("UIListLayout", { Parent = tabContent, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) })
		Create("UIPadding", {
			PaddingTop = UDim.new(0, 2),
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 4),
			Parent = tabContent,
		})

		local function AddDivider()
			if not CurrentGroup then return end

			local d = Create("Frame", {
				Parent = CurrentGroup, 
				BackgroundColor3 = Style.Outline,
				BackgroundTransparency = 0.3, 
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 1.5), 
				LayoutOrder = ElementIndex,
			})
		end

		local TabStateTween = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

		local function ActivateTab()
			Window.__tabChanged:Fire()
			Window.__activeTabIndex = index

			for i, c in ipairs(self.TabContents) do
				c.Visible = (i == index)
			end

			for i, btn in ipairs(self.TabButtons) do
				local isActive = (i == index)
				local stroke = btn:FindFirstChild("ActiveStroke")

				TweenService:Create(btn, TabStateTween, {
					BackgroundTransparency = isActive and 0.75 or 1,
				}):Play()

				if stroke then
					TweenService:Create(stroke, TabStateTween, {
						Transparency = isActive and 0 or 1,
					}):Play()
				end
			end
		end

		tabBtn.Activated:Connect(ActivateTab)
		if index == 1 then task.wait() ; ActivateTab() end

		-- ==========================================
		-- SECTION
		-- ==========================================
		function Components:AddSection(props)
			props = props or {}

			local secTitle = props.Title or "Section"
			local icon = props.Icon

			ElementIndex = ElementIndex + 1

			local outer = Create("Frame", {
				Name = "Section_" .. secTitle, 
				Parent = tabContent,
				BackgroundColor3 = Style.Primary,
				BackgroundTransparency = 0,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y, 
				LayoutOrder = ElementIndex,
			})
			local outerStroke = Create("UIStroke", {
				Color = Style.Primary, 
				Thickness = 1.5,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border, 
				Parent = outer,
			})
			RegisterTheme({ object = outerStroke, prop = "Color", key = "Primary" })
			RegisterTheme({ object = outer, prop = "BackgroundColor3", key = "Primary" })
			Create("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.85),
					NumberSequenceKeypoint.new(1, 1),
				}),
				Rotation = 270,
				Parent = outer,
			})
			Create("UIListLayout", { Parent = outer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0) })
			Create("UIPadding", {
				Parent = outer,
				PaddingTop = UDim.new(0, 3),
				PaddingBottom = UDim.new(0, 3),
				PaddingLeft = UDim.new(0, 0),
				PaddingRight = UDim.new(0, 0),
			})

			local sectionHeader = Create("Frame", {
				Name = "SectionHeader", 
				Parent = outer,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, DS.SectionHeaderH), 
				LayoutOrder = 1,
			})

			local headerBtn = Create("TextButton", {
				Parent = sectionHeader, 
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1, 
				Text = "", 
				ZIndex = 5,
			})

			local chevronSz = DS.IconSz
			local chevron = Create("ImageLabel", {
				Parent = sectionHeader, 
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -(DS.Padding + chevronSz), 0.5, -chevronSz / 2), 
				Size = UDim2.new(0, chevronSz, 0, chevronSz),
				Image = GetIcon("chevron-down"), 
				ImageColor3 = Style.Primary,
				Rotation = -90,
			})
			RegisterTheme({ object = chevron, prop = "ImageColor3", key = "Primary" })

			local cx = DS.Padding
			if icon then
				local ico = Create("ImageLabel", {
					Parent = sectionHeader, 
					BackgroundTransparency = 1,
					Position = UDim2.new(0, cx, 0.5, -DS.IconSz / 2), Size = UDim2.new(0, DS.IconSz, 0, DS.IconSz),
					Image = GetIcon(icon), 
					ImageColor3 = Style.Primary,
				})
				RegisterTheme({ object = ico, prop = "ImageColor3", key = "Primary" })
				cx = cx + DS.IconSz + DS.Padding
			end

			local secTitleLabel = Create("TextLabel", {
				Parent = sectionHeader, 
				BackgroundTransparency = 1,
				Position = UDim2.new(0, cx, 0, 0), 
				Size = UDim2.new(1, -(cx + DS.Padding + chevronSz + DS.Padding), 1, 0),
				FontFace = GetFont(Enum.FontWeight.Bold), 
				Text = secTitle,
				TextColor3 = Style.Text, 
				TextSize = DS.FontBase,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			RegisterTheme({ object = secTitleLabel, prop = "TextColor3", key = "Text" })

			local clip = Create("Frame", {
				Name = "ContentClip", 
				Parent = outer,
				BackgroundTransparency = 1, 
				Size = UDim2.new(1, 0, 0, 0),
				ClipsDescendants = true, 
				LayoutOrder = 2,
			})

			local sectionGroup = Create("Frame", {
				Name = "InnerContent", 
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y, 
				BackgroundTransparency = 1,
				Parent = clip,
			})

			Create("UIListLayout", { Parent = sectionGroup, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) })
			Create("UIPadding", {
				Parent = sectionGroup,
				PaddingTop = UDim.new(0, 6), 
				PaddingBottom = UDim.new(0, 6),
				PaddingLeft = UDim.new(0, 1), 
				PaddingRight = UDim.new(0, 1),
			})

			CurrentGroup = sectionGroup

			local collapsed = true
			local isTweening = false

			local function UpdateClipSize()
				if not collapsed and not isTweening then
					clip.Size = UDim2.new(1, 0, 0, sectionGroup.AbsoluteSize.Y / WindowScale.Scale)
				end
			end
			sectionGroup:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateClipSize)

			headerBtn.Activated:Connect(function()
				collapsed = not collapsed
				local target = collapsed and UDim2.new(1, 0, 0, 0) or UDim2.new(1, 0, 0, sectionGroup.AbsoluteSize.Y / WindowScale.Scale)

				isTweening = true

				TweenService:Create(chevron, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Rotation = collapsed and -90 or 0 }):Play()

				local tw = TweenService:Create(clip, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = target })

				tw:Play()

				tw.Completed:Connect(function()
					isTweening = false
					if not collapsed then
						clip.Size = UDim2.new(1, 0, 0, sectionGroup.AbsoluteSize.Y / WindowScale.Scale)
					end
				end)
			end)

			LastElementType = "Section"

			local SectionObj = { Frame = outer }

			function SectionObj:SetTitle(t) 
				secTitleLabel.Text = t 
			end

			return SectionObj
		end

		-- ==========================================
		-- PARAGRAPH
		-- ==========================================
		function Components:AddParagraph(props)
			props = props or {}

			if LastElementType == "Component" then 
				AddDivider() 
			end

			ElementIndex = ElementIndex + 1

			local frame = Create("Frame", {
				Name = "ParagraphFrame", 
				Parent = CurrentGroup,
				BackgroundTransparency = 1, 
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 0), 
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = ElementIndex,
			})
			local padding = Create("UIPadding", {
				PaddingTop = UDim.new(0, 10), 
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 12), 
				PaddingRight = UDim.new(0, 12),
				Parent = frame,
			})

			local titleLbl = nil
			if (props.Title or "") ~= "" then
				titleLbl = Create("TextLabel", {
					Parent = frame, 
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 20), 
					FontFace = GetFont(Enum.FontWeight.SemiBold),
					Text = props.Title, 
					TextColor3 = Style.Text, 
					TextSize = DS.FontTitle,
					TextXAlignment = Enum.TextXAlignment.Left, 
					TextYAlignment = Enum.TextYAlignment.Top,
				})
			end

			local bodyLbl = Create("TextLabel", {
				Size = UDim2.new(1, 0, 0, 0), 
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1, 
				TextWrapped = true, 
				RichText = true,
				TextYAlignment = Enum.TextYAlignment.Top, 
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = props.Color or Style.Text, 
				FontFace = GetFont(Enum.FontWeight.Medium),
				TextSize = props.TextSize or DS.FontBase,
				Text = props.Text or "Paragraph text goes here...", 
				Parent = frame,
			})
			RegisterTheme({ object = bodyLbl, prop = "TextColor3", key = "Text" })

			if titleLbl then
				Create("UIListLayout", { Parent = frame, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder })
				titleLbl.LayoutOrder = 1
				bodyLbl.LayoutOrder = 2
				padding:Destroy()

				Create("UIPadding", {
					PaddingTop = UDim.new(0, 10), 
					PaddingBottom = UDim.new(0, 10),
					PaddingLeft = UDim.new(0, 12), 
					PaddingRight = UDim.new(0, 12), 
					Parent = frame,
				})
			end

			LastElementType = "Component"

			local Obj = { Frame = frame }

			function Obj:SetTitle(t)
				if titleLbl then 
					titleLbl.Text = t 
				end
			end

			function Obj:SetText(t) 
				bodyLbl.Text = t 
			end
			function Obj:SetColor(c) 
				bodyLbl.TextColor3 = c 
			end

			return Obj
		end

		-- ==========================================
		-- BUTTON
		-- ==========================================
		function Components:AddButton(props)
			props = props or {}

			if LastElementType == "Component" then 
				AddDivider() 
			end

			ElementIndex = ElementIndex + 1

			local frameH = props.Desc and DS.CompHDesc or DS.CompH
			local callback = props.Callback or function() end

			local btnFrame = Create("Frame", {
				Name = "ButtonFrame", 
				Parent = CurrentGroup,
				BackgroundTransparency = 1, 
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, frameH), 
				LayoutOrder = ElementIndex, 
				Active = true,
			})

			local icon = Create("ImageLabel", {
				BackgroundTransparency = 1, 
				Image = GetIcon("mouse-pointer-2"),
				Position = UDim2.new(1, -32, 0.5, 0), 
				AnchorPoint = Vector2.new(0, 0.5),
				ImageColor3 = Style.Primary, 
				Size = UDim2.fromOffset(DS.FontBase + 4, DS.FontBase + 4),
				ScaleType = Enum.ScaleType.Fit, 
				Parent = btnFrame,
			})
			RegisterTheme({ object = icon, prop = "ImageColor3", key = "Primary" })

			local titleLbl = Create("TextLabel", {
				Text = props.Title or "Button",
				Size = UDim2.new(0.5, -12, props.Desc and 0 or 1, 0),
				Position = props.Desc and UDim2.new(0, DS.Padding, 0, 6) or UDim2.new(0, DS.Padding, 0.5, 0),
				AnchorPoint = props.Desc and Vector2.new(0, 0) or Vector2.new(0, 0.5),
				BackgroundTransparency = 1, 
				FontFace = GetFont(Enum.FontWeight.SemiBold),
				TextSize = DS.FontTitle, 
				TextColor3 = Style.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = props.Desc and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
				Parent = btnFrame,
			})

			local descLbl = nil
			if props.Desc then
				descLbl = Create("TextLabel", {
					Text = props.Desc, 
					Size = UDim2.new(0.5, -12, 0, 20),
					Position = UDim2.new(0, DS.Padding, 0, DS.FontTitle + 6),
					AnchorPoint = Vector2.new(0, 0), 
					BackgroundTransparency = 1,
					FontFace = GetFont(Enum.FontWeight.Regular), 
					TextSize = DS.FontDesc,
					TextColor3 = Style.TextDim, 
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = false, 
					Parent = btnFrame,
				})
				RegisterTheme({ object = descLbl, prop = "TextColor3", key = "TextDim" })
			end

			local clickBtn = Create("TextButton", {
				Parent = btnFrame, 
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0), 
				Text = "", 
				ZIndex = 10, 
				Active = true,
			})
			clickBtn.Activated:Connect(function()
				if typeof(callback) == "function" then callback() end
			end)

			LastElementType = "Component"

			local Obj = { Frame = btnFrame }

			function Obj:SetTitle(t) 
				titleLbl.Text = t 
			end

			function Obj:SetDesc(t)
				if descLbl then 
					descLbl.Text = t 
				end
			end

			function Obj:SetCallback(fn) 
				callback = fn 
			end

			return Obj
		end

		-- ==========================================
		-- INPUT
		-- ==========================================
		function Components:AddInput(configKey, props)
			if type(configKey) == "table" then 
				props = configKey
				configKey = nil 
			end

			props = props or {}

			local cfgKey = configKey
			local default = props.Default or ""

			if cfgKey and ConfigData[cfgKey] ~= nil then 
				default = ConfigData[cfgKey] 
			end

			if LastElementType == "Component" then 
				AddDivider() 
			end

			ElementIndex = ElementIndex + 1

			local frameH = props.Desc and DS.CompHDesc or DS.CompH
			local inputFrame = Create("Frame", {
				Name = "InputFrame", 
				Parent = CurrentGroup,
				BackgroundTransparency = 1, 
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, frameH), 
				LayoutOrder = ElementIndex,
			})

			local titleLbl = Create("TextLabel", {
				Parent = inputFrame, 
				BackgroundTransparency = 1,
				Position = props.Desc and UDim2.new(0, DS.Padding, 0, 6) or UDim2.new(0, DS.Padding, 0.5, 0),
				AnchorPoint = props.Desc and Vector2.new(0, 0) or Vector2.new(0, 0.5),
				Size = UDim2.new(0.5, -12, 
					props.Desc and 0 or 1, 0),
				FontFace = GetFont(Enum.FontWeight.SemiBold), 
				Text = props.Title or "Input",
				TextColor3 = Style.Text, 
				TextSize = DS.FontTitle,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = props.Desc and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
			})

			if props.Desc then
				local desc = Create("TextLabel", {
					Text = props.Desc, 
					Size = UDim2.new(0.5, -12, 0, 20),
					Position = UDim2.new(0, DS.Padding, 0, DS.FontTitle + 6),
					AnchorPoint = Vector2.new(0, 0), 
					BackgroundTransparency = 1,
					FontFace = GetFont(Enum.FontWeight.Regular), 
					TextSize = DS.FontDesc,
					TextColor3 = Style.TextDim, 
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true, 
					Parent = inputFrame,
				})
				RegisterTheme({ object = desc, prop = "TextColor3", key = "TextDim" })
			end

			local boxFrame = Create("Frame", {
				Size = UDim2.new(0.5, -DS.Padding, 0, DS.InputH),
				Position = UDim2.new(0.5, DS.Padding / 2, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5), 
				BackgroundColor3 = Style.InputBg,
				BackgroundTransparency = 0.5, 
				ClipsDescendants = true, 
				Parent = inputFrame,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = boxFrame })

			local stroke = Create("UIStroke", { 
				Color = Style.InputStroke, 
				Transparency = 0.15, 
				Thickness = 1.4, 
				Parent = boxFrame 
			})
			RegisterTheme({ object = boxFrame, prop = "BackgroundColor3", key = "InputBg" })
			RegisterTheme({ object = stroke, prop = "Color", key = "InputStroke" })

			local textBox = Create("TextBox", {
				Position = UDim2.new(0, 8, 0, 0), 
				Size = UDim2.new(1, -16, 1, 0),
				BackgroundTransparency = 1, 
				PlaceholderText = props.Placeholder or "Value..",
				Text = tostring(default), 
				ClearTextOnFocus = false,
				FontFace = GetFont(Enum.FontWeight.Medium), 
				TextSize = DS.FontBase,
				TextColor3 = Style.Text, 
				PlaceholderColor3 = Style.TextDim,
				TextXAlignment = Enum.TextXAlignment.Left,
				ClipsDescendants = true, 
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = boxFrame,
			})
			RegisterTheme({ object = textBox, prop = "TextColor3", key = "Text" })
			RegisterTheme({ object = textBox, prop = "PlaceholderColor3", key = "TextDim" })

			local inputCallback = props.Callback or function() end
			local InputObj = { Frame = inputFrame, Value = tostring(default) }

			local function setValue(v, silent)
				v = tostring(v or "")
				textBox.Text = v
				InputObj.Value = v
				if not silent and typeof(inputCallback) == "function" then inputCallback(v) end
			end

			textBox.FocusLost:Connect(function()
				if cfgKey then ConfigData[cfgKey] = textBox.Text end
				setValue(textBox.Text)
			end)

			textBox:GetPropertyChangedSignal("Text"):Connect(function()
				InputObj.Value = textBox.Text
			end)

			LastElementType = "Component"

			function InputObj:Set(v) 
				setValue(v, true) 
			end

			function InputObj:SetValue(v) 
				setValue(v, true) 
			end

			function InputObj:GetValue() 
				return textBox.Text 
			end

			function InputObj:SetTitle(t) 
				titleLbl.Text = t 
			end

			function InputObj:SetPlaceholder(t) 
				textBox.PlaceholderText = t 
			end

			function InputObj:SetCallback(fn) 
				inputCallback = fn 
			end

			if cfgKey then 
				Window.Elements[cfgKey] = { Object = InputObj, Type = "Input" } 
			end

			return InputObj
		end

		-- ==========================================
		-- SLIDER
		-- ==========================================
		function Components:AddSlider(configKey, props)
			if type(configKey) == "table" then 
				props = configKey
				configKey = nil 
			end

			props = props or {}

			local cfgKey = configKey
			local min = props.Min or 0
			local max = props.Max or 100
			local default = props.Default or min

			if cfgKey and ConfigData[cfgKey] ~= nil then
				default = tonumber(ConfigData[cfgKey]) or default
			end

			if LastElementType == "Component" then 
				AddDivider() 
			end

			ElementIndex = ElementIndex + 1

			local sliderFrame = Create("Frame", {
				Name = "SliderFrame", 
				Parent = CurrentGroup,
				BackgroundTransparency = 1, 
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, DS.SliderH), 
				LayoutOrder = ElementIndex,
			})

			local titleLbl = Create("TextLabel", {
				Parent = sliderFrame, 
				BackgroundTransparency = 1,
				Position = UDim2.new(0, DS.Padding, 0, 6), 
				Size = UDim2.new(1, -(DS.Padding * 2 + 54), 0, 20),
				FontFace = GetFont(Enum.FontWeight.SemiBold), 
				Text = props.Title or "Slider",
				TextColor3 = Style.Text, 
				TextSize = DS.FontTitle,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextTruncate = Enum.TextTruncate.AtEnd,
			})

			local valueLbl = Create("TextLabel", {
				Parent = sliderFrame, 
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 50, 0, DS.FontTitle),
				Position = UDim2.new(1, -DS.Padding, 0, DS.Padding),
				AnchorPoint = Vector2.new(1, 0), 
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = tostring(math.floor(default)), 
				TextColor3 = Style.Text,
				FontFace = GetFont(Enum.FontWeight.Bold), 
				TextSize = DS.FontTitle,
			})
			RegisterTheme({ object = valueLbl, prop = "TextColor3", key = "Text" })

			local sliderBg = Create("Frame", {
				Parent = sliderFrame, 
				BackgroundColor3 = Style.InputBg,
				BackgroundTransparency = 0.5, 
				BorderSizePixel = 0,
				Position = UDim2.new(0, DS.Padding, 1, -12),
				Size = UDim2.new(1, -(DS.Padding * 2), 0, 4), 
				AnchorPoint = Vector2.new(0, 1),
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = sliderBg })
			RegisterTheme({ object = sliderBg, prop = "BackgroundColor3", key = "InputBg" })

			local fill = Create("Frame", {
				Parent = sliderBg, 
				BackgroundColor3 = Style.Primary, 
				BorderSizePixel = 0,
				Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
			RegisterTheme({ object = fill, prop = "BackgroundColor3", key = "Primary" })

			local knob = Create("Frame", {
				Parent = sliderBg, 
				BackgroundColor3 = Color3.new(1, 1, 1), 
				BorderSizePixel = 0,
				Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0),
				Size = UDim2.new(0, 14, 0, 14), 
				AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 2,
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

			local inputBtn = Create("TextButton", {
				Parent = sliderBg, 
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(1, 0, 0, 26),
				Text = "", ZIndex = 3,
				Active = true,
			})

			local dragging = false
			local sliderCallback = props.Callback or function() end
			local SliderObj = { Value = default }
			local knobTween = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

			local function updateSlider(value, silent)
				value = math.clamp(value, min, max)

				local p = (value - min) / (max - min)
				fill.Size = UDim2.new(p, 0, 1, 0)
				knob.Position = UDim2.new(p, 0, 0.5, 0)
				valueLbl.Text = tostring(math.floor(value))
				SliderObj.Value = value

				if not silent then
					if cfgKey then ConfigData[cfgKey] = value end
					sliderCallback(value)
				end
			end

			inputBtn.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					TweenService:Create(knob, knobTween, { Size = UDim2.new(0, 18, 0, 18) }):Play()
					local p = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
					updateSlider(min + (max - min) * p)
				end
			end)

			inputBtn.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
					TweenService:Create(knob, knobTween, { Size = UDim2.new(0, 14, 0, 14) }):Play()
				end
			end)

			inputBtn.MouseEnter:Connect(function()
				if not dragging then
					TweenService:Create(knob, knobTween, { Size = UDim2.new(0, 16, 0, 16) }):Play()
				end
			end)

			inputBtn.MouseLeave:Connect(function()
				if not dragging then
					TweenService:Create(knob, knobTween, { Size = UDim2.new(0, 14, 0, 14) }):Play()
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local p = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
					updateSlider(min + (max - min) * p)
				end
			end)

			LastElementType = "Component"

			function SliderObj:Set(val, silent) 
				updateSlider(val, silent) 
			end

			function SliderObj:GetValue() 
				return SliderObj.Value 
			end

			function SliderObj:SetTitle(t) 
				titleLbl.Text = t 
			end

			function SliderObj:SetCallback(fn) 
				sliderCallback = fn 
			end

			if cfgKey then 
				Window.Elements[cfgKey] = { Object = SliderObj, Type = "Slider" } 
			end

			return SliderObj
		end

		-- ==========================================
		-- TOGGLE
		-- ==========================================
		function Components:AddToggle(configKey, props)
			if type(configKey) == "table" then 
				props = configKey
				configKey = nil 
			end

			props = props or {}

			local cfgKey = configKey
			local default = props.Default or false

			if cfgKey and ConfigData[cfgKey] ~= nil then 
				default = ConfigData[cfgKey] 
			end

			local toggled = default

			if LastElementType == "Component" then 
				AddDivider() 
			end

			ElementIndex = ElementIndex + 1

			local frameH = props.Desc and DS.CompHDesc or DS.CompH
			local toggleFrame = Create("Frame", {
				Name = "ToggleFrame", 
				Parent = CurrentGroup,
				BackgroundTransparency = 1, 
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, frameH), 
				LayoutOrder = ElementIndex, 
				Active = true,
			})

			local titleLbl = Create("TextLabel", {
				Parent = toggleFrame, 
				BackgroundTransparency = 1,
				Position = props.Desc and UDim2.new(0, DS.Padding, 0, 6) or UDim2.new(0, DS.Padding, 0.5, 0),
				AnchorPoint = props.Desc and Vector2.new(0, 0) or Vector2.new(0, 0.5),
				Size = UDim2.new(1, -60, props.Desc and 0 or 1, 0),
				FontFace = GetFont(Enum.FontWeight.SemiBold), 
				Text = props.Title or "Toggle",
				TextColor3 = Style.Text, 
				TextSize = DS.FontTitle,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = props.Desc and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
			})

			local descLbl = nil
			if props.Desc then
				descLbl = Create("TextLabel", {
					Text = props.Desc, 
					Size = UDim2.new(1, -60, 0, 20),
					Position = UDim2.new(0, DS.Padding, 0, DS.FontTitle + 6),
					AnchorPoint = Vector2.new(0, 0), 
					BackgroundTransparency = 1,
					FontFace = GetFont(Enum.FontWeight.Regular), 
					TextSize = DS.FontDesc,
					TextColor3 = Style.TextDim, 
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true, 
					Parent = toggleFrame,
				})
				RegisterTheme({ object = descLbl, prop = "TextColor3", key = "TextDim" })
			end

			local switchBg = Create("Frame", {
				Parent = toggleFrame, 
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = toggled and Style.Primary or Style.ToggleOff,
				Position = UDim2.new(1, -DS.Padding, 0.5, 0),
				Size = UDim2.new(0, DS.ToggleW, 0, DS.ToggleH),
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = switchBg })
			RegisterTheme({
				object = switchBg,
				custom = function(theme, tw)
					local color = toggled and theme.Primary or theme.ToggleOff
					if color then
						TweenService:Create(switchBg, tw, { BackgroundColor3 = color }):Play()
					end
				end,
			})

			local circleSz = DS.ToggleH - 4
			local circle = Create("Frame", {
				Parent = switchBg, 
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Style.Text,
				Position = UDim2.new(0, toggled and (DS.ToggleW - circleSz - 2) or 2, 0.5, 0),
				Size = UDim2.new(0, circleSz, 0, circleSz),
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = circle })
			RegisterTheme({ object = circle, prop = "BackgroundColor3", key = "Text" })

			local clickBtn = Create("TextButton", {
				Parent = toggleFrame, 
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0), 
				Text = "", 
				Active = true,
			})

			local ToggleObj = { Value = default }
			local toggleCallback = props.Callback or function() end

			local function setState(val)
				toggled = val
				ToggleObj.Value = toggled

				local tw = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

				TweenService:Create(switchBg, tw, { 
					BackgroundColor3 = toggled and Style.Primary or Style.ToggleOff 
				}):Play()

				TweenService:Create(circle, tw, { 
					Position = UDim2.new(0, toggled and (DS.ToggleW - circleSz - 2) or 2, 0.5, 0) 
				}):Play()

				if cfgKey then ConfigData[cfgKey] = toggled end
				toggleCallback(toggled)
			end

			clickBtn.Activated:Connect(function() 
				setState(not toggled) 
			end)

			LastElementType = "Component"

			function ToggleObj:Set(v)
				if type(v) ~= "boolean" then v = v == true end
				setState(v)
			end

			function ToggleObj:SetValue(v) 
				self:Set(v) 
			end

			function ToggleObj:GetValue() 
				return toggled 
			end

			function ToggleObj:SetTitle(t) 
				titleLbl.Text = t 
			end

			function ToggleObj:SetDesc(t)
				if descLbl then descLbl.Text = t end
			end

			function ToggleObj:SetCallback(fn) 
				toggleCallback = fn 
			end

			if cfgKey then 
				Window.Elements[cfgKey] = { Object = ToggleObj, Type = "Toggle" } 
			end

			return ToggleObj
		end

		-- ==========================================
		-- DROPDOWN
		-- ==========================================
		function Components:AddDropdown(configKey, props)
			if type(configKey) == "table" then 
				props = configKey
				configKey = nil 
			end

			props = props or {}

			local cfgKey = configKey
			local ddName = props.Name or props.Title or "Dropdown"
			local getOptions = (typeof(props.Options) == "function") and props.Options or nil
			local items = getOptions and getOptions() or props.Options or {}
			local defaultVal = props.Default
			local ddCallback = props.Callback or function() end
			local searchEnabled = props.SearchEnabled or false
			local isMulti = props.Multi or false

			local singleSel = defaultVal
			local multiSel = {}

			if cfgKey and ConfigData[cfgKey] ~= nil then
				local saved = ConfigData[cfgKey]
				if type(saved) == "table" then
					if isMulti then
						for _, v in pairs(saved) do
							if table.find(items, v) then table.insert(multiSel, v) end
						end
					else
						if saved[1] and table.find(items, saved[1]) then
							singleSel = saved[1]
							defaultVal = saved[1]
						end
					end
				end
			end

			if LastElementType == "Component" then 
				AddDivider() 
			end

			ElementIndex = ElementIndex + 1

			local frameH = props.Desc and DS.CompHDesc or DS.CompH
			local ddFrame = Create("Frame", {
				Name = "DropdownFrame", 
				Parent = CurrentGroup,
				BackgroundTransparency = 1, 
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, frameH), 
				ClipsDescendants = true,
				ZIndex = 2, 
				LayoutOrder = ElementIndex, 
				Active = true,
			})

			local titleLbl = Create("TextLabel", {
				Parent = ddFrame, 
				BackgroundTransparency = 1,
				Position = props.Desc and UDim2.new(0, DS.Padding, 0, 6) or UDim2.new(0, DS.Padding, 0.5, 0),
				AnchorPoint = props.Desc and Vector2.new(0, 0) or Vector2.new(0, 0.5),
				Size = UDim2.new(1, -40, props.Desc and 0 or 1, 0),
				FontFace = GetFont(Enum.FontWeight.SemiBold), 
				Text = ddName,
				TextColor3 = Style.Text, 
				TextSize = DS.FontTitle,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = props.Desc and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
				ZIndex = 2,
			})

			if props.Desc then
				local desc = Create("TextLabel", {
					Text = props.Desc, 
					Size = UDim2.new(1, -40, 0, 20),
					Position = UDim2.new(0, DS.Padding, 0, DS.FontTitle + 6),
					AnchorPoint = Vector2.new(0, 0), 
					BackgroundTransparency = 1,
					FontFace = GetFont(Enum.FontWeight.Regular), 
					TextSize = DS.FontDesc,
					TextColor3 = Style.TextDim, 
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true, 
					ZIndex = 2, 
					Parent = ddFrame,
				})
				RegisterTheme({ object = desc, prop = "TextColor3", key = "TextDim" })
			end

			local function buildMultiText(sel)
				if #sel == 0 then return "Select..."
				elseif #sel == 1 then return sel[1]
				else return sel[1] .. ", +" .. (#sel - 1) end
			end

			local curValLbl = Create("TextLabel", {
				Parent = ddFrame, 
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0.5, 0), 
				Size = UDim2.new(1, -35, 0, 20),
				AnchorPoint = Vector2.new(0, 0.5), 
				FontFace = GetFont(Enum.FontWeight.Regular),
				Text = isMulti and buildMultiText(multiSel) or (singleSel or "Select..."),
				TextColor3 = Style.TextDim, 
				TextSize = DS.FontBase - 1,
				TextXAlignment = Enum.TextXAlignment.Right, 
				TextTruncate = Enum.TextTruncate.AtEnd, 
				ZIndex = 2,
			})
			RegisterTheme({ object = curValLbl, prop = "TextColor3", key = "TextDim" })

			local chevronIcon = Create("ImageLabel", {
				Parent = ddFrame, 
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -28, 0.5, 0), 
				Size = UDim2.new(0, 20, 0, 20),
				AnchorPoint = Vector2.new(0, 0.5), 
				Image = GetIcon("chevron-right"),
				ImageColor3 = Style.TextDim, 
				ZIndex = 2,
			})
			RegisterTheme({ object = chevronIcon, prop = "ImageColor3", key = "TextDim" })

			local clickBtn = Create("TextButton", {
				Parent = ddFrame, 
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0), 
				Text = "", 
				ZIndex = 3, 
				Active = true,
			})

			local DropdownObj = { Items = items, Value = defaultVal }

			if isMulti then
				clickBtn.Activated:Connect(function()
					if getOptions then
						items = getOptions() or items
						DropdownObj.Items = items
					end
					Window:OpenRightDropdownMulti(ddName, items, multiSel, function(sel)
						table.clear(multiSel)
						for _, v in pairs(sel) do 
							table.insert(multiSel, v) 
						end

						curValLbl.Text = buildMultiText(multiSel)
						if cfgKey then 
							ConfigData[cfgKey] = multiSel 
						end

						ddCallback(multiSel)
					end, searchEnabled)
				end)

				function DropdownObj:Set(value)
					if typeof(value) ~= "table" then return end

					table.clear(multiSel)

					for _, v in pairs(value) do
						if table.find(items, v) then 
							table.insert(multiSel, v) 
						end
					end

					curValLbl.Text = buildMultiText(multiSel)

					if cfgKey then ConfigData[cfgKey] = multiSel end
					ddCallback(multiSel)
				end

				function DropdownObj:GetValue() return multiSel end
			else
				clickBtn.Activated:Connect(function()
					if getOptions then
						items = getOptions() or items
						DropdownObj.Items = items
					end
					Window:OpenRightDropdown(ddName, items, singleSel, function(value)
						if value and value[1] then
							singleSel = value[1]
							curValLbl.Text = singleSel

							if cfgKey then ConfigData[cfgKey] = value end
							ddCallback(value)
						end
					end, searchEnabled)
				end)

				function DropdownObj:Set(value)
					if value == nil then value = {} end
					if typeof(value) ~= "table" then return end

					if value[1] and table.find(items, value[1]) then
						singleSel = value[1]
						curValLbl.Text = singleSel
						if cfgKey then ConfigData[cfgKey] = value end
						ddCallback(value)
					else
						singleSel = nil
						curValLbl.Text = "Select..."
						if cfgKey then ConfigData[cfgKey] = {} end
						ddCallback({})
					end
				end

				function DropdownObj:GetValue() return singleSel end
			end

			function DropdownObj:Refresh(newItems)
				items = newItems or items
				self.Items = items
			end

			function DropdownObj:SetTitle(t) 
				titleLbl.Text = t 
			end

			function DropdownObj:SetCallback(fn) 
				ddCallback = fn 
			end


			LastElementType = "Component"

			if cfgKey then 
				Window.Elements[cfgKey] = { Object = DropdownObj, Type = "Dropdown" } 
			end

			return DropdownObj
		end

		return Components
	end

	-- ==========================================
	-- CONFIG TAB
	-- ==========================================
	function Window:AddConfigTab()
		local tab = self:AddTab({ Title = "Config", Icon = "settings" })

		local saveSec = tab:AddSection({ Title = "Save Configuration" })

		local nameInput = tab:AddInput({ 
			Title = "Config Name", 
			Placeholder = "Name config..." 
		})

		tab:AddButton({
			Title = "Save Config",
			Callback = function()
				local name = (nameInput and nameInput.Value or ""):match("^%s*(.-)%s*$")
				if name == "" then
					self:Notify({ Title = "Save Failed", Content = "Config name cannot be empty!" })
					return
				end
				self:SaveConfig(name)
			end,
		})

		local loadSec = tab:AddSection({ Title = "Load Configuration" })

		local configList = self:ListConfigs()

		local function CurrentConfigs()
			local list = self:ListConfigs()
			return #list > 0 and list or { "empty" }
		end

		local configDrop = tab:AddDropdown({
			Title = "Saved Configs",
			Options = CurrentConfigs,
			Default = configList[1],
		})

		tab:AddButton({
			Title = "Load Config",
			Callback = function()
				local sel = configDrop:GetValue()
				if not sel or sel == "empty" then
					self:Notify({ Title = "Load Failed", Content = "No configuration has been selected" })
					return
				end
				self:LoadConfig(sel)
			end,
		})

		tab:AddButton({
			Title = "Overwrite Config",
			Callback = function()
				local sel = configDrop:GetValue()
				if not sel or sel == "empty" then
					self:Notify({ Title = "Overwrite Failed", Content = "No configuration has been selected" })
					return
				end
				self:OverwriteConfig(sel)
			end,
		})

		tab:AddButton({
			Title = "Delete Config",
			Callback = function()
				local sel = configDrop:GetValue()
				if not sel or sel == "empty" then
					self:Notify({ Title = "Delete Failed", Content = "No configuration has been selected" })
					return
				end
				self:DeleteConfig(sel)
			end,
		})

		local themeSec = tab:AddSection({ Title = "Theme" })

		local themeDrop = tab:AddDropdown({
			Title = "Select Theme",
			Options = self:GetThemes(),
			Default = self:GetCurrentTheme(),
		})

		tab:AddButton({
			Title = "Apply Theme",
			Callback = function()
				local sel = themeDrop:GetValue()
				if not sel then
					self:Notify({ Title = "Theme Error", Content = "Select theme first!" })
					return
				end
				self:ApplyTheme(sel)
			end,
		})

		return tab
	end

	return Window
end

return NextHub
