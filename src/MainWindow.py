import json
import os
import random
import subprocess
import sys
import threading
import time
import webbrowser
from inspect import _void
import traceback

import __main__
import pygame
import pyperclip
from pygame.locals import *
from steamid_converter import Converter

import Scripts.BasicFunctions as BF
import Scripts.Configs as cfg
import Scripts.GlobalVariables as GVars
import Scripts.RunGame as RG
import Scripts.Updater as up
import Scripts.Workshop as workshop
from Scripts.BasicLogger import Log, StartLog
import Scripts.DataSystem as DS
import Scripts.DiscordRichPresence as DRP

tk = ""
try:
    from tkinter import Tk

    tk = Tk()
    tk.withdraw()
except Exception as e:
    Log(str(e))

# set current directory to the directory of this file
os.chdir(os.path.dirname(os.path.abspath(__file__)))

class Gui:
    def __init__(self, devMode: bool) -> None:
        pygame.mixer.pre_init(channels=1)
        pygame.init()
        pygame.mixer.init()

        self.hvrclksnd = pygame.mixer.Sound("GUI/assets/sounds/hoverclick.wav")
        self.hvrclksnd.set_volume(0.05)

        #! public variables
        self.coolDown: int = 0
        self.CurInput: str = ""
        self.ERRORLIST: list = []
        self.InputPrompt: list = []
        self.PromptBreaks: int = 0
        self.HasBreaks: bool = False
        self.PlayersMenu: list = []
        self.directorymenu: list = []
        self.directorymenutext: list = []
        self.PopupBoxList: list = []
        self.LanguagesMenu: list = []
        self.IsUpdating: bool = False
        self.AfterInputFunction = None
        self.SettingsButtons: list = []
        self.SecAgo: float = time.time()
        self.selectedpopupbutton: self.ButtonTemplate
        self.LookingForInput: bool = False
        self.CurrentSelectedPlayer: int = 0
        self.Floaters: list[self.Floater] = []

    ###############################################################################
        # The resolution of the launcher when it opens, why the height is 800 is to accomidate the Steam Decks resolution if launching the launcher in Gaming Mode
        self.screen = pygame.display.set_mode((1280, 800), RESIZABLE) 
        self.fpsclock = pygame.time.Clock()
        self.devMode: bool = devMode
        self.running: bool = True
        self.FPS: int = 60
        self.currentVersion: str = "2.1.0" # Change this before releasing a new version of the launcher

        # Define the name and image of the window
        pygame.display.set_caption('Portal 2: Multiplayer Mod Launcher')
        self.p2mmlogo = pygame.image.load("GUI/assets/images/p2mm64.png").convert_alpha()
        pygame.display.set_icon(self.p2mmlogo)
        # cubes
        self.greencube = pygame.image.load("GUI/assets/images/greencube.png").convert_alpha()
        self.redcube = pygame.image.load("GUI/assets/images/redcube.png").convert_alpha()
        self.goldencube = pygame.image.load("GUI/assets/images/yellowcube.png").convert_alpha()

        ###############################################################################

        self.DefineMainMenu()
        self.DefineSettingsMenu()
        self.DefineDataMenu()
        self.DefineWorkshopMenu()
        self.DefineManualMountingMenu()
        self.DefineResourcesMenu()
        self.DefineTestingMenu()

        self.CurrentButtonsIndex: int = 0
        self.CurrentMenuTextIndex: int = 0
        self.CurrentMenuButtons: list = self.MainMenuButtons
        self.CurrentMenuText: list = self.MainMenuText
        self.SelectedButton: self.ButtonTemplate = self.CurrentMenuButtons[self.CurrentButtonsIndex]

        for i in range(9):
            self.AddFloater(50, 50, 20, 75, 75)

    # surf = pygame.surface.Surface([int(W / 25) + int(H / 50), int(W / 25) + int(H / 50)])
    #     surf.set_colorkey((0, 0, 0))
    #     surf.fill((255, 255, 255))
    #     surf = pygame.transform.rotate(surf, 19)

    def PlaySound(self, sound: pygame.mixer.Sound) -> None:
        """Plays the launcher's sounds when hovering / clicking on a buttong
        Args:
            sound (pygame.mixer.Sound): the sound to play
        """
        LauncherSFX = GVars.configData["Launcher-SFX"]["value"] == "true"
        if LauncherSFX:
            pygame.mixer.Sound.play(sound)

    class Floater:
        def __init__(self, rot: float, surf: pygame.Surface, x: float, y: float, negrot: bool) -> None:
            self.rot: float = rot
            self.surf: pygame.Surface = surf
            self.x: float = x
            self.y: float = y
            self.negrot: bool = negrot

    def AddFloater(self, width: float, height: float, rot: float, x: float, y: float) -> None:
        """creates the falling cubes and adds them to a list of floaters

        Args:
            width (float): the widh of the cube's image
            height (float): the height of the cube's image
            rot (float): the rotation of the cube on the z axis when it spawns
            x (float): the x position where it first spawns
            y (float): the y position where it first spawns
        """
        surf = self.greencube
        surf = pygame.transform.scale(surf, (width, height))
        surf = pygame.transform.rotate(surf, 0)

        negrot = random.randint(0, 1) == 1

        floater = self.Floater(rot, surf, x, y, negrot)

        self.Floaters.append(floater)

    # DISPLAY TEXT CLASS
    # Needs to be programmed for the size to grow when the size variable is bigger, not smaller, see below
    class DisplayText:
        def __init__(self,
                    text: str, # The text you want to display
                    font: str = "GUI/assets/fonts/pixel.ttf", # In case we have a custom font that needs to replace the default, this may be the case for certain languages.
                    textColor: tuple = (155, 155, 155), # The color you want the text displayed to be in RGB format
                    xpos: float = 0, # The bigger the number, the more right the text will be.
                    ypos: float = 0, # The bigger the number, the lower the text will be.
                    xstart: float = 0, # Where the next line for the line will begin, normally this should be equal to xpos
                    xend: float = 100, # Where the line of text will end and start the next one at xstart
                    size: float = 100 # The bigger the number, the smaller it is, because that definitely makes sense, needs to be fixed.
                    ) -> None:

            self.text = text
            self.font = font
            self.textColor = textColor
            self.xpos = xpos
            self.xstart = xstart
            self.xend = xend
            self.ypos = ypos
            self.size = size

    # BUTTON CLASS
    class ButtonTemplate:
        def __init__(self,
                     text: str, # The text for the button
                     func=_void, # What the button will do when the user clicks it
                     activeColor: tuple = (255, 255, 0), # The color of the button when the user hovers the cursor over it
                     inactiveColor: tuple = (155, 155, 155), # The color that the button will be when the user doesn't hover over it
                     sizemult: float = 1,
                     selectanim: str = "pop", # The sound that is played when it is hovered over
                     curanim: str = "",
                     isasync: bool = False,
                     xpos: float = 16, # The small the number, the more the text moves right.
                     ypos: float = 2, # The bigger the number, the more the text moves up.
                     x: float = 16, # A duct tape fix to prevent errors with mouse movement detection
                     y: float = 2, # A duct tape fix to prevent errors with mouse movement detection
                     width: float = 28, # A duct tape fix to prevent errors with mouse movement detection
                     height: float = 14, # A duct tape fix to prevent errors with mouse movement detection
                     size: float = 700, # Size "700" appears to be default size. Increasing over "7500" will start to make the launcher unstable.
                     font: str = "GUI/assets/fonts/pixel.ttf" # In case we have a custom font that needs to replace the default, this may be the case for certain languages.
                     ) -> None:

            self.text = text
            self.font = font
            self.function = func
            self.activecolor = activeColor
            self.inactivecolor = inactiveColor
            self.sizemult = sizemult
            self.selectanim = selectanim
            self.curanim = curanim
            self.isasync = isasync
            self.pwrsnd = pygame.mixer.Sound("GUI/assets/sounds/power.wav")
            self.pwrsnd.set_volume(0.25)
            self.blipsnd = pygame.mixer.Sound("GUI/assets/sounds/blip.wav")
            self.blipsnd.set_volume(0.25)
            self.selectsnd = self.pwrsnd
            self.hoversnd = self.blipsnd
            self.xpos = xpos
            self.ypos = ypos
            self.x = x
            self.y = y
            self.width = width
            self.height = height
            self.size = size

    #!############################
    #! Declaring buttons
    #!############################

    def DefineMainMenu(self) -> None:
        self.Button_LaunchGame = self.ButtonTemplate(translations["play_button"], self.Button_LaunchGame_func, (50, 255, 120), isasync=True)
        self.Button_Settings = self.ButtonTemplate(translations["settings_button"], self.Button_Settings_func)
        #self.Button_Data = self.ButtonTemplate(translations["data_menu_button"], self.Button_Data_func, (235, 172, 14)) This will be the buttons position in the list onces its finished
        self.Button_Update = self.ButtonTemplate(translations["update_button"], self.Button_Update_func, (255, 0, 255), isasync=True)
        self.Button_ManualMode = self.ButtonTemplate(translations["manual_mounting_button"], self.Button_ManualMode_func)
        self.Button_Workshop = self.ButtonTemplate(translations["workshop_button"], self.Button_Workshop_func, (14, 216, 235))
        self.Button_ResourcesMenu = self.ButtonTemplate(translations["resources_button"], self.Button_ResourcesMenu_func, (75, 0, 255))
        self.Button_Exit = self.ButtonTemplate(translations["exit_button"], self.Button_Exit_func, (255, 50, 50), isasync=True, selectanim="none")
        self.Text_MainMenuText = self.DisplayText(translations["welcome"], textColor=(255, 234, 0), xpos=870, xstart=870, xend=2000, ypos=20, size=75)
        self.Text_LauncherVersion = self.DisplayText(translations["version"] + self.currentVersion, textColor=(255, 234, 0), xpos=75, xstart=75, xend=750, ypos=735)

        # The DisplayText class needs a seperate table for displaying nonfunction text, this worked better than trying to merge both DisplayText and ButtonTemplate classes
        self.MainMenuText = [self.Text_MainMenuText, self.Text_LauncherVersion] 
        self.MainMenuButtons = [self.Button_LaunchGame, self.Button_Settings, self.Button_Update,
                            self.Button_ManualMode, self.Button_Workshop, self.Button_ResourcesMenu]

        if self.devMode:
            self.Button_Data = self.ButtonTemplate(translations["data_menu_button"], self.Button_Data_func, (235, 172, 14)) # For now Data will be a dev mode button
            self.Button_Test = self.ButtonTemplate("Test Button", self.Button_Test_func)
            self.Text_DevMode = self.DisplayText(translations["dev_mode_enabled"], textColor=(255, 0, 0), xpos=75, xstart=75, xend=750, ypos=770)
            self.MainMenuButtons.append(self.Button_Data)
            self.MainMenuButtons.append(self.Button_Test)
            self.MainMenuText.append(self.Text_DevMode)

        self.MainMenuButtons.append(self.Button_Exit)
        # We don't need the back button in the main menu but I thought it will be better the declare it here -Cabiste
        self.Button_Back = self.ButtonTemplate(
            translations["back_button"], self.Button_Back_func)

    def DefineSettingsMenu(self) -> None:
        self.Button_LauncherSettingsMenu = self.ButtonTemplate(
            translations["launcher_settings_button"], self.Button_LauncherSettingsMenu_func)
        self.Button_Portal2Settings = self.ButtonTemplate(
            translations["portal2_config_button"], self.Button_Portal2Settings_func)
        self.Button_AdminsMenu = self.ButtonTemplate(
            translations["player_button"], self.Button_AdminsMenu_func, (0, 255, 255))
        self.Button_LanguageMenu = self.ButtonTemplate(
            translations["languages_button"], self.Button_LanguageMenu_func, (175, 75, 0))
        self.Text_SettingsLaunchText = self.DisplayText(
            translations["language_menu_launch_text"], textColor=(255, 234, 0), xpos=40, xstart=40, xend=1000, ypos=540, size=75)
        self.Text_SettingsPortal2Text = self.DisplayText(
            translations["language_menu_portal2_text"], textColor=(255, 234, 0), xpos=40, xstart=40, xend=1000, ypos=620, size=75)
        self.Text_SettingsPlayersText = self.DisplayText(
            translations["language_menu_players_text"], textColor=(255, 234, 0), xpos=40, xstart=40, xend=1000, ypos=700, size=75)

        self.SettingsMenus = [self.Button_LauncherSettingsMenu, self.Button_Portal2Settings,
                              self.Button_AdminsMenu, self.Button_LanguageMenu]
        self.SettingsMenuText = [self.Text_SettingsLaunchText, self.Text_SettingsPortal2Text,
                                self.Text_SettingsPlayersText]

        if self.devMode:
            self.Button_HiddenSettings = self.ButtonTemplate(translations["dev_settings_button"], self.Button_DevSettings_func)
            self.SettingsMenus.append(self.Button_HiddenSettings)

        self.SettingsMenus.append(self.Button_Back)

    def DefineDataMenu(self) -> None:
        self.Text_DataSystemStateTxt = self.DisplayText(
            translations["data_system_state_txt"], textColor = (155, 155, 155), xpos=10, xstart=10, xend=1000, ypos=10, size=60)
        if DS.dataSystemState:
            self.Text_DataSystemState = self.DisplayText(
                translations["data_enabled"],
                textColor = (21, 255, 0),
                xpos = 670,
                xstart = 670,
                xend= 6700,
                ypos = 15,
                size = 75)
        else:
            self.Text_DataSystemState = self.DisplayText(
                translations["data_disabled"],
                textColor = (255, 21, 0),
                xpos = 670,
                xstart = 670,
                xend= 6700,
                ypos = 15,
                size = 75)
        self.Button_RefreshDataSystem = self.ButtonTemplate(translations["data_system_refresh"], self.Button_RefreshDataSystem_func)

        self.DataMenuText = [self.Text_DataSystemStateTxt, self.Text_DataSystemState]
        self.DataMenuButtons = [self.Button_RefreshDataSystem, self.Button_Back]

    def DefineWorkshopMenu(self) -> None:
        self.Button_GetWorkShopCommand = self.ButtonTemplate(
            translations["get_level_button"], self.Button_GetWorkShopCommand_func)

        self.WorkshopButtons = [
            self.Button_GetWorkShopCommand, self.Button_Back]

    def DefineManualMountingMenu(self) -> None:
        self.Button_ManualMount = self.ButtonTemplate(
            translations["mount_button"], self.Button_ManualMount_func, (50, 255, 120), isasync=True)
        self.Button_ManualUnmount = self.ButtonTemplate(
            translations["unmount_button"], self.Button_ManualUnmount_func, (255, 50, 50), isasync=True)

        self.ManualButtons = [self.Button_ManualMount,
                              self.Button_ManualUnmount, self.Button_Back]

    def DefineResourcesMenu(self) -> None:
        self.Button_GitHub = self.ButtonTemplate(
            translations["github_button"], self.Button_GitHub_func, (255, 255, 255), isasync=True)
        self.Button_Guide = self.ButtonTemplate(
            translations["guide_button"], self.Button_Guide_func, (35, 35, 50), isasync=True)
        self.Button_Discord = self.ButtonTemplate(
            translations["discord_server_button"], self.Button_Discord_func, (75, 75, 150), isasync=True)

        self.ResourcesButtons = [
            self.Button_GitHub, self.Button_Guide, self.Button_Discord, self.Button_Back]

    def DefineTestingMenu(self) -> None:
        self.Button_InputField = self.ButtonTemplate(
            "User Input", self.Button_InputField_func)
        self.PopupBox_gui = self.ButtonTemplate(
            "Popup Box", self.PopupBox_test_func)
        self.Button_PrintToConsole = self.ButtonTemplate(
            "Print to Console", self.Button_PrintToConsole_func)
        self.Button_Back = self.ButtonTemplate(
            translations["back_button"], self.Button_Back_func)

        self.Text_TestMenuTextTest1 = self.DisplayText(
            "testtext: All default settings")
        self.Text_TestMenuTextTest2 = self.DisplayText(
            "testtext2: textColor=(52, 67, 235), ypos=600", textColor=(52, 67, 235), ypos=600)
        self.Text_TestMenuTextTest3 = self.DisplayText(
            "testtext3: textColor=(214, 30, 17), xpos=600, xstart=600", textColor=(214, 30, 17), xpos=600, xstart=600)
        self.Text_TestMenuTextTest4 = self.DisplayText(
            "testtext4: textColor=(143, 222, 24), xpos=600, xstart=600, ypos=600", textColor=(143, 222, 24), xpos=600, xstart=600, ypos=600)
        self.Text_TestMenuTextTest5 = self.DisplayText(
            "testtext5: textColor=(255, 255, 0), xpos=600, xstart=600, xend=2000, ypos=300", textColor=(255, 255, 0), xpos=600, xstart=600, xend=2000, ypos=300)

        self.TestMenuText = [self.Text_TestMenuTextTest1, self.Text_TestMenuTextTest2, 
                            self.Text_TestMenuTextTest3, self.Text_TestMenuTextTest4,
                            self.Text_TestMenuTextTest5]
        self.TestMenu = [self.Button_InputField, self.PopupBox_gui,
                        self.Button_PrintToConsole, self.Button_Back]

