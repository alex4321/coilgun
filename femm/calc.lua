setcompatibilitymode(1) -- 4.2

TEMP_FILE_NAME_SHORT = "temp"
TEMP_FILE_NAME = TEMP_FILE_NAME_SHORT .. ".fem"
TEMP_ANS_FILE_NAME = TEMP_FILE_NAME_SHORT .. ".ans"

AIR_MATERIAL = "Air"
CUPRUM_MATERIAL = "Cu"
IRON_MATERIAL = "Iron"
IRON_RO = 7800
COIL_CURRENT = "I"
MAX_SEGMENT_GRAD = 5.0
SPACE_MARGIN_MM = 2.0
PROJECTILE_MESH_SIZE = 0.35
COIL_MESHSIZE = 0.5
PROJECTILE_BLOCK_ID = 1
COIL_BLOCK_ID = 2
MAGNETIC_CIRCUIT_BLOCK_ID = 3
PI = 3.1415926535
CU_SIGMA = 0.0000000175
K_RC = 140 -- RC, Ohms*uF
MAXITER = 1000


-----------------------------------------------------
---            Service functions                  ---
-----------------------------------------------------
function append(array, element)
	array[getn(array) + 1] = element
end


function calculate_R_cc(config)
	if config["R_cc"] ~= nil then
		return config["R_cc"]
	else
		return K_RC / config["C"]
	end
end


function calculate_isolated_wire_diameter_mm(config)
	local isolation = sqrt(config["wire_diameter_mm"]) * 0.07
	local isolated_wire_diameter_mm = config["wire_diameter_mm"] + isolation
	return isolated_wire_diameter_mm
end


function calculate_coil_R(wire_l_mm, wire_diameter_mm)
	local wire_l_m = wire_l_mm / 1000.0
	local wire_diameter_m = wire_diameter_mm / 1000.0
	return CU_SIGMA * wire_l_m / (pi * (wire_diameter_m / 2)^2)
end


-----------------------------------------------------
---         Project initialization                ---
-----------------------------------------------------
function add_iron_material()
	local iron_props = {
		{0,      0       },
		{0.0001, 50      },
		{0.001,  100     },
		{0.01,   150     },
		{0.015,  175     },
		{0.0253, 200     },
		{0.15,   300     },
		{0.5031, 400     },
		{1.0059, 500     },
		{1.3706, 700     },
		{1.4588, 900     },
		{1.51,   1200    },
		{1.55,   1600    },
		{1.58,   2000    },
		{1.62,   2700    },
		{1.77,   10000   },
		{1.84,   20000   },
		{1.93,   42000   },
		{2.01,   75000   },
		{2.10,   123300  },
		{2.25,   207000  },
		{2.439,  350000  },
		{3.13,   900000  },
		{7.65,   4500000 },
		{13.3,   9000000 },
		{22.09,  16000000}
	}

	mi_addmaterial(IRON_MATERIAL,"","","","","",0)
	for _, prop in iron_props do
		mi_addbhpoint(IRON_MATERIAL, prop[1], prop[2])
	end
end


function initialize(config)
    create(0)
    mi_probdef(0,"millimeters","axi",1E-8,30)

    mi_addmaterial(AIR_MATERIAL, 1, 1)
    mi_addmaterial(CUPRUM_MATERIAL, 1, 1, "", "", "", 58, "", "", "", 3, "", "", 1, config.wire_diameter_mm)
    mi_addcircprop(COIL_CURRENT, 0, 0, 1)
    add_iron_material()
end


function create_space(config)
    mi_addnode(0, config["space_size_mm"] + SPACE_MARGIN_MM)
    mi_addnode(0, -config["space_size_mm"] - SPACE_MARGIN_MM)
    mi_addsegment(0,  config["space_size_mm"] + SPACE_MARGIN_MM,
			      0, -config["space_size_mm"] - SPACE_MARGIN_MM)
	mi_addarc(0, -config["space_size_mm"] - SPACE_MARGIN_MM,
			  0,  config["space_size_mm"] + SPACE_MARGIN_MM,
			  180, MAX_SEGMENT_GRAD)
	mi_addblocklabel(config["space_size_mm"], 0.0)
	mi_clearselected()
	mi_selectlabel(config["space_size_mm"], 0.0)
	mi_setblockprop(AIR_MATERIAL, 1, "", "", "", 0)
end


