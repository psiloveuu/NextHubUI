-- ==========================================
-- DEBUG MODE (ROBLOX STUDIO COMPATIBILITY)
-- ==========================================
if not isfile then
	_G.DebugFileSystem = _G.DebugFileSystem or {}
	function isfile(path) return _G.DebugFileSystem[path] ~= nil end
	function readfile(path)
		local data = _G.DebugFileSystem[path]
		if not data then warn("[Debug Mode] File not found (simulated): " .. path) end
		return data or ""
	end
	function writefile(path, content)
		_G.DebugFileSystem[path] = content
		print("[Debug Mode] Saved to memory: " .. path)
	end
end

local NextHub = {}

local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService     = game:GetService("RunService")
local HttpService    = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- RESPONSIVE: DEVICE DETECTION
-- ==========================================
local ViewportSize = workspace.CurrentCamera.ViewportSize
local ScreenW      = ViewportSize.X

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
		WindowW    = 480, WindowH    = 300,
		SidebarW   = 130, HeaderH    = 34,
		CompH      = 30,  CompHDesc  = 42,
		FontTitle  = 10,  FontBase   = 10,
		TabFontSz  = 10,  TabBtnH    = 28,
		SliderH    = 44,  PanelW     = 150,
		LogoSz     = 34,  FontBadge  = 12,
		FontHeader = 12,  NotifyW    = 220,
		NotifyH    = 45,  NotifyIcon = 24,
		NotifyFontT = 11, NotifyFontC = 10,
		DDHeader   = 30,  Padding    = 8,   
		IconSz     = 14,  ToggleW    = 32,  
		ToggleH    = 16,  InputH     = 22,
		FontDesc   = 10
	},
	Tablet = {
		WindowW    = 600, WindowH    = 390,
		SidebarW   = 155, HeaderH    = 38,
		CompH      = 32,  CompHDesc  = 46,
		FontTitle  = 12,  FontBase   = 12,
		TabFontSz  = 11,  TabBtnH    = 34,
		SliderH    = 48,  PanelW     = 175,
		LogoSz     = 38,  FontBadge  = 14,
		FontHeader = 14,  NotifyW    = 260,
		NotifyH    = 55,  NotifyIcon = 28, 
		NotifyFontT = 12, NotifyFontC = 11,
		DDHeader   = 40,  Padding    = 10,  
		IconSz     = 16,  ToggleW    = 36,  
		ToggleH    = 18,  InputH     = 24,
		FontDesc   = 11
	},
	Desktop = {
		WindowW    = 700, WindowH    = 450,
		SidebarW   = 180, HeaderH    = 44,
		CompH      = 34,  CompHDesc  = 50,
		FontTitle  = 14,  FontBase   = 14,
		TabFontSz  = 12,  TabBtnH    = 38,
		SliderH    = 52,  PanelW     = 200,
		LogoSz     = 42,  FontBadge  = 16,
		FontHeader = 16,  NotifyW    = 300,
		NotifyH    = 65,  NotifyIcon = 32, 
		NotifyFontT = 14, NotifyFontC = 12,
		DDHeader   = 50,  Padding    = 12,  
		IconSz     = 18,  ToggleW    = 40,  
		ToggleH    = 20,  InputH     = 26,
		FontDesc   = 12
	},
}
local DS = DSConfig[DeviceType] or DSConfig.Desktop

-- ==========================================
-- NEXTHUB UI: STYLE & VISUALS
-- ==========================================
local Style = {
	DarkBg          = Color3.fromRGB(20, 20, 20),
	SidebarBg       = Color3.fromRGB(20, 20, 20),
	InputBg         = Color3.fromRGB(30, 30, 30),
	InputStroke     = Color3.fromRGB(150, 150, 150),
	Primary         = Color3.fromRGB(100, 180, 255),
	Text            = Color3.fromRGB(255, 255, 255),
	TextDim         = Color3.fromRGB(140, 140, 140),
	HeaderBadge     = Color3.fromRGB(100, 180, 255),
	VersionBadge    = Color3.fromRGB(255, 232, 25),
	ToggleOff       = Color3.fromRGB(70, 70, 70),
	FontBase        = "rbxasset://fonts/families/Montserrat.json",
	ElementBackground = Color3.fromRGB(30, 30, 30),
	Outline         = Color3.fromRGB(60, 60, 70),
	Hover           = Color3.fromRGB(40, 45, 60),
	CheckboxOn      = Color3.fromRGB(100, 180, 255),
	CheckboxOff     = Color3.fromRGB(60, 60, 70),
}

local function GetFont(weight)
	weight = weight or Enum.FontWeight.Regular
	return Font.new(Style.FontBase, weight)
end

local IconCache    = {}
local iconInitDone = false

local RawPacks = {
	lucide = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua",
	solar  = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/solar/dist/Icons.lua",
	craft  = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/craft/dist/Icons.lua",
	geist  = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/geist/dist/Icons.lua",
}

local ICON_FALLBACK = {

    ["x"]               = "rbxassetid://76821953846248",
    ["minus"]           = "rbxassetid://133556159576809",
    ["check"]           = "rbxassetid://93898873302694",
    ["chevron-right"]   = "rbxassetid://92473583511724",
    ["chevron-down"]    = "rbxassetid://134243273101015",
    ["chevron-left"]    = "rbxassetid://73780377692148",
    ["chevron-up"]      = "rbxassetid://122444883127455",
    ["bell"]            = "rbxassetid://97392696311902",
    ["mouse-pointer-2"] = "rbxassetid://78956681942188",

    ["info-square-bold"]        = "rbxassetid://131995373201472",

    ["fish"]            = "rbxassetid://124360663785796",
    ["repeat-2"]        = "rbxassetid://78082218499697",
    ["shopping-cart"]   = "rbxassetid://121098640829562",
    ["arrow-left-right"]= "rbxassetid://131324733048447",
    ["map-pin"]         = "rbxassetid://100033680381365",
    ["activity"]        = "rbxassetid://94212016861936",
    ["link"]            = "rbxassetid://92181172123618",
    ["swords"]          = "rbxassetid://132405197863294",
    ["skull"]           = "rbxassetid://74237056000103",
    ["user"]            = "rbxassetid://95489465399880",
    ["calendar"]        = "rbxassetid://114792700814035", 

    ["crown"]           = "rbxassetid://127843403295538",
    ["sparkles"]        = "rbxassetid://91872927606406",

    ["arrow-up"]        = "rbxassetid://89282378235317",
    ["arrow-down"]      = "rbxassetid://98764963621439",
    ["arrow-left"]      = "rbxassetid://102531941843733",
    ["arrow-right"]     = "rbxassetid://113692007244654",
    ["arrow-up-down"]   = "rbxassetid://81019887641527",
    ["arrow-right-left"]= "rbxassetid://77015754304300",
    ["refresh-cw"]      = "rbxassetid://78082218499697",
    ["rotate-ccw"]      = "rbxassetid://78082218499697",
    ["external-link"]   = "rbxassetid://129331830773832",
    ["copy"]            = "rbxassetid://78979572434545",
    ["download"]        = "rbxassetid://134814648082393",
    ["upload"]          = "rbxassetid://93307473217005", 

    ["circle-check"]    = "rbxassetid://85262178816537",
    ["circle-x"]        = "rbxassetid://76821953846248",
    ["circle-alert"]    = "rbxassetid://83898160590116",
    ["circle-plus"]     = "rbxassetid://113157136350384",
    ["circle-minus"]    = "rbxassetid://133556159576809",
    ["alert-triangle"]  = "rbxassetid://83898160590116",
    ["info"]            = "rbxassetid://131995373201472",
    ["check-circle"]    = "rbxassetid://85262178816537",
    ["xmark"]           = "rbxassetid://76821953846248",

    ["eye"]             = "rbxassetid://100033680381365",
    ["eye-off"]         = "rbxassetid://135928786788378",
    ["lock"]            = "rbxassetid://118765061220571",
    ["unlock"]          = "rbxassetid://91306356501736",
    ["settings"]        = "rbxassetid://116544501716299", 
    ["cog"]             = "rbxassetid://116544501716299",
    ["sliders"]         = "rbxassetid://85787771732439",
    ["filter"]          = "rbxassetid://88811660555940",
    ["search"]          = "rbxassetid://92010083223634",

    ["message-circle"]  = "rbxassetid://96145330292478",
    ["message-square"]  = "rbxassetid://96145330292478",
    ["webhook"]         = "rbxassetid://92181172123618",
    ["send"]            = "rbxassetid://113692007244654",
    ["share"]           = "rbxassetid://129280608535523",

    ["sword"]           = "rbxassetid://132405197863294",
    ["shield"]          = "rbxassetid://75954432775071",
    ["shield-check"]    = "rbxassetid://75954432775071",
    ["zap"]             = "rbxassetid://102881251417484",
    ["flame"]           = "rbxassetid://98218034436456",
    ["bomb"]            = "rbxassetid://139223800924636",
    ["target"]          = "rbxassetid://134242818164054",
    ["crosshair"]       = "rbxassetid://134242818164054",
    ["award"]           = "rbxassetid://132740088158419",
    ["trophy"]          = "rbxassetid://132740088158419",
    ["star"]            = "rbxassetid://120318414957104",
    ["gem"]             = "rbxassetid://105846996304890",
    ["coins"]           = "rbxassetid://116510979641930",
    ["backpack"]        = "rbxassetid://140420225386018",
    ["bag"]             = "rbxassetid://140420225386018",
    ["box"]             = "rbxassetid://101768155599700",
    ["package"]         = "rbxassetid://101768155599700",
    ["bot"]             = "rbxassetid://80451686744860",
    ["cpu"]             = "rbxassetid://77549309870247",
    ["wand"]            = "rbxassetid://91872927606406",
    ["magic"]           = "rbxassetid://91872927606406",

    ["compass"]         = "rbxassetid://115123411028382", 
    ["navigation"]      = "rbxassetid://115123411028382",
    ["globe"]           = "rbxassetid://76231597751076",
    ["home"]            = "rbxassetid://136249099949073",

    ["chart-bar"]       = "rbxassetid://105389816384108",
    ["trending-up"]     = "rbxassetid://88268905998571",
    ["trending-down"]   = "rbxassetid://107217459044963",
    ["database"]        = "rbxassetid://126791525623846",
    ["layers"]          = "rbxassetid://138929929862605",

    ["image"]           = "rbxassetid://80808285757226",
    ["video"]           = "rbxassetid://81719056173960",
    ["music"]           = "rbxassetid://134948051536671",
    ["volume"]          = "rbxassetid://111264764438958",

    ["clock"]           = "rbxassetid://121808839832144",
    ["timer"]           = "rbxassetid://126259032907535",
    ["hourglass"]       = "rbxassetid://93205297285245",

    ["user-round"]      = "rbxassetid://95489465399880",
    ["users"]           = "rbxassetid://71907624112229",
    ["person"]          = "rbxassetid://95489465399880",
    ["baby"]            = "rbxassetid://93472926933440",
    ["cat"]             = "rbxassetid://124252153404931",
    ["dog"]             = "rbxassetid://71920105558570",
    ["bird"]            = "rbxassetid://132284145117371",
    ["fish-symbol"]     = "rbxassetid://118475177681618",

    ["tree"]            = "rbxassetid://98218034436456",
    ["leaf"]            = "rbxassetid://74925550436750",
    ["flower"]          = "rbxassetid://86129438272762",
    ["droplet"]         = "rbxassetid://100597455015098",
    ["cloud"]           = "rbxassetid://121226497050352",
    ["sun"]             = "rbxassetid://86114208148727",
    ["moon"]            = "rbxassetid://71938114737914",
    ["snowflake"]       = "rbxassetid://72307126270226",
    ["lightning"]       = "rbxassetid://133517088924849",

    ["apple"]           = "rbxassetid://104349242902442",
    ["banana"]          = "rbxassetid://140713420056179",
    ["cherry"]          = "rbxassetid://139519182403183",
    ["beer"]            = "rbxassetid://116404978807744",
    ["coffee"]          = "rbxassetid://106864403231093",
    ["cookie"]          = "rbxassetid://73159504540002",
    ["candy"]           = "rbxassetid://107812129154678",
    ["wine"]            = "rbxassetid://131675403196921",
    ["beef"]            = "rbxassetid://105850162318915",

    ["wrench"]          = "rbxassetid://108644821412796",
    ["hammer"]          = "rbxassetid://100203029845919",
    ["scissors"]        = "rbxassetid://116344601101413",
    ["pen"]             = "rbxassetid://104622936345006",
    ["trash"]           = "rbxassetid://126279426372342",
    ["bug"]             = "rbxassetid://83626408925438",
    ["key"]             = "rbxassetid://116024426170705",
    ["flag"]            = "rbxassetid://78183383236196",
    ["bookmark"]        = "rbxassetid://121093149326239",
    ["tag"]             = "rbxassetid://116620312917084",
    ["heart"]           = "rbxassetid://112788845135284",
    ["thumbs-up"]       = "rbxassetid://82004462003936",
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
    for name, url in pairs(RawPacks) do
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
        pcall(function()
            writefile("nexthub_icons.json", HttpService:JSONEncode(IconCache))
        end)
    end
end

local function GetIcon(name)
    if type(name) ~= "string" then return "" end

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
-- NEXTHUB UI: UTILITIES
-- ==========================================
local Connections = {}

local function MakeDraggable(topbarobject, object)
	local Dragging    = false
	local DragInput   = nil
	local DragStart   = nil
	local StartPosition = nil

	local function Update(input)
		local Delta = input.Position - DragStart
		local pos   = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X,
			StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
		TweenService:Create(object, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = pos}):Play()
	end

	table.insert(Connections, topbarobject.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Dragging      = true
			DragStart     = input.Position
			StartPosition = object.Position
			local connection
			connection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					Dragging = false
					if connection then connection:Disconnect() end
				end
			end)
		end
	end))

	table.insert(Connections, topbarobject.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			DragInput = input
		end
	end))

	table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
		if input == DragInput and Dragging then Update(input) end
	end))
