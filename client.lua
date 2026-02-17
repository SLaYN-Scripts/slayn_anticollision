-- Enumerate objects in GamePool
local function EnumerateObjects()
  return coroutine.wrap(function()
    local handle, entity = FindFirstObject()
    if not handle or handle == -1 then
      if handle and handle ~= -1 then EndFindObject(handle) end
      return
    end

    local ok = true
    repeat
      coroutine.yield(entity)
      ok, entity = FindNextObject(handle)
    until not ok

    EndFindObject(handle)
  end)
end

local function vdist(a, b)
  local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
  return math.sqrt(dx*dx + dy*dy + dz*dz)
end

local function toHash(model)
  if type(model) == 'number' then return model end
  return joaat(model)
end

local function buildPropHashSet(props)
  local set = {}
  for i = 1, #props do
    set[toHash(props[i])] = true
  end
  return set
end

local function disableCollision(entity)
  if not DoesEntityExist(entity) then return false end
  SetEntityAsMissionEntity(entity, false, true)
  SetEntityCollision(entity, false, false)
  if Config.FreezeObjects then
    FreezeEntityPosition(entity, true)
  end
  return true
end

local function normalizePoint(p)
  local props = p.props or Config.DefaultProps or {}
  return {
    coords = p.coords,
    radius = p.radius or Config.DefaultPointRadius or 2.0,
    intervalMs = p.intervalMs or Config.PointReapplyIntervalMs or 2000,
    propSet = buildPropHashSet(props)
  }
end

local function getPropsForZone(def)
  local props = def.props or Config.DefaultProps or {}
  return buildPropHashSet(props)
end

-- Processes a point, only props of list (propSet) and inside point radius
local function processPoint(point)
  local c = point.coords
  local r = point.radius
  local propSet = point.propSet

  if not propSet or next(propSet) == nil then return 0 end

  local changed = 0
  for obj in EnumerateObjects() do
    if DoesEntityExist(obj) then
      local model = GetEntityModel(obj)
      if propSet[model] then
        local o = GetEntityCoords(obj)
        if vdist(o, c) <= r then
          if disableCollision(obj) then
            changed = changed + 1
          end
        end
      end
    end
  end

  return changed
end

-- Processes inside zone, clear around player (scanRadius) but only props of the list
local function processZoneAroundPlayer(scanRadius, propSet)
  if not propSet or next(propSet) == nil then
    return 0
  end

  local ped = PlayerPedId()
  local pcoords = GetEntityCoords(ped)

  local changed = 0
  for obj in EnumerateObjects() do
    if DoesEntityExist(obj) then
      local o = GetEntityCoords(obj)
      if vdist(o, pcoords) <= scanRadius then
        local model = GetEntityModel(obj)
        if propSet[model] then
          if disableCollision(obj) then
            changed = changed + 1
          end
        end
      end
    end
  end

  return changed
end

local function createZone(def)
  if def.type == 'box' then
    return lib.zones.box({
      coords = def.coords,
      size = def.size,
      rotation = def.rotation or 0.0,
      debug = def.debug or false
    })
  elseif def.type == 'sphere' then
    return lib.zones.sphere({
      coords = def.coords,
      radius = def.radius,
      debug = def.debug or false
    })
  elseif def.type == 'poly' then
    return lib.zones.poly({
      points = def.points,
      thickness = def.thickness or 8.0,
      debug = def.debug or false
    })
  end
  return nil
end

-- =========================
--        POINT LOOP
-- =========================
local function StartPointLoop()
  local points = {}
  for i = 1, #Config.Points do
    points[i] = normalizePoint(Config.Points[i])
  end

  local nextRun = {}
  for i = 1, #points do nextRun[i] = 0 end

  while true do
    local ped = PlayerPedId()
    local pcoords = GetEntityCoords(ped)
    local now = GetGameTimer()

    local nearAnything = false

    for i = 1, #points do
      local p = points[i]
      if vdist(pcoords, p.coords) <= (Config.PointActivationDistance or 80.0) then
        nearAnything = true
        if now >= (nextRun[i] or 0) then
          local changed = processPoint(p)
          if changed > 0 then
            if Config.Debug then
                lib.print.info(('Point #%d: removed collision in %d object(s)'):format(i, changed))
            end
          end
          nextRun[i] = now + (p.intervalMs or 2000)
        end
      end
    end

    if nearAnything then
      Wait(250)
    else
      Wait(1500)
    end
  end
end

-- =========================
--        ZONE SETUP
-- =========================
local function StartZones()
  for i = 1, #Config.Zones do
    local def = Config.Zones[i]
    local zone = createZone(def)

    if not zone then
      if Config.Debug then
        lib.print.warn(('Invalid zone at index %s (type=%s)'):format(i, tostring(def.type)))
      end
      goto continue
    end

    local propSet = getPropsForZone(def)

    local running = false
    local loopId = 0

    function zone:onEnter()
      running = true
      loopId = loopId + 1
      local myLoop = loopId

      if Config.Debug then
        lib.print.info(('Entered in zone: %s'):format(def.name or tostring(i)))
      end

      CreateThread(function()
        local scanRadius = def.scanRadius or Config.ZoneScanRadius or 35.0
        local intervalMs = def.intervalMs or Config.ZoneReapplyIntervalMs or 2000

        while running and myLoop == loopId do
          local changed = processZoneAroundPlayer(scanRadius, propSet)
          if changed > 0 then
            if Config.Debug then
                lib.print.info(('Zone %s: removed collision in %d object(s)'):format(def.name or tostring(i), changed))
            end
          end
          Wait(intervalMs)
        end
      end)
    end

    function zone:onExit()
      running = false
      if Config.Debug then
        lib.print.info(('Left zone: %s'):format(def.name or tostring(i)))
      end
    end

    ::continue::
  end
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    lib.print.info("Resource Started Successfully!")
    StartPointLoop()
    StartZones()
end)
