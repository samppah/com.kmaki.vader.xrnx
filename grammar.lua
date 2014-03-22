--vader grammar lulpeg
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
function tonumber_(numberstring)
    --print("v1", v1)
    --This function works from Cf, normal "tonumber()" does not. Why?
    print("tonumber_: ",numberstring, tonumber(numberstring))
    return tonumber(numberstring)
end


--Grammar
do
    --Whitespace
    G.ws = S(" \n\t")^0 --whitespace


    --Values
    G.pm = S'+-'
    G.mpm = C((G.pm)^0) --maybe plus/minus
    G.digit = L.digit
    G.digits = C(G.digit^1)
    G.float = C(G.mpm * G.digits * G:maybe(C'.' * G.digits) )
    G.hex = C(G.mpm * P'0x' * (G.digit + S'AaBbCcDdEeFf')^1)

    G.internal = C(S'ptlnc' + S'_"') --"solvables"

    G.value = C(G.hex + G.float + G.internal) * G.ws

    G.notevalue = C(P'0n' * S'AaBbCcDdEeFfGg' * '#-' * G.digit)


    ------From LPeg examples
    G.balanced_parentheses_element = P{ "(" * ((1 - S"()") + V(1))^0 * ")" }


    ------From LPeg examples
    local Number = G.value
    G.TermOp = C(S("+-")) * G.ws
    G.FactorOp = C(S("*/")) * G.ws
    G.OpenPar = "(" * G.ws
    G.ClosePar = ")" * G.ws


    -- Auxiliary function
    function binop_eval (v1, op, v2)
        print("v1", v1)
        print("v2", v2)
        print("op", op)
      if (op == "+") then return v1 + v2
      elseif (op == "-") then return v1 - v2
      elseif (op == "*") then return v1 * v2
      elseif (op == "/") then return v1 / v2
      end
    end


    -- Grammar

    G.binary_operation = P{
        "Exp",

        Exp = Cf(V"Term" * Cg(G.TermOp * V"Term")^0, binop_eval);

        Term = Cf(V"Factor" * Cg(G.FactorOp * V"Factor")^0, binop_eval);

        Factor = G.value / tonumber_ + G.OpenPar * V"Exp" * G.ClosePar;

    }

    -------End snip


    G.expression =
        Ct(
            Cg(
                G.binary_operation
                + G.value / tonumber_
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
    G.rangedef =
        Cg(
            Ct(
                (

                    Cg(
                        G.expression
                    , "BEG_VAL")
                    * Cg(
                        (G.rng_sep * G.expression)
                    , "END_VAL")^0



                    + Cg(
                        (G.rng_sep * G.expression)
                    , "END_VAL")


                )
            )
        , "RNG_DEF") 
        --+ Err("invalid range") --This does not work with "MAYBE RANGE" type situations. Errors out.



    --Scopetag
    G.scopetag = {
        pattern_level = {
            pattern = {
                single = Cg(Ct(Cg((P'p'), "_string")), "SCT_PAT_SINGLE"),
                double = Cg(Ct(Cg((P'pp'), "_string")), "SCT_PAT_DOUBLE"),
                upper = Cg(Ct(Cg((P'P'), "_string")), "SCT_PAT_UPPER")
            },
            sequence = {
                single = Cg(Ct(Cg((P'q'), "_string")), "SCT_SEQ_SINGLE"),
                double = Cg(Ct(Cg((P'qq'), "_string")), "SCT_SEQ_DOUBLE"),
                upper = Cg(Ct(Cg((P'Q'), "_string")), "SCT_SEQ_UPPER")
            },
            section = {
                single = Cg(Ct(Cg((P'c'), "_string")), "SCT_SEC_SINGLE"),
                double = Cg(Ct(Cg((P'cc'), "_string")), "SCT_SEC_DOUBLE"),
                upper = Cg(Ct(Cg((P'C'), "_string")), "SCT_SEC_UPPER")
            },
        },
        track_level = {
            track = {
                single = Cg(Ct(Cg((P't'), "_string")), "SCT_TRK_SINGLE"),
                double = Cg(Ct(Cg((P'tt'), "_string")), "SCT_TRK_DOUBLE"),
                upper = Cg(Ct(Cg((P'T'), "_string")), "SCT_TRK_UPPER")
            },
            group = {
                single = Cg(Ct(Cg((P'g'), "_string")), "SCT_GRP_SINGLE"),
                double = Cg(Ct(Cg((P'gg'), "_string")), "SCT_GRP_DOUBLE"),
                upper = Cg(Ct(Cg((P'G'), "_string")), "SCT_GRP_UPPER")
            },
        },
        line_level = {
            line = {
                single = Cg(Ct(Cg((P'l'), "_string")), "SCT_LIN_SINGLE"),
                double = Cg(Ct(Cg((P'll'), "_string")), "SCT_LIN_DOUBLE"),
                upper = Cg(Ct(Cg((P'L'), "_string")), "SCT_LIN_UPPER")
            },
        },
        column_level = {
            note_column = {
                single = Cg(Ct(Cg((P'n'), "_string")), "SCT_NOC_SINGLE"),
                double = Cg(Ct(Cg((P'nn'), "_string")), "SCT_NOC_DOUBLE"),
                upper = Cg(Ct(Cg((P'N'), "_string")), "SCT_NOC_UPPER")
            },
            effect_column = {
                single = Cg(Ct(Cg((P'e'), "_string")), "SCT_EFC_SINGLE"),
                double = Cg(Ct(Cg((P'ee'), "_string")), "SCT_EFC_DOUBLE"),
                upper = Cg(Ct(Cg((P'E'), "_string")), "SCT_EFC_UPPER")
            },
        },
        subcolumn_level = {
            note_value = {
                single = Cg(Ct(Cg((P'n'), "_string")), "SCT_NVA_SINGLE"),
                double = Cg(Ct(Cg((P'nn'), "_string")), "SCT_NVA_DOUBLE"),
                upper = Cg(Ct(Cg((P'N'), "_string")), "SCT_NVA_UPPER")
            },
            instrument_value = {
                single = Cg(Ct(Cg((P'i'), "_string")), "SCT_INS_SINGLE"),
                double = Cg(Ct(Cg((P'ii'), "_string")), "SCT_INS_DOUBLE"),
                upper = Cg(Ct(Cg((P'I'), "_string")), "SCT_INS_UPPER")
            },
            volume_value = {
                single = Cg(Ct(Cg((P'v'), "_string")), "SCT_VOL_SINGLE"),
                double = Cg(Ct(Cg((P'vv'), "_string")), "SCT_VOL_DOUBLE"),
                upper = Cg(Ct(Cg((P'V'), "_string")), "SCT_VOL_UPPER")
            },
            pan_value = {
                single = Cg(Ct(Cg((P'p'), "_string")), "SCT_PAN_SINGLE"),
                double = Cg(Ct(Cg((P'pp'), "_string")), "SCT_PAN_DOUBLE"),
                upper = Cg(Ct(Cg((P'P'), "_string")), "SCT_PAN_UPPER")
            },
            delay_value = {
                single = Cg(Ct(Cg((P'd'), "_string")), "SCT_DEL_SINGLE"),
                double = Cg(Ct(Cg((P'dd'), "_string")), "SCT_DEL_DOUBLE"),
                upper = Cg(Ct(Cg((P'D'), "_string")), "SCT_DEL_UPPER")
            },
            effect_number = {
                single = Cg(Ct(Cg((P'f'), "_string")), "SCT_ENU_SINGLE"),
                double = Cg(Ct(Cg((P'ff'), "_string")), "SCT_ENU_DOUBLE"),
                upper = Cg(Ct(Cg((P'F'), "_string")), "SCT_ENU_UPPER")
            },
            effect_value = {
                single = Cg(Ct(Cg((P'x'), "_string")), "SCT_EVA_SINGLE"),
                double = Cg(Ct(Cg((P'xx'), "_string")), "SCT_EVA_DOUBLE"),
                upper = Cg(Ct(Cg((P'X'), "_string")), "SCT_EVA_UPPER")
            },
        },
    } 


    --ScopeFlags
    G.scopeflags = Cg(Ct(C(S"'*!")^1), "SCP_FLG")



    --Scopepartials
    --Create scope partial patterns procedurally
    function G:get_scopepartial(scopetag_name, level, tag)

        local p = 

            ( Cmt(((scopetag_name.double * (G.scopeflags)^-1)) , function(val)
                print("**************scpt double found "..level.."/"..tag)
                return true
            end))

            + ( Cmt(((scopetag_name.single * (G.rangedef)^-1 * (G.scopeflags)^-1)) , function()
                    print("**************scpt single found "..level.."/"..tag)
                    return true 
                end))

            + ( Cmt(((scopetag_name.upper * (G.scopeflags)^-1)) , function()
                    print("**************scpt upper found "..level.."/"..tag)
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
                        * Cmt(Cc("__explicit"), function() print("****pattop") return true end)
                    )
                    +
                    (
                        (G.scp_trk_lev) * (G.scp_lin_lev)^-1 * (G.scp_col_lev)^-1 * (G.scp_sbc_lev)^-1
                        * Cmt(Cc("__explicit"), function() print("****trktop") return true end)
                    )
                    + 
                    ( 
                        (G.scp_lin_lev) * (G.scp_col_lev)^-1 * (G.scp_sbc_lev)^-1
                        * Cmt(Cc("__explicit"), function() print("****lintop") return true end)
                    )
                    + 
                    (
                        (G.scp_col_lev) * (G.scp_sbc_lev)^-1
                        * Cmt(Cc("__explicit"), function() print("****coltop") return true end)
                    )
                    +
                    ( 
                        (G.scp_sbc_lev)
                        * Cmt(Cc("__explicit"), function() print("****sbctop") return true end)
                    )
                )
                
            , "SCP")
            * Cmt(Cc("__explicit"), function() print("****scopefound") return true end)
        )
        + Err("invalid scope")

    --Target
    --G.target =      Cg( (G.scope) + error_"Invalid target.", "TRG" )
    --G.content =     Cg( (G.expression) + (G.scope)^-1, error_"Invalid content." "CNT" ) --or expression
    --
    G.target =      (
                        Cg( (G.scope)
                            --* ((#G.cnt_sep + #G.msg_sep) - 1)
                        , "TRG" )
                        * Cmt(Cc("__explicit"), function() print("****msgpartinc") counter_msg_part = counter_msg_part + 1 return true end)
                    )
                    + Err("invalid target")
    G.content =     (
                        Cg( 
                            (G.expression)
                            + ((G.scope)^-1)
                            --* (#G.msg_sep - 1)
                        , "CNT" )
                    * Cmt(Cc("__explicit"), function() print("****msgpartinc") counter_msg_part = counter_msg_part + 1 return true end)
                    )
                    + Err("invalid content")

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


function parse(msg)
    --[[
    This is the main message parsing function called from main
    --]]
    
    --Parse user input with LPeg
    local parsed = match(G.script, msg)

    --Work out implicit values
     

    --Back with process_data
    return parsed
end