#######################################################################

    def gradientRect(self, window: pygame.Surface, left_colour: tuple, right_colour: tuple, target_rect: pygame.Rect) -> None:
        colour_rect = pygame.Surface((2, 2))  # tiny! 2x2 bitmap
        pygame.draw.line(colour_rect, left_colour, (0, 0),
                         (0, 1))  # left colour line
        pygame.draw.line(colour_rect, right_colour, (1, 0),
                         (1, 1))  # right colour line
        colour_rect = pygame.transform.smoothscale(
            colour_rect, (target_rect.width, target_rect.height))  # stretch!
        window.blit(colour_rect, target_rect)

    def BackMenu(self) -> None:
        if len(self.directorymenu) > 0:
            self.ChangeMenu(self.directorymenu.pop(), self.directorymenutext.pop(), False)

    # the button to go to the previous menu
    def Button_Back_func(self) -> None:
        self.BackMenu()

    def RefreshSettingsMenu(self, menu: str) -> None:
        self.SettingsButtons.clear()

        class curkeyButton:
            def __init__(self, key: str, outerSelf: Gui) -> None:
                self.text = GVars.configData[key]["value"]
                self.mlen = 10
                if len(self.text) > self.mlen:
                    self.text = self.text[:self.mlen] + "..."
                self.text = key + ": " + self.text
                self.cfgkey = key
                self.cfgvalue = GVars.configData[key]["value"]
                self.keyobj = GVars.configData[key]
                self.activecolor = (255, 255, 0)
                self.inactivecolor = (155, 155, 155)
                self.sizemult = 1
                self.outerSelf = outerSelf
                self.size = 700
                self.xpos = 16
                self.ypos = 2
                self.x = 16 # A duct tape fix to prevent errors with mouse movement detection
                self.y = 2 # A duct tape fix to prevent errors with mouse movement detection
                self.width = 28 # A duct tape fix to prevent errors with mouse movement detection
                self.height = 14 # A duct tape fix to prevent errors with mouse movement detection
                self.font = "GUI/assets/fonts/pixel.ttf"
            
            def whileSelectedfunction(self, outerSelf: Gui) -> None:
                outerSelf.BlitDescription(self.keyobj["description"], 75,
                                          520, (130, 130, 255))
                outerSelf.BlitDescription(self.keyobj["warning"], 75, 555, (255, 50, 50))

            selectanim = "pop"
            selectsnd = pygame.mixer.Sound("GUI/assets/sounds/power.wav")
            selectsnd.set_volume(0.25)
            hoversnd = pygame.mixer.Sound("GUI/assets/sounds/blip.wav")
            hoversnd.set_volume(0.25)
            curanim = ""

            def function(self) -> None:
                if self.cfgvalue == "true" or self.cfgvalue == "false":
                    if self.cfgvalue == "false":
                        cfg.EditConfig(self.cfgkey, "true")
                    # default to false to avoid errors
                    else:
                        cfg.EditConfig(self.cfgkey, "false")
                    self.outerSelf.RefreshSettingsMenu(menu)
                    #DS.checkConfigChange()
                    # Put Data System checking here for when a setting changes
                else:
                    def AfterInputGenericSetConfig(inp: str) -> None:
                        cfg.EditConfig(self.cfgkey, inp.strip())
                        Log("Saved '" + inp.strip() +
                            "' to config " + self.cfgkey)
                        self.outerSelf.Error(
                            translations["error_saved"], 5, (75, 200, 75))
                        self.outerSelf.RefreshSettingsMenu(menu)
                        #DS.checkConfigChange()

                    self.outerSelf.GetUserInputPYG(
                        AfterInputGenericSetConfig, self.keyobj["prompt"], self.cfgvalue)

            isasync = False

        for key in GVars.configData:
            if GVars.configData[key]["menu"] == menu:
                Log(str(key) + ": " + str(GVars.configData[key]["value"]))
                self.SettingsButtons.append(curkeyButton(key, self))
        self.SettingsButtons.append(self.Button_Back)

    def RefreshDataMenu(self) -> None:
        Log("Refreshing the data system...")
        DS.dataSystemInitialization(refresh=True)
        self.Error(translations["data_system_refreshing"], 3, (75, 120, 255))
        if DS.dataSystemState == True:
            self.Error(translations["data_system_refresh_success"], 5, (21, 255, 0))
        else:
            self.Error(translations["data_system_refresh_failed"], 5, (255, 21, 0))

    def RefreshPlayersMenu(self) -> None:
        cfg.ValidatePlayerKeys()

        self.PlayersMenu.clear()
        PlayerKey = GVars.configData["Players"]["value"][self.CurrentSelectedPlayer]
        print(PlayerKey)

        # displays and changes the player name
        def Button_PlayerName_func() -> None:
            def AfterInputPlayerName(inp: str) -> None:
                Log("Saving player name: "+ inp)
                cfg.EditPlayer(self.CurrentSelectedPlayer, name=inp.strip())
                self.Error(translations["error_saved"], 5, (75, 200, 75))
                self.RefreshPlayersMenu()

            self.GetUserInputPYG(
                AfterInputPlayerName, translations["players_enter_username"], PlayerKey["name"])

        Button_PlayerName = self.ButtonTemplate(
            translations["players_name"] + PlayerKey["name"], Button_PlayerName_func, (255, 255, 120))

        # sets the steam id for the player
        def Button_PlayerSteamId_func() -> None:
            def AfterInputSteamID(inp: str) -> None:
                Log("Saving SteamID: " + str(inp))

                if not (inp.isdigit()):
                    try:
                        # this is only useful if the user gives a steamID2
                        inp = Converter.to_steamID3(inp.strip())
                        # replace all [] with ""
                        inp = inp.replace("[", "").replace("]", "")
                        # only get everything after the last ":"
                        inp = inp.split(":")[-1]
                        self.Error(
                            translations["players_converted_steamid"], 5, (75, 120, 255))
                    except Exception as e:
                        self.Error(
                            translations["players_invalid_steamid"], 5, (255, 50, 50))
                        Log(str(e))
                        return

                cfg.EditPlayer(self.CurrentSelectedPlayer, steamId=inp)
                self.Error(translations["error_saved"], 5, (75, 200, 75))
                self.RefreshPlayersMenu()

            self.GetUserInputPYG(
                AfterInputSteamID, "Enter A SteamID", PlayerKey["steamid"])

        Button_PlayerSteamId = self.ButtonTemplate(
            "SteamID: " + PlayerKey["steamid"], Button_PlayerSteamId_func, (255, 255, 120))

        # sets the admin level for th player

        def Button_AdminLevel_func() -> None:
            def AfterInputAdminLevel(inp: str) -> None:

                if not inp.isdigit():
                    self.Error(
                        translations["players_admin_error_not-a-number"], 5, (255, 50, 50))
                    return

                if int(inp) > 6 or int(inp) < 0:
                    self.Error(
                        translations["admin_level_error_out-of-range"], 5, (255, 255, 50))
                    return

                # here i'm converting to int then to str so it removes all the extra 0s on the left side (05 -> 5)
                cfg.EditPlayer(self.CurrentSelectedPlayer, level=str(int(inp)))
                self.Error(translations["error_saved"], 5, (75, 200, 75))
                Log("Saving admin level as " + str(inp))
                self.RefreshPlayersMenu()

            self.GetUserInputPYG(
                AfterInputAdminLevel, translations["players_admin-enter-admin-level"], PlayerKey["adminlevel"])

        Button_AdminLevel = self.ButtonTemplate(
            translations["players_admin_level"] + PlayerKey["adminlevel"], Button_AdminLevel_func, (255, 255, 120))

        # changes the view to the next player
        def Button_NextPlayer_func() -> None:

            if self.CurrentSelectedPlayer < len(GVars.configData["Players"]["value"]) - 1:
                Log("Next player")
                self.CurrentSelectedPlayer += 1
            else:
                Log("No more players")
                self.CurrentSelectedPlayer = 0

            self.RefreshPlayersMenu()
            self.ChangeMenu(self.PlayersMenu, append=False)

        Button_NextPlayer = self.ButtonTemplate(
            translations["players_next_button"], Button_NextPlayer_func, (255, 255, 120))

       # adds a player to the list
        def Button_AddPlayer_func() -> None:

            Log("Adding blank player...")
            GVars.configData["Players"]["value"].append(cfg.defaultplayerarray)
            cfg.WriteConfigFile(GVars.configData)
            Log(str(len(GVars.configData["Players"]["value"]) - 1))
            self.CurrentSelectedPlayer = len(
                GVars.configData["Players"]["value"]) - 1
            self.RefreshPlayersMenu()

        Button_AddPlayer = self.ButtonTemplate(
            translations["players_add_player"], Button_AddPlayer_func, (120, 255, 120))

        # deletes a player from the list
        def Button_DeletePlayer_func() -> None:

            if len(GVars.configData["Players"]["value"]) <= 1:
                self.Error(
                    translations["players_error_must_be_at_least_one_player"], 5, (255, 50, 50))
                return

            Log("Deleting player...")
            cfg.DeletePlayer(self.CurrentSelectedPlayer)
            self.CurrentSelectedPlayer -= 1
            self.RefreshPlayersMenu()

        Button_DeletePlayer = self.ButtonTemplate(
            translations["players_remove_player"], Button_DeletePlayer_func, (255, 50, 50))

        ####################
        self.PlayersMenu.append(Button_PlayerName)
        self.PlayersMenu.append(Button_PlayerSteamId)
        self.PlayersMenu.append(Button_AdminLevel)
        self.PlayersMenu.append(Button_NextPlayer)
        self.PlayersMenu.append(Button_AddPlayer)
        self.PlayersMenu.append(Button_DeletePlayer)
        self.PlayersMenu.append(self.Button_Back)

    #!############################
    #! MAIN BUTTONS FUNCTIONS
    #!############################

    # launches the game

    def Button_LaunchGame_func(self) -> None:
        if self.coolDown > 0:
            return

        self.coolDown = int(3 * 60)
        RunGameScript()

    # switches to the settings menu

    def Button_Settings_func(self) -> None:
        self.ChangeMenu(self.SettingsMenus, self.SettingsMenuText)

    # switches to the data menu

    def Button_Data_func(self) -> None:
        self.ChangeMenu(self.DataMenuButtons, self.DataMenuText)
        self.RefreshDataMenu()

    # launcher update button

    def Button_Update_func(self) -> None:
        if self.coolDown > 0:
            return

        self.coolDown = int(3 * 60)

        if not CheckForUpdates():
            self.Error(
                translations["update_already_up_to_date"], 5, (200, 75, 220))

    # switches to the manual mod un/mounting menu

    def Button_ManualMode_func(self) -> None:
        self.ChangeMenu(self.ManualButtons, append=True)

    # switches to the workshop menu

    def Button_Workshop_func(self) -> None:
        self.ChangeMenu(self.WorkshopButtons, append=True)

    # switches to the resources menu (github, discord etc...)

    def Button_ResourcesMenu_func(self) -> None:
        self.ChangeMenu(self.ResourcesButtons, append=True)

    # it closes the game

    def Button_Exit_func(self) -> None:
        self.running = False

    #!############################
    #! SETTINGS BUTTONS FUNCTIONS
    #!############################

    # switches to the launcher specific settings

    def Button_LauncherSettingsMenu_func(self) -> None:
        self.RefreshSettingsMenu("launcher")
        self.ChangeMenu(self.SettingsButtons, append=True)

    # switches to the portal 2 sepcific settings

    def Button_Portal2Settings_func(self) -> None:
        self.RefreshSettingsMenu("portal2")
        self.ChangeMenu(self.SettingsButtons, append=True)

    # switches to the player menu where you can add admins

    def Button_AdminsMenu_func(self) -> None:
        self.RefreshPlayersMenu()
        self.ChangeMenu(self.PlayersMenu, append=True)

    # switches to the language menu where you can pick a language for the launcher

    def Button_LanguageMenu_func(self) -> None:
        # for choosing a languages
        self.LanguageButton()
        self.ChangeMenu(self.LanguagesMenu, append=True)

    # shows the dev settings

    def Button_DevSettings_func(self) -> None:
        self.RefreshSettingsMenu("dev")
        self.ChangeMenu(self.SettingsButtons, append=True)

    #!############################
    #! SAVES BUTTONS FUNCTIONS
    #!############################

    def Button_RefreshDataSystem_func(self) -> None:
        self.RefreshDataMenu()

    #!############################
    #! MANUAL MODE BUTTONS FUNCTIONS
    #!############################

    # a button for manual mounting

    def Button_ManualMount_func(self) -> None:
        if self.coolDown > 0:
            return

        self.coolDown = int(3 * 60)
        MountModOnly()

    # a button for manual unmounting

    def Button_ManualUnmount_func(self) -> None:
        if self.coolDown > 0:
            return

        self.coolDown = int(3 * 60)
        UnmountScript()

    #!############################
    #! WORKSHOP BUTTONS FUNCTIONS
    #!############################

    # get's the id from a map's url then copies the changelevel command to the clipboard

    def Button_GetWorkShopCommand_func(self) -> None:
        def AfterInput(input: str):
            map = workshop.MapFromSteamID(input)

            if map is not None:
                pyperclip.copy("changelevel " + map)
                self.Error(
                    translations["workshop_changelevel_command"], 3, (255, 0, 255))
                self.Error(
                    translations["workshop_copied_to_clipboard"], 3, (0, 255, 0))
                return

            self.Error(translations["workshop_map_not_found"])
            self.Error(
                translations["workshop_sentence0_sure-you-are-sub"], 6, (255, 255, 0))
            self.Error(
                translations["workshop_sentence0_to-map-and-play-it"], 6, (255, 255, 0))
            self.Error(
                translations["workshop_sentence0_least-once"], 6, (255, 255, 0))

        self.GetUserInputPYG(AfterInput, translations["workshop_link"])

    #!############################
    #! RESOURCES BUTTONS FUNCTIONS
    #!############################

    # opens the github repo in the browser

    def Button_GitHub_func(self) -> None:
        # open the discord invite in the default browser
        webbrowser.open(
            "https://github.com/kyleraykbs/Portal2-32PlayerMod#readme")

    # this simply opens the steam guide

    def Button_Guide_func(self) -> None:
        # open the steam guide in the default browser
        webbrowser.open(
            "https://steamcommunity.com/sharedfiles/filedetails/?id=2458260280")

    # opens the browser to an invite to the discord server

    def Button_Discord_func(self) -> None:
        # open the discord invite in the default browser
        webbrowser.open("https://discord.com/invite/kW3nG6GKpF")

    #!############################
    #! TESTING BUTTONS FUNCTIONS
    #!############################

    # a button for testing stuff

    def Button_Test_func(self) -> None:
        self.ChangeMenu(self.TestMenu, self.TestMenuText, True)


