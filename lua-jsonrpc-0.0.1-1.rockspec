package = "lua-jsonrpc"
version = "0.0.1-1"
source = {
   url = "https://github.com/r3l0c/lua-json-rpc.git"
}
description = {
   summary = "A Lua>=5.2 library for generating and processing JSON-RPC",
   detailed = "A Lua>=5.2 library for generating and processing JSON-RPC",
   homepage = "*** please enter a project homepage ***",
   license = "BSD"
}
dependencies = {
  "lua >= 5.2",
  "luajson >=1.3.4",
  "lualogging >= 1.3.0"
}
build = {
   type = "builtin",
   modules = {
      ["json-rpc"] = "src/json-rpc.lua"
   }
}
