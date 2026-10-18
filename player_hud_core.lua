-- Pocket Unlimited + Advanced Peripherals Player Detector + HUD Glasses CC
local MAX_PLAYERS = 10
local REFRESH = 0.05
local HUD_SIZES = { { 80, 28 }, { 128, 48 }, { 192, 72 }, { 256, 96 }, { 256, 128 } }
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
local detailIndex = #HUD_SIZES
if type(hud.setSize) == "function" then
  local width, height = hud.getSize()
  local size = HUD_SIZES[detailIndex]
  if width ~= size[1] or height ~= size[2] then pcall(hud.setSize, size[1], size[2]) end
end
local previousHudRows, needsFullHudClear = {}, true
local function changeDetail(delta)
  if type(hud.setSize) ~= "function" then return end
  local nextIndex = math.max(1, math.min(#HUD_SIZES, detailIndex + delta))
  if nextIndex == detailIndex then return end
  local size = HUD_SIZES[nextIndex]
  if pcall(hud.setSize, size[1], size[2]) then
    detailIndex = nextIndex
    previousHudRows, needsFullHudClear = {}, true
  end
end

local selected, running = 1, true
local players, wearer = {}, nil
local enabled = {}

local function scan()
  local me = detector.getOwner(true)
  if not me then return {}, 0, nil, "Waiting for player data..." end
  local ownerHasPosition = me.x ~= nil and me.y ~= nil and me.z ~= nil
  local ownerCanProject = ownerHasPosition and me.yaw ~= nil and me.pitch ~= nil

  local found = {}
  local present = {}
  local online = detector.getOnlinePlayers() or {}
  for _, name in ipairs(online) do
    local p = detector.getPlayer(name, true)
    local playerName = name
    local isMe
    if me.uuid and p and p.uuid then
      isMe = p.uuid == me.uuid
    else
      local ownerName = me.username or me.name
      isMe = ownerName and name:lower() == ownerName:lower()
    end
    if not isMe then
      -- shortcut: assumes same dimension when AP omits IDs; use explicit IDs to reject cross-dimensional players.
      local sameWorld = not (p and me.dimension and p.dimension and p.dimension ~= me.dimension)
      local hasPosition = p and p.x ~= nil and p.y ~= nil and p.z ~= nil and sameWorld
      local distance
      if hasPosition and ownerHasPosition then
        local dx, dy, dz = p.x - me.x, p.y - me.y, p.z - me.z
        distance = math.sqrt(dx * dx + dy * dy + dz * dz)
      end
      found[#found + 1] = {
        name = playerName,
        dimension = p and p.dimension,
        x = p and p.x,
        y = p and p.y,
        z = p and p.z,
        eyeHeight = (p and p.eyeHeight) or 1.62,
        positionAvailable = hasPosition and ownerCanProject,
        sameDimension = sameWorld,
        distance = distance,
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
  if ownerCanProject then return found, #online, me end
  return found, #online, nil, "Waiting for player position data..."
end

local function drawHud()
  local width, height = hud.getSize()
  hud.setBackgroundColour(0)
  if not wearer or width < 1 or height < 1 then
    if needsFullHudClear then hud.clear(); needsFullHudClear = false
    else
      for row in pairs(previousHudRows) do hud.setCursorPos(1, row); hud.clearLine() end
    end
    previousHudRows = {}
    return
  end

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
  local markers, labels, occupied, currentHudRows = {}, {}, {}, {}

  for i, p in ipairs(players) do
    if enabled[p.name] and p.positionAvailable and p.sameDimension and p.distance then
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
          markers[#markers + 1] = {
            x = x, y = y, name = p.name, distance = string.format("%.1f", p.distance),
            colour = colorsByPlayer[(i - 1) % #colorsByPlayer + 1],
          }
          occupied[y] = occupied[y] or {}
          occupied[y][x] = true
          currentHudRows[y] = true
        end
      end
    end
  end

  for _, marker in ipairs(markers) do
    local function leftFor(text)
      local label = text:sub(1, width)
      return math.max(1, math.min(width - #label + 1, marker.x - math.floor(#label / 2))), label
    end
    local nameLeft, name = leftFor(marker.name)
    local distanceLeft, distance = leftFor(marker.distance)
    local function canPlace(row, left, label)
      if row < 1 or row > height then return false end
      for x = left, left + #label - 1 do
        if occupied[row] and occupied[row][x] then return false end
      end
      return true
    end
    local function place(row, left, label)
      labels[#labels + 1] = { x = left, y = row, text = label }
      occupied[row] = occupied[row] or {}
      for x = left, left + #label - 1 do occupied[row][x] = true end
      currentHudRows[row] = true
    end
    local placed = false
    for gap = 0, height do
      local nameY, distanceY = marker.y - 1 - gap, marker.y + 1 + gap
      if canPlace(nameY, nameLeft, name) and canPlace(distanceY, distanceLeft, distance) then
        place(nameY, nameLeft, name)
        place(distanceY, distanceLeft, distance)
        placed = true
        break
      end
    end
    if not placed then
      for offset = 1, height do
        local nameY, distanceY = marker.y + offset, marker.y + offset + 1
        if canPlace(nameY, nameLeft, name) and canPlace(distanceY, distanceLeft, distance) then
          place(nameY, nameLeft, name)
          place(distanceY, distanceLeft, distance)
          placed = true
          break
        end
      end
    end
    if not placed then
      for offset = 2, height + 1 do
        local nameY, distanceY = marker.y - offset, marker.y - offset + 1
        if canPlace(nameY, nameLeft, name) and canPlace(distanceY, distanceLeft, distance) then
          place(nameY, nameLeft, name)
          place(distanceY, distanceLeft, distance)
          break
        end
      end
    end
  end

  if needsFullHudClear then
    hud.clear()
    needsFullHudClear = false
  else
    local rowsToClear = {}
    for row in pairs(previousHudRows) do rowsToClear[row] = true end
    for row in pairs(currentHudRows) do rowsToClear[row] = true end
    for row in pairs(rowsToClear) do hud.setCursorPos(1, row); hud.clearLine() end
  end
  if hud.setTextShadow then pcall(hud.setTextShadow, "OUTLINE") end
  for _, marker in ipairs(markers) do
    hud.setTextColour(marker.colour)
    hud.setCursorPos(marker.x, marker.y)
    hud.write(string.char(7))
  end
  for _, label in ipairs(labels) do
    hud.setTextColour(colors.white)
    hud.setCursorPos(label.x, label.y)
    hud.write(label.text)
  end
  previousHudRows = currentHudRows
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
  local missingPosition = false
  for i, p in ipairs(players) do
    if not p.positionAvailable then missingPosition = true end
    line(i + 1, (enabled[p.name] and "[x] " or "[ ] ") .. p.name .. (p.positionAvailable and "" or " *"),
      enabled[p.name] and colors.lime or colors.gray)
  end
  line(#players + 2, "[ Quit ]", colors.red)
  local hudWidth, hudHeight = hud.getSize()
  line(#players + 3, "Detail " .. detailIndex .. "/" .. #HUD_SIZES .. " " .. hudWidth .. "x" .. hudHeight .. " L/R", colors.gray)
  if not message and #players == 0 then message = "No other players returned by detector."
  elseif not message and missingPosition then message = "* Detector returned no position for this player." end
  if message then
    term.setCursorPos(1, #players + 4)
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
      elseif key == keys.left then changeDetail(-1)
      elseif key == keys.right then changeDetail(1)
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
