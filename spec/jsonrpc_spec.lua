--
--   jsonrpc_spec.lua:
--     Unit tests for the json-rpc implementation
-- Author: Nikolaos Tsiogkas, <nikolaos.tsiogkas@kuleuven.be>
-- KU Leuven, Belgium
--------------------------------------------------
--
-- Requirements: 
--------------------------------------------------
local jsonrpc = require("json-rpc")
local logging = require("logging")

-- We don't care about logging here
jsonrpc.logger:setLevel(logging.FATAL)

describe("Test error object", function()
  it("Get existing error object", function()
    assert.is_not_nil(jsonrpc.get_error_object("parse_error"))
  end)

  it("Get non existing error object", function()
    assert.is_nil(jsonrpc.get_error_object("foo"))
  end)

  it("Add invalid error object", function()
    local error_object = { err_code=-32002 }
    assert.is_nil(jsonrpc.add_error_object("invalid_error", error_object))
    error_object = { err_message="Just message" }
    assert.is_nil(jsonrpc.add_error_object("invalid_error", error_object))
    assert.is_nil(jsonrpc.get_error_object("invalid_error"))
  end)

  it("Overwrite std error object", function()
    local error_name = "parse_error"
    local error_object = { err_code=-1, err_message="An error message" }
    local ret = jsonrpc.add_error_object(error_name, error_object)
    assert.is_nil(ret)
  end)

  it("Overwrite user defined error object", function()
    local error_name = "an_error"
    local error_object = { err_code=-32005, err_message="An error message" }
    local ret = jsonrpc.add_error_object(error_name, error_object)
    assert.are.same(error_object, ret)
    assert.are.same(error_object, jsonrpc.get_error_object(error_name))
    error_object = { err_code=-32006, err_message="An error message" }
    ret = jsonrpc.add_error_object(error_name, error_object)
    assert.are.same(error_object, ret)
    assert.are.same(error_object, jsonrpc.get_error_object(error_name))
    jsonrpc.remove_error_object("an_error")
  end)

  it("Remove user error object", function()
    local error_name = "an_error"
    local error_object = { err_code=-32005, err_message="An error message" }
    local ret = jsonrpc.add_error_object(error_name, error_object)
    assert.are.same(error_object, jsonrpc.get_error_object(error_name))
    ret = jsonrpc.remove_error_object(error_name)
    assert.is_true(ret)
    assert.is_nil(jsonrpc.get_error_object(error_name))
  end)

  it("Remove std error object", function()
    local error_name = "parse_error"
    local ret = jsonrpc.remove_error_object(error_name)
    assert.is_false(ret)
    ret = jsonrpc.get_error_object(error_name)
    assert.are.equal(-32700, ret.err_code)
  end)

  it("Duplicate error code", function()
    local error_name = "Duplicate"
    local error_object = { err_code=-32700, err_message="An error message" }
    assert.is_nil(jsonrpc.add_error_object(error_name, error_object))
    assert.is_nil(jsonrpc.get_error_object(error_name))
    local err_str = "Parse error"
    error_name = "parse_error"
    assert.are.equal(err_str, jsonrpc.get_error_object(error_name).err_message)
  end)

  it("Add valid error object", function()
    local error_object = { err_code=-32001, err_message="An error message" }
    local ret = jsonrpc.add_error_object("new_error", error_object)
    assert.are.same(error_object, ret)
  end)
end)

describe("Test RPC encoding", function()
  it("Call no method", function()
    local enc = jsonrpc.encode_rpc(jsonrpc.notification)
    assert.is_nil(enc)
  end)

  it("Call no function", function()
    local enc = jsonrpc.encode_rpc(notification, "method")
    assert.is_nil(enc)
  end)
end)

describe("Test notification", function()
  it("Test notification no method", function()
    local ret = jsonrpc.notification()
    assert.is_nil(ret)
  end)
  
  it("Test notification no params", function()
    local json = require("json")
    local method_name = "a_method"
    local ret = jsonrpc.notification(method_name)
    assert.are.equal(ret.method, method_name)
    assert.are.equal(ret.jsonrpc, 2.0)
  end)

  it("Test notification single param", function()
    local method_name = "a_method"
    local single_param = 42.0
    local ret = jsonrpc.notification(method_name, single_param)
    assert.are.equal(ret.params, single_param)
  end)

  it("Test notification positional params", function()
    local method_name = "a_method"
    local array_params = {1, 2}
    local ret = jsonrpc.notification(method_name, array_params)
    assert.are.same(ret.params, array_params)
  end)

  it("Test notification named poarams", function()
    local method_name = "a_method"
    local object_param = { param_1=1, param_2=2 }
    local ret = jsonrpc.notification(method_name, object_param)
    assert.are.same(ret.params, object_param)
  end)
end)