#! END OF BUTTON FUNCTIONS

    # I but editting this function we can have DisplayText keep to it's assigned menu, but I could be wrong, Cabiste knows more about this than I do -Orsell
    def ChangeMenu(self, menu: list, text: list = [], append: bool = True) -> None:
        if append:
            self.directorymenu.append(self.CurrentMenuButtons)
            self.directorymenutext.append(self.CurrentMenuText)

        self.CurrentMenuButtons = menu
        self.CurrentMenuText = text

        if self.CurrentButtonsIndex >= len(menu):
            self.CurrentButtonsIndex = len(menu) - 1

        if self.CurrentMenuTextIndex >= len(text):
            self.CurrentMenuTextIndex = len(text) - 1

        self.SelectedButton = self.CurrentMenuButtons[self.CurrentButtonsIndex]

    ####################

    # input field
    def Button_InputField_func(self) -> None:
        def AfterInput(input) -> None:
            self.Error("Input: " + input, 3, (255, 255, 0))
        self.GetUserInputPYG(AfterInput)

    #######################

    # this is a test for the popup box

    def PopupBox_test_func(self) -> None:
        def YesInput() -> None:
            self.Error(translations["error_yes"], 3, (75, 255, 75))

        def NoInput() -> None:
            self.Error(translations["error_no"], 3, (255, 75, 75))

        Button_Confirm = self.ButtonTemplate(
            translations["error_yes"], YesInput, (75, 200, 75))
        Button_Decline = self.ButtonTemplate(
            translations["error_no"], NoInput, (255, 75, 75))
        self.PopupBox("Trolling Time!?!?!", "Have you given Cabiste an\naneruism today?",
                      [Button_Confirm, Button_Decline])

    def Button_PrintToConsole_func(self) -> None:
        print(GVars.modPath)
        print(GVars.configPath)

    ################################

    def SelectAnimation(self, btn: ButtonTemplate, anim: str) -> None:
        if anim == "pop":
            btn.curanim = "pop1"

    def RunAnimation(self, button: ButtonTemplate, anim: str) -> None:
        if anim == "pop1":
            if button.sizemult < 1.3:
                button.sizemult += 0.1
            else:
                button.curanim = "pop2"
        if anim == "pop2":
            if button.sizemult > 1:
                button.sizemult -= 0.1
            else:
                button.sizemult = 1
                button.curanim = ""

    def BlitDescription(self, 
            txt: str, 
            x: float = None, 
            y: float = None,
            clr: tuple = (255, 255, 255)) -> None:

        if x is None:
            x = self.screen.get_width() / 16
        if y is None:
            y = self.screen.get_height() / 16
        
        if (len(txt) > 0):
            text = pygame.font.Font("GUI/assets/fonts/pixel.ttf", int(int(
                int((int(self.screen.get_width() / 15) + int(self.screen.get_height() / 25)) / (len(txt) * 0.1))))).render(txt, True, clr)
            if not (self.LookingForInput):
                self.screen.blit(text, (x, y))

    def GetUserInputPYG(self, 
        afterfunc=None, 
        prompt: list = [], 
        preinput: str = "") -> None:

        Log("Getting user input...")
        self.LookingForInput = True
        self.CurInput = preinput

        # We need to check for "\n"s in the prompt that is supplied
        # If there is then we will seperate each part of text into a table
        breaktxt = "\n"
        self.HasBreaks = False
        self.PromptBreaks = 0
        if breaktxt in prompt:
            self.HasBreaks = True
            prompt = prompt.split("\n")
            for breaktxt in prompt:
                self.PromptBreaks += 1
                print(breaktxt)
                print(self.PromptBreaks)
            print(prompt)
            self.InputPrompt = str(prompt)
        else:
            print(prompt)
            self.InputPrompt = str(prompt)
            
        self.AfterInputFunction = afterfunc
        Log("AfterInputFunction: " + str(self.AfterInputFunction))

    def Error(self, text: str, time: int = 3, color: tuple = (255, 75, 75)) -> None:
        Log(text)

        if "\n" not in text:
            self.ERRORLIST.append([text, time, color])
            return

        # if the text has newlines, split it up
        text = text.split("\n")
        for i in range(0, len(text)):
            self.ERRORLIST.append([text[i], time, color])

    def PopupBox(self, title: str, text: str, buttons: list) -> None:

        # MANUAL #
        # title = "A String Title For The Box"
        # text = "A String Of Text To Display In The Box (use \n for newlines)"
        # buttons = [["Button Text", "Button Function"], ["Button Text", "Button Function"], etc, etc.....]
        ##########

        self.selectedpopupbutton = buttons[0]

        PopupBox = [title, text, buttons]  # TITLE, TEXT, BUTTONS
        Log("Creating popup box... Tile: " + str(title) +
            " Text: " + text + " Buttons: " + str(buttons))
        self.PopupBoxList.append(PopupBox)

    # the language button (English, French, etc...)
    def Button_Language_func(self) -> None:
        lang: str = self.LanguagesMenu[self.CurrentButtonsIndex].text.replace(
            "→ ", "")
        Log("Language set: " + lang)
        cfg.EditConfig("Active-Language", lang)
        LoadTranslations()
        self.__init__(self.devMode)
        self.Error(translations["language_error0_language_update"])

    def LanguageButton(self) -> None:
        self.LanguagesMenu.clear()
        Languages = GetAvailableLanguages()
        for language in Languages:
            if GVars.configData["Active-Language"]["value"] == language:
                language = "→ " + language

            self.LanguagesMenu.append(self.ButtonTemplate(
                language, self.Button_Language_func, (150, 150, 255)))

        self.LanguagesMenu.append(self.Button_Back)

    ###############################################################################

    def Update(self) -> None:
        W = self.screen.get_width()
        H = self.screen.get_height()
        clr = (0, 0, 0)
        fntdiv: int = 32
        fntsize = int(W / fntdiv)
        mindiv = int(fntdiv / 1.25)

        # DEBUG

        # tempsurf = pygame.font.Font("GUI/assets/fonts/pixel.ttf", int(int((int(W / 25) + int(H / 50)) / 1.5))).render("CuM", True, (255, 100, 255))
        # screen.blit(tempsurf, (mousex - tempsurf.get_width()/2, mousey - tempsurf.get_height()/2))

        # MENU 2 ELECTRIC BOOGALOO
        # loop through all buttons
        indx = 0

        for button in self.CurrentMenuButtons:
            indx += 1
            button.width = int(button.size / 25)
            button.height = int(button.size / 50)

            if button == self.SelectedButton:
                clr = button.activecolor
            else:
                clr = button.inactivecolor
            self.RunAnimation(button, button.curanim)

            text1 = pygame.font.Font(button.font, (button.width + button.height)).render(button.text, True, clr)

            if not (self.LookingForInput):
                self.screen.blit(
                    text1, (W / button.xpos, (H / button.ypos - (text1.get_height() / 2)) * (indx / 5)))
            #button.x = W / 16
            #button.y = (H / 2 - (text1.get_height() / 2)) * (indx / 5)
            button.x = W / button.xpos
            button.y = ((H / button.ypos) - (text1.get_height() / 2)) * (indx / 5)
            button.width = text1.get_width()
            button.height = text1.get_height()

        # TEXT DISPLAYED ON MENU
        for displaytext in self.CurrentMenuText:
            # We need to check for "\n"s in the prompt that is supplied
            # If there is then we will seperate each part of text into a table
            # breaktxt = "\n"
            # TextBreaks = 0
            # displaytext.width = int(W / displaytext.size)
            # displaytext.height = int(H / displaytext.size)
            # if breaktxt in displaytext.text:
            #     text = (displaytext.text).split("\n")
            #     for breaktxt in text:
            #         TextBreaks += 1
            #         print("Text Piece:" + breaktxt)
            #         print("Num of Breaks:" + str(TextBreaks))
            #     breaks = 0
            #     for breaks in range(0, TextBreaks):
            #         displaytextsurf = pygame.font.Font("GUI/assets/fonts/pixel.ttf", 
            #             (displaytext.width + displaytext.height)).render(text[breaks], True, displaytext.textColor)
            #         self.screen.blit(displaytextsurf, (displaytext.xpos, ((displaytext.ypos * breaks))))
            #         print(breaks)
            # else:
            #     displaytextsurf = pygame.font.Font("GUI/assets/fonts/pixel.ttf", 
            #             (displaytext.width + displaytext.height)).render(displaytext.text, True, displaytext.textColor)
            #     self.screen.blit(displaytextsurf, (displaytext.xpos, displaytext.ypos))
            displaytext.width = int(W / displaytext.size)
            displaytext.height = int(H / displaytext.size)
            text = pygame.font.Font("GUI/assets/fonts/pixel.ttf", (displaytext.width + displaytext.height))
            words = [word.split(' ') for word in displaytext.text.splitlines()]  # 2D array where each row is a list of words.
            space = text.size(' ')[0]  # The width of a space.
            max_width = displaytext.xend
            max_height = H
            x = displaytext.xpos
            y = displaytext.ypos
            # This code will wrap any text that goes off screen, thanks Stack Overflow for this :)
            for line in words:
                for word in line:
                    word_surface = text.render(word, True, displaytext.textColor)
                    word_width, word_height = word_surface.get_size()
                    if x + displaytext.xstart >= max_width:
                        x = displaytext.xstart  # Reset the x.
                        y += word_height  # Start on new row.
                    self.screen.blit(word_surface, (x, y))
                    x += word_width + space
                x = displaytext.xstart
                y += word_height
                

        # BACKGROUND
        for floater in self.Floaters:
            surf = floater.surf
            if (self.SelectedButton.text == translations["unmount_button"] or self.SelectedButton.text == translations["exit_button"]):
                surf = self.redcube
            if (self.SelectedButton.text == translations["back_button"]):
                surf = self.goldencube
            surf = pygame.transform.scale(surf, (W / 15, W / 15))
            surf = pygame.transform.rotate(surf, floater.rot)
            center = surf.get_rect().center
            LauncherCubes = GVars.configData["Launcher-Cubes"]["value"] == "true"
            if (LauncherCubes):
                self.screen.blit(
                    surf, (floater.x - center[0], floater.y - center[1]))
            if floater.negrot:
                floater.rot -= (1 + random.randint(0, 2))
            else:
                floater.rot += (1 + random.randint(0, 2))
            if (self.SelectedButton.text == translations["back_button"]):
                floater.x -= W / 60
                if floater.x < (floater.surf.get_width() * -2):
                    floater.y = random.randint(0, H)
                    floater.x = (floater.surf.get_width() * 2) + \
                        (random.randint(W, W * 2)) * 1
                    floater.negrot = random.randint(0, 1) == 1
            elif (self.SelectedButton.text == translations["unmount_button"] or self.SelectedButton.text == translations["exit_button"]):
                floater.y -= H / 60
                if floater.y < (floater.surf.get_height() * -2):
                    floater.y = (floater.surf.get_height() * 2) + \
                        (random.randint(H, H * 2))
                    floater.x = random.randint(0, W)
                    floater.negrot = random.randint(0, 1) == 1
            else:
                floater.y += H / 60
                if floater.y > (H + floater.surf.get_height() * 2):
                    floater.y = (floater.surf.get_height() * -2) + \
                        (random.randint(0, H)) * -1
                    floater.x = random.randint(0, W)
                    floater.negrot = random.randint(0, 1) == 1

        # Put assets/images/keys.png on the top right corner of the screen
        keys = pygame.image.load("GUI/assets/images/keys.png").convert_alpha()
        keys = pygame.transform.scale(keys, (W / 10, W / 10))
        self.screen.blit(keys, ((W / 1.05) - keys.get_width(), H / 1.25))

        # MENU

        self.SelectedButton = self.CurrentMenuButtons[self.CurrentButtonsIndex]

        # OVERLAY

        indx = 0
        for error in self.ERRORLIST[::-1]:
            indx += 1
            errortext = pygame.font.Font("GUI/assets/fonts/pixel.ttf", int(int(W / 60) + int(H / 85))).render(error[0],
                                                                                                              True,
                                                                                                              error[2])
            self.screen.blit(
                errortext, (W / 30, ((errortext.get_height() * indx) * -1) + (H / 1.05)))

        # every 1 second go through each error and remove it if it's been there for more than 1 second
        if (time.time() - self.SecAgo) > 1:
            for error in self.ERRORLIST:
                if (error[1] < 0):
                    self.ERRORLIST.remove(error)
                error[1] -= 1
            self.SecAgo = time.time()

        try:
            # if self.CurrentMenu == setti
            self.SelectedButton.whileSelectedfunction(self)

        except Exception as e:
            # Log(str(e))
            pass

        # DRAW POPUP BOX
        if len(self.PopupBoxList) > 0:
            sz = 1.25

            # draw a white box that is half the width and height of the screen
            boxbackground = pygame.Surface((W / sz, W / (sz * 2)))
            boxbackground.fill((255, 255, 255))
            boxbackground.set_alpha(175)
            self.screen.blit(boxbackground, (W / 2 - (boxbackground.get_width() / 2),
                                             H / 2 - (boxbackground.get_height() / 2)))

            bw = boxbackground.get_width()
            bh = boxbackground.get_height()
            bx = W / 2 - (bw / 2)
            by = H / 2 - (bh / 2)

            # put the title in the box
            boxtitle = pygame.font.Font("GUI/assets/fonts/pixel.ttf", fntsize).render(self.PopupBoxList[0][0], True,
                                                                                      (255, 255, 0))
            titlew = boxtitle.get_width()
            titleh = boxtitle.get_height()
            titlex = bx + (bw / 2) - (titlew / 2)
            titley = by + (titleh / 2)
            self.screen.blit(boxtitle, (titlex, titley))

            # put the text in the box
            ctext = self.PopupBoxList[0][1].split("\n")
            indx = 0
            for line in ctext:
                text = pygame.font.Font(
                    "GUI/assets/fonts/pixel.ttf", int(fntsize / 1.5)).render(line, True, (0, 0, 0))
                textw = text.get_width()
                texth = text.get_height()
                textx = bx + (bw / 2) - (textw / 2)
                texty = by + (titleh * 2) + (texth * indx)
                self.screen.blit(text, (textx, texty))
                indx += 1

            # put the buttons in the box
            amtob = len(self.PopupBoxList[0][2])
            indx = 0
            for button in self.PopupBoxList[0][2]:
                buttonsurf = pygame.surface.Surface(
                    ((bw / amtob) / 1.2, (bh / 5)))
                if (button == self.selectedpopupbutton):
                    buttonsurf.fill(button.activecolor)
                else:
                    buttonsurf.fill(button.inactivecolor)
                surfw = buttonsurf.get_width()
                surfh = buttonsurf.get_height()
                surfx = bx + (bw / amtob) * indx + \
                    (bw / amtob) / 2 - (surfw / 2)
                surfy = by + bh - (bh / 4)
                button.x = surfx
                button.y = surfy
                button.width = surfw
                button.height = surfh
                self.screen.blit(buttonsurf, (surfx, surfy))

                text = pygame.font.Font("GUI/assets/fonts/pixel.ttf", int(fntsize / 1.5)).render(button.text, True,
                                                                                                 (255, 255, 255))
                textw = text.get_width()
                texth = text.get_height()
                textx = bx + (bw / amtob) * (indx) + \
                    ((bw / amtob) / 2) - (textw / 2)
                texty = by + bh - (bh / 5) + (texth / 2)
                self.screen.blit(text, (textx, texty))
                indx += 1

        # DRAW INPUT BOX
        if self.LookingForInput:
            # divide the CurrentInput into lines
            lines = []
            # every  23 characters, add a new line
            lines.append(self.CurInput[0:mindiv])
            for i in range(mindiv, len(self.CurInput), mindiv):
                lines.append(self.CurInput[i:i + mindiv])

            InputText = ""
            for i in range(len(lines)):
                InputText = pygame.font.Font(
                    "GUI/assets/fonts/pixel.ttf", fntsize).render(lines[i], True, (255, 255, 175))
                self.screen.blit(InputText, (W / 2 - (InputText.get_width() / 2), (
                    (((H / 2) - (InputText.get_height() * 1.25)) + ((text1.get_height() * 1.25) * i))) - (
                    (((text1.get_height() * 1.25) * (len(lines) / 2))))))

            surf1 = pygame.Surface((W / 1.5, W / 100))
            surf1.fill((255, 255, 255))
            surf2 = pygame.Surface((W / 1.5, W / 100))
            blitpos = (
                (W / 2) - (surf2.get_width() / 2), (H / 2) + ((InputText.get_height() * 1.725) * ((len(lines) / 2) - 1)))
            self.screen.blit(surf1, blitpos)
            if self.HasBreaks == True:
                breaks = 0
                for breaks in range(0, self.PromptBreaks):
                    surfInputPrompt = pygame.font.Font("GUI/assets/fonts/pixel.ttf", 
                        int(fntsize/1.5)).render(self.InputPrompt[breaks], True, (255, 255, 255))
                    
                    # blit it right below the surf1
                    self.screen.blit(surfInputPrompt, 
                            (blitpos[0] + (surf1.get_width() / 2) - (surfInputPrompt.get_width() / 2),
                            ((blitpos[1] + 15)+ (surfInputPrompt.get_height() * breaks))))             
            else:
                surfInputPrompt = pygame.font.Font("GUI/assets/fonts/pixel.ttf", 
                        int(fntsize/1.5)).render(self.InputPrompt, True, (255, 255, 255))
                    
                # blit it right below the surf1
                self.screen.blit(surfInputPrompt, 
                        (blitpos[0] + (surf1.get_width() / 2) - (surfInputPrompt.get_width() / 2),
                        (blitpos[1] + surfInputPrompt.get_height())))
            
    ###############################################################################

    def Main(self) -> None:
        LastBackspace = 0
        discordPresenceCount = 0
        discordPresenceRefreshCount = 0
        while self.running:
            mouse = pygame.mouse.get_pos()
            mousex = mouse[0]
            mousey = mouse[1]

            # make the screen a gradient
            self.screen.fill((0, 0, 0))
            self.gradientRect(self.screen, (0, 2, 10), (2, 2, 10), pygame.Rect(
                0, 0, self.screen.get_width(), self.screen.get_height()))
            self.Update()
            pygame.display.update()
            self.fpsclock.tick(self.FPS)

            if self.coolDown > 0:
                self.coolDown -= 1

            # so you can hold backspace to delete
            if (self.LookingForInput):
                BACKSPACEHELD = pygame.key.get_pressed()[pygame.K_BACKSPACE]
                if (BACKSPACEHELD):
                    LastBackspace += 0.25
                # if its been a second since the last backspace, delete the last character
                if (LastBackspace >= 1):
                    if (len(self.CurInput) > 0):
                        self.CurInput = self.CurInput[:-1]
                    LastBackspace = 0

            for event in pygame.event.get():
                if event.type == QUIT:
                    self.running = False

                # INPUT BOX INPUT
                if (self.LookingForInput):
                    CTRLHELD = pygame.key.get_mods() & pygame.KMOD_CTRL
                    SHIFTHELD = pygame.key.get_mods() & pygame.KMOD_SHIFT

                    if event.type == pygame.KEYDOWN:
                        # get the key and add it to self.CurInput
                        name = pygame.key.name(event.key)
                        if name == "space":
                            self.CurInput += " "
                        elif name in ["return", "enter"]:
                            self.LookingForInput = False
                            self.AfterInputFunction(self.CurInput)
                        elif name == "escape":
                            self.LookingForInput = False
                        elif name == "tab":
                            self.CurInput += "    "
                        elif CTRLHELD and name == "v":
                            try:
                                str1 = str(tk.selection_get(
                                    selection="CLIPBOARD")).replace("\n", "")
                                Log(f"Pasted: {str1}")
                                self.CurInput += str1
                            except Exception as e:
                                Log(str(e))  # always log the error
                                pass
                        elif len(name) == 1:
                            if SHIFTHELD:
                                # if the name doesnt contain a letter
                                if not name.isalpha():
                                    name = name.replace("1", "!").replace("2", "@").replace("3", "#").replace("4",
                                                                                                              "$").replace(
                                        "5", "%").replace("6", "^").replace("7", "&").replace("8", "*").replace("9",
                                                                                                                "(").replace(
                                        "0", ")").replace("`", "~").replace("-", "_").replace("=", "+").replace("[",
                                                                                                                "{").replace(
                                        "]", "}").replace("\\", "|").replace(";", ":").replace("'", "\"").replace(",",
                                                                                                                  "<").replace(
                                        ".", ">").replace("/", "?")
                                # convert lowercase to uppercase
                                else:
                                    name = name.upper()
                                self.CurInput += name
                            else:
                                self.CurInput += name
                        # support for numpad
                        elif len(name) == 3:
                            self.CurInput += name[1]

                # POPUP BOX INPUT
                if len(self.PopupBoxList) > 0:
                    boxlen = len(self.PopupBoxList[0][2])
                    if event.type == KEYDOWN:
                        if event.key == K_ESCAPE:
                            self.PopupBoxList.pop()

                        if event.key == K_RIGHT:
                            for btn in self.PopupBoxList[0][2]:
                                if btn == self.selectedpopupbutton:
                                    if self.PopupBoxList[0][2].index(btn) < boxlen - 1:
                                        self.selectedpopupbutton = self.PopupBoxList[0][2][self.PopupBoxList[0][2].index(
                                            btn) + 1]

                        elif event.key == K_LEFT:
                            for btn in self.PopupBoxList[0][2]:
                                if btn == self.selectedpopupbutton:
                                    if self.PopupBoxList[0][2].index(btn) > 0:
                                        self.selectedpopupbutton = self.PopupBoxList[0][2][self.PopupBoxList[0][2].index(
                                            btn) - 1]

                        elif event.key == K_SPACE or event.key == K_RETURN:
                            self.selectedpopupbutton.function()
                            self.PopupBoxList.pop()

                    elif event.type == MOUSEBUTTONDOWN:
                        # if the mouse is over a button
                        for btn in self.PopupBoxList[0][2]:
                            if (btn.x < mousex < btn.x + btn.width) and (btn.y < mousey < btn.y + btn.height):
                                self.selectedpopupbutton = btn
                                self.selectedpopupbutton.function()
                                self.PopupBoxList.pop()
                                break

                # NORMAL INPUT
                if event.type == KEYDOWN:
                    if event.key in [K_ESCAPE, K_BACKSPACE]:
                        self.BackMenu()
                    elif event.key in [K_DOWN, K_s]:
                        if self.CurrentButtonsIndex < len(self.CurrentMenuButtons) - 1:
                            self.CurrentButtonsIndex += 1
                            self.SelectedButton = self.CurrentMenuButtons[self.CurrentButtonsIndex]
                            self.PlaySound(self.SelectedButton.hoversnd)
                        else:
                            self.CurrentButtonsIndex = 0
                            self.SelectedButton = self.CurrentMenuButtons[self.CurrentButtonsIndex]
                            self.PlaySound(self.SelectedButton.hoversnd)
                    elif event.key in [K_UP, K_w]:
                        if self.CurrentButtonsIndex > 0:
                            self.CurrentButtonsIndex -= 1
                            self.SelectedButton = self.CurrentMenuButtons[self.CurrentButtonsIndex]
                            self.PlaySound(self.SelectedButton.hoversnd)
                        else:
                            self.CurrentButtonsIndex = len(
                                self.CurrentMenuButtons) - 1
                            self.SelectedButton = self.CurrentMenuButtons[self.CurrentButtonsIndex]
                            self.PlaySound(self.SelectedButton.hoversnd)
                    elif event.key in [K_SPACE, K_RETURN, K_KP_ENTER]:
                        self.SelectAnimation(
                            self.SelectedButton, self.SelectedButton.selectanim)
                        if self.SelectedButton.function:
                            if self.SelectedButton.isasync:
                                threading.Thread(
                                    target=self.SelectedButton.function).start()
                            else:
                                self.SelectedButton.function()

                        self.PlaySound(self.SelectedButton.selectsnd)

                # LMB
                # executes the button's function on left mouse click IF the mouse is above the button
                if event.type == pygame.MOUSEBUTTONDOWN:
                    if event.button == 1:
                        button = self.SelectedButton
                        if (mousex > button.x and mousex < button.x + button.width) and (mousey > button.y and mousey < button.y + button.height):
                            if self.SelectedButton.function:
                                if self.SelectedButton.isasync:
                                    threading.Thread(
                                        target=self.SelectedButton.function).start()
                                else:
                                    self.SelectedButton.function()

                            self.SelectAnimation(
                                self.SelectedButton, self.SelectedButton.selectanim)

                            self.PlaySound(self.SelectedButton.selectsnd)

                ###############################
                # changes the `SelectedButton` and the `CurrentButtonsIndex` to the button the mouse is on
                if event.type == pygame.MOUSEMOTION:
                    for button in self.CurrentMenuButtons:
                        # if the mouse is over the button
                        if (mousex > button.x and mousex < button.x + button.width) and (mousey > button.y and mousey < button.y + button.height):
                            # if the button isnt already selected
                            if button != self.SelectedButton:
                                # select the button
                                self.SelectedButton = button
                                # set current buttons index to the button
                                self.CurrentButtonsIndex = self.CurrentMenuButtons.index(
                                    button)
                                # play the hover sound
                                self.PlaySound(self.hvrclksnd)

            ###############################
            # changes the color of the hovered button in the popup box
            if len(self.PopupBoxList) > 0:
                for button in self.PopupBoxList[0][2]:
                    # if the mouse is over the button
                    if ((mousex > button.x and mousex < button.x + (button.size / 25)) and (mousey > button.y and mousey < button.y + (button.size / 50))):
                        if button != self.selectedpopupbutton:
                            self.selectedpopupbutton = button
                            self.PlaySound(button.hoversnd)

            discordPresenceCount += 1 # Every frame we will add to the counter, every 60 frame is a second
            if discordPresenceCount == int(60 * 15): # Every 15 seconds we will update the Discord Rich Presence and check if Discord is still running or not
                DRP.updateRichPresence()
                discordPresenceCount = 0

        PreExit()

        pygame.quit()
        os._exit(0)

