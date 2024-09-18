local module = {};

local Knit = require(game:GetService("ReplicatedStorage").Knit);

local CollectionService = game:GetService("CollectionService");

function module:Init()
	
	local TransactionService	= Knit.GetService("TransactionService");
	local EventService			= Knit.GetService("EventService");
	
	function EventService.Client.OnRiotPrompt:Connect(player, retrieve)

		local character = player.character;
		if character and CollectionService:HasTag(character, "Riot Prompt") then
			if retrieve then

				CollectionService:RemoveTag(character, "Riot Prompt");
				TransactionService:Award(player, "AK74");
			else

				CollectionService:RemoveTag(character, "Riot Prompt");
			end;
		end;
	end;

	CollectionService:GetInstanceAddedSignal("Riot Prompt"):Connect(function(character)
		wait(10);
		CollectionService:RemoveTag(character, "Riot Prompt");
	end);
end;

return module;