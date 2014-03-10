--developer_test.lua
--
--this is for vader -renoise tool
--it's used to produce a coherent
--testing process for debugging
--
--TODO: double range offenders: p1..2_ -> CRITICAL ERROR
--
--TODO: effect/ note column fix:
--      f:1 on note column -> note entered
--      f:1 on effect column -> nothing entered
--
--

local vader = get_tool_root_node()
local test_log = ALog("Testing log", vader.displays.msg_dlg, 0)
-- a global to pass a title of test group
local tg = ""
local test_groups = table.create()
local test_group_count = 0
local vb = renoise.ViewBuilder()
local dialog_devtest = nil
local visible_page = 1

local function test_a_script(title, script)
    --Tests a single script
    --register a new log for tests
    test_log:entry("Testing "..title)
end

local function add_to_test_group(group, script, title)
    test_groups[group]:insert(script)
end


--TODO: The title does not get added anywhere.
local function add_test_group(group, script_table)
    test_group_count = test_group_count + 1
    if test_groups[group] then
        for _ = 1, #script_table/2 do
            local script = script_table[(_*2) - 1]
            local title = script_table[(_*2)]
            add_to_test_group(group, script, title)
        end
    else
        test_groups[group]=table.create()
        for _ = 1, #script_table/2 do
            local script = script_table[(_*2) - 1]
            local title = script_table[(_*2)]
            add_to_test_group(group, script, title)
        end
    end
end


add_test_group("Target scope - tags",
    {
        "p", "",
        "q", "",
        "s", "",
        "t", "",
        "g", "",
        "l", "",
        "c", "",
        "n", "",
        "i", "",
        "v", "",
        "a", "",
        "d", "",
        "e", "",
        "f", "",
        "x", "",
    }
)

add_test_group("Context scope - tags",
    {
        ":p", "",
        ":q", "",
        ":s", "",
        ":t", "",
        ":g", "",
        ":l", "",
        ":c", "",
        ":n", "",
        ":i", "",
        ":v", "",
        ":a", "",
        ":d", "",
        ":e", "",
        ":f", "",
        ":x", "",
    }
)

add_test_group("Target scope - double tags",
    {
        "pp", "",
        "qq", "",
        "ss", "",
        "tt", "",
        "gg", "",
        "ll", "",
        "cc", "",
        "nn", "",
        "ii", "",
        "vv", "",
        "aa", "",
        "dd", "",
        "ee", "",
        "ff", "",
        "xx", "",
    }
)
add_test_group("No range offenders pt 1",
    {
        "p..", "",
        "q..", "",
        "s..", "",
        "t..", "",
        "g..", "",
        "l..", "",
        "c..", "",
        "n..", "",
        "i..", "",
        "v..", "",
        "a..", "",
        "d..", "",
        "e..", "",
        "f..", "",
        "x..", "",
    }
)
add_test_group("No range offenders pt 2",
    {
        "p(..)", "",
        "q(..)", "",
        "s(..)", "",
        "t(..)", "",
        "g(..)", "",
        "l(..)", "",
        "c(..)", "",
        "n(..)", "",
        "i(..)", "",
        "v(..)", "",
        "a(..)", "",
        "d(..)", "",
        "e(..)", "",
        "f(..)", "",
        "x(..)", "",
    }
)
add_test_group("Bad range offenders pt 1",
    {
        "p1..4_", "",
        "q1..4_", "",
        "s1..4_", "",
        "t1..4_", "",
        "g1..4_", "",
        "l1..4_", "",
        "c1..4_", "",
        "n1..4_", "",
        "i1..4_", "",
        "v1..4_", "",
        "a1..4_", "",
        "d1..4_", "",
        "e1..4_", "",
        "f1..4_", "",
        "x1..4_", "",
    }
)
add_test_group("Shorthand ranging (just a random index of 5) pt 1",
    {
        "p..5", "",
        "q..5", "",
        "s..5", "",
        "t..5", "",
        "g..5", "",
        "l..5", "",
        "c..5", "",
        "n..5", "",
        "i..5", "",
        "v..5", "",
        "a..5", "",
        "d..5", "",
        "e..5", "",
        "f..5", "",
        "x..5", "",
    }
)