# !######################################################
# !                       Logic
# !######################################################

def PreExit() -> None:
    Log("Shutting down the P2MM launcher...")
    Log("Shutting down Portal 2...")
    # windows
    if (GVars.iow):
        os.system("taskkill /f /im portal2.exe")

    # linux
    if (GVars.iol) or (GVars.iosd):
        os.system("killall -9 portal2_linux")

    # this is to make sure the portal 2 thread is dead
    # 1 second should be enough for it to die
    time.sleep(1)
    Log("Portal 2 has been shutdown...")

    # Make sure the P2MM ModFiles are unmounted from Portal 2
    if (GVars.configData["Auto-Umount"]["value"] == "true"):
        Log("Unmounting P2MM's ModFiles from Portal 2...")
        UnmountScript(False)
        Ui.Error(translations["unmounted_error"], 5, (125, 0, 125))
        Log("Unmounted P2MM's ModFiles from Portal 2...")
    
    # Wrap up Discord Rich Presence by closing the connection
    DRP.shutdownRichPresence()
    Log("The P2MM launcher has been shutdown...")

def GetGamePath() -> None:
    tmpp = BF.TryFindPortal2Path()

    if tmpp:
        cfg.EditConfig("Portal2-Path", tmpp.strip())
        Log("Saved '" + tmpp.strip() + "' as the game path!")
        Ui.Error(translations["game_path_error-founded"], 5, (255, 255, 75))
        VerifyGamePath()
        return

    def AfterInputGP(inp) -> None:
        cfg.EditConfig("Portal2-Path", inp.strip())
        Log("Saved '" + inp.strip() + "' as the game path!")
        Ui.Error(translations["game_path_error-saved"], 5, (75, 200, 75))
        VerifyGamePath()

    Ui.GetUserInputPYG(AfterInputGP, translations["game_path_enter_path"])

