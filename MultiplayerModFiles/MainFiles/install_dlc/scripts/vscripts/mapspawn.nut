//********************************************************************************************
//MAPSPAWN.nut is called on newgame or transitions
//********************************************************************************************
printl("==== calling mapspawn.nut")

//-----------------------------------
//             COPYRIGHT
//2020 Portal 2: Multiplayer Mod Team 
//     under a GNU GPLv3 license
//-----------------------------------

//-----------------------------------
// Purpose: Run custom code on map
// spawn to optimize specific maps
// and client experience.
//-----------------------------------

DedicatedServer <- 0 // Are we hosting a dedicated server?

DevMode <- true // Are we in developer mode?

UsePlugin <- true // Are we using our custom plugin?

canclearcache <- false
DoneCacheing <- false
CachedModels <- []
IsInSpawnZone <- []
HasSpawned <- false
PlayerColorCached <- []
CheatsOff <- 0
ReadyCheatsOff <- 0
PlayerJoined <- 0
PlayerID <- 0
GBIsMultiplayer <- 0
DedicatedServerOneTimeRun <- 1
TryGelocity <- 1
TryGelocity2 <- 1
TryGelocity3 <- 1
copp <- 0
WFPDisplayDisabled <- 0
IsSingleplayerMap <- false
LoadPlugin <- false
PluginLoaded <- false
if (UsePlugin==true) {
    PluginLoaded <- true
}

//-----------------------------------
// Initialization Code
//-----------------------------------

