-- Pocket Unlimited + Advanced Peripherals Player Detector + HUD Glasses CC
local MAX_PLAYERS = 10
local REFRESH = 1
local VERTICAL_FOV = 70

local pocket = peripheral.wrap("back")
assert(pocket and pocket.upgrades, "Enable Pocket Unlimited and equip Player Detector + HUD Glasses")

local detector, hud
for _, upgrade in pairs(pocket.upgrades()) do
  if type(upgrade.getOwner) == "function" and type(upgrade.getPlayer) == "function" then detector = upgrade end
  if type(upgrade.getSize) == "function" and type(upgrade.setCursorPos) == "function" then hud = upgrade end
end
assert(detector, "Player Detector pocket upgrade not found")
assert(hud, "HUD Glasses pocket upgrade not found")

local selected, running = 1, true
local players, wearer = {}, nil
local enabled = {}

local function scan()
  local me = detector.getOwner()
  if not me or not me.x or not me.y or not me.z or not me.yaw or not me.pitch then
    return {}, 0, nil, "Waiting for player data..."
  end

  local found = {}
  local present = {}
  local online = detector.getOnlinePlayers() or {}
  for _, name in ipairs(online) do
    local p = detector.getPlayer(name)
    local playerName = p and (p.name or name)
    local isMe = p and ((me.uuid and p.uuid == me.uuid)
      or (me.name and playerName:lower() == me.name:lower()))
    if p and p.x and p.y and p.z and not isMe then
      local sameDimension = p.dimension == me.dimension
      local dx, dy, dz = p.x - me.x, p.y - me.y, p.z - me.z
      found[#found + 1] = {
        name = playerName,
        dimension = p.dimension,
        x = p.x,
        y = p.y,
        z = p.z,
        eyeHeight = p.eyeHeight or 1.62,
        distance = sameDimension and math.sqrt(dx * dx + dy * dy + dz * dz) or nil,
      }
      present[playerName] = true
      if enabled[playerName] == nil then enabled[playerName] = true end
    end
  end
  table.sort(found, function(a, b)
    if a.distance and b.distance then return a.distance < b.distance end
    if a.distance then return true end
    if b.distance then return false end
    return a.name < b.name
  end)
  while #found > MAX_PLAYERS do table.remove(found) end
  for playerName in pairs(enabled) do
    if not present[playerName] then enabled[playerName] = nil end
  end
  return found, #online, me
end

local function drawHud()
  local width, height = hud.getSize()
  hud.setBackgroundColour(0)
  hud.clear()
  if not wearer or width < 1 or height < 1 then return end

  local colorsByPlayer = { colors.lime, colors.red, colors.cyan, colors.yellow, colors.magenta,
    colors.orange, colors.lightBlue, colors.pink, colors.green, colors.purple }
  local verticalTangent = math.tan(math.rad(VERTICAL_FOV / 2))
  local aspect = width / height * (2 / 3) -- CC glyphs are about two thirds as wide as they are tall.
  local horizontalTangent = verticalTangent * aspect
  for i, p in ipairs(players) do
    if enabled[p.name] and p.dimension == wearer.dimension then
      local dx, dy, dz = p.x - wearer.x, p.y + p.eyeHeight * 0.55 - (wearer.y + (wearer.eyeHeight or 1.62)), p.z - wearer.z
      local horizontal = math.sqrt(dx * dx + dz * dz)
      local yaw = (math.deg(math.atan(-dx, dz)) - wearer.yaw + 180) % 360 - 180
      local pitch = -math.deg(math.atan(dy, horizontal)) - wearer.pitch
      local nx = math.tan(math.rad(yaw)) / horizontalTangent
      local ny = math.tan(math.rad(pitch)) / verticalTangent
      if math.abs(yaw) < 89 and math.abs(pitch) < 89 and math.abs(nx) <= 1 and math.abs(ny) <= 1 then
        local x = math.max(1, math.min(width, math.floor((nx + 1) * width / 2 + 0.5)))
        local y = math.max(1, math.min(height, math.floor((ny + 1) * height / 2 + 0.5)))
        hud.setTextColour(colorsByPlayer[(i - 1) % #colorsByPlayer + 1])
        if hud.setTextShadow then pcall(hud.setTextShadow, "OUTLINE") end
        hud.setCursorPos(x, y)
        hud.write(".")
      end
    end
  end
end

local function drawComputer(message)
  local width = term.getSize()
  term.setCursorPos(1, 1)
  term.clear()
  selected = math.max(1, math.min(selected, #players + 2))
  local allEnabled, anyEnabled = true, false
  for _, p in ipairs(players) do
    if enabled[p.name] then anyEnabled = true else allEnabled = false end
  end

  local function line(row, label, colour)
    term.setCursorPos(1, row)
    term.setBackgroundColor(row == selected and colors.yellow or colors.black)
    term.setTextColor(row == selected and colors.black or colour)
    term.clearLine()
    term.write((row == selected and "> " or "  ") .. label:sub(1, math.max(0, width - 2)))
  end

  local allState = allEnabled and "ON" or (anyEnabled and "MIXED" or "OFF")
  line(1, "Toggle all: " .. allState, colors.cyan)
  for i, p in ipairs(players) do
    line(i + 1, (enabled[p.name] and "[x] " or "[ ] ") .. p.name,
      enabled[p.name] and colors.lime or colors.gray)
  end
  line(#players + 2, "[ Quit ]", colors.red)
  if message then
    term.setCursorPos(1, #players + 3)
    term.setTextColor(colors.red)
    print(message)
  end
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
end

local function activateSelected()
  if selected == 1 then
    local turnOn = false
    for _, p in ipairs(players) do
      if not enabled[p.name] then turnOn = true; break end
    end
    for _, p in ipairs(players) do enabled[p.name] = turnOn end
  elseif selected <= #players + 1 then
    local p = players[selected - 1]
    enabled[p.name] = not enabled[p.name]
  else
    running = false
  end
end

local function updateLoop()
  while running do
    local ok, result, _, currentWearer, message = pcall(scan)
    if ok then
      players, wearer = result, currentWearer
    else
      players, wearer = {}, nil
      message = "Detector error: " .. tostring(result)
    end
    drawComputer(message)
    drawHud()
    sleep(REFRESH)
  end
end

local function controlLoop()
  while running do
    local event, key, _, y = os.pullEvent()
    if event == "key" then
      if key == keys.up then selected = math.max(1, selected - 1)
      elseif key == keys.down then selected = math.min(#players + 2, selected + 1)
      elseif key == keys.enter then activateSelected() end
    elseif event == "mouse_click" and key == 1 and y and y <= #players + 2 then
      selected = math.max(1, y)
      activateSelected()
    end
  end
end

parallel.waitForAny(updateLoop, controlLoop)
hud.clear()
term.clear()
term.setCursorPos(1, 1)
print("Player HUD stopped")
