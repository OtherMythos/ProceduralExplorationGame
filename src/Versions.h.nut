#define const static const char*

const GAME_TITLE = "Un-Named RPG game";
const GAME_VERSION_SUFFIX = "alpha";

#undef const

#define const static const int

const GAME_VERSION_MAJOR = 0;
const GAME_VERSION_MINOR = 5;
const GAME_VERSION_PATCH = 0;

#undef const

//NOTE: This is expected to be populated by a script.
//const GIT_HASH = "9e78c65f"
