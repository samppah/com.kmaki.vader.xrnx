----------------------------------------------------
--
-- vader 0.1
--
-- (V)ery (AD)vanced (E)diting in (R)enoise
--
-- or a command line for pattern edits in renoise
--
-- created by Samppa Hannikainen (KMaki)
--
----------------------------------------------------
--
-- main.lua
--
----------------------------------------------------
-- file created         05-Jan-2012



----------------------------------------------------
-- Create tool info variables
----------------------------------------------------
-- Read from the manifest.xml file.
class "RenoiseScriptingTool" (renoise.Document.DocumentNode)
function RenoiseScriptingTool:__init()    
    renoise.Document.DocumentNode.__init(self) 
    self:add_property("Name", "Untitled Tool")
    self:add_property("Id", "Unknown Id")
    self:add_property("Version", "Unknown Version")
end

-- Set values at Global declarations, initializations
local manifest = RenoiseScriptingTool()
local ok,err = manifest:load_from("manifest.xml")

----------------------------------------------------
-- Globals declaration, initialization
----------------------------------------------------

-- renoise.song() placeholder
local rs

-- link_rs() -function placeholder
local link_rs

function get_rs()
    -- This can be called by submodules to get the
    -- renoise.song() -reference, to be set later
    return rs
end

-- Tool global root node (everything under vader will be 'global')
local vader = table.create()

-- Lexicon main table
vader.lex = table.create()

-- Macros main table
vader.macro_shortcuts = table.create()

-- Scripting Tool Preferences (preferences.xml)
vader.preferences = renoise.Document.create("ScriptingToolPreferences") {
    dummy = "dummy"
}

-- GUI placeholders
vader.dialog_cmd = nil
vader.dialog_devtest = nil

-- Global viewbuilder reference
vader.vb = renoise.ViewBuilder()

-- Global displays reference
vader.displays = table.create()

-- Main notifier table
vader.notifiers = table.create()

-- Main logs table
vader.logs = table.create() -- Main log placeholder. This collects all sublogs.
do
    vader.logs.main = nil
    -- Command line history (log) placeholder
    vader.logs.history = nil
    -- The main output
    vader.logs.out = nil
    -- Main debug log placeholder
    vader.logs.debug = nil
    -- Active task log placeholder
    vader.logs.active_task = nil
end

-- Main processing cursor placeholder
vader.cursor = nil

----------------------------------------------------
-- Constants, options, flags, et cetera
----------------------------------------------------
-- Tool info
vader.TOOL_NAME = manifest:property("Name").value
vader.TOOL_ID = manifest:property("Id").value
vader.TOOL_VERSION = manifest:property("Version").value

-- Internal / Technical
vader.LOOP_SAFETY_LIMIT = 10 -- Iteration max count for while loops to prevent lockups
vader.NIL_PLACEHOLDER_IN_TABLES = "NIL_PLACEHOLDER_IN_TABLES" --Workaround for a specific Lua issue

-- Debug options
vader.DEBUG_MODE = true --a general "Debug mode is on" -flag
vader.DEBUG_CRITICAL_ERROR = true --a global flag for error handling
vader.DEBUG_UNHANDLED_ERROR = true --a global flag for error handling
vader.DEBUG_BREAK_ON_CRITICAL_ERRORS = false --a global switch to go 'full stop' on critical vader errors
vader.DEBUG_BREAK_ON_UNHANDLED_ERRORS = true --a global switch to go 'full stop' on native Lua (unexpected) errors
vader.DEBUG_DEV_TEST = false --a global flag for separating messages from the devtes gui from normal messages

-- Keybind names
vader.KEYBIND_NAME_OPEN_CMD_PROMPT = "Open command prompt"
vader.KEYBIND_NAME_OPEN_MACRO_PROMPT = "Open macro prompt"
vader.KEYBIND_NAME_REPEAT_LAST = "Repeat history item 1"
vader.KEYBIND_NAME_REPEAT_LAST2 = "Repeat history item 2"

-- Logging
vader.LOG_DEFAULT_SEPARATOR = " - "
vader.LOG_INIT_VERBOSITY = 10 -- Verbosity level of log initialization messages
vader.LOG_DEFAULT_MAX_LEN = 999 -- Default max number of items per log (can be temporarily over this)

-- History
vader.START_OF_HISTORY_TEXT = ""
vader.END_OF_HISTORY_TEXT = "^^^^^^^^^^^^^^^^^^^^^^^^^^^^"

