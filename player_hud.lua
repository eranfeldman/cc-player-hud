-- Downloads and runs the latest player HUD on every launch.
local url = "https://raw.githubusercontent.com/eranfeldman/cc-player-hud/main/player_hud_core.lua"
local core = "player_hud_core.lua"

local response, err
if http and http.get then
  local ok, result, reason = pcall(http.get, url)
  if ok then response, err = result, reason else err = result end
else
  err = "HTTP API is unavailable"
end
if response then
  local source = response.readAll()
  response.close()
  local chunk, syntaxError = load(source, "@" .. core)
  if chunk then
    local file = fs.open(core, "w")
    if file then
      file.write(source)
      file.close()
      print("Player HUD updated.")
    else
      print("Could not save update; using cached copy.")
    end
  else
    print("Update has a syntax error; using cached copy: " .. tostring(syntaxError))
  end
else
  print("Update check failed; using cached copy: " .. tostring(err))
end

if not fs.exists(core) then error("No cached HUD program. Check HTTP access and launch again.") end
os.run({}, core, ...)