function init() {

    // Run singleplayer code
    if (GetMapName().slice(0, 7) != "mp_coop") {
        IsSingleplayerMap <- true
        Singleplayer()
    }

    // Set a URL for downloading custom files through GitHub
    SendToConsole("sv_downloadurl https://github.com/kyleraykbs/gilbert/raw/main/portal2")
    SendToConsole("sv_allowdownload 1")
    SendToConsole("sv_allowupload 1")

    // Create an on screen text message entity
    onscreendisplay <- Entities.CreateByClassname("game_text")
    onscreendisplay.__KeyValueFromString("targetname", "onscreendisplaympmod")
    onscreendisplay.__KeyValueFromString("message", "Waiting For Players...")
    onscreendisplay.__KeyValueFromString("holdtime", "0.2")
    onscreendisplay.__KeyValueFromString("fadeout", "0.2")
    onscreendisplay.__KeyValueFromString("fadein", "0.2")
    onscreendisplay.__KeyValueFromString("spawnflags", "1")
    onscreendisplay.__KeyValueFromString("color", "60 200 60")
    onscreendisplay.__KeyValueFromString("channel", "1")

    // Create a join message entity
    joinmessagedisplay <- Entities.CreateByClassname("game_text")
    joinmessagedisplay.__KeyValueFromString("targetname", "joinmessagedisplaympmod")
    joinmessagedisplay.__KeyValueFromString("holdtime", "3")
    joinmessagedisplay.__KeyValueFromString("fadeout", "0.2")
    joinmessagedisplay.__KeyValueFromString("fadein", "0.2")
    joinmessagedisplay.__KeyValueFromString("spawnflags", "1")
    joinmessagedisplay.__KeyValueFromString("color", "255 200 0")
    joinmessagedisplay.__KeyValueFromString("channel", "3")

    // Create entity to run loop() every 0.1 seconds
    timer <- Entities.CreateByClassname("logic_timer")
    timer.__KeyValueFromString("targetname", "timer")
    EntFireByHandle(timer, "AddOutput", "RefireTime 0.1", 0, null, null)
    EntFireByHandle(timer, "AddOutput", "classname move_rope", 0, null, null)
    EntFireByHandle(timer, "AddOutput", "OnTimer worldspawn:RunScriptCode:loop():0:-1", 0, null, null)
    EntFireByHandle(timer, "Enable", "", 0.1, null, null)

    // Create an entity that sends a client command
    clientcommand <- Entities.CreateByClassname("point_clientcommand")

    // Attempt to load custom plugin
    if("getPlayerName" in this) {
        printl("=================================")
        printl("Plugin already loaded! Skipping...")
        printl("=================================")
    } else {
        printl("============================")
        printl("Plugin not loaded! Loading...")
        printl("============================")
        pluginloadcommand <- Entities.CreateByClassname("point_servercommand")
        // SendToConsole("plugin_load pl")
        LoadPlugin <- true
        PluginLoaded <- false
    }

//-----------------------------------
// Run Map-specific Support Code
//  (Official Cooperative Maps)
//-----------------------------------

    // Are we on mp_coop_lobby_3?
    if (GetMapName() == "mp_coop_lobby_3") {
        LobbyOneTimeRun()
    }
	
    // Map support for mp_coop_lobby_3 if we are on that map
    function LobbyOneTimeRun() {
        //Purpose: Enable the hub entirely
        try {
            // enable team building course
            DoEntFire("!self", "enable", "", 0.0, null, Entities.FindByName(null, "relay_reveal_teambuilding"))
            DoEntFire("!self", "trigger", "", 0.0, null, Entities.FindByName(null, "relay_reveal_teambuilding"))

            // enable tbeam course
            DoEntFire("!self", "enable", "", 0.0, null, Entities.FindByName(null, "relay_reveal_tbeam"))
            DoEntFire("!self", "trigger", "", 0.0, null, Entities.FindByName(null, "relay_reveal_tbeam"))

            // enable paint course
            DoEntFire("!self", "enable", "", 0.0, null, Entities.FindByName(null, "relay_reveal_paint"))
            DoEntFire("!self", "trigger", "", 0.0, null, Entities.FindByName(null, "relay_reveal_paint"))

            // enable fling course
            DoEntFire("!self", "enable", "", 0.0, null, Entities.FindByName(null, "relay_reveal_fling"))
            DoEntFire("!self", "trigger", "", 0.0, null, Entities.FindByName(null, "relay_reveal_fling"))

            // enable extra course
            DoEntFire("!self", "enable", "", 0.0, null, Entities.FindByName(null, "relay_reveal_extra"))
            DoEntFire("!self", "trigger", "", 0.0, null, Entities.FindByName(null, "relay_reveal_extra"))

            // enable all finished course
            DoEntFire("!self", "enable", "", 0.0, null, Entities.FindByName(null, "relay_reveal_all_finished"))
            DoEntFire("!self", "trigger", "", 0.0, null, Entities.FindByName(null, "relay_reveal_all_finished"))

            // enable music
            DoEntFire("!self", "invalue", "7", 0.0, null, Entities.FindByName(null, "@music_lobby_7"))
            // Entities.FindByName(null, "brush_spawn_blocker_red").Destroy()
            // Entities.FindByName(null, "brush_spawn_blocker_blue").Destroy()
        } catch(exception) {
    }
	    
//-----------------------------------
	    
    // Are we on mp_coop_tripleaxis?
    if (GetMapName() == "mp_coop_tripleaxis") {
        mp_coop_tripleaxisFIX()
    }

    // Map support for mp_coop_tripleaxis if we are on that map
    function mp_coop_tripleaxisFIX() {
        Entities.FindByName(null, "outro_math_counter").Destroy()
    }

//-----------------------------------
	    
    // Are we on mp_coop_separation_1?
    if (GetMapName() == "mp_coop_separation_1") {
        mp_coop_separation_1FIX()
        mp_coop_separation_1FIXONETIME()
    }

    // Map support for mp_coop_separation_1 if we are on that map
    function mp_coop_separation_1FIX() {
        EntFireByHandle(Entities.FindByName(null, "left_1st_room_spawn-initial_blue_spawn"), "SetAsActiveSpawn", "", 0, null, null)
        EntFireByHandle(Entities.FindByName(null, "right_1st_room_spawn-initial_orange_spawn"), "SetAsActiveSpawn", "", 0, null, null)
        Entities.FindByName(null, "split_counter").Destroy()
    }
    // NOTE: This is only done once!!!
    function mp_coop_separation_1FIXONETIME() {
        EntFireByHandle(Entities.FindByName(null, "@glados"), "runscriptcode", "GladosCoopMapStart()", 0, null, null)
        EntFireByHandle(Entities.FindByName(null, "@glados"), "runscriptcode", "GladosCoopElevatorEntrance(1)", 0, null, null)
        EntFireByHandle(Entities.FindByName(null, "@glados"), "runscriptcode", "GladosCoopElevatorEntrance(2)", 0, null, null)

        local ent = null
        while(ent = Entities.FindByName(ent, "split_exit_arms")) {
            EntFireByHandle(ent, "setanimation", "90up", 0, null, null)
        }

        local ent = null
        while(ent = Entities.FindByName(ent, "split_entrance_arms")) {
            EntFireByHandle(ent, "setanimation", "90down", 0, null, null)
        }

        local ent = null
        while (ent = Entities.FindByClassnameWithin(ent, "func_areaportalwindow", OldPlayerPos, 5000)) {
            EntFireByHandle(ent, "SetFadeEndDistance", "10000", 0, null, null)
        }

        local loopTimes = 0
        while (loopTimes <= 0) {
            Entities.FindByName(null, "split_exit_fake_collision").Destroy()
            local loopTimes = loopTimes + 1
        }
    }
//-----------------------------------

    // Are we on mp_coop_paint_conversion?
    if (GetMapName() == "mp_coop_paint_conversion") {
        mp_coop_paint_conversionFIX()
    }

    // Map support for mp_coop_paint_conversion if we are on that map
    function mp_coop_paint_conversionFIX() {
        Entities.FindByName(null, "disassembler_1_door_blocker").Destroy()
        Entities.FindByName(null, "disassembler_2_door_blocker").Destroy()

        Entities.FindByName(null, "disassembler_1_door_2").Destroy()
        Entities.FindByName(null, "disassembler_1_door_1").Destroy()

        Entities.FindByName(null, "disassembler_2_door_2").Destroy()
        Entities.FindByName(null, "disassembler_2_door_1").Destroy()
    }

//-----------------------------------
// Run Map-specific Support Code
//   (Custom Cooperative Maps)
//-----------------------------------

    // Are we on mp_coop_gelocity_1_v02?
    if (TryGelocity == 1) {
        try {
            if (GetMapName().slice(28, 50) == "mp_coop_gelocity_1_v02") {
                Gelocity()
            }
        } catch(exception) {
            TryGelocity <- 0
        }
    }

    // Map support for mp_coop_gelocity_1_v02 if we are on that map
    function Gelocity() {
        DoEntFire("!self", "kill", "", 0.0, null, Entities.FindByName(null, "door2_player2"))
        DoEntFire("!self", "kill", "", 0.0, null, Entities.FindByName(null, "door2_player1"))
        DoEntFire("!self", "kill", "", 0.0, null, Entities.FindByName(null, "start_clip_1"))
        DoEntFire("!self", "kill", "", 0.0, null, Entities.FindByName(null, "start_clip_2"))

        local ent = null
        while(ent = Entities.FindByClassname(ent, "func_portal_bumper")) {
            ent.Destroy() // 20 entities removed
        }

        while(ent = Entities.FindByClassname(ent, "beam_spotlight")) {
            ent.Destroy() // 85 entities removed
        }
    }

//-----------------------------------
	    
    // Are we on mp_coop_gelocity_2_v01?
    if (TryGelocity2 == 1) {
        try {
            if (GetMapName().slice(28, 50) == "mp_coop_gelocity_2_v01") {
                Gelocity2()
            }
        } catch(exception) {
            TryGelocity2 <- 0
        }
    }

    // Map support for mp_coop_gelocity_2_v01 if we are on that map
    function Gelocity2() {
        local ent = null
        while(ent = Entities.FindByClassname(ent, "func_portal_bumper")) {
            ent.Destroy() // 20 entities removed
        }

        while(ent = Entities.FindByClassname(ent, "beam_spotlight")) {
            ent.Destroy() // 85 entities removed
        }

        while(ent = Entities.FindByClassname(ent, "env_glow")) {
            ent.Destroy() // 85 entities removed
        }

        while(ent = Entities.FindByClassname(ent, "light_spot")) {
            ent.Destroy() // 85 entities removed
        }

        while(ent = Entities.FindByClassname(ent, "keyframe_rope")) {
            ent.Destroy() // 85 entities removed
        }

        while(ent = Entities.FindByClassname(ent, "move_rope")) {
            ent.Destroy() // 85 entities removed
        }

        while(ent = Entities.FindByClassname(ent, "info_overlay")) {
            ent.Destroy() // 85 entities removed
        }
    }

//-----------------------------------
	    
    // Are we on mp_coop_gelocity_3_v02?
    if (TryGelocity3 == 1) {
        try {
            if (GetMapName().slice(28, 50) == "mp_coop_gelocity_3_v02") {
                Gelocity3()
            }
        } catch(exception) {
            TryGelocity3 <- 0
        }
    }

    // Map support for mp_coop_gelocity_3_v02 if we are on that map
    function Gelocity3() {
        DoEntFire("!self", "kill", "", 0.0, null, Entities.FindByName(null, "door_start_2_2"))
        DoEntFire("!self", "kill", "", 0.0, null, Entities.FindByName(null, "door_start_2_1"))
        DoEntFire("!self", "kill", "", 0.0, null, Entities.FindByName(null, "door_start_1_2"))
        DoEntFire("!self", "kill", "", 0.0, null, Entities.FindByName(null, "door_start_1_1"))
        DoEntFire("!self", "kill", "", 0.0, null, Entities.FindByName(null, "door_start"))
        DoEntFire("!self", "kill", "", 0.0, null, Entities.FindByName(null, "red_dropper-door_eixt"))
        DoEntFire("!self", "kill", "", 0.0, null, Entities.FindByName(null, "blue_dropper-item_door"))

        local ent = null
        while(ent = Entities.FindByClassname(ent, "func_portal_bumper")) {
            ent.Destroy() // 20 entities removed
        }

        while(ent = Entities.FindByClassname(ent, "beam_spotlight")) {
            ent.Destroy() // 85 entities removed
        }
    }
}

//-----------------------------------
// Global Functions Code
//-----------------------------------

// Teleport Players Within A Distance
function TeleportPlayerWithinDistance(SearchPos, SearchDis, TeleportDest) {
    local ent = null
    while(ent = Entities.FindByClassnameWithin(ent, "player", SearchPos, SearchDis)) {
        ent.SetOrigin(TeleportDest)
    }
}

function PlayerWithinDistance(SearchPos, SearchDis) {
    local ent = null
    while(ent = Entities.FindByClassnameWithin(ent, "player", SearchPos, SearchDis)) {
        return ent
    }
}

function DeleteModels(ModelName) {
    local ent = null
    
}

function CacheModel(ModelName) {
    if (Entities.FindByModel(null, "models/"+ModelName)) {
            printl("Model " + ModelName + " is already cached!")
        } else {
        try {
            if (servercommand) {
                printl("servercommand exists")
            }
        } catch(exception) {
            // server an entity that sends a client command
            servercommand <- Entities.CreateByClassname("point_servercommand")
        }

        EntFireByHandle(servercommand, "command", "sv_cheats 1", 0, null, null)
        EntFireByHandle(servercommand, "command", "prop_dynamic_create " + ModelName, 0, null, null)
        EntFireByHandle(servercommand, "command", "sv_cheats 0", 0, null, null)
        CachedModels.push("models/"+ModelName)

        printl("Model " + ModelName + " has been cached sucessfully!")
    }
}

//-----------------------------------
// Base Multiplayer Support Code
//-----------------------------------

// Set GBIsMultiplayer to 1 if the game is multiplayer
try {
    if (::IsMultiplayer()) {
        GBIsMultiplayer <- 1
    }
} catch(exception) {
    GBIsMultiplayer <- 0
}

function GeneralOneTime() {
canclearcache <- true

HasSpawned <- true

local p = null
while (p = Entities.FindByClassname(p, "player")) {
    if (p.GetTeam()==2) {
	OrangeOldPlayerPos <- p.GetOrigin()
    }
}

MapOneTimeRun()

SingleplayerOnFirstSpawn()

local DoorEntities = [
    "airlock_1-door1-airlock_entry_door_close_rl",
    "airlock_2-door1-airlock_entry_door_close_rl",
    "last_airlock-door1-airlock_entry_door_close_rl",
    "airlock_1-door1-door_close",
    "airlock1-door1-door_close",
    "camera_door_3-relay_doorclose",
    "entry_airlock-door1-airlock_entry_door_close_rl",
    "door1-airlock_entry_door_close_rl",
    "airlock-door1-airlock_entry_door_close_rl",
    "orange_door_1-ramp_close_start",
    "blue_door_1-ramp_close_start",
    "orange_door_1-airlock_player_block",
    "blue_door_1-airlock_player_block",
    "airlock_3-door1-airlock_entry_door_close_rl",  //mp_coop_sx_bounce (Sixense map)
]

foreach (DoorType in DoorEntities) {
    try {
	Entities.FindByName(null, DoorType).Destroy()
    } catch(exception) {
    }
}

local ent = null
while (ent = Entities.FindByClassname(ent, "trigger_playerteam")) {
    DoEntFire("!self", "starttouch", "", 0.0, null, ent)
}

OnPlayerJoin <- function() {
    local p = null
    while (p = Entities.FindByClassname(p, "player")) {
        if (p.ValidateScriptScope()) {
            local script_scope = p.GetScriptScope()
            if (!("Colored" in script_scope)) {

                // get player's index and store it
                PlayerID <- p.GetRootMoveParent()
                PlayerID <- PlayerID.entindex()

                // set viewmodel names 
                local ent = null
                while (ent=Entities.FindByClassname(ent, "predicted_viewmodel")) {
                    EntFireByHandle(ent, "addoutput", "targetname viewmodel_player" + ent.GetRootMoveParent().entindex(), 0, null, null)
                    printl("renamed predicted_viewmodel to viewmodel_player" + ent.GetRootMoveParent().entindex())
                    // printl("" + ent.GetRootMoveParent().entindex() + " rotation " + ent.GetAngles())
                    // printl("" + ent.GetRootMoveParent().entindex() + "    origin " + ent.GetOrigin())
                }

                // load plugin
                if (UsePlugin==true) {
                    if (LoadPlugin==true) {
                        EntFireByHandle(pluginloadcommand, "Command", "plugin_load pl", 0, null, null)
                        EntFireByHandle(pluginloadcommand, "Command", "changelevel mp_coop_lobby_3", 0, null, null)
                        LoadPlugin <- false
                    }
                }

                // Set some cvars on every client
                SendToConsole("sv_timeout 3")
                SendToConsole("gameinstructor_enable 1")
                EntFireByHandle(clientcommand, "Command", "gameinstructor_enable 1", 0, p, p)
                EntFireByHandle(clientcommand, "Command", "bind tab +score", 0, p, p)
                EntFireByHandle(clientcommand, "Command", "stopvideos_fadeout", 0, p, p)
                EntFireByHandle(clientcommand, "Command", "r_portal_fastpath 0", 0, p, p)
                EntFireByHandle(clientcommand, "Command", "r_portal_use_pvs_optimization 0", 0, p, p)

                // Print join message on HUD
                if (PluginLoaded==true) {
                    JoinMessage <- getPlayerName(PlayerID-1) + " Joined The Game"
                } else {
                    JoinMessage <- "Player " + PlayerID + " Joined The Game"
                }
                JoinMessage = JoinMessage.tostring()
                joinmessagedisplay.__KeyValueFromString("message", JoinMessage)
                EntFireByHandle(joinmessagedisplay, "display", "", 0.0, null, null)
                if (PlayerID >= 2) {
                    onscreendisplay.__KeyValueFromString("y", "0.075")
                }
                // Assign every client a targetname keyvalue
                if (PlayerID >= 3) {
                    
                    p.__KeyValueFromString("targetname", "player" + PlayerID)
                }

                // Set a random color for clients that join after 16 have joined
                if (PlayerID != 1) {
                    R <- RandomInt(0, 255), G <- RandomInt(0, 255), B <- RandomInt(0, 255)
                    ReadyCheatsOff <- 1
                }

                // Create an entity to display player color at the bottom left of every clients' screen
                colordisplay <- Entities.CreateByClassname("game_text")
                colordisplay.__KeyValueFromString("targetname", "colordisplay" + PlayerID)
                colordisplay.__KeyValueFromString("x", "0")
                colordisplay.__KeyValueFromString("holdtime", "100000")
                colordisplay.__KeyValueFromString("fadeout", "0")
                colordisplay.__KeyValueFromString("fadein", "0")
                colordisplay.__KeyValueFromString("channel", "0")
                colordisplay.__KeyValueFromString("y", "1")

                // Set preset colors for up to 16 clients
                switch (PlayerID) {
                    case 1 : R <- 255; G <- 255; B <- 255; break;
                    case 2 : R <- 180, G <- 255, B <- 180; break;
                    case 3 : R <- 120, G <- 140, B <- 255; break;
                    case 4 : R <- 255, G <- 170, B <- 120; break;
                    case 5 : R <- 255, G <- 100, B <- 100; break;
                    case 6 : R <- 255, G <- 180, B <- 255; break;
                    case 7 : R <- 255, G <- 255, B <- 180; break;
                    case 8 : R <-   0, G <- 255, B <- 240; break;
                    case 9 : R <-  75, G <-  75, B <-  75; break;
                    case 10: R <- 100, G <-  80, B <-   0; break;
                    case 11: R <-   0, G <-  80, B <- 100; break;
                    case 12: R <- 120, G <- 155, B <-  25; break;
                    case 13: R <-   0, G <-   0, B <- 100; break;
                    case 14: R <-  80, G <-   0, B <-   0; break;
                    case 15: R <-   0, G <-  75, B <-   0; break;
                    case 16: R <-   0, G <-  75, B <-  75; break;
                }

                script_scope.Colored <- true
                EntFireByHandle(p, "Color", (R + " " + G + " " + B), 0, null, null)

                if (PlayerID==1) {
                    WorldInitalSpawn()
                }
                
                return
                }
            }
        }
    }   

//-----------------------------------
// START OF LOOP CODE
//-----------------------------------
    
    function loop() {

        OnPlayerJoin() // Defined at line 445

        General() // Defined at line 723

        AllMapsLoopCode() // Defined at line 749

        // local player = null
        // while (player=Entities.FindByClassname(player, "player")) {
        //     local traceend = TraceDir(player.EyePosition(), player.GetAngles(), 100, null).Hit
        //     local pos = TraceVec(player.EyePosition(), traceend,player).Hit
        //     DebugDrawLine(player.EyePosition(), pos, 255, 255, 255, false, -1)
        //     DebugDrawBox(pos, Vector(-2,-2,-2), Vector(2,2,2), 255, 0, 0, 0, 0.1)
        // }

        // Delete all cached models
        if (DoneCacheing==true) {
            foreach (index, CustomGameModel in CachedModels)  {
                try {
                local ent = null
                while (ent = Entities.FindByModel(ent, CustomGameModel)) {
                    if (ent.GetName()!="genericcustomprop") {
                        ent.Destroy()
                    }
                }
                } catch(exception) {
                        printl("ERROR: COULD NOT DELETE THE CUSTOM GAME MODEL: " + CustomGameModel)
                    }
                }
        }
        if (canclearcache==true) {
            foreach (index, CustomGameModel in CachedModels)  {
                CachedModels.remove(index)
            }
        }

        try {
        // Detect death
        if (HasSpawned==true) {
            local p = null
            while (p = Entities.FindByClassname(p, "player")) {
                if (!Entities.FindByNameWithin(null, p.GetName(), OldPlayerPos, 45) && !Entities.FindByNameWithin(null, p.GetName(), OrangeOldPlayerPos, 45))  {
                    foreach (index, item in IsInSpawnZone)  {
                        if (item == p.GetRootMoveParent().entindex().tostring())  {
                            IsInSpawnZone.remove(index)
                        }
                    }
                }

            ContinueDeathCode <- true
            foreach (Name in IsInSpawnZone) {
                if (Name==p.GetRootMoveParent().entindex().tostring()) {
                    ContinueDeathCode <- false
                }
            }

            if (ContinueDeathCode==true) {
                if (Entities.FindByNameWithin(null, p.GetName(), OldPlayerPos, 45) || Entities.FindByNameWithin(null, p.GetName(), OrangeOldPlayerPos, 45)) {
                    //ON DEATH
                    if(PluginLoaded==true) {
                        printl("Player " + getPlayerName(p.entindex()-1) + " Has Respawned")
                    }
                    //show player color again
                    foreach (index, item in PlayerColorCached)  {
                        if (item == p.GetRootMoveParent().entindex().tostring())  {
                            PlayerColorCached.remove(index)
                        }
                    }
                    // END OF ON DEATH
                    IsInSpawnZone.push(p.GetRootMoveParent().entindex().tostring())
                    }
                }
            }
        }

        // Display the current player color in the bottom right of their screen upon spawning
        if (HasSpawned==true) {
            local p = null
            while (p = Entities.FindByClassname(p, "player")) {
                CanTag <- true
                foreach (Name in PlayerColorCached) {
                    if (Name==p.GetRootMoveParent().entindex().tostring()) {
                        CanTag <- false
                    }
                }
                currentnametag <- p.GetRootMoveParent().entindex().tostring()
                if (CanTag==true) {
                        RGB <- "255 255 255"; COLORMESSAGE <- "Random Color";
                        switch (p.GetRootMoveParent().entindex()) {
			    // These are the names of the colors in order of the clients that join (up to 16)
                            case 1 : RGB <- "255 255 255"; COLORMESSAGE <- "White"     ; break;
                            case 2 : RGB <- "120 255 120"; COLORMESSAGE <- "Green"     ; break;
                            case 3 : RGB <- "120 140 255"; COLORMESSAGE <- "Blue"      ; break;
                            case 4 : RGB <- "255 170 120"; COLORMESSAGE <- "Orange"    ; break;
                            case 5 : RGB <- "255 100 100"; COLORMESSAGE <- "Red"       ; break;
                            case 6 : RGB <- "255 110 255"; COLORMESSAGE <- "Pink"      ; break;
                            case 7 : RGB <- "255 255 180"; COLORMESSAGE <- "Yellow"    ; break;
                            case 8 : RGB <- "0 255 240"  ; COLORMESSAGE <- "Aqua"      ; break;
                            case 9 : RGB <- "75 75 75"   ; COLORMESSAGE <- "Black"     ; break;
                            case 10: RGB <- "100 80 0"   ; COLORMESSAGE <- "Brown"     ; break;
                            case 11: RGB <- "0 80 100"   ; COLORMESSAGE <- "Dark Cyan" ; break;
                            case 12: RGB <- "120 155 25" ; COLORMESSAGE <- "Dark Lime" ; break;
                            case 13: RGB <- "0 0 100"    ; COLORMESSAGE <- "Dark Blue" ; break;
                            case 14: RGB <- "80 0 0"     ; COLORMESSAGE <- "Dark Red"  ; break;
                            case 15: RGB <- "0 75 0"     ; COLORMESSAGE <- "Dark Green"; break;
                            case 16: RGB <- "0 75 75"    ; COLORMESSAGE <- "Dark Aqua" ; break;
                        }
                        try {
                        Entities.FindByName(null, "colordisplay" + currentnametag).__KeyValueFromString("message", "Player Color: " + COLORMESSAGE)
                        Entities.FindByName(null, "colordisplay" + currentnametag).__KeyValueFromString("color", RGB)
                        } catch(exception) {

                        }
                        EntFireByHandle(Entities.FindByName(null, "colordisplay" + currentnametag), "display", "", 0.0, p, p)
                        PlayerColorCached.push(currentnametag);
                }
            }
        }
        } catch(exception) {
            printl("Death detection failed. Client likely crashed...")
        }

        // Disconnect player if trying to play singleplayer
        if (GBIsMultiplayer==0) {
            SendToConsole("disconnect \"You cannot play singleplayer when Portal 2 is launched from the Multiplayer Mod Launcher. Please restart the game from Steam\"")
        }

        // Singleplayer loop
        if (GetMapName().slice(0, 7) != "mp_coop") {
            SingleplayerLoop()
        }

        // Run dedicated server code
        if (DedicatedServer == 1) {
            DedicatedServerFunc()
        }

        // Make every clients' collision more elastic
        local k = "CollisionGroup "
        EntFire("player", "addoutput", k + 2)

        // turn cheats off if ready (sv_cheats 0)
        if (ReadyCheatsOff == 1) {
            if (CheatsOff == 0) {
                if (GetMapName() == "mp_coop_lobby_3") {
                    //SendToConsole("sv_cheats 0")
                }
                CheatsOff <- 1
            }
        }

        if (DevMode==true) {
            DevHacks()
        }
    }


//-----------------------------------
// Loop 1: OnPlayerJoin()
//-----------------------------------

// Code is at line 445

//-----------------------------------
// Loop 2: General()
//-----------------------------------

    // general fixes for all maps
    function General() {

            // display waiting for players and run nessacary code after spawn
            if (WFPDisplayDisabled == 0) { 
                        try {
                if (copp == 0) {
                    OldPlayerPos <- Entities.FindByName(null, "blue").GetOrigin()
                    copp <- 1
                }
            } catch(exception) {}

            try {
                // Check if client is in spawn zone
                if (Entities.FindByNameWithin(null, "blue", OldPlayerPos, 35)) {
                    DoEntFire("onscreendisplaympmod", "display", "", 0.0, null, null)
                } else {
                    WFPDisplayDisabled <- 1
                    GeneralOneTime()
                }
            } catch(exception) {}
        }
    }

//-----------------------------------
// Loop 3: AllMapsLoopCode()
//-----------------------------------
    function AllMapsLoopCode() {
        // run all required loops
        if (GetMapName() == "mp_coop_lobby_3") {
            ArtTherapyLobby()
            }

        // Run custom credits code
        if (GetMapName() == "mp_coop_credits") {
            CreditsLoop()
        }
	// Run code fix for mp_coop_wall_5
        if (GetMapName() == "mp_coop_wall_5") {
            mp_coop_wall_5FIX()
        }
	// Run code fix for mp_coop_2paints_1bridge
        if (GetMapName() == "mp_coop_2paints_1bridge") {
            mp_coop_2paints_1bridgeFIX()
        }
    }

//-----------------------------------
// END OF LOOP CODE
//-----------------------------------
	    
//-----------------------------------
// Remove useless entities so that
// the entity limit does not crash
// the game
//-----------------------------------
	    
	// Remove func_portal_bumper's from the map
        local ent = null
        while(ent = Entities.FindByClassname(ent, "func_portal_bumper")) {
            ent.Destroy() // 165 entities removed
        }
	// Remove env_sprite's from the map
        local ent = null
        while(ent = Entities.FindByClassname(ent, "env_sprite")) {
            ent.Destroy() // 31 entities removed
        }

        // fix art therapy tube glitches
        Entities.FindByName(null, "dlc_room_fall_push_right").Destroy()
        Entities.FindByName(null, "dlc_room_fall_push_left").Destroy()

        // fix track 5
        // entry door fix
        Entities.FindByName(null, "track5-door_paint-trigger_hurt_door").Destroy()
        Entities.FindByName(null, "track5-door_paint-collide_door").Destroy()

        // light fix
        Entities.FindByName(null, "@light_shadowed_paintroom").Destroy()

        // remove orange exit door
        local ent = null
        while(ent = Entities.FindByName(ent, "track5-orangeiris_door_elevator_pit")) {
            ent.Destroy()
        }

        Entities.FindByName(null, "track5-orangeescape_elevator_clip").Destroy()

        // remove blue exit door
        local ent = null
        while(ent = Entities.FindByName(ent, "track5-iris_door_elevator_pit")) {
            ent.Destroy()
        }

        Entities.FindByName(null, "track5-escape_elevator_clip").Destroy()
    }

//-----------------------------------
// Course 5 Map Support Code
//-----------------------------------
	    
        // Remove the bottom of droppers in Course 5
        local p = null
        while (p = Entities.FindByClassname(p, "player")) {
            local ent = null
            while (ent = Entities.FindByClassnameWithin(ent, "prop_dynamic", OldPlayerPos, 500)) {
                if (ent.GetModelName() == "models/props_underground/underground_boxdropper.mdl") {
                    EntFireByHandle(ent, "SetAnimation", "open_idle", 0.0, null, null)
                }

                if (ent.GetModelName() == "models/props_backstage/item_dropper.mdl") {
                    EntFireByHandle(ent, "SetAnimation", "item_dropper_idle", 0.0, null, null)
                }
            }
        }
    }
    
    // Run code when the map spawns
    function WorldInitalSpawn() {
        try {
            if (IsSingleplayerMap==true) {
                WorldInitalSpawnSingleplayer()
            }
        } catch(exception) {}

        if (GetMapName()=="mp_coop_lobby_3") {
		
//-----------------------------------
// AUTO GENERATED OBJECT CACHE CODE
//-----------------------------------
		
CacheModel("props_bts/truss_1024.mdl")

CacheModel("props_bts/hanging_walkway_32a.mdl")

CacheModel("props_bts/hanging_walkway_64a.mdl")

CacheModel("props_bts/truss_1024.mdl")

CacheModel("props_bts/lab_pod_b.mdl")

CacheModel("props_bts/truss_1024.mdl")

CacheModel("props_bts/hanging_walkway_128c.mdl")

CacheModel("props_bts/hanging_walkway_512a.mdl")

CacheModel("props_bts/push_button_stand.mdl")

CacheModel("props_bts/truss_1024.mdl")

CacheModel("props_gameplay/industrial_elevator_a.mdl")

CacheModel("props_bts/hanging_walkway_l.mdl")

CacheModel("props_bts/hanging_walkway_end_a.mdl")

CacheModel("props_bts/push_button_stand.mdl")

CacheModel("props_bts/hanging_walkway_end_a.mdl")

CacheModel("props_gameplay/industrial_elevator_a.mdl")

CacheModel("props_bts/hanging_walkway_128a.mdl")

CacheModel("props_bts/hanging_walkway_512a.mdl")

CacheModel("props_bts/lab_pod_b.mdl")

CacheModel("car_int_dest/car_int_dest.mdl")

CacheModel("props_gameplay/push_button.mdl")

CacheModel("a4_destruction/wallpanel_256_cdest.mdl")

CacheModel("props_gameplay/push_button_mp.mdl")

CacheModel("a4_destruction/wallpanel_256_cdest.mdl")

CacheModel("anim_wp/tv_wallpanel.mdl")

CacheModel("anim_wp/tv_wallpanel.mdl")

CacheModel("anim_wp/tv_wallpanel.mdl")

CacheModel("props_gameplay/push_button.mdl")

CacheModel("a4_destruction/wallpanel_256_cdest.mdl")

CacheModel("a4_destruction/wallpanel_256_cdest.mdl")

CacheModel("a4_destruction/fin3_fgwallsmash_stat.mdl")

DoneCacheing <- true

        }
    }

    function MapOneTimeRun() {
        if (GetMapName()=="mp_coop_lobby_3") {
		
//-----------------------------------
// AUTO GENERATED OBJECT CREATION CODE
//-----------------------------------
		
local modelnumber32 = CreateProp("prop_dynamic", Vector(4487.027, 3194.76, 1002.301), "models/props_bts/truss_1024.mdl", 0)
modelnumber32.SetAngles(-0.005, 90.01, -89.98)
modelnumber32.__KeyValueFromString("solid", "6")
modelnumber32.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber33 = CreateProp("prop_dynamic", Vector(4309.685, 3848.971, 934.872), "models/props_bts/hanging_walkway_32a.mdl", 0)
modelnumber33.SetAngles(0, -179.967, 0)
modelnumber33.__KeyValueFromString("solid", "6")
modelnumber33.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber34 = CreateProp("prop_dynamic", Vector(4309.694, 3801.083, 934.972), "models/props_bts/hanging_walkway_64a.mdl", 0)
modelnumber34.SetAngles(-0, 0.01, 360)
modelnumber34.__KeyValueFromString("solid", "6")
modelnumber34.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber35 = CreateProp("prop_dynamic", Vector(4486.305, 3194.931, -1043.699), "models/props_bts/truss_1024.mdl", 0)
modelnumber35.SetAngles(-0.005, 90.01, -89.98)
modelnumber35.__KeyValueFromString("solid", "6")
modelnumber35.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber36 = CreateProp("prop_dynamic", Vector(2872.21, 3923.146, 7.151), "models/props_bts/lab_pod_b.mdl", 0)
modelnumber36.SetAngles(0, -180, -0.02)
modelnumber36.__KeyValueFromString("solid", "6")
modelnumber36.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber37 = CreateProp("prop_dynamic", Vector(4485.943, 3195.016, -2066.699), "models/props_bts/truss_1024.mdl", 0)
modelnumber37.SetAngles(-0.005, 90.01, -89.98)
modelnumber37.__KeyValueFromString("solid", "6")
modelnumber37.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber38 = CreateProp("prop_dynamic", Vector(4310.044, 3193.698, 934.97), "models/props_bts/hanging_walkway_128c.mdl", 0)
modelnumber38.SetAngles(0.001, -0.017, -0.001)
modelnumber38.__KeyValueFromString("solid", "6")
modelnumber38.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber39 = CreateProp("prop_dynamic", Vector(4437.298, 3928.935, 934.958), "models/props_bts/hanging_walkway_512a.mdl", 0)
modelnumber39.SetAngles(-0, -89.97, -0)
modelnumber39.__KeyValueFromString("solid", "6")
modelnumber39.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber40 = CreateProp("prop_dynamic", Vector(4341.034, 3275.196, -512.599), "models/props_bts/push_button_stand.mdl", 0)
modelnumber40.SetAngles(-0, 179.993, 0)
modelnumber40.__KeyValueFromString("solid", "6")
modelnumber40.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber41 = CreateProp("prop_dynamic", Vector(4486.666, 3194.845, -20.699), "models/props_bts/truss_1024.mdl", 0)
modelnumber41.SetAngles(-0.005, 90.01, -89.98)
modelnumber41.__KeyValueFromString("solid", "6")
modelnumber41.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber42 = CreateProp("prop_dynamic", Vector(4410.122, 3194.875, 934.979), "models/props_gameplay/industrial_elevator_a.mdl", 0)
modelnumber42.SetAngles(-0, 179.994, 0)
modelnumber42.__KeyValueFromString("solid", "6")
modelnumber42.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber43 = CreateProp("prop_dynamic", Vector(4309.675, 3928.877, 935), "models/props_bts/hanging_walkway_l.mdl", 0)
modelnumber43.SetAngles(-0, 0.016, 0)
modelnumber43.__KeyValueFromString("solid", "6")
modelnumber43.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber44 = CreateProp("prop_dynamic", Vector(5028.534, 3929.192, 934.891), "models/props_bts/hanging_walkway_end_a.mdl", 0)
modelnumber44.SetAngles(0, -90.014, 0)
modelnumber44.__KeyValueFromString("solid", "6")
modelnumber44.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber45 = CreateProp("prop_dynamic", Vector(4340.937, 3255.135, 935.63), "models/props_bts/push_button_stand.mdl", 0)
modelnumber45.SetAngles(-0, 179.993, 0)
modelnumber45.__KeyValueFromString("solid", "6")
modelnumber45.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber46 = CreateProp("prop_dynamic", Vector(4309.954, 3114.19, 934.914), "models/props_bts/hanging_walkway_end_a.mdl", 0)
modelnumber46.SetAngles(0, 179.982, -0)
modelnumber46.__KeyValueFromString("solid", "6")
modelnumber46.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber47 = CreateProp("prop_dynamic", Vector(4409.51, 3194.552, -511.907), "models/props_gameplay/industrial_elevator_a.mdl", 0)
modelnumber47.SetAngles(0, 179.986, 0)
modelnumber47.__KeyValueFromString("solid", "6")
modelnumber47.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber48 = CreateProp("prop_dynamic", Vector(4948.96, 3929.215, 934.902), "models/props_bts/hanging_walkway_128a.mdl", 0)
modelnumber48.SetAngles(-0, -90, 0)
modelnumber48.__KeyValueFromString("solid", "6")
modelnumber48.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber49 = CreateProp("prop_dynamic", Vector(4309.712, 3705.754, 934.622), "models/props_bts/hanging_walkway_512a.mdl", 0)
modelnumber49.SetAngles(0, -180, -0.059)
modelnumber49.__KeyValueFromString("solid", "6")
modelnumber49.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber50 = CreateProp("prop_dynamic", Vector(2858.858, 4243.747, 7.767), "models/props_bts/lab_pod_b.mdl", 0)
modelnumber50.SetAngles(0.02, -0.001, 0.103)
modelnumber50.__KeyValueFromString("solid", "6")
modelnumber50.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber51 = CreateProp("prop_dynamic", Vector(2866.799, 4066.008, 218.565), "models/car_int_dest/car_int_dest.mdl", 0)
modelnumber51.SetAngles(-0, 90.007, 0)
modelnumber51.__KeyValueFromString("solid", "6")
modelnumber51.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber52 = CreateProp("prop_dynamic", Vector(4341.25, 3275.277, -466.676), "models/props_gameplay/push_button.mdl", 0)
modelnumber52.SetAngles(-0, 179.979, 0)
modelnumber52.__KeyValueFromString("solid", "6")
modelnumber52.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber53 = CreateProp("prop_dynamic", Vector(4128.767, 2912.642, 415.118), "models/a4_destruction/wallpanel_256_cdest.mdl", 0)
modelnumber53.SetAngles(-0, 0.017, 45)
modelnumber53.__KeyValueFromString("solid", "6")
modelnumber53.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber54 = CreateProp("prop_dynamic", Vector(4465.81, 3194.289, -443.653), "models/props_gameplay/push_button_mp.mdl", 0)
modelnumber54.SetAngles(-0, 178.691, 0)
modelnumber54.__KeyValueFromString("solid", "6")
modelnumber54.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber55 = CreateProp("prop_dynamic", Vector(4128.767, 2912.642, 415.118), "models/a4_destruction/wallpanel_256_cdest.mdl", 0)
modelnumber55.SetAngles(-0, 0.017, 45)
modelnumber55.__KeyValueFromString("solid", "6")
modelnumber55.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber56 = CreateProp("prop_dynamic", Vector(4471.268, 3994.334, 999.099), "models/anim_wp/tv_wallpanel.mdl", 0)
modelnumber56.SetAngles(-0, 179.982, 0)
modelnumber56.__KeyValueFromString("solid", "6")
modelnumber56.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber57 = CreateProp("prop_dynamic", Vector(4922.204, 3995.095, 999.885), "models/anim_wp/tv_wallpanel.mdl", 0)
modelnumber57.SetAngles(-0, -179.974, 0)
modelnumber57.__KeyValueFromString("solid", "6")
modelnumber57.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber58 = CreateProp("prop_dynamic", Vector(4703.146, 3995.308, 999.202), "models/anim_wp/tv_wallpanel.mdl", 0)
modelnumber58.SetAngles(-0, 179.97, 0)
modelnumber58.__KeyValueFromString("solid", "6")
modelnumber58.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber59 = CreateProp("prop_button", Vector(4341.152, 3255.216, 981.554), "models/props_gameplay/push_button.mdl", 0)
modelnumber59.SetAngles(-0, 179.979, 0)
modelnumber59.__KeyValueFromString("solid", "6")
modelnumber59.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber60 = CreateProp("prop_dynamic", Vector(4383.452, 2913.066, 415.833), "models/a4_destruction/wallpanel_256_cdest.mdl", 0)
modelnumber60.SetAngles(0, -0.02, 45.008)
modelnumber60.__KeyValueFromString("solid", "6")
modelnumber60.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber61 = CreateProp("prop_dynamic", Vector(4383.452, 2913.066, 415.833), "models/a4_destruction/wallpanel_256_cdest.mdl", 0)
modelnumber61.SetAngles(0, -0.02, 45.008)
modelnumber61.__KeyValueFromString("solid", "6")
modelnumber61.__KeyValueFromString("targetname", "genericcustomprop")

local modelnumber62 = CreateProp("prop_dynamic", Vector(5058.416, 2553.027, 235.856), "models/a4_destruction/fin3_fgwallsmash_stat.mdl", 0)
modelnumber62.SetAngles(-0, 179.902, 90.019)
modelnumber62.__KeyValueFromString("solid", "6")
modelnumber62.__KeyValueFromString("targetname", "genericcustomprop")



        }
    }

