#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\_utility;

init()
{
	loadData();
	
	level.voteHasStarted = false;
	level.voteHasError = false;
	
	level thread voteInit();
	level thread onEndVote();
	level thread credits();
	
    replacefunc(maps\mp\gametypes\_gamelogic::waittillFinalKillcamDone, ::onEndGame);	
	
	newdata = [];
	dataItems = StrTok(getDvar("vote_maps"), ":");
	for(i = 0; i < dataItems.size; i++)
		newdata[i] = [StrTok(dataItems[i], ";")[0], StrTok(dataItems[i], ";")[1]];
	printLn(newdata[0][1]);
}

loadData()
{
	setDvarIfNotInizialized("vote_enable", 1);
	setDvarIfNotInizialized("vote_type", 1);
	setDvarIfNotInizialized("vote_maps_count", 0);
	setDvarIfNotInizialized("vote_dsr_count", 0);
	setDvarIfNotInizialized("vote_time", 20);
	
	setDvar("vote_credits", "Developed by LastDemon99");
	
	shaders = StrTok("background_image;gradient;gradient_fadein;gradient_top", ";");
    foreach(shader in shaders)
        PreCacheShader(shader);
		
	setDvarIfNotInizialized("vote_maps", "mp_plaza2;Arkaden:mp_mogadishu;Bakaara:mp_bootleg;Bootleg:mp_carbon;Carbon:mp_dome;Dome:mp_exchange;Downturn:mp_lambeth;Fallen:mp_hardhat;Hardhat:mp_interchange;Interchange:mp_alpha;Lockdown:mp_bravo;Mission:mp_radar;Outpost:mp_paris;Resistance:mp_seatown;Seatown:mp_underground;Underground:mp_village;Village");
	setDvarIfNotInizialized("vote_dsr", "dsrName1;dsrAlias1;dsrName2;dsrAlias2:dsrName3;dsrAlias3");
}

voteInit()
{
	level waittill("vote_start");	
	level.voteHasStarted = true;	

	level thread voteTimerInit();
	
	createHudText("^7Press [{+forward}] top up - Press [{+back}] to down - Press [{+activate}] to select option - Press [{+melee_zoom}] to undo select", "hudsmall", 0.8, "CENTER", "CENTER", 0, 210, false); 
	
	bg = createIconHud("background_image", "CENTER", "CENTER", 0, 0, 860, 480, (1,1,1), 1, 1, false); 
	bg.hideWhenInMenu = false;
	
	createIconHud("gradient_fadein", "CENTER", "CENTER", -125, 0, 1, 480, (0.48,0.51,0.46), 1, 3, false); 
	createIconHud("white", "RIGHT", "CENTER", -125, 0, 860, 480, (0,0,0), 0.4, 2, false); 
	createIconHud("gradient", "CENTER", "CENTER", -119, 0, 12, 480, (1,1,1), 0.5, 2, false); 
	
	createIconHud("gradient_fadein", "RIGHT", "CENTER", -125, -172, 220, 1, (0.48,0.51,0.46), 1, 3, false); 
	
	if(isDefined(level.maps_index) && isDefined(level.dsr_index))
		createIconHud("gradient_fadein", "RIGHT", "CENTER", -125, -12, 220, 1, (0.48,0.51,0.46), 1, 3, false); 	
	
	hudLastPosY =  -155;
	if(isDefined(level.maps_index))
	{
		createHudText("^7VOTE MAP", "hudsmall", 1.4, "RIGHT", "CENTER", -151, -190, false); 
		
		level.hudMaps = [level.maps_index.size - 1];
		for (i = 0; i < level.maps_index.size; i++)
		{
			level.hudMaps[i] = createHudText(level.maps[level.maps_index[i]][1], "objective", 1.2, "RIGHT", "CENTER", -151, hudLastPosY, false); 
			hudLastPosY += 20;
		}
	}
	
	if(isDefined(level.dsr_index))
	{
		if(isDefined(level.maps_index)) 
		{
			hudLastPosY =  5;
			createHudText("^7VOTE MODE", "hudsmall", 1.4, "RIGHT", "CENTER", -151, -30, false); 
		}			
		else createHudText("^7VOTE MODE", "hudsmall", 1.4, "RIGHT", "CENTER", -151, -190, false); 
		
		level.hudDsr = [level.dsr_index.size - 1];
		for (i = 0; i < level.dsr_index.size; i++)
		{
			level.hudDsr[i] = createHudText(level.dsr[level.dsr_index[i]][1], "objective", 1.2, "RIGHT", "CENTER", -151, hudLastPosY, false); 
			hudLastPosY += 20;
		}
	}
	
	level thread updateVoteCount();
	
	for ( i = 0; i < level.players.size; i++ )
		level.players[i] thread playerVoteInit();
}