def VerifyGamePath(shouldgetpath: bool = True) -> bool:
    Log("Verifying game path...")
    gamepath = GVars.configData["Portal2-Path"]["value"]

    if ((os.path.exists(gamepath)) != True) or (os.path.exists(gamepath + GVars.nf + "portal2_dlc2") != True):
        Ui.Error(translations["game_path-is-invalid"])

        if shouldgetpath:
            Ui.Error(
                translations["game_path-attempt-to-fetch"], 5, (255, 255, 75))
            GetGamePath()

        return False
        Log("Game path is invalid...")
    Log("Game path is valid...")
    return True

def VerifyModFiles() -> bool:
    modFilesPath = GVars.modPath + GVars.nf + "ModFiles" + \
        GVars.nf + "Portal 2" + GVars.nf + "install_dlc"
    Log("Searching for mod files in: " + modFilesPath)
    if (os.path.exists(modFilesPath)) and (os.path.exists(modFilesPath + GVars.nf + "32playermod.identifier")):
        Log("Mod files found!")
        return True

    Log("Mod files not found!")
    return False

def DEVMOUNT() -> None:
    try:
        # delete the old modfiles
        BF.DeleteFolder(GVars.modPath + GVars.nf + "ModFiles")
    except Exception as e:
        Log("Error deleting mod files in dev mount")
        Log(str(e))

    # copy the one in the current directory to the modpath
    BF.CopyFolder(cwd + GVars.nf + "ModFiles",
                  GVars.modPath + GVars.nf + "ModFiles")

