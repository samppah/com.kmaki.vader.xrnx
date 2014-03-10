--
-- macro.lua
--
------------------------------------------
-- file created         15-Jul-2012

-- Code for handling user macros
--
-- dialog_cmd - the main command line dialog.
-- Receives user input, passes to main.lua

------------------------------------------
-- Globals declaration, initialization
------------------------------------------

-- Project wide globals (local representation)
local vader
-- renoise.ViewBuilder() placeholder
local vb
-- Logging placeholder
local macro_log


------------------------------------------
-- Boot procedure, initialization
------------------------------------------

function boot_macro(main_vader)
    -- Project Globals
    vader = main_vader
    vb = vader.vb
end

function init_macro_log(main_vader)
    --This is called from main.lua to init this submodule log
    macro_log = ALog("macro events log", vader.displays.no_display, 0)
    macro_log:add_distribute_log(vader.logs.active_task)
end

------------------------------------------
-- Macro processing minor functions
------------------------------------------

local function is_legal_rns_shortcut(reg_title)
   --Checks that the shortcut user wishes to use is legal 
   --NAME:
   --No : -signs
   if string.find(reg_title, ":") then
       return false, "No : characters in macro names"
   end
   return true
end

local function keybind_exists(title)
    --Simple shortcut to check if bind exists
    return renoise.tool():has_keybinding("Global:" ..vader.TOOL_NAME..":"..title)
end

local function delete_keybind(title)
    --Simple shortcut to delete a bind
    renoise.tool():remove_keybinding("Global:" ..vader.TOOL_NAME..":"..title)
    vader.macro_shortcuts[title] = nil
end

local function add_user_macro(title, script)
    --This adds a shortcut under Global:vader
    -------------------------
    local add_action_string = "Adding"
    --Check if duplicate, if is, remove previous before adding
    if keybind_exists(title) then
        delete_keybind(title)
        add_action_string = "Updating"
    end
    local output = add_action_string.." macro "..title.."."
    macro_log:entry(output)
    --Add 
    renoise.tool():add_keybinding {
        name = "Global:" .. vader.TOOL_NAME..":"..title,
        invoke = function()
            local execute = script
            -- Put input in main log
            local new_log_entry = vader.logs.main:entry("(Macro) "..title..":"..execute)
            -- Enter the actual command in history
            vader.logs.history:entry(execute)
            -- Add to Directives for parsing
            local parse_directive = VaderDirective("PARSE", new_log_entry)
            parse_directive:new_argument(execute)
            vader.directives:entry(parse_directive)
        end
    }
    --Add to macro table
    vader.macro_shortcuts[title] = script
    --Add to preferences
    --TODO!
    --Log & Echo
    --vader.logs.out:entry(output)
end

------------------------------------------
-- Macro processing main functions
------------------------------------------

function remove_user_macro(title)
    -- Currently the top level function for removing
    -- This attempts to remove a user macro
    -------------------------
    if keybind_exists(title) then
        delete_keybind(title)
        local output = "Removed macro "..title.."."
        --[[
        vader.logs.main:entry(output)
        vader.logs.out:entry(output)
        --]]
        return true, output
    else
        local output = "Tried to remove macro "..title..". No such macro was found."
        --[[
        vader.logs.main:entry(output)
        vader.logs.out:entry(output)
        --]]
        vader_error(output, true)
    end
end

function register_rns_shortcut(reg_title, reg_script)
    -- Top level function for adding a bind
    -- Checks if adding is legal
    -- calls subfunctions to add bind
    -- Handles GUI 
    local reg_success, reg_error = is_legal_rns_shortcut(reg_title)
    if reg_success then
        --register shortcut
        add_user_macro(reg_title, reg_script)
        --All's well, exit
        close_dialog_macro()
        --Return
        return true, "added a macro. with directives. yeehaa"
    else
        vader_error(reg_error, true)
    end
end

------------------------------------------
-- Macro processing, functions for vader directives
------------------------------------------

function req_add_mcr(reg_title, reg_script)
    -- Adds request to add macro into directives list
    -------------------------------------------------
    -- Put input in main log
    local new_log_entry = vader.logs.main:entry(reg_title..vader.LOG_DEFAULT_SEPARATOR..reg_script)
    -- Add to Directives for parsing
    local directive = VaderDirective("MACRO_ADD", new_log_entry)
    directive:new_argument(reg_title)
    directive:new_argument(reg_script)
    vader.directives:entry(directive)
    -- TODO:check for a glob flag to close macro prompt after adding
end

function req_remove_mcr(reg_title)
    -- Adds request to remove macro into directives list
    -------------------------------------------------
    -- Put input in main log
    local new_log_entry = vader.logs.main:entry(reg_title)
    -- Add to Directives for parsing
    local directive = VaderDirective("MACRO_REMOVE", new_log_entry)
    directive:new_argument(reg_title)
    vader.directives:entry(directive)
    -- TODO:check for a glob flag to close macro prompt after removing
end
