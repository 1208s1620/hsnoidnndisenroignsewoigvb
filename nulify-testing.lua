--Nulif7.lua
local testing = false --DISABLE THIS BEFORE RELEASE
local c1b12 = false

local ffi = require("ffi")
local httpFactory = require("Lightweight HTTP Library")

local is_beta = false
local version = ""
local date = "April 23 2022"
local script_load = false

local beta_uids = {459, 371, 1183, 503, 423} --beta should be put here.
local admin_uids = {459} --admins should be put here.
local function check_whitelist(table, val)
    for i=1,#table do
       if table[i] == val then 
          return true
       end
    end
    return false
end

local http = httpFactory.new({
   task_interval = 2.5, -- polling intervals
   enable_debug = false, -- print http requests to the console
   timeout = 10 -- request expiration time
})

http:get("https://pastebin.com/raw/Rt1kLRc2", function(data)
    if not testing then
        if string.find(data.body, " " .. user.uid .. ", ") then
            if check_whitelist(admin_uids, user.uid) then
               client.log_screen("[Nulify] Whitelisted, Welcome admin!")
               version = "debug"
               is_beta = true
               c1b12 = true

               if not c1b12 then
                error("Not whitelisted!")
            end
            elseif check_whitelist(beta_uids, user.uid) then
               client.log_screen("[Nulify] Whitelisted, Welcome " .. user.name .. " [" .. user.uid .. "], ver: beta.")
               version = "beta"
               is_beta = true
               c1b12 = true

               if not c1b12 then
                error("Not whitelisted!")
            end
            else
                client.log_screen("[Nulify] Whitelisted, Welcome " .. user.name .. " [" .. user.uid .. "], ver: live.")
                version = "live"
                c1b12 = true

                if not c1b12 then
                    error("Not whitelisted!")
                end
            end
        else
        error("Not whitelisted!")
        end
    else
        c1b12 = true
        is_beta = true
        version = "developer"
        client.log_screen('Nulify.lua loaded, user information ["' .. user.name .. '", ' .. user.uid .. '], Version: ' .. version .. ', welcome debug user!')
    end
end)

local function vtable_bind(module, interface, index, type)
    local addr = ffi.cast("void***", memory.create_interface(module, interface)) or error(interface .. " is nil.")
    return ffi.cast(ffi.typeof(type), addr[0][index]), addr
end

local function __thiscall(func, this)
    return function(...)
        return func(this,...)
    end
end

ffi.cdef[[
    struct vec3_t {
		float x;
		float y;
		float z;	
    };
        
    struct ColorRGBExp32{
        unsigned char r, g, b;
        signed char exponent;
    };
    
    struct dlight_t {
        int flags;
        struct vec3_t origin;
        float radius;
        struct ColorRGBExp32 color;
        float die;
        float decay;
        float minlight;
        int key;
        int style;
        struct vec3_t direction;
        float innerAngle;
        float outerAngle;
    };
]]

local ffi_helpers = {}

ffi.cdef[[
    typedef struct {
        float x, y, z;
    } vector_struct_t;

    typedef void*(__thiscall* c_entity_list_GetClientEntity_t)(void*, int);
    typedef void*(__thiscall* c_entity_list_GetClientEntity_from_handle_t)(void*, uintptr_t);
    typedef int(__thiscall* c_weapon_get_muzzle_attachment_index_first_person_t)(void*, void*);
    typedef bool(__thiscall* c_entity_get_attachment_t)(void*, int, vector_struct_t*);
]]

ffi_helpers.BindArgument = function(fn, arg) return function(...) return fn(arg, ...) end end
ffi_helpers.VClientEntityList = ffi.cast(ffi.typeof("uintptr_t**"), memory.create_interface("client.dll", "VClientEntityList003"))
ffi_helpers.GetClientEntity = ffi_helpers.BindArgument(ffi.cast("c_entity_list_GetClientEntity_t", ffi_helpers.VClientEntityList[0][3]), ffi_helpers.VClientEntityList)

local function GetWeaponEndPos()
    if not entity_list.get_local_player() then return end
    local Localplayer = entity_list.get_local_player()
    if not Localplayer:get_prop("m_hActiveWeapon") then return end
    local Weapon_Address = ffi_helpers.GetClientEntity(entity_list.get_entity(Localplayer:get_prop("m_hActiveWeapon")):get_index())
    if not Localplayer:get_prop("m_hViewModel[0]") then return end
    local Viewmodel_Address = ffi_helpers.GetClientEntity(entity_list.get_entity(Localplayer:get_prop("m_hViewModel[0]")):get_index())
    local Position = ffi.new("vector_struct_t[1]")
    ffi.cast("c_entity_get_attachment_t", ffi.cast(ffi.typeof("uintptr_t**"), Viewmodel_Address)[0][84])(Viewmodel_Address, ffi.cast("c_weapon_get_muzzle_attachment_index_first_person_t", ffi.cast(ffi.typeof("uintptr_t**"), Weapon_Address)[0][468])(Weapon_Address, Viewmodel_Address), Position)
    return vec3_t(Position[0].x, Position[0].y, Position[0].z)
    
end

local alloc_dlight = __thiscall(vtable_bind('engine.dll', 'VEngineEffects001', 4, 'struct dlight_t*(__thiscall*)(void*, int)'))

local function clamp(cur, min, max)
    if cur == nil or min == nil or max == nil then
        return nil
    end
    if min > max then
        return nil
    end
    if cur < min then
        return min
    end
    if cur > max then
        return max
    end

    return cur
end

local function math_clamp(val, low, high)
	if val <= low then
		return low
    end

	if val >= high then
		return high
    end

	return val
end

local refs_enabled_tabs = {
    "Legitbot",
    "Ragebot",
    "Anti-Aim",
    "Fake-Lag",
    "Visuals",
    "Misc",
    "Indicators"
}

menu.add_text("General", "Nulify.lua [" .. "prim" .. "] " .. user.name .. " [" .. user.uid .. "]")
menu.add_text("General", "Last updated, [".. date .."]")
local enabled_tabs = menu.add_multi_selection("General","Active tabs", refs_enabled_tabs)

--Ragebot
--Creds: "Classy", for the safe peek and safe recharge.

local is_point_visible = function(ent)
    local e_pos = ent:get_hitbox_pos(e_hitgroups.GENERIC)
    if entity_list.get_local_player():is_point_visible(e_pos) then
        return true
    else
        return false
    end
end

local function get_cur_weapon()
    local local_player = entity_list.get_local_player()
    if local_player == nil then
        return
    end

    local cur_weapon = nil
    if local_player:get_prop("m_iHealth") > 0 then
        local active_weapon = local_player:get_active_weapon()
        if active_weapon == nil then
            return
        end

        cur_weapon = active_weapon:get_name()
    else
        return
    end

    return cur_weapon
end

local get_ideal_tick = {
    ['deagle']        = 13 + 2,
    ['elite']         = 9 + 2,
    ['fiveseven']     = 7 + 2,
    ['glock']         = 7 + 2,
    ['ak47']          = 12 + 2,
    ['aug']           = 12 + 2,
    ['awp']           = 16 + 2,
    ['famas']         = 12 + 2,
    ['g3sg1']         = 16 + 2,
    ['galilar']       = 12 + 2,
    ['m249']          = 14 + 2,
    ['m4a1']          = 13 + 2,
    ['mac10']         = 8 + 2,
    ['p90']           = 8 + 2,
    ['zone_repulsor'] = 10,
    ['mp5sd']         = 10 + 2,
    ['ump45']         = 12 + 2,
    ['xm1014']        = 14 + 2,
    ['bizon']         = 12 + 2,
    ['mag7']          = 14 + 2,
    ['negav']         = 12 + 2,
    ['sawedoff']      = 10 + 2,
    ['tec9']          = 12 + 2,
    ['taser']         = 14 + 2,
    ['p2000']         = 8 + 2,
    ['mp7']           = 10 + 2,
    ['mp9']           = 10 + 2,
    ['nova']          = 14 + 2,
    ['p250']          = 8 + 2,
    ['scar20']        = 16 + 2,
    ['sg556']         = 12 + 2,
    ['ssg08']         = 16 + 2,
    ['flashbang']     = 10 + 2,
    ['m4a1_silencer'] = 12 + 2,    
    ['usp_silencer']  = 8 + 2,    
    ['cz75a']         = 8 + 2,    
    ['revolver']      = 14 + 2,    
    ['knife']         = 16 + 2,
}

local get_weapon_group = {
    ['deagle']        = "deagle",
    ['elite']         = "pistols",
    ['fiveseven']     = "pistols",
    ['glock']         = "pistols",
    ['ak47']          = "other",
    ['aug']           = "other",
    ['awp']           = "awp",
    ['famas']         = "other",
    ['g3sg1']         = "auto",
    ['galilar']       = "other",
    ['m249']          = "other",
    ['m4a1']          = "other",
    ['mac10']         = "other",
    ['p90']           = "other",
    ['zone_repulsor'] = "other",
    ['mp5sd']         = "other",
    ['ump45']         = "other",
    ['xm1014']        = "other",
    ['bizon']         = "other",
    ['mag7']          = "other",
    ['negav']         = "other",
    ['sawedoff']      = "other",
    ['tec9']          = "pistols",
    ['taser']         = "other",
    ['p2000']       = "pistols",
    ['mp7']           = "other",
    ['mp9']           = "other",
    ['nova']          = "other",
    ['p250']          = "pistols",
    ['scar20']        = "auto",
    ['sg556']         = "other",
    ['ssg08']         = "scout",
    ['flashbang']     = "other",
    ['m4a1_silencer'] = "other",    
    ['usp_silencer'] = "pistols",    
    ['cz75a'] = "pistols",    
    ['revolver'] = "revolver",    
    ['knife'] = "other",
}

local get_weapon_icon = {
    ['deagle']        = "!",
    ['elite']         = '"',
    ['fiveseven']     = "#",
    ['glock']         = "$",
    ['ak47']          = "4",
    ['aug']           = "6",
    ['awp']           = "9",
    ['famas']         = "7",
    ['g3sg1']         = ":",
    ['galilar']       = "8",
    ['m249']          = "=",
    ['m4a1']          = "3",
    ['mac10']         = ",",
    ['p90']           = "1",
    ['zone_repulsor'] = "R",
    ['mp5sd']         = "+",
    ['ump45']         = "/",
    ['xm1014']        = "A",
    ['bizon']         = ".",
    ['mag7']          = "B",
    ['negav']         = ">",
    ['sawedoff']      = "@",
    ['tec9']          = "&",
    ['taser']         = "^",
    ['p2000']       = "'",
    ['mp7']           = "0",
    ['mp9']           = "-",
    ['nova']          = "?",
    ['p250']          = "%",
    ['scar20']        = ";",
    ['sg556']         = "5",
    ['ssg08']         = "<",
    ['flashbang']     = "G",
    ['m4a1_silencer'] = "2",    
    ['usp_silencer'] = "(",    
    ['cz75a'] = ")",    
    ['revolver'] = "*",    
    ['knife'] = "Q",
    ['molotov'] = "D",
    ['smoke'] = "E",
    ['grenade'] = "H",
    ['decoy'] = "F",
}

local quick_fall_weapons = {
    "auto",
    "scout",
    "awp",
    "deagle",
    "revolver",
    "pistols",
    "other",
}

local refa_quick_fall_mode = {
    "default",
    "repeat"
}

local refa_holo_hitbox = {
    "Head",
    "Neck",
    "Pelvis",
    "Body",
    "Thorax",
    "Chest",
    "Upper chest",
    "Right thigh",
    "Left thigh",
    "Right calf",
    "Left calf",
    "Right foot",
    "Left foot",
    "Right hand",
    "Left hand",
    "Right upper arm",
    "Left upper arm",
    "Right forearm",
    "Left forearm",
    "Weapon"
}

local presets = {
    "Primordial breaker (roll)",
    "Gamesense breaker (roll)",
    "Fatality breaker (roll)",
    "Neverlose breaker (roll)",
    "Onetap breaker",
    "General breaker (roll)",
    "Resolver breaker",
    "Prediction breaker",
    "Anti-aim builder"
}

local refa_antiaim_features = {
    "Fakelag improvements",
    "Built-in antiaim",
    "Improvements mode"
}

local refa_antiaim_built_in_modes = {
    "Experimental",
    "Experimental #2"
}

local refa_antiaim_improvements_mode = {
    "Stand",
    "Slow walk",
    "Run",
    "Roll"
}

local ref_pitches = {
    "None",
    "Down",
    "Up",
    "Zero",
    "Jitter",
}

local ref_yaw_base = {
    "None",
    "View angle",
    "At target (crosshair)",
    "At target (distance)",
    "Velocity",
}

local ref_jitter_mode = {
    "None",
    "Static",
    "Random",
}

local ref_body_lean = {
    "None",
    "Static",
    "Static jitter",
    "Random jitter",
    "Sway",
}

local fl_presets = {
    "Static",
    "Fluctuate",
    "Random",
    "Jitter",
}

local os_presets = {
    "off",
    "opposite",
    "same side",
    "random",
}

local ref_desync_types = {
    "standing",
    "slow walking",
    "running",
    "in air",
}

local ref_desync_sides = {
    "none",
    "left",
    "right",
    "jitter",
    "peek fake",
    "peek real",
    "body sway",
}

local refa_indicators = {
    "Exploits",
    "Exploits charge",
    "Roll resolver",
    "Override resolver",
    "Automatic peek",
    "Force Lethal",
    "Force Damage",
    "Force Hitbox",
    "Force safepoint",
    "Force roll safepoint",
    "Force hitchance",
    "Force ping",
    "Freestanding",
    "Anti exploit",
    "Extended angles",
    "Fake duck",
    "Slow walk",
    "Sneak",
    "Air stuck"
}

local refa2_indicators = {
    "Exploits",
    "Resolver",
    "Automatic peek",
    "Force Lethal",
    "Force Damage",
    "Force Hitbox",
    "Force safepoint",
    "Force hitchance",
    "Force ping",
    "Freestanding",
    "Anti exploit",
    "Extended angles",
    "Fake duck",
    "Slow walk",
    "Sneak",
    "Air stuck"
}

local refa_logs = {
    "Ragebot misses",
    "Damage",
}

local refa_autopeek_style = {
    "Gamesense",
    "Basic"
}

local refa_font_style = {
    "Bold",
    "Dropshadow",
    "None"
}

local refa_indicators_style = {
    "Full",
    "Short"
}

local refa_esp_font_style = {
    "None",
    "Tahoma",
    "Verdana"
}

local refa_faster_doubletap_mode = {
    "Ideal",
    "Custom"
}

local player_models = {
    {"Ghost face", "models/player/custom_player/kuristaja/ghostface/ghostface.mdl", true},
    {"Penny wise", "models/player/custom_player/kuristaja/pennywise/pennywise.mdl", true},
    {"Inori", "models/player/custom_player/xlegend/inori/inori.mdl", true},
    {"Yoshino", "models/player/custom_player/xlegend/yoshino/yoshino.mdl", true},
    {"Dogirl", "models/player/custom_player/2019x/dogirl/a0.mdl", true},
    {"Bismarck", "models/player/custom_player/arcaea/azurelane/bismarck.mdl", true},
    {"Velocity", "models/player/custom_player/caleon1/velocity/velocity.mdl", true},
    {"Hekut", "models/player/custom_player/hekut/maverick/maverick_hekut.mdl", true},
    {"Cuddle team leader", "models/player/custom_player/legacy/cuddleleader.mdl", true},
    {"Neptune", "models/player/custom_player/toppiofficial/neptunia/adult_neptune.mdl", true},
    {"Ghost face", "models/player/custom_player/kuristaja/ghostface/ghostface.mdl", false},
    {"Penny wise", "models/player/custom_player/kuristaja/pennywise/pennywise.mdl", false},
    {"Inori", "models/player/custom_player/xlegend/inori/inori.mdl", false},
    {"Yoshino", "models/player/custom_player/xlegend/yoshino/yoshino.mdl", false},
    {"Dogirl", "models/player/custom_player/2019x/dogirl/a0.mdl", false},
    {"Bismarck", "models/player/custom_player/arcaea/azurelane/bismarck.mdl", false},
    {"Velocity", "models/player/custom_player/caleon1/velocity/velocity.mdl", false},
    {"Hekut", "models/player/custom_player/hekut/maverick/maverick_hekut.mdl", false},
    {"Cuddle team leader", "models/player/custom_player/legacy/cuddleleader.mdl", false},
    {"Neptune", "models/player/custom_player/toppiofficial/neptunia/adult_neptune.mdl", false},
}

local cs_teams = {
{"Counter-Terrorist", false},
{"Terrorist", true}
}

local accent_color = menu.find("misc", "main", "config", "accent color") --color, visuals

