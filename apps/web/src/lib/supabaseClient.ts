import { createClient } from "@supabase/supabase-js";

// The anon/publishable key is safe to ship in the client bundle — it has no
// power on its own; Row Level Security policies on each table are what
// actually gate access. Never put the service_role key here.
const SUPABASE_URL = "https://qojdhatypfuakhkkedar.supabase.co";
const SUPABASE_ANON_KEY = "sb_publishable_OX6lgIfO3vfeDsonPJnDuw_SpipH8_R";

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
