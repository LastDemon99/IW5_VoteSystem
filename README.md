<p align="center">
  <img src="https://github.com/LastDemon99/LastDemon99/blob/main/Data/IW5_VoteSystem_v1.png">
  <br><br>
  <b>IW5_VoteSystem</b><br>
  <a>GSC script for plutonium, a dynamic hud for selecting maps and game modes</a> 
  <br><br>
  • <a href="#key-features">Key Features</a> •  
  <a href="#how-to-use">How To Use</a> •
  <a href="#download">Download</a> •  
  <a href="#credits">Credits</a> •
</p>

# <a name="key-features"></a>Key Features
- This script will create a random list of maps and dsr at the end of the game to vote the next rotation
- You can choose the maps and dsr to be displayed in the menu in a range between 1 and 6
- The name that will be displayed in the menu for the respective item will be the one of your preference
- The list shown in the menu is scrollable

# <a name="how-to-use"></a>How To Use
- Place the script file at "%localappdata%/plutonium/storage/iw5/scripts" if the folder does not exist, create it
- Modify the [level.maps](https://github.com/LastDemon99/IW5_GSC_VoteMode/blob/baf2ea0f2c180e7841d007555f36cb2aafaf7488/IW5_VoteSystem.gsc#L48) array to set the range of the maps, and modify the [level.dsr](https://github.com/LastDemon99/IW5_GSC_VoteMode/blob/baf2ea0f2c180e7841d007555f36cb2aafaf7488/IW5_VoteSystem.gsc#L81) array with the dsr of your server
- Specify the range of maps and dsr to display in the function [SetRandomVote()](https://github.com/LastDemon99/IW5_GSC_VoteMode/blob/baf2ea0f2c180e7841d007555f36cb2aafaf7488/IW5_VoteSystem.gsc#L83)
- If your server does not have a map rotation or a serverAdmin, comment out the line containing ["exitLevel(0);"](https://github.com/LastDemon99/IW5_GSC_VoteMode/blob/baf2ea0f2c180e7841d007555f36cb2aafaf7488/IW5_VoteSystem.gsc#L258) and uncomment this line [//cmdexec("start_map_rotate");](https://github.com/LastDemon99/IW5_GSC_VoteMode/blob/baf2ea0f2c180e7841d007555f36cb2aafaf7488/IW5_VoteSystem.gsc#L259)
- To interact with the menu press the keys that appear at the bottom of the screen
- In future updates, modifications can be made in a simpler way

# <a name="download"></a>Download
- Download the .gsc file from the main repository

# <a name="credits"></a>Credits
- The Plutonium team for gsc implementation
- Special thanks to Swifty for solving doubts, testing and fixing part of the code: [Swifty](https://github.com/swifty-tekno) 
- Plutonium discord community for solving doubts