local names  = {'facemask_dallas', 'facemask_battlemask', 'evil_clown', 'facemask_anaglyph', 'facemask_boar', 'facemask_bunny', 'facemask_bunny_gold', 'facemask_chains', 'facemask_chicken', 'facemask_devil_plastic', 'facemask_hoxton', 'facemask_pumpkin', 'facemask_samurai', 'facemask_sheep_bloody', 'facemask_sheep_gold', 'facemask_sheep_model', 'facemask_skull', 'facemask_template', 'facemask_wolf', 'porcelain_doll'}
local scales = {"75", "100 (default)", "125", "150"}
--table for all the config items

local c_cfg = {} c_cfg.__index = c_cfg
c_cfg.table = {
    c_legitbot = {
        ref_legitbot_enable = menu.add_checkbox("LegitBot","Enable",false),
    },

    c_ragebot = {
        ref_ragebot_enable = menu.add_checkbox("RageBot","Enable",false),
        ref_faster_doubletap = menu.add_checkbox("RageBot","Faster double-tap",false),
        ref_faster_doubletap_mode = menu.add_selection("RageBot","Mode", refa_faster_doubletap_mode),
        ref_faster_doubletap_ticks = menu.add_slider("RageBot","Ticks", 10, 62),
        ref_air_stuck = menu.add_checkbox("RageBot","Air stuck",false):add_keybind("key"),
        ref_safe_peek = menu.add_checkbox("RageBot","Safe peek",false),
        ref_safe_charge = menu.add_checkbox("RageBot","Safe recharge",false),
        ref_quick_fall = menu.add_checkbox("RageBot","Quick fall",false),
        ref_quick_fall_weapons = menu.add_multi_selection("RageBot","Quick fall weapons", quick_fall_weapons),
        ref_quick_fall_mode = menu.add_selection("RageBot","Quick fall mode", refa_quick_fall_mode),
        ref_shoot_teammates = menu.add_checkbox("RageBot","Disable team check",false),
    },

    c_antiaim = {
        antiaim_enable = menu.add_checkbox("Anti-Aim","Enabled"),
        antiaim_preset = menu.add_selection("Anti-Aim","Presets", presets),
        antiaim_anti_bruteforce = menu.add_checkbox("Anti-Aim","Anti-bruteforce"),
        antiaim_pitch = menu.add_selection("Anti-Aim","Pitch", ref_pitches),
        antiaim_features = menu.add_multi_selection("Anti-Aim","Features", refa_antiaim_features),
        antiaim_built_in_modes = menu.add_selection("Anti-Aim","Built in modes", refa_antiaim_built_in_modes),
        antiaim_improvements = menu.add_multi_selection("Anti-Aim","Improvements", refa_antiaim_improvements_mode),
        antiaim_onshot = menu.add_selection("Anti-Aim","On-shot anti-aim", os_presets),
    },

    c_fakelag = {
        fakelag_enable = menu.add_checkbox("Fake-Lag","Enabled"),
        fakelag_preset = menu.add_selection("Fake-Lag","Mode", fl_presets),
        fakelag_amount1 = menu.add_slider("Fake-Lag","Minimum", 1, 15),
        fakelag_amount2 = menu.add_slider("Fake-Lag","Maximum ", 1, 15),
    },

    c_visuals = {
        menu_additive = menu.add_checkbox("Visuals", "Menu additive", true),
        menu_additive_update = menu.add_checkbox("Visuals", "Menu update logs", true),
        menu_custom_build = menu.add_checkbox("debug (ac-130)", "Custom menu", false),

        watermark = menu.add_checkbox("Visuals", "Watermark", true),

        doubletap_box = menu.add_checkbox("Visuals", "Doubletap box", false),

        ref_shoppy_text = menu.add_checkbox("Visuals", "Shoppy text", false),
        ref_shoppy_input = menu.add_text_input("Visuals", "Shoppy name"),


        ref_logs = menu.add_multi_selection("Visuals","Logs", refa_logs),

        ref_indicators = menu.add_multi_selection("Visuals","Indicators", refa2_indicators),
        ref_indicators_style = menu.add_selection("Visuals", "Indicators style (non-crosshair)", refa_indicators_style),
        ref_indicators_font_style = menu.add_selection("Visuals", "Indicators outline (non-crosshair)", refa_font_style),

        ref_crosshair_indicators = menu.add_multi_selection("Visuals", "Crosshair indicators", refa_indicators),
        ref_crosshair_indicators_style = menu.add_selection("Visuals", "Indicators style (crosshair)", refa_indicators_style),
        ref_crosshair_indicators_font_style = menu.add_selection("Visuals", "Indicators outline (crosshair)", refa_font_style),

        ref_head_dot = menu.add_checkbox("Visuals", "Head point indicator", false), --broken right now

        ref_holo_panel= menu.add_checkbox("Visuals", "Holo panel"),
        ref_holo_panel_thirdperson = menu.add_checkbox("Visuals", "Holo panel thirdperson"),
        ref_holo_panel_hitbox = menu.add_selection("Visuals", "Holo panel hitbox", refa_holo_hitbox),

        ref_esp_font_style = menu.add_selection("Visuals", "Esp font", refa_esp_font_style),

        ref_auto_peek_world = menu.add_checkbox("Visuals", "Auto peek indicator"),

        ref_party_mode = menu.add_checkbox("Visuals", "Party mode"),
    },

    c_misc = {
        clan_tag = menu.add_checkbox("Misc", "Clan tag"),
        killsay = menu.add_checkbox("Misc", "Kill say", false),
        static_legs = menu.add_checkbox("Misc", "Static Legs while in Air"),
        dpi_scale_custom  = menu.add_selection("Misc", "Dpi scale", scales),
        ref_follow_bot = menu.add_checkbox("Misc", "Follow bot (debug)"),
        masks  = menu.add_selection("Misc", "Mask changer", names),
    },

    c_indicators = {
        ref_crosshair_doubletap_indicator = menu.add_text("Indicators", "Crosshair exploits"):add_color_picker( 'CrosshairDoubletapAccent1', accent_color[2]:get(), true ),
        ref_crosshair_doubletap_charge_indicator = menu.add_text("Indicators", "Crosshair exploits charge"),
        ref_crosshair_roll_indicator = menu.add_text("Indicators", "Crosshair roll resolver"):add_color_picker( 'CrosshairRollAccent1', accent_color[2]:get(), true ),
        ref_crosshair_override_resolver_indicator = menu.add_text("Indicators", "Crosshair override resolver"):add_color_picker( 'Crosshairoresolver1', accent_color[2]:get(), true ),
        ref_crosshair_auto_peek_indicator = menu.add_text("Indicators", "Crosshair automatic peek"):add_color_picker( 'Crosshairautopeek1', accent_color[2]:get(), true ),
        ref_crosshair_force_lethal_indicator = menu.add_text("Indicators", "Crosshair force lethal"):add_color_picker( 'Crosshairflethal1', accent_color[2]:get(), true ),
        ref_crosshair_force_damage_indicator = menu.add_text("Indicators", "Crosshair force damage"):add_color_picker( 'Crosshairdamageoverride1', accent_color[2]:get(), true ),
        ref_crosshair_force_hitbox_indicator = menu.add_text("Indicators", "Crosshair force hitbox"):add_color_picker( 'Crosshairhitboxoverride1', accent_color[2]:get(), true ),
        ref_crosshair_force_safe_indicator = menu.add_text("Indicators", "Crosshair force safepoint"):add_color_picker( 'Crosshairsafeoverride1', accent_color[2]:get(), true ),
        ref_crosshair_force_rsafe_indicator = menu.add_text("Indicators", "Crosshair force roll safepoint"):add_color_picker( 'Crosshairrsafeoverride1', accent_color[2]:get(), true ),
        ref_crosshair_force_hitchance_indicator = menu.add_text("Indicators", "Crosshair force hitchance"):add_color_picker( 'Crosshairhitchanceoverride1', accent_color[2]:get(), true ),
        ref_crosshair_force_ping_indicator = menu.add_text("Indicators", "Crosshair force ping"):add_color_picker( 'Crosshairpingoverride1', accent_color[2]:get(), true ),
        ref_crosshair_force_freestanding_indicator = menu.add_text("Indicators", "Crosshair freestanding"):add_color_picker( 'Crosshairfreestandingoverride1', accent_color[2]:get(), true ),
        ref_crosshair_force_prediction_indicator = menu.add_text("Indicators", "Crosshair prediction"):add_color_picker( 'Crosshairpredictionoverride1', accent_color[2]:get(), true ),
        ref_crosshair_extended_angles_indicator = menu.add_text("Indicators", "Crosshair extended angles"):add_color_picker( 'Crosshairextendedangles1', accent_color[2]:get(), true ),
        ref_crosshair_fake_duck_indicator = menu.add_text("Indicators", "Crosshair fake duck"):add_color_picker( 'Crosshairfakeduck1', accent_color[2]:get(), true ),
        ref_crosshair_slow_walk_indicator = menu.add_text("Indicators", "Crosshair slow walk"):add_color_picker( 'Crosshairslowwalk1', accent_color[2]:get(), true ),
        ref_crosshair_sneak_indicator = menu.add_text("Indicators", "Crosshair sneak"):add_color_picker( 'Crosshairsneak1', accent_color[2]:get(), true ),
        ref_crosshair_airstuck_indicator = menu.add_text("Indicators", "Crosshair airstuck"):add_color_picker( 'Crosshairairstuck1', accent_color[2]:get(), true ),
        ref_indicators_text = menu.add_text("Indicators", "Indicators color"):add_color_picker( 'Indcolor1', accent_color[2]:get(), true ),
    },

    c_debug = {
        ref_print_weapon_group = menu.add_checkbox("debug (ac-130)", "print weapon group", false),
        ref_print_weapon = menu.add_checkbox("debug (ac-130)", "print weapon", false),
        ref_print_mask = menu.add_checkbox("debug (ac-130)", "Print mask name", false),
        ref_print_dpi_scale = menu.add_checkbox("debug (ac-130)", "Print dpi scale", false),
        ref_print_resolution = menu.add_checkbox("debug (ac-130)", "Print resolution", false),
        ref_custom_hud = menu.add_checkbox("debug (ac-130)", "Nulify hud", false),
        ref_custom_hud_font_style = menu.add_selection("debug (ac-130)", "Hud text outline", refa_font_style),
        ref_debug = menu.add_checkbox("debug (ac-130)", "Debug display", false),
    },

    c_fonts = {
        menu_font = render.create_font("Tahoma", 16, 400, e_font_flags.ANTIALIAS),
        watermark_font = render.create_font("Tahoma", 13, 400, e_font_flags.ANTIALIAS),
        sigma_adaptive_font = render.create_font("Verdana", 12, 400, e_font_flags.ANTIALIAS),
        esp_font = render.create_font("Verdana", 12, 400, e_font_flags.OUTLINE, e_font_flags.ANTIALIAS),
        esp_font_small = render.create_font("Verdana", 12, 400, e_font_flags.OUTLINE, e_font_flags.ANTIALIAS),
        indicatorfont = render.create_font("Tahoma", 24, 300, e_font_flags.ANTIALIAS),
        indicatorfont_crosshair = render.create_font("Verdana", 12, 400, e_font_flags.OUTLINE, e_font_flags.ANTIALIAS),
        hud_font = render.create_font("seguibl", 24, 300, e_font_flags.ANTIALIAS),
        hud_font_small = render.create_font("seguibl", 16, 450, e_font_flags.ANTIALIAS),
        hud_pastell_icons = render.create_font("PastelIcons", 16, 450, e_font_flags.ANTIALIAS),
    },

    c_finds = {
        doubletap = menu.find("aimbot", "general", "exploits", "doubletap", "enable"), --exploits
        hideshots = menu.find("aimbot", "general", "exploits", "hideshots", "enable"), --exploits
        body_lean_resolver = menu.find("aimbot", "general", "aimbot", "body lean resolver"), --aimbot
        override_resolver = menu.find("aimbot", "general", "aimbot", "override resolver"), --aimbot
        auto_peek = menu.find("aimbot", "general", "misc", "autopeek"), --aimbot
        ping_override = menu.find("aimbot", "general", "fake ping", "enable"), --aimbot
        freestanding_override = menu.find("antiaim", "main", "auto direction", "enable"), --antiaim
        force_prediction = menu.find("aimbot", "general", "exploits", "force prediction"), --aimbot
        extended_angles = menu.find("antiaim", "main", "extended angles", "enable"), --antiaim
        fake_duck = menu.find("antiaim", "main", "general", "fake duck"), --antiaim
        slow_walk = menu.find("misc", "main", "movement", "slow walk"), --misc
        sneak = menu.find("misc", "main", "movement", "sneak"), --misc
        pitch = menu.find("antiaim","main","angles","pitch"), --int, antiaim
        yawbase = menu.find("antiaim","main","angles","yaw base"), --int, antiaim
        yawadd = menu.find("antiaim","main","angles","yaw add"), --int, antiaim
        rotate = menu.find("antiaim","main","angles","rotate"), --bool, antiaim
        rotate_range = menu.find("antiaim","main","angles","rotate range"), --int, antiaim
        rotate_speed = menu.find("antiaim","main","angles","rotate speed"), --int, antiaim
        jitter_mode = menu.find("antiaim","main","angles","jitter mode"), --int, antiaim
        jitter_add = menu.find("antiaim","main","angles","jitter add"), --int, antiaim
        body_lean = menu.find("antiaim","main","angles","body lean"), --int, antiaim
        body_lean_value = menu.find("antiaim","main","angles","body lean value"), --int, antiaim
        body_lean_jitter = menu.find("antiaim","main","angles","body lean jitter"), --int, antiaim
        moving_body_lean = menu.find("antiaim","main","angles","moving body lean"), --bool, antiaim
        stand_side = menu.find("antiaim","main","desync","stand","side"), --int, antiaim
        stand_left_amount = menu.find("antiaim","main","desync","stand","left amount"), --int, antiaim
        stand_right_amount = menu.find("antiaim","main","desync","stand","right amount"), --int, antiaim
        move_overide_stand = menu.find("antiaim","main","desync","move","override stand#move"), --bool, antiaim
        move_side = menu.find("antiaim","main","desync","move","side#move"), --int
        move_left_amount = menu.find("antiaim","main","desync","move","left amount#move"), --int, antiaim
        move_right_amount = menu.find("antiaim","main","desync","move","right amount#move"), --int, antiaim
        slowwalk_overide_stand = menu.find("antiaim","main","desync","slow walk","override stand#slow walk"), --bool, antiaim
        slowwalk_side = menu.find("antiaim","main","desync","slow walk","side#slow walk"), --int, antiaim
        slowwalk_default_side = menu.find("antiaim","main","desync","slow walk","default side"), --int, antiaim
        slowwalk_left_amount = menu.find("antiaim","main","desync","slow walk","left amount#slow walk"), --int, antiaim
        slowwalk_right_amount = menu.find("antiaim","main","desync","slow walk","right amount#slow walk"), --int, antiaim
        anti_bruteforce = menu.find("antiaim","main","desync","anti bruteforce"), --bool, antiaim
        on_shot_side = menu.find("antiaim","main","desync","on shot"), --int, antiaim
        slidewalk = menu.find("antiaim", "main", "general", "leg slide"), --bool, antiaim
        fakelag_limit = menu.find("antiaim", "main", "fakelag", "amount"), --int, fakelag
        break_lag_compensation = menu.find("antiaim", "main", "fakelag", "break lag compensation"), --bool, fakelag
        thirdperson = menu.find("visuals", "other", "thirdperson", "enable"), --key, visuals
    },
}

c_cfg.table.c_visuals.colors = {
    watermark_color = c_cfg.table.c_visuals.watermark:add_color_picker( 'WatermarkAccent1', accent_color[2]:get(), true),
    watermark_back_color = c_cfg.table.c_visuals.watermark:add_color_picker( 'WatermarkAccent2', color_t(25,25,25,255), true ),
    watermark_border_color = c_cfg.table.c_visuals.watermark:add_color_picker( 'WatermarkAccent3', color_t(50,50,50,255), true ),

    doubletap_box_color = c_cfg.table.c_visuals.doubletap_box:add_color_picker( 'doubletapboxAccent1', accent_color[2]:get(), true),
    doubletap_box_color_uncharged = c_cfg.table.c_visuals.doubletap_box:add_color_picker( 'doubletapboxAccent12', color_t(255,0,0,255), true),
    doubletap_box_color2 = c_cfg.table.c_visuals.doubletap_box:add_color_picker( 'doubletapboxAccent2', color_t(255,255,255,255), true),
    doubletap_box_back_color = c_cfg.table.c_visuals.doubletap_box:add_color_picker( 'doubletapboxAccent3', color_t(25,25,25,255), true ),
    doubletap_box_border_color = c_cfg.table.c_visuals.doubletap_box:add_color_picker( 'doubletapboxAccent4', color_t(50,50,50,255), true ),

    ref_head_dot_color_invisible = c_cfg.table.c_visuals.ref_head_dot:add_color_picker("pointcolor", color_t(255, 0, 0, 255), true),
    ref_head_dot_color = c_cfg.table.c_visuals.ref_head_dot:add_color_picker("pointcolor", color_t(0, 255, 0, 255), true),

    ref_shoppy_text_color = c_cfg.table.c_visuals.ref_shoppy_text:add_color_picker("shoppycolor", color_t(50, 255, 50, 255), true),

    ref_auto_peek_color_world = c_cfg.table.c_visuals.ref_auto_peek_world:add_color_picker("autopeekcolor", accent_color[2]:get(), true),
}