//-----------------------------------
// Course 6 Map Support Code
//-----------------------------------

    // art therapy lobby
    function ArtTherapyLobby() {
        // TPG
        local PLent = null
        while(PLent = Entities.FindByClassnameWithin(PLent, "player", Vector(2367, -8126, -54), 30)) {
            local APLent = null
            while(APLent = Entities.FindByClassname(APLent, "player")) {
                APLent.SetOrigin(Vector(2495, -7451, 410))
            }
        }

        // art therapy left chute enabler
        local vectorEEL
        vectorEEL = Vector(5727, 3336, -441)
        local EELent = null
        while(EELent = Entities.FindByClassnameWithin(EELent, "player", vectorEEL, 12)) {
            local LCatEn = null
            while(LCatEn = Entities.FindByName(LCatEn, "left-enable_cats")) {
                DoEntFire("!self", "enable", "", 0.0, null, LCatEn)
                DoEntFire("!self", "trigger", "", 0.0, null, LCatEn)
            }
        }

        // art therapy left chute teleporter
        TeleportPlayerWithinDistance(Vector(5729, 3336, 1005), 30, Vector(3194, -1069, 1676))

        // art therapy right chute enabler
        local vectorEER
        vectorEER = Vector(5727, 3192, -441)
        local EERent = null
        while(EERent = Entities.FindByClassnameWithin(EERent, "player", vectorEER, 12)) {
            local RCatEn = null
            while(RCatEn = Entities.FindByName(RCatEn, "right-enable_cats")) {
                DoEntFire("!self", "enable", "", 0.0, null, RCatEn)
                DoEntFire("!self", "trigger", "", 0.0, null, RCatEn)
            }
        }

        // art therapy right chute teleporter
        TeleportPlayerWithinDistance(Vector(5727, 3180, 1005), 30, Vector(3191, -1228, 1682))

        // disable art therapy chutes
        local vectorE
        vectorE = Vector(3201, -1152, 1272)
        local Aent = null
        while(Aent = Entities.FindByClassnameWithin(Aent, "player", vectorE, 150)) {
            local LCatDis = null
            while(LCatDis = Entities.FindByName(LCatDis, "left-disable_cats")) {
                DoEntFire("!self", "enable", "", 0.0, null, LCatDis)
                DoEntFire("!self", "trigger", "", 0.0, null, LCatDis)
            }
            local RCatDis = null
            while(RCatDis = Entities.FindByName(RCatDis, "right-disable_cats")) {
                DoEntFire("!self", "enable", "", 0.0, null, RCatDis)
                DoEntFire("!self", "trigger", "", 0.0, null, RCatDis)
            }
        }

        // teleport exiting player out of art therapy
        TeleportPlayerWithinDistance(Vector(3584, -1669, 466), 30, Vector(3919, 3352, 158))
    }

    // mp_coop_2paints_1bridge fix
    function mp_coop_2paints_1bridgeFIX() {
        EntFireByHandle(Entities.FindByName(null, "bridge_2"), "enable", "", 0, null, null)
        EntFireByHandle(Entities.FindByName(null, "bridge_1"), "enable", "", 0, null, null)
        EntFireByHandle(Entities.FindByName(null, "paint_sprayer_blue_1"), "start", "", 0, null, null)
    }

    // mp_coop_wall_5 fix
    function mp_coop_wall_5FIX() {
        TeleportPlayerWithinDistance(Vector(1224, -1984, 565), 100, Vector(1208, -1989, 315))
    }

