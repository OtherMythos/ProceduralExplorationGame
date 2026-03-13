#include "GameCoreLogger.h"

#ifdef WIN32
    #ifdef WIN_DESKTOP_APPLICATION
        #include "spdlog/sinks/msvc_sink.h"
    #endif
#elif defined(TARGET_ANDROID)
    #include "spdlog/sinks/android_sink.h"
#endif

#if !defined(WIN32) && !defined(TARGET_ANDROID) || (defined(WIN32) && !defined(WIN_DESKTOP_APPLICATION))
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
            #endif
        #elif defined(TARGET_ANDROID)
            _logger = spdlog::android_logger_mt(loggerName);
        #endif

        #if !defined(WIN32) && !defined(TARGET_ANDROID) || (defined(WIN32) && !defined(WIN_DESKTOP_APPLICATION))
            //Share the engine's stdout sink so both loggers contend on the same mutex,
            //preventing interleaved ANSI colour codes from concurrent threads.
            auto engineLogger = spdlog::get("AV");
            if(engineLogger && !engineLogger->sinks().empty()){
                _logger = std::make_shared<spdlog::logger>(loggerName, engineLogger->sinks().begin(), engineLogger->sinks().end());
            } else {
                _logger = spdlog::stdout_color_mt(loggerName);
            }
        #endif

        _logger->set_level(spdlog::level::trace);
    }
}