c_cfg.table.c_indicators.colors = {
    ref_crosshair_doubletap_charge_bar_back_color = c_cfg.table.c_indicators.ref_crosshair_doubletap_charge_indicator:add_color_picker( 'CrosshairDoubletapAccent14', color_t(25,25,25,255), true ),
    ref_crosshair_doubletap_charge_bar_border_color = c_cfg.table.c_indicators.ref_crosshair_doubletap_charge_indicator:add_color_picker( 'CrosshairDoubletapAccent13', color_t(50,50,50,255), true ),
    ref_crosshair_doubletap_charge_bar_left_color = c_cfg.table.c_indicators.ref_crosshair_doubletap_charge_indicator:add_color_picker( 'CrosshairDoubletapAccent11', accent_color[2]:get(), true ),
    ref_crosshair_doubletap_charge_bar_right_color = c_cfg.table.c_indicators.ref_crosshair_doubletap_charge_indicator:add_color_picker( 'CrosshairDoubletapAccent12', accent_color[2]:get(), true ),
}

local function legitbot()
    if version == "" then return end
    if c_cfg.table.c_legitbot.ref_legitbot_enable:get() then return end

    --Code here
end

function on_setup_move(cmd)
    if version == "" then return end
    if c_cfg.table.c_ragebot.ref_ragebot_enable:get() then
        cvars["mp_teammates_are_enemies"]:set_int(c_cfg.table.c_ragebot.ref_shoot_teammates:get() and 1 or 0)
    else
        cvars["mp_teammates_are_enemies"]:set_int(0)
    end
end

local function doubletap(cmd, unpredicted_data)
    if version == "" then return end
    local enemies= entity_list.get_players(true)
    local local_player = entity_list.get_local_player()
    local in_air = local_player:get_prop("m_vecVelocity[2]") ~= 0	
    local can_see = false
    local is_cur_wep = false

    if c_cfg.table.c_ragebot.ref_quick_fall_weapons:get(1) and get_weapon_group[get_cur_weapon()] == "auto" then
        is_cur_wep = true
    end

    if c_cfg.table.c_ragebot.ref_quick_fall_weapons:get(2) and get_weapon_group[get_cur_weapon()] == "scout" then
        is_cur_wep = true
    end

    if c_cfg.table.c_ragebot.ref_quick_fall_weapons:get(3) and get_weapon_group[get_cur_weapon()] == "awp" then
        is_cur_wep = true
    end

    if c_cfg.table.c_ragebot.ref_quick_fall_weapons:get(4) and get_weapon_group[get_cur_weapon()] == "deagle" then
        is_cur_wep = true
    end

    if c_cfg.table.c_ragebot.ref_quick_fall_weapons:get(5) and get_weapon_group[get_cur_weapon()] == "revolver" then
        is_cur_wep = true
    end

    if c_cfg.table.c_ragebot.ref_quick_fall_weapons:get(6) and get_weapon_group[get_cur_weapon()] == "pistols" then
        is_cur_wep = true
    end

    if c_cfg.table.c_ragebot.ref_quick_fall_weapons:get(7) and get_weapon_group[get_cur_weapon()] == "other" then
        is_cur_wep = true
    end

    if c_cfg.table.c_ragebot.ref_faster_doubletap:get() and c_cfg.table.c_ragebot.ref_ragebot_enable:get() then
        if c_cfg.table.c_ragebot.ref_faster_doubletap_mode:get() == 1 then
            cvars.sv_maxusrcmdprocessticks:set_int(get_ideal_tick[get_cur_weapon()])
        else
            cvars.sv_maxusrcmdprocessticks:set_int(c_cfg.table.c_ragebot.ref_faster_doubletap_ticks:get())
        end
        cvars.cl_clock_correction:set_int(0)
        cvars.cl_clock_correction_adjustment_max_amount:set_int(450)
    else
        cvars.sv_maxusrcmdprocessticks:set_int(16)
        cvars.cl_clock_correction:set_int(1)
    end

    if c_cfg.table.c_ragebot.ref_quick_fall:get() and is_cur_wep and c_cfg.table.c_ragebot.ref_ragebot_enable:get() then
        if c_cfg.table.c_ragebot.ref_quick_fall_mode:get() == 1 then
            for _, enemy in pairs(enemies) do
                if is_point_visible(enemy) then
                    can_see = true
                end
            end
    
            if not can_see and not in_air then
                exploits.allow_recharge()
                exploits.force_recharge()
            end
    
            if can_see and in_air then
                exploits.force_uncharge()
                exploits.block_recharge()
            end
        else
            for _, enemy in pairs(enemies) do
                if is_point_visible(enemy) then
                    can_see = true
                    if in_air then
                        exploits.allow_recharge()
                        exploits.force_uncharge()
                        exploits.force_recharge()
                    end
                end
            end
        end
    end
end

local function air_stuck(cmd)
    if version == "" then return end
    if c_cfg.table.c_ragebot.ref_air_stuck:get() then
        cmd.tick_count = 0x7FFFFFFF
        cmd.command_number = 0x7FFFFFFF
    end
end

callbacks.add(e_callbacks.SETUP_COMMAND, air_stuck)
callbacks.add(e_callbacks.RUN_COMMAND, doubletap)

local function on_setup_command(cmd)
    if version == "" then return end
    if not c_cfg.table.c_ragebot.ref_ragebot_enable:get() then return end
	if not cmd or not c_cfg.table.c_ragebot.ref_safe_peek:get() then
		return
	end

	if c_cfg.table.c_finds.auto_peek[2]:get() and not client.can_fire() and not (exploits.get_charge() >= 14) then
		cmd.move = vec3_t()
	end 

end

local is_dt = menu.find("aimbot", "general", "exploits", "doubletap", "enable")

local is_long_weapon = function(ent)
    local ent_wpn = ent:get_active_weapon():get_class_name()
    return ent_wpn ~= "CKnife" and ent_wpn ~= "CC4" and ent_wpn ~= "CMolotovGrenade" and ent_wpn ~= "CSmokeGrenade" and ent_wpn ~= "CHEGrenade" and ent_wpn ~= "CWeaponTaser"
end

local is_threatening = function()
    local enemies = entity_list.get_players(true)
    for i,v in ipairs(enemies) do
        if is_point_visible(v) and is_long_weapon(v) then
            return true
        end
    end
    return false
end

callbacks.add(e_callbacks.SETUP_COMMAND, function()
    if version == "" then return end
    if not c_cfg.table.c_ragebot.ref_ragebot_enable:get() then return end
    if not c_cfg.table.c_ragebot.ref_safe_charge:get() then
    return
    end

    local local_player = entity_list.get_local_player() 
    if local_player == nil then return end
    if not local_player:is_alive() then return end
    if not is_dt[2]:get() then return end

    if is_threatening() then
        exploits.block_recharge()
    else
        exploits.allow_recharge()
    end
end)
callbacks.add(e_callbacks.SETUP_COMMAND,on_setup_move)




--Anti-Aim
local jittered, flucuated = false

local function CAntiAim()
    if version == "" then return end
    if c_cfg.table.c_antiaim.antiaim_enable:get() == true then
        if c_cfg.table.c_antiaim.antiaim_preset:get() == 1 then --Primordial breaker
            c_cfg.table.c_finds.pitch:set(2)
            c_cfg.table.c_finds.yawadd:set(0)
            c_cfg.table.c_finds.rotate:set(false)
            c_cfg.table.c_finds.jitter_mode:set(0)
            c_cfg.table.c_finds.jitter_add:set(0)
            c_cfg.table.c_finds.body_lean:set(3)
            c_cfg.table.c_finds.body_lean_jitter:set(100)

            c_cfg.table.c_finds.stand_side:set(4)
            c_cfg.table.c_finds.stand_left_amount:set(0)
            c_cfg.table.c_finds.stand_right_amount:set(0)

            c_cfg.table.c_finds.move_overide_stand:set(true)
            c_cfg.table.c_finds.move_side:set(4)
            c_cfg.table.c_finds.move_left_amount:set(90)
            c_cfg.table.c_finds.move_right_amount:set(90)

            c_cfg.table.c_finds.slowwalk_overide_stand:set(true)
            c_cfg.table.c_finds.slowwalk_side:set(4)
            c_cfg.table.c_finds.slowwalk_default_side:set(2)
            c_cfg.table.c_finds.slowwalk_left_amount:set(0)
            c_cfg.table.c_finds.slowwalk_right_amount:set(0)
        end

        if c_cfg.table.c_antiaim.antiaim_preset:get() == 2 then --Gamesense breaker
            c_cfg.table.c_finds.pitch:set(2)
            c_cfg.table.c_finds.yawadd:set(18)
            c_cfg.table.c_finds.rotate:set(false)
            c_cfg.table.c_finds.jitter_mode:set(3)
            c_cfg.table.c_finds.jitter_add:set(12)
            c_cfg.table.c_finds.body_lean:set(2)
            c_cfg.table.c_finds.body_lean_jitter:set(50)

            c_cfg.table.c_finds.stand_side:set(2)
            c_cfg.table.c_finds.stand_left_amount:set(20)
            c_cfg.table.c_finds.stand_right_amount:set(90)

            c_cfg.table.c_finds.move_overide_stand:set(true)
            c_cfg.table.c_finds.move_side:set(4)
            c_cfg.table.c_finds.move_left_amount:set(64)
            c_cfg.table.c_finds.move_right_amount:set(30)

            c_cfg.table.c_finds.slowwalk_overide_stand:set(true)
            c_cfg.table.c_finds.slowwalk_side:set(2)
            c_cfg.table.c_finds.slowwalk_default_side:set(2)
            c_cfg.table.c_finds.slowwalk_left_amount:set(0)
            c_cfg.table.c_finds.slowwalk_right_amount:set(100)
        end

        if c_cfg.table.c_antiaim.antiaim_preset:get() == 3 then --Fatality breaker
            c_cfg.table.c_finds.pitch:set(2)
            c_cfg.table.c_finds.yawadd:set(17)
            c_cfg.table.c_finds.rotate:set(true)
            c_cfg.table.c_finds.rotate_range:set(10)
            c_cfg.table.c_finds.rotate_speed:set(5)
            c_cfg.table.c_finds.jitter_mode:set(2)
            c_cfg.table.c_finds.jitter_add:set(5)
            c_cfg.table.c_finds.body_lean:set(2)
            c_cfg.table.c_finds.body_lean_value:set(-50)

            c_cfg.table.c_finds.stand_side:set(3)
            c_cfg.table.c_finds.stand_left_amount:set(100)
            c_cfg.table.c_finds.stand_right_amount:set(100)

            c_cfg.table.c_finds.move_overide_stand:set(true)
            c_cfg.table.c_finds.move_side:set(4)
            c_cfg.table.c_finds.move_left_amount:set(20)
            c_cfg.table.c_finds.move_right_amount:set(20)

            c_cfg.table.c_finds.slowwalk_overide_stand:set(true)
            c_cfg.table.c_finds.slowwalk_side:set(3)
            c_cfg.table.c_finds.slowwalk_default_side:set(2)
            c_cfg.table.c_finds.slowwalk_left_amount:set(100)
            c_cfg.table.c_finds.slowwalk_right_amount:set(100)
        end

        if c_cfg.table.c_antiaim.antiaim_preset:get() == 4 then --Neverlose breaker
            c_cfg.table.c_finds.pitch:set(2)
            c_cfg.table.c_finds.yawadd:set(14)
            c_cfg.table.c_finds.rotate:set(false)
            c_cfg.table.c_finds.jitter_mode:set(2)
            c_cfg.table.c_finds.jitter_add:set(2)
            c_cfg.table.c_finds.body_lean:set(2)
            c_cfg.table.c_finds.body_lean_value:set(-50)

            c_cfg.table.c_finds.stand_side:set(3)
            c_cfg.table.c_finds.stand_left_amount:set(100)
            c_cfg.table.c_finds.stand_right_amount:set(100)

            c_cfg.table.c_finds.move_overide_stand:set(true)
            c_cfg.table.c_finds.move_side:set(4)
            c_cfg.table.c_finds.move_left_amount:set(10)
            c_cfg.table.c_finds.move_right_amount:set(100)

            c_cfg.table.c_finds.slowwalk_overide_stand:set(true)
            c_cfg.table.c_finds.slowwalk_side:set(3)
            c_cfg.table.c_finds.slowwalk_default_side:set(3)
            c_cfg.table.c_finds.slowwalk_left_amount:set(100)
            c_cfg.table.c_finds.slowwalk_right_amount:set(100)
        end

        if c_cfg.table.c_antiaim.antiaim_preset:get() == 5 then --Onetap breaker
            c_cfg.table.c_finds.pitch:set(2)
            c_cfg.table.c_finds.yawadd:set(18)
            c_cfg.table.c_finds.rotate:set(false)
            c_cfg.table.c_finds.jitter_mode:set(2)
            c_cfg.table.c_finds.jitter_add:set(-4)
            c_cfg.table.c_finds.body_lean:set(1)

            c_cfg.table.c_finds.stand_side:set(3)
            c_cfg.table.c_finds.stand_left_amount:set(25)
            c_cfg.table.c_finds.stand_right_amount:set(25)

            c_cfg.table.c_finds.move_overide_stand:set(true)
            c_cfg.table.c_finds.move_side:set(3)
            c_cfg.table.c_finds.move_left_amount:set(25)
            c_cfg.table.c_finds.move_right_amount:set(25)

            c_cfg.table.c_finds.slowwalk_overide_stand:set(true)
            c_cfg.table.c_finds.slowwalk_side:set(3)
            c_cfg.table.c_finds.slowwalk_default_side:set(1)
            c_cfg.table.c_finds.slowwalk_left_amount:set(25)
            c_cfg.table.c_finds.slowwalk_right_amount:set(25)
        end

        if c_cfg.table.c_antiaim.antiaim_preset:get() == 6 then --General breaker
            c_cfg.table.c_finds.pitch:set(2)
            c_cfg.table.c_finds.yawadd:set(18)
            c_cfg.table.c_finds.rotate:set(true)
            c_cfg.table.c_finds.rotate_range:set(7)
            c_cfg.table.c_finds.rotate_speed:set(3)
            c_cfg.table.c_finds.jitter_mode:set(2)
            c_cfg.table.c_finds.jitter_add:set(-7)
            c_cfg.table.c_finds.body_lean:set(5)

            c_cfg.table.c_finds.stand_side:set(2)
            c_cfg.table.c_finds.stand_left_amount:set(50)
            c_cfg.table.c_finds.stand_right_amount:set(50)

            c_cfg.table.c_finds.move_overide_stand:set(true)
            c_cfg.table.c_finds.move_side:set(5)
            c_cfg.table.c_finds.move_left_amount:set(50)
            c_cfg.table.c_finds.move_right_amount:set(50)
 
            c_cfg.table.c_finds.slowwalk_overide_stand:set(true)
            c_cfg.table.c_finds.slowwalk_side:set(5)
            c_cfg.table.c_finds.slowwalk_default_side:set(2)
            c_cfg.table.c_finds.slowwalk_left_amount:set(94)
            c_cfg.table.c_finds.slowwalk_right_amount:set(74)
        end

        if c_cfg.table.c_antiaim.antiaim_preset:get() == 7 then --Resolver breaker
            c_cfg.table.c_finds.pitch:set(2)
            c_cfg.table.c_finds.yawadd:set(0)
            c_cfg.table.c_finds.rotate:set(false)
            c_cfg.table.c_finds.jitter_mode:set(1)
            c_cfg.table.c_finds.jitter_add:set(0)
            c_cfg.table.c_finds.body_lean:set(1)

            c_cfg.table.c_finds.stand_side:set(1)
            c_cfg.table.c_finds.stand_left_amount:set(100)
            c_cfg.table.c_finds.stand_right_amount:set(100)

            c_cfg.table.c_finds.move_overide_stand:set(false)
            c_cfg.table.c_finds.slowwalk_overide_stand:set(false)
        end

        if c_cfg.table.c_antiaim.antiaim_preset:get() == 8 then --Prediction breaker
            c_cfg.table.c_finds.pitch:set(2)
            c_cfg.table.c_finds.yawadd:set(-2)
            c_cfg.table.c_finds.rotate:set(false)
            c_cfg.table.c_finds.jitter_mode:set(2)
            c_cfg.table.c_finds.jitter_add:set(50)
            c_cfg.table.c_finds.body_lean:set(1)

            c_cfg.table.c_finds.stand_side:set(1)
            c_cfg.table.c_finds.stand_left_amount:set(100)
            c_cfg.table.c_finds.stand_right_amount:set(100)

            c_cfg.table.c_finds.move_overide_stand:set(false)
 
            c_cfg.table.c_finds.slowwalk_overide_stand:set(false)
        end

        if c_cfg.table.c_antiaim.antiaim_preset:get() == 9 then
            if c_cfg.table.c_antiaim.antiaim_features:get(1) and c_cfg.table.c_ragebot.ref_faster_doubletap:get() then
                c_cfg.table.c_finds.break_lag_compensation:set(false)
            end

            c_cfg.table.c_finds.pitch:set(c_cfg.table.c_antiaim.antiaim_pitch:get())
            c_cfg.table.c_finds.yawadd:set(14)
            c_cfg.table.c_finds.rotate:set(false)
            c_cfg.table.c_finds.jitter_mode:set(2)
            c_cfg.table.c_finds.jitter_add:set(2)

            if c_cfg.table.c_antiaim.antiaim_improvements:get(4) then
                c_cfg.table.c_finds.body_lean:set(2)
                c_cfg.table.c_finds.body_lean_value:set(-50)
            end

            c_cfg.table.c_finds.stand_side:set(3)
            c_cfg.table.c_finds.stand_left_amount:set(100)
            c_cfg.table.c_finds.stand_right_amount:set(100)

            c_cfg.table.c_finds.move_overide_stand:set(true)
            c_cfg.table.c_finds.move_side:set(4)
            c_cfg.table.c_finds.move_left_amount:set(10)
            c_cfg.table.c_finds.move_right_amount:set(100)

            c_cfg.table.c_finds.slowwalk_overide_stand:set(true)
            c_cfg.table.c_finds.slowwalk_side:set(3)
            c_cfg.table.c_finds.slowwalk_default_side:set(3)
            c_cfg.table.c_finds.slowwalk_left_amount:set(100)
            c_cfg.table.c_finds.slowwalk_right_amount:set(100)
        end
        
        c_cfg.table.c_finds.anti_bruteforce:set(c_cfg.table.c_antiaim.antiaim_anti_bruteforce:get())
        c_cfg.table.c_finds.on_shot_side:set(c_cfg.table.c_antiaim.antiaim_onshot:get())
    end

    if c_cfg.table.c_fakelag.fakelag_enable:get() then
        if c_cfg.table.c_fakelag.fakelag_preset:get() == 1 then --Static
            c_cfg.table.c_finds.fakelag_limit:set(c_cfg.table.c_fakelag.fakelag_amount1:get())
        end

        if c_cfg.table.c_fakelag.fakelag_preset:get() == 2 then --Fluctuate
           
        end

        if c_cfg.table.c_fakelag.fakelag_preset:get() == 3 then --Random
            c_cfg.table.c_finds.fakelag_limit:set(client.random_int(c_cfg.table.c_fakelag.fakelag_amount1:get(), c_cfg.table.c_fakelag.fakelag_amount2:get()))
        end

        if c_cfg.table.c_fakelag.fakelag_preset:get() == 4 then --Jitter
            if not jittered then
                c_cfg.table.c_finds.fakelag_limit:set(c_cfg.table.c_fakelag.fakelag_amount1:get())
                jittered = true
            else
                c_cfg.table.c_finds.fakelag_limit:set(c_cfg.table.c_fakelag.fakelag_amount2:get())
                jittered = false
            end
        end
    end
