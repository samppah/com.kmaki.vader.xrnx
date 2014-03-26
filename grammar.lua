--vader grammar lulpeg

local vader = get_tool_root_node()

function boot_grammar(main_vader)
    vader = main_vader
end


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

G = {}

--Stuff for Syntax Errors
local counter_script = 0
local counter_msg = 0
local counter_msg_part = 0
local counter_scope_part = 0

--Stuff for context based internal values
local context = {}

local function set_context(level_name, item_name)
    --[[
    Returns a dummy LPeg pattern that doesn't interfere with
    capturing process, but sets local variable context
    --]]
    return P(
            Cmt(P(0), function(subject, pos)
                --vader.logs.debug:entry("Set context level["..level_name.."] item["..item_name.."]")
                context[level_name] = item_name
                return pos
            end)
            )
end


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

    dummy1 seems to be the subject (the whole message that is parsed)
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

--General Pattern building rules for LPeg
function G:maybe(p) return p ^ -1 end
function G:either(p, q) return p + q end

--Conversions for LPeg parser
function tonumber_(numberstring)
	print("tonumber_ :"..numberstring)
	if type(numberstring) == "number" then
		return numberstring
	else
	    --print("v1", v1)
	    --This function works from Cf, normal "tonumber()" does not. Why?
	    --print("tonumber_: ",numberstring, tonumber(numberstring))
	    return tonumber(numberstring)
	end
end


--LPeg Grammar
--Whitespace
G.ws = S(" \n\t")^0 --whitespace

--Scopetags
G.scopetag = {
    pattern_level = {
        pattern = {
            single = Cg(Ct(Cg((P'p'), "_string")), "pattern") * set_context("scopetag", "pattern"),
            double = Cg(Ct(Cg((P'pp'), "_string")), "pattern") * set_context("scopetag", "pattern"),
            upper = Cg(Ct(Cg((P'P'), "_string")), "pattern") * set_context("scopetag", "pattern") 
        },

        sequence = {
            single = Cg(Ct(Cg((P'q'), "_string")), "sequence") * set_context("scopetag", "sequence"),
            double = Cg(Ct(Cg((P'qq'), "_string")), "sequence") * set_context("scopetag", "sequence"),
            upper = Cg(Ct(Cg((P'Q'), "_string")), "sequence") * set_context("scopetag", "sequence")
        },
        section = {
            single = Cg(Ct(Cg((P'c'), "_string")), "section") * set_context("scopetag", "section"),
            double = Cg(Ct(Cg((P'cc'), "_string")), "section") * set_context("scopetag", "section"),
            upper = Cg(Ct(Cg((P'C'), "_string")), "section") * set_context("scopetag", "section")
        },
    },
    track_level = {
        track = {
            single = Cg(Ct(Cg((P't'), "_string")), "track") * set_context("scopetag", "track"),
            double = Cg(Ct(Cg((P'tt'), "_string")), "track") * set_context("scopetag", "track"),
            upper = Cg(Ct(Cg((P'T'), "_string")), "track") * set_context("scopetag", "track")
        },
        group = {
            single = Cg(Ct(Cg((P'g'), "_string")), "trackgroup") * set_context("scopetag", "trackgroup"),
            double = Cg(Ct(Cg((P'gg'), "_string")), "trackgroup") * set_context("scopetag", "trackgroup"),
            upper = Cg(Ct(Cg((P'G'), "_string")), "trackgroup") * set_context("scopetag", "trackgroup")
        },
    },
    line_level = {
        line = {
            single = Cg(Ct(Cg((P'l'), "_string")), "line") * set_context("scopetag", "line"),
            double = Cg(Ct(Cg((P'll'), "_string")), "line") * set_context("scopetag", "line"),
            upper = Cg(Ct(Cg((P'L'), "_string")), "line") * set_context("scopetag", "line")
        },
    },
    column_level = {
        note_column = {
            single = Cg(Ct(Cg((P'n'), "_string")), "note_column") * set_context("scopetag", "note_column"),
            double = Cg(Ct(Cg((P'nn'), "_string")), "note_column") * set_context("scopetag", "note_column"),
            upper = Cg(Ct(Cg((P'N'), "_string")), "note_column") * set_context("scopetag", "note_column")
        },
        effect_column = {
            single = Cg(Ct(Cg((P'e'), "_string")), "effect_column") * set_context("scopetag", "effect_column"),
            double = Cg(Ct(Cg((P'ee'), "_string")), "effect_column") * set_context("scopetag", "effect_column"),
            upper = Cg(Ct(Cg((P'E'), "_string")), "effect_column") * set_context("scopetag", "effect_column")
        },
    },
    subcolumn_level = {
        note_value = {
            single = Cg(Ct(Cg((P'n'), "_string")), "note_value") * set_context("scopetag", "note_value"),
            double = Cg(Ct(Cg((P'nn'), "_string")), "note_value") * set_context("scopetag", "note_value"),
            upper = Cg(Ct(Cg((P'N'), "_string")), "note_value") * set_context("scopetag", "note_value")
        },
        instrument_value = {
            single = Cg(Ct(Cg((P'i'), "_string")), "instrument_value") * set_context("scopetag", "instrument_value"),
            double = Cg(Ct(Cg((P'ii'), "_string")), "instrument_value") * set_context("scopetag", "instrument_value"),
            upper = Cg(Ct(Cg((P'I'), "_string")), "instrument_value") * set_context("scopetag", "instrument_value")
        },
        volume_value = {
            single = Cg(Ct(Cg((P'v'), "_string")), "volume_value") * set_context("scopetag", "volume_value"),
            double = Cg(Ct(Cg((P'vv'), "_string")), "volume_value") * set_context("scopetag", "volume_value"),
            upper = Cg(Ct(Cg((P'V'), "_string")), "volume_value") * set_context("scopetag", "volume_value")
        },
        pan_value = {
            single = Cg(Ct(Cg((P'p'), "_string")), "panning_value") * set_context("scopetag", "panning_value"),
            double = Cg(Ct(Cg((P'pp'), "_string")), "panning_value") * set_context("scopetag", "panning_value"),
            upper = Cg(Ct(Cg((P'P'), "_string")), "panning_value") * set_context("scopetag", "panning_value")
        },
        delay_value = {
            single = Cg(Ct(Cg((P'd'), "_string")), "delay_value") * set_context("scopetag", "delay_value"),
            double = Cg(Ct(Cg((P'dd'), "_string")), "delay_value") * set_context("scopetag", "delay_value"),
            upper = Cg(Ct(Cg((P'D'), "_string")), "delay_value") * set_context("scopetag", "delay_value")
        },
        effect_number = {
            single = Cg(Ct(Cg((P'f'), "_string")), "effectnumber") * set_context("scopetag", "effectnumber"),
            double = Cg(Ct(Cg((P'ff'), "_string")), "effectnumber") * set_context("scopetag", "effectnumber"),
            upper = Cg(Ct(Cg((P'F'), "_string")), "effectnumber") * set_context("scopetag", "effectnumber")
        },
        effect_value = {
            single = Cg(Ct(Cg((P'x'), "_string")), "effectamount") * set_context("scopetag", "effectamount"),
            double = Cg(Ct(Cg((P'xx'), "_string")), "effectamount") * set_context("scopetag", "effectamount"),
            upper = Cg(Ct(Cg((P'X'), "_string")), "effectamount") * set_context("scopetag", "effectamount")
        },
    },
} 

