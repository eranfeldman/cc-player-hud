-- Downloads and runs the latest player HUD on every launch.
local api = "https://api.github.com/repos/eranfeldman/cc-player-hud/commits/main?update=" .. tostring(os.epoch("utc"))
local core = "player_hud_core.lua"

local url, response, err
if http and http.get then
  local ok, result, reason = pcall(http.get, api, {
    Accept = "application/vnd.github+json",
    ["Cache-Control"] = "no-cache",
  })
  if ok and result then
    local commit = textutils.unserialiseJSON(result.readAll())
    result.close()
    if commit and type(commit.sha) == "string" and #commit.sha == 40 and commit.sha:match("^[%da-f]+$") then
      url = "https://raw.githubusercontent.com/eranfeldman/cc-player-hud/" .. commit.sha .. "/player_hud_core.lua"
      local downloaded, file, downloadError = pcall(http.get, url)
      if downloaded then response, err = file, downloadError else err = file end
    else
      err = "GitHub did not return a valid commit."
    end
  else
    err = ok and reason or result
  end
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
