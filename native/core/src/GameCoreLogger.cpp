#include "GameCoreLogger.h"

#ifdef WIN32
    #ifdef WIN_DESKTOP_APPLICATION
        #include "spdlog/sinks/msvc_sink.h"
    #else
        #include "spdlog/sinks/stdout_color_sinks.h"
    #endif
#else
    #include "spdlog/sinks/stdout_color_sinks.h"
#endif

namespace ProceduralExplorationGameCore{
    std::shared_ptr<spdlog::logger> GameCoreLogger::_logger;

    void GameCoreLogger::initialise(){
        static const char* loggerName = "GAME_CORE";
        #ifdef WIN32
            #ifdef WIN_DESKTOP_APPLICATION
                auto sink = std::make_shared<spdlog::sinks::msvc_sink_mt>();
                _logger = std::make_shared<spdlog::logger>(loggerName, sink);
            #else
                _logger = spdlog::stdout_color_mt(loggerName);
            #endif

        #else
            _logger = spdlog::stdout_color_mt(loggerName);
        #endif

        _logger->set_level(spdlog::level::trace);
    }
}