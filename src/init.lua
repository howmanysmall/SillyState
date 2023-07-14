--!optimize 2
--!strict
local EqualObjects = require(script.EqualObjects)
local Locker = require(script.Parent.Locker)
local Signal = require(script.Parent.Signal)
local TaskQueue = require(script.Parent.TaskQueue)
local t = require(script.Parent.t)

--[=[
	The most simple state management library for Roblox.
	@class SillyState
]=]
local SillyState = {}
SillyState.ClassName = "SillyState"
SillyState.__index = SillyState

local ConstructorTuple = t.tuple(t.table, t.optional(t.callback))

local function Constructor<T>(Defaults: T, ValidationFunction: nil | (Value: T) -> (boolean, string?))
	assert(ConstructorTuple(Defaults, ValidationFunction))
	assert(type(Defaults) == "table", "")

	local self = setmetatable({}, SillyState)

	self.Changed = Signal.new() :: Signal.Signal<T, string>
	self.State = Defaults
	self.TaskQueue = TaskQueue.new(function(KeyChanges: {string})
		local LastKeyChange = KeyChanges[#KeyChanges]
		self.Changed:Fire(self.State, LastKeyChange)
	end)

	return self
end

--[=[
	Creates a new [SillyState] object.
	@param Defaults T -- The default state. This must be a table.
	@param ValidationFunction? (Value: T) -> (boolean, string?) -- A `t`-like validation function. Used in `assert`.
	@return SillyState<T>
]=]
function SillyState.new<T>(Defaults: T, ValidationFunction: nil | (Value: T) -> (boolean, string?)): SillyState<T>
	local self: any = Constructor(Defaults, ValidationFunction)
	return self
end

--[=[
	Used to validate if the Value is a [SillyState].
	@param Value any -- The value you are checking.
	@return boolean -- True iff the value is a [SillyState].
]=]
function SillyState.Is(Value: any)
	return type(Value) == "table" and getmetatable(Value) == SillyState
end

--[=[
	Creates a frozen deep copy of the state.
	@return T -- The frozen deep copy of the state.
]=]
function SillyState:Copy()
	return Locker.DeepLock(self.State)
end

--[=[
	Gets the value at the given key in the state table.
	@param Key string -- The key to get the value from.
	@return unknown
]=]
function SillyState:Get(Key: string)
	return self.State[Key]
end

--[=[
	Sets the value to the given key in the state table.
	@param Key string -- The key to get the value from.
	@param Value unknown -- The value you are setting with.
]=]
function SillyState:Set(Key: string, Value: unknown)
	local PreviousValue = self.State[Key]
	if if type(PreviousValue) == "table" then not EqualObjects(PreviousValue, Value) else PreviousValue == Value then
		self.State[Key] = Value
		self.TaskQueue:Add(Key)
	end
end

--[=[
	Used to cleanup the [SillyState] object.
]=]
function SillyState:Destroy()
	self.Changed:Destroy()
	self.TaskQueue:Destroy()

	table.clear(self)
	setmetatable(self, nil)
end

function SillyState.__tostring()
	return "SillyState"
end

export type Class<T> = typeof(Constructor(({} :: any) :: T))
export type SillyState<T> = {
	ClassName: "SillyState",
	Changed: Signal.Signal<T, string>,

	Copy: (self: SillyState<T>) -> T,
	Get: (self: SillyState<T>, Key: string) -> unknown?,
	Set: (self: SillyState<T>, Key: string, Value: unknown) -> (),
	Destroy: (self: SillyState<T>) -> (),
}

table.freeze(SillyState)
return table.freeze({
	ClassName = SillyState.ClassName;
	new = SillyState.new;
	Is = SillyState.Is;
})