-----------------------------------------------------
---        Objects creation geometry              ---
-----------------------------------------------------
function create_rotation_body(geometry, group_id)
	function build_line(points, group_id)
		local last_point = {nil, nil}
		for _, point in points do
			if (point[1] ~= last_point[1]) or (point[2] ~= last_point[2]) then
				mi_addnode(point[1], point[2])
				last_point = {point[1], point[2]}
			end
		end
		mi_clearselected()
		local last_point = {nil, nil}
		for _, point in points do
			if (point[1] ~= last_point[1]) or (point[2] ~= last_point[2]) then
				mi_selectnode(point[1], point[2])
				last_point = {point[1], point[2]}
			end
		end
		mi_setnodeprop("", group_id)
		for i=1,getn(points)-1 do
			local point, next_point = points[i], points[i + 1]
			if (point[1] ~= next_point[1]) or (point[2] ~= next_point[2]) then
				mi_addsegment(point[1], point[2], next_point[1], next_point[2])
			end
		end
		mi_clearselected()
	end

	local y_offset = geometry["y_offset"]
	local inner_points = {}
	local outer_points = {}

	append(inner_points, {geometry["points"][1][1], y_offset})
	append(outer_points, {geometry["points"][1][2], y_offset})
	for i=2,getn(geometry["points"]) do
		local point = geometry["points"][i]
		local prev_point = geometry["points"][i - 1]
		local y = (i - 1) * geometry["step_mm"] + y_offset
		if point[1] ~= prev_point[1] then
			append(inner_points, {prev_point[1], y})
			append(inner_points, {point[1], y})
		end
		if point[2] ~= prev_point[2] then
			append(outer_points, {prev_point[2], y})
			append(outer_points, {point[2], y})
		end
	end
	append(inner_points, {geometry["points"][getn(geometry["points"])][1], geometry["step_mm"] * getn(geometry["points"]) + y_offset})
	append(outer_points, {geometry["points"][getn(geometry["points"])][2], geometry["step_mm"] * getn(geometry["points"]) + y_offset})

	build_line(inner_points, group_id)
	build_line(outer_points, group_id)

	mi_selectnode(inner_points[1][1], inner_points[1][2])
	mi_selectnode(outer_points[1][1], outer_points[1][2])
	mi_setnodeprop("", group_id)
	mi_addsegment(inner_points[1][1], inner_points[1][2], outer_points[1][1], outer_points[1][2])
	mi_clearselected()

	local inner_point_count = getn(inner_points)
	local outer_point_count = getn(outer_points)
	mi_selectnode(inner_points[inner_point_count][1], inner_points[inner_point_count][2])
	mi_selectnode(outer_points[outer_point_count][1], outer_points[outer_point_count][2])
	mi_setnodeprop("", group_id)
	mi_addsegment(inner_points[inner_point_count][1], inner_points[inner_point_count][2],
			      outer_points[outer_point_count][1], outer_points[outer_point_count][2])
	mi_clearselected()

	local inner_x = (geometry["points"][1][1] + geometry["points"][1][2]) / 2
	local inner_y = geometry["y_offset"] + geometry["step_mm"] / 2

	return inner_x, inner_y
end


function create_projectile(config)
	local projectile_x, projectile_y = create_rotation_body(config["projectile"], PROJECTILE_BLOCK_ID)
	mi_addblocklabel(projectile_x, projectile_y)
	mi_clearselected()
	mi_selectlabel(projectile_x, projectile_y)
	mi_setblockprop(IRON_MATERIAL, 1, PROJECTILE_MESH_SIZE, "", "", PROJECTILE_BLOCK_ID)
	mi_clearselected()
	return projectile_x, projectile_y
end


function create_coil(config)
	local coil_x, coil_y = create_rotation_body(config["coil"], COIL_BLOCK_ID)
	mi_addblocklabel(coil_x, coil_y)
	mi_clearselected()
	mi_selectlabel(coil_x, coil_y)
	mi_setblockprop(CUPRUM_MATERIAL, 0, COIL_MESHSIZE, COIL_CURRENT, "", COIL_BLOCK_ID)
	mi_clearselected()

	local isolated_wire_diameter_mm = calculate_isolated_wire_diameter_mm(config)
	local l_mm = 0
	local n = 0
	for _, point in config["coil"]["points"] do
		block_S_mm2 = config["coil"]["step_mm"] * (point[2] - point[1])
		block_n = config["coil_wire_density"] * block_S_mm2 / (isolated_wire_diameter_mm^2)
		block_mean_circle_R_mm = (point[2] + point[1]) / 2
		block_mean_circle_l_mm = 2 * PI * block_mean_circle_R_mm
		block_l_mm = block_mean_circle_l_mm * block_n

		n = n + block_n
		l_mm = l_mm + block_l_mm
	end

	return coil_x, coil_y, l_mm, n
end


