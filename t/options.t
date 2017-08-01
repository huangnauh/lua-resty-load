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

=== TEST 1: set commit version
--- http_config eval: $::HttpConfig
--- config
    location = /t {
        content_by_lua '
            local rload = require "resty.load"
            rload.init()

            local skey = "script.abc"
            rload.set_code(skey, "ngx.say(\'hello world\')", "xxxx")
            rload.install_code(skey)
            local test = require "script.abc"
            test()
            local commit_version = rload.get_load_version()
            ngx.say("commit_version: ", commit_version)

            local skey = "modules.abc"
            rload.set_code(skey, "local _M = {version = 0.01} return _M", "yyyy")
            rload.install_code(skey)
            local test = require "modules.abc"
            ngx.say("version: ", test.version)
            local commit_version = rload.get_load_version()
            ngx.say("commit_version: ", commit_version)
        ';
    }
--- request
GET /t
--- response_body
hello world
commit_version: xxxx
version: 0.01
commit_version: yyyy
--- no_error_log
[error]
