--vader grammar lulpeg

local vader = nil

function boot_grammar(main_vader)
    vader = main_vader
end

--require("remdebug.engine")
--remdebug.engine.start()
--debug.start()

local lulpeg = require("LuLpeg/lulpeg")

local match = lulpeg.match
local P = lulpeg.P
local S = lulpeg.S
local R = lulpeg.R
local C = lulpeg.C
local Cb = lulpeg.Cb
local Cc = lulpeg.Cc
local Cp = lulpeg.Cp
local Ct = lulpeg.Ct
local Cg = lulpeg.Cg
local Cf = lulpeg.Cf
local Cmt = lulpeg.Cmt
local V = lulpeg.V
local L = {}
lulpeg.locale(L)

local status = "nothing"
local context = {
    "nothing", --script part (target, context, globalflags, macro
    "nothing", --scope level (pattern, track, line, column, subcolumn)
    "nothing"  --scope partial
}
local top_defined_level = {
    target = "nothing",
    content = "nothing"
}
local has_scope = {
    target = false,
    content = false
}

local last_expression_solved_value = nil --used for range definitions
local function set_last_expression_solved_value(value)
    --print("set last expression solved value: "..value)
    last_expression_solved_value = value
end

local function setcontext(target, value)
    context[target] = value
    return true
end


G = {}

--Syntax Errors
--[[
function error_(msg)
    parse_error = msg
    return P(-1) --Set this to -1 -> error whenever no match at no end of file
end
--]]

local counter_script = 0
local counter_msg = 0
local counter_msg_part = 0
local counter_scope_part = 0

function G:reset_parse_counters()
    counter_script = 0
    counter_msg = 0
    counter_msg_part = 0
    counter_scope_part = 0
end

local function ErrorCall (dummy1, dummy2, msg)
    --[[
    This is local LPeg parsing error handler. It is called from withing the
    capturing functions

    dummy1 seems to be the subject
    dummy2 is possibly the point that is tried to match
    --]]
    
    --if parse_error == "" then
        --The first error encountered is stored
      parse_error = parse_error..dummy1..", "..dummy2.."--> "..msg.."\n"
    --end
    print("------")
    --print("parse_error", parse_error)
    print("counter_script", counter_script)
    print("counter_msg", counter_msg)
    print("counter_msg_part", counter_msg_part)
    print("counter_scope_part", counter_scope_part)
    print("------")
    return false
end

local function Err (msg)
    return Cmt (Cc (msg), ErrorCall)
end

--general rules
function G:maybe(p) return p ^ -1 end
function G:either(p, q) return p + q end


--Conversions
local function note_convert(note)
    --converts a note string to note value and vice versa
    --data
    print("note_convert: ", note)
    local specials = {
        "OFF",
        "---"
    }
    local notestrings_upper = {
        "C-",
        "C#",
        "D-",
        "D#",
        "E-",
        "F-",
        "F#",
        "G-",
        "G#",
        "A-",
        "A#",
        "B-"
    }
    local notestrings_lower = {
        "c-",
        "c#",
        "d-",
        "d#",
        "e-",
        "f-",
        "f#",
        "g-",
        "g#",
        "a-",
        "a#",
        "b-"
    }
    --subfunctions nstr_to_nval and nval_to_nstr
    local function nstr_to_nval(nstr)
        --converts a notestring (nstr) into a note value 
        --catch errors
        assert(type(nstr) == "string", "Notestring type must be a string, got ".. type(nstr))
        assert(#nstr == 3, "Notestring must be exactly 3 characters long, got ".. #nstr)

        local special = table.find(specials, string.sub(nstr,1,3))
        local note = table.find(notestrings_upper, string.sub(nstr,1,2)) or table.find(notestrings_lower, string.sub(nstr,1,2))
        local octave = tonumber(string.sub(nstr,3))
       
        --catch errors
        assert(note or special, "Invalid notestring: " .. ((string.sub(nstr,1,3)) or "nil") .. " , expected format example: C-4")
        if note then
          assert(type(octave) == "number", "Invalid notestring octave: " .. (string.sub(nstr,3) or "nil") .. " , expected a number (0-9)")
        end

        --the math
        local nval 
        if note then
            nval = note + (octave*12) - 1
        else
            if nstr == "OFF" then
                nval = 120
            else
                nval = 121 --empty
            end
        end

        return nval
        
    end

    --------

    local function nval_to_nstr(nval) 
        --converts a note value (nval) into a notestring
        --catch errors
        assert(type(nval) == "number", "Note value format must be a number, got" ..type(nval))
        assert(nval >= 0 and nval <= 121, "Note value range 0-121, got " ..nval)

        --the abc
        local nstr
        if nval > 119 then
            --special
            if nval == 120 then
                nstr = "OFF"
            else
                nstr = "---"
            end
        else
            --regular note
            local octave = math.floor (nval/12)
            local note = nval - (12*octave)
            nstr = notestrings[note+1] .. octave
        end
        
        return nstr
    end

    --------

    --main
    assert(type(note) == "number" or type(note) == "string", "note_conv excpects number or string")
    local converted_note
    if type(note) == "number" then
        converted_note = nval_to_nstr(note)
    else
        converted_note = nstr_to_nval(note)
    end
    print("note_convert input: "..note..", returning: "..converted_note)
    return converted_note
end
local function tonumber_(numberstring)
    --print("v1", v1)
    --This function works from Cf, normal "tonumber()" does not. Why?
    --
    --This has to deal with solvables?
    --
    
    --
    if not vader then 
        print("booting, ignoring tonumber_()")
        return
    end --nevermind this before booting
    
    print("executing tonumber_()")
    --Solvables
    local solvables = {
        'p',
        't',
        'l',
        'c',
        'n',
        'e',
        'v',
        'd',
        'a',
        '_',
        '"',
        '='
    }

    local issolvable = false
    for index, test_string in ipairs(solvables) do
        if numberstring == test_string then
            issolvable = true
            break
        end
    end

    print ("tonumber_() defining type of string to solve for string: '"..numberstring.."' of type: "..type(numberstring))
    if issolvable then
        print ("tonumber_() defined type of said string as SOLVABLE")

        local solver = require("solver")

        print ("tonumber_ is going to solve string:" .. (numberstring or "nil") .. " within context:")
        rprint (context)
        local exp = solve(numberstring, context)
        set_last_expression_solved_value(exp)
        return last_expression_solved_value

    --note values
    elseif string.sub(numberstring, 1, 2) == "0n" then
        print ("tonumber_() defined type of said string as NOTESTRING")
        set_last_expression_solved_value(note_convert(string.sub(numberstring, 3)))
        return last_expression_solved_value

    --everything else
    else
        print ("tonumber_() defined type of said string as NUMBER")
        set_last_expression_solved_value(tonumber(numberstring))
        return last_expression_solved_value
    end
end

--Grammar rules
do
    --Whitespace
    G.ws = S(" \n\t")^0 --whitespace

    --Root level separators
    G.msg_sep = P';'
    G.cnt_sep = P':'
    G.glf_sep = P'--'
    G.mcr_sep = P'@'

    --Lower level separators
    G.rng_sep = P'..'

    --Values
    G.pm = S'+-'
    G.mpm = C((G.pm)^0) --maybe plus/minus
    G.digit = L.digit
    G.digits = C(G.digit^1)
    G.float = C(G.mpm * G.digits * G:maybe(C'.' * G.digits) )
    G.hex = C(G.mpm * P'0x' * (G.digit + S'AaBbCcDdEeFf')^1)


    G.notevalue = P'0n' * 
        (S'AaBbCcDdEeFfGg' * S'#-' * G.digit)
    +   (P'OFF')
    +   (P'---')

    G.internal = C(S'ptlcnevda' + S'_"') --"solvables" note that "=" is reserved for internal calls.

    G.value = Cmt(C(G.hex + G.notevalue + G.float + G.internal) / tonumber_ * G.ws, function(a,b,c)
        set_last_expression_solved_value(c)
        return true,c
    end)


    ------From LPeg examples
    G.balanced_parentheses_element = P{ "(" * ((1 - S"()") + V(1))^0 * ")" }

    ------From LPeg examples
    G.TermOp = C(S("+-")) * G.ws
    G.FactorOp = C(S("*/")) * G.ws
    G.OpenPar = "(" * G.ws
    G.ClosePar = ")" * G.ws


    function binop_eval (v1, op, v2)
        print("v1", v1)
        print("v2", v2)
        print("op", op)
      if (op == "+") then
          set_last_expression_solved_value(v1 + v2)
          return last_expression_solved_value
      elseif (op == "-") then
          set_last_expression_solved_value(v1 - v2)
          return last_expression_solved_value
      elseif (op == "*") then
          set_last_expression_solved_value(v1 * v2)
          return last_expression_solved_value
      elseif (op == "/") then
          set_last_expression_solved_value(v1 / v2)
          return last_expression_solved_value
      end
    end


    --This is not from examples
    function func_eval (func, v1, v2)

        --random
        if func == "?" then
            if v2 then
                local upper = math.max(v1, v2)
                local lower = math.min(v1, v2)
                set_last_expression_solved_value (math.random(lower, upper))
                return last_expression_solved_value
            else
                set_last_expression_solved_value (math.random(v1))
                return last_expression_solved_value
            end

        --min
        elseif func == "<" then
            if v2 then
                set_last_expression_solved_value (math.min(v1, v2))
                return last_expression_solved_value
            else
                set_last_expression_solved_value (v1)
                return last_expression_solved_value
            end

        --max
        elseif func == ">" then
            if v2 then
                set_last_expression_solved_value (math.max(v1, v2))
                return last_expression_solved_value
            else
                set_last_expression_solved_value (v1)
                return last_expression_solved_value
            end

        --sin
        elseif func == "SIN" then
            set_last_expression_solved_value (math.sin(v1))
            return last_expression_solved_value

        --cos
        elseif func == "COS" then
            set_last_expression_solved_value (math.cos(v1))
            return last_expression_solved_value

        --square root
        elseif func == "SQR" then
            set_last_expression_solved_value (math.sqrt(v1))
            return last_expression_solved_value

        --failback
        else
            set_last_expression_solved_value (0)
            return last_expression_solved_value
        end
    end

    G.FuncName = C(S("?<>")) * G.ws
                + C("SIN") * G.ws
                + C("COS") * G.ws
                + C("SQR") * G.ws


    --This is not from examples
    

    G.binary_operation = P{
        "Exp",

        Exp = Cf(V"Term" * Cg(G.TermOp * V"Term")^0, binop_eval);

        Term = Cf(V"Factor" * Cg(G.FactorOp * V"Factor")^0, binop_eval);

        Factor = (G.value + V"Func") + G.OpenPar * V"Exp" * G.ClosePar;

        Func = G.FuncName * G.OpenPar * V"Exp" * (P(','* G.ws) * V"Exp")^0 * G.ClosePar / func_eval;

    }

      

    G.expression =
        Ct(
            Cg(
                G.binary_operation
                + G.value
            , "EXP")
        )

    -------End snip









    --Range (defined separately for each scope when generating scope partials
    function G:get_range_definition_for_scopepartial() 
        local rangedef =
        Cg(
            Ct(
                (

                    --("BEG_VAL..END_VAL")
                    Cg(
                        G.expression
                    , "BEG_VAL")
                    * Cg(
                        (G.rng_sep * G.expression)
                    , "END_VAL")
                    
                    
                    --("BEG_VAL..")
                    +Cg(
                        G.expression
                    , "BEG_VAL")
                    * Cg(
                        G.rng_sep
                        * Ct(
                            Cg(
                                Cc('"')/tonumber_
                            , "EXP")
                            )
                    , "END_VAL")


                    --("..END_VAL")
                    + Cg(
                        (G.rng_sep * G.expression)
                    , "END_VAL")
                    * Cg(
                        Ct(
                            Cg(
                                Cc('=')/tonumber_
                            , "EXP")
                            )
                    , "BEG_VAL")


                    --("BEG_VAL (=END VAL)")
                    +Cg(
                        Cmt(
                            G.expression, function(a,b,c)
                                --print("BEG VAL (=END VAL)")
                                return true, c
                            end)
                    , "BEG_VAL")

                    * Cg(
                        Ct(
                            Cg(
                                Cmt(
                                    Cc(last_expression_solved_value),function()
                                            return true, last_expression_solved_value
                                        end
                                        )
                            , "EXP")
                            )
                    , "END_VAL")

                )
            )
        , "RNG_DEF") 
        *Cmt(Cc(""), function() print("context is:") rprint(context) return true end)
        --+ Err("invalid range") --This does not work with "MAYBE RANGE" type situations. Errors out.


    local rangedef_maybe_in_parentheses =
        rangedef
        + G.OpenPar * rangedef * G.ClosePar
            
        return rangedef_maybe_in_parentheses --finished pattern
    end


    --Scopetag
    G.scopetag = {
        pattern_level = {
            pattern = {
                single = Cg(Ct(Cg((P'p' * G.ws), "_string")), "pattern")
                    *Cmt(Cc(""), function() context[3] = "pattern" return true end),
                double = Cg(Ct(Cg((P'pp' * G.ws), "_string")), "pattern")
                    *Cmt(Cc(""), function() context[3] = "pattern" return true end),
                upper = Cg(Ct(Cg((P'P' * G.ws), "_string")), "pattern")
                    *Cmt(Cc(""), function() context[3] = "pattern" return true end),
            },
            sequence = {
                single = Cg(Ct(Cg((P'q' * G.ws), "_string")), "sequence")
                *Cmt(Cc(""), function() context[3] = "sequence" return true end),
                double = Cg(Ct(Cg((P'qq' * G.ws), "_string")), "sequence")
                *Cmt(Cc(""), function() context[3] = "sequence" return true end),
                upper = Cg(Ct(Cg((P'Q' * G.ws), "_string")), "sequence")
                *Cmt(Cc(""), function() context[3] = "sequence" return true end),
            },
            --[[
            section = {
                single = Cg(Ct(Cg((P'c'), "_string")), "section")
                *Cmt(Cc(""), function() context[3] = "section" return true end),
                double = Cg(Ct(Cg((P'cc'), "_string")), "section")
                *Cmt(Cc(""), function() context[3] = "section" return true end),
                upper = Cg(Ct(Cg((P'C'), "_string")), "section")
                *Cmt(Cc(""), function() context[3] = "section" return true end),
            },
            --]]
        },
        track_level = {
            track = {
                single = Cg(Ct(Cg((P't' * G.ws), "_string")), "track")
                *Cmt(Cc(""), function() context[3] = "track" return true end),
                double = Cg(Ct(Cg((P'tt' * G.ws), "_string")), "track")
                *Cmt(Cc(""), function() context[3] = "track" return true end),
                upper = Cg(Ct(Cg((P'T' * G.ws), "_string")), "track")
                *Cmt(Cc(""), function() context[3] = "track" return true end),
            },
            --[[
            group = {
                single = Cg(Ct(Cg((P'g'), "_string")), "group")
                *Cmt(Cc(""), function() context[3] = "group" return true end),
                double = Cg(Ct(Cg((P'gg'), "_string")), "group")
                *Cmt(Cc(""), function() context[3] = "group" return true end),
                upper = Cg(Ct(Cg((P'G'), "_string")), "group")
                *Cmt(Cc(""), function() context[3] = "group" return true end),
            },
            --]]
        },
        line_level = {
            line = {
                single = Cg(Ct(Cg((P'l' * G.ws), "_string")), "line")
                *Cmt(Cc(""), function() context[3] = "line" return true end),
                double = Cg(Ct(Cg((P'll' * G.ws), "_string")), "line")
                *Cmt(Cc(""), function() context[3] = "line" return true end),
                upper = Cg(Ct(Cg((P'L' * G.ws), "_string")), "line")
                *Cmt(Cc(""), function() context[3] = "line" return true end),
            },
        },
        column_level = {
            note_column = {
                single = Cg(Ct(Cg((P'c' * G.ws), "_string")), "note_column")
                *Cmt(Cc(""), function() context[3] = "note_column" return true end),
                double = Cg(Ct(Cg((P'cc' * G.ws), "_string")), "note_column")
                *Cmt(Cc(""), function() context[3] = "note_column" return true end),
                upper = Cg(Ct(Cg((P'C' * G.ws), "_string")), "note_column")
                *Cmt(Cc(""), function() context[3] = "note_column" return true end),
            },
            effect_column = {
                single = Cg(Ct(Cg((P'e' * G.ws), "_string")), "effect_column")
                *Cmt(Cc(""), function() context[3] = "effect_column" return true end),
                double = Cg(Ct(Cg((P'ee' * G.ws), "_string")), "effect_column")
                *Cmt(Cc(""), function() context[3] = "effect_column" return true end),
                upper = Cg(Ct(Cg((P'E' * G.ws), "_string")), "effect_column")
                *Cmt(Cc(""), function() context[3] = "effect_column" return true end),
            },
        },
        subcolumn_level = {
            note_value = {
                single = Cg(Ct(Cg((P'n' * G.ws), "_string")), "note_value")
                *Cmt(Cc(""), function() context[3] = "note_value" return true end),
                double = Cg(Ct(Cg((P'nn' * G.ws), "_string")), "note_value")
                *Cmt(Cc(""), function() context[3] = "note_value" return true end),
                upper = Cg(Ct(Cg((P'N' * G.ws), "_string")), "note_value")
                *Cmt(Cc(""), function() context[3] = "note_value" return true end),
            },
            instrument_value = {
                single = Cg(Ct(Cg((P'i' * G.ws), "_string")), "instrument_value")
                *Cmt(Cc(""), function() context[3] = "instrument_value" return true end),
                double = Cg(Ct(Cg((P'ii' * G.ws), "_string")), "instrument_value")
                *Cmt(Cc(""), function() context[3] = "instrument_value" return true end),
                upper = Cg(Ct(Cg((P'I' * G.ws), "_string")), "instrument_value")
                *Cmt(Cc(""), function() context[3] = "instrument_value" return true end),
            },
            volume_value = {
                single = Cg(Ct(Cg((P'v' * G.ws), "_string")), "volume_value")
                *Cmt(Cc(""), function() context[3] = "volume_value" return true end),
                double = Cg(Ct(Cg((P'vv' * G.ws), "_string")), "volume_value")
                *Cmt(Cc(""), function() context[3] = "volume_value" return true end),
                upper = Cg(Ct(Cg((P'V' * G.ws), "_string")), "volume_value")
                *Cmt(Cc(""), function() context[3] = "volume_value" return true end),
            },
            pan_value = {
                single = Cg(Ct(Cg((P'a' * G.ws), "_string")), "pan_value")
                *Cmt(Cc(""), function() context[3] = "pan_value" return true end),
                double = Cg(Ct(Cg((P'aa' * G.ws), "_string")), "pan_value")
                *Cmt(Cc(""), function() context[3] = "pan_value" return true end),
                upper = Cg(Ct(Cg((P'A' * G.ws), "_string")), "pan_value")
                *Cmt(Cc(""), function() context[3] = "pan_value" return true end),
            },
            delay_value = {
                single = Cg(Ct(Cg((P'd' * G.ws), "_string")), "delay_value")
                *Cmt(Cc(""), function() context[3] = "delay_value" return true end),
                double = Cg(Ct(Cg((P'dd' * G.ws), "_string")), "delay_value")
                *Cmt(Cc(""), function() context[3] = "delay_value" return true end),
                upper = Cg(Ct(Cg((P'D' * G.ws), "_string")), "delay_value")
                *Cmt(Cc(""), function() context[3] = "delay_value" return true end),
            },
            effect_number = {
                single = Cg(Ct(Cg((P'f' * G.ws), "_string")), "effect_number")
                *Cmt(Cc(""), function() context[3] = "effect_number" return true end),
                double = Cg(Ct(Cg((P'ff' * G.ws), "_string")), "effect_number")
                *Cmt(Cc(""), function() context[3] = "effect_number" return true end),
                upper = Cg(Ct(Cg((P'F' * G.ws), "_string")), "effect_number")
                *Cmt(Cc(""), function() context[3] = "effect_number" return true end),
            },
            effect_amount = {
                single = Cg(Ct(Cg((P'x' * G.ws), "_string")), "effect_amount")
                *Cmt(Cc(""), function() context[3] = "effect_amount" return true end),
                double = Cg(Ct(Cg((P'xx' * G.ws), "_string")), "effect_amount")
                *Cmt(Cc(""), function() context[3] = "effect_amount" return true end),
                upper = Cg(Ct(Cg((P'X' * G.ws), "_string")), "effect_amount")
                *Cmt(Cc(""), function() context[3] = "effect_amount" return true end),
            },
        },
    } 


    --ScopeFlags
    G.scopeflags = Cg(Ct(C(S"'*!")^1), "SCP_FLG")



    --Scopepartials
    --Create scope partial patterns procedurally
    function G:get_scopepartial(scopetag_name, level, tag)

        --set global seeking level
        status = "parse scope partials"
        context = {scopetag_name, level, tag}
        --print(context[3])

        local p = 


            --A double scopetag + possible flags
            Ct(scopetag_name.double
            * Cg(
                Ct(
                    Cg( 
                        Ct(
                            Cg(
                                Cc('_')/tonumber_
                            , "EXP")
                        )
                    , "BEG_VAL")
                    * Cg(
                        Ct(
                            Cg(
                                Cc('"')/tonumber_
                            , "EXP")
                            )
                    , "END_VAL")
                )
            , "RNG_DEF")

            * (G.scopeflags)^-1)


            --An upper scopetag
            + Ct(scopetag_name.upper

            * Cg(
                Ct(
                    Cg( 
                        Ct(
                            Cg(
                                Cc('_')/tonumber_
                            , "EXP")
                        )
                    , "BEG_VAL")
                    * Cg(
                        Ct(
                            Cg(
                                Cc('"')/tonumber_
                            , "EXP")
                            )
                    , "END_VAL")
                )
            , "RNG_DEF")

            * (G.scopeflags)^-1)


            --A single scopetag + range + maybe flags
            + Ct(scopetag_name.single

                * G:get_range_definition_for_scopepartial()

                * (G.scopeflags)^-1
            )




            --A single scopetag + no range + maybe flags
            + Ct(scopetag_name.single

            * Cg(
                Ct(
                    Cg( 
                        Ct(
                            Cg(
                                Cc('=')/tonumber_
                            , "EXP")
                        )
                    , "BEG_VAL")
                    * Cg(
                        Ct(
                            Cg(
                                Cc('=')/tonumber_
                            , "EXP")
                            )
                    , "END_VAL")
                )
            , "RNG_DEF")

            * (G.scopeflags)^-1)


        return p

    end

    G.scopepartial = {
        pattern_level = {},
        track_level = {},
        line_level = {},
        column_level = {},
        subcolumn_level = {},
    }
    for level, tags in pairs(G.scopetag) do
        for tag, patterns in pairs(tags) do
            G.scopepartial[level][tag] = G:get_scopepartial(G.scopetag[level][tag], level, tag)
        end
    end

    --Levelpartials
    function G:get_levelpartial(scopepartial_level)
        local levelpartial
        for partial, pattern in pairs(scopepartial_level) do

            --print("debug: ")
            --print(partial)
            --print(pattern)

            if not levelpartial then
                --first rule
                levelpartial = pattern
            else
                --following rules
                levelpartial = levelpartial + pattern
            end
        end
        return levelpartial
    end

    G.scp_pat_lev = Cg(
                    Cmt(Cc("__explicit"),
                    function()
                        context[2] = "pattern level"
                        return true
                    end)
                    * G:get_levelpartial(G.scopepartial.pattern_level),    "SCP_PAT")
    G.scp_trk_lev = Cg(
                    Cmt(Cc("__explicit"),
                    function()
                        context[2] = "track level"
                        return true
                    end)
                    * G:get_levelpartial(G.scopepartial.track_level),      "SCP_TRK")
    G.scp_lin_lev = Cg(
                    Cmt(Cc("__explicit"),
                    function()
                        context[2] = "line level"
                        return true
                    end)
                    * G:get_levelpartial(G.scopepartial.line_level),       "SCP_LIN")
    G.scp_col_lev = Cg(
                    Cmt(Cc("__explicit"),
                    function()
                        context[2] = "column level"
                        return true
                    end)
                    * G:get_levelpartial(G.scopepartial.column_level),     "SCP_COL")
    G.scp_sbc_lev = Cg(
                    Cmt(Cc("__explicit"),
                    function()
                        context[2] = "subcolumn level"
                        return true
                    end)
                    * G:get_levelpartial(G.scopepartial.subcolumn_level),  "SCP_SBC")


    --Scope (general)
    G.scope =

        Ct(
            Cg(
                Ct(
                    (
                        (G.scp_pat_lev)
                        * (G.scp_trk_lev)^-1
                        * (G.scp_lin_lev)^-1
                        * (G.scp_col_lev)^-1
                        * (G.scp_sbc_lev)^-1
                        * Cmt(Cc("__explicit"),
                        function()
                            --print("****pattop")
                            top_defined_level[context[1]] = "pattern level"
                            return true 
                        end)
                    )
                    +
                    (
                        (G.scp_trk_lev)
                        * (G.scp_lin_lev)^-1
                        * (G.scp_col_lev)^-1
                        * (G.scp_sbc_lev)^-1
                        * Cmt(Cc("__explicit"),
                        function()
                            --print("****trktop")
                            top_defined_level[context[1]] = "track level"
                            return true 
                        end)
                    )
                    + 
                    ( 
                        (G.scp_lin_lev)
                        * (G.scp_col_lev)^-1
                        * (G.scp_sbc_lev)^-1
                        * Cmt(Cc("__explicit"),
                        function()
                            --print("****lintop")
                            top_defined_level[context[1]] = "line level"
                            return true
                        end)
                    )
                    + 
                    (
                        (G.scp_col_lev)
                        * (G.scp_sbc_lev)^-1
                        * Cmt(Cc("__explicit"),
                        function()
                            --print("****coltop")
                            top_defined_level[context[1]] = "column level"
                            return true
                        end)
                    )
                    +
                    ( 
                        (G.scp_sbc_lev)
                        * Cmt(Cc("__explicit"),
                        function()
                            --print("****sbctop")
                            top_defined_level[context[1]] = "subcolumn level"
                            return true
                        end)
                    )
                )
                
            , "SCP")
            * Cmt(Cc("__explicit"),
            function()
                --print("****scopefound")
                has_scope[context[1]] = true
                return true
            end)
        )
        --+ Err("invalid "..(context[2] or "?").." scope in "..(context[1] or "nothing"))
        --+ Err("invalid scope in "..(context[2] or "nothing"))

    --Target
    G.target =      G.ws * (
                        Cg( 
                    Cmt(Cc("__explicit"),
                    function()
                        print("****msgpartinc")
                        counter_msg_part = counter_msg_part + 1
                        context[1] = "target"
                        return true
                    end)
                    *        (G.scope)
                            --* ((#G.cnt_sep + #G.msg_sep) - 1)
                        , "TRG" )
                    )
                    --Err("invalid target")

    G.content =     G.ws * (
                        Cg( 
                    Cmt(Cc("__explicit"),
                    function()
                        print("****msgpartinc")
                        counter_msg_part = counter_msg_part + 1
                        context[1] = "content"
                        return true
                    end)
                    *       (G.expression)
                            + ((G.scope)^-1)
                            --* (#G.msg_sep - 1)
                        , "CNT" )
                    )
                    --+ Err("invalid content")

    G.globalflags = G.ws * 
                    Cg(
                    Cmt(Cc("__explicit"),
                    function()
                        print("****msgpartinc")
                        counter_msg_part = counter_msg_part + 1
                        context[1] = "globalflags"
                        return true
                    end)
                    * ( (P(1) - (G.mcr_sep + G.msg_sep))^1 )
                        , "GFL" )
                    
    G.macro =       G.ws *
                    Cg(
                    Cmt(Cc("__explicit"),
                    function()
                        print("****msgpartinc")
                        counter_msg_part = counter_msg_part + 1
                        context[1] = "macro"
                        return true
                    end)
                    * ( (P(1) - (G.msg_sep))^1 )
                        , "MCR" )

    --Message
    G.message =
        Ct(
            Cg(
                Ct(
                    (
                        (   (G.target) * (G.cnt_sep * G.content)^-1 * (G.glf_sep * G.globalflags)^-1 * (G.mcr_sep * G.macro)^-1 )
                    )
                    +
                    (
                        ( (G.cnt_sep * G.content) * (G.glf_sep * G.globalflags)^-1 * (G.mcr_sep * G.macro)^-1 )
                    )
                    +
                    (
                        ( (G.glf_sep * G.globalflags) * (G.mcr_sep * G.macro)^-1 )
                    )
                    +   
                    (
                        (G.mcr_sep * G.macro)
                    )

                )
            , "MSG")
            * Cmt(Cc("__explicit"), function() print("****msginc") counter_msg = counter_msg + 1 return true end)
        )
        + Err("invalid message")

    --Script
    G.script =
        Ct(
            Cg(
                Ct(
                    (G.msg_sep^-1 * G.message * (G.msg_sep * G.message)^0 * -1)
                )
            , "SCRIPT")
        )
        + Err("invalid script")
end
return G
