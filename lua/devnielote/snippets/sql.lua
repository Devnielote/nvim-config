local ls = require("luasnip")
local parse = ls.parser.parse_snippet

-- Queremos que $module$ quede literal en el buffer
local function lit(text)
  return (text:gsub("%$", "\\$"))
end

return {
  ---------------------------------------------------------------------------
  -- 1) SQL VIEWS (archivo .sql)
  ---------------------------------------------------------------------------
  parse("gomod_sqlview", lit([[
-- Vista SQL para el módulo "$module$"

DROP VIEW IF EXISTS $module$_list_view CASCADE;

CREATE OR REPLACE VIEW $module$_list_view AS
SELECT
    -- TODO: reemplazar con columnas reales
    t.id,
    t.active,
    t.create_date,
    t.name
FROM $module$ t
-- TODO: agregar JOINs necesarios
;

REVOKE ALL ON $module$_list_view FROM PUBLIC;
REVOKE ALL ON $module$_list_view FROM developer;
GRANT SELECT ON $module$_list_view TO developer;
]])),
}