//-----------------------------------
// Dedicated Server Code
//-----------------------------------

    function DedicatedServerFunc() {
        if (DedicatedServerOneTimeRun == 1) {print()}

        local p = null
        while (p = Entities.FindByClassname(p, "player")) {
            if (p.entindex() == 1) {
                EntFireByHandle(clientcommand, "Command", "exec DedicatedServerCommands", 0, p, p)
                // set size to 0
                EntFireByHandle(p, "AddOutput", "ModelScale 0", 0, null, null)
            }
        }
    }

//-----------------------------------
// Custom Credits Code
//-----------------------------------

    // remove selected pods
    function CreditsRemovePod() {
        local ent = null
        while (ent = Entities.FindByNameNearest("chamber*", Vector(-64, 217, 72), 100)) {
            ent.Destroy()
        }

        while (ent = Entities.FindByNameNearest("bubbles*", Vector(-64, 217, 72), 100)) {
            ent.Destroy()
        }
    }

    // fix void camera glitch
    function FixCreditsCameras() {
        // disable useless cameras
        EntFireByHandle(Entities.FindByName(null, "camera_SP"), "disable", "", 0, null, null)
        EntFireByHandle(Entities.FindByName(null, "camera_O"), "disable", "", 0, null, null)

        // reload main camera with new params
        Entities.FindByName(null, "camera").__KeyValueFromString("target_team", "-1")
        EntFireByHandle(Entities.FindByName(null, "camera"), "disable", "", 0, null, null)
        EntFireByHandle(Entities.FindByName(null, "camera"), "enable", "", 0, null, null)
    }

    // replace females with P-body's
    function CreditsSetModelPB(ent) {
        FixCreditsCameras()

        // count how many credits come on screen to change to humans
        MPMCredits <- MPMCredits + 1

        // preset animation
        local RandomAnimation = RandomInt(0, CRAnimationTypesPB)

        // remove pod if needed
        HasRemovedPod <- 0
        foreach (anim in NOTubeAnimsPB) {
            if (AnimationsPB[RandomAnimation] == anim && HasRemovedPod == 0) {
                HasRemovedPod <- 1
                CreditsRemovePod()
            }
        }

        // set model
        ent.SetModel("models/player/eggbot/eggbot.mdl")

        // set color
        EntFireByHandle(ent, "Color", (RandomInt(0, 255) + " " + RandomInt(0, 255) + " " + RandomInt(0, 255)), 0, null, null)

        // set position
        ent.SetOrigin(Vector(0, 0, 7.5))

        // set animation
        EntFireByHandle(ent, "setanimation", AnimationsPB[RandomAnimation], 0, null, null)
    }

    // replace males with Atlas's
    function CreditsSetModelAL(ent) {
        FixCreditsCameras()

        // count how many credits come on screen to change to humans
        MPMCredits <- MPMCredits + 1

        // preset animation
        local RandomAnimation = RandomInt(0, CRAnimationTypesAL)

        // set model
        ent.SetModel("models/player/ballbot/ballbot.mdl")

        // set color
        EntFireByHandle(ent, "Color", (RandomInt(0, 255) + " " + RandomInt(0, 255) + " " + RandomInt(0, 255)), 0, null, null)

        // set position
        ent.SetOrigin(Vector(-10, 0, 25.5))

        // set animation
        EntFireByHandle(ent, "setanimation", AnimationsAL[RandomAnimation], 0, null, null)

        // remove pod if needed
        HasRemovedPod <- 0
        foreach (anim in NOTubeAnimsAL) {
            if (AnimationsAL[RandomAnimation] == anim && HasRemovedPod == 0) {
                HasRemovedPod <- 1
                CreditsRemovePod()
                ent.SetOrigin(Vector(0, 0, 7.5))
            }
        }
    }

    function CreditsLoop() {
        // if mod credits aren't finished change humans to robots
        if (MPMCredits <= MPModCreditNumber) {
            // change males to atlases
            local ent = null
            while (ent = Entities.FindByModel(ent, "models/props_underground/stasis_chamber_male.mdl")) {
                CreditsSetModelAL(ent)
            }

            local ent = null
            while (ent = Entities.FindByModel(ent, "models/props_underground/stasis_chamber_male01.mdl")) {
                CreditsSetModelAL(ent)
            }

            local ent = null
            while (ent = Entities.FindByModel(ent, "models/props_underground/stasis_chamber_male_02.mdl")) {
                CreditsSetModelAL(ent)
            }

            // change females to pbodys
            local ent = null
            while (ent = Entities.FindByModel(ent, "models/props_underground/stasis_chamber_female_01.mdl")) {
                CreditsSetModelPB(ent)
            }

            local ent = null
            while (ent = Entities.FindByModel(ent, "models/props_underground/stasis_chamber_female_02.mdl")) {
                CreditsSetModelPB(ent)
            }

            local ent = null
            while (ent = Entities.FindByModel(ent, "models/props_underground/stasis_chamber_female_03.mdl")) {
                CreditsSetModelPB(ent)
            }
        }
    }

    // credits one time run code
    if (GetMapName() == "mp_coop_credits") {
        // set credits animations
        // pbody animations
        AnimationsPB <- ["taunt_laugh", "taunt_teamhug_idle", "noGun_crouch_idle", "taunt_face_palm", "taunt_selfspin", "taunt_pretzelwave", "noGun_airwalk", "noGun_airwalk", "portalgun_drowning", "layer_taunt_noGun_small_wave", "taunt_highFive_idle"]

        // atlas animations
        AnimationsAL <- ["taunt_laugh", "taunt_laugh", "taunt_teamhug_initiate", "taunt_teamhug_noShow", "ballbot_taunt_rps_shake", "taunt_basketball2", "taunt_headspin", "taunt_facepalm", "taunt_shrug", "layer_taunt_trickfire_handstand", "portalgun_jump_spring", "portalgun_thrash_fall", "noGun_crouch_idle", "noGun_airwalk", "noGun_airwalk"]

        // pbody animations out of tube
        NOTubeAnimsPB <- ["taunt_laugh", "taunt_teamhug_idle", "noGun_crouch_idle", "taunt_face_palm", "taunt_selfspin", "taunt_pretzelwave", "layer_taunt_noGun_small_wave", "taunt_highFive_idle"]

        // atlas animations out of tube
        NOTubeAnimsAL <- ["taunt_laugh", "taunt_laugh", "taunt_teamhug_initiate", "taunt_teamhug_noShow", "ballbot_taunt_rps_shake", "taunt_basketball2", "taunt_headspin", "taunt_facepalm", "taunt_shrug", "layer_taunt_trickfire_handstand", "noGun_crouch_idle"]

        // credit run counter
        MPMCredits <- 0

        // set the amount of pbody animations
        CRAnimationTypesPB <- -1
        foreach (value in AnimationsPB) {
            CRAnimationTypesPB <- CRAnimationTypesPB + 1
        }

        // set the amount of atlas animations
        CRAnimationTypesAL <- -1
        foreach (value in AnimationsAL) {
            CRAnimationTypesAL <- CRAnimationTypesAL + 1
        }

        // add team names to credits
        MPMCoopCreditNames <- [
        "",
        "",
        "",
        "",
        "Portal 2 Multiplayer Mod: Credits",
        "",
        "--------------------------",
        "Multiplayer Mod: Team",
        "--------------------------",
        "kyleraykbs | Scripting + Team Lead",
        "Vista | Reverse Engineering, Plugin Dev",
        "Bumpy | Scripting + Script Theory",
        "Wolƒe Strider Shoσter | Scripting",
        "Enator18 | Python" 
        "Nanoman2525 | Mapping + Entity and Command Help",
        "--------------------------",
        "Multiplayer Mod: Contributers",
        "--------------------------",
        "Darnias | Jumpstarter Code",
        "Mellow | stole all of Python"
        "The Pineapple | Hamachi support",
        "actu | Remote File Downloads",
        "Blub/Vecc | Code Cleanup + Commenting",
        "AngelPuzzle | Translations",
        "SuperSpeed | spedrun da test",
        "--------------------------",
        "Multiplayer Mod: Beta Testers",
        "--------------------------",
        "sear",
        "Trico_Everfire",
        "Brawler",
        "iambread",
        "hulkstar",
        "neck",
        "soulfur",
        "brawler",
        "Sheuron",
        "portalboy",
        "charity",
        "Souper Marilogi",
        "fluffys",
        "JDWMGB",
        "ALIEN GOD",
        "mono",
        "mp_emerald",
        "Funky Kong",
        "MicrosoftWindows",
        "dactam",
        "wol",
        "kitsune",
        "charzar",
        "NintenDude",
        "SlingEXE",
        "--------------------------",
        "Thank you all so so much!!!",
        "--------------------------"
        "",
        "",
        "--------------------------",
        "Valve: Credits",
        "--------------------------",
        ]

        // set the amount of credits
        MPModCreditNumber <- -1
        foreach (value in MPMCoopCreditNames) {
            MPModCreditNumber <- MPModCreditNumber + 1
        }

        // mount list of credits to credits
        foreach (Name in MPMCoopCreditNames) {
            AddCoopCreditsName(Name)
        }
    }

    // run init code
    try {
    Entities.First().ConnectOutput("OnUser1", "init")
    } catch(exception) {}
    try {
    DoEntFire("worldspawn", "FireUser1", "", 0.0, null, null)
    } catch(exception) {}