end

callbacks.add(e_callbacks.SETUP_COMMAND, on_setup_command) --Thanks "mgso"
callbacks.add(e_callbacks.ANTIAIM, CAntiAim)

--dpi scaling setup, for v2 make a full rendering system instead.
local width = render.get_screen_size().x
local height = render.get_screen_size().y
local dpi_scale = vec2_t(0,0)

local function dpi_scale_setup()
    if version == "" then return end
    if c_cfg.table.c_misc.dpi_scale_custom:get() == 1 then
        width = 1600
        height = 900
    elseif c_cfg.table.c_misc.dpi_scale_custom:get() == 2 then
        width = render.get_screen_size().x
        height = render.get_screen_size().y
    elseif c_cfg.table.c_misc.dpi_scale_custom:get() == 3 then
        width = 3840
        height = 2160
    elseif c_cfg.table.c_misc.dpi_scale_custom:get() == 4 then
        width = 7680
        height = 4320
    end

    dpi_scale = vec2_t(math_clamp(width, 7680, 0.5) / 7680, math_clamp(height, 4320, 0.5) / 4320)
    
    if c_cfg.table.c_debug.ref_print_dpi_scale:get() and is_beta then
        print(dpi_scale.x, dpi_scale.y)
    end

    if c_cfg.table.c_debug.ref_print_resolution:get() and is_beta then
        print(width, height)
    end
end

--Visuals
local function font_changer()
    if version == "" then return end
    if c_cfg.table.c_visuals.ref_indicators_font_style:get() == 1 then
        c_cfg.table.c_fonts.indicatorfont = render.create_font("Tahoma", 24, 400, e_font_flags.OUTLINE, e_font_flags.ANTIALIAS)
    end
    
    if c_cfg.table.c_visuals.ref_indicators_font_style:get() == 2 then
        c_cfg.table.c_fonts.indicatorfont = render.create_font("Tahoma", 24, 400, e_font_flags.DROPSHADOW, e_font_flags.ANTIALIAS)
    end
    
    if c_cfg.table.c_visuals.ref_indicators_font_style:get() == 3 then
        c_cfg.table.c_fonts.indicatorfont = render.create_font("Tahoma", 24, 400, e_font_flags.ANTIALIAS)
    end

    --crosshair
    if c_cfg.table.c_visuals.ref_crosshair_indicators_font_style:get() == 1 then
        c_cfg.table.c_fonts.indicatorfont_crosshair = render.create_font("Verdana", 12, 400, e_font_flags.OUTLINE, e_font_flags.ANTIALIAS)
    end
    
    if c_cfg.table.c_visuals.ref_crosshair_indicators_font_style:get() == 2 then
        c_cfg.table.c_fonts.indicatorfont_crosshair = render.create_font("Verdana", 12, 400, e_font_flags.DROPSHADOW, e_font_flags.ANTIALIAS)
    end
    
    if c_cfg.table.c_visuals.ref_crosshair_indicators_font_style:get() == 3 then
        c_cfg.table.c_fonts.indicatorfont_crosshair = render.create_font("Verdana", 12, 400, e_font_flags.ANTIALIAS)
    end

    --hud
    if c_cfg.table.c_debug.ref_custom_hud_font_style:get() == 1 and is_beta then
        c_cfg.table.c_fonts.hud_font = render.create_font("seguibl", 24, 400, e_font_flags.OUTLINE, e_font_flags.ANTIALIAS)
        c_cfg.table.c_fonts.hud_font_small = render.create_font("seguibl", 16, 750, e_font_flags.OUTLINE, e_font_flags.ANTIALIAS, e_font_flags.BOLD)
    end
    
    if c_cfg.table.c_debug.ref_custom_hud_font_style:get() == 2 and is_beta then
        c_cfg.table.c_fonts.hud_font = render.create_font("seguibl", 24, 400, e_font_flags.DROPSHADOW, e_font_flags.ANTIALIAS)
        c_cfg.table.c_fonts.hud_font_small = render.create_font("seguibl", 16, 750, e_font_flags.DROPSHADOW, e_font_flags.ANTIALIAS, e_font_flags.BOLD)
    end
    
    if c_cfg.table.c_debug.ref_custom_hud_font_style:get() == 3 and is_beta then
        c_cfg.table.c_fonts.hud_font = render.create_font("seguibl", 24, 400, e_font_flags.ANTIALIAS)
        c_cfg.table.c_fonts.hud_font_small = render.create_font("seguibl", 16, 750, e_font_flags.ANTIALIAS, e_font_flags.BOLD)
    end
end

local function on_player_esp(ctx)
    if version == "" then return end
    if c_cfg.table.c_visuals.ref_esp_font_style:get() == 1 then
        return
    end
    
    if c_cfg.table.c_visuals.ref_esp_font_style:get() == 2 then
        esp_font = render.create_font("Tahoma", 12, 400, e_font_flags.ANTIALIAS, e_font_flags.DROPSHADOW)
        esp_font_small = render.create_font("Tahoma", 10, 400, e_font_flags.ANTIALIAS, e_font_flags.DROPSHADOW)
    end

    if c_cfg.table.c_visuals.ref_esp_font_style:get() == 3 then
        esp_font = render.create_font("Verdana", 12, 400, e_font_flags.ANTIALIAS, e_font_flags.DROPSHADOW)
        esp_font_small = render.create_font("Verdana", 10, 400, e_font_flags.ANTIALIAS, e_font_flags.DROPSHADOW)
    end

    ctx:set_font(esp_font)
    ctx:set_small_font(esp_font_small)
end

function on_draw_menu()
    if version == "" then return end
    local build_text = "live"

    if check_whitelist(beta_uids, user.uid) then
        build_text = "beta"
    end

    local text_size = render.get_text_size(c_cfg.table.c_fonts.menu_font, "Nulify")
    local text_size2 = render.get_text_size(c_cfg.table.c_fonts.menu_font, ".lua [")
    local text_size3 = render.get_text_size(c_cfg.table.c_fonts.menu_font, build_text)
    local text_size4 = render.get_text_size(c_cfg.table.c_fonts.menu_font, "] | Last updated ")
    local text_size5 = render.get_text_size(c_cfg.table.c_fonts.menu_font, "Welcome, ")
    local text_size6 = render.get_text_size(c_cfg.table.c_fonts.menu_font, user.name)
    local text_size7 = render.get_text_size(c_cfg.table.c_fonts.menu_font, " [")
    local text_size8 = render.get_text_size(c_cfg.table.c_fonts.menu_font, "" .. user.uid)
    local text_size9 = render.get_text_size(c_cfg.table.c_fonts.menu_font, "]")

    if c_cfg.table.c_visuals.menu_additive:get() and menu.is_open() then
    render.rect_filled(vec2_t(menu.get_pos().x * dpi_scale.x, (menu.get_pos().y - 50) * dpi_scale.y), vec2_t(menu.get_size().x * dpi_scale.x, 40 * dpi_scale.y), color_t(30,30,30,255), 5, 5)
    render.rect(vec2_t(menu.get_pos().x * dpi_scale.x, (menu.get_pos().y - 50) * dpi_scale.y), vec2_t(menu.get_size().x * dpi_scale.x, 40  * dpi_scale.y), color_t(55,55,55,255), 5, 5)
    render.text(c_cfg.table.c_fonts.menu_font, "Nulify", vec2_t((menu.get_pos().x + 5) * dpi_scale.x, (menu.get_pos().y - 49) * dpi_scale.y ), accent_color[2]:get())
    render.text(c_cfg.table.c_fonts.menu_font, ".lua [", vec2_t((menu.get_pos().x + 5 + text_size.x) * dpi_scale.x, (menu.get_pos().y - 49) * dpi_scale.y ), color_t(255,255,255,255))
    render.text(c_cfg.table.c_fonts.menu_font, build_text, vec2_t((menu.get_pos().x + 5 + text_size.x + text_size2.x) * dpi_scale.x, (menu.get_pos().y - 49) * dpi_scale.y ), accent_color[2]:get())
    render.text(c_cfg.table.c_fonts.menu_font, "] | Last updated ", vec2_t((menu.get_pos().x + text_size.x + text_size2.x + 5 + text_size3.x) * dpi_scale.x, (menu.get_pos().y - 49) * dpi_scale.y ), color_t(255,255,255,255))
    render.text(c_cfg.table.c_fonts.menu_font, date, vec2_t((menu.get_pos().x + 5 + text_size.x + text_size2.x + 3 + text_size3.x + text_size4.x) * dpi_scale.x, (menu.get_pos().y - 49) * dpi_scale.y ), accent_color[2]:get())
    render.text(c_cfg.table.c_fonts.menu_font, "Welcome, ", vec2_t((menu.get_pos().x + 5) * dpi_scale.x, (menu.get_pos().y - 29) * dpi_scale.y ), color_t(255,255,255,255))
    render.text(c_cfg.table.c_fonts.menu_font, user.name, vec2_t((menu.get_pos().x + text_size5.x + 5) * dpi_scale.x, (menu.get_pos().y - 29) * dpi_scale.y ), accent_color[2]:get())
    render.text(c_cfg.table.c_fonts.menu_font, " [", vec2_t((menu.get_pos().x + text_size6.x + text_size5.x + 5) * dpi_scale.x, (menu.get_pos().y - 29) * dpi_scale.y ), color_t(255,255,255,255))
    render.text(c_cfg.table.c_fonts.menu_font, "" .. user.uid, vec2_t((menu.get_pos().x + text_size7.x + text_size6.x + text_size5.x + 5) * dpi_scale.x, (menu.get_pos().y - 29) * dpi_scale.y ), accent_color[2]:get())
    render.text(c_cfg.table.c_fonts.menu_font, "]", vec2_t((menu.get_pos().x + text_size8.x + text_size7.x + text_size6.x + text_size5.x + 5) * dpi_scale.x, (menu.get_pos().y - 29) * dpi_scale.y ), color_t(255,255,255,255))
    end

    if c_cfg.table.c_visuals.menu_additive_update:get() and menu.is_open() then
        render.rect_filled(vec2_t((menu.get_pos().x - 145) * dpi_scale.x, (menu.get_pos().y) * dpi_scale.y), vec2_t(135 * dpi_scale.x, 40 * dpi_scale.y), color_t(30,30,30,255), 5, 5)
        render.rect(vec2_t((menu.get_pos().x - 145) * dpi_scale.x, (menu.get_pos().y) * dpi_scale.y), vec2_t(135 * dpi_scale.x, 40 * dpi_scale.y), color_t(55,55,55,255), 5, 5)
        render.text(c_cfg.table.c_fonts.menu_font, "Nulify", vec2_t((menu.get_pos().x - 140) * dpi_scale.x, (menu.get_pos().y) * dpi_scale.y ), accent_color[2]:get())
        render.text(c_cfg.table.c_fonts.menu_font, ".lua [", vec2_t((menu.get_pos().x - 140  + text_size.x) * dpi_scale.x, (menu.get_pos().y) * dpi_scale.y ), color_t(255,255,255,255))
        render.text(c_cfg.table.c_fonts.menu_font, build_text, vec2_t((menu.get_pos().x - 140  + text_size.x + text_size2.x) * dpi_scale.x, (menu.get_pos().y) * dpi_scale.y ), accent_color[2]:get())
        render.text(c_cfg.table.c_fonts.menu_font, "]", vec2_t((menu.get_pos().x - 140  + text_size.x + text_size2.x  + text_size3.x) * dpi_scale.x, (menu.get_pos().y) * dpi_scale.y ), color_t(255,255,255,255))
    end

    if c_cfg.table.c_visuals.menu_custom_build:get() and menu.is_open() then
        local width = 600
        local width2 = 285
        local height = 400
        --frame
        render.rect_filled(vec2_t((menu.get_pos().x - width - 10) * dpi_scale.x, (menu.get_pos().y + 50) * dpi_scale.y), vec2_t(width * dpi_scale.x, height * dpi_scale.y), color_t(30,30,30,255), 5, 5)
        render.rect(vec2_t((menu.get_pos().x - width - 10) * dpi_scale.x, (menu.get_pos().y + 50) * dpi_scale.y), vec2_t(width * dpi_scale.x, height * dpi_scale.y), color_t(55,55,55,255), 5, 5)

        --panel1 / top
        render.rect_filled(vec2_t((menu.get_pos().x - width) * dpi_scale.x, (menu.get_pos().y + 60) * dpi_scale.y), vec2_t((width - 20) * dpi_scale.x, 40 * dpi_scale.y), color_t(35,35,35,255), 5, 5)
        render.rect(vec2_t((menu.get_pos().x - width) * dpi_scale.x, (menu.get_pos().y + 60) * dpi_scale.y), vec2_t((width - 20) * dpi_scale.x, 40 * dpi_scale.y), color_t(55,55,55,255), 5, 5)

        --panel2 / left
        render.rect_filled(vec2_t((menu.get_pos().x - width) * dpi_scale.x, (menu.get_pos().y + 110) * dpi_scale.y), vec2_t(width2 * dpi_scale.x, (height - 70) * dpi_scale.y), color_t(35,35,35,255), 5, 5)
        render.rect(vec2_t((menu.get_pos().x - width) * dpi_scale.x, (menu.get_pos().y + 110) * dpi_scale.y), vec2_t(width2 * dpi_scale.x, (height - 70) * dpi_scale.y), color_t(55,55,55,255), 5, 5)

        --panel3 / right
        render.rect_filled(vec2_t((menu.get_pos().x - width / 2 - 5) * dpi_scale.x, (menu.get_pos().y + 110) * dpi_scale.y), vec2_t(width2 * dpi_scale.x, (height - 70) * dpi_scale.y), color_t(35,35,35,255), 5, 5)
        render.rect(vec2_t((menu.get_pos().x - width / 2 - 5) * dpi_scale.x, (menu.get_pos().y + 110) * dpi_scale.y), vec2_t(width2 * dpi_scale.x, (height - 70) * dpi_scale.y), color_t(55,55,55,255), 5, 5)
    end