def MountModOnly() -> bool:
    cfg.ValidatePlayerKeys()

    if Ui.IsUpdating:
        Ui.Error(translations["update_is-updating"], 5, (255, 75, 75))
        return False

    if not VerifyGamePath():
        return False

    Ui.Error(translations["mounting_mod"], 5, (75, 255, 75))

    gamepath = GVars.configData["Portal2-Path"]["value"]

    if (GVars.configData["Dev-Mode"]["value"] == "true"):
        Ui.Error(translations["devmod_is_active"], 5, (255, 180, 75))
        DEVMOUNT()
        Ui.Error(
            translations["devmod_copied_from_local_repo"], 5, (75, 255, 75))

    if (VerifyModFiles()):
        DoEncrypt = GVars.configData["Encrypt-Cvars"]["value"] == "true"
        RG.MountMod(gamepath, DoEncrypt)
        Ui.Error(translations["mounted"], 5, (75, 255, 75))
        return True

    # If the they are not a developer and the mod files don't exist ask them to download the files from the repo
    if (os.path.exists(GVars.modPath + GVars.nf + "ModFiles")):
        BF.DeleteFolder(GVars.modPath + GVars.nf + "ModFiles")

    if not up.haveInternet():
        def OkInput() -> None:
            Log("Downloading the latest mod files...")
            UpdateModFiles()

        OkButton = Ui.ButtonTemplate(
            translations["error_ok"], OkInput, (75, 255, 75))
        Ui.Error(
            translations["update_error_connection_problem"], 5, (255, 75, 75))
        Ui.PopupBox(translations["update_error_connection_problem"], 
            translations["no_internet_error"], OkButton)
        return False
    
    return True