--ScopeFlags
G.scopeflags = Cg(Ct(C(S"'*!")^1), "SCP_FLG")
--Values
G.pm = S'+-'
G.mpm = C((G.pm)^0) --maybe plus/minus
G.digit = L.digit
G.digits = C(G.digit^1)
G.float = C(G.mpm * G.digits * G:maybe(C'.' * G.digits) )
G.hex = C(G.mpm * P'0x' * (G.digit + S'AaBbCcDdEeFf')^1)

--Internal symbols, values
G.symbol_min = C(P'_')
G.symbol_max = C(P'"')
G.symbol_empty = C(P'o')
G.symbol_visible = C(P'´')
G.symbol_non_empty = C(P"'")
G.symbol_inverse = C(P'!')
G.symbol_random = C(P'?')

--Get single scopetags for "current" solvables
local function get_single_scopepartials()
    --Returns a combined pattern to match any "single" scope partial
    --print("getting single scopepartials")
    local single_scopepartials
    for level, tags in pairs(G.scopetag) do
        for tag, partial in pairs(tags) do
            --print(tags, tag, partial)
            if not single_scopepartials then
                --First rule
                single_scopepartials = partial["single"]
            else
                single_scopepartials = single_scopepartials + partial["single"]
            end
        end
    end
    return single_scopepartials
end

G.symbol_current = get_single_scopepartials()

local function solve(internal_value)

    local solve_function = vader.lex.solve_lookup_table[internal_value]
    vader_assert(solve_function, "Can't solve: "..internal_value..", no function in vader.lex.solve_lookup_table.")

    local scope = context["scopetag"]
    vader_assert(scope, "Can't solve: "..internal_value..", no scope for context set.")

    vader.logs.debug:entry("solve(): "..internal_value.." / "..scope)
    return solve_function(scope)

end

G.internal = 
        Cc("<value current>") * G.symbol_current / solve
    +
        Cc("<symbol min>") * G.symbol_min / solve
    +
        Cc("<symbol max>") * G.symbol_max /solve


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

