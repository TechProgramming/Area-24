local Knit = require(game:GetService("ReplicatedStorage").Knit)
local NumberFormat = require(Knit.Util.NumberFormat)

local ReplicatedStorage	= game:GetService("ReplicatedStorage");
local CollectionService	= game:GetService("CollectionService");
local TweenService		= game:GetService("TweenService");
local SoundService		= game:GetService("SoundService");
local StarterGui		= game:GetService("StarterGui");
local Lighting			= game:GetService("Lighting");
local Players			= game:GetService("Players");

local AreaController = Knit.CreateController({
	Name = "AreaController",
})

local PLAYER = Players.LocalPlayer;

local LightingSetting = ReplicatedStorage:WaitForChild("LightingSetting");
local TweenSource;

local ConnectionPlaylist;
local ActivePlaylist;
local ActiveSound;
function AreaController:KnitStart()
	
	local AreaService = Knit.GetService("AreaService")
	
	local function SyncLoop(area)
		
		local sync = AreaService:GetSync(area);
		if sync and sync.Target and sync.TimePosition then
			
			if ConnectionPlaylist then
				
				ConnectionPlaylist:Disconnect();
				ConnectionPlaylist = nil;
			end;
			if ActiveSound then
				
				ActiveSound:Stop();
				ActiveSound = nil;
			end;
			local targetAudio = sync.Target;
			targetAudio.TimePosition = sync.TimePosition;
			targetAudio:Resume();
			ActiveSound = targetAudio;
			ConnectionPlaylist = targetAudio.DidLoop:Connect(SyncLoop(area));
		end;
	end;
	
	local function UnSyncLoop()
		
		if ConnectionPlaylist then
			
			ConnectionPlaylist:Disconnect();
			ConnectionPlaylist = nil;
		end;
		if ActiveSound then
			
			ActiveSound:Stop();
			ActiveSound = nil;
		end;
		local targetAudio = ActivePlaylist[math.random(1, #ActivePlaylist)];
		targetAudio:Play();
		ActiveSound = targetAudio;
		ConnectionPlaylist = targetAudio.DidLoop:Connect(UnSyncLoop());
	end;
	
	AreaService.OnAreaChange:Connect(function(name, area)
		
		if not name or not area then
			
			if ConnectionPlaylist then
				
				ConnectionPlaylist:Disconnect();
				ConnectionPlaylist = nil;
			end;
			if ActivePlaylist then
				
				ActivePlaylist = nil;
			end;
			if ActiveSound then
				
				ActiveSound:Stop();
				ActiveSound = nil;
			end;
			return;
		end;
		
		local reverbType = area:GetAttribute("ReverbType")
		if reverbType then
			SoundService.AmbientReverb = Enum.ReverbType[reverbType];
		end;
		
		if area:GetAttribute("Instant") then
			TweenSource = TweenInfo.new(0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
		else
			TweenSource = TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
		end;
		
		local audio = AreaService:GetAudio(area);
		if audio then
			
			if #audio > 1 then
				
				local sync = AreaService:GetSync(area);
				if sync and sync.Target and sync.TimePosition then
					
					if ConnectionPlaylist then
						
						ConnectionPlaylist:Disconnect();
						ConnectionPlaylist = nil;
					end;
					if ActiveSound then
						
						ActiveSound:Stop();
						ActiveSound = nil;
					end;
					local targetAudio = sync.Target;
					targetAudio.TimePosition = sync.TimePosition;
					targetAudio:Resume();
					ActivePlaylist = audio;
					ActiveSound = targetAudio;
					ConnectionPlaylist = targetAudio.DidLoop:Connect(SyncLoop(area));
				else
					
					if ConnectionPlaylist then
						
						ConnectionPlaylist:Disconnect();
						ConnectionPlaylist = nil;
					end;
					if ActiveSound then
						
						ActiveSound:Stop();
						ActiveSound = nil;
					end;
					local targetAudio = audio[math.random(1, #audio)];
					targetAudio:Play();
					ActivePlaylist = audio;
					ActiveSound = targetAudio;
					ConnectionPlaylist = targetAudio.DidLoop:Connect(UnSyncLoop());
				end;
			else
				
				local syncType, sync = AreaService:GetSync(area);
				local targetAudio = audio[1];
				if sync and sync.TimePosition then
					
					targetAudio.TimePosition = sync.TimePosition;
					targetAudio:Resume();
					ActiveSound = targetAudio;
				else
					
					targetAudio:Play();
					ActiveSound = targetAudio;
				end;
			end;
		end;
		
		--if LightingSetting then
			
		--	local targetTween = {};
		--	local targetSetting = LightingSetting:FindFirstChild(area:GetAttribute("LightingSettings"));
		--	if targetSetting then
				
		--		local targetAtmosphere		= targetSetting.InLighting:FindFirstChild("Atmosphere");
		--		local lightingAtmosphere	= Lighting:FindFirstChild("Atmosphere");
		--		if targetAtmosphere and lightingAtmosphere then
		--			local newTween = TweenService:Create(lightingAtmosphere, TweenSource,
		--				{
		--					Density	= targetAtmosphere.Density,
		--					Offset	= targetAtmosphere.Offset,
		--					Color	= targetAtmosphere.Color,
		--					Decay	= targetAtmosphere.Decay,
		--					Glare	= targetAtmosphere.Glare,
		--					Haze	= targetAtmosphere.Haze,
		--				});
		--			table.insert(targetTween, 1, newTween);
		--		end;
				
		--		local targetSky		= targetSetting.InLighting:FindFirstChild("Cloudy");
		--		local lightingSky	= Lighting:FindFirstChild("Cloudy")
		--		if targetSky and lightingSky then
		--			local newTween = TweenService:Create(lightingSky, TweenSource,
		--				{
		--					MoonAngularSize	= targetSky.MoonAngularSize,
		--					StarCount		= targetSky.StarCount,
		--					SunAngularSize	= targetSky.SunAngularSize,
		--				});
		--			table.insert(targetTween, 1, newTween);
		--			lightingSky.CelestialBodiesShown	= targetSky.CelestialBodiesShown;
		--			lightingSky.MoonTextureId			= targetSky.MoonTextureId;
		--			lightingSky.SkyboxBk				= targetSky.SkyboxBk;
		--			lightingSky.SkyboxDn				= targetSky.SkyboxDn;
		--			lightingSky.SkyboxFt				= targetSky.SkyboxFt;
		--			lightingSky.SkyboxLf				= targetSky.SkyboxLf;
		--			lightingSky.SkyboxRt				= targetSky.SkyboxRt;
		--			lightingSky.SkyboxUp				= targetSky.SkyboxUp;
		--			lightingSky.SunTextureId			= targetSky.SunTextureId;
		--		end;
				
		--		local targetColorCorrection		= targetSetting.InLighting:FindFirstChild("ColorCorrection");
		--		local lightingColorCorrection	= Lighting:FindFirstChild("ColorCorrection");
		--		if targetColorCorrection and lightingColorCorrection then
		--			local newTween = TweenService:Create(lightingColorCorrection, TweenSource,
		--				{
		--					Brightness	= targetColorCorrection.Brightness,
		--					Contrast	= targetColorCorrection.Contrast,
		--					Saturation	= targetColorCorrection.Saturation,
		--					TintColor	= targetColorCorrection.TintColor,
		--				});
		--			table.insert(targetTween, 1, newTween);
		--			lightingColorCorrection.Enabled	= targetColorCorrection.Enabled;
		--		end;
				
		--		local newTween = TweenService:Create(Lighting, TweenSource,
		--			{
		--				Ambient						= targetSetting.Lighting.Ambient.Value,
		--				Brightness					= targetSetting.Lighting.Brightness.Value,
		--				ColorShift_Bottom			= targetSetting.Lighting.ColorShift_Bottom.Value,
		--				ColorShift_Top				= targetSetting.Lighting.ColorShift_Top.Value,
		--				EnvironmentDiffuseScale		= targetSetting.Lighting.EnvironmentDiffuseScale.Value,
		--				EnvironmentSpecularScale	= targetSetting.Lighting.EnvironmentSpecularScale.Value,
		--				OutdoorAmbient				= targetSetting.Lighting.OutdoorAmbient.Value,
		--				ShadowSoftness				= targetSetting.Lighting.ShadowSoftness.Value,
		--			});
		--		table.insert(targetTween, 1, newTween);
				
		--		for _, tween in pairs(targetTween) do
		--		--	tween:Play();
		--		end;
		--	end;
		--end;
	end)
end

return AreaController