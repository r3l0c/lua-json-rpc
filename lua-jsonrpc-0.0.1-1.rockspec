package = "lua-jsonrpc"
version = "0.0.1-1"
source = {
   url = "*** please add URL for source tarball, zip or repository here ***"
}
description = {
   summary = "A Lua 5.3 library for generating and processing JSON-RPC",
   detailed = "A Lua 5.3 library for generating and processing JSON-RPC",
   homepage = "*** please enter a project homepage ***",
   license = "BSD"
}
dependencies = {
  "lua >= 5.3",
  "luajson >=1.3.4",
  "lualogging >= 1.3.0"
}
build = {
   type = "builtin",
   modules = {
      ["json-rpc"] = "src/json-rpc.lua"
   }
}
