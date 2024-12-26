local function trim(str)
	return (string.match(str, "^%s*(.-)%s*$") or "")
end
local function is_windows()
	local uname = vim.loop.os_uname()
	return uname.sysname:match("^Windows")
end
local function split(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		table.insert(t, str)
	end
	return t
end
local function printTable(tbl, indent)
	indent = indent or "  "
	for k, v in pairs(tbl) do
		if type(v) == "table" then
			print(indent .. tostring(k) .. ":")
			printTable(v, indent .. "  ")
		else
			print(indent .. tostring(k) .. ": " .. tostring(v))
		end
	end
end
local isWindows = is_windows() and 1 or 0
local separator = "/"
local cwd = ''
local config = {
	file_icons = {
		["lua"] = "",
		["json"] = "",
		["xml"] = "",
		["yaml"] = "",
		["yml"] = "",
		["txt"] = "",
		["md"] = "",
		["py"] = "",
		["js"] = "",
		["ts"] = "",
		["tsx"] = "",
		["jsx"] = "",
		["vue"] = "",
		["svelte"] = "",
		["html"] = "",
		["css"] = "",
		["less"] = "",
		["sass"] = "",
		["stylus"] = "",
		["tailwind"] = "󱏿",
		["prisma"] = "",
		["java"] = "",
		["c"] = "",
		["c#"] = "",
		["cpp"] = "",
		["sh"] = "",
		["rust"] = "",
		["ruby"] = "",
		["php"] = "",
		["jpg"] = "",
		["png"] = "",
		["gif"] = "",
		["ico"] = "",
		["svg"] = "",
		["pdf"] = "",
		["doc"] = "",
		["docx"] = "",
		["xls"] = "",
		["xlsx"] = "",
		["ppt"] = "",
		["pptx"] = "",
		["zip"] = "",
		["gitignore"] = "",
		["LICENSE"] = "󱕴",
		["mp4"] = "",
		["mp3"] = "",
		["default"] = "",
	},
	folder_icon = "",
	folder_open_icon = "",
	auto_focus_file = true,
	enable_git_status = true
}
local git_hightlight_color = {
	M = { name = "GitModified", fg = '#FFC107' },
	A = { name = "GitAdded", fg = '#28A745' },
	D = { name = "GitDeleted", fg = '#DC3545' },
	R = { name = "GitRenamed", fg = '#17A2B8' },
	C = { name = "GitCopied", fg = '#007BFF' },
	U = { name = "GitUnmerged", fg = '#DEDEDE' },
}
local function get_file_icon(is_dir, file)
	if is_dir then
		return config.folder_icon
	end
	local ext = vim.fn.fnamemodify(file, ":e")
	return config.file_icons[ext] or config.file_icons["default"]
end
local M = {}
local files_list_data = {}
local files_index_map = {}
local files_git_status = {}
local files_list = {}
local tree_bufnr = nil
local cur_line = 1
local is_tree_open = false
local is_first_open = false
local width = 30
local can_checking_git_status = true --是否能获取git状态
local copied_file_path = nil
local moved_file_path = nil
local function getValueByIndexPath(tree, indexPath)
	local current = { children = tree }
	for i = 1, #indexPath do
		current = current.children[indexPath[i]]
		if not current then
			error("Invalid index path")
			return nil
		end
	end
	return current
end
local function updateValueByIndexPath(tree, indexPath, newValue, isChange)
	local current = { children = tree }
	for i = 1, #indexPath do
		current = current.children[indexPath[i]]
		if not current then
			error("Invalid index path")
			return false
		end
	end
	if isChange ~= nil and isChange(current) == false then
		return false
	end
	for key, value in pairs(newValue) do
		current[key] = value
	end
	return true
end
local function get_current_files(path, level)
	local pathIndex = files_index_map[path]
	local old_data = nil
	local currentLevel = level + 1
	if pathIndex ~= nil then
		old_data = getValueByIndexPath(files_list_data, pathIndex)
	end
	local result = {}
	local folderResult = {}
	local fileResult = {}
	for file in vim.fs.dir(path) do
		local indent = string.rep("  ", level)
		local full_path = path .. separator .. file
		local is_dir = vim.fn.isdirectory(full_path) == 1
		local name = " " .. indent .. get_file_icon(is_dir, file) .. " " .. file
		local info = {
			name = name,
			level = currentLevel,
			full_path = full_path,
			parent_path = path,
			is_dir = is_dir,
			is_open = false,
			children = is_dir and {} or nil,
			git_status = nil
		}
		if is_dir then
			if old_data then
				for i = 1, #old_data.children do
					local oldItem = old_data.children[i]
					if oldItem.full_path == info.full_path and oldItem.is_dir and oldItem.is_open then
						info.is_open = true
						info.children = oldItem.children
						info.name = oldItem.name
					end
				end
			end
			table.insert(folderResult, info)
		else
			table.insert(fileResult, info)
		end
	end
	local index = 1
	local function set_pathIndex(full_path, curLevel)
		local newPathIndexs = {}
		if pathIndex ~= nil then
			for i = 1, #pathIndex do
				newPathIndexs[i] = pathIndex[i]
			end
		end
		newPathIndexs[curLevel] = index
		files_index_map[full_path] = newPathIndexs
		index = index + 1
	end
	for j = 1, #folderResult do
		set_pathIndex(folderResult[j].full_path, currentLevel)
		table.insert(result, folderResult[j])
	end
	for j = 1, #fileResult do
		set_pathIndex(fileResult[j].full_path, currentLevel)
		table.insert(result, fileResult[j])
	end
	if level <= 0 then
		files_list_data = result
	else
		if pathIndex ~= nil then
			updateValueByIndexPath(files_list_data, pathIndex, { children = result })
		end
	end
end
local function set_cursor_to_tree_line(line, scrollCenter)
	local winnr = vim.fn.win_findbuf(tree_bufnr)[1]
	if winnr then
		vim.api.nvim_set_current_win(winnr)
		vim.api.nvim_win_set_cursor(winnr, { line, 0 })
		cur_line = line
		if scrollCenter then
			vim.api.nvim_win_set_option(winnr, "scrolloff", 5)
		end
	end
end
local function render_tree()
	local content = {}
	files_list = {}
	local highlight_lines = {
		M = {},
		A = {},
		D = {},
		R = {},
		C = {},
		U = {},
	}
	local index = 1
	local function foreachTree(tree)
		for i = 1, #tree do
			local git_status = files_git_status[tree[i].full_path]
			if git_status ~= nil then
				table.insert(highlight_lines[git_status], index)
			end
			index = index + 1
			table.insert(files_list, tree[i])
			table.insert(content, tree[i].name)
			if tree[i].children and tree[i].is_open then
				foreachTree(tree[i].children)
			end
		end
	end
	foreachTree(files_list_data)
	vim.api.nvim_buf_set_lines(tree_bufnr, 0, -1, false, content)
	for type, lines in pairs(highlight_lines) do
		for i = 1, #lines do
			vim.api.nvim_buf_add_highlight(tree_bufnr, -1, git_hightlight_color[type].name, lines[i] - 1, 0, -1)
		end
	end
end
local function open_file_or_folder_under_cursor()
	local line_number = vim.fn.line(".")
	local item = files_list[line_number]
	local full_path = item.full_path
	local level = item.level
	if item.is_dir then
		local pathIndexs = files_index_map[full_path]
		if item.is_open == false then
			updateValueByIndexPath(files_list_data, pathIndexs, {
				is_open = true,
				name = string.gsub(files_list[line_number].name, config.folder_icon, config.folder_open_icon),
			})
			get_current_files(full_path, level)
		else
			updateValueByIndexPath(files_list_data, pathIndexs, {
				is_open = false,
				name = string.gsub(files_list[line_number].name, config.folder_open_icon, config.folder_icon),
			})
		end
		render_tree()
		set_cursor_to_tree_line(line_number)
	else
		local current_win = vim.fn.winnr()
		local right_win_id = vim.fn.win_getid(current_win + 1)
		if right_win_id ~= 0 then
			vim.api.nvim_set_current_win(right_win_id)
			vim.cmd("edit " .. full_path)
		else
			vim.cmd("vsplit " .. full_path)
			vim.cmd("wincmd l")
		end
	end
end
local function delete_file_or_folder_under_cursor()
	local line_number = vim.fn.line(".")
	local item = files_list[line_number]
	local full_path = item.full_path
	if full_path then
		local confirm = vim.fn.confirm("Confirm to delete " .. full_path .. "?", "&yes\n&no")
		if confirm == 1 then
			if item.is_dir then
				vim.fn.delete(full_path, "rf")
			else
				vim.fn.delete(full_path)
			end
			get_current_files(item.parent_path, item.level - 1)
			render_tree()
			set_cursor_to_tree_line(line_number)
		end
	end
end
local function create_file_or_folder_under_cursor()
	local line_number = vim.fn.line(".")
	local item = files_list[line_number]
	local path = item.parent_path
	local is_dir = item.is_dir
	if item.is_dir then
		path = item.full_path
	elseif not parent_path then
		path = vim.fn.getcwd()
	end
	local input = vim.fn.input("please input the file name or path: ")
	if input == "" then
		return
	end
	local full_path = trim(path .. "/" .. input)
	local confirm = vim.fn.confirm("confirm to create " .. input .. "?", "&yes\n&no")
	if confirm == 1 then
		local str = string.sub(full_path, -1)
		if str == "/" or str == separator then
			vim.fn.mkdir(full_path)
		else
			vim.fn.writefile({}, full_path)
		end
		get_current_files(path, is_dir and item.level or item.level - 1)
		render_tree()
		set_cursor_to_tree_line(line_number)
	end
end
local function rename_file_or_folder_under_cursor()
	local line_number = vim.fn.line(".")
	local item = files_list[line_number]
	local full_path = item.full_path
	if full_path then
		local new_name = vim.fn.input("Please enter a new name: ", vim.fn.fnamemodify(full_path, ":t"))
		if new_name == "" or new_name == vim.fn.fnamemodify(full_path, ":t") then
			return
		end
		local new_full_path = vim.fn.fnamemodify(full_path, ":h") .. "/" .. new_name
		local confirm = vim.fn.confirm("Confirm to rename to " .. new_name .. "?", "&yes\n&no")
		if confirm == 1 then
			if os.rename(full_path, new_full_path) then
				get_current_files(item.parent_path, item.level - 1)
				render_tree()
				set_cursor_to_tree_line(line_number)
			else
				vim.api.nvim_err_writeln("Rename failed")
			end
		end
	end
end
local function copy_file_under_cursor()
	local line_number = vim.fn.line(".")
	local item = files_list[line_number]
	local full_path = item.full_path
	if full_path then
		moved_file_path = nil
		copied_file_path = full_path
		vim.api.nvim_echo({ { "copy: " .. full_path, "MoreMsg" } }, true, {})
	end
end
local function move_file_under_cursor()
	local line_number = vim.fn.line(".")
	local item = files_list[line_number]
	local full_path = item.full_path
	if full_path then
		copied_file_path = nil
		moved_file_path = full_path
		vim.api.nvim_echo({ { "move: " .. full_path, "MoreMsg" } }, true, {})
	end
end
local function paste_file_under_cursor()
	if not copied_file_path and not moved_file_path then
		vim.api.nvim_echo({ { "No files were copied or cut", "WarningMsg" } }, true, {})
		return
	end
	local line_number = vim.fn.line(".")
	local item = files_list[line_number]
	local path = item.full_path
	local parent_path = item.parent_path
	if not parent_path then
		parent_path = vim.fn.getcwd()
	end
	local is_dir = item.is_dir
	if is_dir ~= true then
		path = parent_path
	end
	local isCopy = copied_file_path and 1 or 0
	local origin_path = isCopy and copied_file_path or moved_file_path
	local base_name = vim.fn.fnamemodify(origin_path, ":t")
	local new_full_path = path .. "/" .. base_name
	if vim.fn.isdirectory(new_full_path) == 1 or vim.fn.filereadable(new_full_path) == 1 then
		local confirm = vim.fn.confirm("Whether to overwrite a file or folder with the same name?", "&yes\n&no")
		if confirm ~= 1 then
			return
		end
	end
	local command
	if isWindows == 1 then
		if isCopy == 1 then
			command = string.format('copy "%s" "%s"', origin_path, new_full_path)
		else
			command = string.format('move "%s" "%s"', origin_path, new_full_path)
		end
	else
		if vim.fn.isdirectory(origin_path) == 1 then
			if isCopy == 1 then
				command = string.format('cp -r "%s" "%s"', origin_path, new_full_path)
			else
				command = string.format('mv "%s" "%s"', origin_path, new_full_path)
			end
		else
			if isCopy == 1 then
				command = string.format('cp "%s" "%s"', origin_path, new_full_path)
			else
				command = string.format('mv "%s" "%s"', origin_path, new_full_path)
			end
		end
	end
	local function execute_command(command)
		local file = io.popen(command)
		if file then
			local output = file:read("*all")
			file:close()
			return output
		else
			return nil
		end
	end
	local success = execute_command(command)
	if success then
		get_current_files(path, is_dir and item.level or item.level - 1)
		if isCopy == 0 then
			for i = 1, #files_list do
				if files_list[i].full_path == origin_path then
					get_current_files(files_list[i].parent_path, files_list[i].level - 1)
					break
				end
			end
		end
	else
		vim.api.nvim_err_writeln("copy failed")
	end
	render_tree()
	set_cursor_to_tree_line(line_number)
end
local function locate_file_in_tree()
	if is_tree_open == false then
		return false
	end
	local cur_buf_nr = vim.api.nvim_get_current_buf()
	if cur_buf_nr == tree_bufnr then
		return false
	end
	local file_path = vim.api.nvim_buf_get_name(cur_buf_nr)
	if file_path == "" then
		return false
	end
	if files_list[cur_line] and file_path == files_list[cur_line].name then
		return false
	end
	local pathIndexs = files_index_map[file_path]
	if pathIndexs == nil then
		return false
	end
	local newPathIndexs = {}
	for i = 1, #pathIndexs do
		newPathIndexs[i] = pathIndexs[i]
		local current = getValueByIndexPath(files_list_data, newPathIndexs)
		if current ~= nil then
			if current.is_dir == true and current.is_open == false then
				current.is_open = true
				current.name = string.gsub(current.name, config.folder_icon, config.folder_open_icon)
			end
		else
			print("Error: current is nil at index path")
		end
	end
	render_tree()
	local line_number = 0
	for i, node in ipairs(files_list) do
		if node.full_path == file_path then
			line_number = i
			break
		end
	end
	if line_number == 0 then
		return false
	end
	local cur_win_id = vim.api.nvim_get_current_win()
	set_cursor_to_tree_line(line_number, true)
	vim.api.nvim_set_current_win(cur_win_id)
	vim.api.nvim_set_current_buf(cur_buf_nr)
end
local function get_git_status()
	if can_checking_git_status == false then
		return
	end
	can_checking_git_status = false
	local git_cmd = "git status --untracked-files=no --porcelain --short"
	files_git_status = {}
	local job = vim.fn.jobstart(git_cmd, {
		on_stdout = function(job_id, data, event)
			if event == "stdout" then
				if #data > 0 then
					for _, line in ipairs(data) do
						if line ~= "" then
							local status_code = string.sub(line, 2, 2)
							local path = string.sub(line, 4)
							local status_description = {
								M = "Modified",
								A = "Added",
								D = "Deleted",
								R = "Renamed",
								C = "Copied",
								U = "Unmerged",
							}
							local result = split(path, separator)
							local str = ''
							for j = 1, #result do
								str = str .. separator .. result[j]
								local file_path = cwd .. str
								files_git_status[file_path] = status_code
							end
						end
					end
				else
					print("No changes detected.")
				end
			end
		end,
		on_exit = function(job_id, exit_code)
			if exit_code == 0 then
				if is_tree_open then
					render_tree()
				end
			end
			can_checking_git_status = true
		end
	})
end
local function toggle_tree()
	if is_tree_open then
		local winnr = vim.fn.win_findbuf(tree_bufnr)[1]
		if winnr then
			vim.api.nvim_set_current_win(winnr)
			vim.cmd("q")
		end
		is_tree_open = false
	else
		vim.cmd("wincmd H")
		vim.cmd("vsplit")
		vim.cmd("wincmd h")
		vim.cmd("vertical resize " .. width)
		tree_bufnr = vim.api.nvim_create_buf(false, true)
		if not is_first_open then
			get_current_files(cwd, 0)
			is_first_open = true
		end
		vim.api.nvim_win_set_buf(0, tree_bufnr)
		render_tree()
		set_cursor_to_tree_line(1)
		is_tree_open = true
		vim.api.nvim_buf_set_option(tree_bufnr, "filetype", "simple-tree")
		vim.api.nvim_win_set_option(0, "wrap", false)
		vim.api.nvim_win_set_option(0, "wrapscan", false)
		vim.api.nvim_win_set_option(0, "cursorline", true)
		vim.api.nvim_win_set_option(0, "number", false)
		vim.api.nvim_win_set_option(0, "relativenumber", false)
		vim.api.nvim_win_set_option(0, "signcolumn", "no")
		vim.api.nvim_win_set_option(0, "foldenable", false)
		vim.api.nvim_win_set_option(0, "list", false)
		vim.api.nvim_win_set_option(0, "scrolloff", 0)
		vim.api.nvim_win_set_option(0, "sidescroll", 1)
		vim.api.nvim_win_set_option(0, "sidescrolloff", 5)
		local insert_mode_keys =
		{ "i", "a", "I", "A", "o", "O", "s", "S", "X", "cw", "C", "P", ".", "c", "x", "u", "U", "d", "D", "p" }
		for _, key in ipairs(insert_mode_keys) do
			vim.api.nvim_buf_set_keymap(tree_bufnr, "n", key, "<Nop>", { noremap = true, silent = true })
			vim.api.nvim_buf_set_keymap(tree_bufnr, "v", key, "<Nop>", { noremap = true, silent = true })
		end
		vim.api.nvim_buf_set_keymap(
			tree_bufnr,
			"n",
			"<CR>",
			':lua require("simple-tree").open_file_or_folder_under_cursor()<CR>',
			{ noremap = true, silent = true }
		)
		vim.api.nvim_buf_set_keymap(
			tree_bufnr,
			"n",
			"o",
			':lua require("simple-tree").open_file_or_folder_under_cursor()<CR>',
			{ noremap = true, silent = true }
		)
		vim.api.nvim_buf_set_keymap(
			tree_bufnr,
			"n",
			"d",
			':lua require("simple-tree").delete_file_or_folder_under_cursor()<CR>',
			{ noremap = true, silent = true }
		)
		vim.api.nvim_buf_set_keymap(
			tree_bufnr,
			"n",
			"a",
			':lua require("simple-tree").create_file_or_folder_under_cursor()<CR>',
			{ noremap = true, silent = true }
		)
		vim.api.nvim_buf_set_keymap(
			tree_bufnr,
			"n",
			"r",
			':lua require("simple-tree").rename_file_or_folder_under_cursor()<CR>',
			{ noremap = true, silent = true }
		)
		vim.api.nvim_buf_set_keymap(
			tree_bufnr,
			"n",
			"<2-LeftMouse>",
			':lua require("simple-tree").open_file_or_folder_under_cursor()<CR>',
			{ noremap = true, silent = true }
		)
		vim.api.nvim_buf_set_keymap(
			tree_bufnr,
			"n",
			"c",
			':lua require("simple-tree").copy_file_under_cursor()<CR>',
			{ noremap = true, silent = true }
		)
		vim.api.nvim_buf_set_keymap(
			tree_bufnr,
			"n",
			"p",
			':lua require("simple-tree").paste_file_under_cursor()<CR>',
			{ noremap = true, silent = true }
		)
		vim.api.nvim_buf_set_keymap(
			tree_bufnr,
			"n",
			"m",
			':lua require("simple-tree").move_file_under_cursor()<CR>',
			{ noremap = true, silent = true }
		)
	end
end
function M.setup(user_conf)
	vim.api.nvim_create_user_command("TreeToggle", function()
		toggle_tree()
	end, {})
	user_conf = user_conf or {}
	if user_conf.folder_icon and type(user_conf.folder_icon) == "string" then
		config.folder_icon = user_conf.folder_icon
	end
	if user_conf.width and type(user_conf.width) == "number" then
		width = user_conf.width
	end
	if user_conf.folder_open_icon and type(user_conf.folder_open_icon) == "string" then
		config.folder_open_icon = user_conf.folder_open_icon
	end
	if user_conf.file_icons and type(user_conf.file_icons) == "table" then
		for key, value in pairs(user_conf.file_icons) do
			config.file_icons[key] = value
		end
	end
	if user_conf.enable_git_status and type(user_conf.enable_git_status) == "boolean" then
		config.enable_git_status = user_conf.enable_git_status
	end
	if user_conf.auto_focus_file and type(user_conf.auto_focus_file) == "boolean" then
		config.auto_focus_file = user_conf.auto_focus_file
	end
	if config.auto_focus_file then
		vim.api.nvim_create_autocmd("BufEnter", {
			callback = function()
				locate_file_in_tree()
			end,
		})
	end
	cwd = vim.fn.expand("%:p:h")
	if vim.fn.isdirectory(cwd) ~= 1 then
		cwd = vim.fn.expand("%:p:h:h")
	end
	if config.enable_git_status then
		local is_git_repo = vim.fn.system("git rev-parse --is-inside-work-tree")
		if string.match(is_git_repo, "true") == nil then
			can_checking_git_status = false
			return
		end
		if can_checking_git_status == true then
			for key, item in pairs(git_hightlight_color) do
				vim.api.nvim_set_hl(0, item.name, {
					fg = item.fg,
					bold = false,
					italic = false,
					underline = false,
				})
			end
			get_git_status()
			vim.api.nvim_create_autocmd("BufWritePost", {
				callback = function()
					if is_tree_open then
						get_git_status()
					end
				end,
			})
		end
	end
	M.open_file_or_folder_under_cursor = open_file_or_folder_under_cursor
	M.delete_file_or_folder_under_cursor = delete_file_or_folder_under_cursor
	M.create_file_or_folder_under_cursor = create_file_or_folder_under_cursor
	M.rename_file_or_folder_under_cursor = rename_file_or_folder_under_cursor
	M.copy_file_under_cursor = copy_file_under_cursor
	M.move_file_under_cursor = move_file_under_cursor
	M.paste_file_under_cursor = paste_file_under_cursor
end
return M