add_test_group("Fill stuff BRAINLESS",
    {
        "pn:10", "",
        "qn:10", "",
        "sn:10", "",
        "tn:10", "",
        "gn:10", "",
        "ln:10", "",
        "cn:10", "",
        "nn:10", "",
        "in:10", "",
        "vn:10", "",
        "an:10", "",
        "dn:10", "",
        "en:10", "",
        "fn:10", "",
        "xn:10", "",
    }
)
add_test_group("Fill stuff BRAINLESS 2",
    {
        "px:10", "",
        "qx:10", "",
        "sx:10", "",
        "tx:10", "",
        "gx:10", "",
        "lx:10", "",
        "cx:10", "",
        "nx:10", "",
        "ix:10", "",
        "vx:10", "",
        "ax:10", "",
        "dx:10", "",
        "ex:10", "",
        "fx:10", "",
        "xx:10", "",
    }
)

add_test_group("Simple arithmetics",
    {
        ":6+2", "Correct: 8",
        ":6+2/2", "Correct: 7",
        ":(6+2)/2", "Correct: 4",
        ":6/2+2", "Correct: 5",
    }
)
add_test_group("Content side scope - tags and range",
    {
        ":p1", "",
        ":q1", "",
        ":s1", "",
        ":t1", "",
        ":g1", "",
        ":l1", "",
        ":c1", "",
        ":n1", "",
        ":i1", "",
        ":v1", "",
        ":a1", "",
        ":d1", "",
        ":e1", "",
        ":f1", "",
        ":x1", "",
    }
)
add_test_group("Stupid copy trg:cnt, trg==cnt",
    {
        "p:p", "",
        "q:q", "",
        "s:s", "",
        "t:t", "",
        "g:g", "",
        "l:l", "",
        "c:c", "",
        "n:n", "",
        "i:i", "",
        "v:v", "",
        "a:a", "",
        "d:d", "",
        "e:e", "",
        "f:f", "",
        "x:x", "",
    }
)

