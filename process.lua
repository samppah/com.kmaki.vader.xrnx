
--
--process.lua
--
----------------------------------------------------
-- file created         15-Feb-2012

-- this contains the pattern data processing function
-- that is called by main, after parsing a message
-- the exact mechanism is that parse() adds "PROCESS"-
-- directives into the list, which are then dispatched
-- by main().

----------------------------------------------------
-- Globals declaration, initialization
----------------------------------------------------
-- Project wide globals (local representation)
local vader
local rs

-- File globals
local process_log 
local p_data = table.create() --main process data holder

----------------------------------------------------
-- Boot procedure, initialization
----------------------------------------------------

function boot_process(main_vader)
    -- Project Globals
    vader = main_vader
    rs = get_rs()
end
function init_process_log(main_vader)
    process_log = ALog("process()", vader.displays.no_display, 0)
    process_log:add_distribute_log(vader.logs.active_task)
end

----------------------------------------------------
-- Process helper functions
----------------------------------------------------
----TODO: Do these need to be global?
function set_sequence(index)
    --TODO:
    vader.cursor.pattern = index
    if vader.PROCESS_MOVE_CURSOR == true then
        -- It's up, ok to move renoise cursor
        rs.selected_sequence_index = index
        process_log:entry("Moved renoise cursor (sequence)")
    end
    return rs:pattern(rs.sequencer:pattern(index))
end
function set_pattern(index)
    vader.cursor.pattern = index
    -- Check if the move cursor flag is up
    if vader.PROCESS_MOVE_CURSOR == true then
        -- It's up, ok to move renoise cursor
        rs.selected_pattern_index = index
        process_log:entry("Moved renoise cursor (pattern)")
    end
    return rs:pattern(index)
end
function set_track(index, this_pattern)
    -- Sets selected track at index and returns track and pattern_track objects. No constraining.
    vader.cursor.track = index
    -- Check if the move cursor flag is up
    if vader.PROCESS_MOVE_CURSOR == true then
        -- It's up, ok to move renoise cursor
        rs.selected_track_index = index
        process_log:entry("Moved renoise cursor (track)")
    end
    return rs:track(index), this_pattern:track(index)
end
function set_line(index, this_pattern_track)
    -- Sets selected line at index and returns pattern_track_line object. No constraining.
    vader.cursor.line = index
    -- Check if the move cursor flag is up
    if vader.PROCESS_MOVE_CURSOR == true then
        -- It's up, ok to move renoise cursor
        local new_pos = rs.transport.edit_pos --init new pos as a SongPos object
        new_pos.line = index
        rs.transport.edit_pos = new_pos
        process_log:entry("Moved renoise cursor (line)")
    end
    return this_pattern_track:line(index) 
end
function set_column(index, this_pattern_track_line, col_type_string)
    -- This is a master function for set_note_column() / set_effect_column()
    if col_type_string == "note_column" then
        return set_note_column(index, this_pattern_track_line)
    elseif col_type_string == "effect_column" then
        return set_effect_column(index, this_pattern_track_line)
    else
        --Something weird has been tried to set
        vader_error("Unidentified column type in set()")
    end
end
function set_note_column(index, this_pattern_track_line)
    -- Sets selected note_column at index and returns track object. No constraining.
    vader.cursor.note_column = index
    -- Check if the move cursor flag is up
    if vader.PROCESS_MOVE_CURSOR == true then
        -- It's up, ok to move renoise cursor
        rs.selected_note_column_index = index
    end
    return this_pattern_track_line:note_column(index)
end
function set_effect_column(index, this_pattern_track_line)
    -- Sets selected effect_column at index and returns track object. No constraining.
    vader.cursor.effect_column = index
    -- Check if the move cursor flag is up
    if vader.PROCESS_MOVE_CURSOR == true then
        -- It's up, ok to move renoise cursor
        rs.selected_effect_column_index = index
    end
    return this_pattern_track_line:effect_column(index)
end
--TODO: do the above need to be global?
local function song_data_constrain(value_to_constrain, data_type)
    -- Constrains a song data object to its minimum, maximum, according to vader.lex.songdata_codex
    -- if constrained, return a value
    -- if not constrained, return nothing!
    -- Register in debug
    local constrain_log = ALog("song_data_constrain()", vader.displays.no_display, 0)
    constrain_log:add_distribute_log(process_log)
    constrain_log:entry("Checking need to constrain "..data_type.." value")
    -- Error catching
    local data = vader.lex.songdata_codex[data_type]
    vader_assert(data, "Trying to constrain a song data object not found in codex ("..(data_type or "nil") )
    --
    local is_scalable = data.values and data.values.scale
    vader_assert(is_scalable, "Trying to scale a non-scalable song data object ("..(data_type or "nil") )
    ----------------
    local scale = data.values.scale
    local specials = data.values.specials
    local minval = scale.MIN()
    local maxval = scale.MAX()

    --Constrain
    local constrained_value = nil

    if value_to_constrain <= maxval and value_to_constrain >= minval then
        --in range
    else
        --out of range
        --Constrain
        if value_to_constrain <= minval then
            constrained_value = minval
        else
            constrained_value = maxval
        end
        constrain_log:entry("Constrained a "..data_type.." value")
    end

    return constrained_value or value_to_constrain