G.notevalue = P'0n' * C(S'AaBbCcDdEeFfGg' * S'#-' * G.digit)/note_convert

G.value = C(G.hex) + G.notevalue + C(G.float) + G.internal * G.ws

------From LPeg examples
local Number = G.value
G.TermOp = C(S("+-")) * G.ws
G.FactorOp = C(S("*/")) * G.ws
G.OpenPar = "(" * G.ws
G.ClosePar = ")" * G.ws

-- Function identifiers
G.fn_id = C('?') --random function
	+ C('SIN') --sine function
	+ C('COS') --cosine function
	+ C('SQR') --square root
        + C('RND') --random function


-- Evaluation functions
function binop_eval (v1, op, v2)
  if (op == "+") then return v1 + v2
  elseif (op == "-") then return v1 - v2
  elseif (op == "*") then return v1 * v2
  elseif (op == "/") then return v1 / v2
  end
end



function fn_eval(...)
    -- Gets passed fn_id, argument list
    rprint(arg)
    local fn_id = arg[1]
    local argument_table = arg[2]
    -- Random function
    if fn_id == "?" or fn_id == "RND" then 
            if argument_table[2] then
                --2 arguments, random number from arg1 to arg2
                local low_bound = math.min(argument_table[1], argument_table[2])
                local high_bound = math.max(argument_table[1], argument_table[2])
                local diff = high_bound - low_bound
                return math.random(diff) + low_bound
            elseif argument_table[1] then
                --Just 1 argument, random number from 0 to arg
                return math.random(argument_table[1])
            else
                not_implemented("Random function with no arguments")
            end
    end
    return 0
end


--Expression grammar.
G.expression = 
    Ct(
        Cg(
            P{

                "Exp",

                Exp = V"BinOp" + G.value / tonumber_ + V"Fn";



                BinOp = Cf(V"Term" * Cg(G.TermOp * V"Term")^0, binop_eval);

                Term = Cf(V"Factor" * Cg(G.FactorOp * V"Factor")^0, binop_eval);

                Factor = (G.value / tonumber_ + V"Fn") + G.OpenPar * V"BinOp" * G.ClosePar;



                Fn = Cf(G.fn_id * P('(') * V"Fn_arglist" * P(')'), fn_eval);

                Fn_arglist = Ct(V"Exp" * (P(',') * V"Exp")^0);



            }
        , "EXP")
    )

--Root level separators
G.msg_sep = P';'
G.cnt_sep = P':'
G.glf_sep = P'--'
G.mcr_sep = P'@'


--Lower level separators
G.rng_sep = P'..'


--Range

G.rangedef_unnested =
        Ct(
            (

                Cg(
                    G.expression
                , "BEG_VAL")

		* (

			Cg(
			    (G.rng_sep * G.expression)
			    +
			    (G.rng_sep * Cc("<value current>"))

			, "END_VAL")

		)^-1

                +

		(
		
		Cg(
                    (G.rng_sep * Cc("<value current>"))
                , "BEG_VAL")
		*
		Cg(
                    (G.expression)
                , "END_VAL")
		)


            )
        )


G.rangedef =
    Cg(
    	--TODO: does not handle nested nests. -> Grammar to do this?
    	--Unnested
    	G.rangedef_unnested
	+
	--Nested 
        (
	    P'(' *
	    G.rangedef_unnested
	    * P')'
        )

    , "RNG_DEF") 
    --+ Err("invalid range") --This does not work with "MAYBE RANGE" type situations. Errors out.






--Scopepartials
--Create scope partial patterns procedurally
function G:get_scopepartial(scopetag_name, level, tag)

    local p = 

        ( (scopetag_name.double * (G.scopeflags)^-1) * Cmt( Cc(""), function(val, val2, val3, val4)
            --print("**************scpt double found "..level.."/"..tag)
            return true
        end))

        + ( (scopetag_name.single * (G.rangedef)^-1 * (G.scopeflags)^-1) * Cmt( Cc("") , function(val, val2, val3, val4)
                --print("**************scpt single found "..level.."/"..tag)
                return true
            end))

        + ( (scopetag_name.upper * (G.scopeflags)^-1) * Cmt( Cc("") , function(val, val2, val3, val4)
                --print("**************scpt upper found "..level.."/"..tag)
                return true
            end))

        --+ Err("no partial in "..level.."/"..tag)

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

