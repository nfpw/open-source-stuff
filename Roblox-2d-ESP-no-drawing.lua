--// start stuff
	if not game:IsLoaded() then
		repeat
			game.Loaded:Wait()
		until game:IsLoaded()
	end

	--// bad executor check
	    --if not (isfolder and isfile and readfile and writefile and makefolder and ((syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request) and ((syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)) and game.HttpGetAsync and loadstring) then return print('get better executor') end;
	--__

	--// exploit funcs
		local http_request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request;
		local queue_on_teleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport);
		local get = function(string, boolean) return game:HttpGetAsync(string, boolean); end;
		local cloneref = cloneref or function(instance) return instance; end;
		local shared = getgenv() or shared or _G;
		--local print = secureprint or print;
		--local warn = securewarn or warn;
		local load = loadstring;
	--__

	--// service
		local service = function(instance) return game:GetService(instance); end;
	--__

	--// misc
		local gethui = gethui or function() return cloneref(service'CoreGui'); end;
	--__
--__

--// render
    local utility = {}
    function utility:render(class, properties)
        local instance = Instance.new(class)
        for property, value in pairs(properties) do
            instance[property] = value
        end
        return instance
    end
    local esp_gui = utility:render('ScreenGui', {
        Name = '@nfpw Esp Render',
        Parent = gethui()
    })
--__

