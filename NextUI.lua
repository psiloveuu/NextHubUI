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
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- DEVICE
-- ==========================================
local ScreenW = workspace.CurrentCamera.ViewportSize.X
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
		WindowW = 480, WindowH = 300, SidebarW = 130, HeaderH = 34,
		CompH = 30, CompHDesc = 42, FontTitle = 10, FontBase = 10,
		TabFontSz = 10, TabBtnH = 28, SliderH = 44, PanelW = 150,
		LogoSz = 34, FontBadge = 12, FontHeader = 12, NotifyW = 220,
		NotifyH = 45, NotifyIcon = 24, NotifyFontT = 11, NotifyFontC = 10,
		DDHeader = 30, Padding = 8, IconSz = 14, ToggleW = 32,
		ToggleH = 16, InputH = 22, FontDesc = 10,
	},
	Tablet = {
		WindowW = 600, WindowH = 390, SidebarW = 155, HeaderH = 38,
		CompH = 32, CompHDesc = 46, FontTitle = 12, FontBase = 12,
		TabFontSz = 11, TabBtnH = 34, SliderH = 48, PanelW = 175,
		LogoSz = 38, FontBadge = 14, FontHeader = 14, NotifyW = 260,
		NotifyH = 55, NotifyIcon = 28, NotifyFontT = 12, NotifyFontC = 11,
		DDHeader = 40, Padding = 10, IconSz = 16, ToggleW = 36,
		ToggleH = 18, InputH = 24, FontDesc = 11,
	},
	Desktop = {
		WindowW = 700, WindowH = 450, SidebarW = 180, HeaderH = 44,
		CompH = 34, CompHDesc = 50, FontTitle = 14, FontBase = 14,
		TabFontSz = 12, TabBtnH = 38, SliderH = 52, PanelW = 200,
		LogoSz = 42, FontBadge = 16, FontHeader = 16, NotifyW = 300,
		NotifyH = 65, NotifyIcon = 32, NotifyFontT = 14, NotifyFontC = 12,
		DDHeader = 50, Padding = 12, IconSz = 18, ToggleW = 40,
		ToggleH = 20, InputH = 26, FontDesc = 12,
	},
}
local DS = DSConfig[DeviceType] or DSConfig.Desktop