def GetAvailableLanguages() -> list[str]:
    Log("searching for available languages")
    langs = []
    for file in os.listdir("languages"):
        langs.append(file[:-5])
    customTranslationsPath = GVars.modPath + GVars.nf + "languages"
    if os.path.exists(customTranslationsPath):
        for file in os.listdir(customTranslationsPath):
            langs.append(file[:-5])

    return langs

def LoadTranslations() -> dict:
    global translations
    langPath = "languages/" + \
        GVars.configData["Active-Language"]["value"] + ".json"

    if not os.path.exists(langPath):
        langPath = GVars.modPath + GVars.nf + "languages/" + \
            GVars.configData["Active-Language"]["value"] + ".json"

    translations = json.load(open(langPath, "r", encoding="utf8"))
    EnglishOriginal : dict[str, str] = json.load(open("languages/English.json", "r", encoding="utf8"))

    if (not os.path.exists(langPath)) or (translations.keys() != EnglishOriginal.keys()):
        cfg.EditConfig("Active-Language",
                       cfg.DefaultConfigFile["Active-Language"]["value"])
        langPath = "languages/" + \
            GVars.configData["Active-Language"]["value"] + ".json"

        translations = json.load(open(langPath, "r", encoding="utf8"))

        Log("[ERROR] language file isn't found or key mismatch")

