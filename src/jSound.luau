local jSound = {}

local SoundService = game:GetService("SoundService")
local folder = workspace:FindFirstChild("jSounds")
local TweenService = game:GetService("TweenService")
local jUtil = require(script.Parent.jUtil)
--local par = workspace:WaitForChild("jsoundthing"):WaitForChild("Part")
if not folder then
	folder = Instance.new("Folder")
	folder.Parent = workspace
	folder.Name = "jSounds"
end

local function err(message:string)
	return "[jSound] "..message
end

-- Sound: sound instance to clone
function jSound.GlobalSFX(Sound:Sound, sg:SoundGroup?)
	if not Sound then
        error(err("GlobalSFX Parameter underload!"))
    end
	local p = sg or SoundService 
	local s:Sound = Sound:Clone()
	s.Parent = p
	s.SoundGroup = sg
	s:Play()
	jUtil.Debris(s, s.PlaybackSpeed * s.TimeLength)
end

function jSound.LocalSFX(Where:Vector3|CFrame|PVInstance, s:Sound, sg:SoundGroup?)
	if not Where or not s then
        error(err("LocalSFX Parameter underload!"))
    end
	local pos:Vector3
	if typeof(Where) == "Vector3" then
		pos = Where
	elseif typeof(Where) == "CFrame" then
		pos = Where.Position
	else
		pos = Where:GetPivot().Position
	end
	
	local p = Instance.new("Part")
	p.Transparency = 1
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Size = Vector3.new(0.05, 0.05, 0.05)
	p.Anchored = true
	p:PivotTo(CFrame.new(pos))
	p.Parent = folder
	s = s:Clone()
	s.SoundGroup = sg
	s.Parent = p
	s:Play()
	jUtil.Debris(p, s.TimeLength / s.PlaybackSpeed)
end

-- TODO: Rewrite playlists (it's kinda ugly, works though)

export type Playlist = {
	["List"]: {string},
	["Shuffle"]: boolean,
	-- awesome function
	["Skip"]: (self: Playlist) -> (),
	["Pause"]: (self: Playlist) -> (),
	["Resume"]: (self: Playlist) -> (),
	["PlayIndex"]: (self: Playlist, index: number) -> (),
	["ChangePlaylist"]: (self: Playlist, newList: {string}, PreserveQueue: boolean?) -> ()
}
local DefaultSettings: Playlist = {
	["List"] = {},
	["Shuffle"] = true
}

function jSound.PlaylistNew(List:{Sound|string}, Shuffle:boolean?, sg:SoundGroup?): Playlist
	local R = Random.new()
	if typeof(List) ~= "table" then
        List = {}
    end
	if typeof(Shuffle) ~= "boolean" then
        Shuffle = true
        R:Shuffle(List)
    end
	if typeof(sg) ~= "Instance" then
        error(err("Error creating a new playlist: No soundgroup was provided!"))
        return
    end
	local SongEnded = Instance.new("BindableEvent")
	local pl:Playlist = jUtil.deepClone(DefaultSettings)
	pl.List = List or pl.List
	pl.Shuffle = typeof(Shuffle) == "boolean" and Shuffle or pl.Shuffle
	local s = Instance.new("Sound")
	s.Parent = sg
	s.SoundGroup = sg
	s.Volume = 0.5
	s:Play()
	s.Ended:Connect(function()
        SongEnded:Fire()
    end)
	
	local cache = {}
	local curIndex = 1
	local TransitionLock = false
	local Paused = false
	
	-- finds next track and returns soundid
	local function NextTrack()
		curIndex += 1
		if curIndex > #pl.List then
            curIndex = 1
        end
		if pl.Shuffle and #pl.List > 2 then
			local id = nil
			while true do
				local ran = math.random(1, #pl.List)
				if not table.find(cache, pl.List[ran]) then
                    id = pl.List[ran]
                    table.insert(cache, pl.List[ran])
                    break
                end
			end
			if #cache >= 3 then
                table.remove(cache, 1)
            end
			return id
		else
			return pl.List[curIndex]
		end
	end
	
	local function HandleSoundId(Copy:Sound|string)
		local is = typeof(Copy) == "Instance"
		s:ClearAllChildren()
		s.SoundId = is and Copy.SoundId or Copy
		if not is then return end
		for _, v in Copy:GetChildren() do
			local clone = v:Clone()
			clone.Parent = s
		end
	end
	
	local CancelTransition = Instance.new("BindableEvent")
	local function Transition(to:Sound|string)
		CancelTransition:Fire()
		local cancel = false
		task.spawn(function()
			CancelTransition.Event:Wait()
			cancel = true
		end)
		--if typeof(to) == "string" then
		TransitionLock = true
		TweenService:Create(s, TweenInfo.new(1), {Volume = 0}):Play()
		task.wait(1)
		if cancel then return end
		HandleSoundId(to)
		s:Play()
		TransitionLock = false
		SongEnded:Fire()
		TweenService:Create(s, TweenInfo.new(1), {Volume = 0.5}):Play()
		task.wait(1)
			-- i tried
		--elseif typeof(to) == "boolean" then
		--	if to then
		--		s:Resume()
		--		TweenService:Create(s, TweenInfo.new(1), {Volume = 0.5}):Play()
		--	else
		--		TweenService:Create(s, TweenInfo.new(1), {Volume = 0}):Play()
		--		task.wait(1)
		--		if not cancel then
		--			s:Pause()
		--		end
		--	end
		--end
	end
	
	function pl:Skip()
		Transition(NextTrack())
	end
	
	function pl:Pause()
		Paused = true
		s:Pause()
		--Transition(false)
	end
	
	function pl:Resume()
		Paused = false
		s:Resume()
		--Transition(true)
	end
	
	function pl:PlayIndex(index:number)
		if typeof(index) ~= "number" or not self.List[index] then
            error(err("PlayIndex: Invalid index!"))
            return
        end
		Transition(self.List[index])
	end
	
	local CachedLists = {}
	function pl:ChangePlaylist(newList:{string|Sound}, PreserveQueue:boolean?)
		if not newList then
            error(err("Can't change playlist: Provided new list was invalid!"))
            return
        end
		CachedLists[self.List] = curIndex
		if PreserveQueue and CachedLists[newList] then
			CachedLists[self.List] = curIndex
			curIndex = CachedLists[newList]-1
		else
			curIndex = 0
		end
		self.List = newList
		SongEnded:Fire()
	end
	
	task.spawn(function()
		while true do
			if TransitionLock or Paused then task.wait() else
				s:Play()
				local nt = NextTrack()
				HandleSoundId(nt)
				SongEnded.Event:Wait()
			end
		end
	end)
	
	return pl
end

return jSound