-- ==========================================
-- STYLE
-- ==========================================
local Style = {
	DarkBg = Color3.fromRGB(20, 20, 20),
	SidebarBg = Color3.fromRGB(20, 20, 20),
	InputBg = Color3.fromRGB(30, 30, 30),
	InputStroke = Color3.fromRGB(150, 150, 150),
	Primary = Color3.fromRGB(100, 180, 255),
	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(140, 140, 140),
	HeaderBadge = Color3.fromRGB(100, 180, 255),
	VersionBadge = Color3.fromRGB(255, 232, 25),
	ToggleOff = Color3.fromRGB(70, 70, 70),
	FontBase = "rbxasset://fonts/families/Montserrat.json",
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
		Primary = Color3.fromRGB(100, 180, 255),
		Text = Color3.fromRGB(255, 255, 255),
		TextDim = Color3.fromRGB(140, 140, 140),
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
		Text = Color3.fromRGB(195, 220, 205),
		TextDim = Color3.fromRGB(80, 120, 95),
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
		Text = Color3.fromRGB(210, 210, 220),
		TextDim = Color3.fromRGB(95, 95, 108),
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
		Text = Color3.fromRGB(215, 208, 235),
		TextDim = Color3.fromRGB(95, 80, 130),
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
		Text = Color3.fromRGB(225, 210, 210),
		TextDim = Color3.fromRGB(120, 72, 74),
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
		Text = Color3.fromRGB(235, 225, 195),
		TextDim = Color3.fromRGB(120, 100, 55),
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
		Text = Color3.fromRGB(195, 220, 235),
		TextDim = Color3.fromRGB(65, 118, 145),
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
		Text = Color3.fromRGB(235, 210, 220),
		TextDim = Color3.fromRGB(118, 72, 90),
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
	local InitialPos = UDim2.new(0.5, -DS.WindowW / 2, 0.5, -DS.WindowH / 2)

	local MainFrame = Create("Frame", {
		Name = "MainFrame",
		Parent = ScreenGui,
		BackgroundColor3 = Style.DarkBg,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Position = InitialPos,
		Size = InitialSize,
		ClipsDescendants = true,
	})
	local WindowScale = Create("UIScale", { Parent = MainFrame, Scale = 1 })
	Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = MainFrame })

	local MainStroke = Create("UIStroke", { 
		Color = Style.Primary, 
		Thickness = 1.7, 
		Transparency = 0.2, 
		Parent = MainFrame 
	})
	RegisterTheme({ object = MainFrame, prop = "BackgroundColor3", key = "DarkBg" })
	RegisterTheme({ object = MainStroke, prop = "Color", key = "Primary" })

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

	local curX = 6 + DS.LogoSz + 8

	if Mode == "Premium" then
		Create("TextLabel", {
			Text = "|", 
			Size = UDim2.new(0, 0, 0, DS.HeaderH),
			Position = UDim2.fromOffset(curX, 0), 
			BackgroundTransparency = 1,
			FontFace = GetFont(Enum.FontWeight.Bold), 
			TextSize = DS.FontHeader,
			TextXAlignment = Enum.TextXAlignment.Left, 
			TextColor3 = Style.TextDim,
			Parent = Header,
		})

		curX = curX + 15
		Create("ImageLabel", {
			Image = GetIcon("crown"), 
			Size = UDim2.fromOffset(DS.FontTitle, DS.FontTitle),
			Position = UDim2.new(0, curX, 0.5, -DS.FontTitle / 2), 
			BackgroundTransparency = 1,
			ImageColor3 = Color3.fromRGB(255, 215, 0), 
			Parent = Header,
		})

		curX = curX + DS.FontHeader + 4
		local lbl = Create("TextLabel", {
			Text = "Premium", 
			Size = UDim2.new(0, 0, 0, DS.HeaderH),
			Position = UDim2.fromOffset(curX, 0), 
			BackgroundTransparency = 1,
			FontFace = GetFont(Enum.FontWeight.Bold), 
			TextSize = DS.FontHeader,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Color3.fromRGB(255, 215, 0), 
			Parent = Header,
		})

		curX = curX + lbl.TextBounds.X + 5
	else
		Create("TextLabel", {
			Text = "|", 
			Size = UDim2.new(0, 0, 0, DS.HeaderH),
			Position = UDim2.fromOffset(curX, 0), 
			BackgroundTransparency = 1,
			FontFace = GetFont(Enum.FontWeight.Bold), 
			TextSize = DS.FontHeader,
			TextXAlignment = Enum.TextXAlignment.Left, 
			TextColor3 = Style.TextDim,
			Parent = Header,
		})

		curX = curX + 15
		Create("ImageLabel", {
			Image = GetIcon("sparkles"), 
			Size = UDim2.fromOffset(DS.FontTitle, DS.FontTitle),
			Position = UDim2.new(0, curX, 0.5, -DS.FontTitle / 2), 
			BackgroundTransparency = 1,
			ImageColor3 = Color3.fromRGB(150, 200, 255),
			Parent = Header,
		})

		curX = curX + DS.FontHeader + 4
		local lbl = Create("TextLabel", {
			Text = "Free", 
			Size = UDim2.new(0, 0, 0, DS.HeaderH),
			Position = UDim2.fromOffset(curX, 0), 
			BackgroundTransparency = 1,
			FontFace = GetFont(Enum.FontWeight.Bold), 
			TextSize = DS.FontHeader,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Color3.fromRGB(150, 200, 255), 
			Parent = Header,
		})

		curX = curX + lbl.TextBounds.X + 5
	end

	local statusText, statusColor
	if Update == "Stable" then
		statusText = "STABLE"
		statusColor = Color3.fromRGB(40, 190, 100)
	elseif Update == "Hotfix" then
		statusText = "HOTFIX"
		statusColor = Color3.fromRGB(160, 100, 255)
	else
		statusText = "BETA"
		statusColor = Style.HeaderBadge
	end

	local tmp = Create("TextLabel", { 
		Text = statusText, 
		FontFace = GetFont(Enum.FontWeight.SemiBold), 
		TextSize = DS.FontBadge, 
		Visible = false, 
		Parent = Header 
	})
	local badgeW = tmp.TextBounds.X + 16
	tmp:Destroy()

	local statusBadge = Create("TextLabel", {
		Size = UDim2.new(0, badgeW, 0, DS.FontBadge + 7),
		Position = UDim2.new(0, curX + 10, 0.5, -(DS.FontBadge + 7) / 2),
		BackgroundColor3 = statusColor, 
		TextColor3 = Style.Text,
		Text = statusText, 
		FontFace = GetFont(Enum.FontWeight.SemiBold),
		TextSize = DS.FontBadge, 
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = Header,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = statusBadge })

	curX = curX + badgeW + 20

	local tmp2 = Create("TextLabel", { 
		Text = version, 
		FontFace = GetFont(Enum.FontWeight.SemiBold), 
		TextSize = DS.FontBadge, 
		Visible = false, 
		Parent = Header 
	})

	local verW = tmp2.TextBounds.X + 16
	tmp2:Destroy()

	local verBadge = Create("TextLabel", {
		Text = version, 
		Size = UDim2.new(0, verW, 0, DS.FontBadge + 7),
		Position = UDim2.new(0, curX, 0.5, -(DS.FontBadge + 7) / 2),
		BackgroundColor3 = Color3.fromRGB(255, 165, 0), 
		TextColor3 = Style.Text,
		FontFace = GetFont(Enum.FontWeight.SemiBold), 
		TextSize = DS.FontBadge,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center, 
		Parent = Header,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = verBadge })

	local btnSz = DS.HeaderH - 22
	local closeBtn = Create("ImageButton", {
		Size = UDim2.fromOffset(btnSz + 7, btnSz + 7),
		Position = UDim2.new(1, -34, 0.5, -(btnSz + 7) / 2),
		BackgroundTransparency = 1, 
		Image = GetIcon("x"),
		ImageColor3 = Color3.fromRGB(190, 220, 255),
		ScaleType = Enum.ScaleType.Fit, 
		ZIndex = 10,
		Active = true, 
		Parent = Header,
	})

	local minimizeBtn = Create("ImageButton", {
		Size = UDim2.fromOffset(btnSz + 7, btnSz + 7),
		Position = UDim2.new(1, -66, 0.5, -(btnSz + 7) / 2),
		BackgroundTransparency = 1, 
		Image = GetIcon("minus"),
		ImageColor3 = Color3.fromRGB(190, 220, 255),
		ScaleType = Enum.ScaleType.Fit, 
		ZIndex = 10,
		Active = true, 
		Parent = Header,
	})

	local IsMinimized = false

	local toggleBtn = Create("ImageButton", {
		Name = "ToggleUI", 
		Parent = ScreenGui,
		BackgroundColor3 = Style.DarkBg, 
		BorderSizePixel = 0,
		Position = UDim2.new(0.1, 0, 0.1, 0),
		Size = UDim2.new(0, DS.HeaderH + 3, 0, DS.HeaderH + 3),
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
	Create("UIStroke", { Color = Style.InputStroke, Thickness = 1, Parent = toggleBtn })

	local function ToggleUI()
		IsMinimized = not IsMinimized

		if IsMinimized then
			local tw = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
				Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1,
			})

			TweenService:Create(WindowScale, TweenInfo.new(0.3), { Scale = 0.5 }):Play()
			tw:Play()

			tw.Completed:Connect(function()
				if IsMinimized then MainFrame.Visible = false end
			end)
		else
			MainFrame.Visible = true
			MainFrame.Size = UDim2.new(0, 0, 0, 0)

			TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = InitialSize, BackgroundTransparency = 0.1,
			}):Play()

			TweenService:Create(WindowScale, TweenInfo.new(0.3), { Scale = 1 }):Play()
		end
	end

	closeBtn.Activated:Connect(function()
		local tw = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1,
		})

		tw:Play()

		tw.Completed:Connect(function() ScreenGui:Destroy() end)
	end)

	toggleBtn.Activated:Connect(ToggleUI)
	minimizeBtn.Activated:Connect(ToggleUI)

	local Sidebar = Create("Frame", {
		Name = "Sidebar", 
		Parent = MainFrame,
		BackgroundColor3 = Style.SidebarBg, 
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, DS.HeaderH - 15),
		Size = UDim2.new(0, DS.SidebarW, 1, -(DS.HeaderH - 15)),
	})

	local TabContainer = Create("ScrollingFrame", {
		Name = "TabContainer", 
		Parent = Sidebar,
		Active = true, 
		BackgroundTransparency = 1, 
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 15), 
		Size = UDim2.new(1, 0, 1, -25),
		CanvasSize = UDim2.new(0, 0, 0, 0), 
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y, 
		ScrollBarThickness = 0,
		ScrollBarImageColor3 = Style.Primary,
	})

	local ButtonsHolder = Create("Frame", {
		Name = "ButtonsHolder", 
		Parent = TabContainer,
		BackgroundTransparency = 1, 
		Size = UDim2.new(1, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})
	Create("UIListLayout", { Parent = ButtonsHolder, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5) })
	Create("UIPadding", { Parent = ButtonsHolder, PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7) })

	local SlidingIndicator = Create("Frame", {
		Name = "SlidingIndicator", 
		Parent = TabContainer,
		BackgroundColor3 = Style.Primary, 
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 0), 
		Size = UDim2.new(0, 4, 0, DS.TabBtnH - 12),
		Visible = false, 
		ZIndex = 2,
	})
	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SlidingIndicator })
	RegisterTheme({ object = SlidingIndicator, prop = "BackgroundColor3", key = "Primary" })

	local ContentContainer = Create("Frame", {
		Name = "ContentContainer", 
		Parent = MainFrame,
		BackgroundTransparency = 0.7, 
		BackgroundColor3 = Style.InputStroke,
		Position = UDim2.new(0, DS.SidebarW, 0, DS.HeaderH),
		Size = UDim2.new(1, -DS.SidebarW, 1, -DS.HeaderH),
		ClipsDescendants = true,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = ContentContainer })
	RegisterTheme({ object = ContentContainer, prop = "BackgroundColor3", key = "InputStroke" })

	local gameLabel = Create("TextLabel", {
		Name = "TabBtn_GameName", 
		Size = UDim2.new(1, 0, 0, DS.TabBtnH - 2),
		BackgroundColor3 = Color3.fromRGB(50, 50, 50), 
		TextColor3 = Style.Primary,
		Text = "Game: " .. gameName, 
		TextSize = DS.FontBadge - 1,
		FontFace = GetFont(Enum.FontWeight.Bold), 
		BackgroundTransparency = 0.2,
		TextWrapped = true, 
		Parent = ButtonsHolder,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = gameLabel })
	RegisterTheme({ object = gameLabel, prop = "TextColor3", key = "Primary" })

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

		local frame = Create("Frame", {
			Name = "NotifyFrame", 
			Parent = NotifHolder,
			BackgroundColor3 = Style.DarkBg, 
			BackgroundTransparency = 0.05,
			Size = UDim2.fromOffset(DS.NotifyW, DS.NotifyH), 
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

		local bar = Create("Frame", {
			Parent = frame, 
			BackgroundColor3 = Style.Primary, 
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 1, -2), 
			Size = UDim2.new(1, 0, 0, 2),
		})

		frame.Position = UDim2.new(0, DS.NotifyW + 20, 0, 0)
		TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint), { Position = UDim2.new(0, 0, 0, 0) }):Play()
		TweenService:Create(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()

		task.delay(duration, function()
			local tw = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
				Position = UDim2.new(0, DS.NotifyW + 20, 0, 0),
			})
			
			tw:Play()

			tw.Completed:Wait()

			frame:Destroy()
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

		local tw = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

		for i, btn in ipairs(self.TabButtons) do
			local active = (i == self.__activeTabIndex)

			TweenService:Create(btn, tw, {
				BackgroundTransparency = active and 0.75 or 1,
				BackgroundColor3 = active and Style.Primary or Color3.fromRGB(50, 50, 50),
			}):Play()
		end

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
		BackgroundTransparency = 0.2, 
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

	local PanelHeader = Create("Frame", {
		Parent = DropPanel, 
		BackgroundColor3 = Style.DarkBg,
		BackgroundTransparency = 0.15, 
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

	local PanelCloseBtn = Create("ImageButton", {
		Parent = PanelHeader, 
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -30, 0.5, -10), 
		Size = UDim2.new(0, 20, 0, 20),
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

	local function CloseDropPanel()
		if not IsPanelOpen then return end

		IsPanelOpen = false
		TweenService:Create(DropPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
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
		if CurrentPanelCallback then CurrentPanelCallback(PanelMultiSelected) end
		CloseDropPanel()
	end)

	local function OpenPanel()
		if IsPanelOpen then return end
		IsPanelOpen = true
		DropPanel.Visible = true
		DropPanel.Position = UDim2.new(1, 0, 0, HeaderHeight)
		TweenService:Create(DropPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
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
		PanelList.Size = UDim2.new(1, 0, 1, -listTop)

		for _, item in pairs(items) do
			local selected = (item == default)

			local btn = Create("TextButton", {
				Parent = PanelList,
				BackgroundColor3 = selected and Style.Primary or Style.ElementBackground,
				BackgroundTransparency = selected and 0.2 or 0.5,
				Size = UDim2.new(1, 0, 0, DS.TabBtnH - 8),
				FontFace = GetFont(Enum.FontWeight.Medium), Text = "  " .. item,
				TextColor3 = Style.Text, TextSize = DS.FontBase - 1,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				AutoButtonColor = false, ZIndex = 52,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = btn })

			btn.Activated:Connect(function()
				if CurrentPanelCallback then CurrentPanelCallback({ item }) end
				CloseDropPanel()
			end)

			btn.MouseEnter:Connect(function()
				if not selected then 
					TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = Style.Hover }):Play() 
				end
			end)

			btn.MouseLeave:Connect(function()
				if not selected then 
					TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = Style.ElementBackground }):Play() 
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

		local function RefreshRows()
			for _, row in pairs(PanelList:GetChildren()) do
				if row:IsA("Frame") then
					local checked = table.find(PanelMultiSelected, row.Name) ~= nil

					local cb = row:FindFirstChild("CheckBox")
					local cm = row:FindFirstChild("CheckMark")

					if cb then 
						TweenService:Create(cb, TweenInfo.new(0.15), { 
							BackgroundColor3 = checked and Style.CheckboxOn or Style.CheckboxOff 
						}):Play() 
					end

					if cm then cm.Visible = checked end
				end
			end
		end

		for _, item in pairs(items) do
			local checked = table.find(PanelMultiSelected, item) ~= nil

			local row = Create("Frame", {
				Name = item, 
				Parent = PanelList,
				BackgroundColor3 = Style.ElementBackground, 
				BackgroundTransparency = 0.5,
				Size = UDim2.new(1, 0, 0, DS.TabBtnH - 6), 
				ZIndex = 52,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = row })

			local cb = Create("Frame", {
				Name = "CheckBox", 
				Parent = row,
				BackgroundColor3 = checked and Style.CheckboxOn or Style.CheckboxOff,
				Position = UDim2.new(1, -30, 0.5, -9), 
				Size = UDim2.new(0, 18, 0, 18), 
				ZIndex = 53,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = cb })

			Create("ImageLabel", {
				Name = "CheckMark", Parent = cb, 
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -2, 1, -2), 
				Position = UDim2.new(0, 1, 0, 1),
				Image = GetIcon("check"), 
				ImageColor3 = Style.Text, 
				ZIndex = 54, 
				Visible = checked,
			})
			
			Create("TextLabel", {
				Parent = row, 
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 0), 
				Size = UDim2.new(1, -44, 1, 0),
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
				TweenService:Create(row, TweenInfo.new(0.15), { BackgroundColor3 = Style.Hover }):Play() 
			end)

			row.MouseLeave:Connect(function() 
				TweenService:Create(row, TweenInfo.new(0.15), { BackgroundColor3 = Style.ElementBackground }):Play() 
			end)
		end

		OpenPanel()
	end

	local function MoveIndicator(btn)
		if not SlidingIndicator.Visible then 
			SlidingIndicator.Visible = true 
		end

		local y = (btn.AbsolutePosition.Y - TabContainer.AbsolutePosition.Y) + TabContainer.CanvasPosition.Y

		TweenService:Create(SlidingIndicator, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(12, y + 6),
		}):Play()
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
		local BG_TW = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

		local tabBtn = Create("ImageButton", {
			Name = "TabBtn_" .. index, 
			Size = UDim2.new(1, 0, 0, DS.TabBtnH),
			BackgroundColor3 = (index == 1) and Style.Primary or Color3.fromRGB(50, 50, 50),
			BackgroundTransparency = (index == 1) and 0.75 or 1,
			AutoButtonColor = false, 
			Active = true, 
			Parent = ButtonsHolder,
		})
		self.TabButtons[index] = tabBtn
		Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = tabBtn })

		if tabIcon then
			Create("ImageLabel", {
				Size = UDim2.fromOffset(DS.IconSz + 4, DS.IconSz + 4),
				Position = UDim2.new(0, DS.Padding + 4, 0.5, -(DS.IconSz + 4) / 2),
				BackgroundTransparency = 1, 
				Image = GetIcon(tabIcon) or "",
				Parent = tabBtn,
			})
		end

		local tabLabel = Create("TextLabel", {
			Text = tabTitle,
			Size = UDim2.new(1, -(DS.Padding * 2 + DS.IconSz), 1, 0),
			Position = UDim2.new(0, tabIcon and (DS.Padding + DS.IconSz + 12) or DS.Padding, 0, 0),
			BackgroundTransparency = 1, 
			TextColor3 = Style.Text,
			FontFace = GetFont(Enum.FontWeight.Medium), 
			TextSize = DS.TabFontSz,
			TextXAlignment = Enum.TextXAlignment.Left, 
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

		Create("UIListLayout", { Parent = tabContent, SortOrder = Enum.SortOrder.LayoutOrder })
		Create("UIPadding", {
			PaddingTop = UDim.new(0, 12), 
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12), 
			PaddingBottom = UDim.new(0, 12),
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
			Create("UIPadding", { Parent = d, PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) })
		end

		local function ActivateTab()
			Window.__tabChanged:Fire()
			Window.__activeTabIndex = index

			for i, c in ipairs(self.TabContents) do
				local active = (i == index)
				local b = self.TabButtons[i]

				c.Visible = active
				TweenService:Create(b, BG_TW, {
					BackgroundTransparency = active and 0.75 or 1,
					BackgroundColor3 = active and Style.Primary or Color3.fromRGB(50, 50, 50),
				}):Play()
			end

			MoveIndicator(tabBtn)
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
				BackgroundTransparency = 1, 
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y, 
				LayoutOrder = ElementIndex,
			})
			Create("UIPadding", {
				Parent = outer, 
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft = UDim.new(0, 1), 
				PaddingRight = UDim.new(0, 1),
			})
			Create("UIListLayout", { Parent = outer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) })

			local sectionHeader = Create("Frame", {
				Name = "SectionHeader", 
				Parent = outer,
				BackgroundColor3 = Style.ElementBackground, 
				BackgroundTransparency = 0.3,
				Size = UDim2.new(1, 0, 0, 35), 
				LayoutOrder = 1,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = sectionHeader })
			RegisterTheme({ object = sectionHeader, prop = "BackgroundColor3", key = "ElementBackground" })

			local secStroke = Create("UIStroke", {
				Color = Style.Primary, 
				Thickness = 1.5,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border, 
				Parent = sectionHeader,
			})
			RegisterTheme({ object = secStroke, prop = "Color", key = "Primary" })

			local headerBtn = Create("TextButton", {
				Parent = sectionHeader, 
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1, 
				Text = "", 
				ZIndex = 5,
			})

			local chevron = Create("ImageLabel", {
				Parent = sectionHeader, 
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -28, 0.5, -8), 
				Size = UDim2.new(0, 16, 0, 16),
				Image = GetIcon("chevron-down"), 
				ImageColor3 = Style.Primary,
			})
			RegisterTheme({ object = chevron, prop = "ImageColor3", key = "Primary" })

			local cx = 12
			if icon then
				local ico = Create("ImageLabel", {
					Parent = sectionHeader, 
					BackgroundTransparency = 1,
					Position = UDim2.new(0, cx, 0.5, -9), Size = UDim2.new(0, 18, 0, 18),
					Image = GetIcon(icon), 
					ImageColor3 = Style.Primary,
				})
				RegisterTheme({ object = ico, prop = "ImageColor3", key = "Primary" })
				cx = cx + 28
			end

			local secTitleLabel = Create("TextLabel", {
				Parent = sectionHeader, 
				BackgroundTransparency = 1,
				Position = UDim2.new(0, cx, 0, 0), 
				Size = UDim2.new(1, -(cx + 40), 1, 0),
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
				BackgroundColor3 = Style.ElementBackground,
				BackgroundTransparency = 0.5, 
				Parent = clip,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = sectionGroup })
			RegisterTheme({ object = sectionGroup, prop = "BackgroundColor3", key = "ElementBackground" })

			Create("UIListLayout", { Parent = sectionGroup, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) })
			Create("UIPadding", {
				Parent = sectionGroup,
				PaddingTop = UDim.new(0, 6), 
				PaddingBottom = UDim.new(0, 6),
				PaddingLeft = UDim.new(0, 6), 
				PaddingRight = UDim.new(0, 6),
			})

			CurrentGroup = sectionGroup

			local collapsed = false
			local isTweening = false

			local function UpdateClipSize()
				if not collapsed and not isTweening then
					clip.Size = UDim2.new(1, 0, 0, sectionGroup.AbsoluteSize.Y)
				end
			end
			sectionGroup:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateClipSize)

			headerBtn.Activated:Connect(function()
				collapsed = not collapsed
				local target = collapsed and UDim2.new(1, 0, 0, 0) or UDim2.new(1, 0, 0, sectionGroup.AbsoluteSize.Y)

				isTweening = true

				TweenService:Create(chevron, TweenInfo.new(0.3), { Rotation = collapsed and -90 or 0 }):Play()

				local tw = TweenService:Create(clip, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = target })
				
				tw:Play()

				tw.Completed:Connect(function()
					isTweening = false
					if not collapsed then
						clip.Size = UDim2.new(1, 0, 0, sectionGroup.AbsoluteSize.Y)
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
					TextColor3 = Style.Primary, 
					TextSize = DS.FontTitle,
					TextXAlignment = Enum.TextXAlignment.Left, 
					TextYAlignment = Enum.TextYAlignment.Top,
				})
				RegisterTheme({ object = titleLbl, prop = "TextColor3", key = "Primary" })
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
				TextColor3 = Style.Primary,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = props.Desc and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
				Parent = btnFrame,
			})
			RegisterTheme({ object = titleLbl, prop = "TextColor3", key = "Primary" })

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
				TextColor3 = Style.Primary, 
				TextSize = DS.FontTitle,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = props.Desc and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
			})
			RegisterTheme({ object = titleLbl, prop = "TextColor3", key = "Primary" })

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
				Position = UDim2.new(0, 12, 0, 6), 
				Size = UDim2.new(1, -24, 0, 20),
				FontFace = GetFont(Enum.FontWeight.SemiBold), 
				Text = props.Title or "Slider",
				TextColor3 = Style.Primary, 
				TextSize = DS.FontTitle,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			RegisterTheme({ object = titleLbl, prop = "TextColor3", key = "Primary" })

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
				Size = UDim2.new(1, 0, 1, 0), 
				Text = "", ZIndex = 3,
			})

			local dragging = false
			local sliderCallback = props.Callback or function() end
			local SliderObj = { Value = default }

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
					TweenService:Create(knob, TweenInfo.new(0.1), { Size = UDim2.new(0, 18, 0, 18) }):Play()
					local p = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
					updateSlider(min + (max - min) * p)
				end
			end)

			inputBtn.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
					TweenService:Create(knob, TweenInfo.new(0.1), { Size = UDim2.new(0, 14, 0, 14) }):Play()
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
				TextColor3 = Style.Primary, 
				TextSize = DS.FontTitle,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = props.Desc and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
			})
			RegisterTheme({ object = titleLbl, prop = "TextColor3", key = "Primary" })

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
			local items = props.Options or {}
			local defaultVal = props.Default or items[1]
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
				TextColor3 = Style.Primary, 
				TextSize = DS.FontTitle,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = props.Desc and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
				ZIndex = 2,
			})
			RegisterTheme({ object = titleLbl, prop = "TextColor3", key = "Primary" })

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
					if typeof(value) ~= "table" then return end
					if value[1] then
						singleSel = value[1]
						curValLbl.Text = singleSel
						if cfgKey then ConfigData[cfgKey] = value end
						ddCallback(value)
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
		local tab = self:AddTab({ Title = "| Config", Icon = "settings" })

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
		local configDrop = tab:AddDropdown({
			Title = "Saved Configs",
			Options = #configList > 0 and configList or { "empty" },
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
				local newList = self:ListConfigs()
				configDrop:Refresh(#newList > 0 and newList or { "empty" })
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