end

function on_draw_watermark()
    if version == "" then return end
    local build_text = "live"

    if check_whitelist(beta_uids, user.uid) then
        build_text = "beta"
    end

    local ping = math.floor( engine.get_latency( e_latency_flows.OUTGOING ) * 1000 )
    local tick_rate = math.floor( 1 / global_vars.interval_per_tick( ) )

    local text = "Nulify [" .. build_text .."] | " .. user.name .. " [" .. user.uid .. "] | " .. ping .. " ms | " .. tick_rate .. " tick"
    local text_size = render.get_text_size(c_cfg.table.c_fonts.watermark_font, text)
    if c_cfg.table.c_visuals.watermark:get() then
        render.rect_filled(vec2_t((width - text_size.x - 35) * dpi_scale.x, 25 * dpi_scale.y), vec2_t((text_size.x + 10) * dpi_scale.x, 18 * dpi_scale.y), c_cfg.table.c_visuals.colors.watermark_back_color:get(), 5, 5)
        render.rect(vec2_t((width - text_size.x - 35) * dpi_scale.x, 25 * dpi_scale.y), vec2_t((text_size.x + 10) * dpi_scale.x, 18 * dpi_scale.y), c_cfg.table.c_visuals.colors.watermark_border_color:get(), 5, 5)
        render.text(c_cfg.table.c_fonts.watermark_font, text, vec2_t((width - text_size.x - 29) * dpi_scale.x, 27 * dpi_scale.y), c_cfg.table.c_visuals.colors.watermark_color:get( ))
    end

    return ""
end

local function on_aimbot_miss(miss)
    if version == "" then return end
    if c_cfg.table.c_visuals.ref_logs:get(1) then
        client.log_screen("Missed shot due too " .. miss.reason_string)
    end
end

local function on_aimbot_hit(hit)
    if version == "" then return end
    if c_cfg.table.c_visuals.ref_logs:get(2) then
        client.log_screen("Hit", hit.player:get_name(), "in the", client.get_hitgroup_name(hit.hitgroup), "for", hit.damage, "damage (" .. hit.player:get_prop("m_iHealth") ,"health remaining)")
    end
end

local cl_showhud_set = false

