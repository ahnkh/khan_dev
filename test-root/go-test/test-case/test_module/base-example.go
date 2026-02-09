package test_module

// import "log"

import (
	"os"
	"sync"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

type BaseExample struct{}

func (t *BaseExample) Test() {

	//log 호출전, 기본 로깅도 필요하다. => 2개 호출이 안되는 문제, 좀더 배우자.
	// log.Println("test base test")

	// S().Info("running BaseTest")

	t.testLogger()
}

func (t *BaseExample) testLogger() {

	InitLogger("test.log")

	S().Debug("test Logger")

}

/**
기본 logger 테스트
아직 문법이 익숙하지는 않지만, 우선 작성후 하나씩 터득
**/

var (
	log  *zap.Logger
	once sync.Once
)

func InitLogger(logFile string) *zap.Logger {
	once.Do(func() {

		encoderConfig := zapcore.EncoderConfig{
			TimeKey:    "time",
			LevelKey:   "level",
			MessageKey: "msg",
			CallerKey:  "caller",

			EncodeTime:   zapcore.ISO8601TimeEncoder,
			EncodeLevel:  zapcore.CapitalLevelEncoder,
			EncodeCaller: zapcore.ShortCallerEncoder,
		}

		file, err := os.OpenFile(
			logFile,
			os.O_CREATE|os.O_APPEND|os.O_WRONLY,
			0644,
		)
		if err != nil {
			panic(err)
		}

		core := zapcore.NewCore(
			zapcore.NewConsoleEncoder(encoderConfig),
			zapcore.AddSync(file),
			// zap.InfoLevel,
			zap.DebugLevel,
		)

		log = zap.New(core, zap.AddCaller())
	})

	return log
}

// L: 어디서든 가져다 쓰는 글로벌 접근자
func L() *zap.Logger {
	if log == nil {
		panic("logger not initialized")
	}
	return log
}

// S: Sugared Logger (Python logging 느낌)
func S() *zap.SugaredLogger {
	return L().Sugar()
}
