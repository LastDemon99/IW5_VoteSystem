#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\_utility;

init()
{
	LoadData();
	
	level thread VoteInit();
	level thread OnEndVote();
	
    replacefunc(maps\mp\gametypes\_gamelogic::waittillFinalKillcamDone, ::_gamelogic_waittillFinalKillcamDone_custom);
	
	//setDvar("scr_" + level.gametype + "_timelimit", 0.1);	
}

_gamelogic_waittillFinalKillcamDone_custom() 
{
    if (!IsDefined(level.finalkillcam_winner))
	{
	    if (isRoundBased() && !wasLastRound())
			return false;
		
		wait 3;
        level notify("vote_start");
		level waittill("vote_end");
        return false;
    }
	
    level waittill("final_killcam_done");
	if (isRoundBased() && !wasLastRound())
		return true;
	
	wait 3;
    level notify("vote_start");
	level waittill("vote_end");
    return true;
}


LoadData()
{
	level.votetime = 20;
	shaders = StrTok("background_image;gradient;gradient_fadein;gradient_top", ";");
    foreach(shader in shaders)
        PreCacheShader(shader);
	
	level.maps = [ "mp_plaza2;Arkaden",
            "mp_mogadishu;Bakaara",
            "mp_bootleg;Bootleg",
            "mp_carbon;Carbon",
            "mp_dome;Dome",
            "mp_exchange;Downturn",
            "mp_lambeth;Fallen",
            "mp_hardhat;Hardhat",
            "mp_interchange;Interchange",
            "mp_alpha;Lockdown",
            "mp_bravo;Mission",
            "mp_radar;Outpost",
            "mp_paris;Resistance",
            "mp_seatown;Seatown",
            "mp_underground;Underground",
            "mp_village;Village" ];
            
			//dlc maps
			/*"mp_morningwood;Blackbox",
            "mp_park;Liberation",
            "mp_qadeem;Oasis",
            "mp_overwatch;Overwatch",
            "mp_italy;Piazza",
            "mp_meteora;Sanctuary",
            "mp_cement;Foundation",
            "mp_aground_ss;Aground",
            "mp_hillside_ss;Getaway",
            "mp_restrepo_ss;Lookout",
            "mp_courtyard_ss;Erosion",
            "mp_terminal_cls;Terminal" ];*/
	
	//
	
	level.dsr = [ "ffa_sniper;iSnipe FFA", "ffa_os;Old School FFA", "inf_ss;SharpShooter Infected", "tdm_crank;Cranked TDM" ];
	
	level thread SetRandomVote(6, 4);	
}

VoteInit()
{
	level waittill("vote_start");//game_over	

	level thread createTimerHud();
	
	createHudText("^7VOTE MAP", "hudsmall", 1.4, "RIGHT", "CENTER", -151, -190, false); 
	createHudText("^7VOTE MODE", "hudsmall", 1.4, "RIGHT", "CENTER", -151, -30, false); 
	
	createHudText("^7Press [{+forward}] top up - Press [{+back}] to down - Press [{+activate}] to select option - Press [{+melee_zoom}] to undo select", "hudsmall", 0.8, "CENTER", "CENTER", 0, 210, false); 
	
	bg = createIconHud("background_image", "CENTER", "CENTER", 0, 0, 860, 480, (1,1,1), 1, 1, false); 
	bg.hideWhenInMenu = false;
	
	createIconHud("gradient_fadein", "CENTER", "CENTER", -125, 0, 1, 480, (0.48,0.51,0.46), 1, 3, false); 
	createIconHud("white", "RIGHT", "CENTER", -125, 0, 860, 480, (0,0,0), 0.4, 2, false); 
	createIconHud("gradient", "CENTER", "CENTER", -119, 0, 12, 480, (1,1,1), 0.5, 2, false); 
	
	createIconHud("gradient_fadein", "RIGHT", "CENTER", -125, -172, 220, 1, (0.48,0.51,0.46), 1, 3, false); 
	createIconHud("gradient_fadein", "RIGHT", "CENTER", -125, -12, 220, 1, (0.48,0.51,0.46), 1, 3, false); 	
	
	level.hudMaps = [level.maps_index.size - 1];
	level.hudDsr = [level.dsr_index.size - 1];
	
	hudLastPosY =  -155;
	for (i = 0; i < level.maps_index.size; i++)
	{
		level.hudMaps[i] = createHudText(getMapAlias(level.maps_index[i]), "objective", 1.2, "RIGHT", "CENTER", -151, hudLastPosY, false); 
		hudLastPosY += 20;
	}
	hudLastPosY =  5;	
	for (i = 0; i < level.dsr_index.size; i++)
	{
		level.hudDsr[i] = createHudText(getDsrAlias(level.dsr_index[i]), "objective", 1.2, "RIGHT", "CENTER", -151, hudLastPosY, false); 
		hudLastPosY += 20;
	}
	
	level thread UpdateVoteCount();
	
	for ( i = 0; i < level.players.size; i++ )
		level.players[i] thread PlayerVoteInit();
}

