local ls = require("luasnip")
local parse = ls.parser.parse_snippet

-- Igual que en go.lua: convierte "$" en "\$"
local function lit(text)
  return (text:gsub("%$", "\\$"))
end

return {
  ---------------------------------------------------------------------------
  -- 1) TYPES GENÉRICOS PARA UN MÓDULO ($Struct$, $Struct$Name, $Struct$Names)
  ---------------------------------------------------------------------------
  parse("tsmod_types_generic", lit([[
import { apiResp, metaData } from '@/core/models';

export type $Struct$ = {
  id?: number;
  active?: boolean;
  create_date?: string;
  update_date?: string;
  create_uid?: number;
  write_uid?: number;
  delete_at?: string | null;
  // Campos específicos del modelo $Struct$
  // e.g.
  // company_id?: number;
  // company_name?: string;
  // name?: string;
};

export type ApiResp$Struct$ = metaData & { data: $Struct$[] };
export type ApiResp$Struct$ById = apiResp & { data: $Struct$ };

// Versión solo id + name (para dropdowns, listas simples, etc.)
export type $Struct$Name = {
  id?: number | null;
  name?: string;
};

export type ApiResp$Struct$Name = metaData & { data: $Struct$Name[] };
export type ApiResp$Struct$NameById = apiResp & { data: $Struct$Name };

// Versión extendida tipo "Names" (alias, descripción, etc.)
// Úsala si tu módulo maneja nombres alternos; si no aplica, bórrala.
export type $Struct$Names = {
  id?: number | null;
  // Referencia al modelo principal, si aplica
  $Struct$_id?: number | null;

  name: string;
  alias?: string | null;
  description?: string | null;
  active?: boolean;
  create_date?: string;
  update_date?: string;
  create_uid?: number | null;
  write_uid?: number | null;
};

export type ApiResp$Struct$Names = metaData & { data: $Struct$Names[] };
export type ApiResp$Struct$NamesById = apiResp & { data: $Struct$Names };
]])),

  ---------------------------------------------------------------------------
  -- 2) INITIAL VALUES GENÉRICOS PARA ESE MÓDULO
  ---------------------------------------------------------------------------
  parse("tsmod_initials_generic", lit([[
import { INITIAL_BOOLEAN_VALUE, INITIAL_NUMBER_VALUE, INITIAL_STRING_VALUE } from '@/core/utils';
import { $Struct$, $Struct$Names } from '@/features/modules/$module$/utils/types';

export const INITIAL_$Struct$: $Struct$ = {
  id: INITIAL_NUMBER_VALUE ?? undefined,
  active: INITIAL_BOOLEAN_VALUE,
  create_date: INITIAL_STRING_VALUE,
  update_date: INITIAL_STRING_VALUE,
  create_uid: INITIAL_NUMBER_VALUE ?? undefined,
  write_uid: INITIAL_NUMBER_VALUE ?? undefined,
  delete_at: null,
  // Campos específicos del modelo $Struct$
  // e.g.
  // company_id: INITIAL_NUMBER_VALUE ?? undefined,
  // company_name: INITIAL_STRING_VALUE,
  // name: INITIAL_STRING_VALUE,
};

export const INITIAL_$Struct$Names: $Struct$Names = {
  id: INITIAL_NUMBER_VALUE ?? undefined,
  $Struct$_id: INITIAL_NUMBER_VALUE ?? undefined,
  name: INITIAL_STRING_VALUE,
  alias: INITIAL_STRING_VALUE,
  description: INITIAL_STRING_VALUE,
  active: INITIAL_BOOLEAN_VALUE,
  create_date: INITIAL_STRING_VALUE,
  update_date: INITIAL_STRING_VALUE,
  create_uid: INITIAL_NUMBER_VALUE ?? undefined,
  write_uid: INITIAL_NUMBER_VALUE ?? undefined,
};
]])),
}

