--[[
	Easy management of sounds, music playlists
]]

-- enable dynamic typechecking
local DEBUG = false
-- Object pool size. It is adviced you rise it if sound effects are frequent
local OBJ_POOL3D = 200
local OBJ_POOL2D = 100

local jSound = {}
local Playlist = {}
Playlist.__index = Playlist

local SoundService = game:GetService("SoundService")
local folder = workspace:FindFirstChild("jSounds") -- This folder will be used for temp instances in jSound.LocalSFX

local Janitor = require(script.Parent.Janitor)
local ObjPooling = require(script.Parent.ObjPooling)
local jUtil = require(script.Parent.jUtil)
local t = require(script.Parent.t)

local Params = {
	LoadWait = 0,
	AutoExpand = true,
	MaxPoolSize = 1000
}
local Sound3D = Instance.new("Attachment")
do
	local sound = Instance.new("Sound")
	sound.Name = "s"
	sound.Parent = Sound3D
end

local Pool3D = ObjPooling.new(OBJ_POOL3D, Sound3D, Params)
local Pool2D = ObjPooling.new(OBJ_POOL2D, Instance.new("Sound"), Params)

if not folder then
	folder = Instance.new("Folder")
	folder.Parent = workspace
	folder.Name = "jSounds"
end

--[[
	Equals 2 sounds
]]
local function Equal(SoundTarget:Sound, Soundtemplate:Sound)
	SoundTarget.Volume = Soundtemplate.Volume
	SoundTarget.PlaybackSpeed = Soundtemplate.PlaybackSpeed
	SoundTarget.SoundId = Soundtemplate.SoundId
	SoundTarget.RollOffMaxDistance = Soundtemplate.RollOffMaxDistance
	SoundTarget.RollOffMinDistance = Soundtemplate.RollOffMinDistance
	SoundTarget.TimePosition = Soundtemplate.TimePosition
	SoundTarget.RollOffMode = Soundtemplate.RollOffMode
end
--[[
	Resets a sound to it's original state after pool usage
]]


local checkGlobalSFX = t.tuple(t.instanceIsA("Sound"), t.optional(t.instanceIsA("SoundGroup")))

--[[
	Create a sound effect in 2D space. The sound will be destroyed when it ends.

	It is ill-advised to interact with instances created by this function, as they are pooled.

	@param Sound Sound to clone. Children will not be preserved
	@param SoundGroup Optional sound group to parent the sound to
]]
function jSound.GlobalSFX(Sound:Sound, SoundGroup:SoundGroup?)
	if DEBUG then
		assert(checkGlobalSFX(Sound, SoundGroup))
	end
	local p = SoundGroup or SoundService 
	local Queued = Pool2D:LoadItem(p)
	local s:Sound = Queued.Instance
	s.SoundGroup = SoundGroup
	Equal(s, Sound)
	s:Play()
	s.Ended:Once(Queued.Unload, Queued)
end

-- unreadable piece of shit. All it does is it just checks types of the function LocalSFX
local CheckLocalSFX = t.tuple(t.union(t.Vector3, t.CFrame, t.instanceIsA("PVInstance")), t.instanceIsA("Sound"), t.optional(t.instanceIsA("SoundGroup")))

--[[
	Play a sound effect in 3D space. The sound will be destroyed when it ends.

	It is ill-advised to interact with instances created by this function, as they are pooled.

	
	@param Where Where the sound will play WARNING: if set to a PVInstance, the SFX will NOT be pooled! That might cause performance drops if it's very frequent
	@param Sound Sound to clone. Children will not be preserved
	@param SoundGroup Optional sound group to parent the sound to
]]
function jSound.LocalSFX(Where:Vector3|CFrame|PVInstance, Sound:Sound, SoundGroup:SoundGroup?)
	if DEBUG then
		assert(CheckLocalSFX(Where, Sound, SoundGroup))
	end
	local pos:Vector3
	if typeof(Where) == "Vector3" then
		pos = Where
	elseif typeof(Where) == "CFrame" then
		pos = Where.Position
	end
	local s:Sound
	if typeof(Where) == "Instance" then
		local attach = Sound3D:Clone()
		s = attach.s
		s.Ended:Once(function()
			attach:Destroy()
		end)
		attach.Parent = Where
	else
		local Queued = Pool3D:LoadItem(folder)
		local attach = Queued.Instance
		attach.WorldPosition = pos
		s = attach.s
		s.Ended:Once(Queued.Unload, Queued)
	end
	Equal(s, Sound)
	s.SoundGroup = SoundGroup
	s:Play()
