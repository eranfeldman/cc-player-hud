-- Collect redacted Player Detector/HUD diagnostics and upload with CC:Tweaked pastebin.
local report = {}
local function add(s) report[#report + 1] = tostring(s) end
local function call(label, fn)
  local ok, value = pcall(fn)
  if not ok then add(label .. " error=" .. tostring(value)); return nil end
  return value
end
local function fields(label, value)
  if type(value) ~= "table" then add(label .. " type=" .. type(value)); return end
  local keys = {}
  for key in pairs(value) do keys[#keys + 1] = tostring(key) end
  table.sort(keys)
  local wanted = { "x", "y", "z", "yaw", "pitch", "dimension", "name", "username", "uuid", "eyeHeight" }
  local parts = {}
  for _, key in ipairs(wanted) do
    parts[#parts + 1] = key .. "=" .. type(value[key])
  end
  add(label .. " keys=" .. table.concat(keys, ",") .. " fields=" .. table.concat(parts, ","))
end
local function xyz(v)
  return type(v) == "table" and type(v.x) == "number" and type(v.y) == "number" and type(v.z) == "number"
end
local function distBucket(a, b)
  if not xyz(a) or not xyz(b) then return "unknown" end
  local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
  local d = math.sqrt(dx * dx + dy * dy + dz * dz)
  if d < 5 then return "under5" end
  if d < 20 then return "5to20" end
  if d < 100 then return "20to100" end
  return "over100"
end

add("Player HUD diagnostic v1")
add("ComputerCraft=" .. tostring(os.version and os.version() or "unknown"))
for _, path in ipairs({ "player_hud.lua", "player_hud_core.lua" }) do
  if fs.exists(path) then
    local file = fs.open(path, "r")
    local source = file.readAll()
    file.close()
    add(path .. " bytes=" .. tostring(#source)
      .. " apiUpdater=" .. tostring(source:find("api.github.com/repos/eranfeldman/cc-player-hud", 1, true) ~= nil)
      .. " missingDimensionFix=" .. tostring(source:find("assumes same dimension when AP omits IDs", 1, true) ~= nil)
      .. " oldRangeGate=" .. tostring(source:find("getPlayersInRange(46340)", 1, true) ~= nil))
  else
    add(path .. " missing=true")
  end
end
add("pocketBackType=" .. tostring(peripheral.getType("back")))
local pocket = peripheral.wrap("back")
local upgrades = pocket and pocket.upgrades and call("upgrades", function() return pocket.upgrades() end)
local detector, hud = nil, nil
for _, upgrade in pairs(upgrades or {}) do
  if type(upgrade.getOwner) == "function" and type(upgrade.getPlayer) == "function" then detector = upgrade end
  if type(upgrade.getSize) == "function" and type(upgrade.setCursorPos) == "function" then hud = upgrade end
end
add("detectorFound=" .. tostring(detector ~= nil) .. " hudFound=" .. tostring(hud ~= nil))

if detector then
  local owner = call("getOwner(true)", function() return detector.getOwner(true) end)
  local ownerPlain = call("getOwner()", function() return detector.getOwner() end)
  fields("ownerDetailed", owner)
  fields("ownerPlain", ownerPlain)
  local online = call("getOnlinePlayers", function() return detector.getOnlinePlayers() end) or {}
  add("onlineCount=" .. tostring(#online))
  local range10, range46340 = {}, {}
  local names10 = call("getPlayersInRange(10)", function() return detector.getPlayersInRange(10) end)
  local namesWide = call("getPlayersInRange(46340)", function() return detector.getPlayersInRange(46340) end)
  for _, n in ipairs(names10 or {}) do range10[tostring(n):lower()] = true end
  for _, n in ipairs(namesWide or {}) do range46340[tostring(n):lower()] = true end
  add("range10Count=" .. tostring(#(names10 or {})) .. " rangeWideCount=" .. tostring(#(namesWide or {})))
  for i, name in ipairs(online) do
    if i > 20 then add("playerRowsTruncated=true"); break end
    local normal = call("getPlayer", function() return detector.getPlayer(name) end)
    local detailed = call("getPlayer(true)", function() return detector.getPlayer(name, true) end)
    fields("player" .. i .. " normal", normal)
    fields("player" .. i .. " detailed", detailed)
    local selfNameMatch = false
    local ownerNames = {}
    if owner then ownerNames[#ownerNames + 1] = owner.name; ownerNames[#ownerNames + 1] = owner.username end
    if ownerPlain then ownerNames[#ownerNames + 1] = ownerPlain.name; ownerNames[#ownerNames + 1] = ownerPlain.username end
    for _, ownerName in ipairs(ownerNames) do
      if type(ownerName) == "string" and ownerName:lower() == tostring(name):lower() then selfNameMatch = true end
    end
    local uuidMatch = owner and detailed and owner.uuid ~= nil and detailed.uuid == owner.uuid or false
    local dims = "unknown"
    if owner and detailed and owner.dimension ~= nil and detailed.dimension ~= nil then
      dims = tostring(owner.dimension == detailed.dimension)
    end
    add("player" .. i .. " selfNameMatch=" .. tostring(selfNameMatch)
      .. " uuidMatch=" .. tostring(uuidMatch) .. " coords=" .. tostring(xyz(detailed))
      .. " view=" .. tostring(owner and type(owner.yaw) == "number" and type(owner.pitch) == "number")
      .. " dimMatch=" .. dims .. " distanceBucket=" .. distBucket(owner, detailed)
      .. " range10=" .. tostring(range10[tostring(name):lower()] == true)
      .. " rangeWide=" .. tostring(range46340[tostring(name):lower()] == true))
  end
else
  add("No Player Detector methods found on back pocket.")
end

if hud then
  local size = call("hud.getSize", function() return { hud.getSize() } end)
  add("hudSize=" .. (size and tostring(size[1]) .. "x" .. tostring(size[2]) or "unknown"))
end
local f = fs.open("player_hud_diag.txt", "w")
local body = table.concat(report, "\n") .. "\n"
f.write(body)
f.close()
print("Report saved; player names, UUIDs, and exact coordinates are redacted. Uploading...")
if not http or not http.request then
  print("HTTP request API unavailable. Report is player_hud_diag.txt")
  return
end
local url = "https://paste.rs/"
local ok, err = http.request(url, body, { ["Content-Type"] = "text/plain; charset=utf-8" })
if not ok then
  print("Upload could not start: " .. tostring(err) .. ". Report is player_hud_diag.txt")
  return
end
local timer = os.startTimer(15)
while true do
  local event, eventUrl, result = os.pullEvent()
  if (event == "http_success" or event == "http_failure") and eventUrl == url then
    os.cancelTimer(timer)
    if event == "http_success" then
      local status = result.getResponseCode and result.getResponseCode() or 200
      local link = result.readAll():gsub("%s+$", "")
      result.close()
      if status == 201 and link:match("^https://paste%.rs/") then
        print("Paste link: " .. link)
      else
        print("Upload returned HTTP " .. tostring(status) .. ". Report is player_hud_diag.txt")
      end
    else
      print("Upload failed: " .. tostring(result) .. ". Report is player_hud_diag.txt")
    end
    return
  elseif event == "timer" and eventUrl == timer then
    print("Upload timed out. Report is player_hud_diag.txt")
    return
  end
end