PlayerVoteInit()
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
	max_index = level.maps_index.size - 1;
	hasVoted = [ false, false];
	selected = [ -1, -1];
	
	for(;;) 
	{
		if(!hasVoted[0]) 
		{
			default_y = -155;
			max_index = level.maps_index.size - 1;
		}
		else 
		{
			default_y = 5;
			max_index = level.dsr_index.size - 1;
		}	
		
		navbar.y = default_y + index * 20;
		navbar_shadow.y = (default_y - 10) + index * 20;
		
		key = self waittill_any_return("up", "down", "select", "melee");			
		if(key == "up" && !hasVoted[1])
		{
			if(index > 0) index --;
			else index = max_index;
			self playlocalsound("mouse_over");	
		}
		else if (key == "down" && !hasVoted[1])
		{
			if(index < max_index) index++;
			else index = 0;
			self playlocalsound("mouse_over");	
		}
		else if (key == "select")
		{
			if(!hasVoted[0])
			{
				hasVoted[0] = true;
				selected[0] = index;
				level.maps_vote[selected[0]]++;
				index = 0;
				
				self iprintln("^2You have vote map ^1" + getMapAlias(level.maps_index[selected[0]]));
				self playlocalsound("recondrone_lockon");	
			}
			else if (!hasVoted[1])
			{
				hasVoted[1] = true;
				selected[1] = index;
				level.dsr_vote[selected[1]]++;
				
				self iprintln("^2You have vote mode ^1" + getDsrAlias(level.dsr_index[selected[1]]));
				self playlocalsound("recondrone_lockon");
			}
		}
		else if (key == "melee")
		{
			if(hasVoted[0] && !hasVoted[1])
			{
				level.maps_vote[selected[0]]--;
				hasVoted[0] = false;
				selected[0] = -1;		
				
				self iprintln("^2You have ^1denied ^2your vote map");	
				self playlocalsound("mine_betty_click");
			}
			else if (hasVoted[1])
			{
				level.dsr_vote[selected[1]]--;
				hasVoted[1] = false;
				selected[1] = -1;
				
				self iprintln("^2You have ^1denied ^2your vote mode");		
				self playlocalsound("mine_betty_click");				
			}
		}
		else self playlocalsound("elev_door_interupt");			
		wait 0.05;
	}
}

UpdateVoteCount()
{
	for(;;)
	{
		for (i = 0; i < level.maps_index.size; i++)
			level.hudMaps[i] setText("^7[" + level.maps_vote[i] + "] " + getMapAlias(level.maps_index[i]));
		
		for (i = 0; i < level.dsr_index.size; i++)
			level.hudDsr[i] setText("^7[" + level.dsr_vote[i] + "] " + getDsrAlias(level.dsr_index[i])); 
		wait(0.05);
	}
}

OnEndVote()
{
	level waittill("vote_end");
	
	level.winMap = [ 0, 0 ];
	level.winDSR = [ 0, 0 ];
	
	for (i = 0; i < level.maps_index.size; i++)
		if(level.winMap[0] < level.maps_vote[i])
				level.winMap = [ level.maps_vote[i], i];
			
	for (i = 0; i < level.dsr_index.size; i++)
		if(level.winDSR[0] < level.dsr_vote[i])
				level.winDSR = [ level.dsr_vote[i], i];

	if (level.winMap[0] == 0 && level.winMap[1] == 0) level.winMap[1] = randomIntRange(0, level.maps_vote.size);
	if (level.winDSR[0] == 0 && level.winDSR[1] == 0) level.winDSR[1] = randomIntRange(0, level.dsr_vote.size);	
	
    setDvar("sv_maprotation", "dsr " + getDsr(level.dsr_index[level.winDSR[1]]) + " map " + getMap(level.maps_index[level.winMap[1]]));
	exitLevel(0);
	//cmdexec("start_map_rotate");
}

getMap(index)
{
	return StrTok(level.maps[index], ";")[0];
}

getMapAlias(index)
{
	return StrTok(level.maps[index], ";")[1];
}

getDsr(index)
{
	return StrTok(level.dsr[index], ";")[0];
}

getDsrAlias(index)
{
	return StrTok(level.dsr[index], ";")[1];
}

SetRandomVote(maps_size, dsr_size)
{
	if(maps_size > 6 || dsr_size > 6) return;
	if(maps_size > level.maps.size) return;
	if(dsr_size > level.dsr.size) return;
	
	level.maps_index = randomNum(maps_size, 0, level.maps.size);	
	level.dsr_index = randomNum(dsr_size, 0, level.dsr.size);	
	
	level.maps_vote = [maps_size - 1 ];	
	level.dsr_vote = [dsr_size - 1 ];	
	
	for(i = 0; i < maps_size; i++)
		level.maps_vote[i] = 0;
	
	for(i = 0; i < dsr_size; i++)
		level.dsr_vote[i] = 0;
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

createTimerHud()
{
	//the game hide or delete timer on game ended, with createServerTimer()
	crappy_timer = createHudText("^2Vote end in: ", "hudsmall", 1.4, "RIGHT", "RIGHT", -50, 170, false);
	soundFX = spawn( "script_origin", (0,0,0) );
	soundFX hide();
	
	for (i = level.votetime; i > 0; i--)
	{
		if(i > 5) crappy_timer setText("^2Vote end in: " + i); 
		else 
		{
			crappy_timer setText("^1Vote end in: " + i); 
			soundFX playSound( "ui_mp_timer_countdown" );
		}
		wait(1);
	}
	level notify("vote_end");
}
