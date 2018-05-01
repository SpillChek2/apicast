--- Policy module
-- Policies should define a method for each of the nginx phases (rewrite,
-- access, etc.) in which they want to run code. When Apicast runs each of
-- those phases, if the policy has been loaded, it will run the code in the
-- method with the phase name. So for example, if we want to define a policy
-- that needs to execute something in the rewrite phase, we need to write
-- a 'rewrite' method.

local _M = { }

local PHASES = {
    'init', 'init_worker',
    'rewrite', 'access',
    'content', 'balancer',
    'header_filter', 'body_filter',
    'post_action',  'log', 'metrics',
}

local setmetatable = setmetatable
local ipairs = ipairs
local format = string.format
local empty = table.new(0,0 )
local noop = function() end

local function __tostring(policy)
    return format("Policy: %s (%s)", policy._NAME, policy._VERSION)
end

local function __eq(policy, other)
    return policy._NAME == other._NAME and policy._VERSION == other._VERSION
end

local inspect = require('inspect')

local function __gc(proxy)
    local policy = getmetatable(proxy).__index -- proxy always points to the policy
    local mt = getmetatable(policy) or empty-- in case someone changed the policy metatable

    local gc = mt.__gc or noop

    return gc(policy)
end

local function metatable(policy)
    local proxy = newproxy(true)
    local mt = getmetatable(proxy)

    mt.__index = policy
    mt.__tostring = __tostring
    mt.__gc = __gc
policy.proxy = proxy

    return mt
end

--- Initialize new policy
-- Returns a new policy that you can extend however you want.
-- @tparam string name Name of the new policy.
-- @tparam string version Version of the new policy. Default value is 0.0
-- @treturn policy New policy
function _M.new(name, version)
    local policy = {
        _NAME = name,
        _VERSION = version or '0.0',
    }

    local mt = metatable(policy)

    function policy.new()
        return setmetatable({}, mt)
    end

    for _, phase in _M.phases() do
        policy[phase] = noop
    end

    return setmetatable(policy, { __tostring = __tostring, __eq = __eq })
end

function _M.phases()
    return ipairs(PHASES)
end

return _M
