Name
====

lua-resty-load - Dynamically require lua files/scripts for the ngx_lua

Table of Contents
=================

* [Name](#name)
* [Status](#status)
* [Description](#description)
* [Synopsis](#synopsis)
* [Methods](#methods)
    * [init](#init)
    * [create_load_syncer](#create_load_syncer)
    * [set_code](#set_code)
    * [install_code](#install_code)
    * [load_script](#load_script)
    * [get_load_version](#get_load_version)
    * [get_version](#get_version)
* [Author](#author)
* [Copyright and License](#copyright-and-license)

Status
======

This library is already usable though still experimental.

The Lua API is still in flux and may change in the near future.

Description
===========

This Lua library to help OpenResty/ngx_lua users to dynamically load lua files/scripts

One caveat is that your dynamically loaded Lua code should not use the FFI API to define new C symbols or C types. 

Note that at least [ngx_lua v0.7.18](https://github.com/openresty/lua-nginx-module/tags) is required


Synopsis
========

```lua
    http {
        lua_package_path "/path/to/lua-resty-load/lib/?.lua;;";
        
        init_by_lua '
            local rload  = require "resty.load"
            rload.init()
            -- if you need code to be loaded in the beginning
            -- please provide the module with following interfaces:
            --
            -- 
            -- local load_init_module = require "load_init_module_name"
            -- local load_init = load_init_module:new()
            -- local keys = load_init:lkeys()
            -- 
            -- for _, key in ipairs(keys) do
            --     local code = load_init:lget(key)
            --     print("script/module name: ", key, ", code: ", code)
            -- end
            --
            --
            -- then just pass the name to rload.init:
            -- local rload  = require "resty.load"
            -- rload.init({module_name="load_init_module_name"})
        ';
        
        init_worker_by_lua '
            local rload  = require "resty.load"
            rload.create_load_syncer()
        ';
    }
    
    server {
        location /test {
            content_by_lua '
                local rload = require "resty.load"
                rload.set_code("script.abc", "local test = require \'modules.abc\' ngx.say(\'version: \',test.version)")
                rload.set_code("modules.abc", "local _M = {version = 0.01} return _M")
                rload.install_code()
                local test = require "script.abc"
                test()
                -- dynamic load
                rload.set_code("script.abc", "ngx.say(\'hello world\')")
                rload.install_code("script.abc")
                local test = require "script.abc"
                test()
            ';
        }
    }
```

[Back to TOC](#table-of-contents)

Methods
=======

[Back to TOC](#table-of-contents)

init
-------
`syntax: ok, err = load.init(options_config?)`

`context: init_by_lua*`

Initialize the library. In case of failures, returns `nil` and a string describing the error.

If you need to load any code in the beginning, you can do so by defining a custom load_init module. 

An optional Lua table `options_config` can be specified as the only argument to this method to specify load_init module config:

* `module_name`

    Your load_init module must implement the new(), lkeys() and lget(key) methods, along with the optional method lversion().
    
    * [new](#load_init_modulenew)
    * [lkeys](#load_init_modulelkeys)
    * [lget](#load_init_modulelget)
    * [lversion](#load_init_modulelversion)
    
load_init_module:new
---
Creates a load_init object. In case of failures, returns nil and a string describing the error.

* `options_config`

    Just the parameter in `load.init`
    
load_init_module:lkeys
---
**syntax:** *keys, err = load_init_module:lkeys()*

Retrieving a lua array that include all the script/module names. In case of failures, returns nil and a string describing the error.

load_init_module:lget
---
**syntax:** *code, err = load_init_module:lget(key)*

Retrieving the code for the script/module name `key`. In case of failures, returns nil and a string describing the error.

load_init_module:lversion
---
**syntax:** *version, err = load_init_module:lversion()*

Retrieving the version for current codes. This is optional for fallback and version checking. `version` no longer than 32 characters.

In case of failures, returns nil and a string describing the error.

[Back to TOC](#table-of-contents)

create_load_syncer
-------

`syntax: ok, err = rload.create_load_syncer()`

`context: init_worker_by_lua*`

Creates an Nginx timer to make dynamical loading work. In case of failures, returns nil and a string describing the error.

[Back to TOC](#table-of-contents)

set_code
-------
`syntax: ok, err = rload.set_code(name, code)`

Set the code to the module `name`, but it don't take effect yet. In case of failures, returns nil and a string describing the error.

[Back to TOC](#table-of-contents)

install_code
-------
`syntax: ok, err = rload.install_code(name?)`

By default, all the set codes will be installed. It will take effect after the load_syncer timer be called.

When the `name` argument is given, only the module `name` will be installed.

In case of failures, returns nil and a string describing the error.

[Back to TOC](#table-of-contents)

load_script
-------
`syntax: fun, err = rload.load_script(name, options_table?)`

Load script by the name `name`, this method returns the (successfully) script function `fun` for later use.

An optional Lua table can be specified as the last argument to this method to specify the environment for the script:

* `env`

    If this option is set to a table, then a function environment will be set.
    
* `global`
    
    If this option is set to `true`, then the global environment will be set.

In case of failures, returns nil and a string describing the error.

[Back to TOC](#table-of-contents)

get_load_version
-------
`syntax: commit_version, err = rload.get_load_version()`

This method returns the value if `load_init_module` has the `lversion` method or "0" by default.

In case of failures, returns nil and a string describing the error.

[Back to TOC](#table-of-contents)

get_version
-------
`syntax: ok, err = rload.get_version()`

Returns the resulting json string, for example,

```
{
  "global_version": 4,
  "commit_version": "79630b",
  "modules": [
    {
      "time": "2016-11-23 17:38:11",
      "version": "aed4a968ef14f8db732e3602c34dc37a",
      "name": "modules.abc"
    },
    {
      "time": "2016-11-23 17:38:11",
      "version": "7a170b7731543b56722101c4167965b3",
      "name": "script.test"
    }
  ]
}
```

* `global_version`
    
    Returns how many times the lua library loads script/module since nginx start/reload
    
* `commit_version`

    Returns the exactly the same version as [get_load_version](#get_version).
    
* `version`

    Returns the MD5 hash of the code.
    
In case of failures, returns nil and a string describing the error.

[Back to TOC](#table-of-contents)


Author
======

UPYUN Inc.

[Back to TOC](#table-of-contents)

Copyright and License
=====================

This module is licensed under the BSD license.

Copyright (C) 2016, by UPYUN Inc.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

[Back to TOC](#table-of-contents)