-- Prompt
vader.PROMPT_MODE_EDIT = ">>>"
vader.PROMPT_MODE_BROWSE = ""

-- GUI
vader.PROMPT_TOTAL_WIDTH = 330
vader.PROMPT_MODE_WIDTH = 30
vader.PROMPT_HOME_DUMP_HEIGHT = 200
vader.PROMPT_HOME_DUMP_ITEMS = 5 --number of items kept in home dump
vader.PROMPT_CLOSE_AFTER_FINISH = true

-- Displays
vader.DEFAULT_DISPLAY = "no_display"
vader.STATUSBAR_ACT_STRING = nil-- This updates on each display, alternating between the table values
vader.STATUSBAR_ACT_STRING_TABLE = {
    "...",
    ":..",
    ".:.",
    "..:",
}
--[[
The reason to have this alternating "ACT_STRING", is to have a way to
notify user if (s)he enters the exact same command, which would output
the exact same status message.
--]]

-- Output
vader.OUTPUT_NUMBER_FORMAT = "hif"
vader.OUTPUT_DEFAULT_NUMBER_FORMAT = "i"

--[[
OUTPUT NUMBER FORMAT is a string that defines the
main output number format. The three choices are
integer, float, and hex. Any starting letter of
the choices (i)nteger, (h)ex, or (f)loat will make
that a part of the output. All can be used at the same time.
The order is assigned by the ordering of the i f h -letters.
--]]

-- Parsing
function update_statusbar_message_prefix()
    -- This is 'live' so it must be wrapped into an update function.
    vader.STATUSBAR_MESSAGE_PREFIX = vader.TOOL_NAME.." "..vader.STATUSBAR_ACT_STRING.." "
end

-- Processing
vader.PROCESS_MOVE_CURSOR = true --move renoise cursor when processing
vader.PROCESS_IGNORE_WRONG_COLTYPE = true --describes how processing behaves on note&effect columns and 'current' value.
--[[
When PROCESS_IGNORE_WRONG_COLTYPE == true, trying to access current column data
with the wrong type of subcolumn data (e.g. try to access current effect column data
when cursor is on note column) will just silently ignore the request.
When it is set false, the cursor will try to jump into the first available
column of the right type, and complete the request. If no such columns are available
in the current track, request will be silently ignored.
--]]
vader.PROCESS_MAKE_SELECTION = false --make a pattern selection over the target area
vader.PROCESS_MAKE_LOOP = false --set loop start, end, over the target lines area

----------------------------------------------------
-- Error handling
----------------------------------------------------
vader.ERROR_UNDEFINED_MESSAGE = "NOOOOooooooo!"

function vader_error(error_msg, is_syntax_error)
    --[[
    Raises an handled error to be handled by directives_dispatch()
    (directives_dispatch is wrapped in a protected call for this)
    is_syntax_error is a boolean that describes
    the situation of a 'syntax_error' type of thing.
    --]]

    -- Default values
    error_msg = error_msg or vader.ERROR_UNDEFINED_MESSAGE
    -----------------
    -- Check if it's tool internal
    if is_syntax_error == true then
        -- It's just a syntax error, set flag
        vader.DEBUG_CRITICAL_ERROR = false
    end
    -- Set handled flag
    vader.DEBUG_UNHANDLED_ERROR = false
    -- Fire the error
    error(error_msg, 2)
end

function vader_assert(condition, error_msg, is_syntax_error)
    --[[
    see vader_error for description
    --]]
    -- Default values
    condition = condition or false --just to prove a point
    error_msg = error_msg or vader.ERROR_UNDEFINED_MESSAGE
    -----------------
    -- Do assert
    if not condition then
        -- Check if it's tool internal
        if is_syntax_error == true then
            -- It's just a syntax error, set flag
            vader.DEBUG_CRITICAL_ERROR = false
        end
        -- Set handled flag
        vader.DEBUG_UNHANDLED_ERROR = false
        -- Fire the error
        error(error_msg, 2)
    end
end

function not_implemented(feature)
    --[[
    A helper/shorthand to inform user that the feature (s)he tried
    to access is not implemented yet
    --]]
    vader_error("NOT IMPLEMENTED YET: "..feature, true)
end

----------------------------------------------------
-- File dependencies
----------------------------------------------------
function get_tool_root_node()
    -- This function serves the submodules
    -- Pass vader reference
    return vader
