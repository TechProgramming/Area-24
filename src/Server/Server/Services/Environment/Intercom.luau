local Knit = require(game:GetService("ReplicatedStorage").Knit);

local CollectionService = game:GetService("CollectionService");

local Intercoms = CollectionService:GetTagged("Intercom");

local Announcements =
	{
		["Code Brown"]	= 6456260122,
		["Alarm"]		= 5344070323,
		["Attention"]	= 4002655502,
		["Work"]		= 6826415438,	
		["Rollcall"]	= 6826415894,
		["Lunch"]		= 6826416234,
		["Lockdown"]	= 6826416463,
		["Break"]		= 6826416792,
		["Sleep"]		= 6826417055,
		
		--Contest
		["Vented"]  = 7539608126; -- vent opened
	};

local AnnouncementsGroup =
	{
		["Rollcall"]	= {6826415894, 6914146439},
		["Lunch"]		= {6826416234, 6914146598, 7539605767}, --last one is contest PIZZA
		["Work"]		= {6826415438, 6914068969},
		["Sleep"]		= {6826417055, 6914454636},
		["Lockdown"]	= {6826416463, 6914146746},
		
		["GeneralRandom"] = {7539588451, 7539600258, 7539607141, 6456260122} -- contest besides last one which is frames' code brown
	};

local IntercomService = Knit.CreateService({
	Name = "IntercomService",
	Client = {},
	Busy = false,
});


function IntercomService:KnitStart()
	--print("START THE INTERCOM")
	while true do 
		local waitTime = math.random(120, 600)
		print(waitTime)
		wait(waitTime)
		self:PlayFromGroup("GeneralRandom")
		
	end
end;

function IntercomService:PlayFromGroup(name)

	local group = AnnouncementsGroup[name];
	if group then

		local audio = group[math.random(1, #group)];
		if audio then

			for _, intercom in pairs(Intercoms) do
				intercom.Music:Stop()
				intercom.Music.SoundId = "rbxassetid://"..audio
				intercom.Tone:Play()
			end
		end;
	end;
end;

function IntercomService:PlayWithGroupPriority(name)

	local group = AnnouncementsGroup[name];
	if group then

		local audio = group[math.random(1, #group)];
		if audio then

			for _, intercom in pairs(Intercoms) do

				intercom.Music.SoundId = "rbxassetid://"..audio;
				intercom.Tone:Play();
			end;
		end;
	else
		local audio = Announcements[name];
		if audio then

			for _, intercom in pairs(Intercoms) do
				intercom.Music:Stop()
				intercom.Music.SoundId = "rbxassetid://"..audio;
				intercom.Tone:Play();
			end;
		end;
	end;
end;

function IntercomService:StartAlarm()
	
	local audio = Announcements["Alarm"]
	if audio then
		
		for _, intercom in pairs(Intercoms) do
			intercom.Alarm.SoundId = "rbxassetid://"..audio
			intercom.Alarm:Play()
		end
	end
end

function IntercomService:StopAlarm()
	for _, intercom in pairs(Intercoms) do
		intercom.Alarm:Stop()
	end
end

function IntercomService:Play(name)
	
	local audio = Announcements[name]
	if audio then
		
		for _, intercom in pairs(Intercoms) do
			intercom.Music:Stop()
			intercom.Music.SoundId = "rbxassetid://"..audio
			intercom.Tone:Play()
		end
	end
end

for _, intercom in pairs(Intercoms) do
	
	intercom.Tone.Played:Connect(function()
		
		wait(2)
		intercom.Music:Play()
	end)
end

return IntercomService;