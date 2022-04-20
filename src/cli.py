import Scripts.GlobalVariables as GVars
from Scripts.BasicLogger import Log, StartLog
import Scripts.RunGame as RG
import Scripts.Configs as cfg
import os

def UserAction():
    validinput = False
    global WillMount
    WillMount = True
    while (not validinput):
        ShouldMount = input("(?) Would you like to mount or unmount the mod? (Mount/Unmount) ")

        # if the user doesn't want to proceed they can can quit
        if (ShouldMount.upper() == "EXIT" or ShouldMount.upper() == "ABORT" or ShouldMount.upper() == "QUIT"):
            Log("Exiting")
            quit()

        if (ShouldMount.upper() == "MOUNT" or ShouldMount.upper() == "M"):
            validinput = True
            Log("User input: " + ShouldMount)
            Log("Mounting the mod...")
        elif (ShouldMount.upper() == "UNMOUNT" or ShouldMount.upper() == "U"):
            validinput = True
            WillMount = False
            Log("User input: " + ShouldMount)
            Log("Unmounting the mod...")
        else:
            Log("Type in a valid option!")


def GetGamePath():
    folder = input("please enter the path to the game: ").strip()
    cfg.EditConfig("portal2path", folder)
    Log("saved '" + folder + "' as the game path")


def VerifyGamePath():
    Log("Verifying game path...")
    valid= False
    while valid == False:
        gamepath = GVars.configData["portal2path"]
        if ((os.path.exists(gamepath)) != True) or (os.path.exists(gamepath + GVars.nf + "portal2_dlc2") != True):
            Log("Game path is invalid")
            GetGamePath()
        else:
            valid = True


def OnStart():
    # populate the global variables
    GVars.init()
    # to do the fancy log thing
    StartLog()
    # load the configs (yes it's better to do it separately)
    GVars.LoadConfig()


def Init():
    OnStart()
    Log("")
    Log("Initializing...")
    Log("")

    # ask the user what they want before proceeding
    UserAction()
    Log("")

    VerifyGamePath()
    gamepath = GVars.configData["portal2path"]
    
#//# mount the multiplayer mod #//#
    if (WillMount):
        if RG.MountMod(gamepath) == "filesMissing":
            Log("the mod files are missing")
            return
        RG.LaunchGame(gamepath)

    else:
        RG.DeleteUnusedDlcs(gamepath)
        RG.UnpatchBinaries(gamepath)
        Log("Unmounted the game successfully")
        
    input("Press enter to exit")


if __name__ == "__main__":
    # RUN INIT
    Init()