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

--[[
local function check_macro_assign(tokenstream)
    local macro_content
    local macro_identifier
    --find next @
    --if not found,
        --return false
    --else
        --if first:
            --nothing to assign, error. abort
        --if last:
            --no macro identifier, error. abort
        --if middle:
            --split into msg, rest TokenStreams
            --push msg into macro_content , name with macro identifier
            --(remove the ;)
            --return macro tokendata --TODO:FORMAT
        --end
    --end, PARSE FINISHED! 
end
--]]

--[[
local function check_macro_expand(msg_tokenstream)
    local expanded_tokenstream
    --find macro expand tokenstream
    --find next &
    --if not found,
        --return false
    --else
        --if last,
            --"cannot find macro identifier" -error
            --abort,
        --else
            --replace macro token with stored tokenstream (lookup from vader.lex.macros)
        --end
    --go back to finding next, FROM end position!
    
    --return expanded tokenstream
end
--]]

--[[
--Tokenize function not needed in LPeg branch
local function tokenize(input_charstream)
    -- Takes in a charstream, returns a tokenstream
    -- This is returned as result of tokenizing
    local tokens = TokenStream("input_tokenstream")
    local scanner = CharacterScanner("input_scanner", input_charstream)

    local new_token

    -- Init sub-process logging
    local tokenize_log = ALog("tokenize()", vader.displays.no_display, 0)
    tokenize_log:add_distribute_log(parse_log)

    local function get_next_token()
        -- Main tokenizing function
        -- goes through vader.lex.tokens,
        -- tries to match with start_match.
        -- lex contains special instructions for
        -- some cases.
        -- Runs through ALL of the table,
        -- deciding if newly found match is
        -- better than the one already found
        -- TODO:cleanup. Seems to work but is a mess

        local get_next_token_log = ALog("get_next_token()", vader.displays.no_display, 0)
        get_next_token_log:add_distribute_log(tokenize_log)

        local best_match_string
        local best_match_type
        local best_match_priority
        local best_match_properties
        local characters = Counter() 
        local more_items_count
        local item_compare_string
        local match
        local last_char
        local last_bagged -- Boolean, default false, set to true when got the last char of the string
        local more_chars -- Boolean, additional return value, does the string have more chars to tokenize?

        -- Helper functions
        local function more_characters_in_original()
            -- Expands scanner and returns true if there are more characters in the 
            -- original string to match against
            local success = scanner:expand()
            -- Update last_char character
            last_char = scanner:scan_item(scanner:scan_len())
            if success then
                --debug message
            else
                --debug messsage
            end
            return success
        end

        local function is_match()
            -- Returns true if new character at end of scanner matches
            local success = last_char:find(item_compare_string)
            if success then
                --debug message
            else
                --debug message
            end
            return success
        end
        local function get_more()
            -- Returns true if new characters could still be added AND expands scanner
            local more = more_characters_in_original()

            local success = (more) and (characters:value() < more_items_count or more_items_count == 0) and (is_match())
            if success then
                --debug message
            else
                --debug message
            end
            -- Flip the last bagged switch
            if not more then
                last_bagged = true
            end
            return success
        end
        --------------------

        match = scanner:all_scan_items()
        local a_new_token = Token(match, "unidentified")
        best_match_string = ""
        best_match_type = ""
        best_match_priority = 99999999
        best_match_properties = table.create()

        --assert(#match == 1, "#match not 1, something's wrong") --this was before
        for token_type, tokenize_data in pairs(vader.lex.tokens) do
            -- Loop over vader.lex.tokens to find possible matches to variable:match
            local match_len = tokenize_data[2]
            local compare_table = tokenize_data[3]
            local this_match_priority = 9999
            local this_match_string = ""
            local this_match_type = ""
            local this_match_properties
            if tokenize_data[4] then
                this_match_properties = table.copy(tokenize_data[4])
            else
                this_match_properties = table.create()
            end

            scanner:contract_to_one() --TODO is this needed here?

            -- Put scanner view length similar to match
            if match_len > 1 then
                for i = 1, match_len-1 do
                    scanner:expand()
                end
            end
            match = scanner:all_scan_items()

            if string.find(match, compare_table[1]) then
                -- This is a matching token!
                -- Start counting total match length
                characters:set(#match)
                -- Update token type, string
                this_match_string = match
                this_match_type = token_type
                this_match_priority = tokenize_data[1]
                -- --commented 28.2. seemed unnecessary
                    --if tokenize_data[4] then
                        --this_match_properties = table.copy(tokenize_data[4])
                    --else
                        --this_match_properties = table.create()
                    --end
                --

                --print("found match:"..compare_table[1].."  /  "..match) --debug

                -- See if this match is better than the latest best_match
                -- THIS IS AN IMPORTANT FUNCTION!
                local function replace_with_best_match()
                    local replace_with_best_match_log = ALog("replace_with_best_match()", vader.displays.no_display, 0)
                    replace_with_best_match_log:add_distribute_log(tokenize_log)
                    local win_priority = this_match_priority < best_match_priority
                    local string_longer = (#this_match_string > #best_match_string) 
                    --local type_longer = (#this_match_type > #best_match_type)  --no use?

                    local function choose_this()
                        best_match_string = this_match_string
                        best_match_type = this_match_type
                        best_match_priority = this_match_priority
                        more_chars = not last_bagged --TODO: WHAT THE FUCK IS THIS?
                        -- set token properties
                        best_match_properties = this_match_properties
                    end

                    if  string_longer then
                        if win_priority then
                            -- String longer, win priority
                            choose_this()
                        else
                            -- String longer, lower priority
                            choose_this()
                        end
                    else
                        if win_priority then
                            -- String shorter, win priority
                            choose_this()
                        else
                            -- String shorter, lower priority
                        end
                    end
                end
                replace_with_best_match()
                -- Check if token_type has instructions for matching additional characters
                local more_method_char
                if #compare_table > 1 then
                    more_method_char = compare_table[2]:sub(1,1)
                end
                -- Search for =, + on the second last char in token_type match
                if more_method_char == "+" or more_method_char == "=" then
                    -- matched token_type in vader.lex.tokens has instructions for matching more characters in token
                    -- Try to match more characters into token string
                    -- Check how many items in max should be seeked after
                    more_items_count =  tonumber(compare_table[2]:sub(2,2))
                    assert(more_items_count, "Malformed grammar rule. Expected a + or = character and a number, got:"..more_method_char..more_items_count)

                    -- Store current last char
                    last_char = scanner:scan_item(scanner:scan_len())

                    -- Setup method of matching
                    if more_method_char == "+" then
                        if #compare_table < 3 then
                            -- Find characters that match original token_type match
                            item_compare_string = compare_table[1]
                        else
                            -- Find characters that match the 'rest_match' pattern
                            item_compare_string = compare_table[3]
                        end
                    elseif more_method_char == "=" then
                        -- Find exactly same characters
                        item_compare_string = match
                        -- Handle escapes on special cases
                        --TODO: this only handles 1 char long patterns
                        if item_compare_string == "^" or
                            item_compare_string == "$" or
                            item_compare_string == "(" or
                            item_compare_string == ")" or
                            item_compare_string == "%" or
                            item_compare_string == "." or
                            item_compare_string == "[" or
                            item_compare_string == "]" or
                            item_compare_string == "*" or
                            item_compare_string == "+" or
                            item_compare_string == "-" or
                            item_compare_string == "?" then
                            -- Escaoe
                            item_compare_string = "%"..item_compare_string
                        end
 
                    end

                    -- Search all matching characters
                    while get_more() do
                        -- While is_matching and total_chars<op_instruct, update this_match
                        -- Add into this_match_string 
                        this_match_string = this_match_string..last_char
                        -- Click counter
                        characters:inc()
                    end
                    
                    -- Match has been bagged, handle the scanner position
                    -- Have we hit the end?
                    if not last_bagged then
                        -- We did not hit the end, but failed in finding the current
                        -- Last char suitable. pull scanner .to-end back from over the failchar.
                        -- Scanner:contract()
                        -- remove the failchar from this_match_string
                        -- this_match_string = this_match_string:sub(1, #this_match_string-1)
                        -- Update last_char character
                        last_char = scanner:scan_item(scanner:scan_len())
                    else
                        -- We hit the end and tokenized that too. word!
                    end

                    -- After each expansion, size back to one
                    scanner:contract_to_one()
                    -- Update last_char character
                    last_char = scanner:scan_item(scanner:scan_len())
                else
                    -- token_type has no instructions to match additional characters.
                    -- quit. all chars for token found.
                end

                replace_with_best_match()

                -- Set best match so far
                a_new_token.string = best_match_string
                a_new_token.token_type = best_match_type
                a_new_token.properties = best_match_properties

                -- Reset match total character counter
                characters:reset()

                -- Go again (if more tokens in vader.lex.tokens) or quit
            else
                -- Not a match, this one.
                --print("not a match:"..compare_table[1].."  //  "..match) --debug
            end
        end

        -- loop has now ran over vader.lex.tokens
        if best_match_string and #best_match_string > 0 then
            -- move scanner over to next letter
            for i=1, #best_match_string do
                more_chars = scanner:mv_fwd()
            end
        else
            more_chars = scanner:mv_fwd()
        end

        last_bagged = not more_chars

        return a_new_token, more_chars
    end

    -- The main tokenizing loop
    repeat
        local scan_more
        new_token, scan_more = get_next_token()
        tokens:push(new_token)
    until not scan_more


    -- Done
    return tokens
end
--Tokenize function not needed in LPeg branch
--]]


--[[
--Validate function must be reformatted in LPeg branch
local function validate(input_tokenstream, parse_recursion_level, is_successive_message)
    -- This splits input_tokenstream into its components and generates a tree structure.


    -- This is the first return value, a script-tree
    local script
    -- This is the second return value, the iteration scope
    local it_scp = table.create()
    -- This is the third return value, the content
    local it_cnt = table.create()

    -- Init sub-process logging
    local validate_log = ALog("validate()", vader.displays.no_display, 0)
    validate_log:add_distribute_log(parse_log)
    
    ----------------------------------------
    -- validate() HELPER FUNCTIONS
    ----------------------------------------
    
    local function split_in_n_by_token_type(split_tree, split_token_type, branch_ts_name)

        local split_in_n_by_token_type_log = ALog("split_in_n_by_token_type()", vader.displays.no_display, 0)
        split_in_n_by_token_type_log:add_distribute_log(validate_log)

        -- Generalized tokentree structuring function
        -- Splits stream into parts by token type, creates branches
        -- Used in splitting into msgs according to msg_prefix tokens

        local loop = Switch()
        local iterations = Counter()
        local cursor_at = 1
        while loop.state do
            iterations:inc()
            local next_separator, pos_case = script:find_token_type(split_token_type, cursor_at)
            if next_separator then
                if pos_case == "first" then
                    -- A tokenstream prepended with the split_token
                    -- Make a note about not having to prefix first msg with this
                    vader.logs.warnings:entry("Unnecessary leading "..split_tree.list:item(next_separator).string.." character")
                    -- Remove token
                    script:pop()
                    -- Done for this round
                elseif pos_case == "last" then
                    -- A tokenstream appended with the split_token
                    -- Make a note about not having to add this to the end
                    vader.logs.warnings:entry("Unnecessary trailing "..split_tree.list:item(next_separator).string.." character")
                    -- Remove unneeded token
                    script:pop_end()
                    -- Done for this round
                else
                    if next_separator == cursor_at then
                        -- Two separators after each other in the middle of a script
                        -- Make a note about this
                        vader.logs.warnings:entry("Unnecessary following "..split_tree.list:item(next_separator).string.." character")
                        -- Remove separator
                        script:get(next_separator)
                        -- Done for this round
                    else
                        -- Normal
                        -- Remove separator
                        -- TODO:optional!
                        script:get(next_separator)
                        -- Branch into msg
                        local sub_tree = script:sub(branch_ts_name, cursor_at, next_separator - 1)
                        local sub_token = Token(branch_ts_name, branch_ts_name)
                        script:replace_w_tree(branch_ts_name, cursor_at, next_separator - 1, sub_token, sub_tree)
                        -- Set cursor position
                        cursor_at = cursor_at + 1
                    end
                end

            else
                -- Was not found any more
                -- Get all from cursor position to end
                local sub_tree = script:sub(branch_ts_name, cursor_at, #script)
                local sub_token = Token(branch_ts_name, branch_ts_name)
                script:replace_w_tree(branch_ts_name, cursor_at, #script, sub_token, sub_tree)
                -- Exit
                --vader.logs.debug:entry("Found "..(iterations.count-1).." message separators", 3)
                split_in_n_by_token_type_log:entry("Separated "..#script.." valid messages from script")
                loop:off()
            end
            --Check if an endless loop situation was faced
            vader_assert(iterations.count < vader.LOOP_SAFETY_LIMIT, "Something went wrong in "..branch_ts_name.." split-in-n loop, exited after "..iterations.count.." iterations")
        end
        iterations:reset()
        return split_tree
        --pcs is the number of pieces returned
    end

    ----------------------------------------
    -- validate() FUNCTION MAIN
    ----------------------------------------
    --Check if this parse function has been called as a 'subitem'
    --from a user inputted script that has several messages
    local is_subitem_parse
    if parse_recursion_level then
        is_subitem_parse = true
    end

    if not is_subitem_parse then
        -- This seems like a user input message. Prepare it.
        -- Split into msg parts
        local notes
        --Create a fresh tree
        script = TokenTree("script_tree", input_tokenstream)
        script = split_in_n_by_token_type(script, "<prfx addt msg>", "<msg>")
        -- Script is now msg tokens with sub-branches only

        -- Redistribute msgs into separate PARSE calls
        if #script > 1 then
            -- Script has more than 1 messages
            for _, subitem in ipairs(script.branches.items) do
                -- Call parse on each one separately.
                validate_log:entry("Parsing a sub-item")
                -- Log
                local new_log_entry = vader.logs.main:entry("SUBITEM PARSE")
                -- Add to Directives for parsing
                local parse_directive = VaderDirective("PARSE", new_log_entry)
                parse_directive:new_argument(subitem)
                parse_directive:new_argument((parse_recursion_level or 0) + 1)
                if _ > 1 then
                    local is_successive_message = true
                    parse_directive:new_argument(is_successive_message)
                end
                local hold_trigger = true
                vader.directives:entry(parse_directive, hold_trigger)
            end
            -- TODO: will it be possible/reasonable to remove the 'script' layer
            -- from the messages?
            return true
        end
    else
        -- This seems like a subitem parse. Grab the TokenTree
        -- The obscure operation below in short is:
        -- 1) this is a subitem parse. So we know that
        -- instead of a normal tokenstream passed to the validate-
        -- function, the passed item is actually a tokentree.
        -- TODO: this is backwards, and weird.
        -- This tokentree is a <msg> split from a multi-message script
        -- and 'sent back' to validate by the other half of this
        -- if-then-else structure.
        --
        -- 2) knowing that: create an empty script host,
        -- insert the msg branch. This has to be done with some trickery
        -- because of the lack of a dedicated function for this
        -- TODO here.
        local msg_token = Token("<msg>", "<msg>")
        local dummy_token = Token("dummy", "dummy")
        local dummy_stream = TokenStream("dummy")
        dummy_stream:push(dummy_token)
        script = TokenTree("script_tree", dummy_stream)
        script:replace_w_tree("<msg>", 1, 1, msg_token, input_tokenstream)
    end
    --Script should at this point always have just a single message.

    --script:dump_recursive()
    ----------------------------------------
    -- Work each msg branch out
    for msg_index, msg in ipairs(script.branches.items) do
        validate_log:entry("Validating script message "..msg_index) --debug
        -- Split into context areas: target, content, flags
        -- Find all separators
        --TODO: (check for invalid (eg many cnt_prefix ones) separators, error)
        local cnt_prefix, cnt_pos_case = msg:find_token_type("<prfx cnt>")
        local flg_prefix, flg_pos_case = msg:find_token_type_match("<flg ")

        -- Split
        if cnt_prefix then
            if cnt_pos_case == "first" then
                -- Only content part, no target
                validate_log:entry("No target_context found in msg "..msg_index..".")
                -- Remove the unnecessary cnt_prefix token
                msg:pop()
                if flg_prefix then
                    --full content and flag parts
                    validate_log:entry("Cnt and Flg parts found in msg"..msg_index..".")
                    local cnt_token = Token("<cnt>", "<cnt>")
                    local flg_token = Token("<glob flg>", "<glob flg>")
                    msg:branch_by_points({flg_prefix}, {cnt_token, flg_token}, {"<cnt>","<glob flg>"}, "into_next")

                else
                    --no flags part, only content
                    --branch into content
                    validate_log:entry("Only Cnt part found in msg"..msg_index..".")
                    local sub_tree = msg:sub("<cnt>", 1, #msg)
                    local sub_token = Token("<cnt>", "<cnt>")
                    msg:replace_w_tree("<cnt>", 1, #msg, sub_token, sub_tree)
                    --done
                end
            elseif cnt_pos_case == "last" then
                -- Empty content, no flags (since flags cannot be after content)
                -- Unnecessary :
                validate_log:entry("No content_context found in msg "..msg_index..". Unnecessary trailing : character.")
                -- Remove separator
                msg:pop_end()
                -- Branch into target
                local sub_tree = msg:sub("<trg>", 1, #msg)
                local sub_token = Token("<trg>", "<trg>")
                msg:replace_w_tree("<trg>", 1, #msg, sub_token, sub_tree)
                -- Done
            else
                -- Target and content part
                if flg_prefix then
                    -- Full target, content and flag parts
                    validate_log:entry("Trg, Cnt and Flg parts found in msg"..msg_index..".")
                    local trg_token = Token("<trg>", "<trg>")
                    local cnt_token = Token("<cnt>", "<cnt>")
                    local flg_token = Token("<glob flg>", "<glob flg>")
                    msg:branch_by_points({cnt_prefix, flg_prefix}, {trg_token, cnt_token, flg_token}, {"<trg>", "<cnt>", "<glob_flg>"}, {"remove", "into_next"})
                else
                    -- Target and content only. No flags.
                    validate_log:entry("Found target and content contexts in msg "..msg_index..".")
                    -- Branch into target, content
                    local trg_token = Token("<trg>", "<trg>")
                    local cnt_token = Token("<cnt>", "<cnt>")
                    msg:branch_by_points({cnt_prefix}, {trg_token, cnt_token}, {"<trg>", "<cnt>"}, "remove")
                end
            end
        else
            -- no cnt separator: no cnt
            if flg_prefix then
                -- Target and flag part
                -- Full target and flag parts
                validate_log:entry("Trg and Flg parts found in msg"..msg_index..".")
                local trg_token = Token("<trg>", "<trg>")
                local flg_token = Token("<glob flg>", "<glob flg>")
                msg:branch_by_points({flg_prefix}, {trg_token, flg_token}, {"<trg>","<glob flg>"}, "into_next")
            else
                -- No flags part, only target
                -- Branch into target
                validate_log:entry("Only Trg part found in msg"..msg_index..".")
                local sub_tree = msg:sub("<trg>", 1, #msg)
                local sub_token = Token("<trg>", "<trg>")
                msg:replace_w_tree("<trg>", 1, #msg, sub_token, sub_tree)
                -- Done
            end
        end

        --Contexts are now split
        
        ----------------------------------------
        -- Work each context out
        --
        -- Subfunctions for context processing
        local function split_in_scope_partials(cxt, tags)
            local split_in_scope_partials_log = ALog("split_in_scope_partials()", vader.displays.no_display, 0)
            split_in_scope_partials_log:add_distribute_log(validate_log)
            -- Splits a fresh cxt in scope partials
            local tags_at = tags[1]
            local tagnames = tags[2]
            if #cxt == 1 or #tags_at == 1 then
                -- Special case: 1 partial long target.
                -- Branch
                split_in_scope_partials_log:entry("Found only one partial: "..tagnames[1])
                local sub_tree = cxt:sub("<scope partial>", 1, #cxt)
                local sub_token = Token("<scope partial>", "<scope partial>")
                cxt:replace_w_tree("<scope partial>", 1, #cxt, sub_token, sub_tree)
            else
                -- Normal case: multiple partials
                local logmsg = "Splitting to partials: 1"
                for _ = 1, #tags_at do
                    logmsg = logmsg..vader.LOG_DEFAULT_SEPARATOR..tagnames[_]..vader.LOG_DEFAULT_SEPARATOR..tags_at[_]
                end
                -- Split
                -- Remove all scopetags that are at position 1 to avoid splitting there
                for key, value in pairs(tags_at) do
                    if value == 1 then
                        table.remove(tags_at, key)
                        table.remove(tagnames, key)
                    end
                end
                -- Split and branch at scopetag points
                split_in_scope_partials_log:entry("Splitting to partials at:")
                cxt:branch_by_points(tags_at, tagnames, tagnames, "into_next")
            end
            return true
        end

        local function validate_partial(scp, tags)
            -- Validates a single scope partial
            local tags_at = tags[1]
            local tagnames = tags[2]

            local validate_partial_log = ALog("validate_partial() ["..scp.name.."]", vader.displays.no_display, 0)
            validate_partial_log:add_distribute_log(validate_log)

            -- Get this scope level
            local scp_level = scp:item(1):has_match_in_property_string("_level")
            local scp_string
            if not scp_level then
                -- First Token is still not a scopetag. Bummer!
                vader_error("Malformed partial ["..scp.name.."]")
            else
                -- Deliver scope property to all tokens
                scp:set_property(scp_level)
                -- Get this partial scope
                scp_string = string.sub(scp:item(1).token_type, 11, scp:item(1).token_type:find("[ >]", 12) - 1) --TODO! THIS IS THE SHIT! THIS BREAKS EVERYTHING RIGHT NOW.
                -- Set this partial scope to tree
                scp.scope = scp_string
                --split into tag, rangedef, flags
            end

            --Split into tag / range definition
            if #scp > 1 then
                --print("Separating the scopetag from rest of scope partial:")--debug
                --scp:item(1):dump()--debug
                scp:branch_by_points({1},{"<scopetag>", "<range definition>"}, {"<scopetag>", "<range definition>"}, "into_prev")
            else
                --it's a scope partial with a single scopetag and should not be split further
                local sub_tree = scp:sub("<scopetag>", 1, 1)
                local sub_token = Token("<scopetag>", "<scopetag>")
                scp:replace_w_tree("<scopetag>", 1, 1, sub_token, sub_tree)
            end

            --Parse range definition
            local rng_def = scp:branch(2) 

            --if rng_def then rng_def:dump_recursive() end --debug
            if not rng_def then
                --No range was explicitly defined in the message. Conjure it up.
                local rng_def_tree = TokenTree("range_def_tree")
                rng_def_tree.scope = scp.scope
                --Get scopetag type
                local sct_type = scp:branch(1).list:item(1).token_type
                if sct_type:find("upper>") then
                    --Uppercase scopetag: assume 'each and every' -range
                    local rng_def_stream = TokenStream("<range definition>")
                    rng_def_stream:push(Token("<symbol min>", "<symbol min>"))
                    rng_def_stream:push(Token("<range appendix>", "<range appendix>"))
                    rng_def_stream:push(Token("<symbol max>", "<symbol max>"))
                    --Put it in rng_def_tree
                    rng_def_tree:feed(rng_def_stream)
                elseif sct_type:find("double>") then
                    --Double scopetag: assume 'any non-empty/ every visible' -range
                    local rng_def_stream = TokenStream("<range definition>")
                    --TODO:SET TOKEN PROPERTIES!!!
                    rng_def_stream:push(Token("<symbol min>", "<symbol min>"))
                    rng_def_stream:push(Token("<range appendix>", "<range appendix>"))
                    rng_def_stream:push(Token("<symbol max>", "<symbol max>"))
                    local flag_token = Token("<symbol non empty>", "<symbol non empty>")
                    flag_token:set_property("is range flag")
                    rng_def_stream:push(flag_token)
                    --Put it in rng_def_tree
                    rng_def_tree:feed(rng_def_stream)
                    --rng_def_tree:dump()--debug
                else
                    --Normal scopetag: assume 'only current' range
                    local rng_def_stream = TokenStream("<range definition>")
                    rng_def_stream:push(Token("<value current>", "<value current>"))
                    --Put it in rng_def_tree
                    rng_def_tree:feed(rng_def_stream)
                end

                --put rng_def_tree in scp
                local rng_def_token = Token("<range definition>", "<range definition>")
                scp:push(rng_def_token)
                scp:replace_w_tree("<range definition>", 2, 2, rng_def_token, rng_def_tree)

                --redefine rng_def
                rng_def = scp:branch(2) 
                --rng_def:dump_recursive()--debug
            end

            -- De-nest a possibly nested range def
            rng_def:denest()

            -- Split into range and flags by finding the first flag in 'root'

            -- make root 'visible' by putting 1st level stuff in nest
            validate_log:entry("Pulling out root level in rng_def by branching root level nests)")
            rng_def:branch_nests()

            -- Separate the flags and range part first
            local flg_start, pos_case = rng_def:find_token_property("is range flag")
            if not flg_start then
                -- No flags
                -- Create an empty flags item, split & branch
                local flg_token = Token("<nothing-token>", "<nothing-token>")
                rng_def:push(flg_token)
                rng_def:branch_by_points({#rng_def}, {"<range>", "<flags>"}, {"<range>", "<flags>"}, "into_next")
            else
                -- Some flags found, examine further
                if pos_case == "first" then
                    --Flags, but no range
                    -- Create an empty range item, put in range_def start
                    local auto_insert_token = Token("<nothing-token>", "<nothing-token>")
                    rng_def:push_end(auto_insert_token)
                    flg_start = 2
                    -- recreated range def. now can split.
                else
                    -- both flags and range found
                    -- Okay. roll by.
                end
                -- Split & branch
                rng_def:branch_by_points({flg_start}, {"<range>", "<flags>"}, {"<range>", "<flags>"}, "into_next")
            end

            --rng_def:dump_recursive()--debug

            local rng = rng_def:branch(1)
            local flg = rng_def:branch(2)

            -- TODO: make this a general function! Range derivation is a common enough task!
            -- Find range separator, derive start, end values accordingly


            --Get the range separator point
            local rng_apx, pos_case = rng:find_token_type("<range appendix>")
            --Rephrase the flag start
            local flg_start = rng:find_token_type("<flags>")
            if not rng_apx then
                -- No range def separator, assume a single value range
                validate_log:entry("No range appendix in range definition:"..rng.name..". Assuming a single item range")
                local start_token = Token("<range value start>", "<range value start>")
                local start_tokentree = rng:sub("<range value start>", 1, #rng)
                rng:replace_w_tree("<range value start>", 1, #rng, start_token, start_tokentree) 
                local end_token = Token("<range value end>", "<range value end>")
                local end_tokentree = start_tokentree:duplicate()
                rng:push(end_token)
                rng:replace_w_tree("<range value end>", 2, #rng, end_token, end_tokentree) 
            else

                -- A range def separator was found, examine further
                -- Apply the shortcuts for max, min values
                if pos_case == "first" then
                    -- Check for a syntax error
                    vader_assert(#rng > 1, "No start or end value in range definition", true)
                    -- No start value, but a range apx still: replace start value with "min"
                    -- Insert a 'min' symbol to tree start.
                    validate_partial_log:entry("Filled in a shorthand range start min definition")
                    local auto_insert_token = Token("<symbol min>", "<symbol min>")
                    rng:push_end(auto_insert_token)
                    rng_apx = 2
                elseif pos_case == "last" then
                    -- No end value, but a range apx still: replace end value with "max"
                    -- Insert a 'max' symbol to tree end.
                    validate_partial_log:entry("Filled in a shorthand range end max definition")
                    local auto_insert_token = Token("<symbol max>", "<symbol max>")
                    rng:push(auto_insert_token)
                else
                    -- Both start and end values found.
                    -- all's a-ok. roll by.
                end

                -- Validate Range based on # of tokens. Should be exactly 3. (Start, separator, end)
                vader_assert(#rng == 3, "Invalid range definition", true)

                -- Split into a real range_def
                local start_token = Token("<range value start>", "<range value start>")
                local end_token = Token("<range value end>", "<range value end>")
                rng:branch_by_points({rng_apx}, {start_token, end_token}, {"<range value start>","<range value end>"}, "remove")
            end
            --rng_def:dump_recursive()--debug
            -- User inputted range definition is now deconstructed
            -- Solve range tokenstreams down to number values
            local rng_val_start = rng:branch(1)
            local rng_val_end = rng:branch(2)

            rng_val_start:solve()

            if rng_val_end then
                rng_val_end:solve()
            end

            -- Range is now solved into start, end number values
            -- This scope partial is done
            return true
        end

        for cxt_index, cxt in pairs(msg.branches.items) do

            validate_log:entry("Context processing stage "..cxt_index..vader.LOG_DEFAULT_SEPARATOR..cxt.name)
            ----------------------------------------
            -- Target handling
            if cxt.name == "<trg>" then
                local trg = cxt
                trg.list:set_property("target context")
                --structure nests to bring out root level
                trg:branch_nests()
                --find scopetags
                --start by initializing tables for split function
                local tags_at = table.create()
                local tagnames = table.create()
                table.insert(tagnames, "<scope partial>")
                --collect and fill tables
                for index = 1, #trg.list do
                    local token = trg.list:item(index)
                    if token:has_property("is scopetag") then
                        table.insert(tags_at, index)
                        table.insert(tagnames, "<scope partial>")
                    end
                end

                -- Inspect some possible errors for target context
                -- Test if any scopetags. else. fail.
                vader_assert(#tags_at > 0, "Target context needs to have at least one scopetag.", true)

                -- Test if trg starts with scopetag. else. fail.
                vader_assert(table.find(tags_at, 1), "Target definition has to start with a scopetag.", true)

                local tags = {tags_at, tagnames}
                split_in_scope_partials(trg, tags)

                -- Work each scope partial out
                for scp_index, scp in pairs(trg.branches.items) do
                    validate_partial(scp, tags)
                end

                -- All scope partials worked out

                -- Create a valid ScopeObject, assign to the
                -- it_scp -return value
                it_scp[msg_index] = ScopeObject(trg)

            end
            -- Target context case worked out
            -- debug:
            --if type(it_scp[msg_index]) == "TokenTree" then it_scp[msg_index]:dump_recursive() end

            ----------------------------------------
            -- Content handling
            if cxt.name == "<cnt>" then
                
                local cnt = cxt
                cnt.list:set_property("content context")

                --structure nests to bring out root level
                cnt:branch_nests()

                --find (possible) scopetags
                --start by initializing tables for split function
                local tags_at = table.create()
                local tagnames = table.create()
                table.insert(tagnames, "<scope partial>")
                --collect and fill tables
                for index = 1, #cnt.list do
                    local token = cnt.list:item(index)
                    if token:has_property("is scopetag") then
                        table.insert(tags_at, index)
                        table.insert(tagnames, "<scope partial>")
                    end
                end

                -- Find out the basic type of content (number or scope)
                local cnt_main_type = ""
                if table.find(tags_at, 1) == nil then
                    --does not start with a scopetag. is interpret as a plain number content.
                    validate_log:entry("Content is interpret as a plain number content."..cxt_index)
                    cnt_main_type = "number"
                    -- Test if has scopetag and starts with a number
                    vader_assert(#tags_at == 0, "Content cannot start with a number, when it also has scopetags.")
                else
                    --starts with a scopetag. is interpret as a scope content.
                    validate_log:entry("Content is interpret as a scope content."..cxt_index)
                    cnt_main_type = "scope"
                end

                if cnt_main_type == "number" then
                    --Work out a plain number content
                    --Check that it's not a range.
                    local cnt_sub_type = nil
                    if #cnt == 3 then
                        if cnt:item(2).token_type == "<range appendix>" then
                            cnt_sub_type = "range"
                            not_implemented("Range in content")
                        end
                    end
                    
                    -- Get target scope level, object
                    local trg_level_index
                    local trg_level
                    if it_scp[msg_index] then
                        trg_level_index = it_scp[msg_index].lowest_index
                        trg_level = it_scp[msg_index].scope[trg_level_index]
                        -- Set as scope to cnt
                        cnt.scope = trg_level.name
                    else
                        --It's a cnt only msg
                    end
                    
                    --cnt:dump_recursive() --debug
                    -- Solve the number(s)
                    if cnt_sub_type == "range" then
                        --Solve it
                        cnt:branch(3):solve()
                        cnt:branch(1):solve()
                        --debug:
                        --cnt:item(3):dump()
                        --cnt:item(1):dump()
                        --cnt:dump_recursive()
                    else
                        --It's a derivable to a single number
                        cnt:solve()
                    end

                    -- Assign the solved value into the
                    -- it_cnt -return value
                    it_cnt[msg_index] = cnt
                    print(it_cnt[msg_index])--debug
                    print(it_cnt[msg_index].resolved)--debug
                elseif cnt_main_type == "scope" then
                    --Work out a scope content
                    --cnt:branch_nests() --this has been already done!
                    --Split in scope partials
                    local tags = {tags_at, tagnames}
                    split_in_scope_partials(cnt, tags)
                    --Work each scope partial out
                    for scp_index, scp in pairs(cnt.branches.items) do
                        validate_partial(scp, tags)
                    end

                    --Create a scope object, assign to it_cnt
                    it_cnt[msg_index] = ScopeObject(cnt) 

                else
                    --Could not recognize content main type!
                    vader_error("Could not recognize content main type!")
                end
                validate_log:entry("Content processed:")
                --cnt:dump_recursive()
            end
            -- Content context case worked out

            ----------------------------------------
            -- Flags handling
            if cxt.name == "<glob flg>" then
                local glob_flg = cxt
                glob_flg.list:set_property("global flag context")
                for _, flag in pairs(glob_flg.list.items) do
                    --EXIT
                    if flag.token_type == "<flg exit>" then
                        vader.PROMPT_CLOSE_AFTER_FINISH = true
                    elseif flag.token_type == "<flg exit 2>" then
                        vader.PROMPT_CLOSE_AFTER_FINISH = true
                    elseif flag.token_type == "<flg noexit>" then
                        vader.PROMPT_CLOSE_AFTER_FINISH = false
                    elseif flag.token_type == "<flg noexit 2>" then
                        vader.PROMPT_CLOSE_AFTER_FINISH = false
                    --MOVE
                    elseif flag.token_type == "<flg move>" then
                        vader.PROCESS_MOVE_CURSOR = true
                    elseif flag.token_type == "<flg move 2>" then
                        vader.PROCESS_MOVE_CURSOR = true
                    elseif flag.token_type == "<flg nomove>" then
                        vader.PROCESS_MOVE_CURSOR = false
                    elseif flag.token_type == "<flg nomove 2>" then
                        vader.PROCESS_MOVE_CURSOR = false
                    end
                    --SELECT
                    if flag.token_type == "<flg select>" then
                        vader.PROCESS_MAKE_SELECTION = true
                    elseif flag.token_type == "<flg noselect>" then
                        vader.PROCESS_MAKE_SELECTION = false
                    elseif flag.token_type == "<flg select 2>" then
                        vader.PROCESS_MAKE_SELECTION = true
                    elseif flag.token_type == "<flg noselect 2>" then
                        vader.PROCESS_MAKE_SELECTION = false
                    end
                end
            end
            -- Global flag context case worked out


        end
        --Message contexts worked out

        
        -- for each message 
        -- Add processes in directivelist
        --
        -- TODO:CLEANUP arguments into a reasonable format
        -- trg = {
            -- trg_type (solved in parse!)
            -- trg_tree
            -- trg_resolved at parse
            -- }
        -- cnt = {
            -- trg_type (solved in parse!)
            -- trg_tree
            -- trg_resolved at parse
            -- }
        --TODO:script flag passing!
        -- flg = {
        --      table of: flag token type, value
        --      }
        --
        --TODO:ACTUALLY JUST PARSE EVERYTHING SO THAT ONLY SCOPES CAN BE PASSED
        --TO PROCESS. THIS WAY EVERYTHING BECOMES SIMPLER IN THE PROCESS END, AND
        --ALL THE TYPE VARIATION CRAP CAN BE REMOVED FROM PROCESS.

        --vader.debug:entry("adding a process directive for message "..msg_index)
        -- Put parse success in main log
        local new_log_entry = vader.logs.main:entry("process", 1)
        -- Add to Directives for processing
        local process_directive = VaderDirective("PROCESS", new_log_entry)
        local content_pack = {
            ["static"] = (it_cnt[msg_index] and it_cnt[msg_index].resolved),
            ["dynamic"] = it_cnt[msg_index]
        }
        process_directive:new_argument(it_scp[msg_index])
        process_directive:new_argument(content_pack)
        process_directive:new_argument(is_successive_message)
        -- PROCESSing must be done before sequential PARSEs,
        -- so use entry_at instead of entry. This puts the 
        -- PROCESS-directive first in top of the queue.
        vader.directives:entry_at(process_directive, #vader.directives)
    end
    -- Script worked out


    -- the script tree is generated and ready to be given to parse
    return script

end
--Validate function must be reformatted in LPeg branch
--]]



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
--debug.start()
    local parsed_input = match(G.script, input_msg)
--debug.stop()
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

        --[[
        if has_TRG then
            --validate scope
            --scope shorthand 
            for _, scopetag in pairs (TRG["SCP"]) do
                scopetag_string = scopetag["__string"]
                for __, match_index in pairs (vader.lex.scope_levels) do
                    


                end
            end
        end
        --]]


    ----------------------------------------
    -- Global Flags handling
    --[[
    if cxt.name == "<glob flg>" then
        local glob_flg = cxt
        glob_flg.list:set_property("global flag context")
        for _, flag in pairs(glob_flg.list.items) do
            --EXIT
            if flag.token_type == "<flg exit>" then
                vader.PROMPT_CLOSE_AFTER_FINISH = true
            elseif flag.token_type == "<flg exit 2>" then
                vader.PROMPT_CLOSE_AFTER_FINISH = true
            elseif flag.token_type == "<flg noexit>" then
                vader.PROMPT_CLOSE_AFTER_FINISH = false
            elseif flag.token_type == "<flg noexit 2>" then
                vader.PROMPT_CLOSE_AFTER_FINISH = false
            --MOVE
            elseif flag.token_type == "<flg move>" then
                vader.PROCESS_MOVE_CURSOR = true
            elseif flag.token_type == "<flg move 2>" then
                vader.PROCESS_MOVE_CURSOR = true
            elseif flag.token_type == "<flg nomove>" then
                vader.PROCESS_MOVE_CURSOR = false
            elseif flag.token_type == "<flg nomove 2>" then
                vader.PROCESS_MOVE_CURSOR = false
            end
            --SELECT
            if flag.token_type == "<flg select>" then
                vader.PROCESS_MAKE_SELECTION = true
            elseif flag.token_type == "<flg noselect>" then
                vader.PROCESS_MAKE_SELECTION = false
            elseif flag.token_type == "<flg select 2>" then
                vader.PROCESS_MAKE_SELECTION = true
            elseif flag.token_type == "<flg noselect 2>" then
                vader.PROCESS_MAKE_SELECTION = false
            end
        end
    end
    --]]

    -- Parse is a success
    parse_log:entry("success.") --debug

    -- Get info stored
    vader.logs.main:join_log(parse_log:compress())


    -- Setup this message for processing
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
    ----->>>WED: TRYING TO MAKE PROCESSING WORK!

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

function dummylol()

    --vader.logs.debug:entry("Parsing message: '"..input_msg.."' ...") --debug
    
    --TODO:these are not needed
    local input_script, error, notes

    if not is_subitem_parse then
        -- This seems like a user inputted message. Prepare it.
        -- Initial input definition
        local input_charstream = CharacterStream("input stream", input_msg) --TODO: CharacterStream should be an invisible class
        local input_charscan = CharacterScanner("input char scanner", input_charstream)

        -- Tokenize
        parse_log:entry("Tokenizing...") --debug
        local input_tokenstream = tokenize(input_charstream) -- Return tokenstream 
        parse_log:entry("Tokenized succesfully.") --debug
        --[[
        --if not input_tokenstream then
            --vader.logs.debug:entry("Invalid input: "..input_msg) --debug
            --vader.logs.main:entry("Invalid input: "..input_msg)
            --TODO:error handling here!
        else
            --vader.logs.debug:entry("Tokenized succesfully.", 5) --debug
        end
        --]]
        
        --input_tokenstream:dump()
        -- Macro related checks here!
        --
        --
        --

        -- Transform tokenized input into a valid script tree,
        -- and extract scope with validate()
        --vader.logs.debug:entry("Validating...", 5) --debug
        -- Validate. Several scripts are split in validate into subitems for parsing.
        parse_log:entry("Validating (split phase)...") --debug
        input_script = validate(input_tokenstream, parse_recursion_level, is_successive_message)
        parse_log:entry("Validated succesfully.") --debug
    else
        --This seems like a subitem parse, just send it again to validate()
        --The input_msg part here might seem broken, but it's actually a TokenTree
        parse_log:entry("Validating (single msg phase)...") --debug
        input_script = validate(input_msg, parse_recursion_level, is_successive_message)
        parse_log:entry("Validated succesfully.") --debug
    end



end