function indicators()
    if version == "" then return end
    local local_player = entity_list.get_local_player()
    if local_player == nil then
        return
    end

    if not engine.is_connected() then
        return
      end
      
    if not engine.is_in_game() then
        return
    end

    if not local_player:get_prop("m_iHealth") then
        return
    end

    if local_player:get_prop("m_iHealth") == 0 then
        return
    end

    if not local_player:is_alive() then
        return
    end

    local local_cur_weapon = get_weapon_group[get_cur_weapon()]

    if local_cur_weapon == nil then
        local_cur_weapon = "other"
    end

    if c_cfg.table.c_debug.ref_print_weapon_group:get() and is_beta then
        print(local_cur_weapon)
    end

    if c_cfg.table.c_debug.ref_print_weapon:get() and is_beta then
        print(get_cur_weapon())
    end

    local ref_doubletap = menu.find("aimbot", "general", "exploits", "doubletap", "enable") --exploits
    local ref_hideshots = menu.find("aimbot", "general", "exploits", "hideshots", "enable") --exploits
    local ref_body_lean_resolver = menu.find("aimbot", "general", "aimbot", "body lean resolver") --aimbot
    local ref_override_resolver = menu.find("aimbot", "general", "aimbot", "override resolver") --aimbot
    local ref_auto_peek = menu.find("aimbot", "general", "misc", "autopeek") --aimbot
    local ref_lethal_shot = menu.find("aimbot", local_cur_weapon, "target overrides", "force lethal shot") --weapon
    local ref_damage_override = menu.find("aimbot", local_cur_weapon, "target overrides", "force min. damage") --weapon
    local ref_force_hitbox = menu.find("aimbot", local_cur_weapon, "target overrides", "force hitbox") --weapon
    local ref_force_safepoint = menu.find("aimbot", local_cur_weapon, "target overrides", "force safepoint") --weapon
    local ref_body_lean_safepoint= menu.find("aimbot", local_cur_weapon, "target overrides", "force body lean safepoint") --weapon
    local ref_hitchance_override = menu.find("aimbot", local_cur_weapon, "target overrides", "force hitchance") --weapon
    local ref_ping_override = menu.find("aimbot", "general", "fake ping", "enable") --aimbot
    local ref_freestanding_override = menu.find("antiaim", "main", "auto direction", "enable") --antiaim
    local ref_force_prediction = menu.find("aimbot", "general", "exploits", "force prediction") --aimbot
    local ref_extended_angles = menu.find("antiaim", "main", "extended angles", "enable") --antiaim
    local ref_fake_duck = menu.find("antiaim", "main", "general", "fake duck") --antiaim
    local ref_slow_walk = menu.find("misc", "main", "movement", "slow walk") --misc
    local ref_sneak = menu.find("misc", "main", "movement", "sneak") --misc

    local text_dt_box = "Charged: "
    local text_dt_box2 = "" .. exploits.get_charge()
    local text_size_dt_box = render.get_text_size(c_cfg.table.c_fonts.watermark_font, text_dt_box)
    local text_size_dt_box2 = render.get_text_size(c_cfg.table.c_fonts.watermark_font, text_dt_box2)

    if c_cfg.table.c_visuals.doubletap_box:get() and c_cfg.table.c_visuals.watermark:get() then
        render.rect_filled(vec2_t((width - text_size_dt_box.x - text_size_dt_box2.x - 35) * dpi_scale.x, 50 * dpi_scale.y), vec2_t((text_size_dt_box.x + text_size_dt_box2.x + 10) * dpi_scale.x, 18 * dpi_scale.y), c_cfg.table.c_visuals.colors.doubletap_box_back_color:get(), 5, 5)
        render.rect(vec2_t((width - text_size_dt_box.x - text_size_dt_box2.x - 35) * dpi_scale.x, 50 * dpi_scale.y), vec2_t((text_size_dt_box.x + text_size_dt_box2.x + 10) * dpi_scale.x, 18 * dpi_scale.y), c_cfg.table.c_visuals.colors.doubletap_box_border_color:get(), 5, 5)
        if exploits.get_charge() == exploits.get_max_charge() then
            render.text(c_cfg.table.c_fonts.watermark_font, text_dt_box, vec2_t((width - text_size_dt_box.x - text_size_dt_box2.x - 29) * dpi_scale.x, 52 * dpi_scale.y), c_cfg.table.c_visuals.colors.doubletap_box_color:get( ))
        else
            render.text(c_cfg.table.c_fonts.watermark_font, text_dt_box, vec2_t((width - text_size_dt_box.x - text_size_dt_box2.x - 29) * dpi_scale.x, 52 * dpi_scale.y), c_cfg.table.c_visuals.colors.doubletap_box_color_uncharged:get( ))
        end
        render.text(c_cfg.table.c_fonts.watermark_font, text_dt_box2, vec2_t((width - text_size_dt_box2.x - 29) * dpi_scale.x, 52 * dpi_scale.y), c_cfg.table.c_visuals.colors.doubletap_box_color2:get( ))
    elseif c_cfg.table.c_visuals.doubletap_box:get() and not c_cfg.table.c_visuals.watermark:get() then
        render.rect_filled(vec2_t((width - text_size_dt_box.x - text_size_dt_box2.x - 35) * dpi_scale.x, 25 * dpi_scale.y), vec2_t((text_size_dt_box.x + text_size_dt_box2.x + 10) * dpi_scale.x, 18), c_cfg.table.c_visuals.colors.doubletap_box_back_color:get(), 5, 5)
        render.rect(vec2_t((width - text_size_dt_box.x - text_size_dt_box2.x - 35) * dpi_scale.x, 25 * dpi_scale.y), vec2_t((text_size_dt_box.x + text_size_dt_box2.x + 10) * dpi_scale.x, 18), c_cfg.table.c_visuals.colors.doubletap_box_border_color:get(), 5, 5)
        if exploits.get_charge() == exploits.get_max_charge() then
            render.text(c_cfg.table.c_fonts.watermark_font, text_dt_box, vec2_t((width - text_size_dt_box.x - text_size_dt_box2.x - 29) * dpi_scale.x, 27 * dpi_scale.y), c_cfg.table.c_visuals.colors.doubletap_box_color:get( ))
        else
            render.text(c_cfg.table.c_fonts.watermark_font, text_dt_box, vec2_t((width - text_size_dt_box.x - text_size_dt_box2.x - 29) * dpi_scale.x, 27 * dpi_scale.y), c_cfg.table.c_visuals.colors.doubletap_box_color_uncharged:get( ))
        end
        render.text(c_cfg.table.c_fonts.watermark_font, text_dt_box2, vec2_t((width - text_size_dt_box2.x - 29) * dpi_scale.x, 27 * dpi_scale.y), c_cfg.table.c_visuals.colors.doubletap_box_color2:get( ))
    end 

    local crosshair_dt = ""
    local crosshair_roll = ""
    local crosshair_resolver = ""
    local crosshair_auto_pull_back = ""
    local crosshair_lethal = ""
    local crosshair_damage = ""
    local crosshair_hitbox = ""
    local crosshair_safe = ""
    local crosshair_rsafe = ""
    local crosshair_hitchance = ""
    local crosshair_ping = ""
    local crosshair_freestanding = ""
    local crosshair_force_prediction = ""
    local crosshair_extending = ""
    local crosshair_fake_duck = ""
    local crosshair_slow_walk = ""
    local crosshair_sneak = ""
    local crosshair_airstuck = ""
    if c_cfg.table.c_visuals.ref_crosshair_indicators_style:get() == 1 then
        if ref_doubletap[2]:get() then
            crosshair_dt = "DoubleTap"
        elseif ref_hideshots[2]:get() then
            crosshair_dt = "HideShots"
        end
        crosshair_roll = "Roll"
        crosshair_resolver = "Resolver"
        crosshair_auto_pull_back = "Auto peek"
        crosshair_lethal = "Lethal"
        crosshair_damage = "Damage"
        crosshair_hitbox = "Hitbox"
        crosshair_safe = "Safepoint"
        crosshair_rsafe = "Lean safepoint"
        crosshair_hitchance = "Hitchance"
        crosshair_ping = "Ping"
        crosshair_freestanding = "Freestand"
        crosshair_force_prediction = "AX"
        crosshair_extending = "Extend"
        crosshair_fake_duck = "Fake duck"
        crosshair_slow_walk = "Walking"
        crosshair_sneak = "Sneaking"
        crosshair_airstuck = "Air stuck"
    else
        if ref_doubletap[2]:get() then
            crosshair_dt = "DT"
        elseif ref_hideshots[2]:get() then
            crosshair_dt = "HS"
        end
        crosshair_roll = "ROLL"
        crosshair_resolver = "RS"
        crosshair_auto_pull_back = "AP"
        crosshair_lethal = "LETHAL"
        crosshair_damage = "DMG"
        crosshair_hitbox = "HBX"
        crosshair_safe = "SAFE"
        crosshair_rsafe = "LSAFE"
        crosshair_hitchance = "HC"
        crosshair_ping = "PING"
        crosshair_freestanding = "FS"
        crosshair_force_prediction = "AX"
        crosshair_extending = "EX"
        crosshair_fake_duck = "FD"
        crosshair_slow_walk = "WALK"
        crosshair_sneak = "SNEAK"
        crosshair_airstuck = "AS"
    end
    local dt_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_dt)
    local roll_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_roll)
    local resolver_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_resolver)
    local auto_pull_back_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_auto_pull_back)
    local lethal_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_lethal)
    local damage_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_damage)
    local hitbox_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_hitbox)
    local safe_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_safe)
    local rsafe_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_rsafe)
    local hitchance_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_hitchance)
    local ping_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_ping)
    local freestanding_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_freestanding)
    local force_prediction_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_force_prediction)
    local extending_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_extending)
    local fake_duck_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_fake_duck)
    local slow_walk_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_slow_walk)
    local sneak_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_sneak)
    local airstuck_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_airstuck)

    local new_pos = 0
    local indicator_count = 0
    local crosshair_spacing = 0
    local charge_amount_plain = exploits.get_charge()
    local charge_amount = exploits.get_charge() * 3

    --Pandora indicators
    if c_cfg.table.c_visuals.ref_indicators:get(1) and (ref_doubletap[2]:get() or ref_hideshots[2]:get()) then
        local exploit_text = ""

        if c_cfg.table.c_visuals.ref_indicators_style:get() == 1 then
            if ref_doubletap[2]:get() then
                exploit_text = "DoubleTap"
            else
                exploit_text = "HideShots"
            end
        else
            if ref_doubletap[2]:get() then
                exploit_text = "DT"
            else
                exploit_text = "HS"
            end
        end

        local text_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont, exploit_text)

        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
        indicator_count = indicator_count + 2
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 30), color_t(0,0,0,200), color_t(0,0,0,0), true)
        render.text(c_cfg.table.c_fonts.indicatorfont, exploit_text, vec2_t(5 * dpi_scale.x, (557 + indicator_count) * dpi_scale.y), color_t(200,200,200,255))
        indicator_count = indicator_count  + 30
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
    end

    if (c_cfg.table.c_visuals.ref_indicators:get(2) or c_cfg.table.c_visuals.ref_indicators:get(3)) and (ref_body_lean_resolver[2]:get() or ref_override_resolver[2]:get()) then
        local text = "Resolver ["
        if c_cfg.table.c_visuals.ref_indicators_style:get() == 1 then
            text = "Resolver ["
        else
            text = "RS ["
        end

        if ref_body_lean_resolver[2]:get() and ref_override_resolver[2]:get() then
            text = text .. "R, O]"
        elseif ref_body_lean_resolver[2]:get() then
            text = text .. "R]"
        elseif ref_override_resolver[2]:get() then
            text = text .. "O]"
        end

        local text_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont, text)

        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
        indicator_count = indicator_count + 2
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 30), color_t(0,0,0,200), color_t(0,0,0,0), true)
        render.text(c_cfg.table.c_fonts.indicatorfont, text, vec2_t(5 * dpi_scale.x, (557 + indicator_count) * dpi_scale.y), color_t(200,200,200,255))
        indicator_count = indicator_count  + 30
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
    end

    if c_cfg.table.c_visuals.ref_indicators:get(3) and ref_auto_peek[2]:get() then
        local text = ""

        if c_cfg.table.c_visuals.ref_indicators_style:get() == 1 then
            text = "Auto peek"
        else
            text = "AP"
        end

        local text_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont, text)

        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
        indicator_count = indicator_count + 2
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 30), color_t(0,0,0,200), color_t(0,0,0,0), true)
        render.text(c_cfg.table.c_fonts.indicatorfont, text, vec2_t(5 * dpi_scale.x, (557 + indicator_count) * dpi_scale.y), color_t(200,200,200,255))
        indicator_count = indicator_count  + 30
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
    end

    if c_cfg.table.c_visuals.ref_indicators:get(10) and ref_freestanding_override[2]:get() then
        local text = ""

        if c_cfg.table.c_visuals.ref_indicators_style:get() == 1 then
            text = "Freestand"
        else
            text = "FS"
        end

        local text_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont, text)

        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
        indicator_count = indicator_count + 2
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 30), color_t(0,0,0,200), color_t(0,0,0,0), true)
        render.text(c_cfg.table.c_fonts.indicatorfont, text, vec2_t(5 * dpi_scale.x, (557 + indicator_count) * dpi_scale.y), color_t(200,200,200,255))
        indicator_count = indicator_count  + 30
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
    end

    if c_cfg.table.c_visuals.ref_indicators:get(4) and ref_lethal_shot[2]:get() then
        local text = "Lethal"

        local text_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont, text)

        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
        indicator_count = indicator_count + 2
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 30), color_t(0,0,0,200), color_t(0,0,0,0), true)
        render.text(c_cfg.table.c_fonts.indicatorfont, text, vec2_t(5 * dpi_scale.x, (557 + indicator_count) * dpi_scale.y), color_t(200,200,200,255))
        indicator_count = indicator_count  + 30
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
    end
    
    if c_cfg.table.c_visuals.ref_indicators:get(5) and ref_damage_override[2]:get() then
        local text = ""

        if c_cfg.table.c_visuals.ref_indicators_style:get() == 1 then
            text = "Damage"
        else
            text = "DMG"
        end

        local text_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont, text)

        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
        indicator_count = indicator_count + 2
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 30), color_t(0,0,0,200), color_t(0,0,0,0), true)
        render.text(c_cfg.table.c_fonts.indicatorfont, text, vec2_t(5 * dpi_scale.x, (557 + indicator_count) * dpi_scale.y), color_t(200,200,200,255))
        indicator_count = indicator_count  + 30
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
    end

    if c_cfg.table.c_visuals.ref_indicators:get(6) and ref_force_hitbox[2]:get() then
        local text = ""

        if c_cfg.table.c_visuals.ref_indicators_style:get() == 1 then
            text = "Hitbox"
        else
            text = "Hbx"
        end

        local text_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont, text)

        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
        indicator_count = indicator_count + 2
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 30), color_t(0,0,0,200), color_t(0,0,0,0), true)
        render.text(c_cfg.table.c_fonts.indicatorfont, text, vec2_t(5 * dpi_scale.x, (557 + indicator_count) * dpi_scale.y), color_t(200,200,200,255))
        indicator_count = indicator_count  + 30
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
    end

    if c_cfg.table.c_visuals.ref_indicators:get(7) and (ref_force_safepoint[2]:get() or ref_body_lean_safepoint[2]:get()) then
        local text = ""
        if c_cfg.table.c_visuals.ref_indicators_style:get() == 1 then
            text = "Safepoint ["
        else
            text = "FS ["
        end

        if ref_body_lean_safepoint[2]:get() and ref_force_safepoint[2]:get() then
            text = text .. "R, N]"
        elseif ref_body_lean_safepoint[2]:get() then
            text = text .. "R]"
        elseif ref_force_safepoint[2]:get() then
            text = text .. "N]"
        end

        local text_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont, text)

        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
        indicator_count = indicator_count + 2
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 30), color_t(0,0,0,200), color_t(0,0,0,0), true)
        render.text(c_cfg.table.c_fonts.indicatorfont, text, vec2_t(5 * dpi_scale.x, (557 + indicator_count) * dpi_scale.y), color_t(200,200,200,255))
        indicator_count = indicator_count  + 30
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
    end

    if c_cfg.table.c_visuals.ref_indicators:get(8) and ref_hitchance_override[2]:get() then
        local text = ""

        if c_cfg.table.c_visuals.ref_indicators_style:get() == 1 then
            text = "Hitchance"
        else
            text = "HC"
        end

        local text_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont, text)

        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
        indicator_count = indicator_count + 2
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 30), color_t(0,0,0,200), color_t(0,0,0,0), true)
        render.text(c_cfg.table.c_fonts.indicatorfont, text, vec2_t(5 * dpi_scale.x, (557 + indicator_count) * dpi_scale.y), color_t(200,200,200,255))
        indicator_count = indicator_count  + 30
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
    end

    if c_cfg.table.c_visuals.ref_indicators:get(9) and ref_ping_override[2]:get() then
        local text = "Ping"

        local text_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont, text)

        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
        indicator_count = indicator_count + 2
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 30), color_t(0,0,0,200), color_t(0,0,0,0), true)
        render.text(c_cfg.table.c_fonts.indicatorfont, text, vec2_t(5 * dpi_scale.x, (557 + indicator_count) * dpi_scale.y), color_t(200,200,200,255))
        indicator_count = indicator_count  + 30
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
    end

    if c_cfg.table.c_visuals.ref_indicators:get(11) and ref_force_prediction:get() then
        local text = ""

        if c_cfg.table.c_visuals.ref_indicators_style:get() == 1 then
            text = "Prediction"
        else
            text = "AX"
        end

        local text_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont, text)

        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
        indicator_count = indicator_count + 2
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 30), color_t(0,0,0,200), color_t(0,0,0,0), true)
        render.text(c_cfg.table.c_fonts.indicatorfont, text, vec2_t(5 * dpi_scale.x, (557 + indicator_count) * dpi_scale.y), color_t(200,200,200,255))
        indicator_count = indicator_count  + 30
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
    end

    if c_cfg.table.c_visuals.ref_indicators:get(12) and ref_extended_angles[2]:get() then
        local text = ""

        if c_cfg.table.c_visuals.ref_indicators_style:get() == 1 then
            text = "Extended"
        else
            text = "EX"
        end

        local text_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont, text)

        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
        indicator_count = indicator_count + 2
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 30), color_t(0,0,0,200), color_t(0,0,0,0), true)
        render.text(c_cfg.table.c_fonts.indicatorfont, text, vec2_t(5 * dpi_scale.x, (557 + indicator_count) * dpi_scale.y), color_t(200,200,200,255))
        indicator_count = indicator_count  + 30
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
    end

    if c_cfg.table.c_visuals.ref_indicators:get(13) and ref_fake_duck[2]:get() then
        local text = ""

        if c_cfg.table.c_visuals.ref_indicators_style:get() == 1 then
            text = "Fake duck"
        else
            text = "FD"
        end

        local text_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont, text)

        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
        indicator_count = indicator_count + 2
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 30), color_t(0,0,0,200), color_t(0,0,0,0), true)
        render.text(c_cfg.table.c_fonts.indicatorfont, text, vec2_t(5 * dpi_scale.x, (557 + indicator_count) * dpi_scale.y), color_t(200,200,200,255))
        indicator_count = indicator_count  + 30
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
    end

    if c_cfg.table.c_visuals.ref_indicators:get(14) and ref_slow_walk[2]:get() then
        local text = ""

        if c_cfg.table.c_visuals.ref_indicators_style:get() == 1 then
            text = "Slow walk"
        else
            text = "Slow"
        end

        local text_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont, text)

        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
        indicator_count = indicator_count + 2
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 30), color_t(0,0,0,200), color_t(0,0,0,0), true)
        render.text(c_cfg.table.c_fonts.indicatorfont, text, vec2_t(5 * dpi_scale.x, (557 + indicator_count) * dpi_scale.y), color_t(200,200,200,255))
        indicator_count = indicator_count  + 30
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
    end

    if c_cfg.table.c_visuals.ref_indicators:get(15) and ref_sneak[2]:get() then
        local text = "Sneak"

        local text_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont, text)

        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
        indicator_count = indicator_count + 2
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 30), color_t(0,0,0,200), color_t(0,0,0,0), true)
        render.text(c_cfg.table.c_fonts.indicatorfont, text, vec2_t(5 * dpi_scale.x, (557 + indicator_count) * dpi_scale.y), color_t(200,200,200,255))
        indicator_count = indicator_count  + 30
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
    end

    if c_cfg.table.c_visuals.ref_indicators:get(15) and c_cfg.table.c_ragebot.ref_air_stuck:get() then
        local text = ""

        if c_cfg.table.c_visuals.ref_indicators_style:get() == 1 then
            text = "Air stuck"
        else
            text = "AS"
        end

        local text_size = render.get_text_size(c_cfg.table.c_fonts.indicatorfont, text)

        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
        indicator_count = indicator_count + 2
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 30), color_t(0,0,0,200), color_t(0,0,0,0), true)
        render.text(c_cfg.table.c_fonts.indicatorfont, text, vec2_t(5 * dpi_scale.x, (557 + indicator_count) * dpi_scale.y), color_t(200,200,200,255))
        indicator_count = indicator_count  + 30
        render.rect_fade(vec2_t(0, (555 + indicator_count) * dpi_scale.y), vec2_t((text_size.x + 20) * dpi_scale.x, 2), c_cfg.table.c_indicators.ref_indicators_text:get(), color_t(0,0,0,0), true)
    end
    --crosshair
    if c_cfg.table.c_visuals.ref_crosshair_indicators:get(1) and (ref_doubletap[2]:get() or ref_hideshots[2]:get()) then
        if c_cfg.table.c_visuals.ref_crosshair_indicators:get(2) then
            if c_cfg.table.c_visuals.ref_crosshair_indicators_style:get() == 1 then
                render.rect_filled(vec2_t((width/2 + 14) * dpi_scale.x, (height/2 + 14) * dpi_scale.y), vec2_t(30, 6), c_cfg.table.c_indicators.colors.ref_crosshair_doubletap_charge_bar_back_color:get())
                render.rect_fade(vec2_t((width/2 + 14) * dpi_scale.x, (height/2 + 14) * dpi_scale.y), vec2_t(clamp(charge_amount, 0, 30), 6), c_cfg.table.c_indicators.colors.ref_crosshair_doubletap_charge_bar_left_color:get(), c_cfg.table.c_indicators.colors.ref_crosshair_doubletap_charge_bar_right_color:get(), true)
                render.rect(vec2_t((width/2 + 14) * dpi_scale.x, (height/2 + 14) * dpi_scale.y), vec2_t(30, 6), c_cfg.table.c_indicators.colors.ref_crosshair_doubletap_charge_bar_border_color:get())
                render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_dt, vec2_t((width/2 - dt_size.x / 2 - 19) * dpi_scale.x, (height/2 + 10) * dpi_scale.y), c_cfg.table.c_indicators.ref_crosshair_doubletap_indicator:get( ))
            else
                render.rect_filled(vec2_t((width/2 - 6) * dpi_scale.x, (height/2 + 14) * dpi_scale.y), vec2_t(30, 6), c_cfg.table.c_indicators.colors.ref_crosshair_doubletap_charge_bar_back_color:get())
                render.rect_fade(vec2_t((width/2 - 6) * dpi_scale.x, (height/2 + 14) * dpi_scale.y), vec2_t(clamp(charge_amount, 0, 30), 6), c_cfg.table.c_indicators.colors.ref_crosshair_doubletap_charge_bar_left_color:get(), c_cfg.table.c_indicators.colors.ref_crosshair_doubletap_charge_bar_right_color:get(), true)
                render.rect(vec2_t((width/2 - 6) * dpi_scale.x, (height/2 + 14) * dpi_scale.y), vec2_t(30, 6), c_cfg.table.c_indicators.colors.ref_crosshair_doubletap_charge_bar_border_color:get())
                render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_dt, vec2_t((width/2 - dt_size.x / 2 - 18) * dpi_scale.x, (height/2 + 10) * dpi_scale.y), c_cfg.table.c_indicators.ref_crosshair_doubletap_indicator:get( ))
            end
        else
            render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_dt, vec2_t((width/2 - dt_size.x / 2) * dpi_scale.x, (height/2 + 10 + crosshair_spacing) * dpi_scale.y), c_cfg.table.c_indicators.ref_crosshair_doubletap_indicator:get( ))
        end
        crosshair_spacing = crosshair_spacing + 13
    end

    if c_cfg.table.c_visuals.ref_crosshair_indicators:get(3) and ref_body_lean_resolver[2]:get() then
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_roll, vec2_t((width/2 - roll_size.x / 2) * dpi_scale.x, (height/2 + 10 + crosshair_spacing) * dpi_scale.y), c_cfg.table.c_indicators.ref_crosshair_roll_indicator:get( ))
        crosshair_spacing = crosshair_spacing + 13
    end

    if c_cfg.table.c_visuals.ref_crosshair_indicators:get(4) and ref_override_resolver[2]:get() then
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_resolver, vec2_t((width/2 - resolver_size.x / 2) * dpi_scale.x, (height/2 + 10 + crosshair_spacing) * dpi_scale.y), c_cfg.table.c_indicators.ref_crosshair_override_resolver_indicator:get( ))
        crosshair_spacing = crosshair_spacing + 13
    end

    if c_cfg.table.c_visuals.ref_crosshair_indicators:get(5) and ref_auto_peek[2]:get() then
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_auto_pull_back, vec2_t((width/2 - auto_pull_back_size.x / 2) * dpi_scale.x, (height/2 + 10 + crosshair_spacing) * dpi_scale.y), c_cfg.table.c_indicators.ref_crosshair_auto_peek_indicator:get( ))
        crosshair_spacing = crosshair_spacing + 13
    end

    if c_cfg.table.c_visuals.ref_crosshair_indicators:get(13) and ref_freestanding_override[2]:get() then
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_freestanding, vec2_t((width/2 - freestanding_size.x / 2) * dpi_scale.x, (height/2 + 10 + crosshair_spacing) * dpi_scale.y), c_cfg.table.c_indicators.ref_crosshair_force_freestanding_indicator:get( ))
        crosshair_spacing = crosshair_spacing + 13
    end

    if c_cfg.table.c_visuals.ref_crosshair_indicators:get(6) and ref_lethal_shot[2]:get() then
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_lethal, vec2_t((width/2 - lethal_size.x / 2) * dpi_scale.x, (height/2 + 10 + crosshair_spacing) * dpi_scale.y), c_cfg.table.c_indicators.ref_crosshair_force_lethal_indicator:get( ))
        crosshair_spacing = crosshair_spacing + 13
    end

    if c_cfg.table.c_visuals.ref_crosshair_indicators:get(7) and ref_damage_override[2]:get() then
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_damage, vec2_t((width/2 - damage_size.x / 2) * dpi_scale.x, (height/2 + 10 + crosshair_spacing) * dpi_scale.y), c_cfg.table.c_indicators.ref_crosshair_force_damage_indicator:get( ))
        crosshair_spacing = crosshair_spacing + 13
    end

    if c_cfg.table.c_visuals.ref_crosshair_indicators:get(8) and ref_force_hitbox[2]:get() then
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_hitbox, vec2_t((width/2 - hitbox_size.x / 2) * dpi_scale.x, (height/2 + 10 + crosshair_spacing) * dpi_scale.y), c_cfg.table.c_indicators.ref_crosshair_force_hitbox_indicator:get( ))
        crosshair_spacing = crosshair_spacing + 13
    end

    if c_cfg.table.c_visuals.ref_crosshair_indicators:get(9) and ref_force_safepoint[2]:get() then
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_safe, vec2_t((width/2 - safe_size.x / 2) * dpi_scale.x, (height/2 + 10 + crosshair_spacing) * dpi_scale.y), c_cfg.table.c_indicators.ref_crosshair_force_safe_indicator:get( ))
        crosshair_spacing = crosshair_spacing + 13
    end

    if c_cfg.table.c_visuals.ref_crosshair_indicators:get(10) and ref_body_lean_safepoint[2]:get() then
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_rsafe, vec2_t((width/2 - rsafe_size.x / 2) * dpi_scale.x, (height/2 + 10 + crosshair_spacing) * dpi_scale.y), c_cfg.table.c_indicators.ref_crosshair_force_rsafe_indicator:get( ))
        crosshair_spacing = crosshair_spacing + 13
    end

    if c_cfg.table.c_visuals.ref_crosshair_indicators:get(11) and ref_hitchance_override[2]:get() then
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_hitchance, vec2_t((width/2 - hitchance_size.x / 2) * dpi_scale.x, (height/2 + 10 + crosshair_spacing) * dpi_scale.y), c_cfg.table.c_indicators.ref_crosshair_force_hitchance_indicator:get( ))
        crosshair_spacing = crosshair_spacing + 13
    end

    if c_cfg.table.c_visuals.ref_crosshair_indicators:get(12) and ref_ping_override[2]:get() then
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_ping, vec2_t((width/2 - ping_size.x / 2) * dpi_scale.x, (height/2 + 10 + crosshair_spacing) * dpi_scale.y), c_cfg.table.c_indicators.ref_crosshair_force_ping_indicator:get( ))
        crosshair_spacing = crosshair_spacing + 13
    end

    if c_cfg.table.c_visuals.ref_crosshair_indicators:get(14) and ref_force_prediction:get() then
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_force_prediction, vec2_t((width/2 - force_prediction_size.x / 2) * dpi_scale.x, (height/2 + 10 + crosshair_spacing) * dpi_scale.y), c_cfg.table.c_indicators.ref_crosshair_force_prediction_indicator:get( ))
        crosshair_spacing = crosshair_spacing + 13
    end

    if c_cfg.table.c_visuals.ref_crosshair_indicators:get(15) and ref_extended_angles[2]:get() then
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_extending, vec2_t((width/2 - extending_size.x / 2) * dpi_scale.x, (height/2 + 10 + crosshair_spacing) * dpi_scale.y), c_cfg.table.c_indicators.ref_crosshair_extended_angles_indicator:get( ))
        crosshair_spacing = crosshair_spacing + 13
    end

    if c_cfg.table.c_visuals.ref_crosshair_indicators:get(16) and ref_fake_duck[2]:get() then
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_fake_duck, vec2_t((width/2 - fake_duck_size.x / 2) * dpi_scale.x, (height/2 + 10 + crosshair_spacing) * dpi_scale.y), c_cfg.table.c_indicators.ref_crosshair_fake_duck_indicator:get( ))
        crosshair_spacing = crosshair_spacing + 13
    end

    if c_cfg.table.c_visuals.ref_crosshair_indicators:get(17) and ref_slow_walk[2]:get() then
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_slow_walk, vec2_t((width/2 - slow_walk_size.x / 2) * dpi_scale.x, (height/2 + 10 + crosshair_spacing) * dpi_scale.y), c_cfg.table.c_indicators.ref_crosshair_slow_walk_indicator:get( ))
        crosshair_spacing = crosshair_spacing + 13
    end

    if c_cfg.table.c_visuals.ref_crosshair_indicators:get(18) and ref_sneak[2]:get() then
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_sneak, vec2_t((width/2 - sneak_size.x / 2) * dpi_scale.x, (height/2 + 10 + crosshair_spacing) * dpi_scale.y), c_cfg.table.c_indicators.ref_crosshair_sneak_indicator:get( ))
        crosshair_spacing = crosshair_spacing + 13
    end

    if c_cfg.table.c_visuals.ref_crosshair_indicators:get(19) and c_cfg.table.c_ragebot.ref_air_stuck:get() then
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, crosshair_airstuck, vec2_t((width/2 - airstuck_size.x / 2) * dpi_scale.x, (height/2 + 10 + crosshair_spacing) * dpi_scale.y), c_cfg.table.c_indicators.ref_crosshair_sneak_indicator:get( ))
        crosshair_spacing = crosshair_spacing + 13
    end

    if c_cfg.table.c_visuals.ref_shoppy_text:get() then
        local text_sizenigma = render.get_text_size(c_cfg.table.c_fonts.sigma_adaptive_font, "@" .. c_cfg.table.c_visuals.ref_shoppy_input:get())
        local text_sizeligma = render.get_text_size(c_cfg.table.c_fonts.sigma_adaptive_font, "shoppy.gg/")
        render.text(c_cfg.table.c_fonts.sigma_adaptive_font, "shoppy.gg/", vec2_t((width - text_sizenigma.x - text_sizeligma.x - 1) * dpi_scale.x, 0), color_t(255, 255, 255, 255))
        render.text(c_cfg.table.c_fonts.sigma_adaptive_font, "@" .. c_cfg.table.c_visuals.ref_shoppy_input:get(), vec2_t((width - text_sizenigma.x - 1) * dpi_scale.x, 0), c_cfg.table.c_visuals.colors.ref_shoppy_text_color:get())
    end

    if c_cfg.table.c_debug.ref_custom_hud:get() and get_cur_weapon() and is_beta then
        engine.execute_cmd("cl_drawhud 0")
        local hp = local_player:get_prop("m_iHealth")
        local armor = local_player:get_prop("m_ArmorValue")
        local text_size = render.get_text_size(c_cfg.table.c_fonts.hud_font, "HP")
        local text_size_wep = render.get_text_size(c_cfg.table.c_fonts.hud_font, get_cur_weapon())
        local scoped = local_player:get_prop("m_bIsScoped")
        if scoped == 1 then
            render.rect_filled(vec2_t(width / 2, 0), vec2_t(1 * dpi_scale.x, height), color_t(0, 0, 0, 255))
            render.rect_filled(vec2_t(0, height / 2), vec2_t(width, 1 * dpi_scale.y), color_t(0, 0, 0, 255))
        end

        render.rect_fade(vec2_t(0 * dpi_scale.x, height - 40 * dpi_scale.y), vec2_t(255 * dpi_scale.x, 100 * dpi_scale.y), color_t(0, 0, 0, 0), color_t(0, 0, 0, 235), true)
        render.rect_fade(vec2_t(255 * dpi_scale.x, height - 40 * dpi_scale.y), vec2_t(255 * dpi_scale.x, 100 * dpi_scale.y), color_t(0, 0, 0, 235), color_t(0, 0, 0, 0), true)

        render.rect_fade(vec2_t(110 * dpi_scale.x, height - 16 * dpi_scale.y), vec2_t((hp * 1.6) * dpi_scale.x, 5 * dpi_scale.y), color_t(232, 135, 135, 255), color_t(153, 87, 87, 255)) --hp
        render.text(c_cfg.table.c_fonts.hud_font_small, "HP", vec2_t(35 * dpi_scale.x, height - 23 * dpi_scale.y), color_t(232, 135, 135, 255)) --hp
        render.text(c_cfg.table.c_fonts.hud_font, tostring(hp), vec2_t(62 * dpi_scale.x, height - 29 * dpi_scale.y), color_t(232, 135, 135, 255)) --hp

        render.rect_fade(vec2_t(358 * dpi_scale.x, height - 16 * dpi_scale.y), vec2_t((armor * 1.55) * dpi_scale.x, 5 * dpi_scale.y), color_t(0, 166, 255, 255), color_t(0, 121, 186, 255)) --armor
        render.text(c_cfg.table.c_fonts.hud_font_small, "AR", vec2_t(285 * dpi_scale.x, height - 23 * dpi_scale.y), color_t(0, 166, 255, 255)) --armor
        render.text(c_cfg.table.c_fonts.hud_font, tostring(armor), vec2_t(312 * dpi_scale.x, height - 29 * dpi_scale.y), color_t(0, 166, 255, 255)) --hp


        --weapons
        render.rect_fade(vec2_t(width - text_size_wep.x - 15 * dpi_scale.x, height - 37 * dpi_scale.y), vec2_t(text_size_wep.x + 10 * dpi_scale.x, 25 * dpi_scale.y), color_t(0, 0, 0, 0), color_t(0, 0, 0, 235), true)
        render.text(c_cfg.table.c_fonts.hud_pastell_icons, get_weapon_icon[get_cur_weapon()], vec2_t((1910 - text_size_wep.x) * dpi_scale.x, height - 33 * dpi_scale.y), accent_color[2]:get())
    else
        engine.execute_cmd("cl_drawhud 1")
    end

    if c_cfg.table.c_debug.ref_debug:get() and is_beta then
        render.rect_fade(vec2_t(0, 0), vec2_t(190 * dpi_scale.x,152 * dpi_scale.y), color_t(0, 0, 0, 235), color_t(0, 0, 0, 0), true)
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, "max_range -> " .. antiaim.get_max_desync_range(), vec2_t(1 * dpi_scale.x, 1 * dpi_scale.y), accent_color[2]:get())
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, "real_angel -> " .. antiaim.get_real_angle(), vec2_t(1 * dpi_scale.x, 14 * dpi_scale.y), accent_color[2]:get())
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, "fake_angel -> " .. antiaim.get_fake_angle(), vec2_t(1 * dpi_scale.x, 29 * dpi_scale.y), accent_color[2]:get())
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, "fakeduck -> " .. tostring(antiaim.is_fakeducking()), vec2_t(1 * dpi_scale.x, 43 * dpi_scale.y), accent_color[2]:get())
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, "side -> " .. antiaim.get_desync_side(), vec2_t(1 * dpi_scale.x, 57 * dpi_scale.y), accent_color[2]:get())
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, "charge -> " .. exploits.get_charge(), vec2_t(1 * dpi_scale.x, 70 * dpi_scale.y), accent_color[2]:get())
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, "max_charge -> " .. exploits.get_max_charge(), vec2_t(1 * dpi_scale.x, 83 * dpi_scale.y), accent_color[2]:get())
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, "can_fire -> " .. tostring(client.can_fire()), vec2_t(1 * dpi_scale.x, 96 * dpi_scale.y), accent_color[2]:get())
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, "view_angles -> " .. tostring(engine.get_view_angles()), vec2_t(1 * dpi_scale.x, 109 * dpi_scale.y), accent_color[2]:get())
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, "menu_open -> " .. tostring(menu.is_open()), vec2_t(1 * dpi_scale.x, 123 * dpi_scale.y), accent_color[2]:get())
        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, "wep_group -> " .. get_weapon_group[get_cur_weapon()], vec2_t(1 * dpi_scale.x, 137 * dpi_scale.y), accent_color[2]:get())
    end

    if c_cfg.table.c_visuals.ref_holo_panel:get() then
        if c_cfg.table.c_finds.thirdperson[2]:get() and not c_cfg.table.c_visuals.ref_holo_panel_thirdperson:get() then return end
        local pos = render.world_to_screen(GetWeaponEndPos())

        if c_cfg.table.c_finds.thirdperson[2]:get() then
            if c_cfg.table.c_visuals.ref_holo_panel_hitbox:get() == 1 then
                pos = render.world_to_screen(local_player:get_hitbox_pos(e_hitboxes.HEAD))
            end

            if c_cfg.table.c_visuals.ref_holo_panel_hitbox:get() == 2 then
                pos = render.world_to_screen(local_player:get_hitbox_pos(e_hitboxes.NECK))
            end

            if c_cfg.table.c_visuals.ref_holo_panel_hitbox:get() == 3 then
                pos = render.world_to_screen(local_player:get_hitbox_pos(e_hitboxes.PELVIS))
            end

            if c_cfg.table.c_visuals.ref_holo_panel_hitbox:get() == 4 then
                pos = render.world_to_screen(local_player:get_hitbox_pos(e_hitboxes.BODY))
            end

            if c_cfg.table.c_visuals.ref_holo_panel_hitbox:get() == 5 then
                pos = render.world_to_screen(local_player:get_hitbox_pos(e_hitboxes.THORAX))
            end

            if c_cfg.table.c_visuals.ref_holo_panel_hitbox:get() == 6 then
                pos = render.world_to_screen(local_player:get_hitbox_pos(e_hitboxes.CHEST))
            end

            if c_cfg.table.c_visuals.ref_holo_panel_hitbox:get() == 7 then
                pos = render.world_to_screen(local_player:get_hitbox_pos(e_hitboxes.UPPER_CHEST))
            end

            if c_cfg.table.c_visuals.ref_holo_panel_hitbox:get() == 8 then
                pos = render.world_to_screen(local_player:get_hitbox_pos(e_hitboxes.RIGHT_THIGH))
            end

            if c_cfg.table.c_visuals.ref_holo_panel_hitbox:get() == 9 then
                pos = render.world_to_screen(local_player:get_hitbox_pos(e_hitboxes.LEFT_THIGH))
            end

            if c_cfg.table.c_visuals.ref_holo_panel_hitbox:get() == 10 then
                pos = render.world_to_screen(local_player:get_hitbox_pos(e_hitboxes.RIGHT_CALF))
            end

            if c_cfg.table.c_visuals.ref_holo_panel_hitbox:get() == 11 then
                pos = render.world_to_screen(local_player:get_hitbox_pos(e_hitboxes.LEFT_CALF))
            end

            if c_cfg.table.c_visuals.ref_holo_panel_hitbox:get() == 12 then
                pos = render.world_to_screen(local_player:get_hitbox_pos(e_hitboxes.RIGHT_FOOT))
            end

            if c_cfg.table.c_visuals.ref_holo_panel_hitbox:get() == 13 then
                pos = render.world_to_screen(local_player:get_hitbox_pos(e_hitboxes.LEFT_FOOT))
            end

            if c_cfg.table.c_visuals.ref_holo_panel_hitbox:get() == 14 then
                pos = render.world_to_screen(local_player:get_hitbox_pos(e_hitboxes.RIGHT_HAND))
            end

            if c_cfg.table.c_visuals.ref_holo_panel_hitbox:get() == 15 then
                pos = render.world_to_screen(local_player:get_hitbox_pos(e_hitboxes.LEFT_HAND))
            end

            if c_cfg.table.c_visuals.ref_holo_panel_hitbox:get() == 16 then
                pos = render.world_to_screen(local_player:get_hitbox_pos(e_hitboxes.RIGHT_UPPER_ARM))
            end

            if c_cfg.table.c_visuals.ref_holo_panel_hitbox:get() == 17 then
                pos = render.world_to_screen(local_player:get_hitbox_pos(e_hitboxes.LEFT_UPPER_ARM))
            end

            if c_cfg.table.c_visuals.ref_holo_panel_hitbox:get() == 18 then
                pos = render.world_to_screen(local_player:get_hitbox_pos(e_hitboxes.RIGHT_FOREARM))
            end

            if c_cfg.table.c_visuals.ref_holo_panel_hitbox:get() == 19 then
                pos = render.world_to_screen(local_player:get_hitbox_pos(e_hitboxes.LEFT_FOREARM))
            end
        end

        if pos == nil then return end

        local desync_range = antiaim.get_fake_angle()

        render.rect_filled(vec2_t(pos.x - 100,pos.y - 100), vec2_t(100, 60), color_t(25,25,25,255), 5)
        render.rect(vec2_t(pos.x - 100,pos.y - 100), vec2_t(100, 60), color_t(55,55,55,255), 5)

        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, "Nulify.lua [beta]", vec2_t(pos.x - 97,pos.y - 98), accent_color[2]:get())

        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, "Charge:", vec2_t(pos.x - 97,pos.y - 85), accent_color[2]:get())
        render.rect_filled(vec2_t(pos.x - 54,pos.y - 80), vec2_t(48, 5), color_t(35,35,35,255), true)
        render.rect_fade(vec2_t(pos.x - 54,pos.y - 80), vec2_t(clamp(charge_amount_plain * 3.5, 1, 48), 5), accent_color[2]:get(), accent_color[2]:get(), true)
        render.rect(vec2_t(pos.x - 54,pos.y - 80), vec2_t(48, 5), color_t(55,55,55,255), true)

        render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, "Desync:", vec2_t(pos.x - 97,pos.y - 70), accent_color[2]:get())
        render.rect_filled(vec2_t(pos.x - 54,pos.y - 65), vec2_t(48, 5), color_t(35,35,35,255), true)
        render.rect_fade(vec2_t(pos.x - 54,pos.y - 65), vec2_t(clamp(desync_range / 1.2, 1, 48), 5), accent_color[2]:get(), accent_color[2]:get(), true)
        render.rect(vec2_t(pos.x - 54,pos.y - 65), vec2_t(48, 5), color_t(55,55,55,255), true)

        --render.text(c_cfg.table.c_fonts.indicatorfont_crosshair, "Charge:", vec2_t(pos.x - 97,pos.y - 85), accent_color[2]:get())
        --render.rect_filled(vec2_t(pos.x - 54,pos.y - 80), vec2_t(48, 5), color_t(35,35,35,255), true)
        --render.rect_fade(vec2_t(pos.x - 54,pos.y - 80), vec2_t(clamp(charge_amount_plain * 3.5, 1, 48), 5), accent_color[2]:get(), accent_color[2]:get(), true)
        --render.rect(vec2_t(pos.x - 54,pos.y - 80), vec2_t(48, 5), color_t(55,55,55,255), true)
    end