//-----------------------------------
// Singleplayer Support Code
//-----------------------------------

function Singleplayer() {
    // Support for the map sp_a1_intro2
    if (GetMapName() == "sp_a1_intro2") {
        EntFireByHandle(Entities.FindByName(null, "arrival_elevator-elevator_1"), "startforward", "", 0, null, null)
        SendToConsole("commentary 0")
        Entities.FindByName(null, "@entry_door-door_close_relay").Destroy()
        Entities.FindByName(null, "@exit_door-door_close_relay").Destroy()
        Entities.FindByName(null, "Fizzle_Trigger").Destroy()

    }

    // Support for the map sp_a1_intro3
    if (GetMapName() == "sp_a1_intro3") {
        Entities.FindByName(null, "door_0-door_close_relay").Destroy()
        EntFireByHandle(Entities.FindByName(null, "arrival_elevator-elevator_1"), "startforward", "", 0, null, null)
        Entities.FindByName(null, "player_clips").Destroy()
        // destroy pusher x4
        Entities.FindByName(null, "podium_collapse_push_brush").Destroy()
        Entities.FindByName(null, "podium_collapse_push_brush").Destroy()
        Entities.FindByName(null, "podium_collapse_push_brush").Destroy()
        Entities.FindByName(null, "podium_collapse_push_brush").Destroy()
        Entities.FindByName(null, "door_3-door_close_relay").Destroy()
        Entities.FindByName(null, "portal_orange_2").Destroy()
        Entities.FindByName(null, "emitter_orange_2").Destroy()
        Entities.FindByName(null, "backtrack_brush").Destroy()
        Entities.FindByName(null, "portal_orange_mtg").Destroy()
        Entities.FindByName(null, "emitter_orange_mtg").Destroy()
        hasgotportalgunSPMP <- 0
        timeout <- 1
    }

    // Support for the map sp_a1_intro4
    if (GetMapName() == "sp_a1_intro4") {
        EntFireByHandle(Entities.FindByName(null, "arrival_elevator-elevator_1"), "startforward", "", 0, null, null)
        Entities.FindByName(null, "door_0-door_close_relay").Destroy()
        Entities.FindByClassnameNearest("trigger_once", Vector(464, 136, 72), 1024).Destroy()
        EntFireByHandle(Entities.FindByName(null, "glass_pane_intact_model"), "kill", "", 0, null, null)
        EntFireByHandle(Entities.FindByName(null, "glass_pane_fractured_model"), "enable", "", 0, null, null)
        EntFireByHandle(Entities.FindByName(null, "glass_pane_1_door_1"), "open", "", 0, null, null)
        Entities.FindByName(null, "glass_pane_1_door_1_blocker").Destroy()
        Entities.FindByClassnameNearest("trigger_once", Vector(878, -528, 137), 1024).Destroy()
        Entities.FindByName(null, "glass_shard").Destroy()
        Entities.FindByName(null, "section_2_trigger_portal_spawn_a2_rm3a").Destroy()
        Entities.FindByName(null, "portal_a_lvl3").Destroy()
        Entities.FindByName(null, "section_2_portal_a1_rm3a").Destroy()
        Entities.FindByName(null, "section_2_portal_a2_rm3a").Destroy()
        Entities.FindByName(null, "room_1_portal_activate_rl").Destroy()
        Entities.FindByName(null, "room_2_portal_activate_rl").Destroy()
        Entities.FindByName(null, "room_3_portal_activate_rl").Destroy()
        Entities.FindByName(null, "door_2-close_door_rl").Destroy()
    }

    // Support for the map sp_a1_intro5
    if (GetMapName() == "sp_a1_intro5") {
        EntFireByHandle(Entities.FindByName(null, "arrival_elevator-elevator_1"), "startforward", "", 0, null, null)
        Entities.FindByName(null, "room_1_portal_activate_rl").Destroy()
        Entities.FindByName(null, "door_0-close_door_rl").Destroy()
        Entities.FindByClassnameNearest("trigger_multiple", Vector(-64, 824, 320), 1024).Destroy()
    }

    // Support for the map sp_a1_intro6
    if (GetMapName() == "sp_a1_intro6") {
        EntFireByHandle(Entities.FindByName(null, "arrival_elevator-elevator_1"), "startforward", "", 0, null, null)
        Entities.FindByName(null, "room_1_entry_door-close_door_rl").Destroy()
        Entities.FindByName(null, "room_1_fling_portal_activate_rl").Destroy()
        Entities.FindByName(null, "fling_safety_catapult").Destroy()
        Entities.FindByName(null, "room_1_fling_portal_emitter").Destroy()
        Entities.FindByName(null, "room_2_fling_portal_activate_rl").Destroy()
        Entities.FindByClassnameNearest("trigger_once", Vector(648, 0, 176), 1024).Destroy()
        Entities.FindByClassnameNearest("trigger_once", Vector(1200, -136, 188), 1024).Destroy()
        Entities.FindByClassnameNearest("trigger_once", Vector(2504, -160, 448), 1024).Destroy()
        local fallenautoportal = CreateProp("prop_dynamic", Vector(-325, 24, 0), "models/props/portal_emitter.mdl", 0)
        fallenautoportal.SetAngles(-90, 69, 0)
    }

    // Support for the map sp_a1_intro7
    if (GetMapName() == "sp_a1_intro7") {
        EntFireByHandle(Entities.FindByName(null, "arrival_elevator-elevator_1"), "startforward", "", 0, null, null)
        EntFireByHandle(Entities.FindByName(null, "arrival_elevator-open"), "trigger", "", 0, null, null)
        Entities.FindByName(null, "door_0-close_door_rl").Destroy()
        Entities.FindByName(null, "room_1_portal_activate_rl").Destroy()
        Entities.FindByName(null, "InstanceAuto9-socket_trigger").Destroy()
        Entities.FindByName(null, "bts_panel_door-LR_heavydoor_close").Destroy()
        Entities.FindByName(null, "heavy_door_backtrack_clip").Destroy()
        Entities.FindByName(null, "bts_panel_door-heavydoor_open_clip").Destroy()
        Entities.FindByName(null, "transition_airlock_door_close_rl").Destroy()
        Entities.FindByName(null, "transition_trigger").Destroy()
        Entities.FindByName(null, "portal_detector").__KeyValueFromString("CheckAllIDs", "1")
    }

    // Support for the map sp_a2_laser_intro
    if (GetMapName() == "sp_a2_laser_intro") {
        EntFireByHandle(Entities.FindByName(null, "arrival_elevator-elevator_1"), "startforward", "", 0, null, null)
        Entities.FindByName(null, "door_0-close_door_rl").Destroy()
        Entities.FindByName(null, "@exit_door-close_door_rl").Destroy()
    }

    // Support for the map sp_a2_laser_stairs
    if (GetMapName() == "sp_a2_laser_stairs") {
        Entities.FindByName(null, "door_0-close_door_rl").Destroy()
        Entities.FindByName(null, "door_1-close_door_rl").Destroy()
    }
    
}

