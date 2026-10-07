-- SpidertronPatrols 2.7.0 (latest, maraxsis' hard dependency) vs Factorio 2.1:
-- sp-spidertron-dock (proxy-container) passes circuit_connector as a single
-- definition table (circuit_connector_definitions["artillery-turret"]), but
-- the engine demands a list for this prototype type and aborts the whole
-- data load. Wrap any single-table circuit_connector into a one-element list
-- so the stack loads for the maraxsis checks. Sandbox shim only; not part of
-- the shipped mod.
for _, prototype in pairs(data.raw["proxy-container"] or {}) do
  local connector = prototype.circuit_connector
  if type(connector) == "table" and connector[1] == nil then
    prototype.circuit_connector = { connector }
    log("[e2e-sp-dock-compat] wrapped circuit_connector of proxy-container/"
      .. prototype.name .. " into a list")
  end
end
