# vim:set ft= ts=4 sw=4 et:

use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

# repeat_each(2);

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

=== TEST 1: dynamic load need create_load_syncer
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua '
            local rload = require "resty.load"
            rload.init()
            rload.create_load_syncer()
            local skey = "script.abc"
            rload.set_code(skey, "ngx.say(\'hello world\')")
            rload.install_code(skey)
            local x = rload.load_script("script.abc", {env={ngx=ngx}})
            x()
            rload.set_code(skey, "ngx.say(\'hello world2\')")
            rload.install_code(skey)
            ngx.sleep(2)
            local y = rload.load_script("script.abc", {env={ngx=ngx}})
            y()
        ';
    }
--- request
GET /t
--- response_body
hello world
hello world2
--- no_error_log
[error]


=== TEST 2: otherwise dynamic load not work
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua '
            local rload = require "resty.load"
            rload.init()
            local skey = "script.abc"
            rload.set_code(skey, "ngx.say(\'hello world\')")
            rload.install_code(skey)
            local x = rload.load_script("script.abc", {env={ngx=ngx}})
            x()
            rload.set_code(skey, "ngx.say(\'hello world2\')")
            rload.install_code(skey)
            ngx.sleep(2)
            local y = rload.load_script("script.abc", {env={ngx=ngx}})
            y()
        ';
    }
--- request
GET /t
--- response_body
hello world
hello world
--- no_error_log
[error]