//-----------------------------------
// Developer Hacks Code
//-----------------------------------

function DevHacks() {
//     if (GetMapName()=="mp_coop_paint_longjump_intro") {
//         //airlockexit teleport
//         local ent = null
//         while(ent = Entities.FindByNameWithin(ent, "blue", Vector(80, -7567, 960), 200)) {
//             ent.SetOrigin(Vector(243, -7037, 960))
//         }

//         //teleportfromexit to gel
//         local ent = null
//         while(ent = Entities.FindByNameWithin(ent, "blue", Vector( 80, -7087, 960), 90)) {
//             ent.SetOrigin(Vector(198, -6553, 960))
//         }

//         //yeet to brig
//         local ent = null
//         while(ent = Entities.FindByNameWithin(ent, "blue", Vector( 220, -5829, 807), 350)) {
//             ent.SetOrigin(Vector(257, -5352, 960))
//         }


//         //orang brig
//         local ent = null
//         while(ent = Entities.FindByNameWithin(ent, "blue", Vector( -437, -1541, 448), 80)) {
//             ent.SetOrigin(Vector(-453, -1541, 942))
//         }

//         //speee juhmp
//         local ent = null
//         while(ent = Entities.FindByNameWithin(ent, "blue", Vector( -1, 406, 104), 80)) {
//             ent.SetOrigin(Vector(-136, 58, 1027))
//         }

//         //speee juhmp minr
//         local ent = null
//         while(ent = Entities.FindByNameWithin(ent, "blue", Vector( 431, -2127, 448), 80)) {
//             ent.SetOrigin(Vector(-136, 58, 1027))
//         }

//         //speee oragneuntp
//         local ent = null
//         while(ent = Entities.FindByNameWithin(ent, "blue", Vector( -448, -1543, 758), 80)) {
//             ent.SetOrigin(Vector(-471, -1722, 975))
//         }

//         //tp tu vaulht
//         local ent = null
//         while(ent = Entities.FindByNameWithin(ent, "blue", Vector( 390, -4977, 960), 80)) {
//             ent.SetOrigin(Vector(-171, -1663, 960))
//         }

//         //tp tu vaulht
//         local ent = null
//         while(ent = Entities.FindByNameWithin(ent, "blue", Vector( 751, -6575, 960), 100)) {
//             ent.SetOrigin(Vector(7, 841, 1216))
//         }
//     }
}

