--!strict
local Connection = {}

local HttpService = game:GetService("HttpService")

local function get(port: number): string
    return HttpService:GetAsync(`http://localhost:{port}`)
end

local function post(port: number, path: string, data: string): string
    return HttpService:PostAsync(`http://localhost:{port}{path}`, data)
end

local function checkConnectionStatus(self: Connection)
    local connected, data = pcall(get, self._port)
    if not connected then
        if self.onDisconnect then self.onDisconnect() end
        self:Destroy()
        return
    end

    if self.onDataRecieved then self.onDataRecieved(data :: string) end
    self._thread = task.delay(1, checkConnectionStatus, self)
end

local function Send(self: Connection, path: string, JSON: string): (boolean, string)
    local success, response = pcall(post, self._port, path, JSON)
    return success :: boolean, response :: string
end

local function Destroy(self: Connection)
    coroutine.yield(self._thread)
    coroutine.close(self._thread)
    table.clear(self :: any)
end

type Connection = {
    _port: number,
    _thread: thread,

	onDisconnect: () -> ()?,
	onDataRecieved: (data: string) -> ()?,

	Send: typeof(Send),
    Destroy: typeof(Destroy),
}

function Connection.new(port: number): (Connection?, string?)
    local connected, data = pcall(get :: (number) -> (string), port)
	if not connected then return nil, nil end
	
    local self; self = {
        _port = port,

        Send = Send,
        Destroy = Destroy,
    } :: Connection
    self._thread = task.delay(1, checkConnectionStatus, self)
    
	return self, data ~= "null\n" and (data :: string) or nil
end

return Connection
