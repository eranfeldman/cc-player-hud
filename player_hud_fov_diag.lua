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

local function readFov()
  local ok, fov = pcall(fovApi.getFov)
  return ok and type(fov) == "number" and fov or nil
end

local before = readFov()
print("HUD FOV diagnostic")
print("Source: " .. source)
print("Start with ADS off.")
print("Close this screen, ADS for 10 sec.")
print("Capture starts in 3 seconds...")
sleep(3)

local minFov, maxFov, lastFov, samples
for _ = 1, 100 do
  local fov = readFov()
  if fov then
    minFov = math.min(minFov or fov, fov)
    maxFov = math.max(maxFov or fov, fov)
    lastFov = fov
    samples = (samples or 0) + 1
  end
  sleep(0.1)
end

term.setCursorPos(1, 1)
term.clear()
print("HUD FOV diagnostic result")
print("Source: " .. source)
print("Before: " .. (before and string.format("%.1f deg", before) or "no sample"))
print("Range: " .. (minFov and string.format("%.1f - %.1f deg", minFov, maxFov) or "no samples"))
print("End: " .. (lastFov and string.format("%.1f deg", lastFov) or "no sample"))
print("Samples: " .. (samples or 0) .. "/100")
if minFov and maxFov then
  print("Change: " .. (maxFov - minFov >= 1 and "detected" or "not detected"))
end
