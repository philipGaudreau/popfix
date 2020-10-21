local previewPopup = require'popfix.preview_popup'
local popup = require'popfix.popup'
local M = {}

local currentInstance = nil

function M.open(opts)
	if currentInstance ~= nil then
		if not currentInstance.closed then return false end
		currentInstance = nil
	end
	if opts.mode == nil then
		print('Provide a mode attribute')
		return false
	end
	if opts.mode == 'editor' then
	elseif opts.mode == 'cursor' then
	elseif opts.mode == 'split' then
	else
		print('Note a valid mode')
		return false
	end
	if opts.list == nil then
		print('List attribute is necessary')
		return false
	end
	if opts.preview then
		currentInstance = previewPopup
		if opts.keymaps then
			for key,value in opts.keymaps do
				if value == 'close-selected' or 'close-cancelled' then
					opts.keymaps[key] = currentInstance.getFunction(value)
				end
			end
		end
		M.closed = true
		if not previewPopup.popup(opts) then
			currentInstance = nil
		end
	else
		currentInstance = popup
		if opts.default_keymaps then
			for key,value in opts.default_keymaps do
				if value == 'close-selected' or 'close-cancelled' then
					opts.default_keymaps[key] = currentInstance.getFunction(value)
				end
			end
		end
		M.closed = true
		if not popup.popup(opts) then
			currentInstance = nil
		end
	end
	return true
end


return M