voteTimerInit()
{
	soundFX = spawn("script_origin", (0,0,0) );
	soundFX hide();
	
	timerhud = createTimer(&"Vote end in: ", "hudsmall", 1.4, "RIGHT", "RIGHT", -50, 170);		
	for (i = getDvarInt("vote_time"); i > 0; i--)
	{
		timerhud.Color = (1, 1, 0);		
		if(i < 5) 
		{
			timerhud.Color = (1, 0, 0);
			soundFX playSound( "ui_mp_timer_countdown" );
		}
		wait(1);
	}
	
	level notify("vote_end");
}

playerVoteInit()
{
	if(self.sessionteam == "spectator") return;
	
	self visionsetnakedforplayer("blacktest", 0);
	self playlocalsound("elev_bell_ding");		
	
	self notifyonplayercommand("up", "+forward");
	self notifyonplayercommand("down", "+back");
	self notifyonplayercommand("select", "+activate");
	self notifyonplayercommand("melee", "+melee_zoom");
	
	navbar = self createIconHud("gradient_fadein", "RIGHT", "CENTER", -125, -155, 340, 20, (0,1,0), 0.3, 3, true);
	navbar_shadow = self createIconHud("gradient_top", "RIGHT", "CENTER", -125, -145, 340, 4, (0,0,0), 1, 2, true);
	
	index = 0;
	hasVoted = false;
	selected = [];	
	default_y = -155;
	
	if(isDefined(level.maps_index)) vote_type = "map";
	else vote_type = "dsr";
	
	for(;;) 
	{
		if(vote_type == "map") 
		{
			default_y = -155;
			max_index = level.maps_index.size - 1;
		}
		else 
		{
			if(isDefined(level.maps_index)) default_y = 5;
			max_index = level.dsr_index.size - 1;
		}
 		
		navbar.y = default_y + index * 20;
		navbar_shadow.y = (default_y - 10) + index * 20;		
		key = self waittill_any_return("up", "down", "select", "melee");		
		
		if(key == "up" && !hasVoted)
		{
			if(index > 0) index --;
			else index = max_index;
			self playlocalsound("mouse_over");	
		}
		else if (key == "down" && !hasVoted)
		{
			if(index < max_index) index++;
			else index = 0;
			self playlocalsound("mouse_over");	
		}
		else if (key == "select" && !hasVoted)
		{
			if(vote_type == "map")
			{
				selected["map"] = index;
				level.maps_vote[index]++;
				if(isDefined(level.dsr_index))
				{
					vote_type = "dsr";
					index = 0;
				}
				else hasVoted = true;
			}
			else
			{
				selected["dsr"] = index;
				level.dsr_vote[index]++;
				hasVoted = true;
			}
			
			self playlocalsound("recondrone_lockon");
		}
		else if (key == "melee")
		{
			if((vote_type == "map" && hasVoted) || (isDefined(level.dsr_index) && vote_type == "dsr" && !hasVoted))
			{
				level.maps_vote[selected["map"]]--;
				selected["map"] = undefined;
				if(!isDefined(level.dsr_index)) hasVoted = false;
				else vote_type = "map";
				
				index = 0;
				self playlocalsound("mine_betty_click");
			}
			else if(vote_type == "dsr" && hasVoted)
			{
				level.dsr_vote[selected["dsr"]]--;
				selected["dsr"] = undefined;
				hasVoted = false;
				
				index = 0;
				self playlocalsound("mine_betty_click");				
			}
		}
		else self playlocalsound("elev_door_interupt");			
		wait 0.05;
	}
}

