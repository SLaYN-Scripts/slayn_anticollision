Config = {}

Config.Debug = false
Config.FreezeObjects = false

-- Activate points only when player it's close
Config.PointActivationDistance = 80.0
Config.PointReapplyIntervalMs = 2000
Config.DefaultPointRadius = 2.0

-- Zones: Clear on the zone while inside
Config.ZoneScanRadius = 35.0
Config.ZoneReapplyIntervalMs = 2000

-- Optional global list (used when a point/zone doesn't have prop list defined)
-- Can leave clear "{}" if want ALWAYS define per point/zone
Config.DefaultProps = {
  -- "prop_x",
  -- "prop_z",
}

-- =========================
--          POINTS
-- =========================
-- Format:
--  { coords = vec3(...), radius = 2.0, props = {"prop_x","prop_z"}, intervalMs = 800 }
--  (Props are required if doesn't want to use DefaultProps)

Config.Points = {
  {
    coords = vec3(0.0, 0.0, 0.0),
    radius = 2.0,
    props = { "prop_x", "prop_z" },
  },

  -- Example:
  --{
  --  coords = vec3(440.12, -981.92, 30.69),
  --  radius = 2.2,
  --  props = { "v_ilev_ph_gendoor004", "v_ilev_ph_gendoor002" },
  --  intervalMs = 1200
  --},
}

-- =========================
--           ZONES
-- =========================
-- Types: box | sphere | poly
-- Props for all zone (if doesn't list, it will use DefaultProps)

Config.Zones = {
  {
    type = 'box',
    name = 'Example_Zone',
    coords = vec3(441.0, -981.9, 30.7),
    size = vec3(18.0, 18.0, 8.0),
    rotation = 0.0,
    debug = false,

    props = { "prop_x", "prop_z" }, -- Prop list of that Example Zone
    scanRadius = 30.0,
    intervalMs = 1800
  },
}