add_test_group("Content in parentheses.",
    {
        ":(6+2)", "Correct: 8",
        ":(6+2/2)", "Correct: 7",
        ":((6+2)/2)", "Correct: 4",
        ":(6/2+2)", "Correct: 5",
    }
)
--[[
Have a GUI for testing pages for test groups buttons for testing a group
buttons for each test item
--]]
local function set_random_songpos(seq_boolean, track_boolean, line_boolean, col_boolean, inc_nc_boolean, inc_fx_boolean)
    print("setting random position: seq, track, line, col:")
    print(seq_boolean, track_boolean, line_boolean, col_boolean)
    local rs = renoise.song()
    local sp = rs.transport.edit_pos
    local rnd
    local randomseed = os.clock()
    for _ = 1, 5 do
        rnd = math.random()
    end
    if seq_boolean then
        rnd = math.random()
        local new_pos = 1.5 + ((#rs.sequencer.pattern_sequence - 1)*rnd)
        sp.sequence = new_pos
    end
    if track_boolean then
        rnd = math.random()
        local new_pos = 1.5 + ((#rs.tracks - 1)*rnd)
        rs.selected_track_index = new_pos
    end
    if line_boolean then
        rnd = math.random()
        local new_pos = 1.5 + ((rs.selected_pattern.number_of_lines - 1)*rnd)
        sp.line = new_pos
    end
    if col_boolean then
        --Select col type
        local ct = rs.selected_track
        local ttseq = renoise.Track.TRACK_TYPE_SEQUENCER
        local ttsnd = renoise.Track.TRACK_TYPE_SEND
        local ttmst = renoise.Track.TRACK_TYPE_MASTER
        local ttgrp = renoise.Track.TRACK_TYPE_GROUP
        local cpt = rs.selected_pattern:track(rs.selected_track_index)
        local sel_type = nil
        rnd = math.random()
        if ct.type == ttseq and ct.visible_effect_columns > 0 then 
            --could be both
            if (rnd > 0.5 and inc_nc_boolean) or (not inc_fx_boolean) then
                --note
                sel_type = "note"
            else
                --effect
                sel_type = "effect"
            end
        elseif ct.type == ttseq then
            --note
            sel_type = "note"
        else
            --effect
            sel_type = "effect"
        end
        --Select col index
        rnd = math.random()
        local new_pos = 1.5 + ((ct["visible_"..sel_type.."_columns"] - 1)*rnd)
        rs["selected_"..sel_type.."_column_index"] = new_pos
    end
    rs.transport.edit_pos = sp
end

local function pass_dev_msg(msg)
    -- A modded copy of GUI.lua's pass_msg()
    -- Set devtes flag
    vader.DEBUG_DEV_TEST = true
    -- Add command line history entry
    vader.logs.history:entry(msg, 0)
    -- Put input in main log
    local new_log_entry = vader.logs.debug:entry("DEVELOPER TEST GUI: "..msg)
    -- Add to Directives for parsing
    local parse_directive = VaderDirective("PARSE", new_log_entry)
    parse_directive:new_argument(msg)
    vader.directives:entry(parse_directive)
    --[[
    -- Reset prompt
    clear_cmd_prompt()
    --]]
end

local function create_item_button(item)
    --create a button with script text that will run the script
    local function button_press()
        --what happens when you press it
        --randomize position according checkboxes
        local v = vb.views
        local rseq = v.random_seq_check_id.value
        local rtrk = v.random_track_check_id.value
        local rlin = v.random_line_check_id.value
        local rcol = v.random_col_check_id.value
        local incnc = v.inc_notecol_check_id.value
        local incec = v.inc_fxcol_check_id.value
        set_random_songpos(rseq, rtrk, rlin, rcol, incnc, incec)
        --pass message
        pass_dev_msg(item)
    end
    local i_but_row = vb:row{
        vb:button{
            text = item,
            notifier = button_press
        },
        vb:text{
            text = "WTF" --TODO: what's going on?!?!? where's the description?
        }
    }
    return i_but_row, button_press
end

local function create_group_button(group, invoke_table)
    --create a button with group name that will run all group items
    local function button_press()
        --what happens when you press it
        --run through buttons, call
        for _, invoke_function in ipairs(invoke_table) do
            invoke_function()
        end
    end
    local g_but_row = vb:row{
        vb:button{
            text = (type(group) == "string" and group) or "noname",
            notifier = button_press
        }
    }
    return g_but_row
end

local function create_group_page(group)
    --create a column with
    --group button
    --all item buttons
    local invoke_table = table.create()
    local button_rows_table = table.create()
    --run through test_group
    for _ = 1, #test_groups[group] do
        local button_row, invoke_function = create_item_button(test_groups[group][_])	
        invoke_table:insert(invoke_function)
        button_rows_table:insert(button_row)
    end
    local group_row = create_group_button(group, invoke_table)
    local page_column = vb:column{
        group_row,
        unpack(button_rows_table)
    }
    return page_column
end

local function create_pages()
    local pages_table = table.create()
    for _, page in pairs(test_groups) do
        pages_table:insert(create_group_page(_))
    end
    return pages_table
end

local pages = create_pages()

local function update_pages()
    --run through pages-table
    --set all invisible
    --set visible_page visible
    for _, page in pairs(pages) do
        page.visible = false
    end
    for _, page in pairs(pages) do
        if _ == visible_page then
            page.visible = true
            break
        end
    end
end
update_pages()

local function create_navigation_row()
    --create row with buttons to move to next, prev page 
    local function nav_fwd()
        visible_page = math.min(visible_page + 1, test_group_count)
        update_pages()
    end
    local function nav_back()
        visible_page = math.max(visible_page - 1, 1)
        update_pages()
    end
    local nav_row = vb:row{
        vb:button{
            text = " < ",
            notifier = nav_back
        },
        vb:button{	
            text = " > ",
            notifier = nav_fwd
        },
        vb:checkbox{
            id = "random_seq_check_id",
            tooltip = "Random Sequence",
            value = true,
        },
        vb:checkbox{
            id = "random_track_check_id",
            tooltip = "Random Track",
            value = true,
        },
        vb:checkbox{
            id = "random_line_check_id",
            tooltip = "Random line",
            value = true,
        },
        vb:checkbox{
            id = "random_col_check_id",
            tooltip = "Random Column",
            value = true,
        },
        vb:checkbox{
            id = "inc_notecol_check_id",
            tooltip = "Include note columns (seq tracks)",
            value = true,
        },
        vb:checkbox{
            id = "inc_fxcol_check_id",
            tooltip = "Include effect columns (seq tracks)",
            value = true,
        },
    }
    return nav_row
end

--set init values
visible_page = 1

--create pages
local pages_row = vb:row{unpack(pages)}
--create main content
local nav_row = create_navigation_row()
local test_content = vb:column{
    nav_row,
    pages_row
}
--create dialog


local function show_devtest()

    -- This block makes sure a non-modal dialog is shown once.
    -- If the dialog is already opened, it will be focused.
    if dialog_devtest and dialog_devtest.visible then
        dialog_devtest:show()
        return
    end

    -- It's not visible or nothing, create it

    -- Display dialog
    local dialog_title = string.format("%s %3.2f DEVELOPER TEST DIALOG", vader.TOOL_NAME, vader.TOOL_VERSION)
    dialog_devtest = renoise.app():show_custom_dialog(dialog_title, test_content)

end

--pray it works
  
-- Have a key.
renoise.tool():add_keybinding {
    name = "Global:" ..vader.TOOL_NAME..":Developer testing GUI...",
    invoke = show_devtest
}