onEndGame() 
{
    if (!IsDefined(level.finalkillcam_winner))
	{
	    if (isRoundBased() && !wasLastRound())
			return false;
		
		level dvarListToArray();
		level thread setRandomVote(getDvarInt("vote_maps_count"), getDvarInt("vote_dsr_count"));			
		wait 3;
		
		if(getDvarInt("vote_enable") && !level.voteHasError)
		{
			level notify("vote_start");
			level waittill("vote_end");
		}
		else reportError();
        return false;
    }
	
    level waittill("final_killcam_done");
	if (isRoundBased() && !wasLastRound())
		return true;
	
	level dvarListToArray();
	level thread setRandomVote(getDvarInt("vote_maps_count"), getDvarInt("vote_dsr_count"));		
	wait 3;
	
	if(getDvarInt("vote_enable") && !level.voteHasError)
	{
		level notify("vote_start");
		level waittill("vote_end");
	}
	else reportError();
    return true;
}

onEndVote()
{
	level waittill("vote_end");
	
	level.winMap = [ 0, 0 ];
	level.winDSR = [ 0, 0 ];
	
	if(isDefined(level.maps_index))
	{
		for (i = 0; i < level.maps_index.size; i++)
			if(level.winMap[0] < level.maps_vote[i])
					level.winMap = [ level.maps_vote[i], i];
				
		if (level.winMap[0] == 0 && level.winMap[1] == 0) level.winMap[1] = randomIntRange(0, level.maps_vote.size);
	}
	
	if(isDefined(level.dsr_index))
	{
		for (i = 0; i < level.dsr_index.size; i++)
			if(level.winDSR[0] < level.dsr_vote[i])
					level.winDSR = [ level.dsr_vote[i], i];
				
		if (level.winDSR[0] == 0 && level.winDSR[1] == 0) level.winDSR[1] = randomIntRange(0, level.dsr_vote.size);	
	}
	
	oldMapRotation = StrTok(getDvar("sv_maprotation"), " ");
	
	if(!isDefined(level.dsr_index)) _dsr = oldMapRotation[1];
	else _dsr = level.dsr[level.dsr_index[level.winDSR[1]]][0];
	
	if(!isDefined(level.maps_index)) _map = getdvar("mapname");
	else _map = level.maps[level.maps_index[level.winMap[1]]][0];
	
	setDvar("sv_maprotation", "dsr " + _dsr + " map " + _map);
	
	if(getDvarInt("vote_type") == 1) exitLevel(0);
	else cmdexec("start_map_rotate"); 
}

updateVoteCount()
{
	for(;;)
	{
		if(isDefined(level.maps_index))
		{
			for (i = 0; i < level.maps_index.size; i++)
				level.hudMaps[i] setText("^7[" + level.maps_vote[i] + "] " + level.maps[level.maps_index[i]][1]);
		}
		
		if(isDefined(level.dsr_index))
		{
			for (i = 0; i < level.dsr_index.size; i++)
				level.hudDsr[i] setText("^7[" + level.dsr_vote[i] + "] " + level.dsr[level.dsr_index[i]][1]); 
		}
		wait(0.05);
	}
}

