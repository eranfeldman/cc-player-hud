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

local mode, selected, visible, running = "all", 1, true, true
local players, onlineCount, wearer = {}, 0, nil

local function scan()
  local me = detector.getOwner()
  if not me or not me.x or not me.y or not me.z or not me.yaw or not me.pitch then
    return {}, 0, nil, "Waiting for player data..."
  end

  local found = {}
  local online = detector.getOnlinePlayers() or {}
  for _, name in ipairs(online) do
    local p = detector.getPlayer(name)
    if p and p.x and p.y and p.z and p.uuid ~= me.uuid then
      local sameDimension = p.dimension == me.dimension
      local dx, dy, dz = p.x - me.x, p.y - me.y, p.z - me.z
      found[#found + 1] = {
        name = p.name or name,
        dimension = p.dimension,
        x = p.x,
        y = p.y,
        z = p.z,
        eyeHeight = p.eyeHeight or 1.62,
        distance = sameDimension and math.sqrt(dx * dx + dy * dy + dz * dz) or nil,
      }
    end
  end
  table.sort(found, function(a, b)
    if a.distance and b.distance then return a.distance < b.distance end
    if a.distance then return true end
    if b.distance then return false end
    return a.name < b.name
  end)
  while #found > MAX_PLAYERS do table.remove(found) end
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
    if p.dimension == wearer.dimension then
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

local function drawComputer()
  term.setCursorPos(1, 1)
  term.clear()
  print("Player HUD  |  max " .. MAX_PLAYERS .. " players")
  print("Mode: " .. (mode == "all" and "ALL" or "ONE"))
  if mode == "one" then print("Selected: " .. (players[selected] and players[selected].name or "none")) end
  print("Showing: " .. #players .. "/" .. onlineCount .. " online   HUD: " .. (visible and "ON" or "OFF"))
  if not wearer then print("Waiting for player data or detector error.") end
  print("A: all   P: next player   H: HUD on/off   Q: quit")
end

local function updateLoop()
  while running do
    local ok, result, count, currentWearer, message = pcall(scan)
    if ok then
      players, onlineCount = result, count or #result
      wearer = currentWearer
      if selected > #players then selected = 1 end
    else
      players, onlineCount, wearer = {}, 0, nil
      message = "Detector error: " .. tostring(result)
    end
    drawComputer()
    if message then print(message) end
    if visible then drawHud() else hud.clear() end
    sleep(REFRESH)
  end
end

local function controlLoop()
  while running do
    local _, char = os.pullEvent("char")
    char = string.lower(char)
    if char == "a" then mode = "all"
    elseif char == "p" then
      if #players > 0 then selected = selected % #players + 1 end
      mode = "one"
    elseif char == "h" then visible = not visible
    elseif char == "q" then running = false end
  end
end

parallel.waitForAny(updateLoop, controlLoop)
hud.clear()
term.clear()
term.setCursorPos(1, 1)
print("Player HUD stopped")