function create_magnetic_circuit(config)
	local circuit_x, circuit_y = create_rotation_body(config["magnetic_circuit"], MAGNETIC_CIRCUIT_BLOCK_ID)
	mi_addblocklabel(circuit_x, circuit_y)
	mi_clearselected()
	mi_selectlabel(circuit_x, circuit_y)
	mi_setblockprop(IRON_MATERIAL, 1, "", "", "", MAGNETIC_CIRCUIT_BLOCK_ID)
	mi_clearselected()
end


function place_objects(config)
	create_space(config)
	local projectile_x, projectile_y = create_projectile(config)
	local coil_x, coil_y, wire_l_mm, coil_n = create_coil(config)
	if config["magnetic_circuit"] ~= nil then
		create_magnetic_circuit(config)
	end
	return {
		-- COIL
		["coil_x"] = coil_x,
		["coil_y"] = coil_y,
		["wire_l_mm"] = wire_l_mm,
		["coil_n"] = coil_n,
		-- PROJECTILE
		["projectile_x"] = projectile_x,
		["projectile_y"] = projectile_y,
	}
end


-----------------------------------------------------
---               Simulation                      ---
-----------------------------------------------------
function calculate_coil_L(coil_x, coil_y, coil_n)
	-- Set I=100A to check L
	mi_selectlabel(coil_x, coil_y)
	mi_setblockprop(CUPRUM_MATERIAL, 0, COIL_MESHSIZE, COIL_CURRENT, "", COIL_BLOCK_ID, coil_n) -- последнее значение - число витков
	mi_clearselected()
	mi_modifycircprop(COIL_CURRENT, 1, 100)
	mi_analyze(1)
	mo_reload()
	current_re,_,_,_,flux_re,_ = mo_getcircuitproperties(COIL_CURRENT)
	L = flux_re / current_re
	return L
end


function analysis_step(m_projectile, R, config, t0, dt, I0, V_C0, V0, x0)
	local t = t0 + dt

	mi_modifycircprop(COIL_CURRENT, 1, I0)
	mi_analyze(1)
	mo_reload()

	mi_clearselected()
	mo_groupselectblock(PROJECTILE_BLOCK_ID)
	local F = mo_blockintegral(19)

	local _,_,_,_,Fi0,_ = mo_getcircuitproperties(COIL_CURRENT)
	mi_modifycircprop(COIL_CURRENT, 1, I0 * 1.001)
	mi_analyze(1)
	mo_reload()
	local _,_,_,_,Fi1,_ = mo_getcircuitproperties(COIL_CURRENT)
	local Fii = (Fi1 - Fi0) / (0.001 * I0) -- dFi/dI

	local a_projectile = F / m_projectile
	local dx_m = V0 * dt
	local dx_mm = dx_m * 1000.0
	local x = x0 + dx_mm
	local space_end_X = config["space_size_mm"] - config["projectile"]["step_mm"] * (getn(config["projectile"]["points"]) - 2)
	if x >= space_end_X then
		x = x0
	end
	local V_projectile = V0 + a_projectile * dt

	mi_clearselected()
	mi_selectgroup(PROJECTILE_BLOCK_ID)
	mi_movetranslate(0, dx_mm)
	mi_modifycircprop(COIL_CURRENT, 1, I0)
	mi_analyze(1)
	mo_reload()
	mo_groupselectblock(PROJECTILE_BLOCK_ID)

	local _,_,_,_,Fi0,_ = mo_getcircuitproperties(COIL_CURRENT)
	mi_modifycircprop(COIL_CURRENT, 1 , I0 * 1.001)
	mi_analyze(1)
	mo_reload()
	local _,_,_,_,Fi1,_ = mo_getcircuitproperties(COIL_CURRENT)
	local Fif = (Fi1 - Fi0) / (0.001 * I0) -- dFi/dI

	local dL = Fif - Fii
	local I = I0 + dt * (V_C0 - I0 * R - I0 * dL / dt) / Fii
	if (config["I_max"] ~= nil) and (I > config["I_max"]) then
		I = config["I_max"]
	end
	local V_C = V_C0 - dt * I / (config["C"] / 1000000)
	if (config["parallel_diode"]) and (V_C < 0) then
		V_C = 0.0
	end

	return t, F, a_projectile, V_projectile, x, dx_mm, I, V_C
end


