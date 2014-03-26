--
--classes.lua
--
----------------------------------------------------
-- file created         05-Jan-2012

-- All classes used in tool
-- They are put in subsections and
-- the function parts are wrapped
-- in do, end chunks for:
-- 1)auto folding/syntax based intendation in Vim
-- 2)readability

----------------------------------------------------
-- Globals declaration, initialization
----------------------------------------------------
-- Project wide globals (local representation)
local vader
-- File globals
local method_log

----------------------------------------------------
-- Boot procedure, initialization
----------------------------------------------------

function boot_classes(main_vader)
    -- Project Globals
    vader = main_vader
end

--[[
The Method Log

the method log acts as the "classes.lua" general log.

For functions that need logging:
1)register_method_log(type(self)..":<function_name>()")
2)use "method_log:entry()" to enter stuff in log
-]]

function init_method_log(main_vader)
    --This is called from main.lua to init this submodule log
    method_log = ALog("generic_class_method()", vader.displays.no_display, 0)
    method_log:add_distribute_log(vader.logs.active_task)
end

function name_method_log(name)
    vader_assert(type(name) == "string", "Tried to update method_log.name with name type:"..type(name)..". Use a string.")
    -----------------
    if method_log then
        method_log.name = name
    end
end

function register_method_log(name)
    --[[
    Call this in function to take into use the general method log
    preferred syntax for name:

    <class_name>:<function_name>()

    --]]
    vader_assert(type(name) == "string", "Tried to update method_log.name with name type:"..type(name)..". Use a string.")
    -----------------
    if method_log then
        local method_log
        method_log = ALog(name, vader.displays.no_display, 0)
        method_log:add_distribute_log(vader.logs.active_task)
        return method_log
    end
end

----------------------------------------------------
-- Helper classes
----------------------------------------------------

class "Counter"
-- A simple multipurpose 'click' counter
do
    function Counter:__init()
        self.count = 0
    end
    function Counter:inc()
        self.count = self.count + 1
    end
    function Counter:dec()
        self.count = self.count - 1
    end
    function Counter:reset()
        self.count = 0
    end
    function Counter:set(number)
        --[[
        Set to number
        --]]
        
        ------------------
        -- Error catching
        vader_assert(type(number) == "number", "Tried to set a Counter with number type:"..type(number)..". Use a number.")
        vader_assert(number - math.floor(number) == 0, "Tried to set a Counter with float value:"..number..". Use an integer.")
        -------------
        
        self.count = number
    end
    function Counter:value()
        --[[
        Return the counter value
        --]]
        return self.count
    end
end

class "Switch"
-- A simple switch, essentially just a wrapper for a boolean
do
    function Switch:__init(state)
        --[[
        Initialize with state "state". If "state" is nil, self.state=on
        --]]
        self.state = true
        if state ~= nil then
            self.state = state
        end
    end
    function Switch:on()
        self.state = true
    end
    function Switch:off()
        self.state = false
    end
    function Switch:toggle()
        self.state = not self.state
    end
end

----------------------------------------------------
-- Generalized list classes
----------------------------------------------------

