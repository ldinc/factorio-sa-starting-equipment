---@meta
-- Type definitions for the FactorioTest globals and the luassert functions used in src/tests.
-- Only for the Lua language server (editor + `lua-language-server --check`); never loaded by the game.
-- FactorioTest part: factorio-test.def.lua from https://github.com/GlassBricks/FactorioTest (MIT).

---@type TestCreator
test = nil
---@type TestCreator
it = nil
---@type DescribeCreator
describe = nil
---@type LifecycleFn
before_all = nil
---@type LifecycleFn
after_all = nil
---@type LifecycleFn
before_each = nil
---@type LifecycleFn
after_each = nil
---@type LifecycleFn
after_test = nil

---@param timeout number|nil
---@overload fun()
function async(timeout) end

function done() end

---@param func OnTickFn
function on_tick(func) end

---@param ticks number
---@param func TestFn
function after_ticks(ticks, func) end

---@param ticks number
function ticks_between_tests(ticks) end

---@vararg string
function tags(...) end

---@class FactorioTestConfig
---@field default_timeout number | nil
---@field default_ticks_between_tests number | nil
---@field game_speed number | nil
---@field log_passed_tests boolean | nil
---@field log_skipped_tests boolean | nil
---@field test_pattern string | nil
---@field tag_whitelist string[] | nil
---@field tag_blacklist string[] | nil
---@field before_test_run fun() | nil
---@field after_test_run fun() | nil
---@field sound_effects boolean | nil

---@alias TestFn fun()
---@alias HookFn TestFn
---@alias OnTickFn (fun(tick: number)) | (fun(tick: number): boolean)

---@class TestCreatorBase
---@overload fun(name: string, func: TestFn): TestBuilder<TestFn>
local TestCreatorBase = {}

---@param values any[] rows (tables, spread into arguments) or single values
---@return fun(name: string, func: fun(...: any))
function TestCreatorBase.each(values) end

---@class TestCreator : TestCreatorBase
---@overload fun(name: string, func: TestFn): TestBuilder<TestFn>
---@field skip TestCreatorBase
---@field only TestCreatorBase
local TestCreator = {
    ---@param name string
    todo = function(name)
    end
}

---@class TestBuilder<T>
local TestBuilder = {}

---@generic T
---@param func T
---@return TestBuilder<T>
function TestBuilder.after_script_reload(func) end

---@generic T
---@param func T
---@return TestBuilder<T>
function TestBuilder.after_mod_reload(func) end

---@class DescribeCreatorBase
---@overload fun(name: string, func: TestFn)
local DescribeCreatorBase = {}

---@param values any[] rows (tables, spread into arguments) or single values
---@return fun(name: string, func: fun(...: any))
function DescribeCreatorBase.each(values) end

---@class DescribeCreator : DescribeCreatorBase
---@overload fun(name: string, func: TestFn)
---@field skip DescribeCreatorBase
---@field only DescribeCreatorBase

---@alias LifecycleFn fun(func: HookFn)

-- ---------------------------------------------------------------- luassert (load_luassert = true)

---@class luassert.modifier
---@field same fun(expected: any, actual: any, message?: string)
---@field equal fun(expected: any, actual: any, message?: string)
---@field equals fun(expected: any, actual: any, message?: string)
---@field near fun(expected: number, actual: number, tolerance: number, message?: string)
---@field truthy fun(value: any, message?: string)
---@field falsy fun(value: any, message?: string)
---@field error fun(fn: function, expected?: any, message?: string)
---@field has_error fun(fn: function, expected?: any, message?: string)
---@field unique fun(list: table, deep?: boolean, message?: string)
---@field matches fun(pattern: string, actual: string, init?: integer, plain?: boolean, message?: string)

---@class luassert: luassert.modifier
---@field are luassert.modifier
---@field is luassert.modifier
---@field are_not luassert.modifier
---@field is_not luassert.modifier
---@field is_true fun(value: any, message?: string)
---@field is_false fun(value: any, message?: string)
---@field is_nil fun(value: any, message?: string)
---@field is_not_nil fun(value: any, message?: string)
---@field is_table fun(value: any, message?: string)
---@field is_string fun(value: any, message?: string)
---@field is_number fun(value: any, message?: string)
---@field is_function fun(value: any, message?: string)
---@field has_no fun(...): luassert.modifier
---@overload fun(value: any, message?: any, ...: any): any
assert = nil