end

require "classes"
require "output"
require "gui"
require "macro"
require "lexicon"
require "parser"
require "grammar"
require "process"

----------------------------------------------------
-- Global helper functions
----------------------------------------------------
--TODO: a file for these. plz?

function sleep(time_ms)
    --[[
    Waits for time_ms milliseconds, then returns
    --]]
    --TODO: THIS THING IS NOT WORKING. IT HANGS EVERYTHING!
    vader.logs.active_task:entry("Sleep")
    
    local sleeping = true
    local leave

    leave = function()
        sleeping = false
        if renoise.tool():has_timer(leave) then
            renoise.tool():remove_timer(leave)
        end
    end

    --setup
    if not renoise.tool():has_timer(leave) then
        renoise.tool():add_timer(leave, time_ms)
    end

    --sleep
    while sleeping == true do --NOTE:tried a fix here 8.3.2014
        --nothing
    end

    --that's it
    vader.logs.active_task:entry("Sleep over")
    return
end

function build_notifier(observable, function_to_attach, notifier_table)
    -- Wraps native add_notifier() in if :has_notifier
    if not observable:has_notifier(function_to_attach) then
        observable:add_notifier(function_to_attach) 
    end
    -- Add to notifier table
    -- TODO
    if notifier_table then
        --Remove
    end
end

function clear_notifier(observable, function_to_clear, notifier_table)
    -- Wraps native remove_notifier() in if :has_notifier
    if observable:has_notifier(function_to_attach) then
        observable:remove_notifier(function_to_attach) 
    end
    -- Remove from notifier table
    -- TODO
    if notifier_table then
        -- Remove
    end
end

function build_all_notifiers(notifier_table)
    -- Batch calls build notifier(), takes as argument
    -- a table of form:
    -- [1] = {observable_1, function_to_attach_1}
    -- [2] = {observable_2, function_to_attach_2}
    -- etc..
    -- TODO
end

function clear_all_notifiers(notifier_table)
    -- Batch calls clear notifier(), takes as argument
    -- a table of form:
    -- [1] = {observable_1, function_to_clear_1}
    -- [2] = {observable_2, function_to_clear_2}
    -- etc..
    -- TODO
end

----------------------------------------------------
-- Main functions
----------------------------------------------------