--// playeresp code
	local insert = table.insert
	local find_first_child = cloneref(service'Workspace').FindFirstChild
	local is_a = cloneref(service'Workspace').IsA
	local players = cloneref(service'Players');
	local run_service = cloneref(service'RunService');
	local core_gui = cloneref(service'CoreGui');
	local teams = cloneref(service'Teams');
	local local_player = players.LocalPlayer
	local camera = cloneref(service'Workspace').CurrentCamera
	local viewport_size = camera.ViewportSize

	function get_team_color(player)
		if not shared.Visual_Hub.Visuals.PlayerESP.UseTeamColor then return nil end
		local team = player.Team
		if team then return team.TeamColor.Color end
		return nil
	end

	function is_teammate(player)
		if not shared.Visual_Hub.Visuals.PlayerESP.TeamCheck then return false end
		if not local_player.Team then return false end
		return player.Team == local_player.Team
	end

	function is_within_max_distance(distance)
		local max_distance = shared.Visual_Hub.Visuals.PlayerESP.MaxDistance
		if max_distance <= 0 then return true end
		return distance <= max_distance
	end

	local skeleton_connections = {
		{"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
		{"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
		{"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
		{"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
		{"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
		{"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
	}

	do
		local plr_esp = {}
		local player_data = {}
		local last_state = true

		function plr_esp.clean_all()
			for player, data in pairs(plr_esp) do
				if type(data) == "table" and player ~= "clean_all" and player ~= local_player then
					plr_esp.remove(player)
				end
			end
		end

        plr_esp.get_players = function()
			local plrs = {}
			for _, v in players:GetPlayers() do
				if v ~= local_player then insert(plrs, v) end
			end
			return plrs
		end

		plr_esp.get_character = function(plr)
			return plr and plr.Character
		end

		plr_esp.get_health = function(plr)
			local character = plr_esp.get_character(plr)
			local humanoid = character and find_first_child(character, 'Humanoid')
			if humanoid and humanoid.Health and humanoid.MaxHealth then
				return humanoid.Health, humanoid.MaxHealth
			end
			return 100, 100
		end

		plr_esp.get_tool = function(plr)
			local character = plr_esp.get_character(plr)
			if not character then return "None" end
			for _, child in pairs(character:GetChildren()) do
				if child:IsA("Tool") then return child.Name end
			end
			local backpack = plr:FindFirstChild("Backpack")
			if backpack then
				for _, tool in pairs(backpack:GetChildren()) do
					if tool:IsA("Tool") then return tool.Name.." (Backpack)" end
				end
			end
			return "None"
		end

		plr_esp.get_distance = function(from, to, unit)
			if not (from and from.Position and to and to.Position) then return 0 end
			local distance = (from.Position - to.Position).Magnitude
			return unit == "Meters" and distance * 0.28 or distance
		end

		plr_esp.is_alive = function(plr)
			local character = plr_esp.get_character(plr)
			local root_part = character and find_first_child(character, 'HumanoidRootPart')
			return plr and character and root_part and plr_esp.get_health(plr) > 0
		end

		plr_esp.remove = function(object)
			if not plr_esp[object] then return end
			local elements = plr_esp[object]
			if elements.holder then elements.holder:Destroy() end
			if elements.skeleton then
				for _, skeletonPart in pairs(elements.skeleton) do
					if skeletonPart.line and skeletonPart.line.Parent then
						skeletonPart.line:Destroy()
					end
				end
			end
			if player_data[object] and player_data[object].skeleton_holder then
				player_data[object].skeleton_holder:Destroy()
			end
			if elements.look_direction and elements.look_direction.line then
				elements.look_direction.line:Destroy()
			end
			if elements.bounding_box and elements.bounding_box.image then
				elements.bounding_box.image:Destroy()
			end
			plr_esp[object] = nil
			player_data[object] = nil
		end

		plr_esp.add = function(object)
			if plr_esp[object] then return end

			plr_esp[object] = {
				holder = utility:render('Frame', {
					Parent = esp_gui,
					Name = object.Name,
					BackgroundTransparency = 1,
					BorderSizePixel = 0
				}),
				bounding_box = {
					frame = utility:render("Frame", {
						Name = object.Name,
						BackgroundTransparency = 1,
						BorderSizePixel = 0
					}),
					outline = utility:render("UIStroke", {
						Enabled = false,
						Name = object.Name,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						LineJoinMode = Enum.LineJoinMode.Miter,
						Thickness = 3
					}),
					inline = utility:render("UIStroke", {
						Enabled = false,
						Name = object.Name,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						LineJoinMode = Enum.LineJoinMode.Miter,
						Thickness = 1
					}),
					image = utility:render("ImageLabel", {
						Name = object.Name .. "_BoxImage",
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Visible = false,
						ZIndex = 1,
						ScaleType = Enum.ScaleType.Stretch
					})
				},
				health_bar = {
					outline = utility:render("Frame", {
						Name = object.Name,
						BackgroundTransparency = 1,
						BorderSizePixel = 0
					}),
					inline = utility:render("Frame", {
						Name = object.Name,
						BackgroundTransparency = 1,
						BorderSizePixel = 0
					}),
					gradient = utility:render("UIGradient", {
						Name = object.Name,
						Enabled = false
					}),
					value_text = utility:render("TextLabel", {
						Name = object.Name,
						BackgroundTransparency = 1,
						TextStrokeTransparency = 0
					}),
					value_outline = utility:render("UIStroke", {
						Enabled = true,
						Name = object.Name,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
						LineJoinMode = Enum.LineJoinMode.Miter,
						Thickness = 1
					})
				},
				username = {
					text = utility:render("TextLabel", {
						Name = object.Name,
						BackgroundTransparency = 1,
						TextStrokeTransparency = 0
					}),
					outline = utility:render("UIStroke", {
						Enabled = true,
						Name = object.Name,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
						LineJoinMode = Enum.LineJoinMode.Miter,
						Thickness = 1
					})
				},
				distance = {
					text = utility:render("TextLabel", {
						Name = object.Name,
						BackgroundTransparency = 1,
						TextStrokeTransparency = 0
					}),
					outline = utility:render("UIStroke", {
						Enabled = true,
						Name = object.Name,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
						LineJoinMode = Enum.LineJoinMode.Miter,
						Thickness = 1
					})
				},
				tool = {
					text = utility:render("TextLabel", {
						Name = object.Name,
						BackgroundTransparency = 1,
						TextStrokeTransparency = 0
					}),
					outline = utility:render("UIStroke", {
						Enabled = true,
						Name = object.Name,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
						LineJoinMode = Enum.LineJoinMode.Miter,
						Thickness = 1
					})
				},
				skeleton = {},
				look_direction = {
					line = utility:render("Frame", {
						Name = object.Name.."_LookDirection",
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderSizePixel = 0,
						BackgroundTransparency = 0,
						Size = UDim2.new(0, 1, 0, 1),
						Position = UDim2.new(0, 0, 0, 0),
						Visible = false,
						Parent = esp_gui,
						AnchorPoint = Vector2.new(0.5, 0.5),
						ZIndex = 10
					})
				}
			}

			local skeleton_holder = utility:render("Frame", {
				Name = object.Name.."_Skeleton",
				Parent = esp_gui,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Position = UDim2.fromScale(0, 0)
			})

			for _, connection in ipairs(skeleton_connections) do
				local line = utility:render("Frame", {
					Name = connection[1].."_to_"..connection[2],
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BorderSizePixel = 0,
					BackgroundTransparency = 0,
					Size = UDim2.new(0, 1, 0, 1),
					Position = UDim2.new(0, 0, 0, 0),
					Visible = false,
					Parent = skeleton_holder,
					AnchorPoint = Vector2.new(0.5, 0.5)
				})
				table.insert(plr_esp[object].skeleton, {
					line = line,
					from = connection[1],
					to = connection[2]
				})
			end

			player_data[object] = {
				health = 100,
				max_health = 100,
				is_alive = false,
				character = nil,
				root_part = nil,
				humanoid = nil,
				visible = false,
				position = Vector3.new(0, 0, 0),
				screen_position = Vector2.new(0, 0),
				on_screen = false,
				distance = 0,
				width = 0,
				height = 0,
				tool = "None",
				team_color = nil,
				within_max_distance = true,
				skeleton_holder = skeleton_holder,
				joints = {},
				look_direction_vector = Vector3.new(0, 0, 0)
			}
		end

		function check_for_left_players()
			local current_players = {}
			for _, player in pairs(plr_esp.get_players()) do
				current_players[player] = true
			end
			for player in pairs(player_data) do
				if not current_players[player] and player ~= local_player then
					plr_esp.remove(player)
				end
			end
		end

		function update_player_data()
			while true do
				if shared.Visual_Hub.Visuals.PlayerESP.Enabled then
					check_for_left_players()
					for _, player in pairs(plr_esp.get_players()) do
						if not player_data[player] then plr_esp.add(player) end
						local data = player_data[player]
						local character = plr_esp.get_character(player)
						local root_part = character and find_first_child(character, 'HumanoidRootPart')
						local humanoid = character and find_first_child(character, 'Humanoid')
						data.character = character
						data.root_part = root_part
						data.humanoid = humanoid
						data.is_alive = plr_esp.is_alive(player)
						data.health, data.max_health = plr_esp.get_health(player)
						data.tool = plr_esp.get_tool(player)
						data.team_color = get_team_color(player)
						data.is_teammate = is_teammate(player)
						if data.is_alive and data.root_part then
							local camera_pos = camera.CFrame.Position
							data.distance = (data.root_part.Position - camera_pos).Magnitude
							if shared.Visual_Hub.Visuals.PlayerESP.Distance.Unit == "Meters" then
								data.distance = data.distance * 0.28
							end
							data.within_max_distance = is_within_max_distance(data.distance)
						else
							data.visible = false
							data.within_max_distance = false
						end
					end
					last_state = true
				elseif last_state then
					plr_esp.clean_all()
					last_state = false
				end
				task.wait(0.1)
			end
		end

		players.PlayerRemoving:Connect(function(player)
			if player ~= local_player and plr_esp[player] then
				plr_esp.remove(player)
			end
		end)

		spawn(function() update_player_data() end)

		run_service.Heartbeat:Connect(function()
			local esp_table = shared.Visual_Hub.Visuals.PlayerESP
			if not esp_table.Enabled then return end
			for player, elements in pairs(plr_esp) do
				if type(elements) ~= 'table' or not elements.holder then continue; end;
				local data = player_data[player]
				if not data then continue end
				if esp_table.TeamCheck and data.is_teammate and player ~= local_player then
					elements.holder.Visible = false
					data.skeleton_holder.Visible = false
					elements.look_direction.line.Visible = false
					continue
				end
				if not data.within_max_distance then
					elements.holder.Visible = false
					data.skeleton_holder.Visible = false
					elements.look_direction.line.Visible = false
					continue
				end
				if data.is_alive and data.character then
					data.joints = {}
					for _, part_name in pairs({"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}) do
						local part = data.character:FindFirstChild(part_name)
						if part then data.joints[part_name] = part.Position end
					end
				end
				if data.is_alive and data.humanoid and data.humanoid.RootPart then
					data.look_direction_vector = data.humanoid.RootPart.CFrame.LookVector
				end
				if data.is_alive and data.root_part then
					local position, on_screen = camera:WorldToScreenPoint(data.root_part.Position)
					data.position = position
					data.on_screen = on_screen
					if on_screen then
						local d = 3 * position.Z * math.tan(math.rad(camera.FieldOfView) / 2)
						local scale = (data.root_part.Size.Y * viewport_size.Y) / d
						data.height = 4.4 * scale
						data.width = 3.2 * scale
						data.visible = true
						elements.holder.Position = UDim2.fromOffset(position.X - data.width / 2, position.Y - data.height / 2.40)
						elements.holder.Size = UDim2.fromOffset(data.width, data.height)
						if esp_table.Skeleton and esp_table.Skeleton.Enabled then
							data.skeleton_holder.Visible = true
							for i, conn in ipairs(elements.skeleton) do
								local from_joint = data.joints[conn.from]
								local to_joint = data.joints[conn.to]
								if from_joint and to_joint then
									local from_pos, from_visible = camera:WorldToScreenPoint(from_joint)
									local to_pos, to_visible = camera:WorldToScreenPoint(to_joint)
									if from_visible and to_visible then
										local center = Vector2.new((from_pos.X + to_pos.X) / 2, (from_pos.Y + to_pos.Y) / 2)
										local distance = (Vector2.new(from_pos.X, from_pos.Y) - Vector2.new(to_pos.X, to_pos.Y)).Magnitude
										local angle = math.atan2(to_pos.Y - from_pos.Y, to_pos.X - from_pos.X)
										conn.line.Visible = true
										conn.line.Position = UDim2.fromOffset(center.X, center.Y)
										conn.line.Size = UDim2.fromOffset(distance, esp_table.Skeleton.Thickness or 1)
										conn.line.Rotation = math.deg(angle)
										local skeleton_color = data.team_color or esp_table.Skeleton.Color or Color3.fromRGB(255, 255, 255)
										conn.line.BackgroundColor3 = skeleton_color
										conn.line.BackgroundTransparency = esp_table.Skeleton.Transparency or 0
									else
										conn.line.Visible = false
									end
								else
									conn.line.Visible = false
								end
							end
						else
							data.skeleton_holder.Visible = false
						end
						if esp_table.LookDirection and esp_table.LookDirection.Enabled and data.root_part and data.look_direction_vector then
							local head = data.character and data.character:FindFirstChild("Head")
							if head then
								local start_pos = head.Position
								local end_pos = start_pos + (data.look_direction_vector * (esp_table.LookDirection.Length or 10))
								local start_screen_pos, start_visible = camera:WorldToScreenPoint(start_pos)
								local end_screen_pos, end_visible = camera:WorldToScreenPoint(end_pos)
								if start_visible and end_visible then
									local direction_line = elements.look_direction.line
									direction_line.Visible = true
									local center = Vector2.new((start_screen_pos.X + end_screen_pos.X) / 2, (start_screen_pos.Y + end_screen_pos.Y) / 2)
									local distance = (Vector2.new(start_screen_pos.X, start_screen_pos.Y) - Vector2.new(end_screen_pos.X, end_screen_pos.Y)).Magnitude
									local angle = math.atan2(end_screen_pos.Y - start_screen_pos.Y, end_screen_pos.X - start_screen_pos.X)
									direction_line.Position = UDim2.fromOffset(center.X, center.Y)
									direction_line.Size = UDim2.fromOffset(distance, esp_table.LookDirection.Thickness or 1.5)
									direction_line.Rotation = math.deg(angle)
									local line_color = data.team_color or esp_table.LookDirection.Color or Color3.fromRGB(255, 0, 0)
									direction_line.BackgroundColor3 = line_color
									direction_line.BackgroundTransparency = esp_table.LookDirection.Transparency or 0
								else
									elements.look_direction.line.Visible = false
								end
							else
								elements.look_direction.line.Visible = false
							end
						else
							elements.look_direction.line.Visible = false
						end
						if esp_table.HealthBar.Enabled then
							local health_scale = data.health / data.max_health
							local health_inline = elements.health_bar.inline
							local health_value = elements.health_bar.value_text
							health_inline.Size = UDim2.new(1, -2, health_scale, -2)
							health_inline.Position = UDim2.new(0, 1, 1 - health_scale, 1)
							if esp_table.HealthBar.HealthText.Enabled then
								health_value.Position = UDim2.fromOffset(-34, data.height * (1 - health_scale) - 7)
							end
						end
					else
						data.visible = false
						elements.holder.Visible = false
						data.skeleton_holder.Visible = false
						elements.look_direction.line.Visible = false
					end
				else
					data.visible = false
					elements.holder.Visible = false
					data.skeleton_holder.Visible = false
					elements.look_direction.line.Visible = false
				end
			end
		end)
		while task.wait(0.1) do
			local esp_table = shared.Visual_Hub.Visuals.PlayerESP
			if not esp_table.Enabled then continue end
			for player, elements in pairs(plr_esp) do
				if type(elements) ~= 'table' or not elements.holder then continue end
				if not player or not player.Parent then
					plr_esp.remove(player)
					continue
				end
				local data = player_data[player]
				if not data or not data.visible then continue end
				if shared.Visual_Hub.Visuals.PlayerESP.TeamCheck and data.is_teammate then
					elements.holder.Visible = false
					data.skeleton_holder.Visible = false
					elements.look_direction.line.Visible = false
					continue
				end
				if not data.within_max_distance then
					elements.holder.Visible = false
					data.skeleton_holder.Visible = false
					elements.look_direction.line.Visible = false
					continue
				end
				local holder = elements.holder
				local box = elements.bounding_box.frame
				local inline = elements.bounding_box.inline
				local outline = elements.bounding_box.outline
				local health_inline = elements.health_bar.inline
				local health_outline = elements.health_bar.outline
				local health_gradient = elements.health_bar.gradient
				local health_value = elements.health_bar.value_text
				local health_value_outline = elements.health_bar.value_outline
				local username_text = elements.username.text
				local username_outline = elements.username.outline
				local distance_text = elements.distance.text
				local distance_outline = elements.distance.outline
				local tool_text = elements.tool.text
				local tool_outline = elements.tool.outline
				local team_color = data.team_color
				local default_color = Color3.fromRGB(255, 255, 255)
				local player_name = esp_table.Username.UseDisplayName and (player.DisplayName or player.Name) or player.Name
				local health, max_health = data.health, data.max_health
				local tool_name = data.tool or "None"
				local distance_text_value = esp_table.Distance.Unit == "Meters" and string.format("%.1fm", data.distance) or string.format("%d studs", math.floor(data.distance))
				holder.Visible = true
				if esp_table.Box.Enabled then
					local inline_color = team_color or esp_table.Box.Colors.Inline or default_color
					local outline_color = esp_table.Box.Colors.Outline or Color3.fromRGB(0, 0, 0)
					local fill_color = esp_table.Box.Fill.Color or Color3.fromRGB(0, 0, 0)
					local fill_transparency = esp_table.Box.Fill.Transparency
					box.Visible = true
					box.Parent = holder
					box.Position = UDim2.fromOffset(-1, -1)
					box.Size = UDim2.new(1, 2, 1, 2)
					inline.Enabled = true
					inline.Parent = box
					inline.Color = inline_color
					outline.Enabled = true
					outline.Parent = holder
					outline.Color = outline_color
					if esp_table.Box.Fill.Enabled then
						if esp_table.Box.Fill.CustomImage and esp_table.Box.Fill.CustomImage ~= "None" then
							if not elements.bounding_box.image then
								elements.bounding_box.image = utility:render("ImageLabel", {
									Name = player.Name .. "_BoxImage",
									BackgroundTransparency = 1,
									BorderSizePixel = 0,
									ZIndex = 1,
									ScaleType = Enum.ScaleType.Stretch
								})
							end
							local image = elements.bounding_box.image
							image.Visible = true
							image.Parent = holder
							image.Position = UDim2.fromScale(0, 0)
							image.Size = UDim2.fromScale(1, 1)
							image.Image = esp_table.Box.Fill.CustomImage
							image.ImageTransparency = fill_transparency
							image.ImageColor3 = fill_color
							holder.BackgroundTransparency = 1
						else
							if elements.bounding_box.image then
								elements.bounding_box.image.Visible = false
							end
							holder.BackgroundColor3 = fill_color
							holder.BackgroundTransparency = fill_transparency
						end
					else
						if elements.bounding_box.image then
							elements.bounding_box.image.Visible = false
						end
						holder.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
						holder.BackgroundTransparency = 1
					end
				else
					inline.Enabled = false
					outline.Enabled = false
					if elements.bounding_box.image then
						elements.bounding_box.image.Visible = false
					end
				end
				if esp_table.HealthBar.Enabled then
					local health_scale = health / max_health
					local low_health = esp_table.HealthBar.Colors.Finish or Color3.fromRGB(255, 35, 39)
					local high_health = esp_table.HealthBar.Colors.Start or Color3.fromRGB(23, 255, 42)
					local outline_color = esp_table.HealthBar.Colors.Outline or Color3.fromRGB(0, 0, 0)
					local health_color = high_health:Lerp(low_health, 1 - health_scale)
					health_outline.Visible = true
					health_outline.Parent = holder
					health_outline.BackgroundTransparency = 0
					health_outline.BackgroundColor3 = outline_color
					health_outline.Size = UDim2.fromOffset(4, data.height + 6)
					health_outline.Position = UDim2.fromOffset(-9, -3)
					health_inline.Visible = true
					health_inline.Parent = health_outline
					health_inline.BackgroundTransparency = 0
					health_inline.BackgroundColor3 = health_color
					health_gradient.Enabled = false
					if esp_table.HealthBar.HealthText.Enabled then
						local text_color = esp_table.HealthBar.HealthText.Colors.MatchHealthColor and health_color or (team_color or esp_table.HealthBar.HealthText.Colors.Text or default_color)
						local outline_color = esp_table.HealthBar.HealthText.Colors.Outline or Color3.fromRGB(0, 0, 0)
						health_value.Visible = true
						health_value.Parent = holder
						health_value.Text = math.floor(health)
						health_value.TextColor3 = text_color
						health_value.Font = Enum.Font.SourceSansBold
						health_value.TextSize = 13
						health_value.TextTransparency = 0
						health_value.TextStrokeTransparency = 0.5
						health_value.Size = UDim2.fromOffset(30, 15)
						health_value.TextXAlignment = Enum.TextXAlignment.Center
						health_value_outline.Enabled = true
						health_value_outline.Parent = health_value
						health_value_outline.Color = outline_color
					else
						health_value.Visible = false
						health_value_outline.Enabled = false
					end
				else
					health_outline.Visible = false
					health_inline.Visible = false
					health_gradient.Enabled = false
					health_value.Visible = false
					health_value_outline.Enabled = false
				end
				if esp_table.Username.Enabled then
					local text_color = team_color or esp_table.Username.Colors.Text or default_color
					local outline_color = esp_table.Username.Colors.Outline or Color3.fromRGB(0, 0, 0)
					username_text.Visible = true
					username_text.Parent = holder
					username_text.TextColor3 = text_color
					username_text.Font = Enum.Font.SourceSans
					username_text.TextSize = 14
					username_text.TextTransparency = 0
					username_text.TextStrokeTransparency = 1
					username_text.Text = player_name
					username_text.Size = UDim2.fromOffset(100, 0)
					username_text.AutomaticSize = Enum.AutomaticSize.XY
					username_text.TextXAlignment = Enum.TextXAlignment.Center
					username_text.Position = UDim2.new(0.5, -username_text.Size.X.Offset/2, 0, -17)
					username_outline.Enabled = true
					username_outline.Parent = username_text
					username_outline.Color = outline_color
				else
					username_text.Visible = false
					username_outline.Enabled = false
				end
				if esp_table.Distance.Enabled then
					local text_color = team_color or esp_table.Distance.Colors.Text or default_color
					local outline_color = esp_table.Distance.Colors.Outline or Color3.fromRGB(0, 0, 0)
					distance_text.Visible = true
					distance_text.Parent = holder
					distance_text.Text = distance_text_value
					distance_text.TextColor3 = text_color
					distance_text.Font = Enum.Font.SourceSans
					distance_text.TextSize = 13
					distance_text.TextTransparency = 0
					distance_text.TextStrokeTransparency = 1
					distance_text.Size = UDim2.fromOffset(60, 15)
					distance_text.AutomaticSize = Enum.AutomaticSize.X
					distance_text.TextXAlignment = Enum.TextXAlignment.Center
					distance_text.Position = UDim2.new(1, -5, 0, -5)
					distance_outline.Enabled = true
					distance_outline.Parent = distance_text
					distance_outline.Color = outline_color
				else
					distance_text.Visible = false
					distance_outline.Enabled = false
				end
				if esp_table.Tool.Enabled then
					local text_color = team_color or esp_table.Tool.Colors.Text or default_color
					local outline_color = esp_table.Tool.Colors.Outline or Color3.fromRGB(0, 0, 0)
					tool_text.Visible = true
					tool_text.Parent = holder
					tool_text.Text = tool_name
					tool_text.TextColor3 = text_color
					tool_text.Font = Enum.Font.SourceSans
					tool_text.TextSize = 14
					tool_text.TextTransparency = 0
					tool_text.TextStrokeTransparency = 1
					tool_text.Size = UDim2.fromOffset(100, 0)
					tool_text.AutomaticSize = Enum.AutomaticSize.XY
					tool_text.TextXAlignment = Enum.TextXAlignment.Center
					tool_text.Position = UDim2.new(0.5, -tool_text.Size.X.Offset/2, 1, 2)
					tool_outline.Enabled = true
					tool_outline.Parent = tool_text
					tool_outline.Color = outline_color
				else
					tool_text.Visible = false
					tool_outline.Enabled = false
				end
			end
		end
	end
--__
