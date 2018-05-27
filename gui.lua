--
-- gui.lua
--
------------------------------------------
-- file created         05-Jan-2012

-- Code for the various GUIs
--
-- dialog_cmd - the main command line dialog.
-- Receives user input, passes to main.lua
--
-- dialog_macro - macro editing GUI
-- Used to store/edit user macros

------------------------------------------
-- Globals declaration, initialization
------------------------------------------

-- Project wide globals (local representation)
local vader
-- renoise.ViewBuilder() placeholder
local vb
-- Command prompt dialog placeholder
local dialog_cmd
-- Command prompt dialog content placeholder
local content_cmd = nil
-- Macro prompt dialog placeholder
local dialog_macro
-- Macro prompt dialog content placeholder
local content_macro = nil
-- Macro dialog button function placeholders
local regmacro
local removemacro


-- Command prompt status monitoring values
local cmd_prompt = renoise.Document.create("cmd_prompt_values") {
    -- These are the tool bootup default values
    ["trigger_evaluated"] = true,
    ["msg"] = "", 
    ["msg_prev"] = "",
    ["mode"] = "", 
    ["history_pointer"] = 0,
    ["home_dump_visible"] = false,
}

------------------------------------------
-- Boot procedure, initialization
------------------------------------------


function boot_gui(main_vader)
    -- Project Globals
    vader = main_vader
    vb = vader.vb
    dialog_cmd = vader.dialog_cmd
    -- Update constants
    cmd_prompt.msg.value = vader.START_OF_HISTORY_TEXT
    cmd_prompt.msg.value = vader.END_OF_HISTORY_TEXT
    -- Get macro functions
    regmacro = req_add_mcr
    removemacro = req_remove_mcr
end

function update_vb()
    vb = vader.vb
end

function reset_history()
    cmd_prompt.history_pointer.value = 0
end

function close_dialog_cmd()
    if dialog_cmd and dialog_cmd.visible then
        dialog_cmd:close()
        vb = nil
    end
end

function close_dialog_macro()
    if dialog_macro and dialog_macro.visible then
        dialog_macro:close()
        vb = nil
    end
end
------------------------------------------
-- Minor functions
------------------------------------------
local function clear_cmd_prompt()
    cmd_prompt.msg.value = vader.START_OF_HISTORY_TEXT
end

local function pass_msg(msg)
    -- This happens if user interacts in such a way that
    -- a message is worth sending to parse
    --print(display_string)rint("send message to parse: '"..msg.."'") --debug
    -- Add command line history entry
    vader.logs.history:entry(msg, 0)
    -- Put input in main log
    local new_log_entry = vader.logs.main:entry(msg)
    -- Add to Directives for parsing
    local parse_directive = VaderDirective("PARSE", new_log_entry)
    parse_directive:new_argument(msg)
    vader.directives:entry(parse_directive) --add directive to list and trigger "directives_trigger()" in main
    -- Reset prompt
    clear_cmd_prompt()
end


local function update_cmd_prompt_mode(focused_boolean)
    if focused_boolean == true then
        -- Set mode to edit
        cmd_prompt.mode.value = vader.PROMPT_MODE_EDIT
    else
        -- Set mode to browse
        cmd_prompt.mode.value = vader.PROMPT_MODE_BROWSE
    end
    vb.views.mode_id.text = cmd_prompt.mode.value
end

local function evaluate(msg, msg_prev)
    -- Evaluate need to parse a message in cmd prompt
    if msg == vader.START_OF_HISTORY_TEXT then
        return false
    end
    if msg == vader.END_OF_HISTORY_TEXT then
        clear_cmd_prompt()
        return false
    end
    return true
end

local function cmd_history_trigger()
    -- This is called through the key enter_cmd_key,
    -- when user is in BROWSE-MODE.
    -- This evaluates the need to send selected message to main.
    
    -- Shorthand 
    local msg = cmd_prompt.msg.value
    local msg_prev = cmd_prompt.msg_prev.value

    -- Evaluate message
    local parse = evaluate(msg, msg_prev)
    
    if parse then
        -- Put msg into main
        pass_msg(msg)
    end
    -- Reset history pointer
    reset_history()
