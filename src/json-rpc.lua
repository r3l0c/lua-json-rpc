--
--   json-rpc:
--     simple rpc implementation and helpers
-- Author: Nikolaos Tsiogkas, <nikolaos.tsiogkas@kuleuven.be>
-- Author: Enea Scioni, <enea.scioni@kuleuven.be>
-- KU Leuven, Belgium
--------------------------------------------------
--
-- Requirements: luajson, lualogging
--------------------------------------------------
local json = require('json')

-- Logging
local logging = require('logging')
local logger = logging.new(function(self, level, message)
                             print(level, message)
                             return true
                           end)

local id_gen = {free_id = 0}

-- Standard error objects which can be extended with user defined error objects
-- having error codes from -32000 to -32099. Helper functions add_error_object
-- and get_error_object can be used to add and retrieve error objects.
local error_objects = {
  parse_error       = { err_code=-32700, err_message="Parse error"},
  invalid_request   = { err_code=-32600, err_message="Invalid request"},
  method_not_found  = { err_code=-32601, err_message="Method not found"},
  invalid_params    = { err_code=-32602, err_message="Invalid params"},
  internal_error    = { err_code=-32603, err_message="Internal error"},
  server_error      = { err_code=-32000, err_message="Server error"},
}

local function is_std_error(error_name)
  return ((error_name == 'parse_error') or
          (error_name == 'invalid_request') or
          (error_name == 'method_not_found') or
          (error_name == 'internal_error') or
          (error_name == 'server_error'))
end

-- Get an error object based on its' name.
-- @param error_name The name of the error.
-- @return The error object if it exits or nil if it doesn't exist.
local function get_error_object(error_name)
  return error_objects[error_name]
end

-- Add an error object. If and error code outside of the standard allowed is 
-- given a new object is not created.
-- If an object with the same name exists it is overwritten.
-- If an object with the same error code exists a new object is not created.
-- @param error_name The name of the error to be added.
-- @param error_object The object of the error containing an error code
-- (err_code) and an error message (err_message)
-- @return An error object on successful creation or overwrite. Nil otherwise.
local function add_error_object(error_name, error_object)
  -- If the error object is not complete
  if (not error_object.err_code) or (not error_object.err_message) then
    logger:error("error_code and error_message are required in an error_object")
    return nil
  end

  if is_std_error(error_name) then
    logger:error("Errors defined in the standard cannot be changed")
    return nil
  end

  -- If the error code is not according to standard just issue a warning and
  -- continue normally.
  if (error_object.err_code > -32000) or (error_object.err_code < -32099) then
    logger:error("User defined error codes should be between -32000 and -32099.")
    return nil
  end

  -- If an object with than name already exists, overwrite it.
  if error_objects[error_name] then
    logger:warn("Error object with name "..error_name.." already exists."..
                "Overwritting...")
    error_objects[error_name] = error_object
    return error_objects[error_name]
  end

  -- If an object with the specified error code exists fail and return nil.
  for k, v in pairs(error_objects) do
    if v.err_code == error_object.err_code then
      logger:error("Error code "..tostring(error_object.err_code)..
                   " is already assigned to "..k)
      return nil
    end
  end

  error_objects[error_name] = error_object
  return error_objects[error_name]
end

local function remove_error_object(error_name)
  if is_std_error(error_name) then
    return false
  end
  error_objects[error_name] = nil
  return true
end

local function encode_rpc(func, method, params, id)
  if nil == func then
    logger:error("Function cannot be found")
    return nil
  end
  local obj = func(method, params, id)
  if nil == obj then
    return nil
  end
  return json.encode(obj)
end

local function notification(method, params)
  if nil == method then
    logger:error("A method in an RPC cannot be empty")
    return nil
  end
  local req = {}
  req['jsonrpc'] = 2.0
  req['method'] = method
  req['params'] = params
  return req
end

local function request(method, params, id)
  local req = notification(method, params)
  if nil == req then
    return nil
  end
  req['id'] = id or id_gen.free_id
  if req['id'] == id_gen.free_id then
    id_gen.free_id = req['id'] + 1
  end
  return req
end

local function response(req, results)
  local res = {}
  res['jsonrpc'] = req['jsonrpc']
  res['id'] = req['id']
  res['result'] = results
  return res
end

local function response_error(req, error_name, data)
  local res = {}
  local error_object = get_error_object(error_name) or
                       get_error_object('internal_error')
  res['error'] = {
    code = error_object.err_code,
    message = error_object.err_message,
  }

  res['data'] = data

  if (error_object.err_code == -32700) or (error_object.err_code == -32600) then
    res['id'] = json.util.null()
    res['jsonrpc'] = 2.0
  else
    res['id'] = req['id']
    res['jsonrpc'] = req['jsonrpc']
  end
  return res
end

local function handle_request(methods, req)
  if type(req) ~= 'table' then
    return response_error(req, 'invalid_request', req)
  end
  if type(req['method']) ~= 'string' then
    return response_error(req, 'invalid_request', req)
  end

  local fnc = methods[req['method']]
  -- Method not found
  if type(fnc) ~= 'function' then
    return response_error(req, 'method_not_found')
  end

  local params = req['params']
  -- the JSON lib we are using uses a special value to encode the JSON null...
  if (params==json.util.null) or (params==nil) then
    params = {}
  end

  -- According to the Lua reference, if the first return value of `pcall` is
  -- true (success), then all the following return values are those of the
  -- invoked function.
  -- According to our (??) specs, any remote procedure must also return a
  -- success flag, and then the actual return values (or error data).
  -- Therefore:
  --   `ret[1]` tells whether `pcall` was successful
  --   `ret[2]` tells whether the executed function was successful

  local ret = {pcall(fnc, params)}

  if ret[1] == false then
    logger:error("In pcall(): " .. ret[2])
    return response_error(req, 'internal_error', ret[2])
  end

  if ret[2] == false then
    -- the method was invoked correctly, but itself returned non-success
    local error_name = ret[3]
    if nil == error_name then
      return response_error(req, 'invalid_params', ret[4])
    else
      return response_error(req, error_name, ret[4])
    end
  end

  -- Notification only
  if not req['id']  then
    return true 
  end


  local results = nil
  if #ret==3 then
    -- the method had a single, actual return value
    results = ret[3]
  else
    results = {}
    for i = 3,#ret do
      results[i-2] = ret[i]
    end
  end
  return response(req, results)
end

local function server_response(methods, request)
  local req = request
  if type(request) == 'string' then
    status, req = pcall(json.decode, request)
    if status == false then
      return response_error(req, 'parse_error', req)
    end
  end

  if (#req == 0) and (req.jsonrpc ~= nil) then
    return handle_request(methods, req)
  elseif #req == 0 then
    return response_error(req, 'invalid_request', req)
  else
    res = {}
    for i, r in pairs(req) do
      local lres = handle_request(methods, r)
      if type(lres) == 'table' then
        table.insert(res, lres)
      end
    end
    return res
  end
end

local function get_next_free_id()
  return id_gen.free_id
end

local M = {}

M.logger = logger
M.get_error_object = get_error_object
M.add_error_object = add_error_object
M.remove_error_object = remove_error_object
M.encode_rpc = encode_rpc
M.notification = notification
M.request = request
M.get_next_free_id = get_next_free_id
M.server_response = server_response

return M