end

local function Create(className, properties)
	local instance = Instance.new(className)
	for k, v in pairs(properties) do instance[k] = v end
	return instance
end

local ConfigData = {}
local function loadConfig()
	if isfile and readfile then
		local success, data = pcall(function()
			return HttpService:JSONDecode(readfile("NextHubConfig.json"))
		end)
		if success then ConfigData = data end
	end
end
local function saveConfig()
	if writefile then
		pcall(function() writefile("NextHubConfig.json", HttpService:JSONEncode(ConfigData)) end)
	end
end

local function GetHiddenContainer()
	if type(gethui) == "function" then
		local success, container = pcall(gethui)
		if success and container then return container end
	end
	local SuccessCore, CoreGui = pcall(function() return game:GetService("CoreGui") end)
	if SuccessCore and CoreGui then return CoreGui end
	if type(syn) == "function" and type(syn.protect_gui) == "function" then
		local container = Instance.new("ScreenGui")
		pcall(syn.protect_gui, container)
		container.Parent = game:GetService("CoreGui")
		return container
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

-- ==========================================
-- NEXTHUB UI: MAIN WINDOW
-- ==========================================
function NextHub:CreateWindow(props)
	props   = props or {}
	local title   = props.Title   or "NextHub"
	local logo    = props.Logo    or "rbxassetid://111607497408853"
	local version = props.Version or "1.0.0"
	local gameName = props.Game   or "Unknown"
	local Mode    = props.Mode    or "Free"
	local Update  = props.Update  or "Beta"

	local ScreenGui = Create("ScreenGui", {
		Name             = HttpService:GenerateGUID(false),
		Parent           = GetHiddenContainer(),
		ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn     = false,
		IgnoreGuiInset = true,
	})

	local InitialSize     = UDim2.new(0, DS.WindowW, 0, DS.WindowH)
	local InitialPosition = UDim2.new(0.5, -DS.WindowW / 2, 0.5, -DS.WindowH / 2)

	local MainFrame = Create("Frame", {
		Name                  = "MainFrame",
		Parent                = ScreenGui,
		BackgroundColor3      = Style.DarkBg,
		BackgroundTransparency = 0.1,
		BorderSizePixel       = 0,
		Position              = InitialPosition,
		Size                  = InitialSize,
		ClipsDescendants      = true,
	})
	Create("UICorner",  { CornerRadius = UDim.new(0, 10), Parent = MainFrame })
	Create("UIStroke",  { Color = Style.Primary, Thickness = 1.7, Transparency = 0.2, Parent = MainFrame })

	local header = Create("Frame", {
		Size                  = UDim2.new(1, 0, 0, DS.HeaderH),
		BackgroundTransparency = 1,
		Parent                = MainFrame,
	})
	MakeDraggable(header, MainFrame)

	local headerLogo = Create("ImageLabel", {
		Image                 = logo,
		Size                  = UDim2.fromOffset(DS.LogoSz, DS.LogoSz),
		Position              = UDim2.fromOffset(6, (DS.HeaderH - DS.LogoSz) / 2),
		BackgroundTransparency = 1,
		ScaleType             = Enum.ScaleType.Fit,
		Parent                = header,
	})

	local currentX = 6 + DS.LogoSz + 8

	if Mode == "Premium" then
		Create("TextLabel", {
			Text                  = "|",
			Size                  = UDim2.new(0, 0, 0, DS.HeaderH),
			Position              = UDim2.fromOffset(currentX, 0),
			BackgroundTransparency = 1,
			FontFace              = GetFont(Enum.FontWeight.Bold),
			TextSize              = DS.FontHeader,
			TextXAlignment        = Enum.TextXAlignment.Left,
			TextColor3            = Style.TextDim,
			Parent                = header,
		})
		currentX = currentX + 15
		Create("ImageLabel", {
			Image                 = GetIcon("crown"),
			Size                  = UDim2.fromOffset(DS.FontTitle, DS.FontTitle),
			Position              = UDim2.new(0, currentX, 0.5, -DS.FontTitle / 2),
			BackgroundTransparency = 1,
			ImageColor3           = Color3.fromRGB(255, 215, 0),
			Parent                = header,
		})
		currentX = currentX + DS.FontHeader + 4
		local premLabel = Create("TextLabel", {
			Text                  = "Premium",
			Size                  = UDim2.new(0, 0, 0, DS.HeaderH),
			Position              = UDim2.fromOffset(currentX, 0),
			BackgroundTransparency = 1,
			FontFace              = GetFont(Enum.FontWeight.Bold),
			TextSize              = DS.FontHeader,
			TextXAlignment        = Enum.TextXAlignment.Left,
			TextColor3            = Color3.fromRGB(255, 215, 0),
			Parent                = header,
		})
		currentX = currentX + premLabel.TextBounds.X + 5
	else
		Create("TextLabel", {
			Text                  = "|",
			Size                  = UDim2.new(0, 0, 0, DS.HeaderH),
			Position              = UDim2.fromOffset(currentX, 0),
			BackgroundTransparency = 1,
			FontFace              = GetFont(Enum.FontWeight.Bold),
			TextSize              = DS.FontHeader,
			TextXAlignment        = Enum.TextXAlignment.Left,
			TextColor3            = Style.TextDim,
			Parent                = header,
		})
		currentX = currentX + 15
		Create("ImageLabel", {
			Image                 = GetIcon("sparkles"),
			Size                  = UDim2.fromOffset(DS.FontTitle, DS.FontTitle),
			Position              = UDim2.new(0, currentX, 0.5, -DS.FontTitle / 2),
			BackgroundTransparency = 1,
			ImageColor3           = Color3.fromRGB(150, 200, 255),
			Parent                = header,
		})
		currentX = currentX + DS.FontHeader + 4
		local freeLabel = Create("TextLabel", {
			Text                  = "Free",
			Size                  = UDim2.new(0, 0, 0, DS.HeaderH),
			Position              = UDim2.fromOffset(currentX, 0),
			BackgroundTransparency = 1,
			FontFace              = GetFont(Enum.FontWeight.Bold),
			TextSize              = DS.FontHeader,
			TextXAlignment        = Enum.TextXAlignment.Left,
			TextColor3            = Color3.fromRGB(150, 200, 255),
			Parent                = header,
		})
		currentX = currentX + freeLabel.TextBounds.X + 5
	end

	local statusText, statusColor
	if Update == "Stable" then
		statusText  = "STABLE" ; statusColor = Color3.fromRGB(40, 190, 100)
	elseif Update == "Hotfix" then
		statusText  = "HOTFIX" ; statusColor = Color3.fromRGB(160, 100, 255)
	else
		statusText  = "BETA"   ; statusColor = Style.HeaderBadge
	end

	local temp = Create("TextLabel", { Text = statusText, FontFace = GetFont(Enum.FontWeight.SemiBold), TextSize = DS.FontBadge, Visible = false, Parent = header })
	local badgeW = temp.TextBounds.X + 16
	temp:Destroy()

	local statusBadge = Create("TextLabel", {
		Size                  = UDim2.new(0, badgeW, 0, DS.FontBadge + 7),
		Position              = UDim2.new(0, currentX + 10, 0.5, -(DS.FontBadge + 7) / 2),
		BackgroundColor3      = statusColor,
		TextColor3            = Style.Text,
		Text                  = statusText,
		FontFace              = GetFont(Enum.FontWeight.SemiBold),
		TextSize              = DS.FontBadge,
		TextXAlignment        = Enum.TextXAlignment.Center,
		Parent                = header,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = statusBadge })
	currentX = currentX + badgeW + 20

	local versionText = version
	
	local tmp = Create("TextLabel", { Text = versionText, FontFace = GetFont(Enum.FontWeight.SemiBold), TextSize = DS.FontBadge, Visible = false, Parent = header})
	local versionW = tmp.TextBounds.X + 16
	tmp:Destroy()
	
	local versionBadge = Create("TextLabel", {
		Text                  = versionText,
		Size                  = UDim2.new(0, versionW, 0, DS.FontBadge + 7),
		Position              = UDim2.new(0, currentX, 0.5, -(DS.FontBadge + 7) / 2),
		BackgroundColor3      = Color3.fromRGB(255, 165, 0),
		TextColor3            = Style.Text,
		FontFace              = GetFont(Enum.FontWeight.SemiBold),
		TextSize              = DS.FontBadge,
		TextXAlignment        = Enum.TextXAlignment.Center,
		TextYAlignment        = Enum.TextYAlignment.Center,
		Parent                = header,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = versionBadge })

	local btnSz = DS.HeaderH - 22
	local closeBtn = Create("ImageButton", {
		Size                  = UDim2.fromOffset(btnSz + 7, btnSz + 7),
		Position              = UDim2.new(1, -34, 0.5, -(btnSz + 7) / 2),
		BackgroundTransparency = 1,
		Image                 = GetIcon("x"),
		ImageColor3           = Color3.fromRGB(190, 220, 255),
		ScaleType             = Enum.ScaleType.Fit,
		ZIndex                = 10,
		Active                = true,
		Parent                = header,
	})
	closeBtn.Activated:Connect(function()
		TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
			{ Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }):Play()
		task.wait(0.3)
		ScreenGui:Destroy()
	end)

	local minimizeBtn = Create("ImageButton", {
		Size                  = UDim2.fromOffset(btnSz + 7, btnSz + 7),
		Position              = UDim2.new(1, -66, 0.5, -(btnSz + 7) / 2),
		BackgroundTransparency = 1,
		Image                 = GetIcon("minus"),
		ImageColor3           = Color3.fromRGB(190, 220, 255),
		ScaleType             = Enum.ScaleType.Fit,
		ZIndex                = 10,
		Active                = true,
		Parent                = header,
	})

	local IsMinimized = false
	local toggleBtn = Create("ImageButton", {
		Name                  = "ToggleUI",
		Parent                = ScreenGui,
		BackgroundColor3      = Style.DarkBg,
		BorderSizePixel       = 0,
		Position              = UDim2.new(0.1, 0, 0.1, 0),
		Size                  = UDim2.new(0, DS.HeaderH + 3, 0, DS.HeaderH + 3),
		Image                 = "rbxassetid://111607497408853",
		ImageColor3           = Style.Text,
		Visible               = true,
		Active                = true,
		AutoButtonColor       = false,
		Selectable            = true,
		ZIndex                = 100,
	})
	MakeDraggable(toggleBtn, toggleBtn)
	Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = toggleBtn })
	Create("UIStroke",  { Color = Style.InputStroke, Thickness = 1, Parent = toggleBtn })

	local function ToggleUI()
		IsMinimized = not IsMinimized
		if IsMinimized then
			MainFrame.Visible = false
			TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
				{ Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }):Play()
		else
			MainFrame.Visible = true
			MainFrame.Size = UDim2.new(0, 0, 0, 0)
			TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Size = InitialSize, BackgroundTransparency = 0.1 }):Play()
		end
	end
	toggleBtn.Activated:Connect(ToggleUI)
	minimizeBtn.Activated:Connect(ToggleUI)

	local Sidebar = Create("Frame", {
		Name                  = "Sidebar",
		Parent                = MainFrame,
		BackgroundColor3      = Style.SidebarBg,
		BackgroundTransparency = 1,
		BorderSizePixel       = 0,
		Position              = UDim2.new(0, 0, 0, DS.HeaderH - 15),
		Size                  = UDim2.new(0, DS.SidebarW, 1, -(DS.HeaderH - 15)),
	})

	local TabContainer = Create("ScrollingFrame", {
		Name                  = "TabContainer",
		Parent                = Sidebar,
		Active                = true,
		BackgroundTransparency = 1,
		BorderSizePixel       = 0,
		Position              = UDim2.new(0, 0, 0, 15),
		Size                  = UDim2.new(1, 0, 1, -25),
		CanvasSize            = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize   = Enum.AutomaticSize.Y,
		ScrollingDirection    = Enum.ScrollingDirection.Y,
		ScrollBarThickness    = 0,
		ScrollBarImageColor3  = Style.Primary,
	})

	local ButtonsHolder = Create("Frame", {
		Name                  = "ButtonsHolder",
		Parent                = TabContainer,
		BackgroundTransparency = 1,
		Size                  = UDim2.new(1, 0, 1, 0),
		AutomaticSize         = Enum.AutomaticSize.Y,
	})
	Create("UIListLayout", { Parent = ButtonsHolder, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5) })
	Create("UIPadding", { Parent = ButtonsHolder, PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7) })

	local SlidingIndicator = Create("Frame", {
		Name                  = "SlidingIndicator",
		Parent                = TabContainer,
		BackgroundColor3      = Style.Primary,
		BorderSizePixel       = 0,
		Position              = UDim2.new(0, 0, 0, 0),
		Size                  = UDim2.new(0, 4, 0, DS.TabBtnH - 12),
		Visible               = false,
		ZIndex                = 2,
	})
	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SlidingIndicator })

	local ContentContainer = Create("Frame", {
		Name                  = "ContentContainer",
		Parent                = MainFrame,
		BackgroundTransparency = 0.7,
		BackgroundColor3      = Style.InputStroke,
		Position              = UDim2.new(0, DS.SidebarW, 0, DS.HeaderH),
		Size                  = UDim2.new(1, -DS.SidebarW, 1, -DS.HeaderH),
		ClipsDescendants      = true,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = ContentContainer })

	local gameNameLabel = Create("TextLabel", {
		Name                  = "TabBtn_GameName",
		Size                  = UDim2.new(1, 0, 0, DS.TabBtnH - 2),
		BackgroundColor3      = Color3.fromRGB(50, 50, 50),
		TextColor3            = Style.Primary,
		Text                  = "Game: " .. gameName,
		TextSize              = DS.FontBadge - 1,
		FontFace              = GetFont(Enum.FontWeight.Bold),
		BackgroundTransparency = 0.2,
		TextWrapped           = true,
		Parent                = ButtonsHolder,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = gameNameLabel })

	local Window = {
		Tabs        = {},
		TabButtons  = {},
		TabContents = {},
		Elements    = {},
		__tabChanged = Instance.new("BindableEvent"),
	}

	local NotificationHolder = Create("Frame", {
		Name                   = "NotificationHolder",
		Parent                 = ScreenGui,
		BackgroundTransparency = 1,
		Position               = UDim2.new(1, -20, 1, -20),
		Size                   = UDim2.new(0, DS.NotifyW, 1, -20),
		AnchorPoint            = Vector2.new(1, 1),
		ZIndex                 = 100,
	})

	Create("UIListLayout", {
		Parent             = NotificationHolder,
		SortOrder          = Enum.SortOrder.LayoutOrder,
		VerticalAlignment  = Enum.VerticalAlignment.Bottom,
		Padding            = UDim.new(0, 8),
	})

	function Window:Notify(options)
		options = options or {}
		local Title    = options.Title    or "Notification"
		local Content  = options.Content  or "Message"
		local Duration = options.Duration or 3

		local NotifyFrame = Create("Frame", {
			Name                   = "NotifyFrame",
			Parent                 = NotificationHolder,
			BackgroundColor3       = Style.DarkBg,
			BackgroundTransparency = 0.05,
			Size                   = UDim2.fromOffset(DS.NotifyW, DS.NotifyH),
			ClipsDescendants       = true,
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = NotifyFrame })
		Create("UIStroke", { Color = Style.Primary, Transparency = 0.5, Thickness = 1.2, Parent = NotifyFrame })

		local Icon = Create("ImageLabel", {
			Parent                 = NotifyFrame,
			BackgroundTransparency = 1,
			AnchorPoint            = Vector2.new(0, 0.5),
			Position               = UDim2.new(0, 10, 0.5, 0),
			Size                   = UDim2.fromOffset(DS.NotifyIcon, DS.NotifyIcon),
			Image                  = GetIcon("bell"),
			ImageColor3            = Style.Primary,
		})

		local TextContainer = Create("Frame", {
			Parent                 = NotifyFrame,
			BackgroundTransparency = 1,
			AnchorPoint            = Vector2.new(0, 0.5),
			Position               = UDim2.new(0, DS.NotifyIcon + 18, 0.5, 0),
			Size                   = UDim2.new(1, -(DS.NotifyIcon + 25), 1, 0),
		})

		local TextLayout = Create("UIListLayout", {
			Parent             = TextContainer,
			SortOrder          = Enum.SortOrder.LayoutOrder,
			VerticalAlignment  = Enum.VerticalAlignment.Center,
			Padding            = UDim.new(0, 0),
		})

		local TitleLabel = Create("TextLabel", {
			Parent                 = TextContainer,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 0, DS.NotifyFontT + 2),
			FontFace               = GetFont(Enum.FontWeight.Bold),
			Text                   = Title,
			TextColor3             = Style.Text,
			TextSize               = DS.NotifyFontT,
			TextXAlignment         = Enum.TextXAlignment.Left,
			TextTruncate           = Enum.TextTruncate.AtEnd,
			LayoutOrder            = 1,
		})

		local ContentLabel = Create("TextLabel", {
			Parent                 = TextContainer,
			BackgroundTransparency = 1,
			Size                   = UDim2.new(1, 0, 0, 0),
			AutomaticSize          = Enum.AutomaticSize.Y,
			FontFace               = GetFont(Enum.FontWeight.Regular),
			Text                   = Content,
			TextColor3             = Style.TextDim,
			TextSize               = DS.NotifyFontC,
			TextXAlignment         = Enum.TextXAlignment.Left,
			TextWrapped            = true,
			LayoutOrder            = 2,
		})

		local ProgressBar = Create("Frame", {
			Parent           = NotifyFrame,
			BackgroundColor3 = Style.Primary,
			BorderSizePixel  = 0,
			Position         = UDim2.new(0, 0, 1, -2),
			Size             = UDim2.new(1, 0, 0, 2),
		})

		NotifyFrame.Position = UDim2.new(0, DS.NotifyW + 20, 0, 0)
		TweenService:Create(NotifyFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint), { Position = UDim2.new(0, 0, 0, 0) }):Play()
		TweenService:Create(ProgressBar, TweenInfo.new(Duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()

		task.delay(Duration, function()
			local Tw = TweenService:Create(NotifyFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
				Position = UDim2.new(0, DS.NotifyW + 20, 0, 0)
			})
			Tw:Play()
			Tw.Completed:Wait()
			NotifyFrame:Destroy()
		end)
	end

	function Window:LoadConfig(name)
		for key, data in pairs(Window.Elements) do
			if ConfigData[key] ~= nil then
				pcall(function() data.Object:Set(ConfigData[key]) end)
			end
		end
		self:Notify({ Title = "Config", Content = "Loaded Successfully" })
	end

	-- ==========================================
	-- INTERNAL RIGHT PANEL
	-- ==========================================
	local PanelWidth   = DS.PanelW
	local PanelMargin  = 10
	local HeaderHeight = DS.HeaderH

	local DropdownPanel = Create("Frame", {
		Name                  = "InternalDropdownPanel",
		Parent                = MainFrame,
		BackgroundTransparency = 0.2,
		BackgroundColor3      = Style.SidebarBg,
		BorderSizePixel       = 0,
		Position              = UDim2.new(1, 0, 0, HeaderHeight),
		Size                  = UDim2.new(0, PanelWidth, 1, -(HeaderHeight + PanelMargin * 2)),
		ZIndex                = 50,
		Visible               = false,
		ClipsDescendants      = true,
	})
	Create("UIPadding",  { Parent = DropdownPanel, PaddingBottom = UDim.new(0, 10) })
	Create("UICorner",   { CornerRadius = UDim.new(0, 10), Parent = DropdownPanel })

	local PanelHeader = Create("Frame", {
		Parent                = DropdownPanel,
		BackgroundColor3      = Style.DarkBg,
		BackgroundTransparency = 0.15,
		BorderSizePixel       = 0,
		Size                  = UDim2.new(1, 0, 0, DS.DDHeader),
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = PanelHeader })

	local PanelTitle = Create("TextLabel", {
		Parent                = PanelHeader,
		BackgroundTransparency = 1,
		Size                  = UDim2.new(1, -DS.DDHeader, 1, 0),
		Position              = UDim2.new(0, 15, 0, 0),
		FontFace              = GetFont(Enum.FontWeight.Bold),
		TextColor3            = Style.Primary,
		TextSize              = DS.FontBase,
		TextXAlignment        = Enum.TextXAlignment.Center,
	})

	local CloseBtn = Create("ImageButton", {
		Parent                = PanelHeader,
		BackgroundTransparency = 1,
		Position              = UDim2.new(1, -30, 0.5, -10),
		Size                  = UDim2.new(0, 20, 0, 20),
		Image                 = GetIcon("x"),
		ImageColor3           = Style.TextDim,
		ZIndex                = 51,
	})

	local SearchBox = Create("TextBox", {
		Parent                = DropdownPanel,
		BackgroundColor3      = Style.InputBg,
		BackgroundTransparency = 0.5,
		PlaceholderText       = "Search...",
		Text                  = "",
		PlaceholderColor3     = Style.TextDim,
		TextColor3            = Style.Text,
		FontFace              = GetFont(Enum.FontWeight.Medium),
		TextSize              = DS.FontBase - 1,
		Position              = UDim2.new(0, DS.Padding, 0, (DS.DDHeader + 5)),
		Size                  = UDim2.new(1, -(DS.Padding * 2), 0, DS.InputH),
		ZIndex                = 51,
		Visible               = false,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = SearchBox })
	Create("UIPadding", { Parent = SearchBox, PaddingLeft = UDim.new(0, 8) })

	-- ==========================================
	-- MULTI-SELECT
	-- ==========================================
	local ApplyBtn = Create("TextButton", {
		Parent                = DropdownPanel,
		BackgroundColor3      = Style.Primary,
		BackgroundTransparency = 0.1,
		Position              = UDim2.new(0, 10, 1, -24),
		Size                  = UDim2.new(1, -20, 0, 24),
		FontFace              = GetFont(Enum.FontWeight.Bold),
		Text                  = "Apply",
		TextColor3            = Style.Text,
		TextSize              = DS.FontBase,
		ZIndex                = 52,
		Visible               = false,
		Active                = true,
		AutoButtonColor       = false,
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = ApplyBtn })

	local PanelList = Create("ScrollingFrame", {
		Parent                = DropdownPanel,
		BackgroundTransparency = 1,
		BorderSizePixel       = 0,
		Position              = UDim2.new(0, 0, 0, 45),
		Size                  = UDim2.new(1, 0, 1, -45),
		CanvasSize            = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize   = Enum.AutomaticSize.Y,
		ScrollingDirection    = Enum.ScrollingDirection.Y,
		ScrollBarThickness    = 2,
		ScrollBarImageColor3  = Style.Primary,
		ZIndex                = 51,
	})
	Create("UIListLayout", { Parent = PanelList, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) })
	Create("UIPadding", { Parent = PanelList, PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })

	local IsPanelOpen         = false
	local CurrentPanelCallback = nil
	local PanelIsMulti        = false
	local PanelMultiSelected  = {}

	local function CloseDropdownPanel()
		if not IsPanelOpen then return end
		IsPanelOpen = false
		TweenService:Create(DropdownPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
			Position = UDim2.new(1, 0, 0, HeaderHeight + PanelMargin)
		}):Play()
		task.wait(0.3)
		DropdownPanel.Visible = false
		SearchBox.Text        = ""
		PanelIsMulti          = false
		table.clear(PanelMultiSelected)
	end

	CloseBtn.Activated:Connect(CloseDropdownPanel)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and IsPanelOpen then
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				local mousePos    = input.Position
				local panelAbsPos = DropdownPanel.AbsolutePosition
				local panelAbsSz  = DropdownPanel.AbsoluteSize
				if mousePos.X < panelAbsPos.X or mousePos.X > panelAbsPos.X + panelAbsSz.X or
					mousePos.Y < panelAbsPos.Y or mousePos.Y > panelAbsPos.Y + panelAbsSz.Y then
					if PanelIsMulti and CurrentPanelCallback then
						CurrentPanelCallback(PanelMultiSelected)
					end
					CloseDropdownPanel()
				end
			end
		end
	end)

	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local searchText = SearchBox.Text:lower()
		for _, btn in pairs(PanelList:GetChildren()) do
			if btn:IsA("Frame") then
				local lbl = btn:FindFirstChildWhichIsA("TextLabel")
				if lbl then
					btn.Visible = string.find(lbl.Text:lower(), searchText, 1, true) ~= nil
				end
			end
		end
	end)

	ApplyBtn.Activated:Connect(function()
		if CurrentPanelCallback then
			CurrentPanelCallback(PanelMultiSelected)
		end
		CloseDropdownPanel()
	end)

	-- ==========================================
	-- OpenRightDropdown (Single)
	-- ==========================================
	function Window:OpenRightDropdown(title, items, default, callback, searchEnabled)
		for _, child in pairs(PanelList:GetChildren()) do
			if child:IsA("TextButton") or child:IsA("Frame") then child:Destroy() end
		end

		PanelTitle.Text        = title or "Select"
		CurrentPanelCallback   = callback
		PanelIsMulti           = false
		ApplyBtn.Visible       = false

		SearchBox.Visible = searchEnabled or false
		SearchBox.Text    = ""

		local listTop = searchEnabled and (DS.DDHeader + DS.InputH + (DS.Padding * 2)) or DS.DDHeader
		PanelList.Position = UDim2.new(0, 0, 0, listTop)
		PanelList.Size     = UDim2.new(1, 0, 1, -listTop)

		for _, item in pairs(items) do
			local isSelected = (item == default)
			local ItemBtn    = Create("TextButton", {
				Parent                = PanelList,
				BackgroundColor3      = isSelected and Style.Primary or Style.ElementBackground,
				BackgroundTransparency = isSelected and 0.2 or 0.5,
				Size                  = UDim2.new(1, 0, 0, DS.TabBtnH - 8),
				FontFace              = GetFont(Enum.FontWeight.Medium),
				Text                  = "  " .. item,
				TextColor3            = Style.Text,
				TextSize              = DS.FontBase - 1,
				TextXAlignment        = Enum.TextXAlignment.Left,
				AutoButtonColor       = false,
				ZIndex                = 52,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = ItemBtn })

			ItemBtn.Activated:Connect(function()
				if CurrentPanelCallback then CurrentPanelCallback({ item }) end
				CloseDropdownPanel()
			end)
			ItemBtn.MouseEnter:Connect(function()
				if not isSelected then TweenService:Create(ItemBtn, TweenInfo.new(0.2), { BackgroundColor3 = Style.Hover }):Play() end
			end)
			ItemBtn.MouseLeave:Connect(function()
				if not isSelected then TweenService:Create(ItemBtn, TweenInfo.new(0.2), { BackgroundColor3 = Style.ElementBackground }):Play() end
			end)
		end

		if not IsPanelOpen then
			DropdownPanel.Visible = true
			IsPanelOpen           = true
			DropdownPanel.Position = UDim2.new(1, 0, 0, HeaderHeight)
			TweenService:Create(DropdownPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Position = UDim2.new(1, -(PanelWidth + PanelMargin), 0, HeaderHeight + PanelMargin)
			}):Play()
		end
	end

	-- ==========================================
	-- OpenRightDropdownMulti (Multi-Select)
	-- ==========================================
	function Window:OpenRightDropdownMulti(title, items, currentSelected, callback, searchEnabled)
		for _, child in pairs(PanelList:GetChildren()) do
			if child:IsA("TextButton") or child:IsA("Frame") then child:Destroy() end
		end

		PanelTitle.Text       = title or "Select"
		CurrentPanelCallback  = callback
		PanelIsMulti          = true
		ApplyBtn.Visible      = true

		table.clear(PanelMultiSelected)
		for _, v in pairs(currentSelected or {}) do
			table.insert(PanelMultiSelected, v)
		end

		SearchBox.Visible = searchEnabled or false
		SearchBox.Text    = ""

		local listTop = searchEnabled and (DS.DDHeader + DS.InputH + (DS.Padding * 2)) or DS.DDHeader
		PanelList.Position = UDim2.new(0, 0, 0, listTop)
		PanelList.Size     = UDim2.new(1, 0, 1, -(listTop + 40))

		local function RefreshRows()
			for _, row in pairs(PanelList:GetChildren()) do
				if row:IsA("Frame") then
					local checked   = table.find(PanelMultiSelected, row.Name) ~= nil
					local checkBox  = row:FindFirstChild("CheckBox")
					local checkMark = row:FindFirstChild("CheckMark")
					if checkBox then
						TweenService:Create(checkBox, TweenInfo.new(0.15), {
							BackgroundColor3 = checked and Style.CheckboxOn or Style.CheckboxOff
						}):Play()
					end
					if checkMark then
						checkMark.Visible = checked
					end
				end
			end
		end

		for _, item in pairs(items) do
			local checked = table.find(PanelMultiSelected, item) ~= nil

			local Row = Create("Frame", {
				Name                  = item,
				Parent                = PanelList,
				BackgroundColor3      = Style.ElementBackground,
				BackgroundTransparency = 0.5,
				Size                  = UDim2.new(1, 0, 0, DS.TabBtnH - 6),
				ZIndex                = 52,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Row })

			local CheckBox = Create("Frame", {
				Name             = "CheckBox",
				Parent           = Row,
				BackgroundColor3 = checked and Style.CheckboxOn or Style.CheckboxOff,
				Position         = UDim2.new(1, -30, 0.5, -9),
				Size             = UDim2.new(0, 18, 0, 18),
				ZIndex           = 53,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = CheckBox })

			local CheckMark = Create("ImageLabel", {
				Name                  = "CheckMark",
				Parent                = CheckBox,
				BackgroundTransparency = 1,
				Size                  = UDim2.new(1, -2, 1, -2),
				Position              = UDim2.new(0, 1, 0, 1),
				Image                 = GetIcon("check"),
				ImageColor3           = Style.Text,
				ZIndex                = 54,
				Visible               = checked,
			})

			Create("TextLabel", {
				Parent                = Row,
				BackgroundTransparency = 1,
				Position              = UDim2.new(0, 10, 0, 0),
				Size                  = UDim2.new(1, -44, 1, 0),
				FontFace              = GetFont(Enum.FontWeight.Medium),
				Text                  = item,
				TextColor3            = Style.Text,
				TextSize              = DS.FontBase - 1,
				TextXAlignment        = Enum.TextXAlignment.Left,
				ZIndex                = 53,
			})

			local RowBtn = Create("TextButton", {
				Parent                = Row,
				BackgroundTransparency = 1,
				Size                  = UDim2.new(1, 0, 1, 0),
				Text                  = "",
				ZIndex                = 55,
				Active                = true,
			})

			RowBtn.Activated:Connect(function()
				local idx = table.find(PanelMultiSelected, item)
				if idx then
					table.remove(PanelMultiSelected, idx)
				else
					table.insert(PanelMultiSelected, item)
				end
				RefreshRows()
			end)

			Row.MouseEnter:Connect(function()
				TweenService:Create(Row, TweenInfo.new(0.15), { BackgroundColor3 = Style.Hover }):Play()
			end)
			Row.MouseLeave:Connect(function()
				TweenService:Create(Row, TweenInfo.new(0.15), { BackgroundColor3 = Style.ElementBackground }):Play()
			end)
		end

		if not IsPanelOpen then
			DropdownPanel.Visible  = true
			IsPanelOpen            = true
			DropdownPanel.Position = UDim2.new(1, 0, 0, HeaderHeight)
			TweenService:Create(DropdownPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Position = UDim2.new(1, -(PanelWidth + PanelMargin), 0, HeaderHeight + PanelMargin)
			}):Play()
		end
	end

	local function MoveIndicatorToButton(btn)
		if not SlidingIndicator.Visible then SlidingIndicator.Visible = true end
		local btnAbsPos       = btn.AbsolutePosition
		local containerAbsPos = TabContainer.AbsolutePosition
		TweenService:Create(SlidingIndicator, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(
				btnAbsPos.X - containerAbsPos.X + 6,
				btnAbsPos.Y - containerAbsPos.Y + 6
			)
		}):Play()
	end

	-- ==========================================
	-- TAB COMPONENT
	-- ==========================================
	function Window:AddTab(tabProps)
		local Components      = {}
		local ElementIndex    = 0
		local CurrentGroup
		local LastElementType = nil

		tabProps = tabProps or {}

		local tabTitle = tabProps.Title or "Tab"
		local tabIcon  = tabProps.Icon
		local index    = #self.Tabs + 1

		self.Tabs[index] = tabProps

		local BG_TWEEN = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

		local btn = Create("ImageButton", {
			Name                  = "TabBtn_" .. index,
			Size                  = UDim2.new(1, 0, 0, DS.TabBtnH),
			BackgroundColor3      = (index == 1) and Style.Primary or Color3.fromRGB(50, 50, 50),
			BackgroundTransparency = (index == 1) and 0.75 or 1,
			AutoButtonColor       = false,
			Active                = true,
			Parent                = ButtonsHolder,
		})
		self.TabButtons[index] = btn
		Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = btn })

		if tabIcon then
			Create("ImageLabel", {
				Size                  = UDim2.fromOffset(DS.IconSz + 4, DS.IconSz + 4),
				Position              = UDim2.new(0, DS.Padding + 4, 0.5, -(DS.IconSz + 4) / 2),
				BackgroundTransparency = 1,
				Image                 = GetIcon(tabIcon) or "",
				Parent                = btn,
			})
		end

		Create("TextLabel", {
			Text                  = tabTitle,
			Size                  = UDim2.new(1, -(DS.Padding * 2 + DS.IconSz), 1, 0),
			Position              = UDim2.new(0, tabIcon and (DS.Padding + DS.IconSz + 12) or DS.Padding, 0, 0),
			BackgroundTransparency = 1,
			TextColor3            = Style.Text,
			FontFace              = GetFont(Enum.FontWeight.Medium),
			TextSize              = DS.TabFontSz,
			TextXAlignment        = Enum.TextXAlignment.Left,
			Parent                = btn,
		})

		local content = Create("ScrollingFrame", {
			Name                  = "TabContent_" .. index,
			Size                  = UDim2.new(1, 0, 1, 0),
			CanvasSize            = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize   = Enum.AutomaticSize.Y,
			ScrollBarThickness    = 1.7,
			ScrollBarImageColor3  = Style.Primary,
			ScrollingDirection    = Enum.ScrollingDirection.Y,
			BackgroundTransparency = 1,
			Visible               = (index == 1),
			Parent                = ContentContainer,
		})
		self.TabContents[index] = content

		Create("UIListLayout", { Parent = content, SortOrder = Enum.SortOrder.LayoutOrder })
		Create("UIPadding", {
			PaddingTop    = UDim.new(0, 12),
			PaddingLeft   = UDim.new(0, 12),
			PaddingRight  = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 12),
			Parent        = content,
		})

		local function AddDivider()
			if not CurrentGroup then return end
			local Divider = Create("Frame", {
				Parent                = CurrentGroup,
				BackgroundColor3      = Style.Outline,
				BackgroundTransparency = 0.3,
				BorderSizePixel       = 0,
				Size                  = UDim2.new(1, 0, 0, 1.5),
				LayoutOrder           = ElementIndex,
			})
			Create("UIPadding", { Parent = Divider, PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) })
		end

		local function ActivateTab()
			Window.__tabChanged:Fire()
			for i, c in ipairs(self.TabContents) do
				local active = (i == index)
				local b      = self.TabButtons[i]
				c.Visible    = active
				TweenService:Create(b, BG_TWEEN, {
					BackgroundTransparency = active and 0.75 or 1,
					BackgroundColor3       = active and Style.Primary or Color3.fromRGB(50, 50, 50),
				}):Play()
			end
			MoveIndicatorToButton(btn)
		end

		btn.Activated:Connect(function() ActivateTab() end)
		if index == 1 then task.wait() ; ActivateTab() end

		-- ==========================================
		-- SECTION COMPONENT
		-- ==========================================
		function Components:AddSection(props)
			props = props or {}
			local SectionTitle = props.Title or "Section"
			local Icon         = props.Icon

			ElementIndex = ElementIndex + 1

			local SectionContainer = Create("Frame", {
				Parent                = content,
				BackgroundTransparency = 1,
				Size                  = UDim2.new(1, 0, 0, 28),
				LayoutOrder           = ElementIndex,
			})

			local CurrentX = 0
			if Icon then
				Create("ImageLabel", {
					Parent                = SectionContainer,
					BackgroundTransparency = 1,
					Position              = UDim2.new(0, 0, 0.5, -9),
					Size                  = UDim2.new(0, 18, 0, 18),
					Image                 = GetIcon(Icon),
					ImageColor3           = Style.Primary,
				})
				CurrentX = 24
			end

			CurrentGroup = Create("Frame", {
				AutomaticSize         = Enum.AutomaticSize.Y,
				Size                  = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 0.5,
				BackgroundColor3      = Style.ElementBackground,
				Parent                = content,
				LayoutOrder           = ElementIndex,
			})
			Create("UIListLayout", { Parent = CurrentGroup, SortOrder = Enum.SortOrder.LayoutOrder })
			Create("UICorner",     { Parent = CurrentGroup, CornerRadius = UDim.new(0, 5) })

			local Label = Create("TextLabel", {
				Name                  = "SectionLabel",
				Parent                = SectionContainer,
				BackgroundTransparency = 1,
				Position              = UDim2.new(0, CurrentX, 0, 0),
				Size                  = UDim2.new(0, 0, 1, 0),
				AutomaticSize         = Enum.AutomaticSize.X,
				FontFace              = GetFont(Enum.FontWeight.Bold),
				Text                  = SectionTitle,
				TextColor3            = Style.Primary,
				TextSize              = DS.FontBase - 1,
				TextXAlignment        = Enum.TextXAlignment.Left,
			})

			task.delay(0.05, function()
				local LineX   = CurrentX + Label.TextBounds.X + 10
				local Sep     = Create("Frame", {
					Parent           = SectionContainer,
					BackgroundColor3 = Style.Primary,
					BorderSizePixel  = 0,
					Position         = UDim2.new(0, LineX, 0.5, 0),
					Size             = UDim2.new(1, -LineX, 0.05, 1),
				})
				Create("UICorner", { CornerRadius = UDim.new(0.8, 0), Parent = Sep })
			end)

			LastElementType = "Section"
			return { Frame = SectionContainer }
		end

		-- ==========================================
		-- PARAGRAPH COMPONENT
		-- ==========================================
		function Components:AddParagraph(props)
			props = props or {}

			if LastElementType == "Component" then AddDivider() end
			ElementIndex = ElementIndex + 1

			local ParagraphFrame = Create("Frame", {
				Name                  = "ParagraphFrame",
				Parent                = CurrentGroup,
				BackgroundTransparency = 1,
				BorderSizePixel       = 0,
				Size                  = UDim2.new(1, 0, 0, 0),
				AutomaticSize         = Enum.AutomaticSize.Y,
				LayoutOrder           = ElementIndex,
			})

			local Padding = Create("UIPadding", {
				PaddingTop    = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
				PaddingLeft   = UDim.new(0, 12),
				PaddingRight  = UDim.new(0, 12),
				Parent        = ParagraphFrame,
			})

			local TitleLabel = nil
			if (props.Title or "") ~= "" then
				TitleLabel = Create("TextLabel", {
					Parent                = ParagraphFrame,
					BackgroundTransparency = 1,
					Size                  = UDim2.new(1, 0, 0, 20),
					FontFace              = GetFont(Enum.FontWeight.SemiBold),
					Text                  = props.Title,
					TextColor3            = Style.Primary,
					TextSize              = DS.FontTitle,
					TextXAlignment        = Enum.TextXAlignment.Left,
					TextYAlignment        = Enum.TextYAlignment.Top,
				})
			end

			local TextLabel = Create("TextLabel", {
				Size                  = UDim2.new(1, 0, 0, 0),
				AutomaticSize         = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				TextWrapped           = true,
				RichText              = true,
				TextYAlignment        = Enum.TextYAlignment.Top,
				TextXAlignment        = Enum.TextXAlignment.Left,
				TextColor3            = props.Color or Style.Text,
				FontFace              = GetFont(Enum.FontWeight.Medium),
				TextSize              = props.TextSize or DS.FontBase,
				Text                  = props.Text or "Paragraph text goes here...",
				Parent                = ParagraphFrame,
			})

			if TitleLabel then
				Create("UIListLayout", { Parent = ParagraphFrame, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder })
				TitleLabel.LayoutOrder = 1
				TextLabel.LayoutOrder  = 2
				Padding:Destroy()
				Create("UIPadding", {
					PaddingTop    = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
					PaddingLeft   = UDim.new(0, 12), PaddingRight  = UDim.new(0, 12),
					Parent        = ParagraphFrame,
				})
			end

			LastElementType = "Component"
			local Obj = { Frame = ParagraphFrame }
			function Obj:SetText(t) TextLabel.Text = t end
			return Obj
		end

		-- ==========================================
		-- BUTTON COMPONENT
		-- ==========================================
		function Components:AddButton(props)
			props = props or {}

			if LastElementType == "Component" then AddDivider() end
			ElementIndex = ElementIndex + 1

			local FrameH  = props.Desc and DS.CompHDesc or DS.CompH
			local Callback = props.Callback or function() end

			local ButtonFrame = Create("Frame", {
				Name                  = "ButtonFrame",
				Parent                = CurrentGroup,
				BackgroundTransparency = 1,
				BorderSizePixel       = 0,
				Size                  = UDim2.new(1, 0, 0, FrameH),
				LayoutOrder           = ElementIndex,
				Active                = true,
			})

			Create("ImageLabel", {
				BackgroundTransparency = 1,
				Image                 = GetIcon("mouse-pointer-2"),
				Position              = UDim2.new(1, -32, 0.5, 0),
				AnchorPoint           = Vector2.new(0, 0.5),
				ImageColor3           = Style.Primary,
				Size                  = UDim2.fromOffset(DS.FontBase + 4, DS.FontBase + 4),
				ScaleType             = Enum.ScaleType.Fit,
				Parent                = ButtonFrame,
			})

			local TextLabel = Create("TextLabel", {
				Text                  = props.Title or "Button",
				Size                  = UDim2.new(0.5, -12, props.Desc and 0 or 1, 0),
				Position              = props.Desc and UDim2.new(0, DS.Padding, 0, 6) or UDim2.new(0, DS.Padding, 0.5, 0),
				AnchorPoint           = props.Desc and Vector2.new(0, 0) or Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				FontFace              = GetFont(Enum.FontWeight.SemiBold),
				TextSize              = DS.FontTitle,
				TextColor3            = Style.Primary,
				TextXAlignment        = Enum.TextXAlignment.Left,
				TextYAlignment        = props.Desc and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
				Parent                = ButtonFrame,
			})

			if props.Desc then
				Create("TextLabel", {
					Text                  = props.Desc,
					Size                  = UDim2.new(0.5, -12, 0, 20),
					Position              = UDim2.new(0, DS.Padding, 0, DS.FontTitle + 6),
					AnchorPoint           = Vector2.new(0, 0),
					BackgroundTransparency = 1,
					FontFace              = GetFont(Enum.FontWeight.Regular),
					TextSize              = DS.FontDesc,
					TextColor3            = Style.TextDim,
					TextXAlignment        = Enum.TextXAlignment.Left,
					TextWrapped           = false,
					Parent                = ButtonFrame,
				})
			end

			local ClickBtn = Create("TextButton", {
				Parent                = ButtonFrame,
				BackgroundTransparency = 1,
				Size                  = UDim2.new(1, 0, 1, 0),
				Text                  = "",
				ZIndex                = 10,
				Active                = true,
			})
			ClickBtn.Activated:Connect(function()
				if typeof(Callback) == "function" then Callback() end
			end)

			LastElementType = "Component"
			local Obj = { Frame = ButtonFrame }
			function Obj:SetText(t) TextLabel.Text = t end
			return Obj
		end

		-- ==========================================
		-- INPUT COMPONENT
		-- ==========================================
		function Components:AddInput(props)
			props = props or {}

			local ConfigKey      = props.ConfigKey or (props.Title or "Input")
			local InputDefault   = props.Default or ""
			if ConfigData[ConfigKey] ~= nil then InputDefault = ConfigData[ConfigKey] end

			if LastElementType == "Component" then AddDivider() end
			ElementIndex = ElementIndex + 1

			local FrameH  = props.Desc and DS.CompHDesc or DS.CompH

			local InputFrame = Create("Frame", {
				Name                  = "InputFrame",
				Parent                = CurrentGroup,
				BackgroundTransparency = 1,
				BorderSizePixel       = 0,
				Size                  = UDim2.new(1, 0, 0, FrameH),
				LayoutOrder           = ElementIndex,
			})

			Create("TextLabel", {
				Parent                = InputFrame,
				BackgroundTransparency = 1,
				Position              = props.Desc and UDim2.new(0, DS.Padding, 0, 6) or UDim2.new(0, DS.Padding, 0.5, 0),
				AnchorPoint           = props.Desc and Vector2.new(0, 0) or Vector2.new(0, 0.5),
				Size                  = UDim2.new(0.5, -12, props.Desc and 0 or 1, 0),
				FontFace              = GetFont(Enum.FontWeight.SemiBold),
				Text                  = props.Title or "Input",
				TextColor3            = Style.Primary,
				TextSize              = DS.FontTitle,
				TextXAlignment        = Enum.TextXAlignment.Left,
				TextYAlignment        = props.Desc and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
			})

			if props.Desc then
				Create("TextLabel", {
					Text                  = props.Desc,
					Size                  = UDim2.new(0.5, -12, 0, 20),
					Position              = UDim2.new(0, DS.Padding, 0, DS.FontTitle + 6),
					AnchorPoint           = Vector2.new(0, 0),
					BackgroundTransparency = 1,
					FontFace              = GetFont(Enum.FontWeight.Regular),
					TextSize              = DS.FontDesc,
					TextColor3            = Style.TextDim,
					TextXAlignment        = Enum.TextXAlignment.Left,
					TextWrapped           = true,
					Parent                = InputFrame,
				})
			end

			local boxFrame = Create("Frame", {
				Size                  = UDim2.new(0.5, -DS.Padding, 0, DS.InputH),
				Position              = UDim2.new(0.5, DS.Padding / 2, 0.5, 0),
				AnchorPoint           = Vector2.new(0, 0.5),
				BackgroundColor3      = Style.InputBg,
				BackgroundTransparency = 0.50,
				Parent                = InputFrame,
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = boxFrame })
			Create("UIStroke",  { Color = Style.InputStroke, Transparency = 0.15, Thickness = 1.4, Parent = boxFrame })

			local box = Create("TextBox", {
				Position              = UDim2.new(0, 8, 0, 0),
				Size                  = UDim2.new(1, -16, 1, 0),
				BackgroundTransparency = 1,
				PlaceholderText       = props.Placeholder or "Value..",
				Text                  = InputDefault,
				ClearTextOnFocus      = false,
				FontFace              = GetFont(Enum.FontWeight.Medium),
				TextSize              = DS.FontBase,
				TextColor3            = Style.Text,
				PlaceholderColor3     = Style.TextDim,
				TextXAlignment        = Enum.TextXAlignment.Left,
				Parent                = boxFrame,
			})

			local Callback = props.Callback or function() end
			local function setValue(v, silent)
				v = tostring(v or "")
				box.Text = v
				if not silent and typeof(Callback) == "function" then Callback(v) end
			end

			box.FocusLost:Connect(function()
				ConfigData[ConfigKey] = box.Text
				setValue(box.Text)
			end)

			LastElementType = "Component"
			local Obj = { Frame = InputFrame }
			function Obj:SetValue(v) setValue(v, true) end
			function Obj:GetValue() return box.Text end
			if ConfigKey then Window.Elements[ConfigKey] = { Object = Obj, Type = "Input" } end
			return Obj
		end

		-- ==========================================
		-- SLIDER COMPONENT
		-- ==========================================
		function Components:AddSlider(props)
			props = props or {}

			local Min       = props.Min     or 0
			local Max       = props.Max     or 100
			local Default   = props.Default or Min
			local ConfigKey = props.ConfigKey or (props.Title or "Slider")

			if ConfigData[ConfigKey] ~= nil then
				Default = tonumber(ConfigData[ConfigKey]) or Default
			end

			if LastElementType == "Component" then AddDivider() end
			ElementIndex = ElementIndex + 1

			local SliderFrame = Create("Frame", {
				Name                  = "SliderFrame",
				Parent                = CurrentGroup,
				BackgroundTransparency = 1,
				BorderSizePixel       = 0,
				Size                  = UDim2.new(1, 0, 0, DS.SliderH),
				LayoutOrder           = ElementIndex,
			})

			Create("TextLabel", {
				Parent                = SliderFrame,
				BackgroundTransparency = 1,
				Position              = UDim2.new(0, 12, 0, 6),
				Size                  = UDim2.new(1, -24, 0, 20),
				FontFace              = GetFont(Enum.FontWeight.SemiBold),
				Text                  = props.Title or "Slider",
				TextColor3            = Style.Primary,
				TextSize              = DS.FontTitle,
				TextXAlignment        = Enum.TextXAlignment.Left,
			})

			local ValueLabel = Create("TextLabel", {
				Parent                 = SliderFrame,
				BackgroundTransparency = 1,
				Size                   = UDim2.new(0, 50, 0, DS.FontTitle),
				Position               = UDim2.new(1, -DS.Padding, 0, props.Description and 6 or DS.Padding),
				AnchorPoint            = Vector2.new(1, 0),
				TextXAlignment         = Enum.TextXAlignment.Right,
				Text                  = tostring(math.floor(Default)),
				TextColor3             = Style.Text,
				FontFace               = GetFont(Enum.FontWeight.Bold),
				TextSize               = DS.FontTitle,
			})

			local SliderBg = Create("Frame", {
				Parent                = SliderFrame,
				BackgroundColor3      = Style.InputBg,
				BackgroundTransparency = 0.5,
				BorderSizePixel       = 0,
				Position              = UDim2.new(0, DS.Padding, 1, -12),
				Size                  = UDim2.new(1, -(DS.Padding * 2), 0, 4),
				AnchorPoint           = Vector2.new(0, 1),
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SliderBg })

			local SliderFill = Create("Frame", {
				Parent           = SliderBg,
				BackgroundColor3 = Style.Primary,
				BorderSizePixel  = 0,
				Size             = UDim2.new((Default - Min) / (Max - Min), 0, 1, 0),
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SliderFill })

			local SliderKnob = Create("Frame", {
				Parent           = SliderBg,
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel  = 0,
				Position         = UDim2.new((Default - Min) / (Max - Min), 0, 0.5, 0),
				Size             = UDim2.new(0, 14, 0, 14),
				AnchorPoint      = Vector2.new(0.5, 0.5),
				ZIndex           = 2,
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SliderKnob })

			local InputBtn = Create("TextButton", {
				Parent                = SliderBg,
				BackgroundTransparency = 1,
				Size                  = UDim2.new(1, 0, 1, 0),
				Text                  = "",
				ZIndex                = 3,
			})

			local Dragging = false
			local SliderObj = { Value = Default }
			local Callback  = props.Callback or function() end

			local function UpdateSlider(value, manual)
				value   = math.clamp(value, Min, Max)
				local p = (value - Min) / (Max - Min)
				SliderFill.Size      = UDim2.new(p, 0, 1, 0)
				SliderKnob.Position  = UDim2.new(p, 0, 0.5, 0)
				ValueLabel.Text      = tostring(math.floor(value))
				SliderObj.Value      = value
				if not manual then
					if ConfigKey then ConfigData[ConfigKey] = value ; saveConfig() end
					Callback(value)
				end
			end

			InputBtn.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					Dragging = true
					TweenService:Create(SliderKnob, TweenInfo.new(0.1), { Size = UDim2.new(0, 18, 0, 18) }):Play()
					local pos     = input.Position.X - SliderBg.AbsolutePosition.X
					local percent = math.clamp(pos / SliderBg.AbsoluteSize.X, 0, 1)
					UpdateSlider(Min + (Max - Min) * percent)
				end
			end)

			InputBtn.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					Dragging = false
					TweenService:Create(SliderKnob, TweenInfo.new(0.1), { Size = UDim2.new(0, 14, 0, 14) }):Play()
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local pos     = input.Position.X - SliderBg.AbsolutePosition.X
					local percent = math.clamp(pos / SliderBg.AbsoluteSize.X, 0, 1)
					UpdateSlider(Min + (Max - Min) * percent)
				end
			end)

			function SliderObj:Set(val, silent) UpdateSlider(val, silent) end

			LastElementType = "Component"
			if ConfigKey then Window.Elements[ConfigKey] = { Object = SliderObj, Type = "Slider" } end
			return SliderObj
		end

		-- ==========================================
		-- TOGGLE COMPONENT
		-- ==========================================
		function Components:AddToggle(props)
			props = props or {}

			local ToggleDefault = props.Default or false
			local ConfigKey     = props.ConfigKey or (props.Title or "Toggle")
			if ConfigData[ConfigKey] ~= nil then ToggleDefault = ConfigData[ConfigKey] end
			local Toggled = ToggleDefault

			if LastElementType == "Component" then AddDivider() end
			ElementIndex = ElementIndex + 1

			local FrameH = props.Desc and DS.CompHDesc or DS.CompH

			local ToggleFrame = Create("Frame", {
				Name                  = "ToggleFrame",
				Parent                = CurrentGroup,
				BackgroundTransparency = 1,
				BorderSizePixel       = 0,
				Size                  = UDim2.new(1, 0, 0, FrameH),
				LayoutOrder           = ElementIndex,
				Active                = true,
			})

			Create("TextLabel", {
				Parent                = ToggleFrame,
				BackgroundTransparency = 1,
				Position              = props.Desc and UDim2.new(0, DS.Padding, 0, 6) or UDim2.new(0, DS.Padding, 0.5, 0),
				AnchorPoint           = props.Desc and Vector2.new(0, 0) or Vector2.new(0, 0.5),
				Size                  = UDim2.new(1, -60, props.Desc and 0 or 1, 0),
				FontFace              = GetFont(Enum.FontWeight.SemiBold),
				Text                  = props.Title or "Toggle",
				TextColor3            = Style.Primary,
				TextSize              = DS.FontTitle,
				TextXAlignment        = Enum.TextXAlignment.Left,
				TextYAlignment        = props.Desc and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
			})

			if props.Desc then
				Create("TextLabel", {
					Text                  = props.Desc,
					Size                  = UDim2.new(1, -60, 0, 20),
					Position              = UDim2.new(0, DS.Padding, 0, DS.FontTitle + 6),
					AnchorPoint           = Vector2.new(0, 0),
					BackgroundTransparency = 1,
					FontFace              = GetFont(Enum.FontWeight.Regular),
					TextSize              = DS.FontDesc,
					TextColor3            = Style.TextDim,
					TextXAlignment        = Enum.TextXAlignment.Left,
					TextWrapped           = true,
					Parent                = ToggleFrame,
				})
			end

			local SwitchBg = Create("Frame", {
				Parent           = ToggleFrame,
				AnchorPoint      = Vector2.new(1, 0.5),
				BackgroundColor3 = Toggled and Style.Primary or Style.ToggleOff,
				Position         = UDim2.new(1, -DS.Padding, 0.5, 0),
				Size             = UDim2.new(0, DS.ToggleW, 0, DS.ToggleH),
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SwitchBg })

			local CircleSz = DS.ToggleH - 4
			local SwitchCircle = Create("Frame", {
				Parent           = SwitchBg,
				AnchorPoint      = Vector2.new(0, 0.5),
				BackgroundColor3 = Style.Text,
				Position         = UDim2.new(0, Toggled and (DS.ToggleW - CircleSz - 2) or 2, 0.5, 0),
				Size             = UDim2.new(0, CircleSz, 0, CircleSz),
			})
			Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SwitchCircle })

			local Button = Create("TextButton", {
				Parent                = ToggleFrame,
				BackgroundTransparency = 1,
				Size                  = UDim2.new(1, 0, 1, 0),
				Text                  = "",
				Active                = true,
			})

			local ToggleObject = { Value = ToggleDefault }
			local Callback = props.Callback or function() end

			local function UpdateToggleState(newValue)
				Toggled              = newValue
				ToggleObject.Value   = Toggled
				local tw = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				TweenService:Create(SwitchBg,     tw, { BackgroundColor3 = Toggled and Style.Primary or Style.ToggleOff }):Play()
				TweenService:Create(SwitchCircle, tw, { Position = UDim2.new(0, Toggled and (DS.ToggleW - CircleSz - 2) or 2, 0.5, 0) }):Play()
				ConfigData[ConfigKey] = Toggled
				Callback(Toggled)
			end

			Button.Activated:Connect(function() UpdateToggleState(not Toggled) end)
			function ToggleObject:SetValue(v)
				if type(v) ~= "boolean" then v = v == true end
				UpdateToggleState(v)
			end

			LastElementType = "Component"
			if ConfigKey then Window.Elements[ConfigKey] = { Object = ToggleObject, Type = "Toggle" } end
			return ToggleObject
		end

		-- ==========================================
		-- DROPDOWN COMPONENT
		-- ==========================================
		function Components:AddDropdown(props, section)
			props = props or {}

			local DropdownName  = props.Name or props.Title or "Dropdown"
			local Items         = props.Options or {}
			local Default       = props.Default or Items[1]
			local Callback      = props.Callback or function() end
			local ConfigKey     = props.ConfigKey or DropdownName
			local SearchEnabled = props.SearchEnabled or false
			local IsMulti       = props.Multi or false

			local SingleSelected = Default
			local MultiSelected = {}

			if ConfigData[ConfigKey] ~= nil then
				local saved = ConfigData[ConfigKey]
				if type(saved) == "table" then
					if IsMulti then
						for _, v in pairs(saved) do
							if table.find(Items, v) then
								table.insert(MultiSelected, v)
							end
						end
					else
						if saved[1] and table.find(Items, saved[1]) then
							SingleSelected = saved[1]
							Default        = saved[1]
						end
					end
				end
			end

			if LastElementType == "Component" then AddDivider() end
			ElementIndex = ElementIndex + 1

			local FrameH = props.Desc and DS.CompHDesc or DS.CompH

			local DropdownFrame = Create("Frame", {
				Name                  = "DropdownFrame",
				Parent                = CurrentGroup,
				BackgroundTransparency = 1,
				BorderSizePixel       = 0,
				Size                  = UDim2.new(1, 0, 0, FrameH),
				ClipsDescendants      = true,
				ZIndex                = 2,
				LayoutOrder           = ElementIndex,
				Active                = true,
			})

			Create("TextLabel", {
				Parent                = DropdownFrame,
				BackgroundTransparency = 1,
				Position              = props.Desc and UDim2.new(0, DS.Padding, 0, 6) or UDim2.new(0, DS.Padding, 0.5, 0),
				AnchorPoint           = props.Desc and Vector2.new(0, 0) or Vector2.new(0, 0.5),
				Size                  = UDim2.new(1, -40, props.Desc and 0 or 1, 0),
				FontFace              = GetFont(Enum.FontWeight.SemiBold),
				Text                  = DropdownName,
				TextColor3            = Style.Primary,
				TextSize              = DS.FontTitle,
				TextXAlignment        = Enum.TextXAlignment.Left,
				TextYAlignment        = props.Desc and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
				ZIndex                = 2,
			})

			if props.Desc then
				Create("TextLabel", {
					Text                  = props.Desc,
					Size                  = UDim2.new(1, -40, 0, 20),
					Position              = UDim2.new(0, DS.Padding, 0, DS.FontTitle + 6),
					AnchorPoint           = Vector2.new(0, 0),
					BackgroundTransparency = 1,
					FontFace              = GetFont(Enum.FontWeight.Regular),
					TextSize              = DS.FontDesc,
					TextColor3            = Style.TextDim,
					TextXAlignment        = Enum.TextXAlignment.Left,
					TextWrapped           = true,
					ZIndex                = 2,
					Parent                = DropdownFrame,
				})
			end

			local function BuildMultiIndicatorText(selected)
				if #selected == 0 then
					return "Select..."
				elseif #selected == 1 then
					return selected[1]
				else
					local first  = selected[1]
					local extras = #selected - 1
					return first .. ", +" .. extras
				end
			end

			local CurrentValue = Create("TextLabel", {
				Parent                = DropdownFrame,
				BackgroundTransparency = 1,
				Position              = UDim2.new(0, 0, 0.5, 0),
				Size                  = UDim2.new(1, -35, 0, 20),
				AnchorPoint           = Vector2.new(0, 0.5),
				FontFace              = GetFont(Enum.FontWeight.Regular),
				Text                  = IsMulti and BuildMultiIndicatorText(MultiSelected)
					or (SingleSelected or "Select..."),
				TextColor3            = Style.TextDim,
				TextSize              = DS.FontBase - 1,
				TextXAlignment        = Enum.TextXAlignment.Right,
				TextTruncate          = Enum.TextTruncate.AtEnd,
				ZIndex                = 2,
			})

			if IsMulti then
				CurrentValue.Text = BuildMultiIndicatorText(MultiSelected)
			end

			Create("ImageLabel", {
				Parent                = DropdownFrame,
				BackgroundTransparency = 1,
				Position              = UDim2.new(1, -28, 0.5, 0),
				Size                  = UDim2.new(0, 20, 0, 20),
				AnchorPoint           = Vector2.new(0, 0.5),
				Image                 = GetIcon("chevron-right"),
				ImageColor3           = Style.TextDim,
				ZIndex                = 2,
			})

			local Button = Create("TextButton", {
				Parent                = DropdownFrame,
				BackgroundTransparency = 1,
				Size                  = UDim2.new(1, 0, 1, 0),
				Text                  = "",
				ZIndex                = 3,
				Active                = true,
			})

			local DropdownObject = { Items = Items, Value = Default }

			if IsMulti then
				Button.Activated:Connect(function()
					Window:OpenRightDropdownMulti(DropdownName, Items, MultiSelected, function(selected)
						table.clear(MultiSelected)
						for _, v in pairs(selected) do table.insert(MultiSelected, v) end

						CurrentValue.Text = BuildMultiIndicatorText(MultiSelected)

						ConfigData[ConfigKey] = MultiSelected
						saveConfig()

						Callback(MultiSelected)
					end, SearchEnabled)
				end)

				function DropdownObject:Set(value)
					if typeof(value) ~= "table" then return end
					table.clear(MultiSelected)
					for _, v in pairs(value) do
						if table.find(Items, v) then table.insert(MultiSelected, v) end
					end
					CurrentValue.Text = BuildMultiIndicatorText(MultiSelected)
					ConfigData[ConfigKey] = MultiSelected
					saveConfig()
					Callback(MultiSelected)
				end

				function DropdownObject:GetValue() return MultiSelected end

			else
				Button.Activated:Connect(function()
					Window:OpenRightDropdown(DropdownName, Items, SingleSelected, function(value)
						if value and value[1] then
							SingleSelected     = value[1]
							CurrentValue.Text  = SingleSelected
							ConfigData[ConfigKey] = value
							saveConfig()
							Callback(value)
						end
					end, SearchEnabled)
				end)

				function DropdownObject:Set(value)
					if typeof(value) ~= "table" then return end
					if value[1] then
						SingleSelected    = value[1]
						CurrentValue.Text = SingleSelected
						ConfigData[ConfigKey] = value
						saveConfig()
						Callback(value)
					end
				end

				function DropdownObject:GetValue() return SingleSelected end
			end

			function DropdownObject:Refresh(newItems)
				Items      = newItems or Items
				self.Items = Items
			end

			LastElementType = "Component"
			if ConfigKey then Window.Elements[ConfigKey] = { Object = DropdownObject, Type = "Dropdown" } end
			return DropdownObject
		end

		return Components
	end

	return Window
end

return NextHub