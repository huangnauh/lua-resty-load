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

=== TEST 1: get script version
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
            local version = rload.get_version(skey)
            ngx.say("code_name: ", version.name)
            ngx.say("code_md5: ", version.version)
        ';
    }
--- request
GET /t
--- response_body
hello world
code_name: script.abc
code_md5: 8ef7fe02783fada43ef65123095166f0
--- no_error_log
[error]


=== TEST 2: get module version
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
            local version = rload.get_version(skey)
            ngx.say("code_name: ", version.name)
            ngx.say("code_md5: ", version.version)
        ';
    }
--- request
GET /t
--- response_body
version: 0.01
code_name: modules.abc
code_md5: 7e55d7f4eec0b53ee9af18980f7d9082
--- no_error_log
[error]


=== TEST 3: get all version
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
            local version = rload.get_version()
            for _, value in ipairs(version.modules) do
                ngx.say("code_name: ", value.name)
                ngx.say("code_md5: ", value.version)
            end

        ';
    }
--- request
GET /t
--- response_body
version: 0.01
code_name: modules.abc
code_md5: 7e55d7f4eec0b53ee9af18980f7d9082
code_name: script.abc
code_md5: cdef2515c6916ef1415252e4715e87a6
--- no_error_log
[error]