end

local function scale_it_index(src_start, src_end, src_at, cnt_start, cnt_end)
    --Scales iteration index value between target, content
    
    --[[
    print("src_start"..src_start)
    print("src_end"..src_end)
    print("src_at"..src_at)
    print("cnt_start"..cnt_start)
    print("cnt_end"..cnt_end)
    --]]

    local src_max = math.max(src_start, src_end)
    local src_min = math.min(src_start, src_end)
    local src_current_percent 
    if src_at == src_start then
        src_current_percent = 0
    elseif src_at == src_end then
        src_current_percent = 1
    elseif src_start > src_end then
        src_current_percent = 1  - ((src_at - src_min) / (src_max-src_min)) 
    else
        src_current_percent = (src_at - src_min) / (src_max-src_min)
    end

    local cnt_max = math.max(cnt_start, cnt_end)
    local cnt_min = math.min(cnt_start, cnt_end)

    local cnt_current_actual = cnt_min + (src_current_percent * (cnt_max-cnt_min) )
    local cnt_current_actual_int = math.floor(cnt_current_actual)
    --TODO: math.floor or math.ceiling!! dependant on which 'side' of the iteration you are
    --
    --print("result-------"..cnt_current_actual_int) --debug
    return cnt_current_actual_int
end

local function songdata_object_is_empty(songdata_object, songdata_object_string)
    -- Returns empty according to vader.lex.songdata_codex
    vader_assert(songdata_object ~= nil, "Tried to call songdata_object_is_empty with a nil songdata_object.")
    vader_assert(type(songdata_object_string) == "string", "Tried to call songdata_object_is_empty with songdata_object_string type:"..type(songdata_object_string)..". Use a string.")
    -------------
    --e.g. pattern_is_empty = songdata_object_is_empty(rs.selected_pattern, "pattern")
    return vader.lex.songdata_codex[songdata_object_string].is_empty(songdata_object)
end

local function proc_data_prep_1(data_root)
    -- A repeating code block on the preparation stage before each layer loop
    -- This A) cleans up data_root structure by redirecting
    -- data_root.partial data into data_root. and B) constrains ranges with song_data_constrain()
    
    -- Deal with level target partial
    local partial_trg = data_root.partial_trg
    local partial_cnt = data_root.partial_cnt
    --Check that partials have start end values assigned
    vader_assert(partial_trg.range.start_value and partial_trg.range.end_value, "No range start/end values found for "..partial_trg.name.." loop")
    --Check partial names exist in songdata_codex
    vader_assert(vader.lex.songdata_codex[partial_trg.name], "Trying to refer to an unknown song data object:"..(partial_trg.name or "nil"))
    if partial_cnt then
        vader_assert(vader.lex.songdata_codex[partial_cnt.name], "Trying to refer to an unknown song data object."..(partial_cnt.name or "nil"))
    end

    local function constrain_and_prepare(this_partial)
        -- Constrain?
        local fixed_sdo_start_index = song_data_constrain(this_partial.range.start_value, this_partial.name)
        local fixed_sdo_end_index = song_data_constrain(this_partial.range.end_value, this_partial.name)

        -- Direction
        local sdo_dir_step
        if fixed_sdo_start_index > fixed_sdo_end_index then
            sdo_dir_step = -1
        else
            sdo_dir_step = 1
        end

        -- Set quick access loop min, max values
        --data_root.min_index = vader.lex.songdata_codex[this_partial.name].values.scale.MIN
        --data_root.max_index = vader.lex.songdata_codex[this_partial.name].values.scale.MAX
        data_root.min_index = vader.lex.songdata_codex[this_partial.name].values.scale.MIN()
        data_root.max_index = vader.lex.songdata_codex[this_partial.name].values.scale.MAX()

        return fixed_sdo_start_index, fixed_sdo_end_index, sdo_dir_step
    end

    -- Set loop values
    data_root.loop = table.create()
    -- Target
    data_root.loop.s_trg, data_root.loop.e_trg, data_root.loop.d_trg = constrain_and_prepare(partial_trg)
    -- Content
    if p_data.cnt_type == "scope" then
        data_root.loop.s_cnt, data_root.loop.e_cnt, data_root.loop.d_cnt = constrain_and_prepare(partial_cnt)
    elseif p_data.cnt_type == "number" then
        --TODO:constrain that too
    elseif p_data.cnt_type == "nothing" then
        --???
    elseif p_data.cnt_type == "special" then
        --???
    end

    -- Skip empty?
    data_root.skip_empty = partial_trg.range.skip_empty or (partial_cnt and partial_cnt.range.skip_empty)

    --Result:
    --data_root.partial_trg : original data of target partial
    --data_root.partial_cnt : original data of content partial OR nil
    --data_root.loop: CONSTRAINED loop data
    --data_root.min_index: minimum index according to vader.lex.songdata_codex --TODO: trg, if cnt then cnt. will this cause troubles?
    --data_root.max_index: maximum index according to vader.lex.songdata_codex --TODO: trg, if cnt then cnt. will this cause troubles?
    --data_root.skip_empty: COMBINED skip empty of trg/cnt
    
    return data_root