def UpdateModFiles() -> None:
    PreExit()
    Ui.Error(translations["update_fetching"], 5000, (255, 150, 75))

    def UpdateThread() -> None:
        Log("Updating...")
        Ui.IsUpdating = True
        up.DownloadNewFiles()
        Ui.Error(translations["update_complete"], 5, (75, 255, 75))
        Ui.IsUpdating = False
        for thing in Ui.ERRORLIST:
            if thing[0] == translations["update_fetching"]:
                Ui.ERRORLIST.remove(thing)

    thread = threading.Thread(target=UpdateThread)
    thread.start()

def UpdateModClient() -> None:
    PreExit()
    Ui.Error(translations["updating_client"], 5000, (255, 150, 75))

    def UpdateThread() -> None:
        Log("Updating client...")
        Ui.IsUpdating = True

        if not up.DownloadClient():
            Ui.Error(
                "Couldn't find the download link \nplease visit our github to update")
            return

        Ui.running = False
        Log("self.running set to false")

    thread = threading.Thread(target=UpdateThread)
    thread.start()

def RunGameScript() -> None:
    if MountModOnly():
        gamepath = GVars.configData["Portal2-Path"]["value"]
        RG.LaunchGame(gamepath)
        Ui.Error(translations["game_launched"], 5, (75, 255, 75))

def UnmountScript(shouldgetpath: bool = True) -> None:
    Log("___Unmounting Mod___")
    VerifyGamePath(shouldgetpath)
    gamepath = GVars.configData["Portal2-Path"]["value"]
    RG.DeleteUnusedDlcs(gamepath)
    RG.UnpatchBinaries(gamepath)
    Log("____DONE UNMOUNTING____")

def RestartClient(path: str = sys.executable) -> None:
    if (GVars.iol) or (GVars.iosd):
        permissioncommand = "chmod +x " + path
        os.system(permissioncommand)

    command = path
    subprocess.Popen(command, shell=True)
    Log("Restarting client")
    Ui.running = False

# checks if the client was downloaded by a previous version of itself
def IsNew() -> None:
    # we pass 2 arguments when we update the client
    # 1- the word "updated"
    # 2- the path of the previous version
    # argument 0 is always the command to start the app so we don't need that

    if len(sys.argv) != 3:
        return

    if (sys.argv[1] != "updated") or (not os.path.exists(sys.argv[2])):
        return

    Log("This is first launch after a successful update")

    Log("Deleting old client...")
    os.remove(sys.argv[2])

    # this will rename the new client to the old client's name
    Log("Renaming new client...")
    os.rename(GVars.executable, sys.argv[2])
    RestartClient("\"" + sys.argv[2] + "\"")

def ClientUpdateBox(update: dict) -> None:
    YesButton = Ui.ButtonTemplate(
        translations["error_yes"], UpdateModClient, (75, 200, 75))
    NoButton = Ui.ButtonTemplate(
        translations["error_no"], activeColor=(255, 75, 75))

    Ui.PopupBox(update["name"], update["message"], [YesButton, NoButton])

def ModFilesUpdateBox() -> None:
    YesButton = Ui.ButtonTemplate(
        translations["error_yes"], UpdateModFiles, (75, 200, 75))
    NoButton = Ui.ButtonTemplate(
        translations["error_no"], activeColor=(255, 75, 75))

    Ui.PopupBox(translations["update_available"],
                translations["update_would_you_like_to"], [YesButton, NoButton])

def CheckForUpdates() -> bool:
    Log("Checking for updates...")
    clientUpdate = up.CheckForNewClient()

    if clientUpdate["status"]:
        ClientUpdateBox(clientUpdate)
        return True

    if up.CheckForNewFiles():
        ModFilesUpdateBox()
        return True

    return False

def Initialize() -> None:
    # Load the global variables
    GVars.init()
    # do the fancy log thing
    StartLog()
    # load the config file into memmory
    GVars.LoadConfig()
    # load the client's translations
    LoadTranslations()
    # Starts up the custom data system
    DS.dataSystemInitialization(refresh=False)

    # checks if this is debug or release mode
    if sys.argv[0].endswith(".py"):
        Log("Running through Python! Not checking for updates.")
        return

    IsNew()  # Check for first time setup after update

    # remove old temp files
    if (os.path.exists(GVars.modPath + GVars.nf + ".temp")):
        BF.DeleteFolder(GVars.modPath + GVars.nf + ".temp")

def PostInitialize() -> None:
    # only check for updates if the user is not running from source
    if not sys.argv[0].endswith(".py"):
        CheckForUpdates()

    VerifyGamePath(False)

    def NewAfterFunction() -> None:
        Ui.Error(translations["game_exited"], 5, (125, 0, 125))
        if (GVars.configData["Auto-Umount"]["value"] == "true"):
            UnmountScript()
            Ui.Error(translations["unmounted_error"], 5, (125, 0, 125))

    GVars.AfterFunction = NewAfterFunction

    if (GVars.hadtoresetconfig):
        Log("Config has been reset to default settings!")
        OkButton = Ui.ButtonTemplate(
            translations["error_ok"], activeColor=(75, 255, 75))
        Ui.PopupBox(translations["launcher_config_reset"],
                    translations["launcher_had_to_reset"], [OkButton])

if __name__ == '__main__':
    try:
        cwd = os.getcwd()
        Initialize()
        Ui = Gui(GVars.configData["Dev-Mode"]["value"] == "true")
        PostInitialize()
        DRP.startRichPresence()
        Ui.Main()
    except Exception as a_funni_wacky_error_occured:
        Log("Exception encountered:\n" + traceback.format_exc())