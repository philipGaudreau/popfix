local M = {}
M.__index = M

local api = vim.api

local identifier = api.nvim_create_namespace('popfix.identifier')
local listNamespace = api.nvim_create_namespace('popfix.listManager')


-- @class ListManager manages list UI and selection on various
-- events
function M:new(opts)
	local obj = {
		list = opts.list,
		preview = opts.preview,
		action = opts.action,
		renderLimit = opts.renderLimit,
		linesRendered = 0,
		currentPromptText = '',
		highlightingFunction = opts.highlightingFunction,
	}
	setmetatable(obj, self)
	return obj
end

function M:select(lineNumber)
	api.nvim_buf_clear_namespace(self.list.buffer, listNamespace,
	0, -1)
	api.nvim_buf_add_highlight(self.list.buffer, listNamespace,
	"Visual", lineNumber - 1, 0, -1)
	local data
	if self.sortedList[lineNumber] then
		data = self.action:select(self.sortedList[lineNumber].index,
		self.list:get(lineNumber - 1))
	end
	if data then
		vim.schedule(function()
			if self.preview then
				if data ~= nil then
					self.preview:writePreview(data)
				end
			end
		end)
	end
end

-- lazy rendering while next selection
function M:select_next()
	if self.currentLineNumber == #self.sortedList then
		return
	end
	if self.currentLineNumber == self.renderLimit then
		self.currentLineNumber = self.currentLineNumber + 1
		self.renderLimit = self.renderLimit + 1
		local string =
		self.originalList[self.sortedList[self.currentLineNumber].index]
		vim.schedule(function()
			self.list:appendLine(string)
			self:select(self.currentLineNumber)
		end)
	else
		self.currentLineNumber = self.currentLineNumber + 1
		vim.schedule(function()
			self:select(self.currentLineNumber)
		end)
	end
end

function M:select_prev()
	if self.currentLineNumber == 1 then return end
	self.currentLineNumber = self.currentLineNumber - 1
	self:select(self.currentLineNumber)
end

function M:add(line, starting, ending, highlightLine)
	local add = false
	local highlight = true
	if self.currentPromptText == '' then
		highlight = true
	end
	if self.linesRendered < self.renderLimit then
		add = true
	end
	if ((not starting) or (not ending)) then
		if not add then return end
		self.linesRendered = self.linesRendered + 1
		local highlightTable
		if highlight then
			highlightTable = self.highlightingFunction(self.currentPromptText,
			line)
		end
		self.currentLineNumber = 1
		vim.schedule(function()
			self.list:appendLine(line)
			self:select(1)
			if highlight then
				for _, col in pairs(highlightTable) do
					api.nvim_buf_add_highlight(self.list.buffer, identifier,
					"Identifier", highlightLine, col - 1, col)
				end
			end
		end)
		return
	end
	if starting >= self.renderLimit then
		return
	end
	if add then
		self.linesRendered = self.linesRendered + 1
	end
	local highlightTable =
	self.highlightingFunction(self.currentPromptText, line)
	self.currentLineNumber = 1
	vim.schedule(function()
		if not add then
			self.list:clearLast()
		end
		self.list:addLine(line, starting, ending)
		self:select(1)
		for _, col in pairs(highlightTable) do
			api.nvim_buf_add_highlight(self.list.buffer, identifier,
			"Identifier", highlightLine, col - 1, col)
		end
	end)
end

function M:clear()
	self.linesRendered = 0
	self.action:select(nil, nil)
	vim.schedule(function()
		self.list:clear()
	end)
end

return M