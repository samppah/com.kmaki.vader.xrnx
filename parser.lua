--
--parser.lua
--
----------------------------------------------------
-- file created         08-Jan-2012

-- The parsing subtasks
-- i.e. handles the "PARSE" -directives from
-- vader.directives -list.
-- Interprets user messages in them and
-- translates into "PROCESS" -directives, and
-- inputs them in the directives-list.

----------------------------------------------------
-- Globals declaration, initialization
----------------------------------------------------
-- Project wide globals (local representation)
local vader
-- File globals
local parse_log

----------------------------------------------------
-- Boot procedure, initialization
----------------------------------------------------

function boot_parser(main_vader)
    -- Project Globals
    vader = main_vader
end
function init_parse_log(main_vader)
    --This is called from main.lua to init this submodule log
    parse_log = ALog("parse()", vader.displays.no_display, 0)
    parse_log:add_distribute_log(vader.logs.active_task)
end



----------------------------------------------------
-- Minor functions
----------------------------------------------------



----------------------------------------------------
-- Main functions
----------------------------------------------------

parse_error = ""
function parse(input_msg, parse_recursion_level, is_successive_message)

    --Start a new parse
    parse_log:clear()
    parse_log:entry("Parsing...")

    -- Update root node
    vader = get_tool_root_node()

    --Setup LPeg for parsing
    local lulpeg = require "LuLpeg/lulpeg"
    local G = require "grammar"
    local match = lulpeg.match

    --Get LPeg parsed input
    parse_log:entry("Parsing message: '"..input_msg.."' ...") --debug
    local parsed_input = match(G.script, input_msg)

    --LPEG BRANCH TESTS
    rprint(parsed_input) --print user input parsed in tree format

    --Reset parse counters
    G:reset_parse_counters()

    --Check parsing success
    if parse_error == "" then
        --Parsing was succesful
        parse_log:entry("User input parsed.")
    else
        --Parsing failed, report errors
        local error_msg = "Parsing error: "..parse_error
        parse_error = "" --reset for future errors
        parse_log:entry(error_msg)
        --Fire error
        vader_error(error_msg, true) --true is for "is_syntax_error")
    end

    --Loop every message in script
    for msg_index, msg_table in ipairs(parsed_input["SCRIPT"]) do

        --Map shorthand
        local TRG = msg_table["MSG"]["TRG"]
        local CNT = msg_table["MSG"]["CNT"]
        local GFL = msg_table["MSG"]["GFL"]
        local MCR = msg_table["MSG"]["MCR"]

        --Analyze: what message parts are included
        local has_TRG = not(not(TRG))
            and vader.logs.debug:entry("Found TRG.")

        local has_CNT = not(not(CNT))
            and vader.logs.debug:entry("Found CNT.")

        local has_GFL = not(not(GFL))
            and vader.logs.debug:entry("Found GFL.")
            and not_implemented("Global flags")

        local has_MCR = not(not(MCR))
            and vader.logs.debug:entry("Found MCR.")
            and not_implemented("Macro part")

        --Build scope object for process
        --Explicit values (and some implicit) are built in LPeg parse
        --now build implicit values
        
        local target_scope
        if has_TRG then
            target_scope = ScopeObject(TRG["SCP"])
        end
        local content_scope
        local content_exp
        if has_CNT then
            if CNT["SCP"] then
                content_scope = ScopeObject(CNT["SCP"])
            elseif CNT["EXP"] then
                content_exp = CNT["EXP"]
            else
                vader_error("Content part is not a scope or an expression. But how. ?")
            end
        end



    ----------------------------------------
    -- Global Flags handling
    -- :TODO

    -- Parse is a success
    parse_log:entry("success.") --debug

    -- Get info stored
    vader.logs.main:join_log(parse_log:compress())


    -- Setup this message as a directive for processing
    --
    local new_log_entry = vader.logs.main:entry("process", 1)
    -- Add to Directives for processing
    local process_directive = VaderDirective("PROCESS", new_log_entry)
    local content_pack = {
        --["static"] = (it_cnt[msg_index] and it_cnt[msg_index].resolved),
        --["dynamic"] = it_cnt[msg_index]
        ["static"] = content_exp,
        ["dynamic"] = content_scope
    }

    process_directive:new_argument(target_scope)
    process_directive:new_argument(content_pack)
    process_directive:new_argument(is_successive_message)
    -- PROCESSing must be done before sequential PARSEs,
    -- so use entry_at instead of entry. This puts the 
    -- PROCESS-directive first in top of the queue.
    vader.directives:entry_at(process_directive, #vader.directives)

    end

    --Back
    return true

end