end

local function player_esp_callback(ctx)
    if ctx.dormant then
        return
    end

    local local_player = entity_list.get_local_player()
    if local_player == nil then
        return
    end

    if not engine.is_connected() then
        return
      end
      
    if not engine.is_in_game() then
        return
    end

    if not local_player:get_prop("m_iHealth") then
        return
    end

    if local_player:get_prop("m_iHealth") == 0 then
        return
    end

    if not local_player:is_alive() then
        return
    end

    local local_cur_weapon = get_weapon_group[get_cur_weapon()]

    if local_cur_weapon == nil then
        local_cur_weapon = "other"
    end

    local enemies = entity_list.get_players(true)
    local in_air = local_player:get_prop("m_vecVelocity[2]") ~= 0	

    for _, enemy in pairs(enemies) do
        local pos = render.world_to_screen(enemy:get_hitbox_pos(e_hitboxes.HEAD))

        if pos == nil then return end

        if c_cfg.table.c_visuals.ref_head_dot:get() then
            render.rect_filled(vec2_t(pos.x - 3 * dpi_scale.x, pos.y - 3 * dpi_scale.y), vec2_t(6 * dpi_scale.x, 6 * dpi_scale.y), color_t(0,0,0,255))

            if is_point_visible(enemy) then
                render.rect_filled(vec2_t(pos.x - 2 * dpi_scale.x, pos.y - 2 * dpi_scale.y), vec2_t(4 * dpi_scale.x, 4 * dpi_scale.y), c_cfg.table.c_visuals.colors.ref_head_dot_color:get())
            else
                render.rect_filled(vec2_t(pos.x - 2 * dpi_scale.x, pos.y - 2 * dpi_scale.y), vec2_t(4 * dpi_scale.x, 4 * dpi_scale.y), c_cfg.table.c_visuals.colors.ref_head_dot_color_invisible:get())
            end
        end
    end
end

