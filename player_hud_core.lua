-- Pocket Unlimited + Advanced Peripherals Player Detector + HUD Glasses CC
local MAX_PLAYERS = 10
local REFRESH = 0.05
local VERTICAL_FOV = 110
local SCREEN_ASPECT = 16 / 9
-- shortcut: assumes 16:9 HUD FIT and 110° FOV; adjust if view settings or dynamic FOV effects differ.

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
  local yaw, pitch = math.rad(wearer.yaw), math.rad(wearer.pitch)
  local sy, cy, sp, cp = math.sin(yaw), math.cos(yaw), math.sin(pitch), math.cos(pitch)
  local fx, fy, fz = -sy * cp, -sp, cy * cp
  local rx, rz = -cy, -sy
  local ux, uy, uz = -sp * sy, cp, sp * cy
  local tanV = math.tan(math.rad(VERTICAL_FOV / 2))
  local tanH = tanV * SCREEN_ASPECT
  local gridAspect = width / height * (2 / 3)
  local contentW = math.min(1, gridAspect / SCREEN_ASPECT)
  local contentH = math.min(1, SCREEN_ASPECT / gridAspect)
  local offsetX, offsetY = (1 - contentW) / 2, (1 - contentH) / 2
  local markers, occupied = {}, {}

  for i, p in ipairs(players) do
    if enabled[p.name] and p.dimension == wearer.dimension and p.distance then
      local dx = p.x - wearer.x
      local dy = p.y + p.eyeHeight * 0.55 - (wearer.y + (wearer.eyeHeight or 1.62))
      local dz = p.z - wearer.z
      local cameraX = dx * rx + dz * rz
      local cameraY = dx * ux + dy * uy + dz * uz
      local cameraZ = dx * fx + dy * fy + dz * fz
      if cameraZ > 0 then
        local u = 0.5 + cameraX / (2 * cameraZ * tanH)
        local v = 0.5 - cameraY / (2 * cameraZ * tanV)
        local gridX = (u - offsetX) / contentW
        local gridY = (v - offsetY) / contentH
        if gridX >= 0 and gridX <= 1 and gridY >= 0 and gridY <= 1 then
          local x = math.floor(gridX * (width - 1) + 1.5)
          local y = math.floor(gridY * (height - 1) + 1.5)
          local label = p.name .. " " .. string.format("%.1f blocks", p.distance)
          markers[#markers + 1] = {
            x = x, y = y, label = label,
            colour = colorsByPlayer[(i - 1) % #colorsByPlayer + 1],
          }
          occupied[y] = occupied[y] or {}
          occupied[y][x] = true
        end
      end
    end
  end

  if hud.setTextShadow then pcall(hud.setTextShadow, "OUTLINE") end
  for _, marker in ipairs(markers) do
    hud.setTextColour(marker.colour)
    hud.setCursorPos(marker.x, marker.y)
    hud.write(".")
  end
  for _, marker in ipairs(markers) do
    local label = marker.label:sub(1, width)
    local left = math.max(1, math.min(width - #label + 1, marker.x - math.floor(#label / 2)))
    local function placeLabel(row)
      if not row then return false end
      occupied[row] = occupied[row] or {}
      for x = left, left + #label - 1 do
        if occupied[row][x] then return false end
      end
      hud.setTextColour(marker.colour)
      hud.setCursorPos(left, row)
      hud.write(label)
      for x = left, left + #label - 1 do occupied[row][x] = true end
      return true
    end
    local placed = false
    for row = marker.y + 1, height do
      if placeLabel(row) then placed = true; break end
    end
    if not placed then
      for row = marker.y - 1, 1, -1 do
        if placeLabel(row) then break end
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