end

local PlaylistChecker = t.tuple(t.table, t.optional(t.boolean), t.optional(t.instanceIsA("SoundGroup")))

--[[
	Create a new playlist.
	@param List Sounds to be used in the playlist. Sounds will be cloned.
	@param Shuffle Whether or not the playlist should play songs in a random order
	@param SoundGroup Sound group that the playlist should use
]]
function jSound.NewPlaylist(List:{Sound}, Shuffle:boolean?, SoundGroup:SoundGroup?)
	if DEBUG then
		assert(PlaylistChecker(List, Shuffle, SoundGroup))
	end
	if #List < 1 then
		error("Playlists cannot have 0 items!", 2)
	end
	local self = setmetatable({}, Playlist)

	self.ShouldShuffle = Shuffle or false
	self.SoundGroup = SoundGroup
	self.CurrentIndex = 1
	self.IsPlaying = false
	self.IsPaused = false
	self._Janitor = Janitor.new()
	self.List = {}

	for _, v in List do
		local t = v:Clone()
		t.Looped = false
		table.insert(self.List, t)
	end
	self:NewSG(self.SoundGroup)

	if self.ShouldShuffle then
		self:Shuffle()
	end

	self:Play()

	return self
end

--[[
	Gets the song at a given index
]]
function Playlist._GetIndex(self:Playlist, index:number)
	return self.List[index]
end

--[[
	Gets the song at the current index
]]
function Playlist._Get(self:Playlist)
	return self:_GetIndex(self.CurrentIndex)
end

--[[
	Play the song on current index
]]
function Playlist.Play(self:Playlist)
	if self.IsPlaying then return end
	local Sound = self:_GetIndex(self.CurrentIndex)
	self.IsPlaying = true
	self.IsPaused = false
	Sound:Play()
	self._Janitor:Add(
		Sound.Ended:Connect(function()
			self:Skip()
		end)
	)
end

--[[
	Stop the song on current index
]]
function Playlist.Stop(self:Playlist)
	local Sound = self:_Get()
	self.IsPlaying = false
	self.IsPaused = false
	self._Janitor:Cleanup()
	Sound:Stop()
end

--[[
	Pause a playlist
	
	Note that it stays in memory; To destroy a playlist, use :Destroy()
]]
function Playlist.Pause(self:Playlist)
	if not self.IsPlaying or self.IsPaused then return end
	local Sound = self:_Get()
	Sound:Pause()
	self.IsPaused = true
end

--[[
	Resume a playlist
]]
function Playlist.Resume(self:Playlist)
	if not self.IsPlaying or not self.IsPaused then return end
	local Sound = self:_Get()
	Sound:Resume()
	self.IsPaused = false
end

--[[
	Skips the currently playing track
]]
function Playlist.Skip(self:Playlist)
	if self.IsPlaying then
		self:Stop()
		self.CurrentIndex = jUtil.WrapNumber(self.CurrentIndex + 1, #self.List)
		self:Play()
	else
		self.CurrentIndex = jUtil.WrapNumber(self.CurrentIndex + 1, #self.List)
	end
end

--[[
	Randomizes the playlist.

	Note that current song will be skipped.
]]
function Playlist.Shuffle(self:Playlist)
	if not self.IsPlaying then
		self.CurrentIndex = 1
		jUtil.ShuffleTable(self.List)
	else
		self:Stop()
		self.CurrentIndex = 1
		jUtil.ShuffleTable(self.List)
		self:Play()
	end
end

--[[
	Assign a new SoundGroup for this playlist

	@param sg SoundGroup to assign the playlist to. Can be nil
]]
function Playlist.NewSG(self:Playlist, sg:SoundGroup?)
	self.SoundGroup = sg
	for _, v in self.List do
		v.SoundGroup = sg
		v.Parent = sg or SoundService
	end
end

--[[
	Disconnects all connections and removes a playlist.
]]
function Playlist.Destroy(self:Playlist)
	self:Stop()
	for _, v in self.List do
		v:Destroy()
	end
	self = nil
end

export type Playlist = typeof(jSound.NewPlaylist())

return jSound
