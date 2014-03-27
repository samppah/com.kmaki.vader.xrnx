--
--lexicon.lua
--
----------------------------------------------------
-- file created         08-Jan-2012


-- Data for parsing


----------------------------------------------------
-- Globals declaration, initialization
----------------------------------------------------

-- Project wide globals (local representation)
local vader = get_tool_root_node()
local rs 

----------------------------------------------------
-- Boot procedure, initialization
----------------------------------------------------

function boot_lexicon(main_vader)
    -- Project Globals
    rs = get_rs()
    vader = main_vader
end

----------------------------------------------------
-- Data retrieving functions and data
----------------------------------------------------

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

function solve_lookup(solve_atom)
    -- This solves a solve atom, by a table lookup
    -- which can be a single value or a binary operation with two values

    local process_title = "solve_lookup()"
    local processing_error = ""
    local processing_notes = table.create()

    local solve_function
    local solve_operators = {}

    --Look up the solving function
    local solve_key


    --Get arguments for solving function (depending on the solve type)
    if #solve_atom == 1 then
        -- It's a single value lookup
        solve_key = solve_atom:item(1).token_type
        if solve_key == "<nest>" or solve_key == "<binary nest>" then
        --if solve_key == "<nest>" or solve_key == "<binary nest>" and solve_atom.resolved == nil then --NOTE: TOOK THIS OFF 26.2.2012. SEEMED CRAZY. AND BREAKS DYNAMIC VALUE APPLYING. FOR SOME REASON.:wa
            -- Has to be a case of nest within a nest. Just get subnest value.
            return solve_atom:branch(1).resolved
        end
        if solve_key == "<digit>" then
            -- A digit, pass the token string:
            solve_operators = {solve_atom:item(1).string}
        elseif solve_key:find("<scopetag ") then
            -- A scopetag, pass the implied scope
            solve_key = "<value current>"
            if not solve_atom.scope then
                --get scope!
                local scope_string = string.sub(solve_atom:item(1).token_type, 11, string.find(solve_atom:item(1).token_type,"[ >]",11)-1) 
                solve_atom.scope = scope_string
            end
            solve_operators = {solve_atom.scope}
            vader_assert(#solve_operators > 0, "Could not pass scope for solving a scope tag <value current> atom")

        elseif solve_key == ("<value current>") or solve_key == ("<symbol min>") or solve_key == ("<symbol max>") or solve_key == ("<symbol empty>") then
            solve_operators = {solve_atom.scope}
        else
            -- It's an unidentified single item lookup!
            -- TODO: error this
        end
    elseif #solve_atom == 3 then
        -- It's a binary operation
        --[[
        print("ATOM")
        solve_atom:dump_recursive()--debug
        print("OP1")
        solve_atom:branch(1):dump()
        print("OP2")
        solve_atom:branch(3):dump()
        --]]

        solve_key = solve_atom:item(2).token_type
        solve_operators = {solve_atom:branch(1).resolved or solve_lookup(solve_atom:branch(1)), solve_atom:branch(3).resolved or solve_lookup(solve_atom:branch(3))}
        vader_assert(solve_operators[1] and solve_operators[2], "Could not find resolved values for both operators of a binary operation.")
        --vader.logs.debug:entry("Assigned operators for a binary! await solve_atom TokenTree dump:", 10)
    end

    -- The basic principle illustrated
    if solve_key then
        --vader.logs.debug:entry("Looking up a solve function for the solve key:"..solve_key, 5)
        solve_function = vader.lex.solve_lookup_table[solve_key] 
    else
        --it's a very simple operation solved ad hoc
    end

    if #solve_operators == 0 then
        -- Unidentified lookup! Could not assign the operators!
        processing_error =     "Assigned 0 operators because could not recognize the solve key:"..(solve_key or "nil").." in "..#solve_atom.." items long solve_atom. Solve atom .resolved was:"..(solve_atom.resolved or "nil")
        --vader.logs.debug:entry("Assigned 0 operators because could not recognize the solve key:"..solve_key.." in "..#solve_atom.." items long solve_atom:")
        --solve_atom:dump_recursive()--debug
        return false, process_title..vader.LOG_DEFAULT_SEPARATOR..processing_error, nil
    end

    local resolved = solve_function(unpack(solve_operators))
    --print("solved an atom with result:", resolved)--debug
    return resolved, nil, processing_notes
end

--TODO: make this work with vader.lex.songdata_codex
vader.lex.solve_lookup_table = {
    --DIGITS
    ["<digit>"] = function(token_string)
        return tonumber(token_string)
    end,

    --VALUE CURRENT
    ["<value current>"] = function(scope)
        if scope == "pattern" then
            return (vader.cursor and vader.cursor.pattern) or rs.selected_pattern_index
        elseif scope == "sequence" then
            return (vader.cursor and vader.cursor.sequence) or rs.selected_sequence_index
        elseif scope == "section" then
            --TODO!!!
            --compatibility placeholder with current pattern return
            return (vader.cursor and vader.cursor.pattern) or rs.selected_pattern_index
        elseif scope == "track" then
            return (vader.cursor and vader.cursor.track) or rs.selected_track_index
        elseif scope == "trackgroup" then
            --TODO!!!
            --compatibility placeholder with current track return
            return (vader.cursor and vader.cursor.track) or rs.selected_track_index
        elseif scope == "line" then
            return (vader.cursor and vader.cursor.line) or rs.transport.edit_pos.line
        elseif scope == "column" then
            if rs.selected_note_column_index then
                return (vader.cursor and vader.cursor.note_column) or rs.selected_note_column_index
            else
                return (vader.cursor and vader.cursor.effect_column) or rs.selected_effect_column_index --maybe with added the note_col_index?
            end
            --[[
        elseif scope == "notecolumn" then
            return (vader.cursor and vader.cursor.note_column) or rs.selected_note_column_index
        elseif scope == "effectcolumn" then
            return (vader.cursor and vader.cursor.effect_column) or rs.selected_effect_column_index
            --]]
        elseif scope == "note_column" then
            return (vader.cursor and vader.cursor.note_column) or rs.selected_note_column_index
        elseif scope == "effect_column" then
            return (vader.cursor and vader.cursor.effect_column) or rs.selected_effect_column_index
        elseif scope == "note_value" then
            if rs.selected_note_column == nil then
                return 0
            else
                return get_selected("note_column").note_value
            end
        elseif scope == "instrument_value" then
            if rs.selected_note_column == nil then
                return 0
            else
                return get_selected("note_column").instrument_value
            end
        elseif scope == "volume_value" then
            if rs.selected_note_column == nil then
                return 0
            else
                return get_selected("note_column").volume_value
            end
        elseif scope == "panning_value" then
            if rs.selected_note_column == nil then
                return 0
            else
                return get_selected("note_column").panning_value
            end
        elseif scope == "delay_value" then
            if rs.selected_note_column == nil then
                return 0
            else
                return get_selected("note_column").delay_value
            end
        elseif scope == "effectnumber" then
            if rs.selected_effect_column == nil then
                return 0
            else
                return get_selected("effect_column").number_value
            end
        elseif scope == "effectamount" then
            if rs.selected_effect_column == nil then
                return 0
            else
                return get_selected("effect_column").amount_value
            end
        end
    end,

    --VALUE MIN
    ["<symbol min>"] = function(scope)
        if scope == "pattern" then
            return 1
        elseif scope == "sequence" then
            return 1
        elseif scope == "section" then
            --TODO!!
            --compatibility placeholder from sequence
            return 1
        elseif scope == "track" then
            return 1
        elseif scope == "trackgroup" then
            --TODO!!
            --compatibility placeholder from track
            return 1
        elseif scope == "line" then
            return 1
        elseif scope == "column" then
            if rs.selected_note_column_index then
                return 1
            else
                return 1
            end
            --[[
        elseif scope == "notecolumn" then
            local is_seq = (rs.selected_track_index < rs.sequencer_track_count)
            local notecol_min
            if is_seq then
                notecol_min = 1
            else
                notecol_min = 0
            end
            return notecol_min
        elseif scope == "effectcolumn" then
            return 1
            --]]
        elseif scope == "note_column" then
            local is_seq = (rs.selected_track_index < rs.sequencer_track_count)
            local notecol_min
            if is_seq then
                notecol_min = 1
            else
                notecol_min = 0
            end
            return notecol_min
        elseif scope == "effect_column" then
            return 1
        elseif scope == "note_value" then
            return 0 
        elseif scope == "instrument_value" then
            return #rs.instruments
        elseif scope == "volume_value" then
            return 0
        elseif scope == "panning_value" then
            return 0
        elseif scope == "delay_value" then
            return 0
        elseif scope == "effectnumber" then
            not_implemented("relative values for effect subcolumn data")
            return --TODO: what here?
        elseif scope == "effectamount" then
            not_implemented("relative values for effect subcolumn data")
            return --TODO: what here?
        end
    end,

    --VALUE MAX
    ["<symbol max>"] = function(scope)
        if scope == "pattern" then
            return #rs.patterns
        elseif scope == "sequence" then
            return #rs.sequencer.pattern_sequence
        elseif scope == "section" then
            --TODO!!
            --compatibility placeholder from sequence
            return #rs.sequencer.pattern_sequence
        elseif scope == "track" then
            return rs.sequencer_track_count + rs.send_track_count + 1 --the 1 is master
        elseif scope == "trackgroup" then
            --TODO!!
            --compatibility placeholder from track
            return rs.sequencer_track_count + rs.send_track_count + 1 --the 1 is master
        elseif scope == "line" then
            return rs.selected_pattern.number_of_lines
        elseif scope == "column" then
            --TODO:this does not always work now! GROUP TRACKS!
            local seq_track=rs:track(1)
            if rs.selected_note_column_index then
                return seq_track.visible_note_columns --TODO:max no of notecolumns
            else
                return seq_track.visible_effect_columns --TODO:max no of effect columns
            end
            --[[
        elseif scope == "notecolumn" then
            --TODO:this does not always work now! GROUP TRACKS!
            local seq_track=rs:track(1)
            return seq_track.visible_note_columns --TODO:max no of notecolumns
        elseif scope == "effectcolumn" then
            --TODO:this does not always work now! GROUP TRACKS!
            local seq_track=rs:track(1)
            return seq_track.visible_effect_columns --TODO:max no of effect columns
            --]]
        elseif scope == "note_column" then
            --TODO:this does not always work now! GROUP TRACKS!
            local seq_track=rs:track(1)
            return seq_track.visible_note_columns --TODO:max no of notecolumns
        elseif scope == "effect_column" then
            --TODO:this does not always work now! GROUP TRACKS!
            local seq_track=rs:track(1)
            return seq_track.visible_effect_columns --TODO:max no of effect columns
        elseif scope == "note_value" then
            return 119 
        elseif scope == "instrument_value" then
            return #rs.instruments
        elseif scope == "volume_value" then
            return 127 
        elseif scope == "panning_value" then
            return 127
        elseif scope == "delay_value" then
            return 255
        elseif scope == "effectnumber" then
            not_implemented("relative values for effect subcolumn data")
            return --TODO: what here?
        elseif scope == "effectamount" then
            not_implemented("relative values for effect subcolumn data")
            return --TODO: what here?
        end
    end,

    --VALUE EMPTY
    ["<symbol empty>"] = function(scope)
        if scope == "pattern" then
            return "CLEAR_OBJECT"
        elseif scope == "sequence" then
            return "CLEAR_OBJECT"
        elseif scope == "track" then
            return "CLEAR_OBJECT"
        elseif scope == "line" then
            return "CLEAR_OBJECT"
        elseif scope == "column" then
            --TODO
            --TODO:this does not always work now! GROUP TRACKS!
            --[[
            local seq_track=rs:track(1)
            if rs.selected_note_column_index then
                return seq_track.max_note_columns --TODO:max no of notecolumns
            else
                return seq_track.max_effect_columns --TODO:max no of effect columns
            end
            --]]
            return
            --[[
        elseif scope == "notecolumn" then
            --TODO
            --TODO:this does not always work now! GROUP TRACKS!
            --local seq_track=rs:track(1)
            --return seq_track.max_note_columns --TODO:max no of notecolumns
            return "CLEAR_OBJECT"
        elseif scope == "effectcolumn" then
            --TODO:this does not always work now! GROUP TRACKS!
            --TODO
            --local seq_track=rs:track(1)
            --return seq_track.max_effect_columns --TODO:max no of effect columns
            return "CLEAR_OBJECT"
            --]]
        elseif scope == "note_column" then
            --TODO
            --TODO:this does not always work now! GROUP TRACKS!
            --local seq_track=rs:track(1)
            --return seq_track.max_note_columns --TODO:max no of notecolumns
            return "CLEAR_OBJECT"
        elseif scope == "effect_column" then
            --TODO:this does not always work now! GROUP TRACKS!
            --TODO
            --local seq_track=rs:track(1)
            --return seq_track.max_effect_columns --TODO:max no of effect columns
            return "CLEAR_OBJECT"
        elseif scope == "note_value" then
            return 121
        elseif scope == "instrument_value" then
            return 255
        elseif scope == "volume_value" then
            return 255
        elseif scope == "panning_value" then
            return 255
        elseif scope == "delay_value" then
            return 0
        elseif scope == "effectnumber" then
            return 0
        elseif scope == "effectamount" then
            return 0
        end
    end,

    --BINARY OPS
    ["<binary op mul>"] = function(op1,op2)
        return op1*op2
    end,
    ["<binary op div>"] = function(op1,op2)
        return op1/op2
    end,
    ["<binary op sum>"] = function(op1,op2)
        return op1+op2
    end,
    ["<binary op sub>"] = function(op1,op2)
        return op1-op2
    end,
}

vader.lex.songdata_codex = {
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
    ["section"] = {
    },
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
    ["group"] = {
    },
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
    ["panning_value"] = {
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
    ["effectnumber"] = {
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
    ["effectamount"] = {
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

----------------------------------------------------
-- Syntax data
----------------------------------------------------

vader.lex.msg_template = {
        ["cmd_def"] = {
            ["target_def"] = {
                ["target"] = {
                },
                ["target_mcrdef"] = {
                },
                ["target_flagdef"] = {
                }
            },
            ["content_def"] = {
                ["content"] = {
                },
                ["content_mcrdef"] = {
                },
                ["content_flagdef"] = {
                }
            },
            ["cmd_mcrdef"] = {
            }
        }, 
        ["glob_mcrdef"] = {
        },
        ["glob_flagdef"] = {
        }
}

vader.lex.tokens = {
    -- Tokens and tokenize data format
    
    --[[

    token_name = {priority, match start character length {start_match_pattern, more_method, more_match_pattern, end_match_pattern}, {properties}}

    priority: if two similar length matches, the one with priority closer to 1 wins (1 wins 3, 4 wins 10 etc.)
    match start character length: the LITERAL length of the start_match_pattern. cannot be derived from the actual start_match_pattern
    more_method: if a number of further characters is to be added into this token, this controls the method of adding. the format is "xn" where x is the method (+, =) and n is the count. + method tries to find matches with the more_match_pattern. = tries to match the exact same string as was found.
    more_match_pattern: see above
    end_match_pattern. not implemented. 
    
    --]]
    
    ["<nest char open>"]                    ={1,  1,  {"%("},},
    ["<nest char close>"]                   ={1,  1,  {"%)"},},

    ["<prfx addt msg>"]                     ={1,  1,  {"%;"},},
    ["<prfx cnt>"]                          ={1,  1,  {"%:"},},
    ["<prfx mcr>"]                          ={1,  1,  {"%@",        "+0",  "[%_a]",},},
    --["<prfx glob flg>"]                     ={1,  2,  {"% %-",},},

    ["<binary op mul>"]                     ={1,  1,  {"%*"},{"is binary op"}},
    ["<binary op div>"]                     ={1,  1,  {"%/"},{"is binary op"}},
    ["<binary op sum>"]                     ={1,  1,  {"%+"},{"is binary op"}},
    ["<binary op sum double>"]              ={1,  2,  {"%+%+"},{"is binary op"}},
    ["<binary op sub>"]                     ={2,  1,  {"%-"},{"is binary op"}},
    ["<binary op sub double>"]              ={2,  2,  {"%-%-"},{"is binary op"}},

    ["<comparison op greater>"]             ={1,  1,  {"%>"},},
    ["<comparison op less>"]                ={1,  1,  {"%<"},},
    ["<comparison op equals>"]              ={1,  2,  {"%=%="},},
    ["<comparison op equals or less>"]      ={1,  2,  {"%<%="},},
    ["<comparison op equals or greater>"]   ={1,  2,  {"%>%="},},

    ["<scopetag sequence>"]                 ={1,  1,  {"q"},{"is scopetag", "pattern_level",      "resolvable to value", "resolvable to range"}},
    ["<scopetag section>"]                  ={1,  1,  {"s"},{"is scopetag", "pattern_level",      "resolvable to value", "resolvable to range"}},
    ["<scopetag pattern>"]                  ={1,  1,  {"p"},{"is scopetag", "pattern_level",      "resolvable to value", "resolvable to range"}},
    ["<scopetag trackgroup>"]               ={1,  1,  {"g"},{"is scopetag", "track_level",        "resolvable to value", "resolvable to range"}},
    ["<scopetag track>"]                    ={1,  1,  {"t"},{"is scopetag", "track_level",        "resolvable to value", "resolvable to range"}},
    ["<scopetag line>"]                     ={1,  1,  {"l"},{"is scopetag", "line_level",         "resolvable to value", "resolvable to range"}},
    --["<scopetag notecolumn>"]               ={1,  1,  {"c"},{"is scopetag", "column_level",       "resolvable to value", "resolvable to range"}},
    --["<scopetag effectcolumn>"]             ={1,  1,  {"e"},{"is scopetag", "column_level",       "resolvable to value", "resolvable to range"}},
    ["<scopetag note_column>"]              ={1,  1,  {"c"},{"is scopetag", "column_level",       "resolvable to value", "resolvable to range"}},
    ["<scopetag effect_column>"]            ={1,  1,  {"e"},{"is scopetag", "column_level",       "resolvable to value", "resolvable to range"}},
    ["<scopetag note_value>"]                ={1,  1,  {"n"},{"is scopetag", "subcolumn_level_note",  "resolvable to value", "resolvable to range"}},
    ["<scopetag instrument_value>"]          ={1,  1,  {"i"},{"is scopetag", "subcolumn_level_note",  "resolvable to value", "resolvable to range"}},
    ["<scopetag volume_value>"]              ={1,  1,  {"v"},{"is scopetag", "subcolumn_level_note",  "resolvable to value", "resolvable to range"}},
    ["<scopetag panning_value>"]             ={1,  1,  {"a"},{"is scopetag", "subcolumn_level_note",  "resolvable to value", "resolvable to range"}},
    ["<scopetag delay_value>"]               ={1,  1,  {"d"},{"is scopetag", "subcolumn_level_note",  "resolvable to value", "resolvable to range"}},
    ["<scopetag effectnumber>"]             ={1,  1,  {"f"},{"is scopetag", "subcolumn_level_effect", "resolvable to value", "resolvable to range"}},
    ["<scopetag effectamount>"]             ={1,  1,  {"x"},{"is scopetag", "subcolumn_level_effect", "resolvable to value", "resolvable to range"}},

    ["<scopetag sequence double>"]          ={1,  2,  {"qq"},{"is scopetag", "pattern_level",      "resolvable to range",}},
    ["<scopetag section double>"]           ={1,  2,  {"ss"},{"is scopetag", "pattern_level",      "resolvable to range",}},
    ["<scopetag pattern double>"]           ={1,  2,  {"pp"},{"is scopetag", "pattern_level",      "resolvable to range",}},
    ["<scopetag trackgroup double>"]        ={1,  2,  {"gg"},{"is scopetag", "track_level",        "resolvable to range",}},
    ["<scopetag track double>"]             ={1,  2,  {"tt"},{"is scopetag", "track_level",        "resolvable to range",}},
    ["<scopetag line double>"]              ={1,  2,  {"ll"},{"is scopetag", "line_level",         "resolvable to range",}},
    --["<scopetag notecolumn double>"]        ={1,  2,  {"cc"},{"is scopetag", "column_level",       "resolvable to range",}},
    --["<scopetag effectcolumn double>"]      ={1,  2,  {"ee"},{"is scopetag", "column_level",       "resolvable to range",}},
    ["<scopetag note_column double>"]       ={1,  2,  {"cc"},{"is scopetag", "column_level",       "resolvable to range",}},
    ["<scopetag effect_column double>"]     ={1,  2,  {"ee"},{"is scopetag", "column_level",       "resolvable to range",}},
    ["<scopetag note_value double>"]         ={1,  2,  {"nn"},{"is scopetag", "subcolumn_level_note",  "resolvable to range",}},
    ["<scopetag instrument_value double>"]   ={1,  2,  {"ii"},{"is scopetag", "subcolumn_level_note",  "resolvable to range",}},
    ["<scopetag volume_value double>"]       ={1,  2,  {"vv"},{"is scopetag", "subcolumn_level_note",  "resolvable to range",}},
    ["<scopetag panning_value double>"]      ={1,  2,  {"aa"},{"is scopetag", "subcolumn_level_note",  "resolvable to range",}},
    ["<scopetag delay_value double>"]        ={1,  2,  {"dd"},{"is scopetag", "subcolumn_level_note",  "resolvable to range",}},
    ["<scopetag effectnumber double>"]      ={1,  2,  {"ff"},{"is scopetag", "subcolumn_level_effect","resolvable to range",}},
    ["<scopetag effectamount double>"]      ={1,  2,  {"xx"},{"is scopetag", "subcolumn_level_effect","resolvable to range",}},

    ["<scopetag sequence upper>"]           ={1,  1,  {"Q"},{"is scopetag", "pattern_level",      "resolvable to range",}},
    ["<scopetag section upper>"]            ={1,  1,  {"S"},{"is scopetag", "pattern_level",      "resolvable to range",}},
    ["<scopetag pattern upper>"]            ={1,  1,  {"P"},{"is scopetag", "pattern_level",      "resolvable to range",}},
    ["<scopetag trackgroup upper>"]         ={1,  1,  {"G"},{"is scopetag", "track_level",        "resolvable to range",}},
    ["<scopetag track upper>"]              ={1,  1,  {"T"},{"is scopetag", "track_level",        "resolvable to range",}},
    ["<scopetag line upper>"]               ={1,  1,  {"L"},{"is scopetag", "line_level",         "resolvable to range",}},
    --["<scopetag notecolumn upper>"]         ={1,  1,  {"C"},{"is scopetag", "column_level",       "resolvable to range",}},
    --["<scopetag effectcolumn upper>"]       ={1,  1,  {"E"},{"is scopetag", "column_level",       "resolvable to range",}},
    ["<scopetag note_column upper>"]        ={1,  1,  {"C"},{"is scopetag", "column_level",       "resolvable to range",}},
    ["<scopetag effect_column upper>"]      ={1,  1,  {"E"},{"is scopetag", "column_level",       "resolvable to range",}},
    ["<scopetag note_value upper>"]          ={1,  1,  {"N"},{"is scopetag", "subcolumn_level_note",  "resolvable to range",}},
    ["<scopetag instrument_value upper>"]    ={1,  1,  {"I"},{"is scopetag", "subcolumn_level_note",  "resolvable to range",}},
    ["<scopetag volume_value upper>"]        ={1,  1,  {"V"},{"is scopetag", "subcolumn_level_note",  "resolvable to range",}},
    ["<scopetag panning_value upper>"]       ={1,  1,  {"A"},{"is scopetag", "subcolumn_level_note",  "resolvable to range",}},
    ["<scopetag delay_value upper>"]         ={1,  1,  {"D"},{"is scopetag", "subcolumn_level_note",  "resolvable to range",}},
    ["<scopetag effectnumber upper>"]       ={1,  1,  {"F"},{"is scopetag", "subcolumn_level_effect","resolvable to range",}},
    ["<scopetag effectamount upper>"]       ={1,  1,  {"X"},{"is scopetag", "subcolumn_level_effect","resolvable to range",}},

    ["<symbol min>"]                        ={1,  1,  {"%_"},{"resolvable to value w context",}},
    ["<symbol max>"]                        ={1,  1,  {'%"'},{"resolvable to value w context",}},
    ["<symbol empty>"]                      ={1,  1,  {"%o"},{"resolvable to value w context", "is range flag"}},
    ["<symbol visible>"]                    ={1,  1,  {"%´"},{"resolvable to range w context", "is range flag"}},
    ["<symbol non_empty>"]                  ={1,  1,  {"%'"},{"resolvable to range w context", "is range flag"}},
    ["<symbol inverse>"]                    ={1,  1,  {"%!"},{"is range flag"}},
    ["<symbol random>"]                     ={1,  1,  {"%?"},{"resolvable to value",}},

    ["<digit>"]                             ={2,  1,  {"%d",     "+0",},{"resolvable to value",}},
    --["<digit hex>"]                         ={2,  1,  {"%x",     "+0",},{"resolvable to value",}},
    ["<digit hex>"]                         ={1,  2,  {"0x",     "+0",   "%x"},{"resolvable to value",}},

    ["<whitespace>"]                        ={1,  1,  {" ",      "+0",},},

    ["<point>"]                             ={2,  1,  {"%."},   },
    ["<range appendix>"]                    ={1,  2,  {"%.%."}, },

    ["<mcr expand>"]                        ={1,  1,  {"&",      "+0",   "[_%a]",},},
    
    --Flags
    --Exit - close prompt after execution
    ["<flg exit>"]                          ={1,  6,  {" %-exit"},},
    ["<flg exit upper>"]                    ={1,  6,  {" %-EXIT"},},
    ["<flg noexit>"]                        ={1,  8,  {" %-noexit"},},
    ["<flg noexit upper>"]                  ={1,  8,  {" %-NOEXIT"},},
    ["<flg exit 2>"]                        ={1,  3,  {" %-x"},},
    ["<flg exit upper_2>"]                  ={1,  3,  {" %-X"},},
    ["<flg noexit 2>"]                      ={1,  5,  {" %-nox"},},
    ["<flg noexit upper_2>"]                ={1,  5,  {" %-NOX"},},

    --Move - move cursor when iterating
    ["<flg move>"]                          ={1,  6,  {" %-move"},},
    ["<flg move upper>"]                    ={1,  6,  {" %-MOVE"},},
    ["<flg nomove>"]                        ={1,  8,  {" %-nomove"},},
    ["<flg nomove upper>"]                  ={1,  8,  {" %-NOMOVE"},},
    ["<flg move 2>"]                        ={1,  4,  {" %-mv"},},
    ["<flg move upper 2>"]                  ={1,  4,  {" %-MV"},},
    ["<flg nomove 2>"]                      ={1,  6,  {" %-nomv"},},
    ["<flg nomove upper 2>"]                ={1,  6,  {" %-NOMV"},},

    --Select - make a selection over target range
    ["<flg select>"]                          ={1,  8,  {" %-select"},},
    ["<flg select upper>"]                    ={1,  8,  {" %-SELECT"},},
    ["<flg noselect>"]                        ={1,  10,  {" %-noselect"},},
    ["<flg noselect upper>"]                  ={1,  10,  {" %-NOSELECT"},},
    ["<flg select 2>"]                        ={1,  5,  {" %-sel"},},
    ["<flg select upper 2>"]                  ={1,  5,  {" %-SEL"},},
    ["<flg noselect 2>"]                      ={1,  8,  {" %-nosel"},},
    ["<flg noselect upper 2>"]                ={1,  8,  {" %-NOSEL"},},
}

function get_scopetag_level(scope_string)
    --This function returns the level of the scopetag or false
    vader_assert(type(scope_string) == "string", "Tried to call get_scopetag_level() with a scope_string type:"..type(scope_string)..". Use a string.")
    --Loop through all strings
    for level_index, level in ipairs(vader.lex.scope_levels) do
        --Get the level name
        for level_name, level_scopetags in pairs(level) do
            -- The "Loop" here is just to get the ONLY key(name) in the table
            if table.find(level_scopetags, scope_string) then
                return level_name, level_index
            end
        end
    end
    --Nothing has been found
    vader_error("Tried to get_scopetag_level() with unidentified scope_string:"..scope_string)
end

vader.lex.scope_levels = {
    --PATTERN LEVEL
    [1] = {
        ["pattern_level"] = {
            [1] = "pattern",
            [2] = "sequence",
            [3] = "section",
        }, 
    }, 
    --TRACK LEVEL
    [2] = {
        ["track_level"] = {
            [1] = "track",
            [2] = "trackgroup",
        }, 
    }, 
    --LINE LEVEL
    [3] = {
        ["line_level"] = {
            [1] = "line",
        }, 
    }, 
    --COLUMN LEVEL
    [4] = {
        ["column_level"] = {
            --[1] = "notecolumn",
            --[2] = "effectcolumn",
            [1] = "note_column",
            [2] = "effect_column",
        }, 
    }, 
    --SUBCOLUMN LEVEL
    [5] = {
        ["subcolumn_level_note"] = {
            [1] = "note_value",
            [2] = "instrument_value",
            [3] = "volume_value",
            [4] = "delay_value",
            [5] = "panning_value",
        }, 
    }, 
    [6] = {
        ["subcolumn_level_effect"] = {
            [1] = "effectnumber",
            [2] = "effectamount",
        }, 
    }, 
}

vader.lex.directives = {
    -- holds the internal directives syntax
    -- actually just a lookup table with functions as
    -- values, directive names as keys
    -- works together with main.lua's directives_dispatch()
    ["PARSE"] = function(directive)
        return parse(directive:arguments())
    end,
    ["PROCESS"] = function(directive)
        return process(directive:arguments())
    end,
    ["MACRO_ADD"] = function(directive)
        return register_rns_shortcut(directive:arguments())
    end,
    ["MACRO_REMOVE"] = function(directive)
        return remove_user_macro(directive:arguments())
    end
}