end

local function level_terminal(data_root, it_scope, it_content, inner_function)
    --A repeating code block on the final stage of each layer loop
    --Check if to skip, handle or go deeper
    local bottom_level_index = it_scope.lowest_index
    local this_level_name, this_level_index = get_scopetag_level(data_root.partial_trg.name) --TODO:set a level index into partial so this is not needed.

    if bottom_level_index == this_level_index then
        --user has not specified scope down to track range
        process_log:entry("Skipping everything below "..this_level_name.." level - not defined by user. Processing as "..this_level_name.." level songdata objects.")
        --Process as objects
        if it_content == "CLEAR_OBJECT" then
            --clear
            vader.lex.songdata_codex[data_root.partial_trg.name].set_empty(data_root.trg_o)
            --p_data.pattern.trg_o:clear()
        elseif p_data.cnt_type == "number" then
            --copy from pattern index
            not_implemented("index based copy")
        elseif p_data.cnt_type == "scope" then
            --copy from scope index
            not_implemented("scope based copy")
        elseif p_data.cnt_type == "special" then
            -- Nothing
        elseif p_data.cnt_type == "nothing" then
            -- Nothing
        else
            -- Somethings gone awry.
            vader_error("Error in content recognition. It_content type:"..(p_data.cnt_type or "nil"))
        end
    else
        --Go to inner function (a loop)
        process_log:entry("Processing further from "..this_level_name.." level.")
        inner_function() --all data is now under p_data, which is 'global', declared in start
        process_log:entry("Exiting back to "..this_level_name.." level")
    end
end

----------------------------------------------------
-- Process main function
----------------------------------------------------

