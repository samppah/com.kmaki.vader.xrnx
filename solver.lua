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

local songdata_codex = {
    ["sequence"] = {
        ["values"] = {
            ["current"] = function()
                return (vader.cursor and vader.cursor.sequence) or rs.selected_sequence_index
            end,
            ["scale"] = {
                ["MIN"] = function()
                    return 1
                end,
                ["MAX"] = function()
                    return #rs.sequencer.pattern_sequence
                end,
            },
            ["special"] = {
                ["MAX_ABSOLUTE"] = function()
                    --TODO:Return number of max possible sequence slots in renoise
                end,
            }
        }
    },
    --[[
    ["section"] = {
    },
    --]]
    ["pattern"] = {
        ["values"] = {
            ["current"] = function()
                return (vader.cursor and vader.cursor.pattern) or rs.selected_pattern_index
            end,
            ["scale"] = {
                ["MIN"] = function()
                    return 1
                end,
                ["MAX"] = function()
                    return #rs.patterns
                end,
            },
            ["special"] = {
                ["MAX_ABSOLUTE"] = function()
                    --TODO:return number of absolute max patterns in renoise
                end,
            },
        },
        ["is_empty"] = function(pattern)
            return pattern.is_empty
        end,
        ["set_empty"] = function(pattern)
            pattern:clear()
            --TODO: return value?
        end,
    },
    ["track"] = {
        ["values"] = {
            ["current"] = function()
                return (vader.cursor and vader.cursor.track) or rs.selected_track_index
            end,
            ["scale"] = {
                ["MIN"] = function()
                    -- Minimum number of tracks in a song
                    return 1
                end,
                ["MAX"] = function()
                    -- Maximum (current) number of tracks
                    return #rs.tracks
                end,
            },
            ["special"] = {
                ["MAX_ABSOLUTE"] = function()
                    -- Absolute maximum number of tracks in a song
                    return math.huge
                end,
            },
        },
        ["is_empty"] = function(track)
            return track.is_empty
        end,
        ["set_empty"] = function(track)
            track:clear()
            --TODO: return value?
        end,
    },
    --[[
    ["group"] = {
    },
    --]]
    ["line"] = {
        ["values"] = {
            ["current"] = function()
                return (vader.cursor and vader.cursor.line) or rs.transport.edit_pos.line
            end,
            ["scale"] = {
                ["MIN"] = function()
                    -- Minimum number of lines in a pattern
                    return 1
                end,
                ["MAX"] = function()
                    -- (Maximum) number of lines in current pattern
                    return get_selected("pattern").number_of_lines
                end,
            },
            ["special"] = {
                ["MAX_ABSOLUTE"] = function()
                    -- Absolute maximum number of lines in a single pattern
                    return renoise.Pattern.MAX_NUMBER_OF_LINES
                end,
            },
        },
        ["is_empty"] = function(line)
            return line.is_empty
        end,
        ["set_empty"] = function(track)
            line:clear()
            --TODO: return value?
        end,
    },
    ["column"] = {
        ["values"] = {
            ["current"] = function()
                if rs.selected_note_column_index then
                    return (vader.cursor and vader.cursor.note_column) or rs.selected_note_column_index
                else
                    return (vader.cursor and vader.cursor.effect_column) or rs.selected_effect_column_index --maybe with added the note_col_index?
                end
            end
        }
    },
    ["note_column"] = {
        ["values"] = {
            ["current"] = function()
                return (vader.cursor and vader.cursor.note_column) or rs.selected_note_column_index
            end,
            ["scale"] = {
                ["MIN"] = function()
                    local pattern_track, track = get_selected("pattern_track")
                    return track.min_note_columns
                end,
                ["MAX"] = function()
                    --TODO:return number of visible note columns
                    local pattern_track, track = get_selected("pattern_track")
                    return track.visible_note_columns
                end,
            },
            ["special"] = {
                ["MAX_ABSOLUTE"] = function(track)
                    local pattern_track, track = get_selected("pattern_track")
                    return track.max_note_columns
                end,
            },
        },
        ["is_empty"] = function(note_column)
            return note_column.is_empty
        end,
        ["set_empty"] = function(note_column)
            note_column:clear()
            --TODO: return value?
        end,
    },
    ["effect_column"] = {
        ["values"] = {
            ["current"] = function()
                return (vader.cursor and vader.cursor.effect_column) or rs.selected_effect_column_index
            end,
            ["scale"] = {
                ["MIN"] = function()
                    local pattern_track, track = get_selected("pattern_track")
                    return track.min_effect_columns
                end,
                ["MAX"] = function()
                    local pattern_track, track = get_selected("pattern_track")
                    return track.visible_effect_columns
                end,
            },
            ["special"] = {
                ["MAX_ABSOLUTE"] = function()
                    local pattern_track, track = get_selected("pattern_track")
                    return track.max_effect_columns
                end,
            },
        },
        ["is_empty"] = function(effect_column)
            return effect_column.is_empty
        end,
        ["set_empty"] = function(effect_column)
            effect_column:clear()
            --TODO: return value?
        end,
    },
    ["note_value"] = {
        ["values"] = {
            ["current"] = function()
                if rs.selected_note_column == nil then
                    return 0
                else
                    return get_selected("note_column").note_value
                end
            end,
            ["scale"] = {
                ["MIN"] = function() return 0 end,
                ["MAX"] = function() return 119 end
            },
            ["special"] = {
                ["OFF"] = 120,
                ["EMPTY"] = 121,
            },
        },
        ["is_empty"] = function(note_column)
            return note_column.note_value == 121
        end,
        ["set_empty"] = function(note_column)
            note_column.note_value = 121
            --TODO: return value?
        end,
    },
    ["instrument_value"] = {
        ["values"] = {
            ["current"] = function()
                if rs.selected_note_column == nil then
                    return 0
                else
                    return get_selected("note_column").instrument_value
                end
            end,
            ["scale"] = {
                ["MIN"] = function() return 1 end,
                ["MAX"] = function() return #rs.instruments end,
            },
            ["special"] = {
                ["EMPTY"] = 255,
                ["MAX_ABSOLUTE"] = 254,
            },
        },
        ["is_empty"] = function(note_column)
            return note_column.instrument_value == 255
        end,
        ["set_empty"] = function(note_column)
            note_column.instrument_value = 255
            --TODO: return value?
        end,
    },
    ["volume_value"] = {
        ["values"] = {
            ["current"] = function()
                if rs.selected_note_column == nil then
                    return 0
                else
                    return get_selected("note_column").volume_value
                end
            end,
            ["scale"] = {
                ["MIN"] = function() return 0 end,
                ["MAX"] = function() return 127 end
            },
            ["special"] = {
                ["EMPTY"] = 255,
                --TODO: da effect shizzle...
            },
        },
        ["is_empty"] = function(note_column)
            return note_column.volume_value == 255
        end,
        ["set_empty"] = function(note_column)
            note_column.volume_value = 255
            --TODO: return value?
        end,
    },
    ["pan_value"] = {
        ["values"] = {
            ["current"] = function()
                if rs.selected_note_column == nil then
                    return 0
                else
                    return get_selected("note_column").panning_value
                end
            end,
            ["scale"] = {
                ["MIN"] = function() return 0 end,
                ["MAX"] = function() return 127 end
            },
            ["special"] = {
                ["EMPTY"] = 255,
                ["MID"] = 64,
                --TODO: da effect shizzle...
            },
        },
        ["is_empty"] = function(note_column)
            return note_column.panning_value == 255
        end,
        ["set_empty"] = function(note_column)
            note_column.panning_value = 255
            --TODO: return value?
        end,
    },
    ["delay_value"] = {
        ["values"] = {
            ["current"] = function()
                if rs.selected_note_column == nil then
                    return 0
                else
                    return get_selected("note_column").delay_value
                end
            end,
            ["scale"] = {
                ["MIN"] = function() return 0 end,
                ["MAX"] = function() return 255 end
            },
            ["special"] = {
                ["EMPTY"] = 0,
            },
        },
        ["is_empty"] = function(note_column)
            return note_column.delay_value == 0
        end,
        ["set_empty"] = function(note_column)
            note_column.delay_value = 0
            --TODO: return value?
        end,
    },
    ["effect_number"] = {
        ["values"] = {
            ["current"] = function()
                if rs.selected_effect_column == nil then
                    return 0
                else
                    return get_selected("effect_column").number_value
                end
            end,
            ["scale"] = {
                --The pattern effect range (01 - 0Z)
                ["MIN"] = function() return 0 end,
                ["MAX"] = function() return 35 end
            },
            ["special"] = {
                ["EMPTY"] = 0,
            },
            ["scale_transform"] = function(value)
                --TODO:
                --[[ the effect number scales!
                0*256 + (0 ... 35) = 00 .. 0Z
                1*256 + (0 ... 35) = 10 .. 1Z
                2*256 + (0 ... 35) = 20 .. 2Z
                ...
                35*256 + (0 ... 35) = Z0 .. ZZ 
                function()
                    return 
                end
                --]]
                --basic idea:
                --]]
            end
        },
        ["is_empty"] = function(effect_column)
            return effect_column.number_value == 0
        end,
        ["set_empty"] = function(note_column)
            effect_column.number_value = 0
            --TODO: return value?
        end,
    },
    ["effect_amount"] = {
        ["values"] = {
            ["current"] = function()
                if rs.selected_effect_column == nil then
                    return 0
                else
                    return get_selected("effect_column").amount_value
                end
            end,
            ["scale"] = {
                ["MIN"] = function() return 0 end,
                ["MAX"] = function() return 255 end
            },
            ["special"] = {
                ["EMPTY"] = 0,
            },
        },
        ["is_empty"] = function(effect_column)
            return effect_column.amount_value == 0
        end,
        ["set_empty"] = function(note_column)
            effect_column.amount_value = 0
            --TODO: return value?
        end,
    },
}
function solve(string, context)
    --[[
    this function resolves an "internal" value
    depending on the context the value was
    inserted in
    --]]

    local partial = context[3]
    --[[
    print("function:solve(string, context)")
    print("string = " .. (string or "nil/false"))
    print("context = " .. (context[3] or "nil/false"))
    if context then
        rprint(context)
    end
    --]]

    if partial == "nothing" then
        vader_error("partial == 'nothing' in solve()")
    end

    if string.find("ptlncvd", string) then
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