function SingleplayerLoop() {
    // sp_a1_intro2
    if (GetMapName() == "sp_a1_intro2") {
        try {
            EntFireByHandle(Entities.FindByName(null, "arrival_elevator-light_elevator_fill"), "TurnOn", "", 0, null, null)
        } catch(exception) {}

        local portalgun = null
        while ( portalgun = Entities.FindByClassname(portalgun, "weapon_portalgun")) {
            portalgun.Destroy()
        }

        local p = null
        while(p = Entities.FindByClassnameWithin(p, "player", Vector(-320, 1248, -656), 45)) {
            SendToConsole("commentary 1")
            SendToConsole("changelevel sp_a1_intro3")
        }

        try {
            Entities.FindByName(null, "block_boxes").Destroy()
        } catch(exception) {}
    }

    // sp_a1_intro3
    if (GetMapName() == "sp_a1_intro3") {
        local p = null
        while(p = Entities.FindByClassnameWithin(p, "player", Vector(-1344, 4304, -784), 45)) {
           SendToConsole("commentary 1")
           SendToConsole("changelevel sp_a1_intro4")
        }

        try {
            EntFireByHandle(Entities.FindByName(null, "arrival_elevator-light_elevator_fill"), "TurnOn", "", 0, null, null)
        } catch(exception) {}

        // remove portalgun
        if (hasgotportalgunSPMP == 0) {
            local portalgun = null
            while (portalgun = Entities.FindByClassname(portalgun, "weapon_portalgun")) {
                portalgun.Destroy()
            }
        }

        if (!Entities.FindByName(null, "portalgun")) {
            local p = null
            if (timeout != 25) {
                timeout <- timeout + 1
                hasgotportalgunSPMP <- 1

                while (p = Entities.FindByClassname(p, "player")) {
                    EntFireByHandle(clientcommand, "Command", "hud_saytext_time 0", 0, p, p)
                    EntFireByHandle(clientcommand, "Command", "give weapon_portalgun", 0, p, p)
                    EntFireByHandle(clientcommand, "Command", "upgrade_portalgun", 0, p, p)
                    EntFireByHandle(clientcommand, "Command", "sv_cheats 1", 0, p, p)
                }
            } else {
                while (p = Entities.FindByClassname(p, "player")) {
                    EntFireByHandle(clientcommand, "Command", "hud_saytext_time 12", 0, p, p)
                }
                EntFireByHandle(clientcommand, "Command", "sv_cheats 0", 0, Entities.FindByName(null, "blue"), Entities.FindByName(null, "blue"))
            }
        }

        // make Wheatley look at player
        local ClosestPlayerMain = Entities.FindByClassnameNearest("player", Entities.FindByName(null, "spherebot_1_bottom_swivel_1").GetOrigin(), 10000)
        EntFireByHandle(Entities.FindByName(null, "spherebot_1_bottom_swivel_1"), "SetTargetEntity", ClosestPlayerMain.GetName(), 0, null, null)
    
        try {
            EntFireByHandle(Entities.FindByName(null, "arrival_elevator-light_elevator_fill"), "TurnOn", "", 0, null, null)
        } catch(exception) {}
    }

    // sp_a1_intro4
    if (GetMapName() == "sp_a1_intro4") {
        try {
            EntFireByHandle(Entities.FindByName(null, "arrival_elevator-light_elevator_fill"), "TurnOn", "", 0, null, null)
        } catch(exception) {}
        local p = null
        while(p = Entities.FindByClassnameWithin(p, "player", Vector(806, -528, 64), 150)) {
            EntFire("projected_texture_03", "TurnOn", "", 0, null)
        }
        local p = null
        while(p = Entities.FindByClassnameWithin(p, "player", Vector( 2151, -527, -499), 45)) {
            SendToConsole("commentary 1")
            SendToConsole("changelevel sp_a1_intro5")
        }
    }

    //sp_a1_intro5
    if (GetMapName() == "sp_a1_intro5") {
        try {
            EntFireByHandle(Entities.FindByName(null, "arrival_elevator-light_elevator_fill"), "TurnOn", "", 0, null, null)
        } catch(exception) {}
        local p = null
        while(p = Entities.FindByClassnameWithin(p, "player", Vector(-67, 1319, -102), 60)) {
            SendToConsole("commentary 1")
            SendToConsole("changelevel sp_a1_intro6")
        }
    }

    //sp_a1_intro6
    if (GetMapName() == "sp_a1_intro6") {
        try {
            EntFireByHandle(Entities.FindByName(null, "arrival_elevator-light_elevator_fill"), "TurnOn", "", 0, null, null)
        } catch(exception) {}
        local p = null
        while(p = Entities.FindByClassnameWithin(p, "player", Vector(3015, -174, -125), 60)) {
            SendToConsole("commentary 1")
            SendToConsole("changelevel sp_a1_intro7")
        }
    }

    WheatleySeq1 <- false

    //sp_a1_intro7
    if (GetMapName() == "sp_a1_intro7") {
        try {
            EntFireByHandle(Entities.FindByName(null, "arrival_elevator-light_elevator_fill"), "TurnOn", "", 0, null, null)
        } catch(exception) {}
        // make Wheatley look at player
        local ClosestPlayerMain = Entities.FindByClassnameNearest("player", Entities.FindByName(null, "spherebot_1_bottom_swivel_1").GetOrigin(), 10000)
        EntFireByHandle(Entities.FindByName(null, "spherebot_1_bottom_swivel_1"), "SetTargetEntity", ClosestPlayerMain.GetName(), 0, null, null)
        EntFireByHandle(Entities.FindByName(null, "spherebot_1_top_swivel_1"), "SetTargetEntity", ClosestPlayerMain.GetName(), 0, null, null)
        //make Wheatley non stealable
        try {
        Entities.FindByName(null, "@sphere").ConnectOutput("OnPlayerPickup","disablewheatleyplayerpickup")
        Entities.FindByName(null, "@sphere").ConnectOutput("OnPlayerDrop","enablewheatleyplayerpickup")
        //disable sentaint arm and disable pickup until spchill is over
        Entities.FindByName(null, "sphere_impact_trigger").ConnectOutput("OnStartTouch","wheatleyhitground")
        //skip panel bit
        Entities.FindByName(null, "@plug_open_rl").ConnectOutput("OnTrigger","SPSkipPanel")
        } catch(exception) { }

        /////////
        //LINES//
        /////////
        
        if(Entities.FindByName(null, "playline1")) {
            Entities.FindByName(null, "@spheredummy").EmitSound("vo\\wheatley\\sp_a2_wheatley_ows01.wav")
            Entities.FindByName(null, "@spheredummy").EmitSound("vo\\wheatley\\sp_a2_wheatley_ows02.wav")
            printl("played line1")
        }

        if(Entities.FindByName(null, "playline2")) {
            Entities.FindByName(null, "@spheredummy").EmitSound("vo\\wheatley\\sphere_flashlight_tour67.wav")
            printl("played line2")
        }

        if(Entities.FindByName(null, "playline3")) {
            Entities.FindByName(null, "@spheredummy").EmitSound("vo\\wheatley\\sp_a1_wakeup_hacking09.wav")
            printl("played line3")
        }

        if(Entities.FindByName(null, "playline4")) {
            Entities.FindByName(null, "InstanceAuto9-sphere_socket").EmitSound("vo\\wheatley\\sp_a1_wakeup_hacking12.wav")
            printl("played line4")
        }

        if(Entities.FindByName(null, "playline5")) {
            Entities.FindByName(null, "@spheredummy").EmitSound("vo\\wheatley\\sp_a1_wakeup_hacking10.wav")
            printl("played line5")
        }

        if(Entities.FindByName(null, "playline6")) {
            Entities.FindByName(null, "InstanceAuto9-sphere_socket").EmitSound("ambient\\alarms\\portal_elevator_chime.wav")
            printl("played line6")
        }

        if(Entities.FindByName(null, "playline7")) {
            Entities.FindByName(null, "@spheredummy").EmitSound("vo\\wheatley\\bw_finale4_hackworked01.wav")
            printl("played line7")
        }



        if(Entities.FindByName(null, "playline8")) {
            Entities.FindByName(null, "@spheredummy").EmitSound("vo\\wheatley\\sp_a1_intro7_hoboturret01.wav")
            printl("played line8")
        }

        if(Entities.FindByName(null, "playline9")) {
            Entities.FindByName(null, "@spheredummy").EmitSound("vo\\wheatley\\sp_a1_intro7_hoboturret08.wav")
            printl("played line9")
        }

        if(Entities.FindByName(null, "playline10")) {
            Entities.FindByName(null, "@spheredummy").EmitSound("vo\\wheatley\\sp_a1_intro7_hoboturret07.wav")
            printl("played line10")
        }

        if(Entities.FindByName(null, "playline11")) {
            Entities.FindByName(null, "@spheredummy").EmitSound("vo\\wheatley\\sp_a1_intro7_hoboturret05.wav")
            printl("played line11")
        }

        if(Entities.FindByName(null, "playline12")) {
            Entities.FindByName(null, "@spheredummy").EmitSound("vo\\wheatley\\sp_a1_intro7_hoboturret06.wav")
            printl("played line12")
        }

        if (!Entities.FindByName(null, "seq1finished")) {
            local p = null
            while (p = Entities.FindByClassnameWithin(p, "player", Vector(-1117, -416, 1280), 100)) {
                Entities.CreateByClassname("prop_dynamic").__KeyValueFromString("targetname", "seq1finished")
                printl("Seq1 Done")
                Entities.FindByName(null, "@spheredummy").EmitSound("vo\\wheatley\\gloriousfreedom03.wav")
                EntFire("offrails_airlock_door_1_open_rl", "trigger", "", 0, null)
            }
        }

        if (!Entities.FindByName(null, "seq2finished")) {
            local p = null
            while (p = Entities.FindByClassnameWithin(p, "player", Vector(-2692, -404, 1280), 100)) {
                Entities.CreateByClassname("prop_dynamic").__KeyValueFromString("targetname", "seq2finished")
                printl("Seq2 Done")

                EntFire("@glados", "runscriptcode", "sp_a1_intro7_HoboTurretScene()", 0, null)
            
                EntFire("myexplode2", "addoutput", "targetname playline8", 0.00, null)
                EntFire("playline8", "addoutput", "targetname myexplode2", 0.11, null)

                EntFire("myexplode2", "addoutput", "targetname playline9", 1.50, null)
                EntFire("playline9", "addoutput", "targetname myexplode2", 1.51, null)

                EntFire("myexplode2", "addoutput", "targetname playline10", 3.10, null)
                EntFire("playline10", "addoutput", "targetname myexplode2", 3.11, null)

                EntFire("myexplode2", "addoutput", "targetname playline11", 4.80, null)
                EntFire("playline11", "addoutput", "targetname myexplode2", 4.81, null)

                EntFire("myexplode2", "addoutput", "targetname playline12", 7.20, null)
                EntFire("playline12", "addoutput", "targetname myexplode2", 7.25, null)
            }
        }

        local p = null
        while(p = Entities.FindByClassnameWithin(p, "player", Vector(-2207, 384, 1280), 200)) {
            SendToConsole("commentary 1")
            SendToConsole("changelevel sp_a1_wakeup")
        }

    }

    //sp_a2_laser_intro
    if (GetMapName() == "sp_a2_laser_intro") {
        try {
            EntFireByHandle(Entities.FindByName(null, "arrival_elevator-light_elevator_fill"), "TurnOn", "", 0, null, null)
        } catch(exception) {}

        local p = null
        while(p = Entities.FindByClassnameWithin(p, "player", Vector(1224, 8, -590), 45)) {
            SendToConsole("commentary 1")
            SendToConsole("changelevel sp_a2_laser_stairs")
        }
        
    }

    //sp_a2_laser_stairs
    if (GetMapName() == "sp_a2_laser_stairs") {
        try {
            EntFireByHandle(Entities.FindByName(null, "arrival_elevator-light_elevator_fill"), "TurnOn", "", 0, null, null)
        } catch(exception) {}

        local p = null
        while(p = Entities.FindByClassnameWithin(p, "player", Vector(148, 1126, -396), 45)) {
            SendToConsole("commentary 1")
            SendToConsole("changelevel sp_a2_dual_lasers")
        }
        
    }

}