setRandomVote(maps_size, dsr_size)
{
	if(maps_size > level.maps.size || dsr_size > level.dsr.size || (maps_size <= 1 && dsr_size <= 1))
	{
		level.voteHasError = true;
		return;
	}
	
	if(maps_size >= 1) 
	{
		level.maps_index = randomNum(maps_size, 0, level.maps.size);
		level.maps_vote = [maps_size - 1 ];	
		
		for(i = 0; i < maps_size; i++)
		level.maps_vote[i] = 0;
	}
	if(dsr_size >= 1)
	{
		level.dsr_index = randomNum(dsr_size, 0, level.dsr.size);	
		level.dsr_vote = [dsr_size - 1 ];	
		
		for(i = 0; i < dsr_size; i++)
		level.dsr_vote[i] = 0;
	}
	
	if((maps_size > 6 && isDefined(level.dsr_index)) || (dsr_size > 6 && isDefined(level.maps_index)))
	{
		level.voteHasError = true;
		return;
	}
}

randomNum(size, min, max)
{
	uniqueArray = [size];
	random = 0;

	for (i = 0; i < size; i++)
	{
		random = randomIntRange(min, max);
		for (j = i; j >= 0; j--)
			if (isDefined(uniqueArray[j]) && uniqueArray[j] == random)
			{
				random = randomIntRange(min, max);
				j = i;
			}
		uniqueArray[i] = random;
	}
	return uniqueArray;
}

createHudText(text, font, size, align, relative, x, y, isClient)
{
	if(isClient) hudText = createFontString(font, size);
	else hudText = createServerFontString(font, size);
	
	hudText setpoint(align, relative, x, y);
	hudText setText(text); 
	hudText.alpha = 1;
	hudText.hideWhenInMenu = true;
	hudText.foreground = true;
	return hudText;
}

createIconHud(shader, align, relative, x, y, width, height, color, alpha, sort, isClient)
{
	if(isClient) hudIcon = createIcon(shader, width, height);
	else hudIcon = createServerIcon(shader, width, height);
	
	hudIcon.align = align;
    hudIcon.relative = relative;
    hudIcon.width = width;
    hudIcon.height = height;    
	hudIcon.alpha = alpha;
	hudIcon.color = color;	
    hudIcon.hideWhenInMenu = true;
	hudIcon.hidden = false;
    hudIcon.archived = false;	
    hudIcon.sort = sort;    
    hudIcon setPoint(align, relative, x, y);
	hudIcon setParent(level.uiParent);
    return hudIcon;
}

createTimer(label, font, size, align, relative, x, y)
{
	timer = createServerTimer(font, size);	
	timer setpoint(align, relative, x, y);
	timer.label = label; 
	timer.alpha = 1;
	timer.hideWhenInMenu = true;
	timer.foreground = true;
	timer setTimer(getDvarInt("vote_time"));
	
	return timer;
}

dvarListToArray()
{
	level.maps = [];	
	dataItems = StrTok(getDvar("vote_maps"), ":");	
	for(i = 0; i < dataItems.size; i++)
		level.maps[i] = [StrTok(dataItems[i], ";")[0], StrTok(dataItems[i], ";")[1]];
	
	level.dsr = [];	
	dataItems = StrTok(getDvar("vote_dsr"), ":");	
	for(i = 0; i < dataItems.size; i++)
		level.dsr[i] = [StrTok(dataItems[i], ";")[0], StrTok(dataItems[i], ";")[1]];
}

setDvarIfNotInizialized(dvar, value)
{
	result = getDvar(dvar);	
	if(!isDefined(result) || result == "")
		setDvar(dvar, value);
}

reportError()
{
	printLn("=================================================");
	printLn("IW5_VoteSystem:: [ERROR]");
	printLn("check the lenght or format from your maps and dsr");
	printLn("=================================================");
}

credits()
{
	for(;;) 
    {
		if(getDvar("vote_credits") != "Developed by LastDemon99")
			setDvar("vote_credits", "Developed by LastDemon99");		
		wait(0.35);
	}
}