class "AList"
--[[
General list, stack, queue functions and properties
A super for several subclasses
--]]
do
    function AList:__init(name_string, item_table, is_sparse)
        --[[
        Name string is self-evident
        item_table can be used to init the AList with a ready table
        is_sparse =true : will store nils as placeholders.
        is_sparse =not true : attempting to store a nil value raises an error
        --]]
        
        -----------------
        -- Error catching
        vader_assert(name_string, "Tried to init "..type(self).." with a nil name argument. Use a string.")
        vader_assert(type(name_string) == "string", "Tried to init "..type(self).." with name argument type:"..type(name_string)..". Only accepted type is string.")
        ---------------
        
        self.name = name_string
        self.items = table.create()
        self.content_type = nil
        self.is_sparse = is_sparse
        self.max_len = nil
        -- handle initializing with a item_table
        if item_table then
            self:feed(item_table)
        end
    end
    function AList:__len()
        --[[
        Overload the length operator
        So that list item count can be queried with simple #AList
        --]]
        return #self.items
    end
    function AList:item(index)
        --[[
        Returns an item with index
        --]]
        
        -----------------
        -- Error catching
        vader_assert(type(index) == "number", "Trying to get "..type(self).." ("..self.name..") item with index type:"..type(index)..". Use a number.")
        vader_assert(index > 0 and index <= #self.items, "Trying to get "..type(self).." ("..self.name..") item index:"..index..", self.items index range is 1 - "..#self.items)
        -----------------
        
        return self.items[index]
    end
    function AList:all_items()
        --[[
        Returns the item table
        --]]
        return self.items
    end
    function AList:first()
        --[[
        Returns the first item
        --]]
        
        -----------------
        -- Error catching
        vader_assert(index > 0, "Trying to get "..type(self).." ("..self.name..") first item and self.items is empty.")
        -----------------
        return self.items[1] 
    end
    function AList:last()
        --[[
        Returns last item
        --]]
        
        -----------------
        -- Error catching
        vader_assert(index > 0, "Trying to get "..type(self).." ("..self.name..") last item and self.items is empty.")
        -----------------
        
        if #self.items == 0 then
            return nil
        else
            return self.items[#self.items]
        end
    end
    function AList:top_index()
        --[[
        Returns the index of item next in line for pop()
        --]]
        -- No generalizations
        -- Depends on the subclass
    end
    function AList:bottom_index()
        --[[
        Returns the logical opposite index of item next in line for pop()
        --]]
        -- No generalizations
        -- Depends on the subclass
    end
    function AList:top()
        --[[
        Returns the item next in line for pop()
        --]]
        local index = self:top_index()
        if index == nil then
            return nil
        else
            return self:item(index)
        end
    end
    function AList:bottom()
        --[[
        Returns the item last in line for pop() (first for pop_end())
        --]]
        local index = self:bottom_index()
        if index == nil then
            return nil
        else
            return self:item(index)
        end
    end
    function AList:clear()
        --[[
        Empties self.items table
        --]]
        self.items = table.create()
    end
    function AList:push(item)
        --[[
        Inserts item in self.items from one end. (Defined by sub-class)
        --]]
        
        -----------------
        -- Error catching
        if not self.is_sparse then
            vader_assert(item ~= nil, "Tried to push a nil object in "..type(self).." ("..self.name..")")
        end
        if item == nil then
            --is_sparse = true, because would've been catched above if not
            item = vader.NIL_PLACEHOLDER_IN_TABLES
        end
        if self.content_type then
            vader_assert(type(item) == self.content_type, "Tried to push a "..type(item).." object in "..type(self).." ("..self.name.."). Content type is "..self.content_type..".")
        end
        -----------------
        
        -- Actual pushing dependant on data structure type. Handled on derived classes.
    end
    function AList:push_end(item)
        --[[
        Inserts item in self.items from one end. (Defined by sub-class)
        --]]
        
        -----------------
        -- Error catching
        vader_assert(item, "Tried to push_end a nil object in "..type(self).." ("..self.name..")")
        if self.content_type then
            vader_assert(type(item) == self.content_type, "Tried to push_end a "..type(item).." object in "..type(self).." ("..self.name.."). Content type is "..self.content_type..".")
        end
        -----------------
        
        -- Actual pushing dependant on data structure type. Handled on derived classes.
    end
    function AList:pop()
        --[[
        Gets an item from self.items from one end. (Defined by sub-class)
        Returns the item defined in top(), top_index(), removes from list
        --]]
        local retval = self:top()
        if retval == nil then
            --out of range index
            return nil
        elseif retval == vader.NIL_PLACEHOLDER_IN_TABLES then
            --a 'nil' in sparse table
            self.items:remove(self:top_index())
            return nil
        else
            --a normal, in-range value
            self.items:remove(self:top_index())
            return retval
        end
    end
    function AList:pop_end()
        --[[
        Gets an item from self.items from one end. (Defined by sub-class)
        Returns the item defined in bottom(), bottom_index(), removes from list
        --]]
        local retval = self:bottom()
        if retval == nil then
            --out of range index
            return nil
        elseif retval == vader.NIL_PLACEHOLDER_IN_TABLES then
            --a 'nil' in sparse table
            self.items:remove(self:bottom_index())
            return nil
        else
            --a normal, in-range value
            self.items:remove(self:bottom_index())
            return retval
        end
    end
    function AList:get(index)
        --[[
        Gets an item from the middle of a list.
        Returns the item, removes from list.
        --]]
        local retval = self:item(index) 
        if retval == nil then
            --out of range index
            return nil
        elseif retval == vader.NIL_PLACEHOLDER_IN_TABLES then
            --a 'nil' in sparse table
            self.items:remove(index)
            return nil
        else
            --a normal, in-range value
            self.items:remove(index)
            return retval
        end
    end
    function AList:insert(item, index)
        --[[
        Inserts item in self.items by index
        --]]
        
        -----------------
        -- Error catching
        if self.is_sparse then
            vader_assert(item, "Tried to insert a nil object in "..type(self).." ("..self.name..")")
        end
        if item == nil then
            --is_sparse = true, because would've been catched above if not
            item = vader.NIL_PLACEHOLDER_IN_TABLES
        end
        if self.content_type then
            vader_assert(type(item) == self.content_type, "Tried to insert a "..type(item).." object in "..type(self).." ("..self.name.."). Content type is "..self.content_type..".")
        end
        vader_assert(type(index) == "number" or type(index) == "nil", "Tried to use "..type(self)..":insert ("..self.name..") with index type:"..type(index)..". Use a number (or nil to insert after last index).")
        vader_assert(index <= #self.items, "Tried to use "..type(self)..":insert ("..self.name..") with index:"..index..". The maximum is #self.items:"..#self.items..". To insert at last position, use nil index argument")
        vader_assert(index > 0, "Tried to use "..type(self)..":insert ("..self.name..") with index:"..index..". The minimum is 1")
        vader_assert(index > 0, "Tried to use "..type(self)..":insert ("..self.name..") with index:"..index..". The minimum is 1")
        -----------------
        
        self.items:insert(index, item)
    end
    function AList:feed(item_table)
        --[[
        Replaces current self.items with item_table
        --]]
        
        -----------------
        -- Error catching
        vader_assert(type(item_table) == "table", "Tried to feed "..type(self).." ("..self.name..") an item_table type:"..type(item_table)..". Use a table of "..(self.content_type or "nil").." objects. (nil = no specified content_type)")
        -----------------
        
        self:clear()
        for key, item in ipairs(item_table) do
            self:push(item)
        end
    end
    function AList:create_empty_instance(name_string)
        --[[
        This is a helper that returns an empty instance of this class. Helps
        functions that return other instances of their class.
        --]]
        -- Specific to each class.
        return AList(name_string)
    end
    function AList:split(at_item, name_1, name_2)
        --[[
        Splits self.items so that first list will contain items 1 - last_item,
        second list will contain items last_item + 1 = #self.items. Returns two
        objects of type type(self) named name_1, name_2 with respective
        self.items -values
        --]]
        
        -----------------
        -- Error catching
        vader_assert(type(at_item) == "number", "Tried to split "..type(self).." ("..self.name..") with split_at argument type:"..type(at_item)..". Use a number.")
        vader_assert(type(name_1) == "string", "Tried to split "..type(self).." ("..self.name..") with name_1 argument type:"..type(name_1)..". Use a string.")
        vader_assert(type(name_2) == "string", "Tried to split "..type(self).." ("..self.name..") with name_2 argument type:"..type(name_2)..". Use a string.")
        vader_assert(#self.items > 0, "Tried to split "..type(self).." ("..self.name.."); self.items is empty.")
        vader_assert(at_item < #self.items, "Tried to split "..type(self).." ("..self.name..") at the last item in self.items, which would result in an empty second instance.")
        -----------------

        local object_1 = self:create_empty_instance(name_1)
        local object_2 = self:create_empty_instance(name_2)
        for item_index = 1, at_item do
            object_1.items[item_index] = self.items[item_index]
        end
        for item_index = at_item + 1, #self.items do
            object_2.items[item_index - at_item] = self.items[item_index]
        end
        return object_1, object_2
    end
    function AList:find_item(condition_function, condition_args, start_index, end_index)
        --[[
        This can be used to search a value within a property table
        This is an abstraction, works together with subclass-specific 'condition-functions'
        --]]
        
        -----------------
        -- Default values
        start_index = start_index or 1
        end_index = end_index or #self.items
        -- Error catching
        vader_assert(type(start_index) == "number", "Tried to use "..type(self)..":find ("..self.name..") with start_index type:"..type(start_index)..". Use a number.")
        vader_assert(type(end_index) == "number", "Tried to use "..type(self)..":find ("..self.name..") with end_index type:"..type(end_index)..". Use a number.")
        vader_assert(start_index <= #self.items, "Tried to use "..type(self)..":find ("..self.name..") with start_index:"..start_index..". The maximum is #self.items:"..#self.items)
        vader_assert(end_index <= #self.items, "Tried to use "..type(self)..":find ("..self.name..") with end_index:"..end_index..". The maximum is #self.items:"..#self.items)
        vader_assert(start_index > 0, "Tried to use "..type(self)..":find ("..self.name..") with start_index:"..start_index..". The minimum is 1")
        vader_assert(end_index > 0, "Tried to use "..type(self)..":find ("..self.name..") with end_index:"..end_index..". The minimum is 1")
        -----------------

        local test_item
        local step
        if start_index > end_index then
            step = -1
        else
            step = 1
        end
        for index = start_index, end_index, step do
            test_item = self:item(index)
            if condition_function(test_item, condition_args) == true then
                local position_case
                if index == self:top_index() then
                    position_case = "first"
                elseif index == self:bottom_index() then
                    position_case = "last"
                else
                    position_case = nil
                end
                return index, position_case
            end
        end
        return nil
    end
    function AList:sub(name_string, start_index, end_index)
        --[[
        Returns a sublist with items from start_index to end_index, named with argument name
        --]]
        
        -----------------
        -- Default values
        start_index = start_index or 1
        end_index = end_index or #self.items
        -- Error catching
        vader_assert(type(name_string) == "string", "Tried to use "..type(self)..":sub ("..self.name..") with name_string type:"..type(name_string)..". Use a string.")
        vader_assert(type(start_index) == "number", "Tried to use "..type(self)..":sub ("..self.name..") with start_index type:"..type(start_index)..". Use a number.")
        vader_assert(type(end_index) == "number", "Tried to use "..type(self)..":sub ("..self.name..") with end_index type:"..type(end_index)..". Use a number.")
        vader_assert(start_index <= #self.items, "Tried to use "..type(self)..":sub ("..self.name..") with start_index:"..start_index..". The maximum is #self.items:"..#self.items)
        vader_assert(end_index <= #self.items, "Tried to use "..type(self)..":sub ("..self.name..") with end_index:"..end_index..". The maximum is #self.items:"..#self.items)
        vader_assert(start_index > 0, "Tried to use "..type(self)..":sub ("..self.name..") with start_index:"..start_index..". The minimum is 1")
        vader_assert(end_index > 0, "Tried to use "..type(self)..":sub ("..self.name..") with end_index:"..end_index..". The minimum is 1")
        -------------------

        local object = self:create_empty_instance(name_string)
        local step
        if start_index > end_index then
            step = -1
        else
            step = 1
        end
        for i = start_index, end_index, step do
            --object:push(self:item(i))
            object:push(self:item(i):duplicate())
        end
        return object
    end
    function AList:replace(start_index, end_index, replace_w_table)
        --[[
        Replaces self.items items from start_index to end_index with items in replace_w_table
        --]]
        
        -----------------
        -- Error catching
        vader_assert(type(start_index) == "number", "Tried to use "..type(self)..":replace ("..self.name..") with start_index type:"..type(start_index)..". Use a number.")
        vader_assert(type(end_index) == "number", "Tried to use "..type(self)..":replace ("..self.name..") with end_index type:"..type(end_index)..". Use a number.")
        vader_assert(start_index <= #self.items, "Tried to use "..type(self)..":replace ("..self.name..") with start_index:"..start_index..". The maximum is #self.items:"..#self.items)
        vader_assert(end_index <= #self.items, "Tried to use "..type(self)..":replace ("..self.name..") with end_index:"..end_index..". The maximum is #self.items:"..#self.items)
        vader_assert(start_index > 0, "Tried to use "..type(self)..":replace ("..self.name..") with start_index:"..start_index..". The minimum is 1")
        vader_assert(end_index > 0, "Tried to use "..type(self)..":replace ("..self.name..") with end_index:"..end_index..". The minimum is 1")
        vader_assert(start_index <= end_index, "Tried to use "..type(self)..":replace ("..self.name..") with start_index:"..start_index.." which is higher than end_index:"..end_index)
        vader_assert(type(replace_w_table) == "table", "Tried to call "..type(self)..":replace ("..self.name..") with replace_w_table argument type:"..type(replace_w_table)..". Use a table of "..self.content_type.." objects.")
        vader_assert(#replace_w_table > 0 , "Tried to call "..type(self)..":replace ("..self.name..") with replace_w_table that has zero items.")
        -------------------
        
        --create sub - lists
        local start_part = table.create()
        if start_index > 1 then
            for i = 1, start_index-1 do
                start_part:insert(self:item(i))
            end
        end
        local end_part = table.create()
        if end_index < #self.items then
            for i = end_index+1, #self.items do
                end_part:insert(self:item(i))
            end
        end
        local mid_part = replace_w_table
        --create combine list and put sublists in it in order
        local combine = table.create()
        if #start_part > 0 then
            for i = 1, #start_part do
                combine:insert(start_part[i])
            end
        end
        for i = 1, #replace_w_table do
            combine:insert(replace_w_table[i])
        end
        if #end_part > 0 then
            for i = 1, #end_part do
                combine:insert(end_part[i])
            end
        end
        --serve the finished list
        self:feed(combine)
    end
    function AList:duplicate()
        --[[
        Returns a verbatim copy
        --]]
        -- Inherited to subclasses that sport the create_empty_instance-method
        local duplicate_list = self:create_empty_instance(self.name)
        duplicate_list.items = table.copy(self.items)
        duplicate_list.content_type = self.content_type
        return duplicate_list
    end
    function AList:adjust(len)
        method_log.name = "AList:adjust()"
        --[[
        TODO: COMMENT THIS
        --]]
        
        -----------------
        -- Error catching
        vader_assert(type(len) == "number" or type(len) == "nil", "Tried to call "..type(self)..":adjust() ("..self.name..") with a len argument type:"..type(len)..". Use a number or nil.")
        if type(len) == "number" then
            vader_assert(len > 0, "Tried to call "..type(self)..":adjust() ("..self.name..") with a len argument smaller than one:"..len..". Use positive, non-zero numbers.")
        end
        -- Default values
        len = len or self.max_len
        -----------------
        
        -- Silent exit conditions
        if len == nil then
            -- Cannot adjust
            return
        end
        if #self < len then
            -- No need to adjust
            return
        end
        method_log:entry("adjusting "..self.name.." to length:"..len, 2)
        --Adjust by popping until #self == len
        while #self > len do
            self:pop()
        end
    end
    function AList:dump()
        --[[
        A debug function
        --]]
        vader.logs.debug:entry(string.format(type(self).." object: '"..self.name.."' dump()"))
        for i = 1, #self.items do
            if self.content_type == "TokenTree" then
                vader.logs.debug:entry("--------")
                self:item(i):dump_recursive()
            elseif self.content_type == "Token" then
                vader.logs.debug:entry("--------")
                self:item(i):dump()
            else
                vader.logs.debug:entry("--------")
                vader.logs.debug:entry(string.format("Item [%i]:", i))
                vader.logs.debug:entry(""..item(i))
            end
        end
        vader.logs.debug:entry("--------")
    end
end

class "AQueue" (AList)
-- General queue functions and properties
do
    function AQueue:__init(name_string, item_table)
        AList.__init(self, name_string, item_table)
    end
    function AQueue:top_index()
        --[[
        Queue pops the item with biggest index
        --]]
        if #self.items == 0 then
            return nil
        else
            return #self.items
        end
    end
    function AQueue:bottom_index()
        --[[
        Return the 'logical' last index in relation to pop()
        --]]
        if #self.items == 0 then
            return nil
        else
            return 1
        end
    end
    function AQueue:push(item)
        AList.push(self, item)
        --[[
        Queue-push insert item in top of the list
        --]]
        -- Push item in list
        self.items:insert(1, item)
    end
    function AQueue:push_end(item)
        AList.push_end(self, item)
        --[[
        Queue-push insert item in top of the list
        --]]
        -- Push item in list
        self.items:insert(item)
    end
    function AQueue:create_empty_instance(name_string)
        --[[
        This is a helper that returns an empty instance of this class. Helps
        functions that return other instances of their class.  Specific to each
        class.
        --]]
        return AQueue(name_string)
    end
end

class "ARevQueue" (AList)
-- General queue functions and properties, reversed order
do
    function ARevQueue:__init(name_string, item_table)
        AList.__init(self, name_string, item_table)
    end
    function ARevQueue:top_index()
        --[[
        Reverse-queue pops the item with smallest index
        --]]
        if #self.items == 0 then
            return nil
        else
            return 1
        end
    end
    function ARevQueue:bottom_index()
        --[[
        Return the 'logical' last index in relation to pop()
        --]]
        if #self.items == 0 then
            return nil
        else
            return #self.items
        end
    end
    function ARevQueue:push(item)
        AList.push(self, item)
        --[[
        Reverse Queue-push inserts item in end of the list
        --]]
        -- Push item in list
        self.items:insert(item)
    end
    function ARevQueue:push_end(item)
        AList.push_end(self, item)
        --[[
        Reverse Queue-push inserts item in end of the list
        --]]
        -- Push item in list
        self.items:insert(1, item)
    end
    function ARevQueue:create_empty_instance(name_string)
        --[[
        This is a helper that returns an empty instance of this class. Helps
        functions that return other instances of their class.  Specific to each
        class.
        --]]
        return ARevQueue(name_string)
    end
end

class "AStack" (AList)
-- General stack functions and properties
do
    function AStack:__init(name_string, item_table)
        AList.__init(self, name_string, item_table)
    end
    function AStack:top_index()
        --[[
        Stack pops the item with smallest index
        --]]
        if #self.items == 0 then
            return nil
        else
            return 1
        end
    end
    function AStack:bottom_index()
        --[[
        Return the 'logical' last index in relation to pop()
        --]]
        if #self.items == 0 then
            return nil
        else
            return #self.items
        end
    end
    function AStack:push(item)
        AList.push(self, item)
        --[[
        Stack-push inserts item in top of the list
        --]]
        -- Push item in list
        self.items:insert(1, item)
    end
    function AStack:push_end(item)
        AList.push_end(self, item)
        --[[
        Stack-push inserts item in top of the list
        --]]
        -- Push item in list
        self.items:insert(item)
    end
    function AStack:create_empty_instance(name_string)
        --[[
        This is a helper that returns an empty instance of this class. Helps
        functions that return other instances of their class.  Specific to each
        class.
        --]]
        return AStack(name_string)
    end
end

class "ARevStack" (AList)
-- General stack functions and properties, reversed order
do
    function ARevStack:__init(name_string, item_table)
        AList.__init(self, name_string, item_table)
    end
    function ARevStack:top_index()
        --[[
        Reverse-stack pops the last item
        --]]
        if #self.items == 0 then
            return nil
        else
            return #self.items
        end
    end
    function ARevStack:bottom_index()
        --[[
        Return the 'logical' last index in relation to pop()
        --]]
        if #self.items == 0 then
            return nil
        else
            return 1
        end
    end
    function ARevStack:push(item)
        AList.push(self, item)
        --[[
        Reverse Stack-push inserts item to the end of the list
        --]]
        -- Push item in list
        self.items:insert(item)
    end
    function ARevStack:push_end(item)
        AList.push_end(self, item)
        --[[
        Reverse Stack-push inserts item to the end of the list
        --]]
        -- Push item in list
        self.items:insert(1, item)
    end
    function ARevStack:create_empty_instance(name_string)
        --[[
        This is a helper that returns an empty instance of this class. Helps
        functions that return other instances of their class.  Specific to each
        class.
        --]]
        return ARevStack(name_string)
    end
end



----------------------------------------------------
-- Displays
----------------------------------------------------

class "ADisplay"
-- General display for directing output into
do
    function ADisplay:__init(name_string, display_function, multilined, multiline_display_function)
        -----------------
        -- Error catching
        vader_assert(name_string, "Tried to init "..type(self).." with nil name_string.")
        vader_assert(type(name_string) == "string", "Tried to init "..type(self).." with a name_string type:"..type(name_string)..". Use string.")
        vader_assert(display_function, "Tried to init "..type(self).." with nil display_function.")
        vader_assert(type(display_function) == "function", "Tried to init "..type(self).." with a display_function type:"..type(name_string)..". Use function value.")
        -- Default values
        self.multilined = multilined or false
        -----------------
        self.name = name_string
        self.display_function = display_function
        self.multiline_display_function = multiline_display_function
    end
    function ADisplay:show(display_object)
        --[[
        Generic show function to output text in any registered display.
        Argument display_object can be a string or a table of strings
        --]]
        
        -----------------
        -- Error catching
        vader_assert(display_object, "Tried to call "..type(self)..":show with nil display_object.")
        if not self.multilined then
            vader_assert(type(display_object) == "string", "Tried to call non-multilined "..type(self)..":show ("..self.name..") with a display_string type:"..type(display_object)..". Use string.")
        else
            local obj_type = type(display_object)
            vader_assert(obj_type == "string" or obj_type == "table", "Tried to call multilined "..type(self)..":show ("..self.name..") with a display_string type:"..obj_type..". Use string or a table of strings.")
            --TODO: check table for types!
        end
        -----------------
        
        -- Display functions and display registering in output.lua
        if type(display_object) == "table" then
            --multiline display
            if not self.multilined then
                --display is not a multiline-display,
                --meaning it does not have a multiline_display_function()
                --do a simple looping over items in table
                for _, item in ipairs(display_object) do
                    self.display_function(display_object)
                end
            else
                --display is registered as a multiline display,
                --use the multiline display function
                self.multiline_display_function(display_object)
            end
        else
            --single line display
            self.display_function(display_object)
        end
    end
end

--[[
TODO: a general vb text display
text, textfield, multiline text, ..?)
--]]

----------------------------------------------------
-- Main process
----------------------------------------------------

class "VaderDirective"
--[[
A processing directive

A directive is an internal command/process object directing the execution of
the program. These are stacked in VaderDirectiveList, and executed from there.
--]]
do
    function VaderDirective:__init(name_string, log_reference)
        -----------------
        -- Error catching
        vader_assert(type(name_string) == "string", "Tried to initialize a VaderDirective with name type:"..type(name_string)..". Only accepted type is string.")
        vader_assert(type(log_reference) == "LogObject", "Tried to initialize a VaderDirective with wrong log_reference type:"..type(log_reference)..". Only accepted type is an existing LogObject.")
        -----------------
        
        self.name = name_string
        self.argument_table = table.create()
        self.state = ""
        self.log_reference = log_reference
        self:update_state("Initialized")
    end
    function VaderDirective:new_argument(argument)
        --[[
        This inserts a new argument to self.argument_table at index. Goes an
        extra mile for allowing storing and returning nil values to / from a
        table
        --]]
        if argument == nil then
            self.argument_table:insert(vader.NIL_PLACEHOLDER_IN_TABLES)
        else
            self.argument_table:insert(argument)
        end
    end
    function VaderDirective:arguments()
        --[[
        This returns all arguments from self.argument_table in 'unpacked' form
        to use with function calls.  Goes an extra mile for allowing storing
        and returning nil values to / from a table
        --]]
        local temp_args = table.copy(self.argument_table)
        local function unpack2(t)
            if #temp_args == 0 then
                return
            else
                local v = table.remove(t, 1)
                if v == vader.NIL_PLACEHOLDER_IN_TABLES then v = nil end
                return v, unpack2(t)
            end
        end
        return unpack2(temp_args)
    end
    function VaderDirective:update_state(state_string)
        --[[
        This updates the self.state and the log reference
        --]]
        self.state = state_string
        self.log_reference:append(state_string)
    end
    function VaderDirective:activate()
        --[[
        Sets directive state as Processing
        --]]
        self:update_state("Processing")
    end
    function VaderDirective:finish()
        --[[
        Sets directive state as Finished
        --]]
        self:update_state("Finished")
        -- Remove from list
    end
    function VaderDirective:dump()
        --[[
        Dumps the directive in target_display
        --]]
        vader.logs.debug:entry("VaderDirective object dump():")
        vader.logs.debug:entry(self.name .. vader.LOG_DEFAULT_SEPARATOR .. self.state)
        vader.logs.debug:entry("Directive arguments:")
        for _,arg in ipairs(self.argument_table) do
            vader.logs.debug:entry(arg)
        end
    end
end

class "VaderDirectiveList" (AQueue)
-- A list to hold directives. See VaderDirective.
do
    function VaderDirectiveList:__init(name_string)
        AQueue.__init(self, name_string)
        self.content_type = "VaderDirective"
    end
    function VaderDirectiveList:entry(entry_object, hold_boolean)
        --[[
        This inserts a directive and triggers directives_trigger() in main.lua
        when no hold_boolean is set.  The hold_boolean must be set 'true', when
        directives are called from within directives. directives_trigger() must
        only be called by the directive that starts the snowball.
        --]]

        -----------------
        -- Error catching
        vader_assert(type(hold_boolean) == "boolean" or type(hold_boolean) == "nil", "Tried to call "..type(self)..":entry, with a hold_boolean type:"..type(hold_boolean)..". Use a boolean value.")
        -----------------
        
        -- Insert directive in main directive list
        self:push(entry_object)

        --[[
        THIS is the old way, inroducing notifier feedback loops.  long story
        short: directive cannot add another directive, if the list is observed
        with the same notifier function that ultimately called the final 'add
        directive' TOGGLE (rather than set) the pending_toggle to make process
        go.
        --]]
        --vader.flags.pending_toggle.value = not vader.flags.pending_toggle.value
        
        if not hold_boolean then
            directives_trigger()
        end

    end
    function VaderDirectiveList:entry_at(entry_object, index)
        --[[
        This inserts a directive at a specific place in the list.
        NOTE: Does NOT call directives_trigger(), (i.e. won't trigger emptying the list)
        --]]

        -----------------
        -- Error catching
        vader_assert(type(index) == "number" or type(index) == "nil", "Tried to call "..type(self)..":entry_at, with index type:"..type(index)..". Use a number or nil.")
        -----------------
        
        -- Insert directive in main directive list
        self:insert(entry_object, index)
    end
    
    function VaderDirectiveList:finish_and_remove(index)
        --[[
        This sets the directive at list postition "index" finished, and removes
        it from the queue. If index is nil, normal Queue order is used (first
        in, first out).
        Always call this when finishing a directive.
        --]]
        
        -----------------
        -- Error catching
        vader_assert(type(index) == "number" or type(index) == "nil", "Tried to call "..type(self)..":finish_and_remove with index type:"..type(index)..". Use a number or nil.")
        ----------------

        index = index or self:top_index()
        --vader.logs.debug:entry("finishing and removing a directive from index position:"..index..":")
        --self:item(index):dump()
        self:get(index):finish()
    end
    function VaderDirectiveList:create_empty_instance(name_string)
        --[[
        This is a helper that returns an empty instance of this class. Helps
        functions that return other instances of their class.  Specific to each
        class.
        --]]
        return VaderDirectiveList(name_string)
    end
end

----------------------------------------------------
-- Parsing process
----------------------------------------------------

class "CharacterStream"
-- A "custom string type". To have similar methods with TokenList.
do
    function CharacterStream:__init(name_string, message_string)
        -----------------
        -- Error catching
        vader_assert(type(name_string) == "string", "Tried to init a "..type(self).." with name_string argument type:"..type(name_string)..". Use string.")
        vader_assert(type(message_string) == "string", "Tried to init a "..type(self).." with message_string argument type:"..type(message_string)..". Use string.")
        ------------------

        self.name = name_string
        self.string = message_string
        self.msg_type = nil
        self.items = message_string --compatibility
    end
    function CharacterStream:__len()
        return #self.string
    end
    function CharacterStream:item(index)
        --[[
        Returns the index:th character
        --]]
        
        -----------------
        -- Error catching
        vader_assert(type(index) == "number", "Tried to call "..type(self)..":item ("..self.string..") with index type:"..type(index)..". Use a number.")
        vader_assert(index <= #self.string, "Tried to call "..type(self)..":item ("..self.string..") with out-of-bounds index:"..index..". Maximum is #self.string:"..#self.string)
        vader_assert(index > 0, "Tried to call "..type(self)..":item ("..self.string..") with out-of-bounds index:"..index..". Minimum is 1")
        ------------------

        return string.sub(self.string, index, index)
    end
    function CharacterStream:all_items()
        --[[
        Returns all characters = a string
        --]]
        return self.string
    end
    function CharacterStream:feed(message_string)
        --[[
        Replaces self.string with message_string
        --]]
        
        -----------------
        -- Error catching
        vader_assert(type(message_string) == "string", "Tried to call "..type(self)..":feed ("..self.name..") with message_string type:"..type(message_string)..". Use a string.")
        ------------------

        self.string = message_string
    end
    function CharacterStream:create_empty_instance(name, string)
        --[[
        Returns a new instance
        --]]
        return CharacterStream(name, string)
    end
    function CharacterStream:sub(name_string, start_index, end_index)
        --[[
        Returns a substring between indexes start_index and end_index
        --]]
        
        -----------------
        -- Error catching
        vader_assert(type(start_index) == "number", "Tried to call "..type(self)..":sub ("..self.string..") with start_index type:"..type(start_index)..". Use a number.")
        vader_assert(start_index <= #self.string, "Tried to call "..type(self)..":sub ("..self.string..") with out-of-bounds start_index:"..start_index..". Maximum is #self.string:"..#self.string)
        vader_assert(start_index > 0, "Tried to call "..type(self)..":sub ("..self.string..") with out-of-bounds start_index:"..start_index..". Minimum is 1")
        vader_assert(type(end_index) == "number", "Tried to call "..type(self)..":sub ("..self.string..") with end_index type:"..type(end_index)..". Use a number.")
        vader_assert(end_index <= #self.string, "Tried to call "..type(self)..":sub ("..self.string..") with out-of-bounds end_index:"..end_index..". Maximum is #self.string:"..#self.string)
        vader_assert(end_index > 0, "Tried to call "..type(self)..":sub ("..self.string..") with out-of-bounds end_index:"..end_index..". Minimum is 1")
        ------------------

        return CharacterStream:create_empty_instance(name_string, string.sub(self.string, start_index, end_index))
    end
    function CharacterStream:find(search_string, start_index, end_index)
        --[[
        Returns the start and end indexes of the first occurrence of
        search_string as an substring of self.string
        --]]
        
        -----------------
        -- Default values
        start_index = start_index or 1
        end_index = end_index or #self.string
        -- Error catching
        vader_assert(type(search_string) == "string", "Tried to call "..type(self)..":find with search_string argument:"..type(search_string)..". Use a string.")
        vader_assert(type(start_index) == "number", "Tried to call "..type(self)..":find with start_index argument:"..type(start_index)..". Use a number.")
        vader_assert(type(end_index) == "number", "Tried to call "..type(self)..":find with end_index argument:"..type(end_index)..". Use a number.")
        vader_assert(start_index <= #self.string, "Tried to use "..type(self)..":find ("..self.string..") with start_index:"..start_index..". The maximum is #self.string:"..#self.string)
        vader_assert(end_index <= #self.string, "Tried to use "..type(self)..":find ("..self.string..") with end_index:"..end_index..". The maximum is #self.string:"..#self.string)
        vader_assert(start_index > 0, "Tried to use "..type(self)..":find ("..self.string..") with start_index:"..start_index..". The minimum is 1")
        vader_assert(end_index > 0, "Tried to use "..type(self)..":find ("..self.string..") with end_index:"..end_index..". The minimum is 1")
        vader_assert(start_index <= end_index, "Tried to use "..type(self)..":find ("..self.string..") with start_index with value greater than end_index. Start:"..start_index..", end:"..end_index)
        vader_assert(start_index + #search_string <= end_index, "Tried to call "..type(self)..":find ("..self.string..") with too long search string:"..#search_string.." (start:"..start_index..", end:"..end_index..", len:"..end_index - start_index..")")
        -----------------

        local position_case
        local find_index = string.find(string.sub(self.string, 1, end_index), search_string, start_index)
        if find_index == 1 then
            position_case = "first"
        elseif find_index == #self.string then
            position_case = "last"
        else
            position_case = nil
        end
        return find_index, position_case
    end
    function CharacterStream:split(at_item)
        --[[
        Splits self.string so that first string will contain chars 1 - at_item,
        second string will contain items at_item + 1 = #self.string.
        Returns two objects of type type(self)
        --]]
        
        -----------------
        -- Error catching
        vader_assert(type(at_item) == "number", "Tried to split "..type(self).." ("..self.string..") with split_at argument type:"..type(at_item)..". Use a number.")
        vader_assert(#self.string > 0, "Tried to split "..type(self).." ("..self.string.."); self.string is empty.")
        vader_assert(at_item < #self.string, "Tried to split "..type(self).." ("..self.string..") at the last item in self.string, which would result in an empty second instance.")
        -----------------

        local object_1 = self:create_empty_instance(string.sub(self.string, 1, at_item))
        local object_2 = self:create_empty_instance(string.sub(self.string, at_item+1, #self.string))
        return object_1, object_2
    end
end

class "Token"
-- A token class
do
    function Token:__init(string, token_type_string, links, origin_string)
        -----------------
        -- Default values
        -- The character string of entire token
        self.string=string or ""        
        -- Type of token, deduced, not user defined
        self.token_type = token_type_string or ""
        -- This is for resolve to value/taskify
        self.links=links or table.create() --TODO: this is not active yet
        -- This is for differentiating user/parser inserted tokens
        self.origin=origin_string or ""        
        -- This comes from lex
        self.properties = table.create()
        -- Error catching
        vader_assert(type(self.string) == "string", "Tried to init a "..type(self).." with string argument type:"..type(string)..". Use a string.")
        vader_assert(type(self.token_type) == "string", "Tried to init a "..type(self).." with token_type_string argument type:"..type(token_type_string)..". Use a string.")
        vader_assert(type(self.origin) == "string", "Tried to init a "..type(self).." with origin_string argument type:"..type(origin_string)..". Use a string.")
        -----------------
        
        -- This is for resolve to value/taskify 
        self.resolved=nil      
        -- If there's an implication of scope, it is stored here
        self.context=nil  
    end
    function Token:set_property(prop)
        --[[
        Sets a property to a token
        --]]
        
        -----------------
        -- Error catching
        vader_assert(type(self.properties)=="table", "Tried to set property on a malformed Token that has no properties table!") 
        --TODO: rid this. Or the root of the problem, actually.
        -----------------
        
        if not self:has_property(prop) then
            table.insert(self.properties, prop)
            --vader.logs.debug:entry("set property "..prop.." to Token:"..self.string..".")--debug
        else
            --vader.logs.debug:entry("did not set property "..prop.." to Token:"..self.string..", had it already")--debug
        end
    end
    function Token:feed_properties(prop_table)
        --[[
        Replaces self.properties with prop_table
        --]]
        -- TODO:vader_asserts
        self.properties = table.create()
        for _ = 1, #prop_table do
            self:set_property(prop_table[_])
        end
    end
    function Token:has_property(prop)
        --[[
        If token has property prop, returns the matching property (true) from
        its self.properties table.
        TODO:vader_asserts
        --]]
        for key, property in pairs(self.properties) do
            if property == prop then
                return property
            end
        end
        return false
    end
    function Token:has_match_in_property_string(prop)
        --[[
        If token has property prop, returns the matching property (true) from
        its self.properties table.
        TODO:vader_asserts
        --]]
        for key, property in pairs(self.properties) do
            if string.find(property, prop) then
                return property
            end
        end
        return false
    end
    function Token:dump(notitle)
        --[[
        Dumps token info in log
        --]]
        vader.logs.debug:entry("--------")
        if not notitle then
            vader.logs.debug:entry(string.format("Token object dump()"))
        end
        vader.logs.debug:entry(string.format("  string: %s", self.string))
        vader.logs.debug:entry(string.format("  type:   %s", self.token_type))
        vader.logs.debug:entry(string.format("  resolved:", (self.resolved or "nil")))
        if #self.properties > 0 then
            for key, property in pairs(self.properties) do
                vader.logs.debug:entry(string.format("  property: %s", property))
            end
        end
        vader.logs.debug:entry("--------")
    end
    function Token:duplicate()
        --[[
        Returns a verbatim copy
        --]]
        local duplicate_token = Token(self.string, self.token_type, self.links, self.origin)
        duplicate_token:feed_properties(self.properties)
        duplicate_token.resolved = self.resolved
        duplicate_token.context = self.context
        return duplicate_token
    end
end

class "TokenStream" (ARevQueue)
-- A list of tokens
do
    function TokenStream:__init(name_string)
        ARevQueue.__init(self, name_string)
        self.content_type = "Token"
        self.resolved = nil
    end
    function TokenStream:create_empty_instance(name_string)
        --[[
        This is a helper that returns an empty instance of this class. Helps
        functions that return other instances of their class.  Specific to each
        class.
        --]]
        return TokenStream(name_string)
    end
    function TokenStream:find_token_type(token_type, start_index, end_index)
        --[[
        Searches returns the index of first item in self.items, that has
        matching self.token_type with the token_type argument.  Direction of
        search is defined with start_index, end_index (end_index can be smaller
        than start_index).
        --]]
        
        -----------------
        -- Error catching
        vader_assert(type(token_type) == "string", "Tried to find_token_type with token_type type:"..type(token_type)..". Use a string.")
        ----------------
        
        local function token_type_condition(item, token_type)
            if item.token_type == token_type then
                return true
            end
        end
        return self:find_item(token_type_condition, token_type, start_index, end_index)
    end

    function TokenStream:find_token_type_match(token_type, start_index, end_index)
        --[[
        Searches returns the index of first item in self.items, that has
        matching self.token_type with the token_type argument.  Direction of
        search is defined with start_index, end_index (end_index can be smaller
        than start_index).
        TODO: Describe how is this different than find_token_type()??
        --]]
        
        -----------------
        -- Error catching
        vader_assert(type(token_type) == "string", "Tried to find_token_type with token_type type:"..type(token_type)..". Use a string.")
        ----------------
        
        local function token_type_match_condition(item, token_type)
            if item.token_type:find(token_type) then
                return true
            end
        end
        return self:find_item(token_type_match_condition, token_type, start_index, end_index)
    end
    function TokenStream:find_token_type_not(token_type, start_index, end_index)
        --[[
        Searches returns the index of first item in self.items, that has
        matching self.token_type with the token_type argument Direction of
        search is defined with start_index, end_index (end_index can be smaller
        than start_index).
        TODO: Describe how is this different than find_token_type()??
        --]]
        
        -----------------
        -- Error catching
        vader_assert(type(token_type) == "string", "Tried to find_token_type with token_type type:"..type(token_type)..". Use a string.")
        ----------------
        
        local function token_type_condition(item, token_type)
            if item.token_type ~= token_type then
                return true
            end
        end
        return self:find_item(token_type_condition, token_type, start_index, end_index)
    end
    function TokenStream:find_token_string(search_string, start_index, end_index)
        --[[
        TODO: COMMENT
        --]]
        
        -----------------
        -- Error catching
        vader_assert(type(search_string) == "string", "Tried to find_token_string with search_string type:"..type(search_string)..". Use a string.")
        ----------------

        local function token_string_condition(item, search_string)
            if item.string == search_string then
                return true
            end
        end
        return self:find_item(token_string_condition, search_string, start_index, end_index)
    end
    function TokenStream:find_token_property(search_prop, start_index, end_index)
        --[[
        TODO:Comment this function
        --]]
        
        -----------------
        -- Error catching
        vader_assert(type(search_prop) == "string", "Tried to find_token_property with search_prop type:"..type(search_prop)..". Use a string.")
        ----------------

        local function token_prop_condition(item, search_prop)
            if item:has_property(search_prop) then
                return true
            end
        end
        return self:find_item(token_prop_condition, search_prop, start_index, end_index)
    end
    function TokenStream:dump()
        --[[
        A debug function
        --]]
        vader.logs.debug:entry(string.format("TokenStream object: '"..self.name.."' dump()"))
        for i = 1, #self.items do
            vader.logs.debug:entry("--------")
            vader.logs.debug:entry(string.format("Token [%i]:", i))
            self:item(i):dump(true)
        end
    end
    function TokenStream:set_property(prop)
        --[[
        Sets property prop for each TokenStream Token
        --]]
        
        -----------------
        -- Error catching
        vader_assert(type(prop)=="string", "Tried to call "..type(self)..":set_property ("..self.name..") with prop argument type:"..type(prop)..". Use a string.")
        -----------------
        
        if self.items and #self.items > 0 then
            for i =1, #self.items do
                self:item(i):set_property(prop)
            end
        end
    end
    function TokenStream:duplicate()
        --[[
        Returns a verbatim copy
        --]]
        local duplicate_stream = ARevQueue.duplicate(self)
        duplicate_stream.content_type = self.content_type
        return duplicate_stream
    end
end

class "TokenTree"
--[[
This is used to create a tree structure of Tokenlists for parsing purposes The
main list handling methods are those of TokenStream (ARevQueue)
--]]
do
    function TokenTree:__init(name_string, list)
        local method_log = register_method_log(type(self)..":__init()")

        ------------------
        -- Default values
        name_string = name_string or ""
        -- Error catching
        vader_assert(type(name_string) == "string", "Tried to init a "..type(self).." with name_string type:"..type(name_string)..". Use a string.")
        vader_assert(type(list) == "TokenStream" or type(list) =="nil", "Tried to init a "..type(self).." with list type:"..type(list)..". Use a TokenStream.")
        ----------------
        
        -- self.list holds this node TokenStream, a list of Tokens, that is
        -- self.branches is a holder for a list of TokenTrees
        self.name = name_string
        self.list = list
        -- create initial (empty) branches
        if self.list then
            self:init_tree()
        end
        self.parent_reference = nil
        self.scope = nil
        method_log:entry("Initialized a "..type(self).." ("..self.name..")", 2)
    end
    function TokenTree:create_empty_instance(name_string)
        --[[
        This is a helper that returns an empty instance of this class. Helps
        functions that return other instances of their class.  Specific to each
        class.
        --]]
        local method_log = register_method_log(type(self)..":create_empty_instance()")

        return TokenTree(name_string)
    end
    function TokenTree:__len()
        --[[
        Overload the length operator
        --]]
        return #self.list
    end
    function TokenTree:init_list(name_string)
        --[[
        Creates the list
        --]]
        self.list = TokenStream(name_string)
    end
    function TokenTree:init_tree()
        --[[
        Creates the branches structure according to the self.list
        --]]
        self.branches = ARevQueue(self.list.name)
        self.branches.content_type = "TokenTree"
        for i = 1, #self.list.items do
            --self.branches:push(self:create_branch(self.list:item(i).string))
            local new_branch = self:create_branch(self.list:item(i).string)
            new_branch.parent_reference = self:branch(i)
            self.branches:push(new_branch)

        end
    end
    function TokenTree:item(index)
        --[[
        Wrapper. returns item from the self.list
        --]]
        return self.list:item(index)
    end
    function TokenTree:push(item)
        --[[
        Pushes a token in self.list, creates a branch
        --]]
        if not self.list then
            self:init_list(item.string)
        end
        if not self.branches then
            self:init_tree()
        end
        local new_branch = self:create_branch(item.name)
        new_branch.parent_reference = self.branches:item(#self)
        self.branches:push(new_branch)
        self.list:push(item)
    end
    function TokenTree:insert(item)
        --[[
        Inserts a token in self.list, creates a branch
        --]]
        if not self.list then
            self:init_list(item.name)
        end
        if not self.branches then
            self:init_tree()
        end
        local new_branch = self:create_branch(item.name)
        new_branch.parent_reference = self.branches:item(#self)
        self.branches:insert(new_branch, index)
        self.list:insert(item, index)
    end
    function TokenTree:push_end(item)
        --[[
        Inserts a token in self.list, creates a branch
        --]]
        if not self.list then
            self:init_list(item.name)
        end
        if not self.branches then
            self:init_tree()
        end
        local new_branch = self:create_branch(item.name)
        new_branch.parent_reference = self.branches:item(#self)
        self.branches:push_end(new_branch)
        self.list:push_end(item)
    end
    function TokenTree:pop()
        --[[
        Returns an item from self.list, handles branches-table
        --]]
        self.branches:pop()
        return self.list:pop()
    end
    function TokenTree:pop_end()
        --[[
        Returns an item from self.list, handles branches-table
        --]]
        self.branches:pop_end()
        return self.list:pop_end()
    end
    function TokenTree:get(index)
        --[[
        Returns an item from self.list, handles branches-table
        --]]
        self.branches:get(index)
        return self.list:get(index)
    end
    function TokenTree:feed(tokenstream)
        --[[
        Feeds a stream, replacing the old content
        --]]
        
        -----------------
        -- Error catching
        vader_assert(type(tokenstream) == "TokenStream", "Tried to call "..type(self)..":feed ("..self.name..") with tokenstream argument type:"..type(tokenstream)..". Use a TokenStream object.")
        vader_assert(#tokenstream.items > 0, "Tried to call "..type(self)..":feed ("..self.name..") with tokenstream that has zero length. Use a TokenStream with at least 1 item.")
        -----------------
        
        -- Replaces current list
        self:init_list(tokenstream.name)
        for i = 1, #tokenstream.items do
            self.list:push(tokenstream:item(i))
        end
        self:init_tree()
    end
    function TokenTree:dump()
        --[[
        Wrapper. dumps the self.list
        --]]
        
        -----------------
        -- Error Catching
        vader_assert(type(self.list) == "TokenStream" or type(self.list) == "nil", "Tried to call "..type(self)..":dump(), but self.list type is:"..type(self.list)..".")
        ------------------

        if self.list then
            self.list:dump()
            vader.logs.debug:entry("Also:self.resolved = "..(self.resolved or "nil"))
        else
            vader.logs.debug:entry("nil")
        end
    end
    function TokenTree:dump_recursive(level, recursive_call)
        --[[
        Dumps the tree structure

        TODO: create a multiline-version of this for home-dump swiftness!
        this must be something like: on first call create a dump_table table,
        collect all entries into the table, and when exiting the recursion
        loop in the very first call loop, ka-pow: display!

        --]]
        local this_level = level or 0
        if not recursive_call then
            vader.logs.debug:entry("Tree dump of "..type(self).." object ("..self.name.."):")
        end

        local is_printable
        -- Text formatting and print
        local function print_item(index, item, tree_resolved)
            if is_printable then
                local level_tab = ""
                if this_level > 1 then
                    for _=2, this_level do
                        level_tab = level_tab .. "---"
                    end
                end
                local formatstring
                if tree_resolved then
                    formatstring = "--%s[%i]   %s   (%s)    =%i"
                else
                    formatstring = "--%s[%i]   %s   (%s)"
                end
                vader.logs.debug:entry(string.format(formatstring, level_tab, index, (item.string or "nil"), (item.token_type or "nil"), (tree_resolved) ) )
                for key, property in pairs(item.properties) do
                    vader.logs.debug:entry(string.format("--%sproperty: %s", level_tab, property))
                end
                local this_scope = self:branch(index).scope 
                if this_scope then
                    vader.logs.debug:entry("--"..level_tab.."scope:"..this_scope)
                end
            end
        end

        -- Debug
        local silent = true
        local really_silent = true
        is_printable = self:debug_check(silent, really_silent)

        -- Recursion
        if self.branches and #self.branches > 0 then
            this_level = this_level + 1
            for branch_index = 1, #self.branches do
                print_item(branch_index, self:item(branch_index), self:branch(branch_index).resolved)
                self:branch(branch_index):dump_recursive(this_level, true)
            end
        end
    end
    function TokenTree:branches_object()
        --[[
        Returns the branches-list -object
        --]]
        return self.branches
    end
    function TokenTree:branches_table()
        --[[
        Returns the items table of the branches-list
        --]]
        return self.branches.items
    end
    function TokenTree:branch(index)
        --[[
        Returns a branch by index
        --]]
        return self.branches.items[index]
    end
    function TokenTree:has_branch(index)
        --[[
        Returns true if branch index has a list longer than 0 items
        --]]
        local test_list = self:branch(index).list.items
        return (test_list and #test_list > 0)
    end
    function TokenTree:branch_by_name(name_string)
        --[[
        Returns a branch by index
        --]]
        
        -----------------
        -- Error catching
        vader_assert(type(name_string) == "string", "Tried to call "..self.type..":branch_by_name with name_string argument type:"..type(name_string)..". Use a string.")
        ------------------

        if self.branches > 0 then
            for key, branch in pairs(self.branches) do
                if branch.name == name_string then
                    return key
                end
            end
        else
            return false
        end
        return false
    end
    function TokenTree:parent()
        --[[
        Returns the parent TokenTree object
        --]]
        return self.parent_reference
    end
    function TokenTree:has_parent()
        --[[
        Returns true if self.parent_reference is not nil, else false
        --]]
        return self.parent_reference ~= nil
    end
    function TokenTree:create_branch(name_string, tokenstream)
        --[[
        Creates empty branch, feeds tokenstream if not nil, sets self.parent_reference
        --]]
        local new_branch = self:create_empty_instance(name_string)
        if tokenstream ~= nil then
            new_branch:feed(tokenstream)
        end
        return new_branch
    end
    function TokenTree:replace_w_stream(name_string, start_index, end_index, token, tokenstream)
        --[[
        Replaces tokens from start_index to end_index with 'token', and creates
        a branching tokenstream (or empty branch if tokenstream == nil)
        name_string argument is the name of the new TokenTree object (the one
        branching from the placeholder)
        --]]
        local method_log = register_method_log(type(self)..":replace_w_stream()")
        
        -- Handle self.list
        self.list:replace(start_index, end_index, {token})
        
        -- Handle self.branches
        local new_branch = self:create_branch(name_string, tokenstream)
        self.branches:replace(start_index, end_index, {new_branch})
        new_branch.parent_reference = self.branches:item(start_index)
        return new_branch
    end
    function TokenTree:replace_w_tree(name_string, start_index, end_index, token, tokentree)
        --[[
        Differs to replace_w_stream in that this places a full TokenTree structures instead of a flat TokenStream
        --]]
        local method_log = register_method_log(type(self)..":replace_w_tree()")

        self.list:replace(start_index, end_index, {token})
        
        -- Handle self.branches
        tokentree.parent_reference = self.branches:item(start_index)
        self.branches:replace(start_index, end_index, {tokentree})
        return tokentree
    end
    function TokenTree:find_token_type(token_type, start_index, end_index)
        --[[
        Wrapper. Search self.list
        --]]
        return self.list:find_token_type(token_type, start_index, end_index)
    end
    function TokenTree:find_token_type_match(token_type, start_index, end_index)
        --[[
        Wrapper. Search self.list
        --]]
        return self.list:find_token_type_match(token_type, start_index, end_index)
    end
    function TokenTree:find_token_string(search_string, start_index, end_index)
        --[[
        Wrapper. Search self.list
        --]]
        return self.list:find_token_string(search_string, start_index, end_index)
    end
    function TokenTree:find_token_property(search_prop, start_index, end_index)
        --[[
        Wrapper. Search self.list
        --]]
        return self.list:find_token_property(search_prop, start_index, end_index)
    end
    function TokenTree:set_property(prop)
        --[[
        Wrapper. Set property on self.list
        --]]
        return self.list:set_property(prop)
    end
    function TokenTree:branch_by_points(at_table, sub_token_table, branch_name_table, separator_handling_mode)
        --[[
        Splits tree at at_table points and branches into substreams
        --]]
        local method_log = register_method_log(type(self)..":branch_by_points()")

        local mode_fix = 0
        --[[
        The mode_fix is for the case that the first split is assigned at 2 and
        separator handling mode is set to "into_next". In which case no first
        part is ever created, and the index calculator i, which is used to set
        the first token cursor point, needs to be adjusted accordingly.
        --]]
        
        for i = 1, #at_table do
            
            vader.logs.debug:entry("splitting tree:("..self.name..") part:"..i, 10)

            --[[
            Calculate actual cut point based on various stuff:
            a) the previous tokenstreams are now 1 token long. (cut_correction)
            b) separator handling mode. (cut_fix)
            c) special cases where 0 length streams would be output. (mode_fix)
            --]]
            
            local cut_correction = 0
            -- The cut_correction is the 'master' correction value. It will have all the corrections applied.

            if i > 1 then
                cut_correction = 0 - at_table[i-1] + i + mode_fix
                --cut_correction = 1 - at_table[i-1] + i + mode_fix
                --cut_correction = -1 - at_table[i-1] + i + mode_fix --TODO: HAVE NO IDEA WHY IT'S JUST THIS NUMBER THAT WORKS
            end

            -- Set minute cut fix based on separator handling mode, and remove separator if needed.
            local cut_fix = nil
            -- The cut_fix is applied on cut_correction based on the separator handling mode.
            local this_separator_handling_mode
            if type(separator_handling_mode) == "table" then
                this_separator_handling_mode = separator_handling_mode[i]
            else
                this_separator_handling_mode = separator_handling_mode
            end
            if this_separator_handling_mode == "remove" then
                -- Remove separator
                self:get(at_table[i]+cut_correction) 
                -- Set cutpoint fix
                cut_fix = -1
            elseif this_separator_handling_mode == "into_prev" then 
                -- Set cutpoint fix
                cut_fix = 0
            elseif this_separator_handling_mode == "into_next" then
                -- Set cutpoint fix
                cut_fix = -1
            else
                -- Unknown separator handling mode!
                -- Error
            end

            cut_correction = cut_correction + cut_fix 

            local result_branch
            if i == #at_table then
                -- Last split: create both 2 parts that are left
                -- Check for a special case:
                if #self > 1 then
                    -- Stream is longer than 1 item.
                    -- Branch first part
                    local start_item_a = math.max(1, i+mode_fix)
                    local end_item_a = math.max(start_item_a, at_table[i]+cut_correction)
                    local sub_tree_a = self:sub(branch_name_table[i], start_item_a, end_item_a)
                    local sub_token_a = Token(branch_name_table[i], branch_name_table[i])
                    result_branch = self:replace_w_tree(branch_name_table[i], start_item_a, end_item_a, sub_token_a, sub_tree_a)

                    --Check for a special case:
                    if at_table[i] == #self and separator_handling_mode == "into_prev" then
                        --Trying to split at last item and include separator in the
                        --first one of the two subs created. > second one will not exist.
                        vader.logs.debug:entry("Skipped last split in branch_by_points ("..self.name.."), length 0.", 5)
                    else
                        -- Branch second part
                        local start_item_b =math.min(#self, start_item_a + 1)
                        local end_item_b = #self
                        local sub_tree_b = self:sub(branch_name_table[i+1], start_item_b, end_item_b)
                        local sub_token_b = Token(branch_name_table[i+1], branch_name_table[i+1])
                        result_branch = self:replace_w_tree(branch_name_table[i+1], start_item_b, end_item_b, sub_token_b, sub_tree_b)
                    end
                else
                    -- if a table's 1 item long, cannot split in 2
                    -- Branch the 1 item long stream
                    local start_item = 1
                    local end_item = 1
                    local sub_tree = self:sub(branch_name_table[i], start_item, end_item)
                    local sub_token = Token(branch_name_table[i+1], branch_name_table[i])
                    result_branch = self:replace_w_tree(branch_name_table[i], start_item, end_item, sub_token, sub_tree)
                end 
            else
                -- Normal split. Create 1 part.
                --Check for a special case:
                if at_table[i] == 1 and separator_handling_mode == "into_next" then
                    --Trying to split at first item and include separator in the
                    --second one of the two subs created. > first one will not exist.
                    vader.logs.debug:entry("Skipped a split at Token index 1 in branch_by_points ("..self.name.."), length 0.", 5)
                    mode_fix = -1
                    -- This mode_fix will apply a calculation correction to the following splits
                    -- so that it will seem that this split never happened.
                else
                    -- Split this one part
                    -- Branch
                    local start_item = math.max(1, i+mode_fix)
                    local end_item = math.max(start_item, at_table[i]+cut_correction)
                    local sub_tree = self:sub(branch_name_table[i], start_item, end_item)
                    local sub_token = Token(branch_name_table[i+1], branch_name_table[i])
                    result_branch = self:replace_w_tree(branch_name_table[i], start_item, end_item, sub_token, sub_tree)
                end
            end
        end
        return self
    end
    function TokenTree:branch_nests()
        --[[
        This finds this level nests and creates sub branches for them 
        --]]
        local method_log = register_method_log(type(self)..":branch_nests()")
        
        -- Catch abnormalities
        if not self.list then
            --no items, cannot have nests
            method_log:entry("No items in self.list", 2)
            return true
        end
        if not (#self > 1) then
            --cannot contain a nest open and a nest close char
            method_log:entry( "Self.list is too short to contain a nest", 2)
            return true
        end
        
        local scanner = TokenScanner("scanner", self.list)
        local nest_open, pos_case = self:find_token_type("<nest char open>")
        if not nest_open then
            -- No nests here. return.
            method_log:entry("No nests.", 2)
            return true
        end
        while nest_open do
            if pos_case == "last" then
                -- a case of unbalanced nesting.
                vader_error("Unbalanced nesting.", true)
            end
            --Init scanner
            scanner.to = nest_open
            scanner:contract_to_one_()
            --Init counter
            local nc = Counter()
            nc:set(1)
            
            --Expand scanner until end or balanced close
            local cut_here = false
            repeat

                if not scanner:expand() then
                    -- No more tokens, quit, assess
                    break
                end

                local token = scanner:tail().token_type

                if token == "<nest char open>" then
                    nc:inc()
                end
                if token == "<nest char close>" then
                    nc:dec()
                end

                if nc.count == 0 then
                    -- Nest has been balanced back to zero. Cut here.
                    cut_here = true
                end

            until cut_here

            if nc.count ~= 0 then
                -- Loop was broken because no more tokens
                -- Error, exit
                vader_error("Unbalanced nesting.", true)
            else
                -- Branch from scanner start to scanner end, leaving out nestchars from sub_tree
                local sub_tree = self:sub("<nest>", scanner.from+1, scanner.to-1)
                local sub_token = Token("<nest>", "<nest>")
                self:replace_w_tree("<nest>", scanner.from, scanner.to, sub_token, sub_tree)
            end

            -- Test for more, run the while loop again if more
            nest_open, pos_case = self:find_token_type("<nest char open>")
        end
        return true
    end
    function TokenTree:branch_binary_ops()
        --[[
        This finds the first 'this_op' binary operation token
        and splits the whole tree in half at that point
        creating two <binary_nest> tokens and the operator is left intact
        (possible values for this_op include 'sub', 'mul' etc..)
        TODO:THIS IS COMPLETELY WRONG!
        --]]
        local method_log = register_method_log(type(self)..":branch_binary_ops()")

        local precedence = {
            "mul",
            "div",
            "sum",
            "sub",
        }
        -- Helpers
        local function this_round_ops_at(op_string)
            -- Build a table of selected binary_op points
            local tropa = table.create()
            ----
            local stream = self.list
            local scanner = TokenScanner("scanner", stream)
            ----
            repeat 
                local token = scanner:head()
                if token.token_type == op_string then
                    -- Put this position in table
                    tropa:insert(scanner.from)
                end
            until scanner:mv_fwd() == false
            if #tropa > 0 then
                method_log:entry("Branch still has "..#tropa.." piece(s) of "..op_string.." operators left", 2)
            else
                method_log:entry("No "..op_string.." operators left", 2)
            end
            return tropa
        end
        local function all_ops_at()
            -- Build a table of all binary_op points
            local aopa = table.create()
            ----
            local stream = self.list
            local scanner = TokenScanner("scanner", stream)
            ----
            repeat 
                local token = scanner:head()
                if string.sub(token.token_type, 1, 10, "<binary op") then
                    -- Put this position in table
                    aopa:insert(scanner.from)
                end
            until scanner:mv_fwd() == false
            method_log:entry("Branch still has "..#aopa.." piece(s) of any binary operators left", 2)
            return aopa
        end

        -- Catch abnormalities
        if not self.list then
            --no items, cannot have nests
            method_log:entry("No items in self.list", 1)
            return true
        end
        if not (#self > 2) then
            --cannot be a binary op
            method_log:entry("Self.list is too short <2 to contain a binary operation", 1)
            return true
        end
        if #self == 3 then 
            -- Split into operators! (Only 1 operation left)
            method_log:entry("Binary operation split: split into operators (BRANCH END)", 1)
            -- Branch, splitting from the operator spot
            local sub_tree_op_1 = self:sub("<binary nest>", 1, 1)
            local sub_tree_op_2 = self:sub("<binary nest>", 3, 3)
            local sub_token_1 = Token("<binary nest>", "<binary nest>")
            local sub_token_2 = Token("<binary nest>", "<binary nest>")
            self:replace_w_tree("<binary nest>", 1, 1, sub_token_1, sub_tree_op_1)
            self:replace_w_tree("<binary nest>", 3, 3, sub_token_2, sub_tree_op_2)
        else
            -- Split into binary nests
            method_log:entry("Binary operation split: split into binary nests", 1)
            -- Go over precedence table and structure the tree
            for _, this_op in ipairs(precedence) do
                -- A repeat loop to get next THIS OPERATOR TYPE binaryop point. If not found, next operator type
                local safety_counter = Counter()
                while #this_round_ops_at("<binary op "..this_op..">") > 0 and #all_ops_at() > 1 do --Yes seems risky...
                    local binary_op, pos_case = self:find_token_type("<binary op "..this_op..">")
                    --vader.logs.debug:entry("Branching binary ops: "..this_op, 10)
                    if binary_op then
                        if pos_case == "first" then
                            -- Missing 1st op error
                            vader_error("Invalid binary operation. Missing 1st operator.")
                        elseif pos_case == "last" then
                            --Check if double
                            if #self:item(binary_op).string == 2 then
                                --It's a double, and legal/valid
                                method_log:entry("Found an inc/dec operation, inserting digit '1' as 2nd operator", 2)
                                --Push a one after last
                                self:push(Token("1","<digit>"))
                            else
                                --It's not a double. Bummer. It's invalid.
                                -- Missing 2nd op error
                                vader_error("Invalid binary operation. Missing 2nd operator.")
                            end
                        end

                        --TODO: THIS IS WORKING WRONG:
                        --IT DIVES INTO AN ENDLESS BRANCH!
                        --SOLUTION: DO ONLY ONCE FOR THE WHOLE LEVEL, HANDLE
                        --REPEAT, UNTIL IN :SOLVE?
                        --self:dump_recursive()--debug
                        -- Branch the binary nest
                        local sub_token = Token("<binary nest>", "<binary nest>")
                        local sub_tree = self:sub("<binary nest>", binary_op - 1, binary_op + 1)
                        self:replace_w_tree("<binary nest>", binary_op - 1 , binary_op + 1, sub_token, sub_tree)
                        --self:dump_recursive()--debug

                        --TODO. this is wrong.
                        --one must not split the tokenstream in half and operate from there,
                        --but must split the tokenstream in bits that range to the next/prev
                        --binary op.
                        --[[ old
                        -- Branch, splitting from the operator spot
                        local sub_tree_op_1 = self:sub("<binary nest>", 1, binary_op - 1)
                        local sub_tree_op_2 = self:sub("<binary nest>", binary_op + 1, #self)
                        local sub_token_1 = Token("<binary nest>", "<binary nest>")
                        local sub_token_2 = Token("<binary nest>", "<binary nest>")
                        self:replace_w_tree("<binary nest>", 1, binary_op - 1, sub_token_1, sub_tree_op_1)
                        self:replace_w_tree("<binary nest>", binary_op + 2 - #sub_tree_op_1, #self, sub_token_2, sub_tree_op_2)
                        --]]
                    else
                        -- SHOULD NOT BE HERE; LOG, EXIT
                        method_log:entry("Unexpected behaviour in binary_op split while loop")
                        break
                    end
                    safety_counter:inc()
                    vader_assert(safety_counter.count < vader.LOOP_SAFETY_LIMIT, "Something went wrong in "..type(self)..":branch_binary_ops()")
                end --while
            end --for
        end --if-then-else

        return true
    end
    function TokenTree:denest()
        --[[
        Unwraps a nest layer from a TokenTree structure
        Assumes a TokenTree comprising of a single <nest> token
        --]]
        local method_log = register_method_log(type(self)..":denest()")
        
        -- Catch impossible or unnecessary denestings
        if not self.list then
            -- This cannot be a valid nest, no subdata!
            method_log:entry("Did not denest. Branch does not have subtrees.", 2)
            return false
        end
        if #self ~= 1 then
            -- This cannot be a simple nest layer
            method_log:entry("Did not denest. Stream not 1 Token long. (Is "..#self.." Tokens long)", 2)
            return false
        end
        if self:item(1).token_type ~= "<nest>" then
            -- This is not a nest token
            method_log:entry("Did not denest. Stream item 1 is not a <nest> Token. (Is "..self:item(1).token_type.." Token)", 2)
            return false
        end
        --------------------
        --self:dump()--debug
        -- Create a links to data structure
        local sub_tree = self:branch(1)
        ---------------------------
        -- Switch references
        self.list = sub_tree.list
        self.branches = sub_tree.branches
        --TODO: what happens to the nest-tokentree (will it be garbage collected?)
        method_log:entry("Denested.", 1)
        return true
    end
    function TokenTree:duplicate()
        --[[
        Returns a deeply copied duplicate of self
        --]]
        local duplicate_tree = TokenTree(self.name)

        if self.list then
            duplicate_tree.list = self.list:duplicate()
        else
            duplicate_tree:init_list("")
        end
        if self.branches and #self.branches > 0 then
            duplicate_tree.branches = self.branches:duplicate()
        else
            duplicate_tree:init_tree()
        end

        if self.branches and #self.branches > 0 then
            for branch_index = 1, #self.branches do
                self:branch(branch_index):duplicate()
            end
        end

        duplicate_tree.scope = self.scope

        return duplicate_tree
    end
    function TokenTree:sub(name_string, start_index, end_index)
        --[[
        Returns a subset of the tree (list/branches)
        Do the sub by creating a duplicate and removing unnecessary
        bits from the start and the end
        --]]
        
        -----------------
        -- Error catching
        vader_assert(type(name_string) == "string", "Tried to call "..type(self)..":sub with a name_string argument type:"..type(name_string)..". Use a string.")
        vader_assert(type(start_index) == "number", "Tried to call "..type(self)..":sub with a start_index argument type:"..type(start_index)..". Use a number.")
        vader_assert(type(end_index) == "number", "Tried to call "..type(self)..":sub with a end_index argument type:"..type(start_index)..". Use a number.")
        vader_assert(start_index <= end_index, "Tried to call "..type(self)..":sub with a start_index higher than end_index. (start_idex:"..start_index..", end_index:"..end_index..")")
        vader_assert(start_index >= 1, "Tried to call "..type(self)..":sub with a start_index lower than 1. The minimum is 1. (start_idex:"..start_index..")")
        vader_assert(end_index <= #self, "Tried to call "..type(self)..":sub with a end_index higher than #self. (end_index:"..end_index..", #self:"..#self..")")
        -----------------
        
        local sub_tree = self:duplicate()
        if start_index > 1 then
            for i = 1, start_index-1 do
                sub_tree:pop()
                --vader.logs.debug:entry("removed an item from tree start")--debug
            end
        end
        if end_index < #self then
            for i = 1, #self-end_index do
                sub_tree:pop_end()
                --vader.logs.debug:entry("removed an item from tree end")--debug
            end
        end
        sub_tree.name = name_string
        return sub_tree
    end
    function TokenTree:debug_check(silent, really_silent)
        --[[
        TODO: COMMENT
        --]]
        local is_printable = true
        local is_ok = true
        local function stealthprint(stuff)
            -- just checks if the silent-argument is true
            if not silent then
                vader.logs.debug:entry(stuff)
            end
        end
        local function normalprint(stuff)
            -- just checks if the silent-argument is true
            if not really_silent then
                vader.logs.debug:entry(stuff)
            end
        end

        stealthprint("TokenTree:debug_check() checking---"..self.name)
        --Check that various elements exist
        if not self.list then
            stealthprint("ERROR  -No self.list!")
            stealthprint("ERROR  -No self.list.items!")
            is_printable = false
            is_ok = false
        else
            stealthprint("OK           -has self.list")
            if not self.list.items then
                stealthprint("ERROR  -No self.list.items!")
                is_printable = false
                is_ok = false
            else
                stealthprint("OK           -has self.list.items")
            end
        end
        if not self.branches then
            stealthprint("ERROR  -No self.branches!")
            stealthprint("ERROR  -No self.branches.items!")
            is_printable = false
            is_ok = false
        else
            stealthprint("OK           -has self.branches")
            if not self.branches.items then
                stealthprint("ERROR  -No self.branches.items!")
                is_printable = false
                is_ok = false
            else
                stealthprint("OK           -has self.branches.items")
            end
        end
        if self.list and self.branches then
            if self.list.items and self.branches.items then
                --Check that branches and list match in number.
                if #self.list.items < #self.branches then
                    stealthprint("ALERT       -self.list.items < self.branches.items")
                    is_ok = false
                    --[[
                    stealthprint("****alert!")
                    stealthprint("****self.branches.items:")
                    rstealthprint(self.branches.items)
                    stealthprint("****self.branches.items[1]:")
                    stealthprint("****self.branches.items[1]:")
                    self.branches.items[1]:dump()
                    stealthprint("****self.branches.items[1]:")
                    rstealthprint(self.branches.items[1])
                    stealthprint("****self.list.items:")
                    rstealthprint(self.list.items)
                    stealthprint("****self.list.items[1]:")
                    self.list.items[1]:dump()
                    --]]

                end
            end
        end
        local ok_string = ""
        if is_ok then
            ok_string = "OK"
        else
            ok_string = "NOT OK!! ERROR!"
        end
        normalprint("TokenTree:debug_check() checking---"..self.name.." finished!----"..ok_string)
        return is_printable, is_ok
    end
    function TokenTree:solve()
        --[[
        This solves a token tree into a single number This assumes that the
        stream is solvable, i.e.  comprises of nothing more than

         -numbers (be them hex, dec, note val or other)
         -values that can be looked up from tables (vars, etc.)
         -nesting
         -binary operations

        --]]
        local method_log = register_method_log(type(self)..":solve()")
        
        -- Create solve tree and stack for solving
        -- Solve stack object
        local solve_stack = AStack("solve_stack")
        solve_stack.content_type = "TokenTree"

        
        -- Fill solve stack, branch into nests/binary ops
        local function structure_solve(this_branch)
            -- This structures this_branch and sub-branches for solving
            local structure_solve_log = ALog("structure_solve()", vader.displays.no_display, 0)
            structure_solve_log:add_distribute_log(method_log)

            --TODO:this should not be a sub-function it confuses things
            local function old_do_recursion()
                --step x. call this structure solving function on all (existing and generated) sub-branches
                if this_branch.list and #this_branch.list > 0 then
                    for key, sub_branch in ipairs(this_branch.branches.items) do
                        local error, notes
                        sub_branch = structure_solve(sub_branch) 
                        --[[
                        if not sub_branch then
                            return false, error, nil
                        elseif notes then
                            return true, nil, notes
                        end
                        --]]
                    end
                end
                -- it's a terminal stop
                return true
            end

            --vader.logs.debug:entry("***dump a branch in structure solve")--debug
            --this_branch:dump_recursive()--debug
            --step 1. remove (possible) parentheses from a <nest> token tokenstream
            if this_branch.name == "<nest>" then
                --TODO: this is not failsafe! should do proper denest instead!
                --this_branch:pop()
                --this_branch:pop_end()
                this_branch:denest()
            end

            --step 2. branch into nests
            this_branch:branch_nests()

            --step 3. branch into arithmetic ops (This is the precedence handling bit!)
            this_branch:branch_binary_ops()

            --step 4. add into solve stack
            if this_branch.list and #this_branch.list > 0 then
                solve_stack:push(this_branch)
            end

            --step 5. go deeper in tree that is being created
            --TODO- work out this recursion thing. The loop below does NOT work
            --the function old_do_recursion DOES work.
            old_do_recursion()
            --step x. call this structure solving function on all (existing and generated) sub-branches
            --[[
            if this_branch.list and #this_branch.list > 0 then
                -- Has sub branches
                for key, sub_branch in ipairs(this_branch.branches.items) do
                    local more
                    sub_branch, more = structure_solve(sub_branch) 
                    if not more then
                        -- Reached a branch end
                        return this_branch, false
                    else
                        -- Still sub_branches left
                        return this_branch, true
                    end
                end
            else
                return this_branch, false
            end
            --]]
            
            --vader.logs.debug:entry("Structure solve succesful")
            return this_branch
        end

        -- STEP 1. STRUCTURE SOLVE
        -- Creates the 'parse tree', solve_stack
        self = structure_solve(self)

        --[[
        --debug:
        print("SOLVE_STACK")
        solve_stack:dump()
        --]]

        -- STEP 2. SOLVE THE GENERATED SOLVE_ATOM STACK
        --Solve the now structured, ordered tree
        local solve_atom = solve_stack:pop()
        local final_resolved
        while solve_atom do 
            --Run through the stack
            -- Solve the atom, put resolved values in the right slots
            solve_atom.resolved = solve_lookup(solve_atom)
            --Store latest solve for self
            final_resolved = solve_atom.resolved
            -- Get next atom (or nil)
            solve_atom = solve_stack:pop()
        end

        --Set main resolved value
        self.resolved = final_resolved

        --Cleanup logs
        vader.logs.main:join_log(method_log:compress())
        
        --Return the resolved value as well, for convenience
        return final_resolved
    end
end

class "Scanner"
do
    function Scanner:__init(name_string, original)
        -----------------
        -- Error Catching
        vader_assert(type(name_string) == "string", "Tried to init a "..type(self).." with name_string type:"..type(name_string)..". Use a string.")
        vader_assert(type(original) == self.content_type, "Tried to init a "..type(self).." with original type:"..type(original)..". Use a "..self.content_type)
        -----------------

        self.name = name_string
        self.original = original
        self.from = 1
        self.to = 1
        self.inspect = self.original:sub(self.name.."__inspect", self.from, self.to)
    end
    function Scanner:at_last_item()
        --[[
        Returns true if the scanner end is at the original items end
        --]]
        return self.to == #self.original
    end
    function Scanner:scan_len()
        --[[
        Returns the scanner items len
        --]]
        return #self.inspect
    end
    function Scanner:original_len()
        --[[
        Returns the original items len
        --]]
        return #self.original
    end
    function Scanner:update()
        self.inspect:feed(self.original:sub(self.name.."__inspect", self.from, self.to).items)
    end
    function Scanner:expand()
        if self.to == #self.original then
            return false
        else
            self.to = math.min(#self.original, self.to + 1)
            self:update()
            return true
        end
    end
    function Scanner:contract()
        if self.to == self.from then
            return false
        else
            self.to = math.max(self.from, self.to - 1)
            self:update()
            return true
        end
    end
    function Scanner:contract_to_one()
        --[[
        Moves self.to on self.from
        --]]
        if self.to == self.from then
            return false
        else
            self.to = self.from
            self:update()
            return true
        end
    end
    function Scanner:expand_()
        if self.from == 1 then
            return false
        else
            self.from = math.max(1, self.from - 1)
            self:update()
            return true
        end
    end
    function Scanner:contract_()
        --[[
        TODO: COMMENT
        --]]
        if self.from == self.to then
            return false
        else
            self.from = math.min(self.from + 1, self.to)
            self:update()
            return true
        end
    end
    function Scanner:contract_to_one_()
        --[[
        Moves self.from on self.to
        --]]
        if self.from == self.to then
            return false
        else
            self.from = self.to
            self:update()
            return true
        end
    end
    function Scanner:mv_fwd()
        --[[
        Caterpillars forward
        --]]
        if self:expand() == true then
            self:contract_()
            return true
        else
            return false
        end
    end
    function Scanner:mv_back()
        --[[
        Caterpillars backward
        --]]
        if self:expand_() == true then
            self:contract()
            return true
        else
            return false
        end
    end
    function Scanner:reset()
        --[[
        Go to start, len 1
        --]]
        self.from = 1
        self.to = 1
        self:update()
    end
    function Scanner:scan_object()
        --[[
        Returns the self.inspect object
        --]]
        return self.inspect
    end
    function Scanner:scan_item(index)
        --[[
        Returns item index n of the scanner object
        --]]
        return self:scan_object():item(index)
    end
    function Scanner:all_scan_items()
        --[[
        Return the entire scan item series.  On character scanner this is a
        string, and on token scanner this is a table of tokens.
        --]]
        return self:scan_object():all_items()
    end
    function Scanner:original_object()
        --[[
        Returns the self.original object
        --]]
        return self.original
    end
    function Scanner:original_item(index)
        --[[
        Returns item index n of the original object
        --]]
        return self:original_object():item(index)
    end
    function Scanner:all_original_items()
        --[[
        Return the entire original item series.  On character scanner this is a
        string, and on token scanner this is a table of tokens
        --]]
        return self:original_object():all_items()
    end
    function Scanner:head()
        --[[
        Returns the first scan item
        --]]
        return self:scan_item(1)
    end
    function Scanner:tail()
        --[[
        Returns the last scan item
        --]]
        return self:scan_item(self:scan_len())
    end
end

class "CharacterScanner" (Scanner)
do
    function CharacterScanner:__init(name_string, original_charstream)
        Scanner.__init(self, name_string, original_charstream)
        self.content_type = "CharacterStream"
    end
end

class "TokenScanner" (Scanner)
do
    function TokenScanner:__init(name_string, original_tokenstream)
        Scanner.__init(self, name_string, original_tokenstream)
        self.content_type = "TokenStream"
    end
end

----------------------------------------------------
-- Pattern data processing
----------------------------------------------------

class "IterationTable"
--[[
This guides the iteration loop process It holds an ordered tree-like reference
table to all the song data objects in iteration range TODO: IS THIS REALLY USED
ANYWHERE? USABLE? NO? REMOVE!:wa
--]]
do
    function IterationTable:__init()
        self.method = nil   --patterns / sequence
        --[[
        self.object_table = {

            pat = {
                objects = {},

                pat_trk = {
                    objects = {},

                    pat_trk_lin = {
                        objects = {},

                        note_cols = {
                            objects = {}
                        },

                        effect_cols = {
                            objects = {}
                        },


                    }
                }
            }
        }
        --]]
        self.index_matrix_pat = table.create()
        self.index_matrix_pat_trk = table.create()
        self.index_matrix_pat_trk_lin = table.create()
        self.index_matrix_column = table.create()
    end
end

class "RangeObject"
--[[
This is used to describe a vader range It is an ordered table of index numbers
that belong in the range
--]]
do
    function RangeObject:__init()
        self.start_value = nil
        self.end_value = nil
        --TODO:FREE TABLE
        --in effect: list of indexes that are part of the set
        self.skip_empty = false
    end
    function RangeObject:dump()
        --[[
        Prints range in terminal
        --]]
        vader.logs.debug:entry("RangeObject dump(): start "..self.start_value.." / end "..self.end_value)
    end
end

class "VaderCursor"
-- This data class can store various cursor positions
do
    function VaderCursor:__init(init_empty)
       self.sequence = nil
       self.pattern = nil
       self.track = nil
       self.line = nil
       self.column = nil
       self.note_column = nil
       self.effect_column = nil
       -- Update to current renoise cursor position
       if not init_empty then
           VaderCursor:get_all()
       end
    end
    function VaderCursor:get_all()
        --[[
        Get current cursor pos
        --]]
        local rs = get_rs()
        local edit_pos = rs.transport.edit_pos
        self.sequence = edit_pos.sequence
        self.pattern = rs.selected_pattern_index
        self.track = rs.selected_track_index
        self.line = edit_pos.line
        self.note_column = rs.selected_note_column_index
        self.effect_column = rs.selected_effect_column_index
    end
    function VaderCursor:get(item)
        --[[
        Get a position index for selected songdata object category
        --]]
        vader_assert(type(item)=="string", "Tried to call "..type(self)..":get() with item type:"..type(item)..". Use a string.")
        local rs = get_rs()
        -- Get current cursor pos
        local edit_pos = rs.transport.edit_pos
        if item == "sequence" then
            self.sequence = edit_pos.sequence
        elseif item == "pattern" then
            self.pattern = rs.selected_pattern_index
        elseif item == "track" then
            self.track = rs.selected_track_index
        elseif item == "line" then
            self.line = edit_pos.line
        elseif item == "note_column" then
            self.note_column = rs.selected_note_column_index
        elseif item == "effect_column" then
            self.effect_column = rs.selected_effect_column_index
        else
            vader.errors:entry("Tried to get an unidentified cursor position:"..item)
        end
    end
    function VaderCursor:set_all()
        --[[
        Set current renoise cursor positions to VaderCursor
        --]]
        local rs = get_rs()
        local c = vader.cursor
        local new_pos = rs.transport.edit_pos
        new_pos.sequence = c.sequence
        rs.selected_pattern_index = c.pattern
        rs.selected_track_index = c.track
        new_pos.line = c.line
        if c.note_column ~= 0 and rs:track(c.track).max_note_columns ~= 0 then
            --it's a note column
            rs.selected_note_column_index = c.note_column
        elseif c.effect_column ~= 0 then
            --it's an effect column?
            rs.selected_effect_column_index = c.effect_column
        else
            --last fallback. effect column has not been set:
            rs.selected_effect_column_index = 1
        end
        rs.transport.edit_pos = new_pos
    end
    function VaderCursor:dump()
        --[[
        Dump cursor info to debug log
        --]]
        vader.logs.debug:entry("sequence:"..self.sequence)
        vader.logs.debug:entry("pattern:"..self.pattern)
        vader.logs.debug:entry("track:"..self.track)
        vader.logs.debug:entry("line:"..self.line)
        vader.logs.debug:entry("note_column:"..self.note_column)
        vader.logs.debug:entry("effect_column:"..self.effect_column)
    end
end

class "ScopePartialObject"
-- This describes a single scope partial
do
    function ScopePartialObject:__init()
        self.level = nil
        self.level_index = nil

        --eg. pattern_level, column_level
        self.name = nil
        --eg. pattern, trackgroup, notevealue
        self.origin = nil
        --eg. user, parser
        self.range = RangeObject()
    end
    function ScopePartialObject:dump()
        --[[
        Dump partial info to debug log
        --]]
        local formatstring_1 = "ScopePartialObject dump(): %s"
        local formatstring_2 = "level:%s  /  origin:%s  /  range:%s..%s"
        vader.logs.debug:entry(string.format(formatstring_1, self.name))
        vader.logs.debug:entry(string.format(formatstring_2, (self.level or "nil"), self.origin, "start "..(self.range.start_value or "nil"), "end "..(self.range.end_value or "nil")))
    end
end
class "ScopeObject"
-- This is used to describe an iteration scope in 0.1
do
    function ScopeObject:__init(cxt)
        local method_log = register_method_log(type(self)..":__init()")
        
        ------------------
        -- Error catching
        vader_assert(type(cxt) == "TokenTree" or type(cxt) == "nil", "Tried to init a ScopeObject with cxt type:"..type(cxt)..". Use a TokenTree object or nil.")
        -----------------
        
        -- Create the partials table
        self.scope = table.create()
        self.topmost_index = nil
        self.topmost_name = nil
        self.lowest_index = nil
        self.lowest_name = nil
        --
        local scp_pattern_level = ScopePartialObject()
        scp_pattern_level.level = "pattern_level"
        scp_pattern_level.level_index = 1
        self.scope:insert(scp_pattern_level)
        --
        local scp_track_level = ScopePartialObject()
        scp_track_level.level = "track_level"  
        scp_pattern_level.level_index = 2
        self.scope:insert(scp_track_level)
        --
        local scp_line_level = ScopePartialObject()
        scp_line_level.level = "line_level" 
        scp_pattern_level.level_index = 3
        self.scope:insert(scp_line_level)
        --
        local scp_column_level = ScopePartialObject()
        scp_column_level.level = "column_level" 
        scp_pattern_level.level_index = 4
        self.scope:insert(scp_column_level)
        --
        local scp_subcolumn_level_note = ScopePartialObject()
        scp_subcolumn_level_note.level = "subcolumn_level_note" 
        scp_pattern_level.level_index = 5
        self.scope:insert(scp_subcolumn_level_note)
        --
        local scp_subcolumn_level_effect = ScopePartialObject()
        scp_subcolumn_level_effect.level = "subcolumn_level_effect" 
        scp_pattern_level.level_index = 6
        self.scope:insert(scp_subcolumn_level_effect)
        --
        --Derive range
        if cxt then
            local process_title = type(self)..":__init() / Derive range"
            local processing_error
            local processing_notes = table.create()
            --Get all scope partials from this context in a table
            local user_partials = table.create()
                
            for index = 1, #cxt do
                local this_partial = cxt:branch(index)
                local this_token = this_partial.name
                if this_token == "<scope partial>" then
                    --Get scope, range start, end
                    local this_scope = this_partial.scope
                    local this_rangedef = this_partial:branch(2)
                    local this_range = this_rangedef:branch(1)
                    local this_start_value = this_range:branch(1).resolved
                    local this_end_value = this_range:branch(2).resolved
                    
                    --Set skip_empty flag and other range extras if needed
                    local this_range_flags = this_rangedef:branch(2)
                    local this_skip_empty
                    if this_range_flags:find_token_type("<symbol non empty>") then
                        this_skip_empty = true
                    else
                        this_skip_empty = false
                    end

                    --Generate partial, insert
                    local new_user_partial = ScopePartialObject()
                    new_user_partial.level = nil
                    new_user_partial.name = this_scope
                    new_user_partial.origin = "user"

                    local n_u_p_range = RangeObject()
                    n_u_p_range.start_value = this_start_value
                    n_u_p_range.end_value = this_end_value
                    n_u_p_range.skip_empty = this_skip_empty

                    new_user_partial.range = n_u_p_range

                    user_partials:insert(new_user_partial)

                    vader.logs.debug:entry("collected user partial:"..new_user_partial.name) --debug

                end
            end
            --Select partials to use in scope
            local function select_partial(scope_name)
                -- This searches the local user_partials-table for partialstring, and
                -- returns partialstring if found, nil if not
                -- This is a subfunction for the selection loop
                for _, partial in pairs(user_partials) do
                    --if user_partials:find(partialstring) then
                    --vader.logs.debug:entry("comparing: "..scope_name.."  /  "..partial.name) --debug
                    if partial.name == scope_name then
                        --vader.logs.debug:entry("found "..scope_name) --debug
                        return partial
                    end
                end
                return nil
            end
            for level_index, level in ipairs(vader.lex.scope_levels) do
                --This loop runs through vader.lex.scope_levels and
                --selects the topmost of all user inputted partials within a scope level [n]
                --for each level, sets either the default scope[n].name or the user inputted scope[n].name
                --also sets the scope[n].origin property
                
                --Get the level name
                local level_name
                for name, _ in pairs(level) do
                    level_name = name
                end
                --Run through items in level table
                for scope_index, scope_name in ripairs(level[level_name]) do
                    local defined_partial = select_partial(scope_name)
                    local default_partialstring = level[level_name][1]
                    --vader.logs.debug:entry("searching scope:"..scope_name) --debug
                    if defined_partial then
                        --TODO:here is some fishy business: why is the first one
                        --defining .level and the second one .name ???
                        self.scope[level_index] = defined_partial
                        self.scope[level_index].level = level_name
                        --self.scope[level_index].name = defined_partialstring
                        self.scope[level_index].origin = "user"
                        break
                    else
                        self.scope[level_index].name = default_partialstring
                        self.scope[level_index].origin = "parser"
                    end
                end
                --vader.logs.debug:entry("searched level:"..level_name..". No more partials!") --debug
            end

            --[[
            --debug
            for _, partial in ipairs(self.scope) do
                partial:dump()
            end
            --]]

            --Compute full range from sparse partial definition
            --Need topmost, lowest user defined levels
            local topmost_name = nil
            local topmost_index = nil
            for scope_level_index, scope_level in ipairs(self.scope) do
                if not topmost_name and scope_level.origin == "user" then
                    topmost_name = scope_level.name
                    topmost_index = scope_level_index
                    --vader.logs.debug:entry("topmost found:"..topmost_name) --debug
                    break
                end
            end
            if not topmost_name then
                vader_error("Could not find topmost defined level in scope!")
            end

            local lowest_name = nil
            local lowest_index = nil
            for scope_level_index, scope_level in ripairs(self.scope) do
                if not lowest_name and scope_level.origin == "user" then
                    lowest_name = scope_level.name
                    lowest_index = scope_level_index
                    --vader.logs.debug:entry("lowest found:"..lowest_name) --debug
                    break
                end
            end
            if not lowest_name then
                vader_error("Could not find lowest defined level in scope!")
            end
            
            -- Assign to object properties
            self.topmost_index = topmost_index
            self.topmost_name = topmost_name
            self.lowest_index = lowest_index
            self.lowest_name = lowest_name

            --Now haz calculated topmost, lowest defined ranges. Make rest up
            vader.logs.debug:entry("defined lowest:"..lowest_name.." / "..lowest_index..", topmost:"..topmost_name.."  /  "..topmost_index)

            for level_index, level_partial in ipairs(self.scope) do
                --This loops creates parser generated 'ghost' ranges for the scope

                --TODO: must assign only one subcolumn value, preference is from column level
                if level_index < topmost_index then
                    --level index is above topmost
                    --apply 'current' range
                    --vader.logs.debug:entry(level_partial.name)
                    local this_range = level_partial.range
                    local solve_stream = TokenStream("solve_stream")
                    local solve_atom = TokenTree("solve_atom", solve_stream)
                    solve_atom.scope = level_partial.name
                    solve_stream:push(Token("<value current>", "<value current>"))
                    local notes
                    this_range.start_value, processing_error, notes = solve_lookup(solve_atom)
                    if not this_range.start_value then
                        return false, processing_error, nil
                    elseif notes then
                        for _, note in ipairs(notes) do
                            processing_notes:insert(note)
                        end
                    end
                    this_range.end_value = this_range.start_value
                    --vader.logs.debug:entry("set parser partial start, end:"..level_partial.range.start_value..", "..level_partial.range.end_value) --debug
                    
                    
                elseif level_index > lowest_index then
                    --level index is below lowest_index
                    --apply '<no_range>' -range
                    --vader.logs.debug:entry(level_partial.name)
                    local this_range = level_partial.range
                    this_range.start_value = nil
                    this_range.end_value = nil
                elseif level_partial.origin == "parser" then
                    --level index is between topmost and lowest
                    --and is not defined by user
                    --apply 'each and every' -range
                    --vader.logs.debug:entry(level_partial.name)
                    local this_range = level_partial.range

                    local solve_stream = TokenStream("solve_stream")
                    local solve_atom = TokenTree("solve_atom", solve_stream)
                    solve_atom.scope = level_partial.name
                    solve_stream:push(Token("<symbol min>", "<symbol min>"))
                    local notes
                    this_range.start_value, processing_error, notes = solve_lookup(solve_atom)
                    if not this_range.start_value then
                        return false, processing_error, nil
                    elseif notes then
                        for _, note in ipairs(notes) do
                            processing_notes:insert(note)
                        end
                    end

                    local solve_stream = TokenStream("solve_stream")
                    local solve_atom = TokenTree("solve_atom", solve_stream)
                    solve_atom.scope = level_partial.name
                    solve_stream:push(Token("<symbol max>", "<symbol max>"))
                    local notes
                    this_range.end_value, processing_error, notes = solve_lookup(solve_atom)
                    if not this_range.end_value then
                        return false, processing_error, nil
                    elseif notes then
                        for _, note in ipairs(notes) do
                            processing_notes:insert(note)
                        end
                    end
                end
            end

        else
            --no context_tree supplied.
            vader.logs.debug:entry("Some weird shit happ'nin, boss")
        return self, nil, processing_notes
        end
    end
    function ScopeObject:dump()
        --[[
        Dump Scope info to debug log
        --]]
        local method_log = register_method_log(type(self)..":dump()")

        vader.logs.debug:entry("ScopeObject dump():")
        vader.logs.debug:entry("--")
        vader.logs.debug:entry("PATTERN LEVEL - " .. (self.scope[1].name or "nil"))
        self.scope[1]:dump()
        vader.logs.debug:entry("--")
        vader.logs.debug:entry("TRACK LEVEL - " .. (self.scope[2].name or "nil"))
        self.scope[2]:dump()
        vader.logs.debug:entry("--")
        vader.logs.debug:entry("LINE LEVEL - " .. (self.scope[3].name or "nil"))
        self.scope[3]:dump()
        vader.logs.debug:entry("--")
        vader.logs.debug:entry("COLUMN LEVEL - " .. (self.scope[4].name or "nil"))
        self.scope[4]:dump()
        vader.logs.debug:entry("--")
        vader.logs.debug:entry("SUBCOLUMN LEVEL NOTE - " .. (self.scope[5].name or "nil"))
        self.scope[5]:dump()
        vader.logs.debug:entry("--")
        vader.logs.debug:entry("SUBCOLUMN LEVEL EFFECT- " .. (self.scope[6].name or "nil"))
        self.scope[6]:dump()
        vader.logs.debug:entry("--")
    end
    function ScopeObject:partial(level_index)
        --[[
        Returns a partial by level_index
        --]]
        local method_log = register_method_log(type(self)..":partial()")

        return self.scope[level_index]
    end
    function ScopeObject:get_object_pointed_at()
        --[[
        Returns the CURRENT object that is pointed at in the scope.
        i.e. the object that has "lowest index",
        i.e. the final object user is pointing at with scope.
        --]]
        local method_log = register_method_log(type(self)..":get_object_pointed_at()")

        local low_i = self.lowest_index
        local low_name = self.lowest_name
        --[[
        local valid_type = {
            "pattern",
            "pattern_track",
            "pattern_track_line",
            "note_column",
            "effect_column",
        }
        --]]
        if low_name == "pattern" then
            return get_selected("pattern")
        elseif low_name == "track" then
            return get_selected("pattern_track")
        elseif low_name == "line" then
            return get_selected("pattern_track_line")
        elseif low_name == "note_column" then
            return get_selected("note_column")
        elseif low_name == "effect_column" then
            return get_selected("effect_column")
        else
            local error = "Could not define low_name in get_object_pointed_at()"
            return false, error, nil
        end
    end
end
class "ScopeObject_2"
-- This is used to describe an iteration scope in 0.2
-- Point a scope in parsed table, init the object with myscope = ScopeObject_2(pointed_table)
do
    function ScopeObject_2:__init(parsed_table)
        local method_log = register_method_log(type(self)..":__init()")
        
        ------------------
        -- Error catching
        vader_assert(type(parsed_table) == "table" or type(parsed_table) == "nil", "Tried to init a ScopeObject_2 with parsed_table type:"..type(parsed_table)..". Use a table or nil.")
        -----------------
        
        -- Create the partials table
        self.scope = table.create()
        -- Init data indexes
        self.topmost_index = nil
        self.topmost_name = nil
        self.lowest_index = nil
        self.lowest_name = nil
        --
        local scp_pattern_level = ScopePartialObject()
        scp_pattern_level.level = "pattern_level"
        scp_pattern_level.level_index = 1
        self.scope:insert(scp_pattern_level)
        --
        local scp_track_level = ScopePartialObject()
        scp_track_level.level = "track_level"  
        scp_pattern_level.level_index = 2
        self.scope:insert(scp_track_level)
        --
        local scp_line_level = ScopePartialObject()
        scp_line_level.level = "line_level" 
        scp_pattern_level.level_index = 3
        self.scope:insert(scp_line_level)
        --
        local scp_column_level = ScopePartialObject()
        scp_column_level.level = "column_level" 
        scp_pattern_level.level_index = 4
        self.scope:insert(scp_column_level)
        --
        local scp_subcolumn_level_note = ScopePartialObject()
        scp_subcolumn_level_note.level = "subcolumn_level_note" 
        scp_pattern_level.level_index = 5
        self.scope:insert(scp_subcolumn_level_note)
        --
        local scp_subcolumn_level_effect = ScopePartialObject()
        scp_subcolumn_level_effect.level = "subcolumn_level_effect" 
        scp_pattern_level.level_index = 6
        self.scope:insert(scp_subcolumn_level_effect)
        --
        --Derive range
        if parsed_table then

            local process_title = type(self)..":__init() / Derive range"
            local processing_error
            local processing_notes = table.create()

            --Get all scope partials from this context in a table
            local user_partials = table.create()
                
            --Loop over all SCP_XXX keys in SCP
            --index will be SCP_XXX, this_partial will be the subtable
            for index, this_partial in pairs(parsed_table) do
                    --Get scope
                    --Find SCT_ key
                    local this_scope = nil
                    for key, value in pairs(this_partial) do
                        if string.sub(key, 1, 4) == "SCT_" then
                        this_scope = key
                    end
                    vader_assert(this_scope, "Could not find a scopetag in parsed scope table.")
                    --Define range specs
                    local this_range = this_partial["RNG_DEF"]
                    local this_start_value = this_range["BEG_VAL"]
                    local this_end_value = this_range["END_VAL"]
                    
                    --Set skip_empty flag and other range extras if needed
                    local this_range_flags = this_partial["SCP_FLG"]

                    local this_skip_empty = nil
                    for index, flag in pairs (this_range_flags) do
                        --Skip empty flag
                        if this_range_flags:find_token_type("'") then
                            this_skip_empty = true
                        else
                            this_skip_empty = false
                        end
                    end

                    --Generate partial, insert
                    local new_user_partial = ScopePartialObject()
                    new_user_partial.level = nil
                    new_user_partial.name = this_scope
                    new_user_partial.origin = "user"

                    local n_u_p_range = RangeObject()
                    n_u_p_range.start_value = this_start_value
                    n_u_p_range.end_value = this_end_value
                    n_u_p_range.skip_empty = this_skip_empty

                    new_user_partial.range = n_u_p_range

                    user_partials:insert(new_user_partial)

                    vader.logs.debug:entry("collected user partial:"..new_user_partial.name) --debug

                end
            end
            

            ----> MO got here from ^there
            --Build new ScopeObject_2 class to init a scope from parsed LPeg Table!


            --Select partials to use in scope
            local function select_partial(scope_name)
                -- This searches the local user_partials-table for partialstring, and
                -- returns partialstring if found, nil if not
                -- This is a subfunction for the selection loop
                for _, partial in pairs(user_partials) do
                    --if user_partials:find(partialstring) then
                    --vader.logs.debug:entry("comparing: "..scope_name.."  /  "..partial.name) --debug
                    if partial.name == scope_name then
                        --vader.logs.debug:entry("found "..scope_name) --debug
                        return partial
                    end
                end
                return nil
            end
            for level_index, level in ipairs(vader.lex.scope_levels) do
                --This loop runs through vader.lex.scope_levels and
                --selects the topmost of all user inputted partials within a scope level [n]
                --for each level, sets either the default scope[n].name or the user inputted scope[n].name
                --also sets the scope[n].origin property
                
                --Get the level name
                local level_name
                for name, _ in pairs(level) do
                    level_name = name
                end
                --Run through items in level table
                for scope_index, scope_name in ripairs(level[level_name]) do
                    local defined_partial = select_partial(scope_name)
                    local default_partialstring = level[level_name][1]
                    --vader.logs.debug:entry("searching scope:"..scope_name) --debug
                    if defined_partial then
                        --TODO:here is some fishy business: why is the first one
                        --defining .level and the second one .name ???
                        self.scope[level_index] = defined_partial
                        self.scope[level_index].level = level_name
                        --self.scope[level_index].name = defined_partialstring
                        self.scope[level_index].origin = "user"
                        break
                    else
                        self.scope[level_index].name = default_partialstring
                        self.scope[level_index].origin = "parser"
                    end
                end
                --vader.logs.debug:entry("searched level:"..level_name..". No more partials!") --debug
            end

            --[[
            --debug
            for _, partial in ipairs(self.scope) do
                partial:dump()
            end
            --]]

            --Compute full range from sparse partial definition
            --Need topmost, lowest user defined levels
            local topmost_name = nil
            local topmost_index = nil
            for scope_level_index, scope_level in ipairs(self.scope) do
                if not topmost_name and scope_level.origin == "user" then
                    topmost_name = scope_level.name
                    topmost_index = scope_level_index
                    --vader.logs.debug:entry("topmost found:"..topmost_name) --debug
                    break
                end
            end
            if not topmost_name then
                vader_error("Could not find topmost defined level in scope!")
            end

            local lowest_name = nil
            local lowest_index = nil
            for scope_level_index, scope_level in ripairs(self.scope) do
                if not lowest_name and scope_level.origin == "user" then
                    lowest_name = scope_level.name
                    lowest_index = scope_level_index
                    --vader.logs.debug:entry("lowest found:"..lowest_name) --debug
                    break
                end
            end
            if not lowest_name then
                vader_error("Could not find lowest defined level in scope!")
            end
            
            -- Assign to object properties
            self.topmost_index = topmost_index
            self.topmost_name = topmost_name
            self.lowest_index = lowest_index
            self.lowest_name = lowest_name

            --Now haz calculated topmost, lowest defined ranges. Make rest up
            vader.logs.debug:entry("defined lowest:"..lowest_name.." / "..lowest_index..", topmost:"..topmost_name.."  /  "..topmost_index)

            for level_index, level_partial in ipairs(self.scope) do
                --This loops creates parser generated 'ghost' ranges for the scope

                --TODO: must assign only one subcolumn value, preference is from column level
                if level_index < topmost_index then
                    --level index is above topmost
                    --apply 'current' range
                    --vader.logs.debug:entry(level_partial.name)
                    local this_range = level_partial.range
                    local solve_stream = TokenStream("solve_stream")
                    local solve_atom = TokenTree("solve_atom", solve_stream)
                    solve_atom.scope = level_partial.name
                    solve_stream:push(Token("<value current>", "<value current>"))
                    local notes
                    this_range.start_value, processing_error, notes = solve_lookup(solve_atom)
                    if not this_range.start_value then
                        return false, processing_error, nil
                    elseif notes then
                        for _, note in ipairs(notes) do
                            processing_notes:insert(note)
                        end
                    end
                    this_range.end_value = this_range.start_value
                    --vader.logs.debug:entry("set parser partial start, end:"..level_partial.range.start_value..", "..level_partial.range.end_value) --debug
                    
                    
                elseif level_index > lowest_index then
                    --level index is below lowest_index
                    --apply '<no_range>' -range
                    --vader.logs.debug:entry(level_partial.name)
                    local this_range = level_partial.range
                    this_range.start_value = nil
                    this_range.end_value = nil
                elseif level_partial.origin == "parser" then
                    --level index is between topmost and lowest
                    --and is not defined by user
                    --apply 'each and every' -range
                    --vader.logs.debug:entry(level_partial.name)
                    local this_range = level_partial.range

                    local solve_stream = TokenStream("solve_stream")
                    local solve_atom = TokenTree("solve_atom", solve_stream)
                    solve_atom.scope = level_partial.name
                    solve_stream:push(Token("<symbol min>", "<symbol min>"))
                    local notes
                    this_range.start_value, processing_error, notes = solve_lookup(solve_atom)
                    if not this_range.start_value then
                        return false, processing_error, nil
                    elseif notes then
                        for _, note in ipairs(notes) do
                            processing_notes:insert(note)
                        end
                    end

                    local solve_stream = TokenStream("solve_stream")
                    local solve_atom = TokenTree("solve_atom", solve_stream)
                    solve_atom.scope = level_partial.name
                    solve_stream:push(Token("<symbol max>", "<symbol max>"))
                    local notes
                    this_range.end_value, processing_error, notes = solve_lookup(solve_atom)
                    if not this_range.end_value then
                        return false, processing_error, nil
                    elseif notes then
                        for _, note in ipairs(notes) do
                            processing_notes:insert(note)
                        end
                    end
                end
            end

        else
            --no context_tree supplied.
            vader.logs.debug:entry("Some weird shit happ'nin, boss")
            return self, nil, processing_notes
        end
    end
    function ScopeObject_2:dump()
        --[[
        Dump Scope info to debug log
        --]]
        local method_log = register_method_log(type(self)..":dump()")

        vader.logs.debug:entry("ScopeObject_2 dump():")
        vader.logs.debug:entry("--")
        vader.logs.debug:entry("PATTERN LEVEL - " .. (self.scope[1].name or "nil"))
        self.scope[1]:dump()
        vader.logs.debug:entry("--")
        vader.logs.debug:entry("TRACK LEVEL - " .. (self.scope[2].name or "nil"))
        self.scope[2]:dump()
        vader.logs.debug:entry("--")
        vader.logs.debug:entry("LINE LEVEL - " .. (self.scope[3].name or "nil"))
        self.scope[3]:dump()
        vader.logs.debug:entry("--")
        vader.logs.debug:entry("COLUMN LEVEL - " .. (self.scope[4].name or "nil"))
        self.scope[4]:dump()
        vader.logs.debug:entry("--")
        vader.logs.debug:entry("SUBCOLUMN LEVEL NOTE - " .. (self.scope[5].name or "nil"))
        self.scope[5]:dump()
        vader.logs.debug:entry("--")
        vader.logs.debug:entry("SUBCOLUMN LEVEL EFFECT- " .. (self.scope[6].name or "nil"))
        self.scope[6]:dump()
        vader.logs.debug:entry("--")
    end
    function ScopeObject_2:partial(level_index)
        --[[
        Returns a partial by level_index
        --]]
        local method_log = register_method_log(type(self)..":partial()")

        return self.scope[level_index]
    end
    function ScopeObject_2:get_object_pointed_at()
        --[[
        Returns the CURRENT object that is pointed at in the scope.
        i.e. the object that has "lowest index",
        i.e. the final object user is pointing at with scope.
        --]]
        local method_log = register_method_log(type(self)..":get_object_pointed_at()")

        local low_i = self.lowest_index
        local low_name = self.lowest_name
        --[[
        local valid_type = {
            "pattern",
            "pattern_track",
            "pattern_track_line",
            "note_column",
            "effect_column",
        }
        --]]
        if low_name == "pattern" then
            return get_selected("pattern")
        elseif low_name == "track" then
            return get_selected("pattern_track")
        elseif low_name == "line" then
            return get_selected("pattern_track_line")
        elseif low_name == "note_column" then
            return get_selected("note_column")
        elseif low_name == "effect_column" then
            return get_selected("effect_column")
        else
            local error = "Could not define low_name in get_object_pointed_at()"
            return false, error, nil
        end
    end
end

----------------------------------------------------
-- Logging
----------------------------------------------------

class "LogObject"
-- This is a single log item
do
    function LogObject:__init(entry_string, verbosity)
        -----------------
        -- Error catching
        vader_assert(entry_string, "Tried to init a LogObject using a nil string argument, use a string")
        vader_assert(type(entry_string) == "string", "Tried to init a LogObject with type:"..type(entry_string)..". Only accepted type is string.")
        -- Default values
        verbosity = verbosity or 0 --default verbosity level (0=show always)
        vader_assert(type(verbosity) == "number", "Tried to init a LogObject with verbosity type:"..type(verbosity)..". Only accepted type is number.")
        -----------------
        
        -- Object properties
        self.time = os.date() --last edit of this entry
        self.time_c = os.date() --creation time
        self.string = entry_string
        self.verbosity = verbosity
    end
    function LogObject:edit(edit_string)
        --[[
        Edits the LogObject.string into edit_string
        --]]
        
        -----------------
        -- Error catching
        vader_assert(edit_string, "Tried to edit a LogObject string using a nil string argument, use string")
        vader_assert(type(edit_string) == "string", "Tried to edit a LogObject string with type:"..type(edit_string)..". Only accepted type is string.")
        -----------------
        
        -- Set properties
        self.time = os.date() --last edit
        self.string = edit_string
    end
    function LogObject:append(append_string, separator_string)
        --[[
        Appends to the LogObject.string with separator_string..append_string
        If no separator_string set, vader.LOG_DEFAULT_SEPARATOR will be used
        --]]
        
        -----------------
        -- Error catching
        vader_assert(append_string, "Tried to append to a LogObject string using a nil string argument, use a string")
        vader_assert(type(append_string) == "string", "Tried to append to a LogObject string with type:"..type(append_string)..". Only accepted type is string.")
        separator_string = separator_string or vader.LOG_DEFAULT_SEPARATOR
        vader_assert(type(separator_string) == "string", "Tried to append to a LogObject string with separator type:"..type(separator_string)..". Only accepted type is string.")
        -----------------

        -- Set properties
        self.time = os.date() --last edit
        self.string = self.string..vader.LOG_DEFAULT_SEPARATOR..append_string
    end
end

class "ALog" (AQueue)
-- This is a general log. Handles logging stuff, AND displaying the stuff being logged.
do
    function ALog:__init(name_string, target_display, verbosity_threshold, max_len)
        AQueue.__init(self, name_string)
        self.type = "ALog"
        self.content_type = "LogObject"
        
        -----------------
        -- Error catching
        vader_assert(type(target_display) == "ADisplay", "Tried to init "..type(self).." with target_display type:"..type(target_display)..". Use an ADisplay object.")
        -- Default values
        self.target_display = target_display or vader.displays.dump
        verbosity_threshold = verbosity_threshold or 0
        self.max_len = max_len or vader.LOG_DEFAULT_MAX_LEN
        -----------------

        self.target_display = target_display
        self.verbosity_threshold =verbosity_threshold 
        self.distribute_logs = AQueue("distribute_logs")
        self.distribute_logs.content_type = "ALog"
        -- Create init LogObject
        self:entry(self.name.." initialized (ALog)", vader.LOG_INIT_VERBOSITY)
    end
    function ALog:entry(entry_object, verbosity)
        --[[
        Inserts an entry to top of list
        Entry object type either a LogObject or a string (will be converted into a LogObject)
        If string is used, a verbsity level can be given with the latter argument
        --]]
        
        ---------------
        -- Error catching
        vader_assert(entry_object, "Tried to insert a nil object into ALog ("..self.name.."), use a LogObject or a string.")
        vader_assert(type(entry_object) == "LogObject" or type(entry_object) == "string", "Tried to insert type:"..type(entry_object).." into ALog. Only accepted types are LogObject and string.")
        ---------------
        
        -- Declare the internal variable that will be occupied with the entry
        local final_entry
        -- Validate entry_object, populate final_entry
        if type(entry_object) ==  "string" then
            final_entry = LogObject(entry_object, verbosity)
        else
            final_entry = entry_object
        end
        
        -- Insert final_entry
        self:push(final_entry)
        -- Run display:show function
        if final_entry.verbosity <= self.verbosity_threshold then
            if self.target_display ~= nil then
                --self.target_display:show(self.name..vader.LOG_DEFAULT_SEPARATOR..final_entry.string)
                self.target_display:show(final_entry.string)
            end
        end

        -- and all the logs in self.distribute logs
        if #self.distribute_logs > 0 then
            for _, distribute_log in pairs(self.distribute_logs.items) do
                distribute_log:entry(self.name and self.name..vader.LOG_DEFAULT_SEPARATOR..final_entry.string or "no name"..vader.LOG_DEFAULT_SEPARATOR..final_entry.string, verbosity)
            end
        end
        --TODO: this allows for an endless loop, if by some freak accident
        --one defines a loop in distribution (Log A -> Log B -> Log A ...etc)
        ---------------
        
        -- Return the log_object
        return final_entry
    end
    function ALog:dump(target_display, verbosity)
        --[[
        This will dump the log in target_display target_display must be
        ADisplay-object, and registered under vader.displays.

        see "output.lua"

        Verbosity is to set dump threshold, type = number
        --]]
        
        -----------------
        -- Default values
        target_display = target_display or vader.displays.dump
        verbosity = verbosity or 0
        -- Error catching
        vader_assert(type(target_display) == "ADisplay", "Tried to dump "..type(self).." ("..self.name..") into a target_display type:"..type(target_display)..". Use ADisplay object.")
        vader_assert(type(verbosity) == "number", "Tried to dump "..type(self).." ("..self.name..") with verbosity level type:"..type(verbosity)..". Use number.") 
        -----------------
        
        -- Dump title
        local verbosity_string = ""
        if verbosity and verbosity > 0 then
            verbosity_string = " (verbosity level "..verbosity..")"
        end
        target_display:show("-----------------------------------------")
        target_display:show("START DUMP OF LOG: '"..self.name.."'"..verbosity_string)
        -- Dump items iteration
        for key, value in pairs(self.items) do
            if value.verbosity <= verbosity then
                -- Dump this item
                target_display:show(string.format("-------\n[%i]:%s\n   %s\n    (created %s)", key, value.string, value.time, value.time_c))
            end
        end
        -- Dump end
        target_display:show("END DUMP OF LOG: '"..self.name.."'"..verbosity_string)
        target_display:show("-----------------------------------------")
    end
    function ALog:verbosity(verbosity_threshold)
        --[[
        Sets log item display verbosity threshold
        --]]
        
        -----------------
        -- Error catching
        vader_assert(type(verbosity_threshold) == "number", "Tried to set "..type(self).." verbosity_threshold with argument type:"..verbosity_threshold..". Use number.")
        -----------------
        
        self.verbosity_threshold = verbosity_threshold
    end
    function ALog:get_items_table(verbosity_threshold)
        --[[
        Returns all items under verbosity threshold
        --]]
        
        -----------------
        -- Default values
        verbosity_threshold = verbosity_threshold or 0
        -- Error catching
        vader_assert(type(verbosity_threshold) == "number", "Tried to get "..type(self).." items with verbosity_threshold argument type:"..verbosity_threshold..". Use number.")
        -----------------

        local retval = table.create()
        for key, item in ipairs(self.items) do
            if item.verbosity <= verbosity_threshold then
                retval:insert(item)
            end
        end
        return retval
    end
    function ALog:create_empty_instance(name_string)
        --[[
        This is a helper that returns an empty instance of this class. Helps
        functions that return other instances of their class.  Specific to each
        class.
        --]]
        return ALog(name_string, self.target_display, self.verbosity_threshold)
    end
    function ALog:add_distribute_log(distribute_log)
        --[[
        Adds a log in self.distribute logs, effectively adds a note to echo all
        entries of this log into the added log
        --]]
        self.distribute_logs:push(distribute_log)
        distribute_log:entry(self.name.." registered as sublog of "..distribute_log.name, vader.LOG_INIT_VERBOSITY)
    end
    function ALog:compress()
        --[[
        Compresses repeating log information

        A destructive method!
        --]]
        if #self > 0 then
            -- Get final log_items in this table
            local final_log_items = {
                ["log_items"] = table.create(),
                ["pcs"] = table.create(),
            }
            -- Collect unique log_items and set their count
            for _, log_item in ipairs(self.items) do
                -- Run through the self.items table,
                local this_string = log_item.string
                local is_there = table.find(final_log_items.log_items, this_string)
                if not is_there then
                    -- There are no log_items like this yet, add it to final_log_items table,
                    -- set pcs value to 1
                    final_log_items.log_items:insert(this_string)
                    final_log_items.pcs:insert(1)
                else
                    -- There already is a log_item like this in final_log_items table,
                    -- increment pcs value of said log_item
                    final_log_items.pcs[is_there] = final_log_items.pcs[is_there] + 1
                end
            end
            -- Create the absolutely_final_log_items table
            local absolutely_final_log_items = table.create()
            for _, log_item_string in ipairs(final_log_items.log_items) do
                absolutely_final_log_items:insert(LogObject(log_item_string..vader.LOG_DEFAULT_SEPARATOR.."x"..final_log_items.pcs[_]..vader.LOG_DEFAULT_SEPARATOR.."(Cmp)"))
            end
            -- Do the hustle!
            self.items = absolutely_final_log_items
        end
        return self
    end
    function ALog:join_log(alog)
        --[[
        Joins alog to self, emptying alog in the process
        --]]
        
        -----------------
        -- Error catching
        vader_assert(type(alog) == "ALog", "Tried to call "..type(self)..":add_log() ("..self.name..") with alog argument type:"..type(alog)..". Use ALog object.")
        -----------------

        if #alog == 0 then
            --silent exit
            return
        end
        --Transfer data to self
        for _ = 1, #alog do
            --self:push(alog:pop())
            local this_entry = alog:pop()
            this_entry.string = alog.name..vader.LOG_DEFAULT_SEPARATOR..this_entry.string
            self:entry(this_entry)
        end
    end
end


----------------------------------------------------
-- Options
----------------------------------------------------

class "VaderOption"
-- This is an option, controllable by user
do
    function VaderOption:__init(name_string, set_function, value_type_string, flag_table)
        -----------------
        -- Error catching
        vader_assert(type(name_string) == "string", "Tried to init a "..type(self).." with name_string argument type:"..type(name_string)..". Use a string.")
        vader_assert(type(set_function) == "function", "Tried to init a "..type(self).." with set_function argument type:"..type(set_function)..". Use a function.")
        vader_assert(type(value_type_string) == "string", "Tried to init a "..type(self).." with value_type_string argument type:"..type(value_type_string)..". Use a string.")
        vader_assert(type(flag_table) == "table", "Tried to init a "..type(self).." with flag_table argument type:"..type(flag_table)..". Use a table.")
        -----------------

        self.name = name_string
        self.value_type = value_type_string
        --[[
        {
        ["<flg exit>"] = true,
        ["<flg exit_2>"] = true,
        }
        --]]
        --TODO:constraints
        self.value = table.create()
        self.value.global = nil
        self.value.script = nil
    end
    function VaderOption:set(value)
        -----------------
        -- Error catching
        vader_assert(type(value) == self.value_type, "Tried to call "..type(self)..":set ("..self.name..") with mismatching value type. Value type for this instance is:"..self.value_type..".")
        -----------------
    end
    function VaderOption:set_for_script(value)
        self:set(value)
        self.value.script = value
    end
    function VaderOption:set_for_global(value)
        self:set(value)
        self.value.global = value
    end
    function VaderOption:reset_from_global()
        self.value.script = self.value.global
    end
end
-- User variables
--

-- Macros
--

-- Solve lookup?
--
