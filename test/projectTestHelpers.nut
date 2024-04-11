//Helpers specific to the game itself, to separate the test setup script from game logic.

::_testHelper.clearAllSaves <- function(){
    print("Cleared all saves");
    _system.removeAll("user://");
}