function WorldInitalSpawnSingleplayer() {
    if (GetMapName() == "sp_a1_intro6") {

    }
}

function SingleplayerOnFirstSpawn() {
    if (GetMapName() == "sp_a1_intro6") {

    }
}

//SINGLEPLAYER FUNCTIONS
function disablewheatleyplayerpickup() {
    printl("Player Picked Up Wheatley. Disabling Pickup!")
    EntFire("@sphere", "disablepickup", "", 0, null)
    EntFire("@sphereDummy", "enablepickup", "", 0, null)
}
function enablewheatleyplayerpickup() {
    printl("Player Picked Up Wheatley. Enabling Pickup!")
    EntFire("@sphere", "enablepickup", "", 0, null)
    EntFire("@sphereDummy", "enablepickup", "", 0, null)
}

function wheatleyhitground() {
    EntFire("@sphere", "disablepickup", "", 1.05, null)
    EntFire("@sphere", "enablepickup", "", 8, null)
    EntFire("spherebot_1_top_swivel_1", "deactivate", "", 1.01, null)
}

function SPSkipPanel() {
    printl("message")
    EntFire("InstanceAuto9-sphere_socket", "setanimation", "bindpose", 2.7, null)
    myexplode2 <- Entities.CreateByClassname("npc_personality_core")
    myexplode2.__KeyValueFromString("targetname", "myexplode2")
    myexplode2.SetOrigin(Vector(-822, -523, 1269))

    myexplode <- Entities.CreateByClassname("env_ar2explosion")
    myexplode.__KeyValueFromString("targetname", "myexplode")
    myexplode.__KeyValueFromString("material", "particle/particle_noisesphere")
    myexplode.SetOrigin(Vector(-822, -523, 1269))
    EntFire("myexplode", "explode", "", 2.5, null)
    EntFire("myexplode2", "explode", "", 2.5, null)
    EntFire("myexplode2", "explode", "", 3.0, null)
    
    Entities.FindByName(null, "@sphere").__KeyValueFromString("targetname", "@sphereDummy")
    local mysphere = Entities.FindByName(null, "@spheredummy")

	self.PrecacheSoundScript( "sphere03.sp_a2_wheatley_ows01" )
    self.PrecacheSoundScript( "sphere03.sp_a2_wheatley_ows02" )
    self.PrecacheSoundScript( "sphere03.sphere_flashlight_tour67" )
    self.PrecacheSoundScript( "sphere03.sp_a1_wakeup_hacking09" )
    self.PrecacheSoundScript( "sphere03.sp_a1_wakeup_hacking12" )
    self.PrecacheSoundScript( "sphere03.sp_a1_wakeup_hacking10" )
    self.PrecacheSoundScript( "sphere03.bw_finale4_hackworked01" )
    self.PrecacheSoundScript( "Portal.elevator_chime" )
    self.PrecacheSoundScript( "sphere03.GloriousFreedom03" )
    self.PrecacheSoundScript( "sphere03.bw_fire_lift03" )

    self.PrecacheSoundScript( "sphere03.sp_a1_intro7_hoboturret01" )
    self.PrecacheSoundScript( "sphere03.sp_a1_intro7_hoboturret08" )
    self.PrecacheSoundScript( "sphere03.sp_a1_intro7_hoboturret07" )
    self.PrecacheSoundScript( "sphere03.sp_a1_intro7_hoboturret05" )
    self.PrecacheSoundScript( "sphere03.sp_a1_intro7_hoboturret06" )

    EntFire("myexplode2", "addoutput", "targetname playline1", 2.65, null)
    EntFire("playline1", "addoutput", "targetname myexplode2", 2.76, null)

    EntFire("myexplode2", "addoutput", "targetname playline2", 6.55, null)
    EntFire("playline2", "addoutput", "targetname myexplode2", 6.66, null)

    EntFire("myexplode2", "addoutput", "targetname playline3", 12.75, null)
    EntFire("playline3", "addoutput", "targetname myexplode2", 12.86, null)

    EntFire("myexplode2", "addoutput", "targetname playline4", 16.75, null)
    EntFire("playline4", "addoutput", "targetname myexplode2", 16.86, null)

    EntFire("myexplode2", "addoutput", "targetname playline5", 18.00, null)
    EntFire("playline5", "addoutput", "targetname myexplode2", 18.11, null)

    EntFire("myexplode2", "addoutput", "targetname playline6", 24.00, null)
    EntFire("playline6", "addoutput", "targetname myexplode2", 24.11, null)

    EntFire("myexplode2", "addoutput", "targetname playline7", 25.50, null)
    EntFire("playline7", "addoutput", "targetname myexplode2", 25.61, null)

    EntFire("bts_panel_door-LR_heavydoor_open", "trigger", "", 25.50, null)

}


/********** *******
* cut paste code *
*****************/

/*

Entities.FindByClassnameNearest("trigger_once", Vector(878, -528, 137), 1024).Destroy()

Entities.FindByName(null, "NAME").Destroy()

Entities.FindByClassnameNearest("CLASS", Vector(1, 2, 3), 1).Destroy()

local p = null
while(p = Entities.FindByClassnameWithin(p, "player", Vector(1, 2, 3), 45)) {
    SendToConsole("commentary 1")
    SendToConsole("changelevel LEVELNAME")
}

local ent = null
while ( ent = Entities.FindByClassname(ent, "CLASSNAME")) {
    ent.Destroy()
}


if (GetMapName() == "MAPNAME") {
    SendToConsole("commentary 0")
}

EntFireByHandle(Entities.FindByName(null, "NAME"), "ACTION", "VALUE", DELAYiny, ACTIVATOR, CALLER)

try {
    EntFireByHandle(Entities.FindByName(null, "arrival_elevator-light_elevator_fill"), "TurnOn", "", 0, null, null)
} catch(exception) {}
*/
