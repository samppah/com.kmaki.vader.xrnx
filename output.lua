--
--output.lua
--
------------------------------------------
-- file created         08-Jan-2012
--
-- last modification    19-Feb-2012
--

-- Output functions
-- These handle directing a string into
-- home dump
-- terminal
-- command-line
-- native modal dialogs
-- file?

------------------------------------------
-- Globals declaration, initialization
------------------------------------------
-- Project wide globals (local representation)
local vader
local vb

------------------------------------------
-- Boot procedure, initialization
------------------------------------------

function boot_output(main_vader)
    -- Project Globals
    vader = main_vader
    vb = vader.vb
end


------------------------------------------
-- Display functions
------------------------------------------

-- No display 'display function'
function no_display_display_function(display_string)
    --dummy
end

-- Home dump display function
function home_dump_display_function(display_string)
    -- Will be registered as ADisplay.display_function
    -- TODO: SPEED THIS UP. THIS IS A COMPLETE SLOTH!
    -- TODO: FIX SUGGESTION: REGISTER AS MULTILINE DISPLAY, IMPLEMENT MULTILINE SHOW
    -- Create text
    local final_text = ARevStack("final_text")
    -- Add display_string
    final_text:push(display_string)
    -- Add current text
    for i = 1, math.min(#vb.views.home_dump_id.paragraphs, vader.PROMPT_HOME_DUMP_ITEMS) do
        if vb.views.home_dump_id.paragraphs[i] then
            final_text:push(vb.views.home_dump_id.paragraphs[i])
        end
    end
    -- update vb-view
    vb.views.home_dump_id.paragraphs = final_text.items
    --vb.views.home_dump_id.visible = false
end
function home_dump_multiline_display_function(display_table)
    -- Create text
    local final_text = ARevStack("final_text")
    -- Add display_table strings
    local text_items = Counter()
    for _, item in ipairs(display_table) do
        final_text:push(item)
        text_items:inc()
        if text_items.count == vader.PROMPT_HOME_DUMP_ITEMS then
            --home dump is full
            break
        end
    end
    if text_items < vader.PROMPT_HOME_DUMP_ITEMS then
        -- Add current text
        local current_text = vb.views_home_dump_id.paragraphs
        for i = 1, math.min(#current_text - text_items.count, vader.PROMPT_HOME_DUMP_ITEMS - text_items.count) do
            if current_text[i] then
                final_text:push(current_text[i])
            end
        end
    end
    -- update vb-view
    vb.views.home_dump_id.paragraphs = final_text.items
end

-- Statusbar display function
function statusbar_display_function(display_string)
    -- Will be registered as ADisplay.display_function
    --update ACT_STRING
    -- Get current index
    local act_string_index
    if vader.STATUSBAR_ACT_STRING == nil then
        act_string_index = 0
    else
        act_string_index = table.find(vader.STATUSBAR_ACT_STRING_TABLE, vader.STATUSBAR_ACT_STRING)
    end
    -- Set new index
    if act_string_index < #vader.STATUSBAR_ACT_STRING_TABLE then
        act_string_index = act_string_index + 1
    else
        act_string_index = 1
    end
    -- Set new string
    vader.STATUSBAR_ACT_STRING = vader.STATUSBAR_ACT_STRING_TABLE[act_string_index]

    --[[
    if vader.STATUSBAR_ACT_STRING ~= vader.STATUSBAR_ACT_STRING_1 then
        vader.STATUSBAR_ACT_STRING = vader.STATUSBAR_ACT_STRING_1
    else
        vader.STATUSBAR_ACT_STRING = vader.STATUSBAR_ACT_STRING_2
    end
    --]]
    
    update_statusbar_message_prefix()
    --display
    renoise.app():show_status(vader.STATUSBAR_MESSAGE_PREFIX..display_string)
end

-- Terminal display function
function terminal_display_function(display_string)
    -- Will be registered as ADisplay.display_function
    print(display_string)
end

-- Command-line display function
function cmd_line_display_function(display_string)
    -- Will be registered as ADisplay.display_function
    set_cmd_line_text(display_string)
end

-- Display functions for renoise native dialogs
function error_dlg_display_function(display_string)
    -- Will be registered as ADisplay.display_function
    renoise.app():show_error(vader.TOOL_NAME.." error\n\n"..display_string)
end
function msg_dlg_display_function(display_string)
    -- Will be registered as ADisplay.display_function
    renoise.app():show_message(vader.TOOL_NAME.." message\n\n"..display_string)
end
function warning_dlg_display_function(display_string)
    -- Will be registered as ADisplay.display_function
    renoise.app():show_warning(vader.TOOL_NAME.." warning\n\n"..display_string)
end

-- Lua error display function
function lua_error_display_function(display_string)
    -- Will be registered as ADisplay.display_function
    error(display_string)
end

------------------------------------------
-- Create, register displays
------------------------------------------

function init_displays()
    -- Create display objects
    local no_display_display_object = ADisplay("no_display_display", no_display_display_function, false)
    local home_dump_display_object = ADisplay("home_dump_display", home_dump_display_function, true, home_dump_multiline_display_function)
    local terminal_display_object = ADisplay("terminal_display", terminal_display_function, false)
    local statusbar_display_object = ADisplay("statusbar_display", statusbar_display_function, false)
    local cmd_line_display_object = ADisplay("cmd_line_display", cmd_line_display_function, false)
    local error_dlg_display_object = ADisplay("error_dlg_display", error_dlg_display_function, false)
    local msg_dlg_display_object = ADisplay("msg_dlg_display", msg_dlg_display_function, false)
    local warning_dlg_display_object = ADisplay("warning_dlg_display", warning_dlg_display_function, false)
    local lua_error_display_object = ADisplay("lua_error_display", lua_error_display_function, false)

    -- Register displays
    vader.displays.no_display = no_display_display_object
    vader.displays.home_dump = home_dump_display_object
    vader.displays.terminal = terminal_display_object
    vader.displays.statusbar = statusbar_display_object
    vader.displays.cmd_line = cmd_line_display_object
    vader.displays.error_dlg = error_dlg_display_object
    vader.displays.msg_dlg = msg_dlg_display_object
    vader.displays.warning_dlg = warning_dlg_display_object
    vader.displays.lua_error = lua_error_display_object
end