end

local function cmd_edit_trigger()
    -- Called constantly by an idler, when GUI is up
    -- This is used to monitor the user input
    -- and to send user edited message to main if needed
    -- 
    -- The main principle here is that IF the user
    -- exits edit_mode and the interface textfield value is unaltered,
    -- it is probably because user has exited editing with 'esc'.
    -- 
    -- IF however the textfield value has been altered
    -- WHEN THE USER EXITS EDIT_MODE, then it must be a message that
    -- the user wishes to send for parsing

    if not vb then return end

    -- Shorthand
    local focused = vb.views.prompt_id.edit_mode
    local trigger_evaluated = cmd_prompt.trigger_evaluated.value
    local msg = cmd_prompt.msg.value
    local msg_prev = cmd_prompt.msg_prev.value


    if focused == true then
        -- User is writing
        if cmd_prompt.trigger_evaluated.value == true then
            -- User has just started writing
            -- Update the prompt prefix
            update_cmd_prompt_mode(focused)
        end
        -- Set "evaluate this when finished" -flag
        cmd_prompt.trigger_evaluated.value = false
        -- Get the msg that was in the field before editing for comparison
        cmd_prompt.msg_prev.value = cmd_prompt.msg.value
        return
    end

    if trigger_evaluated == true then
        -- This edit has already been checked
        -- No action
        return
    end

    -- If the previous conditions have been passed,
    -- User has just exited edit_mode.
    -- Update the prompt prefix
    update_cmd_prompt_mode(focused)
    -- Set "this has been evaluated" flag
    -- so that this user entry won't be evaluated again.
    cmd_prompt.trigger_evaluated.value = true
    -- Reset history pointer
    reset_history()

    -- Evaluate message
    local parse = evaluate(msg, msg_prev)

    if parse then
        -- Pass msg to parse
        pass_msg(msg)
    end
end