function analyze(config, results)
	mi_saveas(TEMP_FILE_NAME)
	mi_analyze(1)
	mi_loadsolution()

	mo_groupselectblock(PROJECTILE_BLOCK_ID)
	local V_projectile = mo_blockintegral(10)
	local m_projectile = IRON_RO * V_projectile + config["projectile_extra_mass_grams"] / 1000.0

	local R_coil = calculate_coil_R(results["wire_l_mm"], config["wire_diameter_mm"])
	local R = R_coil + config["R_switch"] + calculate_R_cc(config)
	local L = calculate_coil_L(results["coil_x"], results["coil_y"], results["coil_n"])

	local t = 0
	local dt = config["dt_us"] / 1000000.0
	local x = config["projectile"]["y_offset"]
	local I = 0.01
	local projectile_V = config["projectile_v0"]
	local V_C = config["V_C"]
	local dx, F, a
	local end_X = config["projectile"]["y_offset"] + config["coil"]["step_mm"] * getn(config["coil"]["points"])
	local space_end_X = config["space_size_mm"] - config["projectile"]["step_mm"] * (getn(config["projectile"]["points"]) - 2)

	local t_values = {}
	local F_values = {}
	local a_values = {}
	local projectile_V_values = {}
	local x_values = {}
	local dx_values = {}
	local I_values = {}
	local V_C_values = {}
	local i = 0

	while not true do
		t, F, a, projectile_V, x, dx, I, V_C = analysis_step(m_projectile, R, config,
				t, dt, I, V_C, projectile_V, x)
		print(F)
		append(t_values, t)
		append(F_values, F)
		append(a_values, a)
		append(projectile_V_values, projectile_V)
		append(x_values, x)
		append(dx_values, dx)
		append(I_values, I)
		append(V_C_values, V_C)

		i = i + 1
		if i >= MAXITER then
			break
		elseif (i > 1) and (F < 1E-2) and (F > -1E-2) then
			break
		elseif projectile_V < 0 then
			break
		elseif (x > end_X) and (F > -1E-3) and (F < 1E-3) then
			break
		elseif x < config["projectile"]["y_offset"] then
			break
		elseif config["switch_turnable"] and config["switch_disable"] ~= nil then
			if config["switch_disable"](t, x, projectile_V) then
				break
			end
		elseif x >= space_end_X then
			break
		end
	end
	local simulation_result = {}
	for i=1,getn(t_values) do
		append(simulation_result, {
			["t"] = t_values[i],
			["F"] = F_values[i],
			["a"] = a_values[i],
			["projectile_V"] = projectile_V_values[i],
			["x_mm"] = x_values[i],
			["dx_mm"] = dx_values[i],
			["I"] = I_values[i],
			["V_C"] = V_C_values[i]
		})
	end
	local configuration = {
		["coil"] = {
			["L"] = L,
			["wire_l_mm"] = results["wire_l_mm"],
			["n"] = results["coil_n"],
		}
	}
	local experiment_result = {
		["simulation"] = simulation_result,
		["configuration"] = configuration
	}
	mi_close()
	return experiment_result
end


-----------------------------------------------------
---            Whole experiment                   ---
-----------------------------------------------------
function save_result(config, experiment_result)
	local result_string = ""
	result_string = result_string .. "configuration.coil.L=" .. tostring(experiment_result["configuration"]["coil"]["L"]) .. "\n"
	result_string = result_string .. "configuration.coil.n=" .. tostring(experiment_result["configuration"]["coil"]["n"]) .. "\n"
	result_string = result_string .. "configuration.coil.wire_l_mm=" .. tostring(experiment_result["configuration"]["coil"]["wire_l_mm"]) .. "\n"
	result_string = result_string .. "#SIMULATION\n"
	result_string = result_string .. "t\tF\ta\tprojectile_V\tx_mm\tdx_mm\tI\tV_C\n"
	for _, step in experiment_result["simulation"] do
		result_string = result_string .. tostring(step["t"]) .. "\t" .. tostring(step["F"]) .. "\t" .. tostring(step["a"])
		result_string = result_string .. "\t" .. tostring(step["projectile_V"]) .. "\t" .. tostring(step["x_mm"])
		result_string = result_string .. "\t" .. tostring(step["dx_mm"]) .. "\t" .. tostring(step["I"])
		result_string = result_string .. "\t" .. tostring(step["V_C"]) .. "\n"
	end

	local handle = openfile(config["result_file_name"], "w")
	write(handle, result_string)
	closefile(handle)
end


function read_configuration()
    dofile("config.lua")
    return __configuration
end


function main(config)
	showconsole()
	clearconsole()
    initialize(config)
	local place_results = place_objects(config)
    mi_zoomnatural()
	local experiment_result = analyze(config, place_results)
	save_result(config, experiment_result)
	remove(TEMP_FILE_NAME)
	remove(TEMP_ANS_FILE_NAME)
end


main(read_configuration())
--quit()