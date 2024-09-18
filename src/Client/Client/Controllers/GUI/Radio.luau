local Knit = require(game:GetService("ReplicatedStorage").Knit);
local MarketplaceService = game:GetService("MarketplaceService")

local PLAYER = game:GetService("Players").LocalPlayer
local RADIO_GUI = PLAYER.PlayerGui:WaitForChild("Radio")

local PLAY_BUTTON = RADIO_GUI.Container.Action.PlayButton
local CLOSE_BUTTON = RADIO_GUI.Container.Close.CloseButton
local SONG_INPUT = RADIO_GUI.Container.SongInput
local NOW_PLAYING = RADIO_GUI.Container.NowPlaying
local MUSIC = script.Music
local THEME = script.Theme
THEME:Play()

local RadioController = Knit.CreateController({
	Name = "RadioController",
})


function RadioController:KnitStart()
	local SFXController = Knit.GetController("SFXController")
	NOW_PLAYING.Text = "Now Playing: N/A"
	
	--Listen to play button
	PLAY_BUTTON.MouseButton1Down:Connect(function()
		self:StopCurrent()
		SFXController:PlayPrefab("ButtonClick")
		self:Play(SONG_INPUT.Text)
	end)
	
	--Listen to close button
	CLOSE_BUTTON.MouseButton1Down:Connect(function()
		SFXController:PlayPrefab("ButtonClick")
		self:Hide()
	end)
	
end


function RadioController:Play(id)
	if not tonumber(id) then
		NOW_PLAYING.Text = "Now Playing: N/A"
		self:StopCurrent()
		return
	end
	
	local info = MarketplaceService:GetProductInfo(id)
	if not info then
		NOW_PLAYING.Text = "ERROR LOADING AUDIO"	
	end

	
	MUSIC.SoundId = "rbxassetid://"..id
	NOW_PLAYING.Text = "Now Playing: "..info.Name
	MUSIC:Play()
	THEME:Stop()
end


function RadioController:StopCurrent()
	MUSIC:Stop()
	THEME:Play()
end


function RadioController:Show()
	RADIO_GUI.Enabled = true
end


function RadioController:Hide()
	RADIO_GUI.Enabled = false
end


return RadioController