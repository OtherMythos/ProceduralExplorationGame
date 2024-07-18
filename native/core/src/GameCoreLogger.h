#pragma once

#include "spdlog/spdlog.h"
#include "spdlog/fmt/ostr.h"

namespace ProceduralExplorationGameCore{
    class GameCoreLogger{
    public:
        static void initialise();

        inline static std::shared_ptr<spdlog::logger>& GetLogger() { return _logger; }
    private:
        static std::shared_ptr<spdlog::logger> _logger;
    };
}

#define GAME_CORE_TRACE(...) ::ProceduralExplorationGameCore::GameCoreLogger::GetLogger()->trace(__VA_ARGS__);
#define GAME_CORE_INFO(...) ::ProceduralExplorationGameCore::GameCoreLogger::GetLogger()->info(__VA_ARGS__);
#define GAME_CORE_WARN(...) ::ProceduralExplorationGameCore::GameCoreLogger::GetLogger()->warn(__VA_ARGS__);
#define GAME_CORE_ERROR(...) ::ProceduralExplorationGameCore::GameCoreLogger::GetLogger()->error(__VA_ARGS__);
#define GAME_CORE_CRITICAL(...) ::ProceduralExplorationGameCore::GameCoreLogger::GetLogger()->critical(__VA_ARGS__);