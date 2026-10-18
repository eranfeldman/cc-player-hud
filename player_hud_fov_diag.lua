local pocket = peripheral.wrap("back")
local fovApi, source

if pocket and type(pocket.upgrades) == "function" then
  for _, upgrade in pairs(pocket.upgrades()) do
    if type(upgrade.getFov) == "function" then fovApi, source = upgrade, "pocket upgrade"; break end
  end
end

if not fovApi then
  local ok, api = pcall(require, "hudfovbridge.fov")
  if ok and type(api) == "table" and type(api.getFov) == "function" then
    fovApi, source = api, "Lua API"
  end
end

if not fovApi then
  print("HUD FOV bridge API not found.")
  print("Restart the client and server with the updated bridge jar.")
  return
end

local minFov, maxFov, lastFov
while true do
  local ok, fov = pcall(fovApi.getFov)
  if ok and type(fov) == "number" then
    minFov = math.min(minFov or fov, fov)
    maxFov = math.max(maxFov or fov, fov)
    lastFov = fov
  else
    lastFov = nil
  end

  term.setCursorPos(1, 1)
  term.clear()
  print("HUD FOV diagnostic")
  print("Source: " .. source)
  print("Current: " .. (lastFov and string.format("%.1f deg", lastFov) or "WAITING FOR SERVER"))
  print("Range: " .. (minFov and string.format("%.1f - %.1f", minFov, maxFov) or "no sample yet"))
  print("Aim down sights to check FOV.")
  print("Ctrl+T to stop.")
  sleep(0.25)
end
