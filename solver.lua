local rs = renoise.song()


local vader = get_tool_root_node()

local function get_selected(type)
    --this helper function returns selected songdata objects
    --type:pattern,pattern_track,pattern_track_line,note_column,effect_column)
    local valid_type = {
        "pattern",
        "pattern_track",
        "pattern_track_line",
        "note_column",
        "effect_column",
    }
    local level = table.find(valid_type, type)
    assert (level, "Invalid song data object type: "..type.." , cannot get reference")

    local object_to_return
    local second_object_to_return

    local this_pat
    local this_pattrack
    local this_track
    local this_pattrackline
    local this_col
    local c = vader.cursor

    --TODO:this is not used.
    local function note_or_effect_col(selected_sub_column_type)
        local sub_col_type = renoise.song().selected_sub_column_type 
        --TODO: how does vader.cursor relate to all this?
        if sub_col_type == renoise.Song.SUB_COLUMN_NOTE or
            sub_col_type == renoise.Song.SUB_COLUMN_INSTRUMENT or
            sub_col_type == renoise.Song.SUB_COLUMN_VOLUME or
            sub_col_type == renoise.Song.SUB_COLUMN_PANNING or
            sub_col_type == renoise.Song.SUB_COLUMN_DELAY then
            return "note_column"
        else
            return "effect_column"
            --[[
            renoise.Song.SUB_COLUMN_EFFECT_NUMBER
            renoise.Song.SUB_COLUMN_EFFECT_AMOUNT
            --]]
        end
    end

    if level > 0 then
        this_pat = rs:pattern((c and c.pattern) or rs.selected_pattern_index)
        if level > 1 then
            this_pattrack = this_pat:track((c and c.track) or rs.selected_track_index)
            this_track = rs:track((c and c.track) or rs.selected_track_index)
            if level > 2 then
                this_pattrackline = this_pattrack:line((c and c.line) or rs.transport.edit_pos.line)
                if level > 3 then
                    if type == "effect_column" then
                        this_col = this_pattrackline:effect_column((c and c.effect_column) or rs.selected_effect_column_index)
                    else
                        --type == "note_column"
                        this_col = this_pattrackline:note_column((c and c.note_column) or rs.selected_note_column_index)
                    end
                    object_to_return = this_col
                else
                    --level = 3
                    object_to_return = this_pattrackline
                end
            else
                --level = 2
                object_to_return = this_pattrack
                second_object_to_return = this_track
            end
        else
            --level = 1
            object_to_return = this_pat
        end
    else
        --level = 0
        object_to_return = nil
    end

    return object_to_return, second_object_to_return
end

local songdata_codex = vader.lex.songdata_codex

function solve(string, context)
    --[[
    this function resolves an "internal" value
    depending on the context the value was
    inserted in
    --]]

    local partial = context[3]

    print("function:solve(string, context)")
    print("string = " .. (string or "nil/false"))
    print("context = " .. (context[3] or "nil/false"))
    if context then
        rprint(context)
    end

    if partial == "nothing" then
        vader_error("partial == 'nothing' in solve()")
    end

    if string.find("qptlcnevda", string) then
        return songdata_codex[partial]["values"]["current"]()
    --[[

    if string == "p" then
        --current pattern
        return rs.selected_pattern_index
    elseif string == "t" then
        --current track
        return rs.selected_track_index
    elseif string == "l" then
        --current line
        return rs.transport.edit_pos.line
    elseif string == "n" then
        --current note column index
        if rs.selected_note_column_index then
            local this_pat = rs.selected_pattern
            local this_pattrack = this_pat:track(rs.selected_track_index)
            local this_pattrackline = this_pattrack:line(rs.transport.edit_pos.line)
            local this_col = this_pattrackline:note_column(rs.selected_note_column_index)
            return this_col.note_value
        else
            return 0
        end
    elseif string == "c" then
        --column index (note or effect)
        if rs.selected_note_column_index then
            return rs.selected_note_column_index
        else
            return rs.selected_effect_column_index
        end
    --]]

    --absolutes (min, max, "=" as current)
    elseif string == "_" then
        return songdata_codex[partial]["values"]["scale"]["MIN"]()

    elseif string == '"' then
        return songdata_codex[partial]["values"]["scale"]["MAX"]()
    elseif string == '=' then
        return songdata_codex[partial]["values"]["current"]()
    else
        return 0
    end
end

return solve
