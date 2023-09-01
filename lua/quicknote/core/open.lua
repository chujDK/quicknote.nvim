local path = require("plenary.path")
local utils = require("quicknote.utils")

local M = {}

-- check if note file exist, if exists, open it
local checkAndOpenNoteFile = function(noteFilePath)
    vim.loop.fs_stat(noteFilePath, function(err, _)
        if err then
            print("Note not found.")
        else
            -- open note file
            -- use vim.defer_fn to avoid "can not call nvim exec in vim loop event"
            vim.defer_fn(function()
                vim.cmd("split " .. noteFilePath)
            end, 0)
        end
    end)
end

local openFloatingWindow = function()
    local buf = vim.api.nvim_create_buf(false, true)

    vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

    local width = vim.api.nvim_get_option("columns")
    local height = vim.api.nvim_get_option("lines")

    local win_height = math.ceil(height * 0.8 - 4)
    local win_width = math.ceil(width * 0.8)

    local row = math.ceil((height - win_height) / 2 - 1)
    local col = math.ceil((width - win_width) / 2)

    local opts = {
        style = "minimal",
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col,
        border = "rounded",
    }

    local win = vim.api.nvim_open_win(buf, true, opts)
    vim.api.nvim_win_set_option(win, "cursorline", true)

    return buf, win
end

-- get note file path of a given line for the current buffer
local getNotePathAtLine = function(line)
    local noteDirPath = utils.path.getNoteDirPathForCurrentBuffer()
    return path:new(noteDirPath, line .. "." .. utils.config.GetFileType()).filename
end

local OpenNoteAtCurrentLineInFloatingWindow = function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local noteFilePath = getNotePathAtLine(line)

    vim.loop.fs_stat(noteFilePath, function(err, _)
        if err then
            print("Note not found.")
        else
            local buf, win = openFloatingWindow()
            vim.api.nvim_buf_set_option(buf, "modifiable", true)
            vim.api.nvim_command("$read" .. noteFilePath)
            vim.api.nvim_buf_set_option(0, "modifiable", false)
        end
    end)
end
M.OpenNoteAtCurrentLineInFloatingWindow = OpenNoteAtCurrentLineInFloatingWindow


-- Open an already existed note at a given line for the current buffer
-- @param line: line number
local OpenNoteAtLine = function(line)
    -- check if note file exist
    local noteFilePath = getNotePathAtLine(line)
    checkAndOpenNoteFile(noteFilePath)
end
M.OpenNoteAtLine = OpenNoteAtLine

-- Open an already existed note at current cursor line for current buffer
local OpenNoteAtCurrentLine = function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    OpenNoteAtLine(line)
end
M.OpenNoteAtCurrentLine = OpenNoteAtCurrentLine

-- Open an already existed note at global
local OpenNoteAtGlobal = function()
    -- get file name from user input
    local fileName = vim.fn.input("Enter note name: ")

    -- get note dir path
    local noteDirPath = utils.path.getNoteDirPathForGlobal()

    -- get note file path
    local noteFilePath = path:new(noteDirPath, fileName .. "." .. utils.config.GetFileType()).filename

    -- check if note file exist
    checkAndOpenNoteFile(noteFilePath)
end
M.OpenNoteAtGlobal = function()
    if utils.config.GetMode() ~= "resident" then
        print("Open note globally just works in resident mode")
        return
    end
    OpenNoteAtGlobal()
end

-- Open an already existed note at CWD
local OpenNoteAtCWD = function()
    -- get file name from user input
    local fileName = vim.fn.input("Enter note name: ")

    -- get note dir path
    local noteDirPath = utils.path.getNoteDirPathForCWD()

    -- get note file path
    local noteFilePath = path:new(noteDirPath, fileName .. "." .. utils.config.GetFileType()).filename

    -- check if note file exist
    checkAndOpenNoteFile(noteFilePath)
end
M.OpenNoteAtCWD = OpenNoteAtCWD

return M