local function directives_dispatch()
    --[[
    The main program flow handler function. Every parsing, processing action is
    dispatched through this.  Functions so that vader.directives -list is
    filled, and directives_trigger() is called.  That will start the process of
    emptying the list to the point of no directives left.
    --]]

    --vader.logs.debug:entry("Dispatching...", 1)

    -- Error catching
    -- NOTE:no error catching yet
    ----------
    local continue_loop = Switch()
    local safety_counter = Counter()

    -------------------------------------------
    -- Local helper functions
    -------------------------------------------
    local function handle_error(error_msg)
        --[[
        This handles errors catched in the dispatcher calls
        vader.DEBUG_CRITICAL_ERROR and vader.DEBUG_UNHANDLED_ERROR are assumed
        to be set on their right states
        --]]
        
        -- Add last history item
        error_msg = vader.logs.history:item(1).string.."\n"..error_msg

        -- Add call traceback on criticals
        if vader.DEBUG_CRITICAL_ERROR == true then
            -- Edit msg
            error_msg = "CRITICAL ERROR!\n\n"..error_msg.. "\n\n" .. debug.traceback()
            if vader.DEBUG_UNHANDLED_ERROR == true then
                -- Edit msg
                error_msg = "AN UNHANDLED "..error_msg
            end
        else
            --Edit msg
            error_msg = "syntax error\n\n"..error_msg
        end

  -- Add message to active_task log, and display it according to log display settings
  vader.logs.active_task:entry(error_msg)
  -- Add message to error log, and display it according to log display settings
  vader.logs.errors:entry(error_msg)

    end


    -------------------------------------------
    -- THE MAIN DISPATCHER LOOP
    -------------------------------------------
    -- Get the message that starts the parse-process snowball
    local input = vader.logs.history:bottom().string
    local output = ""
    while (#vader.directives > 0) and continue_loop.state and safety_counter.count < vader.LOOP_SAFETY_LIMIT do
        --[[
        This while loop will run until all the directives (including those that
        have been added by other directives) run out, or the safety counter
        reaches vader.LOOP_SAFETY_LIMIT
        --]]
        
        -- Add round count
        safety_counter:inc()

        -- Get the next directive
        local directive = vader.directives:top()
        local directive_index = vader.directives:top_index()
        vader.logs.main:entry(directive_index..":"..directive.name, 0)
        local task_function = vader.lex.directives[directive.name]

        -- log GO!
        directive:activate()

        -- GO!
        --Call task_function(directive) in protected mode, store results in AStack object
        local directive_call = function() return task_function(directive) end
        local return_values = AQueue("return_values", { xpcall(directive_call, handle_error) }, true ) --NOTE:true is for is_sparse argument in AList:__init()
        --Check for directive_call success, which will be the first, discardable return value
        if return_values:pop() ~= false then
            --[[
            CASE: Function exited with no errors, deal with it
            --]]
            -- Handle the directive object
            vader.directives:finish_and_remove()
            -- Handle log
            vader.logs.main:entry("DIRECTIVE "..directive_index.."/"..#vader.directives..":"..directive.name..vader.LOG_DEFAULT_SEPARATOR.."Finished.", 0)
            --[[
            --NOTE:This commented section is outdated!
            -- If there are remarks, publish them in logs
            if notes then
                -- Publish notes
                for _, note in ipairs(notes) do
                    vader.logs.main:entry(note)
                end
            end
            --]]
            
            -- Reset flags for default, for following errors
            vader.DEBUG_CRITICAL_ERROR = true
            vader.DEBUG_UNHANDLED_ERROR = true
            vader.DEBUG_DEV_TEST = false
        else
            --[[
            CASE: Function exited with an error
            handle errors by type, pass error message,
            which will be return value 2
            --]]
            
            -- Check for a critical error
            --[[
            A critical error is not a 'vader syntax error'.
            This means that it's something internal that has
            gone wrong, and the error is not a bad input.
            Critical is something that is caught with
            vader_error() or vader_assert().
            --]]
            if vader.DEBUG_CRITICAL_ERROR then
                vader.logs.main:entry("CRITICAL ERROR")
                -- Check if execution is to be stopped on criticals
                if vader.DEBUG_BREAK_ON_CRITICAL_ERRORS then
                    vader.logs.main:entry("BREAK")
                    --throw Lua error
                    error(return_values:pop())
                end
            end

            -- Check for unhandled errors
            --[[
            An unhandled error is something that was not caught
            with a vader_error() or vader_assert(). In other words,
            something is now found to be very wrong with vader code.
            --]]
            if vader.DEBUG_UNHANDLED_ERROR then
                vader.logs.main:entry("UNHANDLED ERROR")
                -- Check if execution is to be stopped on unhandled errors
                if vader.DEBUG_BREAK_ON_UNHANDLED_ERRORS then
                    vader.logs.main:entry("BREAK")
                    --throw Lua error
                    error(return_values:pop())
                end
            end

            -- After handling, reset error type flags for default for following errors
            vader.DEBUG_CRITICAL_ERROR = true
            vader.DEBUG_UNHANDLED_ERROR = true
            vader.DEBUG_DEV_TEST = false

            --Exit dispatching loop, clear directives list
            vader.directives:clear()
            continue_loop:off()
            break

        end
        
        -- Store latest return value as the output
        output = return_values:item(1)
        
    end
    -- Directives -list has now been cleared (or then it's a case of endless recursion)
    
    --Check if exited because of endless recursion
    if safety_counter.count == vader.LOOP_SAFETY_LIMIT then
        --something's gone wrong
        local errormessage = "ENDLESS RECURSION, perchance?"
        vader.logs.errors:entry(errormessage)
    end

    -- Set processing cursor back to nil
    -- vader.cursor = nil

    -- Reset error type flags for default for following errors
    vader.DEBUG_CRITICAL_ERROR = true
    vader.DEBUG_UNHANDLED_ERROR = true
    vader.DEBUG_DEV_TEST = false

    -- Adjust logs to max length
    for _, log in pairs(vader.logs) do
        log:adjust()
    end

    -- Generate output value
    -- placeholder for number output format
    if type(output) == "boolean" then
        --[[
        CASE: command output type is a boolean
        --]]
        
        if output == true then
            output = "." --TODO: an option and default string for this type output, just as ACT_STRING
        else
            --NOTE: this should never happen. Commands exited with false should be catched by error handling.
            output = "Command output was false - something is wrong"
        end

    elseif type(output) == "number" then
        --[[
        CASE: command output type is a number
        --]]

        --TODO: this can be optimized by getting this out of here,
        --and only generating the formatstring when it changes (if it changes)
        local format_code = vader.OUTPUT_NUMBER_FORMAT or vader.OUTPUT_DEFAULT_NUMBER_FORMAT
        local number_formatstring = ""
        local formatstring_args = table.create()

        local at = Counter()
        while at.count <= #format_code do
            if #number_formatstring > 0 then
                number_formatstring = number_formatstring..vader.LOG_DEFAULT_SEPARATOR
            end
            local letter = string.sub(format_code, at.count, at.count)
            if letter == "i" then
                number_formatstring = number_formatstring.."%i"
            elseif letter == "f" then
                number_formatstring = number_formatstring.."%.2f"
            elseif letter == "h" then
                number_formatstring = number_formatstring.."%2X"
            end
            -- Add to the string.format argument table
            formatstring_args:insert(output)
            -- go over if chars still left
            at:inc()
        end

        output = string.format(number_formatstring, unpack(formatstring_args))

    else
        --[[
        CASE: command output is not handled
            -Nil
            -String
            -Table
            -Any object
            -etc.
        --]]

        output = "," --TODO: an option and default string for this type output, just as ACT_STRING

    end

    -- Output main out message
    local entryformat = "%s  -->  %s"
    vader.logs.out:entry(string.format(entryformat, input, output))

    -- Close dialog when such option set
    if vader.PROMPT_CLOSE_AFTER_FINISH then
        close_dialog_cmd()
    end


end

function directives_trigger()
    --[[
    This is called by a VaderDirectiveList -object when
    a directive is added into its list with no "hold_boolean"
    value

    This further evaluates need to dispatch
    --]]

    if #vader.directives == 0 then
        -- false alarm (log this?) TODO
        return false
    else
        directives_dispatch()
    end
end

----------------------------------------------------
-- Boot procedure
----------------------------------------------------

-- Terminal start message
print(string.format("%s %3.2f - Command line for renoise. Initialized at %s", vader.TOOL_NAME, vader.TOOL_VERSION, os.date()))



local function boot_submodules(global_root_node)
    --[[
    Each submodule has a global "boot_<submodule_name>" -function
    that has to do stuff at tool boot.
    --]]
    boot_gui(global_root_node)
    boot_output(global_root_node)
    boot_classes(global_root_node)
    boot_parser(global_root_node)
    boot_lexicon(global_root_node)
    boot_grammar(global_root_node)
    boot_process(global_root_node)
    boot_macro(global_root_node)
end

--Init submodules
boot_submodules(vader)

--Init displays
init_displays()

--Build command prompt GUI
build_cmd_prompt_gui()

-- Setup notifier to handle renoise.song() -pointer
link_rs = function()
    rs=renoise.song()
    boot_submodules(vader)
    -- Init vader.cursor
    vader.cursor = VaderCursor()
end

build_notifier(renoise.tool().app_new_document_observable, link_rs)

--------------
-- Create logs
--------------

-- Main log
vader.logs.main = ALog("Main Log", vader.displays.home_dump, 0)

-- Main out.
vader.logs.out = ALog("Main output", vader.displays.statusbar, 0, 1)

-- Debug log
local dbgoutput
if vader.DEBUG_MODE == true then
    dbgoutput = vader.displays.terminal 
else
    dbgoutput = vader.displays.no_display
end
vader.logs.debug = ALog("Debug Log", dbgoutput, 100)

-- Active_task log
vader.logs.active_task = ALog("active_task", vader.displays.no_display, 3)

-- Warnings log
vader.logs.warnings = ALog("Warnings Log", vader.displays.warning_dlg, 0)

-- Errors log
vader.logs.errors = ALog("Errors Log", vader.displays.error_dlg, 0)

-- Command line history 
vader.logs.history = ALog("Command line history", vader.displays.no_display, 0)
vader.logs.history:pop() --remove the log init entry
vader.logs.history:entry(vader.END_OF_HISTORY_TEXT, 0)

--Echo the active_task log in debug_log
vader.logs.active_task:add_distribute_log(vader.logs.debug)
-- Echo all relevant sublogs in main log
vader.logs.errors:add_distribute_log(vader.logs.main)
vader.logs.out:add_distribute_log(vader.logs.main)
--vader.logs.debug:add_distribute_log(vader.logs.main)

-- Startup submodule logs
local function init_submodule_logs(global_root_node)
    init_parse_log(global_root_node)
    init_process_log(global_root_node)
    init_method_log(global_root_node)
    init_macro_log(global_root_node)
end
init_submodule_logs(vader)


-- Persistent prompt settings, global node
-- TODO:Find out what the hex this was..


-- Main process flags
vader.flags = renoise.Document.create("Main_flags") {
    -- Note: the pending_toggle-"flag" is a TOGGLE. 
    ["pending_toggle"] = false
}
--build_notifier(vader.flags.pending_toggle, directives_trigger)

-- Init main process list for program control flow
vader.directives = VaderDirectiveList("Main_directive_list")


----------------------------------------------------
-- Setup tool Keybindings
----------------------------------------------------

renoise.tool():add_keybinding {
    name = "Global:" ..vader.TOOL_NAME..":"..vader.KEYBIND_NAME_OPEN_CMD_PROMPT.."...",
    invoke = show_cmd_prompt
}

renoise.tool():add_keybinding {
    name = "Global:" ..vader.TOOL_NAME..":"..vader.KEYBIND_NAME_OPEN_MACRO_PROMPT.."...",
    invoke = show_macro_prompt
}

renoise.tool():add_keybinding {
    name = "Global:" .. vader.TOOL_NAME..":"..vader.KEYBIND_NAME_REPEAT_LAST,
    invoke = function()
        local last_msg = vader.logs.history:bottom().string
        if #vader.logs.history > 1 and last_msg and #last_msg > 0 then
            -- Put input in main log
            local new_log_entry = vader.logs.main:entry(vader.KEYBIND_NAME_REPEAT_LAST..":"..last_msg)
            -- Show in history log display, (don't actually put in history)
            vader.logs.history.target_display:show(vader.KEYBIND_NAME_REPEAT_LAST..":"..last_msg)
            -- Add to Directives for parsing
            local parse_directive = VaderDirective("PARSE", new_log_entry)
            parse_directive:new_argument(last_msg)
            vader.directives:entry(parse_directive)
        end
    end
}

renoise.tool():add_keybinding {
    name = "Global:" .. vader.TOOL_NAME..":"..vader.KEYBIND_NAME_REPEAT_LAST2,
    invoke = function()
        local last_msg = vader.logs.history:item(vader.logs.history:bottom_index()+1).string
        if #vader.logs.history > 2 and last_msg and #last_msg > 0 then
            -- Put input in main log
            local new_log_entry = vader.logs.main:entry(vader.KEYBIND_NAME_REPEAT_LAST2..":"..last_msg)
            -- Show in history log display, (don't actually put in history)
            vader.logs.history.target_display:show(vader.KEYBIND_NAME_REPEAT_LAST2..":"..last_msg)
            -- Add to Directives for parsing
            local parse_directive = VaderDirective("PARSE", new_log_entry)
            parse_directive:new_argument(last_msg)
            vader.directives:entry(parse_directive)
        end
    end
}

renoise.tool():add_keybinding {
    name = "Global:" .. vader.TOOL_NAME..":".."debug- update and dump vader.cursor",
    invoke = function ()
        if vader.cursor then
            vader.cursor:get_all()
            vader.cursor:dump()
        else
            print("no vader.cursor available")
        end

    end
}

--[[
renoise.tool():add_keybinding {
    name = "Global:Tools:" .. tool_name.." - Macro hotkey 1",
    invoke = show_dialog
}
renoise.tool():add_keybinding {
    name = "Global:Tools:" .. tool_name.." - Macro hotkey 2",
    invoke = show_dialog
}
renoise.tool():add_keybinding {
    name = "Global:Tools:" .. tool_name.." - Macro hotkey 3",
    invoke = show_dialog
}
renoise.tool():add_keybinding {
    name = "Global:Tools:" .. tool_name.." - Macro hotkey 4",
    invoke = show_dialog
}
renoise.tool():add_keybinding {
    name = "Global:Tools:" .. tool_name.." - Macro hotkey 5",
    invoke = show_dialog
}
]]--


----------------------------------------------------
-- Preferences
----------------------------------------------------

renoise.tool().preferences = vader.preferences



if vader.DEBUG_MODE then
    require "developer_test"
end


-- Reload the script whenever this file is saved. 
-- Additionally, execute the attached function.
_AUTO_RELOAD_DEBUG = function()
    link_rs()
end
