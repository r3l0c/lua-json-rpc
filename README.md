# Lua-JSON-RPC

### A Lua 5.3 library for generating and processing JSON-RPC

## Setup

To setup and use the library and its dependencies `luarocks` is used. To install
it in Debian based distributions you can use:
```bash
$ sudo apt install luarocks
```
or you can get the latest version from the [luarocks repository][1].

### Dependencies

The library depends in the following packages:

- luajson
- lualogging

They should be automatically installed using luarocks.


### Install

To install the library simply use:

```bash
$ luarocks make --local
```

## Usage

Include the module by:

```lua
local jsonrpc = require('json-rpc')
```

There are multiple ways to encode RPCs. Helper functions `notification` and
`request` can be used to generate Lua tables that can be encoded to JSON strings
using any library. For example:
```lua
local notification = jsonrpc.notification("a_method", {1, 2})
local request = jsonrpc.request("a_method", {param1=1, param2=2}, "req_id_1")
```
When generating a request the ID part can be omitted and the library will
automatically generate an integer ID for the request:
```lua
local request = jsonrpc.request("a_method", 42)
```
To directly encode a RPC request to a string the `encode_rpc` function can be
used.
```lua
local notif_str = jsonrpc.encode_rpc(jsonrpc.notification, "a_method", {1,2})
```

To respond to RPCs the function `server_response` is provided. It takes as
arguments a table containing the provided methods and a request (either a string.
or a table). It returns a table containing the response that can be encoded using
any JSON library. For example:
```lua
local function subtract(params)
  local minutend
  local subtrahend
  
  if 0 == #params then
    minutend = params.minutend
    subtrahend = params.subtrahend
  else
    minutend = params[1]
    subtrahend = params[2]
  end
  
  if (nil == minutend) or (nil == subtrahend) then
    return false, "invalid_params, "Must provide two numbers as {minutend,".."
                  "subrtahend} or {minutend=x, subtrahend=y}"

  end

  return true, minutend - subtrahend
end

methods = {
  subtract = subtract
}

local res = jsonrpc.server_response(methods, req)
```
It should be noted that the functions used as methods have a specific signature.
They accept a single parameter as input and return a boolean, the result or an
error name and an optional data section to be used for error reporting.
The boolean is used to denote the success or failure of the call and provide the
respective error.

Users can add, overwrite or remove user defined errors using the helper functions
`add_error_object` and `remove_error_object` as follows:
```lua
local error_object = {err_code=-32001, err_message="an error message"}
local error_name = "an_error"
local ret = jsonrpc.add_error_object(error_name, error_object)
```
and
```lua
local ret = jsonrpc.remove_error_object("an_error")
```
Using these methods a user cannot change the standard defined error objects.

For extra examples one can look at the unit tests defined in [jsonrpc_spec.lua][2].

## Testing
To run the tests [busted][3] is used. It can be installed as follows:
```bash
$ luarocks install busted --local
```
Then in the main folder of the repository use the following command:
```bash
$ busted
```

[1]: https://github.com/luarocks/luarocks/wiki/Download
[2]: ./spec/jsonrpc_spec.lua
[3]: https://olivinelabs.com/busted/
