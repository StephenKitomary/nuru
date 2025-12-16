if not vim.b.nuru_context then
	vim.b.nuru_context = ""
end

local nuru_ns = vim.api.nvim_create_namespace("nuru_eval")
-- Clean ANSI color codes from output
local function clean_output(text)
	text = text:gsub("\27%[[0-9;]*m", "") -- Remove colors
	text = text:gsub("\n$", "") -- Remove trailing newline
	return text
end

local function get_target_code(mode)
	-- If mode is 'block', we try to auto-select the current {} block
	if mode == "block" then
		local save_cursor = vim.fn.getpos(".")
		vim.cmd("normal! va{")
		if vim.fn.mode() == "n" then
			vim.cmd("normal! vip")
		end

		local start_pos = vim.fn.getpos("'<")
		local end_pos = vim.fn.getpos("'>")
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", true)
		vim.fn.setpos(".", save_cursor)

		local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)
		return table.concat(lines, "\n")
	end

	return ""
end

local function execute_nuru(code_chunk, show_result_at_line)
	-- Combine Memory + Current Chunk
	local final_code = (vim.b.nuru_context or "") .. "\n" .. code_chunk

	local tmpfile = "/tmp/nuru_eval.nr"
	local f = io.open(tmpfile, "w")
	if f then
		f:write(final_code)
		f:close()
	else
		print("Error: Could not write temp file")
		return
	end

	local output = vim.fn.system("nuru " .. tmpfile .. " 2>&1")
	output = clean_output(output)

	vim.api.nvim_buf_clear_namespace(0, nuru_ns, 0, -1)

	if show_result_at_line then
		vim.api.nvim_buf_set_extmark(0, nuru_ns, show_result_at_line - 1, 0, {
			virt_text = { { " => " .. output, "Comment" } },
			virt_text_pos = "eol",
		})
	else
		print("Nuru Output: " .. output)
	end
end

local function nuru_memorize_block()
	local code = get_target_code("block")
	if code and code ~= "" then
		vim.b.nuru_context = (vim.b.nuru_context or "") .. "\n" .. code
		print("Nuru: Added function to memory! (" .. #code .. " chars)")
	else
		print("Nuru: Could not find code block to memorize.")
	end
end

local function nuru_clear_memory()
	vim.b.nuru_context = ""
	vim.api.nvim_buf_clear_namespace(0, nuru_ns, 0, -1)
	print("Nuru: Memory cleared.")
end

local function eval_line()
	local line_num = vim.fn.line(".")
	local code = vim.api.nvim_get_current_line()
	execute_nuru(code, line_num)
end

local function eval_visual()
	-- Exit visual mode to set marks
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", true)
	vim.schedule(function()
		local start_ln = vim.fn.line("'<")
		local end_ln = vim.fn.line("'>")
		local lines = vim.api.nvim_buf_get_lines(0, start_ln - 1, end_ln, false)
		local code = table.concat(lines, "\n")
		execute_nuru(code, end_ln)
	end)
end

local function eval_file()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	execute_nuru(table.concat(lines, "\n"), vim.fn.line("$"))
end

-- ==========================================================
-- My keymaps configs, keeping them the same as my clojure keymaps
-- ==========================================================
local map = vim.keymap.set
local opts = { buffer = 0, silent = true }

map("n", "<leader>ss", nuru_memorize_block, vim.tbl_extend("force", opts, { desc = "Memorize Function (Smart Block)" }))
map("n", "<leader>sc", nuru_clear_memory, vim.tbl_extend("force", opts, { desc = "Clear Memory" }))

map("n", "<leader>sf", eval_line, vim.tbl_extend("force", opts, { desc = "Eval line (+Memory)" }))
map("v", "<leader>se", eval_visual, vim.tbl_extend("force", opts, { desc = "Eval selection (+Memory)" }))
map("n", "<leader>sF", eval_file, vim.tbl_extend("force", opts, { desc = "Eval Whole File" }))
