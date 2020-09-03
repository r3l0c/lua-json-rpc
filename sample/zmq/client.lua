--- A dummy JSON-RPC client using a ZeroMQ socket to communicate with the server


local log_console = require"logging.console"
local logger      = log_console()

local jsonrpc = require("json-rpc")

local zmq   = require("lzmq")
local timer = require("lzmq.timer")

-- Establish connection with the RPC server

local server_url = "tcp://localhost:6543"
print("Attempting to connect to : " .. server_url)

local context = zmq.context()
local requester, err = context:socket{zmq.REQ,
  connect = server_url
}
zmq.assert(requester, err)


-- Request the server to invoke the method 'try1'

for request_nbr = 0,2 do
    local request = jsonrpc.encode_rpc(jsonrpc.request, "try1")

    logger:info("Sending request: " .. request)
    requester:send(request)

    local response = requester:recv()
    logger:info("Received response: " .. response )

    timer.sleep(500) -- in ms
end

-- Request the server to invoke the method 'try2', with some arguments

for request_nbr = 0,2 do
    local request = jsonrpc.encode_rpc(jsonrpc.request, "try2", {arg1=1, arg2=2})

    logger:info("Sending request: " .. request)
    requester:send(request)

    local response = requester:recv()
    logger:info("Received response: " .. response )

    timer.sleep(500) -- in ms
end

-- Now request a non-available method

local request = jsonrpc.encode_rpc(jsonrpc.request, "not-available", {"foo"})
logger:info("Sending request: " .. request)
requester:send(request)
local response = requester:recv()
logger:info("Received response: " .. response )

requester:close(0)
context:shutdown(0)
