package liblogger

import (
	"os"
	"path/filepath"
	"sync"
	"time"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

var (
	log  *zap.Logger
	sugar *zap.SugaredLogger
	level zap.AtomicLevel
	once sync.Once
	bInitLog bool
)

//색상 정의 - 향후 전역 define으로 이동
const (
	
	BOLD string = "\x1b[1m"

	RED string = "\x1b[31m"
	GREEN string = "\x1b[32m"
	BLUE string = "\x1b[34m"
	YELLOW string = "\x1b[33m"
	MAGENTA string = "\x1b[36m"
	GRAY string = "\x1b[90m"
	PURPLE string = "\x1b[35m"
	WHITE string = "\x1b[37m"

	NC string = "\x1b[0m"
)

// func InitializeLogger(logFile string) *zap.Logger {
func InitializeLogger(logFile string, initialLevel zapcore.Level) {

	//싱글턴 패턴이다. 향후 다시 문법확인, 메모용으로 기록.
	once.Do(func() {

		//Tag, Level 형식으로 변경
		// encoderConfig.EncodeLevel = func(l zapcore.Level, enc zapcore.PrimitiveArrayEncoder) {
		// 	// 예: [INFO] [DEBUG]
		// 	enc.AppendString("[" + l.CapitalString() + "]")
		// }

		encoderConfig := zapcore.EncoderConfig{
			TimeKey:    "time",
			LevelKey:   "level",
			MessageKey: "msg",
			// CallerKey:  "caller", //호출 함수정보, 주석처리하면 호출되지 않는다.

			// EncodeTime:   zapcore.ISO8601TimeEncoder,
			EncodeTime: func(t time.Time, enc zapcore.PrimitiveArrayEncoder) {

				// const (
				// 	GRAY = "\x1b[90m"
				// 	BOLD = "\x1b[1m"
				// 	NC   = "\x1b[0m"
				// )

				// const BOLD = "\x1b[1m"

				// const GREEN = "\x1b[32m"
				// // const RED = "\x1b[31m"
				// // const YELLOW = "\x1b[33m"
				// // const WHITE = "\x1b[37m"
				// // const GRAY = "\x1b[90m"
				// const NC = "\x1b[0m" //reset

				// enc.AppendString(GRAY + "[" + t.Format("2006-01-02 15:04:05") + "]" + NC)

				enc.AppendString(BOLD + GREEN + "[" + t.Format("2006-01-02 15:04:05") + "]" + NC)

				// enc.AppendString("[" + t.Format("2006-01-02 15:04:05") + "]")
			},


			//26.03.29 콘솔 출력시 color 추가
			// EncodeLevel:  zapcore.CapitalLevelEncoder,
			// EncodeLevel: func(l zapcore.Level, enc zapcore.PrimitiveArrayEncoder) {
			// 	enc.AppendString("[" + l.CapitalString() + "]")
			// },

			//level 출력 옵션, 테스트, 제거
			/*
			EncodeLevel: func(l zapcore.Level, enc zapcore.PrimitiveArrayEncoder) {

				// enc.AppendString("[")
				enc.AppendString(BOLD) // 굵게 시작
				// zapcore.CapitalColorLevelEncoder(l, enc) // 컬러 + LEVEL
				// enc.AppendString(NC) // 스타일 종료
				// enc.AppendString("]")

				enc.AppendString("[")
				zapcore.CapitalColorLevelEncoder(l, enc) // 컬러 적용
				enc.AppendString("]")
			},*/

			EncodeCaller: zapcore.ShortCallerEncoder,

			// TAB 대신 공백 또는 []로 감싸는 포맷 적용 가능
			//ConsoleSeparator: "\u200B", // 기본 "\t" → 공백으로 변경
			ConsoleSeparator: " ", // 기본 "\t" → 공백으로 변경
		}

		//TODO: 디렉토리 생성, 나중에 라이브러리화
		//디렉토리를 추출한다.
		dir := filepath.Dir(logFile)

		// 디렉토리 없으면 생성
		//MkdirAll => 중간 경로까지 모두 생성한다. 이미 존재하면 에러가 나지 않는다. (mkdir -p 느낌)
		//단일 디렉토리 생성은 os.Mkdir()이다.
		if err := os.MkdirAll(dir, 0755); err != nil {
			//TODO: 최초 초기화 과정, 생성 못하는 경우는 프로그램도 종료시킨다.
			//early fail
			panic(err)
		}

		file, err := os.OpenFile(logFile,os.O_CREATE|os.O_APPEND|os.O_WRONLY,0644,)

		if nil != err {
			panic(err)
		}

		// level 설정
		level = zap.NewAtomicLevelAt(initialLevel)

		// stdout + file 동시에 출력
		writer := zapcore.NewMultiWriteSyncer(
			zapcore.AddSync(os.Stdout),
			zapcore.AddSync(file),
		)

		//옵션화는 나중에 이렇게 하면 된다.
		// var stdout bool = true
		// var writers []zapcore.WriteSyncer
        // writers = append(writers, zapcore.AddSync(file))
        // if stdout {
        //     writers = append(writers, zapcore.AddSync(os.Stdout))
        // }

		core := zapcore.NewCore(
			zapcore.NewConsoleEncoder(encoderConfig),
			writer,
			level,
			// zapcore.AddSync(file),
			// zap.InfoLevel,
			// zap.DebugLevel,
		)

		//대박, wrapper를 건너뛰는 기능도 있다.
		// log = zap.New(core, zap.AddCaller())
		log := zap.New(core, zap.AddCaller(), zap.AddCallerSkip(1))
		sugar = log.Sugar()

		//log 초기화 여부 flag
		bInitLog = true
	})

	// return log
}

// // L: 어디서든 가져다 쓰는 글로벌 접근자
// func LOG() *zap.Logger {
// 	if log == nil {
// 		panic("logger not initialized")
// 	}
// 	return log
// }

// S: Sugared Logger (Python logging 느낌)
func LOG() *zap.SugaredLogger {

	if nil == sugar {
		panic("logger not initialized")
	}
	// return log.Sugar()
	return sugar
}

// ==================== Runtime level 변경 ====================
func SetLevel(l zapcore.Level) {
	if false == bInitLog {
		panic("logger not initialized")
	}
	level.SetLevel(l)
}

//BOLD 처리, zapcore에서 지원되지 않아서 별도로 호출 필요
//TODO: GO언어가 익숙해지면, 좀더 유연하게 처리.
func BH(msg string) string {
    // const WHITE = "\x1b[37m"
    // const BOLD  = "\x1b[1m"
    // const NC    = "\x1b[0m"

    return BOLD + WHITE + msg + NC
}

// 일단 이렇게 써보자.
// Python 스타일 wrapper
func Debug(args ...interface{}) {LOG().Debug(args...)}

func Info(args ...interface{}) {LOG().Info(args...)}

func Warn(args ...interface{}) {LOG().Warn(args...)}

func Error(args ...interface{}) {LOG().Error(args...)}

// Key-value 스타일 (Infow) => 불필요
// func Debugw(msg string, keysAndValues ...interface{}) {LOG().Debugw(msg, keysAndValues...)}

// func Infow(msg string, keysAndValues ...interface{}) {LOG().Infow(msg, keysAndValues...)}

// func Warnw(msg string, keysAndValues ...interface{}) {LOG().Warnw(msg, keysAndValues...)}

// func Errorw(msg string, keysAndValues ...interface{}) {LOG().Errorw(msg, keysAndValues...)}

func Debugf(msg string, args ...interface{}) {LOG().Debugf(msg, args...)}

func Infof(msg string, args ...interface{}) {LOG().Infof(msg, args...)}

func Warnf(msg string, args ...interface{}) {LOG().Warnf(msg, args...)}

func Errorf(msg string, args ...interface{}) {LOG().Errorf(msg, args...)}