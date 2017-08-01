# vim:set ft= ts=4 sw=4 et:

use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(2);

plan tests => repeat_each() * (3 * blocks());

my $pwd = cwd();

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;;";
    lua_package_cpath "/usr/local/openresty/lualib/?.so;;";
    lua_shared_dict load 10m;
};

no_long_string();
#no_diff();

run_tests();

__DATA__

=== TEST 1: load script
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua '
            local rload = require "resty.load"
            rload.init()
            local skey = "script.abc"
            rload.set_code(skey, "ngx.say(\'hello world\')")
            rload.install_code(skey)
            local test = require "script.abc"
            test()
        ';
    }
--- request
GET /t
--- response_body
hello world
--- no_error_log
[error]


=== TEST 2: load module
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua '
            local rload = require "resty.load"
            rload.init()
            local skey = "modules.abc"
            rload.set_code(skey, "local _M = {version = 0.01} return _M")
            rload.install_code(skey)
            local test = require "modules.abc"
            ngx.say("version: ", test.version)
        ';
    }
--- request
GET /t
--- response_body
version: 0.01
--- no_error_log
[error]


=== TEST 4: dependent
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua '
            local rload = require "resty.load"
            rload.init()
            rload.set_code("script.abc", "local test = require \'modules.abc\' ngx.say(\'version: \',test.version)")
            rload.set_code("modules.abc", "local _M = {version = 0.01} return _M")
            rload.install_code()
            local test = require "script.abc"
            test()
        ';
    }
--- request
GET /t
--- response_body
version: 0.01
--- no_error_log
[error]


=== TEST 5: dependent before use
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua '
            local rload = require "resty.load"
            rload.init()
            rload.set_code("script.abc", "local test = require \'modules.abc\' ngx.say(\'version: \',test.version)")
            rload.install_code("script.abc")
            rload.set_code("modules.abc", "local _M = {version = 0.01} return _M")
            rload.install_code("modules.abc")
            local test = require "script.abc"
            test()
        ';
    }
--- request
GET /t
--- response_body
version: 0.01
--- no_error_log
[error]


=== TEST 6: dependent after use
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua '
            local rload = require "resty.load"
            rload.init()
            rload.set_code("script.abc", "local test = require \'modules.abc\' ngx.say(\'version: \',test.version)")
            rload.install_code("script.abc")
            rload.set_code("modules.abc", "local _M = {version = 0.01} return _M")
            local test = require "script.abc"
            test()
            rload.install_code("modules.abc")
        ';
    }
--- request
GET /t
--- response_body_like: 500 Internal Server Error
--- error_code: 500
--- error_log
module 'modules.abc' not found