G.scp_pat_lev = Cg(Ct(G:get_levelpartial(G.scopepartial.pattern_level)),    "SCP_PAT")
G.scp_trk_lev = Cg(Ct(G:get_levelpartial(G.scopepartial.track_level)),      "SCP_TRK")
G.scp_lin_lev = Cg(Ct(G:get_levelpartial(G.scopepartial.line_level)),       "SCP_LIN")
G.scp_col_lev = Cg(Ct(G:get_levelpartial(G.scopepartial.column_level)),     "SCP_COL")
G.scp_sbc_lev = Cg(Ct(G:get_levelpartial(G.scopepartial.subcolumn_level)),  "SCP_SBC")


--Scope (general)
G.scope =

    Ct(
        Cg(
            Ct(
                --(G.scp_pat_lev)^-1 * (G.scp_trk_lev)^-1 * (G.scp_lin_lev)^-1 * (G.scp_col_lev)^-1 * (G.scp_sbc_lev)^-1
                (
                    (G.scp_pat_lev) * (G.scp_trk_lev)^-1 * (G.scp_lin_lev)^-1 * (G.scp_col_lev)^-1 * (G.scp_sbc_lev)^-1
                    --* Cmt(Cc("__explicit"), function() print("****pattop") return true end)
                )
                +
                (
                    (G.scp_trk_lev) * (G.scp_lin_lev)^-1 * (G.scp_col_lev)^-1 * (G.scp_sbc_lev)^-1
                    --* Cmt(Cc("__explicit"), function() print("****trktop") return true end)
                )
                + 
                ( 
                    (G.scp_lin_lev) * (G.scp_col_lev)^-1 * (G.scp_sbc_lev)^-1
                    --* Cmt(Cc("__explicit"), function() print("****lintop") return true end)
                )
                + 
                (
                    (G.scp_col_lev) * (G.scp_sbc_lev)^-1
                    --* Cmt(Cc("__explicit"), function() print("****coltop") return true end)
                )
                +
                ( 
                    (G.scp_sbc_lev)
                    --* Cmt(Cc("__explicit"), function() print("****sbctop") return true end)
                )
            )
            
        , "SCP")
        --* Cmt(Cc("__explicit"), function() print("****scopefound") return true end)
    )
    --+ Err("invalid scope")

--Target
--G.target =      Cg( (G.scope) + error_"Invalid target.", "TRG" )
--G.content =     Cg( (G.expression) + (G.scope)^-1, error_"Invalid content." "CNT" ) --or expression
--
G.target =      (
                    set_context("msg_part", "TRG")
                    *

                    Cg( (G.scope)
                        --* ((#G.cnt_sep + #G.msg_sep) - 1)
                    , "TRG" )

                    * Cmt(Cc("__explicit"), function() 
                        --print("****msgpartinc")
                        counter_msg_part = counter_msg_part + 1
                        return true end)
                )
                --+ Err("invalid target")
                
G.content =     (
                    set_context("msg_part", "CNT")
                    *

                    Cg( 
                        (G.scope)
                        + (G.expression)
                        --* (#G.msg_sep - 1)
                    , "CNT" )

                    * Cmt(Cc("__explicit"), function()
                        --print("****msgpartinc")
                        counter_msg_part = counter_msg_part + 1
                        return true end)
                )
                --+ Err("invalid content")

G.globalflags = Cg(( (P(1) - (G.mcr_sep + G.msg_sep))^1 ),                          "GFL" )
G.macro =       Cg(( (P(1) - (G.msg_sep))^1 ),                                      "MCR" )


--Message
G.message =
    Ct(
        Cg(
            Ct(
                (
                    (   (G.target) * (G.cnt_sep * G.content)^-1 * (G.glf_sep * G.globalflags)^-1 * (G.mcr_sep * G.macro)^-1 )
                    --*# (G.msg_sep)
                    --* ( #G.msg_sep - 1)
                )
                +
                (
                    ( (G.cnt_sep * G.content) * (G.glf_sep * G.globalflags)^-1 * (G.mcr_sep * G.macro)^-1 )
                    --*# (G.msg_sep)
                    --* ( #G.msg_sep - 1)
                )
                +
                (
                    ( (G.glf_sep * G.globalflags) * (G.mcr_sep * G.macro)^-1 )
                    --*# (G.msg_sep)
                    --* ( #G.msg_sep - 1)
                )
                +   
                (
                    (G.mcr_sep * G.macro)
                    --*# (G.msg_sep)
                    --*# ( G.msg_sep - 1)
                )

            )
        , "MSG")
        * Cmt(Cc("__explicit"), function()
            --print("****msginc")
            counter_msg = counter_msg + 1
            return true end)
    )
    + Err("invalid message")

--Script
G.script =
    Ct(
        Cg(
            Ct(
                    (G.msg_sep)^-1

                    * G.message

                    * (G.msg_sep * (G.message)^-1 )^0
                    
                    * P(-1)
                )
        , "SCRIPT")
    )
    + Err("invalid script")








return G