describe("Test request", function()
  it("Test request no method", function()
    local ret = jsonrpc.request()
    assert.is_nil(ret)
  end)

  it("Test request no id", function()
    local method_name = "a_method"
    local next_id = jsonrpc.get_next_free_id()
    local ret = jsonrpc.request(method_name)
    assert.are.equal(method_name, ret.method)
    assert.are.equal(next_id, ret.id)
    assert.are_not.equal(next_id, jsonrpc.get_next_free_id())
  end)

  it("Test full request", function()
    local method_name = "a_method"
    local req_id = 42
    local next_id = jsonrpc.get_next_free_id()
    local ret = jsonrpc.request(method_name, nil, req_id)
    assert.are.equal(ret.id, req_id)
    assert.are.equal(next_id, jsonrpc.get_next_free_id())
  end)
end)

describe("Test server_response", function()
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
      return false, nil, "Must provide two numbers as {minutend, subrtahend}"..
                         " or {minutend=x, subtrahend=y}"
    end

    return true, minutend - subtrahend
  end

  local function sum(params)
    sum = 0
    for i, v in pairs(params) do
      sum = sum + v
    end
    return true, sum
  end
  
  local function notify_sum(params)
    return true, nil
  end

  local function notify_hello(params)
    return true, nil
  end

  local function get_data(params)
    return true, {"hello", 5}
  end

  local function multiple_ret_values(params)
    return true, "first", "second", "third"
  end

  local methods = {
    subtract = subtract,
    sum = sum,
    notify_sum = notify_sum,
    notify_hello = notify_hello,
    get_data = get_data,
    multiple_ret_values = multiple_ret_values,
  }
  
  it("Test server parse error", function()
    local jsonstr = '{"jsonrpc": "2.0", "method": "subtract", "id": 1,'..
                    '"params":[1,2}'
    local ret = jsonrpc.server_response(methods, jsonstr)
    local err_code = -32700
    assert.are.equal(ret.error.code, err_code)
    assert.are.equal(json.util.null(), ret.id)
  end)

  it("Test server method not found", function()
    local jsonstr = '{"jsonrpc": "2.0", "method": "substract", "id": 1,'..
                    '"params":[1,2]}'
    local ret = jsonrpc.server_response(methods, jsonstr)
    local err_code = -32601
    assert.are.equal(err_code, ret.error.code)
    assert.are.equal(1, ret.id)
  end)

  it("Test server invalid params null", function()
    local jsonstr = '{"jsonrpc": "2.0", "method": "subtract", "id": 1,'..
                    '"params":null}'
    local ret = jsonrpc.server_response(methods, jsonstr)
    assert.are.equal(-32602, ret.error.code)
  end)

  it("Test server invalid params non existing", function()
    local jsonstr = '{"jsonrpc": "2.0", "method": "subtract", "id": 1,}'
    local ret = jsonrpc.server_response(methods, jsonstr)
    assert.are.equal(-32602, ret.error.code)
  end)

  it("Test server invalid params wrong number", function()
    local jsonstr = '{"jsonrpc": "2.0", "method": "subtract", "id": 1,'..
                    '"params":1}'
    local ret = jsonrpc.server_response(methods, jsonstr)
    assert.are.equal(-32602, ret.error.code)
  end)

  it("Test server invalid params wrong name", function()
    local jsonstr = '{"jsonrpc": "2.0", "method": "subtract", "id": 1,'..
                    '"params": {"minutend": 1, "substrahend": 2}}'
    local ret = jsonrpc.server_response(methods, jsonstr)
    assert.are.equal(-32602, ret.error.code)
  end)

  it("Test server invalid params wrong number named", function()
    local jsonstr = '{"jsonrpc": "2.0", "method": "subtract", "id": 1,'..
                    '"params": {"minutend": 1}}'
    local ret = jsonrpc.server_response(methods, jsonstr)
    assert.are.equal(-32602, ret.error.code)
  end)

  it("Test server invalid request method name", function()
    local jsonstr = '{"jsonrpc": "2.0", "method": 1, "id": 1, "params":[1,2]}'
    local ret = jsonrpc.server_response(methods, jsonstr)
    assert.are.equal(-32600, ret.error.code)
  end)

  it("Test server custom user error", function()
    pending("ToDo")
  end)

  it("Test server notification", function()
    local jsonstr = '{"jsonrpc": "2.0", "method": "subtract", "params":[1,2]}'
    local ret = jsonrpc.server_response(methods, jsonstr)
    assert.is_true(ret)
  end)

  it("Test server notification named", function()
    local jsonstr = '{"jsonrpc": "2.0", "method": "subtract",'..
                    '"params": {"minutend": 1, "subtrahend": 2}}'
    local ret = jsonrpc.server_response(methods, jsonstr)
    assert.is_true(ret)
  end)

  it("Test server correct response positional 1", function()
    local jsonstr = '{"jsonrpc": "2.0", "method": "subtract", "id": 1,'..
                    '"params": [42, 23]}'
    local ret = jsonrpc.server_response(methods, jsonstr)
    assert.are.equal(1, ret.id)
    assert.are.equal(19, ret.result)
  end)

  it("Test server correct response positional 2", function()
    local jsonstr = '{"jsonrpc": "2.0", "method": "subtract", "id": 1,'..
                    '"params": [23, 42]}'
    local ret = jsonrpc.server_response(methods, jsonstr)
    assert.are.equal(1, ret.id)
    assert.are.equal(-19, ret.result)
  end)

  it("Test server correct response named 1", function()
    local jsonstr = '{"jsonrpc": "2.0", "method": "subtract", "id": 1,'..
                    '"params": {"minutend": 42, "subtrahend": 23}}'
    local ret = jsonrpc.server_response(methods, jsonstr)
    assert.are.equal(1, ret.id)
    assert.are.equal(19, ret.result)
  end)

  it("Test server correct response named 2", function()
    local jsonstr = '{"jsonrpc": "2.0", "method": "subtract", "id": 1,'..
                    '"params": {"subtrahend": 23, "minutend": 42}}'
    local ret = jsonrpc.server_response(methods, jsonstr)
    assert.are.equal(1, ret.id)
    assert.are.equal(19, ret.result)
  end)

  it("Test server procedure with multiple ret values", function()
    local jsonstr = jsonrpc.encode_rpc(jsonrpc.request, "multiple_ret_values")
    local ret = jsonrpc.server_response(methods, jsonstr)
    assert.are.equal("first", ret.result[1])
    assert.are.equal("second", ret.result[2])
    assert.are.equal("third", ret.result[3])
  end)

  it("Test server batch requests empty array", function()
    local jsonstr = '[]'
    local ret = jsonrpc.server_response(methods, jsonstr)
    assert.are.equal(-32600, ret.error.code)
  end)

  it("Test server batch requests invalid batch 1", function()
    local jsonstr = '[1]'
    local ret = jsonrpc.server_response(methods, jsonstr)
    assert.are.equal(-32600, ret[1].error.code)
  end)

  it("Test server batch requests invalid batch many", function()
    local jsonstr = '[1,2,3]'
    local ret = jsonrpc.server_response(methods, jsonstr)
    assert.are.equal(-32600, ret[1].error.code)
    assert.are.equal(-32600, ret[2].error.code)
    assert.are.equal(-32600, ret[3].error.code)
  end)

  it("Test server batch requests", function()
    local jsonstr = '['..
                    '{"jsonrpc": "2.0", "method": "sum", "params": [1,2,4],'..
                    '"id": "1"},'..
                    '{"jsonrpc": "2.0", "method": "notify_hello",'..
                    '"params": [7]},'..
                    '{"jsonrpc": "2.0", "method": "subtract",'..
                    '"params": [42,23], "id": "2"},'..
                    '{"foo": "boo"},'..
                    '{"jsonrpc": "2.0", "method": "foo.get", "params": '..
                    '{"name": "myself"}, "id": "5"},'..
                    '{"jsonrpc": "2.0", "method": "get_data", "id": "9"}]'
    local ret = jsonrpc.server_response(methods, jsonstr)
    assert.are.equal(5, #ret)
    assert.are.equal('1', ret[1].id)
    assert.are.equal(7, ret[1].result)
    assert.are.equal('2', ret[2].id)
    assert.are.equal(19, ret[2].result)
    assert.are.equal(json.util.null(), ret[3].id)
    assert.are.equal(-32600, ret[3].error.code)
    assert.are.equal('5', ret[4].id)
    assert.are.equal(-32601, ret[4].error.code)
    assert.are.equal('9', ret[5].id)
    assert.are.same({"hello", 5}, ret[5].result)
  end)

  it("Test server batch all notifications", function()
    local jsonstr = '['..
                    '{"jsonrpc": "2.0", "method": "notify_sum",'..
                    '"params": [1,2,4]},'..
                    '{"jsonrpc": "2.0", "method": "notify_hello",'..
                    '"params": [7]}]'
    local ret = jsonrpc.server_response(methods, jsonstr)
    assert.are.equal(0, #ret)
    assert.are.same({}, ret)
  end)
end)

