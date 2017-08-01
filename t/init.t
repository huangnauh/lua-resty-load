# vim:set ft= ts=4 sw=4 et:

use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(2);

plan tests => repeat_each() * (3 * blocks());

my $pwd = cwd();

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;\$prefix/html/?.lua;;";
    lua_package_cpath "/usr/local/openresty/lualib/?.so;;";
    lua_shared_dict load 1m;
};

no_long_string();
#no_diff();

run_tests();

__DATA__

=== TEST 1: init config
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua '
            local rload = require "resty.load"
            local config = {load_init={module_name="foo"}}
            rload.init(config)
            local test = require "modules.abc"
            ngx.say("version: ", test.version)
        ';
    }
--- user_files
>>> foo.lua
local _M = {}
local mt = { __index = _M }
function _M.new(self, config)
    return setmetatable(config, mt)
end

function _M.lget(self, key)
    if key == "modules.abc" then
        return "local _M = {version = 0.01} return _M"
    else
       return nil, "no code here"
    end
end

function _M.lkeys(self)
    return {"modules.abc"}
end

function _M.lversion(self)
    return "xxxx"
end

return _M

--- request
GET /t
--- response_body
version: 0.01
--- no_error_log
[error]