local function apply_history_item(item_index)
    -- This changes current msg into a msg of a history item
    -- Error catching
    assert(item_index > 0 and item_index <= #vader.logs.history, "Trying to display an out-of-bounds history item, item index:"..item_index.." (Bounds 1-"..#vader.logs.history..")")
    -- Apply change
    set_cmd_line_text(vader.logs.history.items[item_index].string)
end

local function browse_history(direction)
    -- This handles changing the textfield
    -- önto a history item
    
    -- Shorthand
    

    if direction ==  "back" then
        cmd_prompt.history_pointer.value = math.min(cmd_prompt.history_pointer.value+1, #vader.logs.history)
    else
        -- Direction == "fwd"
        cmd_prompt.history_pointer.value = math.max(cmd_prompt.history_pointer.value-1, 0)
    end
    
    if cmd_prompt.history_pointer.value > 0 then
        apply_history_item(cmd_prompt.history_pointer.value)
    else
        clear_cmd_prompt()
    end
    
end

local function focus_cmd_textfield()
    -- Reset textfield, if it is the end of history
    if cmd_prompt.msg.value == vader.END_OF_HISTORY_TEXT then
        cmd_prompt.msg.value = vader.START_OF_HISTORY_TEXT 
    end
    -- Focus command line textfield
    vb.views.prompt_id.edit_mode = true
end

local function toggle_home_dump()
    vb.views.home_dump_id.visible = not vb.views.home_dump_id.visible 
end


------------------------------------------
-- Main functions
------------------------------------------
function set_cmd_line_text(set_string)
    -- This changes current msg into set_string
    -- Error catching
    assert(set_string, "Trying to set nil string into command line")
    assert(type(set_string) == "string", "Trying to set set_string type:"..type(set_string).." into command line textfield. Use string.")
    -------------
    cmd_prompt.msg.value = set_string
end

function build_cmd_prompt_gui()
    -- Create dialog content

    content_cmd = vb:column {
        margin = 2,
        vb:row {
            style = "border",
            vb:text {
                id = "mode_id",
                width = vader.PROMPT_MODE_WIDTH,
                text = cmd_prompt.mode.value,
            },
            vb:textfield {
                id = "prompt_id",
                width = vader.PROMPT_TOTAL_WIDTH - vader.PROMPT_MODE_WIDTH,
                bind = cmd_prompt.msg,
                edit_mode = true
            }
        },
        vb:multiline_text {
            style = "border",
            id = "home_dump_id",
            width = vader.PROMPT_TOTAL_WIDTH,
            height = vader.PROMPT_HOME_DUMP_HEIGHT,
            visible = cmd_prompt.home_dump_visible.value --this for remembering the state of log visibility
        }
    }
    return content_cmd
end

function build_macro_prompt_gui()
    content_macro = vb:column {
        margin = 2,
        vb:row {
            vb:text {
                font = "Bold",
                text = "Title",
                width = 40,
            },
            vb:textfield {
                id = "macro_name_string",
                tooltip = "Title for your shortcut",
                width = 200,
            }
        },
        vb:row {
            vb:text {
                font = "Bold",
                text = "Script",
                width = 40,
            },
            vb:textfield {
                id = "macro_command_string",
                tooltip = "The vader script triggered by shortcut",
                width = 200,
            }
        },
        --[[
        vb:row {
            vb:textfield {
                id = "macro_shortcut_keyname_string",
                width = 200,
                tooltip = "Your shorcut key name.\n(e.g. 'q' or 'return'" 
            }
        },
        vb:row {
            vb:textfield {
                id = "macro_shortcut_keymodifiers_string",
                width = 200,
                tooltip = "Your shorcut key modifiers.\n(e.g. 'shift' or 'option + control'" 
            }
        },
        --]]
        vb:row {
            vb:button {
                text = "ADD",
                tooltip = "Add this shortcut under Global:"..vader.TOOL_NAME.." shortcut group",
                notifier = function()
                    local reg_title = vb.views.macro_name_string.value
                    local reg_script = vb.views.macro_command_string.value
                    regmacro(reg_title, reg_script)
                end,
            },
            vb:button {
                text = "REMOVE",
                tooltip = "Remove this shortcut under Global:"..vader.TOOL_NAME.." shortcut group\n(You only need to fill the title)",
                notifier = function()
                    local reg_title = vb.views.macro_name_string.value
                    removemacro(reg_title)
                end,
            }
        }
    }
    return content_macro
end

function show_cmd_prompt()
    -- Link to global command prompt dialog placeholder

    -- This block makes sure a non-modal dialog is shown once.
    -- If the dialog is already opened, it will be focused.
    if dialog_cmd and dialog_cmd.visible then
        dialog_cmd:show()
        focus_cmd_textfield()
        return
    end

    -- Initialization on each displaying
    update_vb() --This seems to be needed in order to display the GUI after closing it once? TODO:why?
    reset_history()
    clear_cmd_prompt()

    -- Keyhandler
    local function keyhandler(dialog_title, caught_key)
        -- Note:this is only active in BROWSE-MODE

        -- Define reserved keys
        local reserved_keys = { 
           
            ["close_dlg_key"] =
            {["name"] = "esc",      ["modifiers"] = ""},

            ["enter_cmd_key"] =
            {["name"] = "return",   ["modifiers"] = ""},

            ["history_back_key"] =
            {["name"] = "up",       ["modifiers"] = ""},

            ["history_fwd_key"] =
            {["name"] = "down",     ["modifiers"] = ""},

            ["toggle_home_dump_key"] =
            {["name"] = "up",       ["modifiers"] = "shift"},

            -- These keys for debug only
            ["dump_history_key"] =
            {["name"] = "h",            ["modifiers"] = ""},
            ["dump_history_verbose_key"] =
            {["name"] = "h",            ["modifiers"] = "shift"},
            ["dump_main_log_key"] =
            {["name"] = "m",            ["modifiers"] = ""},
            ["dump_main_log_verbose_key"] =
            {["name"] = "m",            ["modifiers"] = "shift"},
            ["dump_debug_log_key"] =
            {["name"] = "d",            ["modifiers"] = ""},
            ["dump_debug_log_verbose_key"] =
            {["name"] = "d",            ["modifiers"] = "shift"},
            ["dump_error_log_key"] =
            {["name"] = "e",            ["modifiers"] = ""},
            ["dump_error_log_verbose_key"] =
            {["name"] = "e",            ["modifiers"] = "shift"},
        }

        -- Test for reserved keys
        -- Put this up if a reserved key is found
        local reserved_flag = false
        -- This is used to store the reserved key title for handling
        local action
        for key_title, reserved_key  in pairs(reserved_keys) do
            if caught_key.name == reserved_key.name and caught_key.modifiers == reserved_key.modifiers then
                -- Caught_key matches some reserved key
                reserved_flag = true
                -- Define action for handling
                action = key_title
                break
            end
        end

        if reserved_flag == false then
            -- Caught_key not in use, pass to renoise (Global scope), exit
            return caught_key
        end

        -- Handle reserved keys
        if action == "close_dlg_key" then
            -- Close dialog
            close_dialog_cmd()
            return
        end
        
        if action ==  "enter_cmd_key" then
            -- Enter selected command from history
            cmd_history_trigger()
            return
        end
        
        if action ==  "history_back_key" then
            -- Browse history 1 item backwards
            browse_history("back")
            return
        end
        if action ==  "history_fwd_key" then
            -- Browse history 1 item forwards
            browse_history("fwd")
            return
        end
        if action ==  "toggle_home_dump_key" then
            -- Toggle visibility of the 'home dump'
            toggle_home_dump()
            return
        end
        ---- Debug keys
        if action ==  "dump_history_key" then
            -- Dump history in terminal. DEBUG.
            vader.logs.history:dump(vader.displays.terminal)
            return
        end
        if action ==  "dump_history_verbose_key" then
            -- Dump verbose history in terminal. DEBUG.
            vader.logs.history:dump(vader.displays.terminal, 100) --TODO: get the highest level updated in a global
            return
        end
        if action ==  "dump_main_log_key" then
            -- Dump history in terminal. DEBUG.
            vader.logs.main:dump(vader.displays.terminal)
            return
        end
        if action ==  "dump_main_log_verbose_key" then
            -- Dump verbose history in terminal. DEBUG.
            vader.logs.main:dump(vader.displays.terminal, 100) --TODO: get the highest level updated in a global
            return
        end
        if action ==  "dump_debug_log_key" then
            -- Dump history in terminal. DEBUG.
            vader.logs.debug:dump(vader.displays.terminal)
            return
        end
        if action ==  "dump_debug_log_verbose_key" then
            -- Dump verbose history in terminal. DEBUG.
            vader.logs.debug:dump(vader.displays.terminal, 100) --TODO: get the highest level updated in a global
            return
        end
        if action ==  "dump_error_log_key" then
            -- Dump history in terminal. DEBUG.
            vader.logs.errors:dump(vader.displays.terminal)
            return
        end
        if action ==  "dump_error_log_verbose_key" then
            -- Dump verbose history in terminal. DEBUG.
            vader.logs.errors:dump(vader.displays.terminal, 100) --TODO: get the highest level updated in a global
            return
        end
    end
   
    if not content_cmd then
        content_cmd = build_cmd_prompt_gui()
    end

    -- Display dialog
    local dialog_title = string.format("%s %3.2f", vader.TOOL_NAME, vader.TOOL_VERSION)
    dialog_cmd = renoise.app():show_custom_dialog(dialog_title, content_cmd, keyhandler)

    -- Spawn an idle notifier to watch over textfield focus
    -- This is the main 'trigger' to the prompt
    if not renoise.tool().app_idle_observable:has_notifier(cmd_edit_trigger) then
        renoise.tool().app_idle_observable:add_notifier(cmd_edit_trigger)
    end

    focus_cmd_textfield()
end

function show_macro_prompt()

    if dialog_macro and dialog_macro.visible then
        dialog_macro:show()
        return
    end

    update_vb() --This seems to be needed in order to display the GUI after closing it once? TODO:why?

    if not content_macro then
        content_macro = build_macro_prompt_gui()
    end


    -- Display dialog
    local dialog_title = string.format("%s %3.2f - MACRO PROMPT", vader.TOOL_NAME, vader.TOOL_VERSION)
    dialog_macro = renoise.app():show_custom_dialog(dialog_title, content_macro)


end
