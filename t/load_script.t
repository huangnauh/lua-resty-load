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

=== TEST 1: load_script
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua '
            local rload = require "resty.load"
            rload.init()
            local skey = "script.abc"
            rload.set_code(skey, "ngx.say(\'hello world\')")
            rload.install_code(skey)
            local test = rload.load_script("script.abc")
            test()
        ';
    }
--- request
GET /t
--- response_body_like: 500 Internal Server Error
--- error_code: 500
--- error_log
attempt to index global 'ngx' (a nil value)


=== TEST 2: load_script env
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua '
            local rload = require "resty.load"
            rload.init()
            local skey = "script.abc"
            rload.set_code(skey, "ngx.say(\'hello world\')")
            rload.install_code(skey)
            local test = rload.load_script("script.abc", {env={ngx=ngx}})
            test()
        ';
    }
--- request
GET /t
--- response_body
hello world
--- no_error_log
[error]



=== TEST 3: load_script global
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua '
            local rload = require "resty.load"
            rload.init()
            local skey = "script.abc"
            rload.set_code(skey, "ngx.say(\'hello world\')")
            rload.install_code(skey)
            local test = rload.load_script("script.abc", {global=true})
            test()
        ';
    }
--- request
GET /t
--- response_body
hello world
--- no_error_log
[error]