function process(it_scope, it_content_pack, is_successive_message)
    -- This is the main process loop. It processes pattern data
    -- running over it_scope, applying it_content on it
    --
    -- Error catching
    --
    -- TODO
    --
    -----------------

    ----------------------------------------
    -- SETUP
    ----------------------------------------
    process_log:clear()
    process_log:entry("Processing...") --debug
    
    -- update rs
    rs = get_rs()

    -- redirect stuff from it_content_pack.
    -- TODO:reformat this. This is outright messy.
    local it_content = it_content_pack.static
    local it_content_tree = it_content_pack.dynamic


    -- Check processing status
    if not is_successive_message then
        -- is_successive_message == false means that this is a processing
        -- call done by a parse directive that is THE FIRST one
        -- in a script.
        --
        -- Get starting cursor pos - initialize vader.cursor
        vader.cursor = VaderCursor()
    else
        -- if this is a successive message (part of the same script),
        -- use the cursor place where was left in last msg
        --
        -- Set processing cursor starting pos (existing vader.cursor)
        vader.cursor:set_all()
    end

    if not it_scope then
        --This message has no target context
        --Exit without iterating
        process_log:entry("No target in message, exited before processing loop.") --debug
        return it_content or true
    end
    -- Get scope partials for iteration loop
    --local it_pat =              it_scope:partial(1)
    local it_pat_trk =          it_scope:partial(2)
    local it_pat_trk_lin =      it_scope:partial(3)
    -- Column level: must select either notecol or effectcol
    local it_col =              it_scope:partial(4)
    local it_notecol =          it_scope:partial(5)
    local it_effectcol =        it_scope:partial(6)

    --Test it_content main type
    --TODO: fix this. Related to cleaning up the 'content_pack' mess
    local it_content_type
    p_data.cnt_type = nil
    if type(it_content) == "number" then
        -- it_content_type = "number"
        p_data.cnt_type = "number"
        --print("STARTING PROCESS: DUMP IT_CNT")
        --print(it_content)
    elseif it_content_tree then
        --IT STILL COULD BE VALUE EMPTY FOR INSTANCE!
        if it_content_tree.partial then
            --the tree has a 'partial' method, it's a scope
            --it_content_type = "scope"
            p_data.cnt_type = "scope"
        else
            --it_content_type = "special"
            p_data.cnt_type = "special"
        end
        --print("STARTING PROCESS: DUMP IT_CNT")
        --it_content_tree:dump()
    else
        --it_content_type = "nothing"
        p_data.cnt_type = "nothing"
    end
    process_log:entry("Content type is "..p_data.cnt_type) --debug


    --Check if content type is supported for now
    if p_data.cnt_type == "number" then
        -- Go ahead
    elseif p_data.cnt_type == "scope" then
        -- Do not go ahead.
        not_implemented("Content = a scope")
    elseif p_data.cnt_type == "special" then
        -- Go ahead
    elseif p_data.cnt_type == "nothing" then
        -- Go ahead
    else
        vader_error("Unknown content type:"..(p_data.cnt_type or "nil"))
    end

    --[[
    --TODO:not used
    --Get composite lowest if it_content_is scope
    local composite_lowest_index = nil
    local composite_lowest_name = nil
    if it_content_type == "scope" then
        if it_content_tree.lowest_index > it_scope.lowest_index then
            composite_lowest_index = it_content_tree.lowest_index
            composite_lowest_name = it_content_tree.lowest_name
        end
    end

    --Create apply_value table if it_content is scope
    ----TODO: this is actually not used. Is it?
    local cnt_stuff = IterationTable()
    if p_data.cnt_type == "scope" then
        cnt_stuff.method = "patterns" --TODO
    end
    --]]

    ----------------------------------------
    --THE INNER LOOPS
    ----------------------------------------
    --These are the loops that run inside each other,
    --forming a construct to iterate over song data.
    --They are called at each level from the 'level_terminal()' function.
    --They're not generalized further, because some
    --levels need special handling methods. They are,
    --however very similar to each other.
    local function note_columns_subcol_loop()
        -----
        local static_content_value
        local dynamic_content_value
        local final_value
        local is_modify_command = (p_data.cnt_type ~= "nothing")
        if is_modify_command then
            static_content_value = it_content
            --dynamic_content_value = (type(it_content_tree) == "TokenTree" and it_content_tree:solve())
            dynamic_content_value = it_content_tree.partial and it_content_tree:partial(5):solve()
            --TODO: select between the two?
            final_value = dynamic_content_value or static_content_value
            vader_assert(type(final_value) == "number" or type(final_value) == "TokenTree", "Could not resolve a value to apply")
        end
        ----------------------------------------
        -- NOTE COLUMNS SUB_COLUMN OPERATIONS
        ----------------------------------------
        local mod_value = it_scope:partial(5).name
        local edit_col = p_data.column.trg_o
        if is_modify_command then
            --Check mod_value exists 
            vader_assert(vader.lex.songdata_codex[mod_value], "Tried to modify an unidentified songdata object:"..(mod_value or "nil"))
            --local constraint_min = vader.lex.songdata_codex[mod_value].values.MIN
            --local constraint_max = vader.lex.songdata_codex[mod_value].values.MAX
            local specials =       vader.lex.songdata_codex[mod_value].values.special or {}
            local is_special = table.find(specials, final_value)

            local apply_value

            if is_special then
                --Don't check for constrains
                apply_value = specials[is_special]
                process_log:entry("Applied a special "..mod_value.." value:"..is_special.." ("..apply_value..")")
            else
                --Check constrains
                apply_value = song_data_constrain(final_value, mod_value)
            end

            -- Check need to expand a subcolumn
            if mod_value == "volume_value" then
                p_data.track.trg_o2.volume_column_visible = true
            elseif mod_value == "panning_value" then
                p_data.track.trg_o2.panning_column_visible = true
            elseif mod_value == "delay_value" then
                p_data.track.trg_o2.delay_column_visible = true
            end
            -- Modify the value
            edit_col[mod_value] = apply_value
        end
    end
    local function effect_columns_subcol_loop()
        local static_content_value
        local dynamic_content_value
        local final_value
        local is_modify_command = (p_data.cnt_type ~= "nothing")
        if is_modify_command then
            static_content_value = it_content
            dynamic_content_value = it_content_tree.partial and it_content_tree:partial(6):solve()
            --TODO: select between the two?
            final_value = dynamic_content_value or static_content_value
            vader_assert(type(final_value) == "number", "Could not resolve a value to apply")
        end
        -----
        ----------------------------------------
        -- EFFECT COLUMNS SUB_COLUMN OPERATIONS
        ----------------------------------------
        local mod_value = it_scope:partial(6).name
        local edit_col = p_data.column.trg_o
        if is_modify_command then
            --Check mod_value exists 
            vader_assert(vader.lex.songdata_codex[mod_value], "Tried to modify an unidentified songdata object:"..(mod_value or "nil"))
            --local constraint_min = vader.lex.songdata_codex[mod_value].values.MIN
            --local constraint_max = vader.lex.songdata_codex[mod_value].values.MAX
            vader_assert(vader.lex.songdata_codex[mod_value].values, "A malformed entry in vader.lex.songdata_codex: no 'values' key."..(mod_value or "nil"))
            local specials =       vader.lex.songdata_codex[mod_value].values.special or {}
            local is_special = table.find(specials, final_value)

            local apply_value

            if is_special then
                --Don't check for constrains
                apply_value = specials[is_special]
                process_log:entry("Applied a special "..mod_value.." value:"..is_special.." ("..apply_value..")")
            else
                --Check constrains
                apply_value = song_data_constrain(final_value, mod_value)
            end
            -- Modify the value
            if mod_value == "effectnumber" then
                edit_col.number_value = final_value
            end
            if mod_value == "effectamount" then
                edit_col.amount_value = final_value
            end
        end
    end
    local function columns_loop()
        --THIS is called from line_level loop terminal
        --setup p_data
        p_data.column = table.create()
        p_data.column.partial_trg = it_scope:partial(4)
        p_data.column.partial_cnt = (p_data.cnt_type == "scope" and it_content_tree:partial(4)) or nil
        p_data.column = proc_data_prep_1(p_data.column, it_scope)

        local partial_trg = p_data.column.partial_trg
        local partial_cnt = p_data.column.partial_cnt
        
        --get trg col type
        if p_data.column.partial_trg.name == "effect_column" then
            --Set col type property
            p_data.column.trg_col_type = "effect_column"
            --Remap the column partial. It is the effect column one.
            p_data.column.partial_trg = it_scope:partial(4)
        else
            --Set col type property
            p_data.column.trg_col_type = "note_column"
            --No need to remap. --TODO: hmm?
        end

        --get cnt col type
        if p_data.cnt_type == "scope" then
            if p_data.column.partial_cnt.name == "effect_column" then
                --Set col type property
                p_data.column.cnt_col_type = "effect_column"
                --Remap the column partial. It is the effect column one.
                p_data.column.partial_cnt = cnt_tree:partial(4)
            else
                --Set col type property
                p_data.column.cnt_col_type = "note_column"
                --No need to remap. --TODO: hmm?
            end
        end

        --Check if rules to skip altogether apply
        --No rules yet
        ----cnt notecol, trg effectcol -type situations -> syntax error. TODO
        if p_data.column.max_index == 0 then
            --No columns of current type in track
            process_log:entry("No "..p_data.column.trg_col_type.."s available in current track. Skipping columns.")
            return --will exit the columns_loop()
        end

        for col_index = p_data.column.loop.s_trg, p_data.column.loop.e_trg, p_data.column.loop.d_trg do
            repeat --faux repeat wrap
                --get current column type
                --TODO: how to work this in vader.cursor?
                p_data.column.this_col_type = nil
                if rs.selected_sub_column_type == renoise.Song.SUB_COLUMN_EFFECT_NUMBER or rs.selected_sub_column_type == renoise.Song.SUB_COLUMN_EFFECT_AMOUNT then
                    p_data.column.this_col_type = "effect_column"
                else
                    p_data.column.this_col_type = "note_column"
                end
                --Check WRONG_COLTYPE situation
                --if p_data.column.this_col_type ~= p_data.column.trg_col_type and p_data.column.partial_trg.range.start_value == 0 then
                if p_data.column.this_col_type ~= p_data.column.trg_col_type then
                    --Trying to access some non-available column range property
                    if vader.PROCESS_IGNORE_WRONG_COLTYPE then
                        -- Quit processing this column here
                        process_log:entry("Ignored a request for relative index on a wrong column type")
                        break --exits "faux" repeat wrap: skips a single column item
                    else
                        -- Try to access last available notecol or first available effectcol
                        not_implemented("Handling wrong coltype in processing.")
                    end
                end

                -- Set target cursor
                p_data.column.trg_i = col_index
                --o2 = Track object, o = pattern_track -object
                p_data.column.trg_o = set_column(p_data.column.trg_i, p_data.line.trg_o, p_data.column.trg_col_type)
                -- Set content cursor
                p_data.column.cnt_o, p_data.column.cnt_i = nil, nil
                --local apply_trk, apply_pat_trk, apply_trk_i = nil, nil

                if p_data.cnt_type == "scope" then
                    local _ = p_data.column
                    _.cnt_i = scale_it_index(_.loop.s_trg, _.loop.e_trg, _.trg_i, _.loop.s_cnt, _.loop.e_cnt)
                    if p_data.column.this_col_type == "note_column" then
                        _.cnt_o = p_data.line.cnt_o:note_column(_.cnt_i)
                    elseif p_data.column.this_col_type == "effect_column" then
                        _.cnt_o = p_data.line.cnt_o:effect_column(_.cnt_i)
                    else
                        vader_error("Unknown column type:"..(p_data.column.this_col_type or "nil"))
                    end
                end

                --Check if rules to skip this index apply
                local skip_this = false
                if p_data.column.skip_empty then
                    skip_this = songdata_object_is_empty(p_data.column.trg_o, p_data.column.this_col_type) or (p_data.column.cnt_o and songdata_object_is_empty(p_data.column.cnt_o, p_data.column.this_col_type))
                end
                --More rules
                --More rules
                --Single index skip rules end: breakpoint
                if skip_this then
                    process_log:entry("Skipped a single column index.")
                    --Use break to skip an index, jumps outside the repeat wrap
                    break
                end
                --Past this index breakpoint

                --Select subcolumn inner loop
                local subcolumns_loop = nil
                if p_data.column.trg_col_type == "note_column" then
                    subcolumns_loop = note_columns_subcol_loop
                else
                    subcolumns_loop = effect_columns_subcol_loop
                end

                --This level terminal
                level_terminal(p_data.column, it_scope, it_content, subcolumns_loop)
            until true --end faux repeat wrap
        end --for loop
    end
    local function lines_loop()
        --THIS is called from track_level loop terminal
        --setup p_data
        p_data.line = table.create()
        p_data.line.partial_trg = it_scope:partial(3)
        p_data.line.partial_cnt = (p_data.cnt_type == "scope" and it_content_tree:partial(3)) or nil
        p_data.line = proc_data_prep_1(p_data.line, it_scope)

        local partial_trg = p_data.line.partial_trg
        local partial_cnt = p_data.line.partial_cnt

        for line_index = p_data.line.loop.s_trg, p_data.line.loop.e_trg, p_data.line.loop.d_trg do
            repeat --faux repeat wrap
                -- Set target cursor
                p_data.line.trg_i = line_index
                --o2 = Track object, o = pattern_track -object
                p_data.line.trg_o = set_line(p_data.line.trg_i, p_data.track.trg_o)
                -- Set content cursor
                p_data.line.cnt_o, p_data.line.cnt_i = nil, nil
                --local apply_trk, apply_pat_trk, apply_trk_i = nil, nil

                if p_data.cnt_type == "scope" then
                    local _ = p_data.line
                    _.cnt_i = scale_it_index(_.loop.s_trg, _.loop.e_trg, _.trg_i, _.loop.s_cnt, _.loop.e_cnt)
                    _.cnt_o = p_data.track.cnt_o:line(_.cnt_i)
                end

                --Check if rules to skip altogether apply
                --No rules yet
                
                --Check if rules to skip this index apply
                local skip_this = false
                if p_data.line.skip_empty then
                    skip_this = songdata_object_is_empty(p_data.line.trg_o, "line") or (p_data.line.cnt_o and songdata_object_is_empty(p_data.line.cnt_o, "line"))
                end
                --More rules
                --More rules
                --Single index skip rules end: breakpoint
                if skip_this then
                    process_log:entry("Skipped a single line index.")
                    --Use break to skip an index, jumps outside the repeat wrap
                    break
                end
                --Past this index breakpoint

                --This level terminal
                level_terminal(p_data.line, it_scope, it_content, columns_loop)
            until true --end faux repeat wrap
        end --for loop
    end
    local function tracks_loop()
        --THIS is called from pattern_level loop terminal
        --setup p_data
        p_data.track = table.create()
        p_data.track.partial_trg = it_scope:partial(2)
        p_data.track.partial_cnt = (p_data.cnt_type == "scope" and it_content_tree:partial(2)) or nil
        local partial_trg = p_data.track.partial_trg
        local partial_cnt = p_data.track.partial_cnt
        --CHECK method (track/group)
        if partial_trg.name == "trackgroup" or (partial_cnt and partial_cnt.name == "trackgroup") then
            not_implemented("trackgroup")
        end
        --Else it's all A-ok
        p_data.track = proc_data_prep_1(p_data.track, it_scope)



        for track_index = p_data.track.loop.s_trg, p_data.track.loop.e_trg, p_data.track.loop.d_trg do
            repeat --faux repeat wrap

                -- Set target cursor
                p_data.track.trg_i = track_index
                --o2 = Track object, o = pattern_track -object
                p_data.track.trg_o2, p_data.track.trg_o = set_track(p_data.track.trg_i, p_data.pattern.trg_o)
                --was: edit_pat = ...
                -- Set content cursor
                p_data.track.cnt_o, p_data.track.cnt_o2, p_data.track.cnt_i = nil, nil
                --local apply_trk, apply_pat_trk, apply_trk_i = nil, nil
                
                --Get track type
                p_data.track.this_track_type = p_data.track.trg_o2.type

                if p_data.cnt_type == "scope" then
                    local _ = p_data.track
                    _.cnt_i = scale_it_index(_.loop.s_trg, _.loop.e_trg, _.trg_i, _.loop.s_cnt, _.loop.e_cnt)
                    _.cnt_o = p_data.pattern.cnt_o:track(_.cnt_i)
                    _.cnt_o2 = rs:track(_.cnt_i)
                end

                --Check if rules to skip altogether apply
                --No rules yet
                
                --Check if rules to skip this index apply
                local skip_this = false
                if p_data.track.skip_empty then
                    skip_this = songdata_object_is_empty(p_data.track.trg_o, "track") or (p_data.track.cnt_o and songdata_object_is_empty(p_data.track.cnt_o, "track"))
                end
                --More rules
                --More rules
                --Single index skip rules end: breakpoint
                if skip_this then
                    process_log:entry("Skipped a single track index.")
                    --Use break to skip an index, jumps outside the repeat wrap
                    break
                end
                --Past this index breakpoint

                --This level terminal
                level_terminal(p_data.track, it_scope, it_content, lines_loop)

            until true --end faux repeat wrap
        end --for loop
    end
    ----------------------------------------
    --THE OUTER LOOPS
    ----------------------------------------
    --This is basically the same as the inner loops above.
    --This is just not wrapped into a function, as this is
    --the outermost loop shell, starting the run.
    --
    --TODO:the seq kind
    --setup

    ----------------------------------------
    -- PATTERNS SETUP
    ----------------------------------------

    --Setup level partials
    p_data.pattern = table.create()
    p_data.pattern.partial_trg = it_scope:partial(1)
    p_data.pattern.partial_cnt = (p_data.cnt_type == "scope" and it_content_tree:partial(1)) or nil
    --Get level method
    p_data.outer_loop_type = p_data.pattern.partial_trg.name
    process_log:entry("outer_loop_type:"..(p_data.outer_loop_type or "nil"))
    --Check if supported outer_loop_type
    p_data.implemented_outer_loops = {
        "pattern",
        "sequence"
    }
    if not table.find(p_data.implemented_outer_loops, p_data.outer_loop_type) then
        not_implemented("Section loop.")
    end
    --[[
    if p_data.outer_loop_type ~= "pattern" then
        not_implemented("Any pattern level loop that is not 'pattern'.")
    end
    --]]
    --Prepare level data
    p_data.pattern = proc_data_prep_1(p_data.pattern, it_scope)

    ----------------------------------------
    -- PATTERNS LOOP
    ----------------------------------------
    --for pattern_index = pattern_start, pattern_end, pattern_dir_step do
    for pattern_index = p_data.pattern.loop.s_trg, p_data.pattern.loop.e_trg, p_data.pattern.loop.d_trg do
        repeat --"faux" repeat wrap for skipping a single index with a "break" -statement
            ----------------------------------------
            -- THIS PATTERN ROUND SETUP
            ----------------------------------------
            --


            if p_data.outer_loop_type == "pattern" then
                ---------------------------------------------
                -- THIS PATTERN (LOOP METHOD 'PATTERN') SETUP
                ---------------------------------------------
                -- Set target cursor
                p_data.pattern.trg_i = pattern_index
                p_data.pattern.trg_o = set_pattern(p_data.pattern.trg_i)
                -- Set content cursor
                p_data.pattern.cnt_o, p_data.pattern.cnt_i = nil, nil

                --TODO:GENERALIZE THIS!
                if p_data.cnt_type == "scope" then
                    local _ = p_data.pattern
                    _.cnt_i = scale_it_index(_.loop.s_trg, _.loop.e_trg, _.trg_i, _.loop.s_cnt, _.loop.e_cnt)
                    _.cnt_o = rs:pattern(p_data.pattern.cnt_i)
                end

                --Check if rules to skip altogether apply
                --No rules yet

                --Check if rules to skip this index apply
                local skip_pattern = false
                if p_data.pattern.skip_empty then
                    skip_pattern = songdata_object_is_empty(p_data.pattern.trg_o, "pattern") or (p_data.pattern.cnt_o and songdata_object_is_empty(p_data.pattern.cnt_o, "pattern"))
                end
                --More rules
                --More rules
                --
                --Single index skip rules end: breakpoint
                if skip_pattern then
                    process_log:entry("Skipped a single pattern index.")
                    --Use break to skip an index, jumps outside the repeat wrap
                    break
                end
                --Past this index breakpoint

                --This level terminal
                level_terminal(p_data.pattern, it_scope, it_content, tracks_loop)

            elseif p_data.outer_loop_type == "sequence" then
                ---------------------------------------------
                -- THIS PATTERN (LOOP METHOD 'SEQUENCE') SETUP
                ---------------------------------------------
                -- Set target cursor
                p_data.pattern.trg_i = pattern_index
                p_data.pattern.trg_o = set_sequence(p_data.pattern.trg_i)
                -- Set content cursor
                p_data.pattern.cnt_o, p_data.pattern.cnt_i = nil, nil
                
                --TODO:GENERALIZE THIS!
                if p_data.cnt_type == "scope" then
                    local _ = p_data.pattern
                    _.cnt_i = scale_it_index(_.loop.s_trg, _.loop.e_trg, _.trg_i, _.loop.s_cnt, _.loop.e_cnt)
                    _.cnt_o = rs.sequencer:pattern(p_data.pattern.cnt_i)
                end

                --Check if rules to skip altogether apply
                --No rules yet

                --Check if rules to skip this index apply
                local skip_pattern = false
                if p_data.pattern.skip_empty then
                    skip_pattern = songdata_object_is_empty(p_data.pattern.trg_o, "pattern") or (p_data.pattern.cnt_o and songdata_object_is_empty(p_data.pattern.cnt_o, "pattern"))
                end
                --More rules
                --More rules
                --
                --Single index skip rules end: breakpoint
                if skip_pattern then
                    process_log:entry("Skipped a single sequence index.")
                    --Use break to skip an index, jumps outside the repeat wrap
                    break
                end
                --Past this index breakpoint

                --Sequence loop specialty: if content is not nil,
                --make pattern in current sequence unique
                --TODO TODO TODO: if p_data.cnt_type ==
                

                --This level terminal
                level_terminal(p_data.pattern, it_scope, it_content, tracks_loop)

            elseif p_data.outer_loop_type == "section" then
                ---------------------------------------------
                -- THIS PATTERN (LOOP METHOD 'SECTION') SETUP
                ---------------------------------------------
                --"sequence" outer loop functions
                not_implemented("section scopetag")
            else
                --unhandled outer loop, SHOULD never happen.
                vader_error("Unhandled outer loop type.")
            end

            -- Make selection in pattern, if flag set
            if vader.PROCESS_MAKE_SELECTION then
                --[[
                rprint(p_data)--debug
                rs.selection_in_pattern.start_line = (p_data.line and p_data.line.loop.s_trg) or 1
                rs.selection_in_pattern.end_line = (p_data.line and p_data.line.loop.e_trg) or rs.selected_pattern.number_of_lines
                rs.selection_in_pattern.start_track = p_data.track.loop.s_trg
                rs.selection_in_pattern.end_track = p_data.track.loop.e_trg
                --]]
                local lnroot = p_data.line
                local trroot = p_data.track
                rs.selection_in_pattern= {
                ["start_line"] = (lnroot and math.min(lnroot.loop.s_trg, lnroot.loop.e_trg)) or 1,
                ["end_line"] = (lnroot and math.max(lnroot.loop.s_trg, lnroot.loop.e_trg)) or rs.selected_pattern.number_of_lines,
                ["start_track"] = (trroot and math.min(trroot.loop.s_trg, trroot.loop.e_trg)) or 1,
                ["end_track"] = (trroot and math.max(trroot.loop.s_trg, trroot.loop.e_trg)) or #rs.tracks,
                }
                process_log:entry("Made a selection over target area")
            end
        until true --faux repeat wrap end.
    end

    -- All loops run through now.
    -- Finalizing stage.

    -- Set loop start and end if flag set
    if vader.PROCESS_MAKE_LOOP then
        --[[
        rprint(p_data)--debug
        rs.selection_in_pattern.start_line = (p_data.line and p_data.line.loop.s_trg) or 1
        rs.selection_in_pattern.end_line = (p_data.line and p_data.line.loop.e_trg) or rs.selected_pattern.number_of_lines
        rs.selection_in_pattern.start_track = p_data.track.loop.s_trg
        rs.selection_in_pattern.end_track = p_data.track.loop.e_trg
        --]]
        not_implemented("Set loop on target range")
    end

    --[[
    print("Cursor dropped at:")
    vader.cursor:dump()--debug
    --]]
    
    -- No errors. Processing is simply a success.
    process_log:entry("success.")

    -- Get info stored
    vader.logs.main:join_log(process_log:compress())

    -- Get back
    return it_content or true
end
