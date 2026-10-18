-- Pocket Unlimited + Advanced Peripherals Player Detector + HUD Glasses CC
local MAX_PLAYERS = 10
local REFRESH = 1
local PAGE_SECONDS = 3

local pocket = peripheral.wrap("back")
assert(pocket and pocket.upgrades, "Enable Pocket Unlimited and equip Player Detector + HUD Glasses")

local detector, hud
for _, upgrade in pairs(pocket.upgrades()) do
  if type(upgrade.getOwner) == "function" and type(upgrade.getPlayer) == "function" then detector = upgrade end
  if type(upgrade.getSize) == "function" and type(upgrade.setCursorPos) == "function" then hud = upgrade end
end
assert(detector, "Player Detector pocket upgrade not found")
assert(hud, "HUD Glasses pocket upgrade not found")

local directions = { "front", "front-right", "right", "back-right", "behind", "back-left", "left", "front-left" }
local mode, selected, visible, running = "all", 1, true, true
local players, onlineCount, ticks = {}, 0, 0

local function round(n, places)
  local scale = 10 ^ places
  return math.floor(n * scale + 0.5) / scale
end

local function direction(dx, dz, yaw)
  local bearing = math.deg(math.atan(-dx, dz))
  local relative = (bearing - yaw + 180) % 360 - 180
  return directions[math.floor((relative + 22.5) / 45) % 8 + 1]
end

local function scan()
  local me = detector.getOwner()
  if not me or not me.x or not me.z or not me.yaw then return {}, 0, "Waiting for player data..." end

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
        distance = sameDimension and math.sqrt(dx * dx + dy * dy + dz * dz) or nil,
        direction = sameDimension and direction(dx, dz, me.yaw) or nil,
        vertical = round(dy, 0),
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
  return found, #online
end

local function hudLine(y, text, width)
  hud.setCursorPos(1, y)
  hud.write(text:sub(1, width))
end

local function drawHud(message)
  local width, height = hud.getSize()
  hud.setBackgroundColour(0)
  hud.clear()
  hud.setTextColour(colors.white)
  hudLine(1, mode == "all" and string.format("PLAYERS %d/%d ONLINE", #players, onlineCount) or "PLAYER: " .. (players[selected] and players[selected].name or "none"), width)

  if message then
    hudLine(2, message, width)
    return
  end

  if mode == "one" then
    local p = players[selected]
    if p then
      hud.setTextColour(colors.lime)
      hudLine(2, p.name, width)
      hud.setTextColour(colors.white)
      if p.distance then
        hudLine(3, p.direction .. "  " .. string.format("%.1f", p.distance) .. "m", width)
        if p.vertical ~= 0 then hudLine(4, string.format("Y %+.0f", p.vertical), width) end
      else
        hudLine(3, p.dimension or "different dimension", width)
      end
    else
      hudLine(2, "No other players online", width)
    end
    return
  end

  if #players == 0 then hudLine(2, "No other players online", width); return end
  local rows = math.max(1, height - 2)
  local pages = math.ceil(#players / rows)
  local page = math.floor(ticks / PAGE_SECONDS) % pages + 1
  local first = (page - 1) * rows + 1
  for row = 1, rows do
    local p = players[first + row - 1]
    if not p then break end
    local line = p.distance and string.format("%s %s %.1fm", p.name, p.direction, p.distance)
      or string.format("%s @ %s", p.name, p.dimension or "other dimension")
    hudLine(row + 1, line, width)
  end
  if pages > 1 and height > 1 then hudLine(height, string.format("Page %d/%d", page, pages), width) end
end

local function drawComputer()
  term.setCursorPos(1, 1)
  term.clear()
  print("Player HUD  |  max " .. MAX_PLAYERS .. " players")
  print("Mode: " .. (mode == "all" and "ALL" or "ONE"))
  if mode == "one" then print("Selected: " .. (players[selected] and players[selected].name or "none")) end
  print("Showing: " .. #players .. "/" .. onlineCount .. " online   HUD: " .. (visible and "ON" or "OFF"))
  print("A: all   P: next player   H: HUD on/off   Q: quit")
end

local function updateLoop()
  while running do
    local ok, result, count, message = pcall(scan)
    if ok then
      players, onlineCount = result, count or #result
      if selected > #players then selected = 1 end
    else
      players, onlineCount, message = {}, 0, "Detector error: " .. tostring(result)
    end
    drawComputer()
    if visible then drawHud(message) else hud.clear() end
    ticks = ticks + REFRESH
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
