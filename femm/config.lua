__configuration = {
    ["wire_diameter_mm"] = 0.65,
    ["space_size_mm"] = 49.5,
    ["projectile_extra_mass_grams"] = 0.1,
    ["projectile_v0"] = 0.2,
    ["coil_wire_density"] = 0.74,
    ["R_switch"] = 0.3,
    ["switch_turnable"] = false,
    ["switch_disable"] = nil, -- or function of (time,x,V)
    ["C"] = 900, -- uF,
    ["V_C"] = 450,
    ["I_max"] = nil,
    ["dt_us"] = 50,
    ["parallel_diode"] = true,
    ["result_file_name"] = "sample1.txt",

    ["projectile"] = {
        ["y_offset"] = -19.0,
        ["step_mm"] = 2.0,
        ["points"] = {
            {4.0/2.0, 8.0/2.0},
            {4.0/2.0, 8.0/2.0},
            {4.0/2.0, 8.0/2.0},
            {4.0/2.0, 8.0/2.0},
            {4.0/2.0, 8.0/2.0},
            {4.0/2.0, 8.0/2.0},
            {0.0    , 8.0/2.0},
            {0.0    , 8.0/2.0},
            {0.0    , 8.0/2.0},
            {0.0    , 8.0/2.0},
        }
    },
    ["coil"] = {
        ["y_offset"] = 0.7,
        ["step_mm"] = 20.0 - 2 * 0.7,
        ["points"] = {
            {8.1/2.0 + 0.7, 26.0/2.0 - 0.7},
        }
    },
    ["magnetic_circuit"] = {
        ["y_offset"] = -4.0,
        ["step_mm"] = 4.0,
        ["points"] = {
            { 8.0/2.0 + 0.7, 26.0/2.0+4.0},
            {26.0/2.0 + 0.7, 26.0/2.0+4.0},
            {26.0/2.0 + 0.7, 26.0/2.0+4.0},
            {26.0/2.0 + 0.7, 26.0/2.0+4.0},
            {26.0/2.0 + 0.7, 26.0/2.0+4.0},
            {26.0/2.0 + 0.7, 26.0/2.0+4.0},
            { 8.0/2.0 + 0.7, 26.0/2.0+4.0},
        }
    }
}