function world_circle(origin, radius, color)
    if version == "" then return end
	local previous_screen_pos, screen

    local animation_cur = 0
    local animation_max = 70 - 1
    local animation_min = 1
    local go_down = false

    for i = 0, radius*4 do
		local pos = vec3_t(radius * math.cos(i) + origin.x, radius * math.sin(i) + origin.y, origin.z);

        if animation_cur > animation_max then
            go_down = true
        end

        if animation_cur < animation_min then
            go_down = false
        end

        if go_down == false then
            animation_cur = animation_cur + 1
        else
            animation_cur = animation_cur - 1
        end

        local screen = render.world_to_screen(pos)
        if not screen then return end
		if screen.x ~= nil and previous_screen_pos then
            render.line(previous_screen_pos, screen, color)
			previous_screen_pos = screen
        elseif screen.x ~= nil then
            previous_screen_pos = screen
		end
	end
end

function autopeek()
    if version == "" then return end 
    if not c_cfg.table.c_visuals.ref_auto_peek_world:get() or not engine.is_in_game() then 
        return
    end

    if not ragebot.get_autopeek_pos() then
        return
    end

    local player = entity_list.get_local_player()
    local pos = ffi.new("struct vec3_t")
    local lporigin = ragebot.get_autopeek_pos()

    world_circle(lporigin, 22, c_cfg.table.c_visuals.colors.ref_auto_peek_color_world:get())
end

local function affects()
    if version == "" then return end
    if c_cfg.table.c_visuals.ref_party_mode:get() then
        cvars.sv_party_mode:set_int(1)
    else
        cvars.sv_party_mode:set_int(0)
    end
end

callbacks.add(e_callbacks.PAINT, dpi_scale_setup)
callbacks.add(e_callbacks.PAINT, font_changer)
callbacks.add(e_callbacks.PLAYER_ESP, on_player_esp)
callbacks.add(e_callbacks.PAINT, affects)
callbacks.add(e_callbacks.DRAW_WATERMARK, function() return"" end)
callbacks.add(e_callbacks.PAINT, on_draw_menu)
callbacks.add(e_callbacks.DRAW_WATERMARK, on_draw_watermark)
callbacks.add(e_callbacks.AIMBOT_MISS, on_aimbot_miss)
callbacks.add(e_callbacks.AIMBOT_HIT, on_aimbot_hit)
callbacks.add(e_callbacks.DRAW_WATERMARK, indicators)
callbacks.add(e_callbacks.PAINT, autopeek)
callbacks.add(e_callbacks.PLAYER_ESP, player_esp_callback)


--Misc
local ffi_handler = {}
local tag_changer = {}


tag_changer.custom_tag = {
    "Nu.lua",
    "Nul.lua",
    "Nuli.lua",
    "Nulif.lua",
    "Nulify.lua",
    "Nulif.lua",
    "Nuli.lua",
    "Nul.lua",
    "Nu.lua",
    "N.lua"
}


local string_mul = function(text, mul)

    mul = math.floor(mul)

    local to_add = text

    for i = 1, mul-1 do
        text = text .. to_add
    end

    return text
end

ffi_handler.sigs = {}
ffi_handler.sigs.clantag = {"engine.dll", "53 56 57 8B DA 8B F9 FF 15"}
ffi_handler.change_tag_fn = ffi.cast("int(__fastcall*)(const char*, const char*)", memory.find_pattern(unpack(ffi_handler.sigs.clantag)))

tag_changer.last_time_update = -1
tag_changer.update = function(tag)
    local current_tick = global_vars.tick_count()

    if current_tick > tag_changer.last_time_update then
        tag = tostring(tag)
        ffi_handler.change_tag_fn(tag, tag)
        tag_changer.last_time_update = current_tick + 16
    end
end

tag_changer.build_first = function(text)

    local orig_text = text
    local list = {}

    text = string_mul(" ", #text * 2) .. text .. string_mul(" ", #text * 2)

    for i = 1, math.floor(#text / 1.5) do
        local add_text = text:sub(i, (i + math.floor(#orig_text * 2) % #text))

        table.insert(list, add_text .. "\t")
    end

    return list
end

tag_changer.build_second = function(text)
    local builded = {}

    for i = 1, #text do

        local tmp = text:sub(i, #text) .. text:sub(1, i-1)

        if tmp:sub(#tmp) == " " then
            tmp = tmp:sub(1, #tmp-1) .. "\t"
        end

        table.insert(builded, tmp)
    end

    return builded
end

tag_changer.current_build = tag_changer.build_first("Nulify.lua")
tag_changer.current_tag = "empty_string"

tag_changer.disabled = true
tag_changer.on_paint = function()
    if version == "" then return end
    local is_enabled = c_cfg.table.c_misc.clan_tag:get()
    if not engine.is_in_game() or not is_enabled then

        if not is_enabled and not tag_changer.disabled then
            ffi_handler.change_tag_fn("", "")
            tag_changer.disabled = true
        end

        tag_changer.last_time_update = -1
        return
    end    

    local tag_type = 3
    local ui_tag = "Nulify.lua"
    if tag_type ~= 3 and ui_tag ~= tag_changer.current_tag then
        tag_changer.current_build = tag_type == 1 and tag_changer.build_first(ui_tag) or tag_changer.build_second(ui_tag)
    elseif tag_type == 3 then
        tag_changer.current_build = tag_changer.custom_tag
    end

    local tag_speed = 3

    if tag_speed == 0 then
        tag_changer.update(ui_tag)
        return
    end

    local current_tag = math.floor(global_vars.cur_time() * tag_speed % #tag_changer.current_build) + 1
    current_tag = tag_changer.current_build[current_tag]

    tag_changer.disabled = false
    tag_changer.update(current_tag)
end

callbacks.add(e_callbacks.PAINT, tag_changer.on_paint)

local get_phrase = function()
    local phrases = {"nn retard knocked on his knees by nulify.lua", "nulify.lua is just better.", "I wish I had nulify.lua", "Nulify.lua > all", "nn retard down!", "just get better nn doggo.", "Nulify.lua goofy goober mode: ON"}
    if #phrases == 0 then return "Nulify, error 102!" end

    return phrases[math.random(1, 7)]
end

local last_chat_time = 0
local on_player_death = function(event)
    if version == "" then return end
    if not c_cfg.table.c_misc.killsay:get() then return end

    local userid, attackerid = event.userid, event.attacker
    if not userid or not attackerid then return end

    local victim, attacker, local_player = entity_list.get_player_from_userid(userid), entity_list.get_player_from_userid(attackerid), entity_list.get_local_player()
    if not victim or not attacker or not local_player then return end

    if attacker == local_player and victim ~= local_player then
        if game_rules.get_prop("m_bIsValveDS") and (last_chat_time > global_vars.cur_time() + 0.3) then
            return 
        end

        local phrase = get_phrase()
        if phrase == '' then return end

        engine.execute_cmd(('say "%s"'):format(phrase) )
    end
end

local on_player_chat = function(event)
    local player = event.entity
    if not player or (not game_rules.get_prop("m_bIsValveDS")) then return end

    if player == entity_list.get_local_player() then
        last_chat_time = global_vars.cur_time()
    end
end

local function staticlegs(ctx)
    if version == "" then return end
    local local_player = entity_list.get_local_player()
	local in_air = local_player:get_prop("m_vecVelocity[2]") ~= 0	
    if c_cfg.table.c_misc.static_legs:get() then
        if in_air then
            ctx:set_render_pose(e_poses.JUMP_FALL, 1)
        end
    end
end

local update_mask = false
menu.add_button("Misc", "Apply current", function()
    if version == "" then return end
    update_mask = true
end)
local remove_mask = false
menu.add_button("Misc", "Remove current", function()
    if version == "" then return end
    remove_mask = true
end)

local mask = "facemask_dallas"
local mask_applied = false

local function on_cmd(mask_name)
    return(string.format('ent_fire !self addoutput "targetname facemask"; prop_dynamic_create %s; ent_setname %s; ent_fire %s disablecollision; ent_fire %s setparent facemask; ent_fire %s setparentattachment facemask', "player/holiday/facemasks/" .. mask_name, mask_name, mask_name, mask_name, mask_name))
end
local function off_cmd(mask_name)
    return(string.format('ent_remove %s', mask_name))
end

local function mask_changer()
    if version == "" then return end
    if c_cfg.table.c_debug.ref_print_mask:get() and is_beta then print(names[c_cfg.table.c_misc.masks:get()]) end
    cvars["sv_cheats"]:set_int(1)

    if update_mask then
        engine.execute_cmd(off_cmd(names[c_cfg.table.c_misc.masks:get()]))
        mask = c_cfg.table.c_misc.masks:get() + 1
        mask_applied = false
        update_mask = false
    end
    if c_cfg.table.c_finds.thirdperson[2]:get() == true and mask_applied == false then
        engine.execute_cmd(off_cmd(names[c_cfg.table.c_misc.masks:get()]))
        engine.execute_cmd(on_cmd(names[c_cfg.table.c_misc.masks:get()]))
        mask_applied = true
    end
    if c_cfg.table.c_finds.thirdperson[2]:get() == false and mask_applied == true then
        engine.execute_cmd(off_cmd(names[c_cfg.table.c_misc.masks:get()]))
        mask_applied = false
    end

    if remove_mask then
        engine.execute_cmd(off_cmd(names[c_cfg.table.c_misc.masks:get()]))
        remove_mask = false
    end
end

local names = {""}

local has_drawn_selection = true
local function get_football()
    if version == "" then return end
    local enemies_only = entity_list.get_players(false)
    for _,player in pairs(enemies_only) do
        names[_] = player:get_name()

        if c_cfg.table.c_misc.ref_follow_bot:get() then
        
        end
    end
    if has_drawn_selection == true then
    local ref_follow_bot_players = menu.add_selection("Misc", "Player  (debug)", names)
    ref_follow_bot_players:set_visible(testing)
    has_drawn_selection = false
    end
end

local ent_list = memory.create_interface("client.dll", "VClientEntityList003")
local entity_list_raw = ffi.cast("void***",ent_list)
local get_client_entity = ffi.cast("void*(__thiscall*)(void*,int)",memory.get_vfunc(ent_list,3))
local model_info_interface = memory.create_interface("engine.dll","VModelInfoClient004")
local raw_model_info = ffi.cast("void***",model_info_interface)
local get_model_index = ffi.cast("int(__thiscall*)(void*, const char*)",memory.get_vfunc(tonumber(ffi.cast("unsigned int",raw_model_info)),2))
local set_model_index_t = ffi.typeof("void(__thiscall*)(void*,int)")
--reversed for no reason cuz ducarii n i thought modelindex no worky
local set_model_index = ffi.cast(set_model_index_t, memory.find_pattern("client.dll","55 8B EC 8B 45 08 56 8B F1 8B 0D ?? ?? ?? ??"))


local team_references, team_model_paths = {}, {}
local model_index_prev

for i=1, #cs_teams do
	local teamname, is_t = unpack(cs_teams[i])

	team_model_paths[is_t] = {}
	local model_names = {}
	local l_i = 0
	for i=1, #player_models do
		local model_name, model_path, model_is_t = unpack(player_models[i])

		if model_is_t == nil or model_is_t == is_t then
			table.insert(model_names, model_name)
			l_i = l_i + 1
			team_model_paths[is_t][l_i] = model_path
		end
	end

	team_references[is_t] = {
		enabled_reference = menu.add_checkbox("Misc",string.format("Model changer",teamname)),
		model_reference = menu.add_list("Misc","Player Models",model_names,5)
	}
	for _, v in pairs(team_references[is_t]) do
		v:set_visible(false)
	end
end


local function do_model_change()
	local local_player = entity_list.get_local_player()

	if local_player == nil then
		return
	end

	if not local_player:is_alive() then
		return
	end

	local player_ptr = ffi.cast("void***",get_client_entity(entity_list_raw,local_player:get_index()))
	local set_model_idx  = ffi.cast(set_model_index_t,memory.get_vfunc(tonumber(ffi.cast("unsigned int",player_ptr)),75))

	if(player_ptr == nil) then
		return
	end

	if(set_model_idx == nil) then
		return
	end

	local model_path, model_index
	local teamnum = local_player:get_prop("m_iTeamNum")
	local is_t = teamnum == 2 and true or false

	for references_is_t, references in pairs(team_references) do
		references.enabled_reference:set_visible(references_is_t == is_t)

		if references_is_t == is_t and references.enabled_reference:get() then
			references.model_reference:set_visible(true)
			model_path = team_model_paths[is_t][tonumber(references.model_reference:get())]
		else
			references.model_reference:set_visible(false)
		end
	end

	local model_index

	if model_path ~= nil then
		model_index = get_model_index(raw_model_info,model_path)
		if model_index == -1 then
			model_index = nil
		end
	end

	if(model_index == nil and model_path ~= nil) then
		client.precache_model(model_path)
	end

	model_index_prev = model_index

	if model_index ~= nil then
		set_model_idx(player_ptr,model_index)
	end
end

callbacks.add(e_callbacks.NET_UPDATE,do_model_change)

c_cfg.table.c_misc.ref_follow_bot:set_visible(testing)

callbacks.add(e_callbacks.SETUP_COMMAND, get_football)

local function show_groups()
    if version == "" then
        menu.set_group_visibility("General", false)
        menu.set_group_visibility("LegitBot", false)
        menu.set_group_visibility("RageBot", false)
        menu.set_group_visibility("Anti-Aim", false)
        menu.set_group_visibility("Fake-Lag", false)
        menu.set_group_visibility("Visuals", false)
        menu.set_group_visibility("Misc", false)
        menu.set_group_visibility("Indicators", false)
        menu.set_group_visibility("debug (ac-130)", false)
    else
        menu.set_group_visibility("General", true)
        menu.set_group_visibility("LegitBot", enabled_tabs:get(1))
        menu.set_group_visibility("RageBot", enabled_tabs:get(2))
        menu.set_group_visibility("Anti-Aim", enabled_tabs:get(3))
        menu.set_group_visibility("Fake-Lag", enabled_tabs:get(4))
        menu.set_group_visibility("Visuals", enabled_tabs:get(5))
        menu.set_group_visibility("Misc", enabled_tabs:get(6))
        menu.set_group_visibility("Indicators", enabled_tabs:get(7))
        menu.set_group_visibility("debug (ac-130)", is_beta)
    end
end

local function show_items()
    local antiaim_builder = false
    if c_cfg.table.c_antiaim.antiaim_preset:get() == 9 then
        antiaim_builder = true
    end

    local show_faster_doubletap_ticks = false
    if c_cfg.table.c_ragebot.ref_faster_doubletap_mode:get() == 2 and c_cfg.table.c_ragebot.ref_faster_doubletap:get() then
        show_faster_doubletap_ticks = true
    end

    c_cfg.table.c_ragebot.ref_faster_doubletap_ticks:set_visible(show_faster_doubletap_ticks)

    c_cfg.table.c_ragebot.ref_faster_doubletap_mode:set_visible(c_cfg.table.c_ragebot.ref_faster_doubletap:get())

    if c_cfg.table.c_visuals.ref_holo_panel:get() then
        c_cfg.table.c_visuals.ref_holo_panel_thirdperson:set_visible(true)
        if c_cfg.table.c_visuals.ref_holo_panel_thirdperson:get() then
            c_cfg.table.c_visuals.ref_holo_panel_hitbox:set_visible(true)
        else
            c_cfg.table.c_visuals.ref_holo_panel_hitbox:set_visible(false)
        end
    else
        c_cfg.table.c_visuals.ref_holo_panel_thirdperson:set_visible(false)
        c_cfg.table.c_visuals.ref_holo_panel_hitbox:set_visible(false)
    end

    c_cfg.table.c_antiaim.antiaim_pitch:set_visible(antiaim_builder)
    c_cfg.table.c_antiaim.antiaim_features:set_visible(antiaim_builder)
    c_cfg.table.c_antiaim.antiaim_built_in_modes:set_visible(antiaim_builder and c_cfg.table.c_antiaim.antiaim_features:get(2))
    c_cfg.table.c_antiaim.antiaim_improvements:set_visible(antiaim_builder and c_cfg.table.c_antiaim.antiaim_features:get(3))
end
local function on_script_load()
    if script_load == false and not (enabled_tabs:get(1) or enabled_tabs:get(2) or enabled_tabs:get(3) or enabled_tabs:get(4) or enabled_tabs:get(5) or enabled_tabs:get(6) or enabled_tabs:get(7)) then
        c_cfg.table.c_misc.dpi_scale_custom:set(2)
        c_cfg.table.c_visuals.ref_indicators_font_style:set(3)
        c_cfg.table.c_visuals.ref_crosshair_indicators_font_style:set(2)
        script_load = true
    end
end

callbacks.add(e_callbacks.PAINT, on_script_load)
callbacks.add(e_callbacks.PAINT, show_items)
callbacks.add(e_callbacks.PAINT, show_groups)
callbacks.add(e_callbacks.PAINT, mask_changer)
callbacks.add(e_callbacks.ANTIAIM, staticlegs)
callbacks.add(e_callbacks.EVENT, on_player_chat, "player_chat")
callbacks.add(e_callbacks.EVENT, on_player_death, "player_death")
