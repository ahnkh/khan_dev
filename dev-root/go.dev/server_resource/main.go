package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
	"time"
)

type Metrics struct {
	Time    string       `json:"time"`
	CPU     CPUInfo      `json:"cpu"`
	Memory  MemoryInfo   `json:"memory"`
	Disks   map[string]DiskInfo `json:"disks"`
	Sensors []SensorInfo `json:"sensors,omitempty"`
	GPU     []GPUInfo    `json:"gpu,omitempty"`
	Power   PowerInfo              `json:"power"`
	Fan     FanInfo                `json:"fan"`
	// Fan     map[string]float64  `json:"fan"`
}

type CPUInfo struct {
	Usage float64 `json:"usage"`
	Load1 float64 `json:"load1"`
	Load5 float64 `json:"load5"`
	Load15 float64 `json:"load15"`
}

type CPUStat struct {
    User    uint64
    Nice    uint64
    System  uint64
    Idle    uint64
    IOWait  uint64
    IRQ     uint64
    SoftIRQ uint64
    Steal   uint64
}


type MemoryInfo struct {
	TotalKB     uint64  `json:"total_kb"`
	AvailableKB uint64  `json:"available_kb"`
	UsedKB      uint64  `json:"used_kb"`
	Usage       float64 `json:"usage"`
}

type DiskInfo struct {
	TotalGB float64 `json:"total_gb"`
	UsedGB  float64 `json:"used_gb"`
	Usage   float64 `json:"usage"`
}

type SensorInfo struct {
	Name  string  `json:"name"`
	Type  string  `json:"type"`
	Value float64 `json:"value"`
	Unit  string  `json:"unit"`
}

type GPUInfo struct {
	Name        string  `json:"name"`
	Temperature float64 `json:"temperature"`
	Usage       float64 `json:"usage"`
	MemoryUsed  float64 `json:"memory_used_mb"`
	MemoryTotal float64 `json:"memory_total_mb"`
	Power       float64 `json:"power_w"`
}

type PowerInfo struct {
	Count  int     `json:"count"`
	WorkingCount int  `json:"working_count"`
	PSU1   float64 `json:"psu1_w"`
	PSU2   float64 `json:"psu2_w"`
	Total  float64 `json:"total_w"`
	FAN    float64 `json:"fan_w"`
	CPU    float64 `json:"cpu_w"`
	Memory float64 `json:"memory_w"`
}

type FanInfo struct {
	Count int                `json:"count"`
	WorkingCount int         `json:"working_count"`
	Fans map[string]float64 `json:"fans"`
}

// --------------------------------------------------
// CPU
// --------------------------------------------------

func readCPUStat() (CPUStat, error) {

    file, err := os.Open("/proc/stat")
    if err != nil {
        return CPUStat{}, err
    }

    defer file.Close()

    scanner := bufio.NewScanner(file)

    for scanner.Scan() {

        fields := strings.Fields(scanner.Text())

        if len(fields) < 9 {
            continue
        }

        /*
            첫 번째 cpu 항목만 사용
        */
        if fields[0] != "cpu" {
            continue
        }

        var stat CPUStat

        stat.User, err = strconv.ParseUint(fields[1], 10, 64)
        if err != nil {
            return CPUStat{}, err
        }

        stat.Nice, err = strconv.ParseUint(fields[2], 10, 64)
        if err != nil {
            return CPUStat{}, err
        }

        stat.System, err = strconv.ParseUint(fields[3], 10, 64)
        if err != nil {
            return CPUStat{}, err
        }

        stat.Idle, err = strconv.ParseUint(fields[4], 10, 64)
        if err != nil {
            return CPUStat{}, err
        }

        stat.IOWait, err = strconv.ParseUint(fields[5], 10, 64)
        if err != nil {
            return CPUStat{}, err
        }

        stat.IRQ, err = strconv.ParseUint(fields[6], 10, 64)
        if err != nil {
            return CPUStat{}, err
        }

        stat.SoftIRQ, err = strconv.ParseUint(fields[7], 10, 64)
        if err != nil {
            return CPUStat{}, err
        }

        stat.Steal, err = strconv.ParseUint(fields[8], 10, 64)
        if err != nil {
            return CPUStat{}, err
        }

        return stat, nil
    }

    if err := scanner.Err(); err != nil {
        return CPUStat{}, err
    }

    return CPUStat{}, fmt.Errorf("cpu information not found")
}

// func readCPUStat() (uint64, uint64, error) {
// 	file, err := os.Open("/proc/stat")
// 	if err != nil {
// 		return 0, 0, err
// 	}
// 	defer file.Close()

// 	scanner := bufio.NewScanner(file)

// 	if !scanner.Scan() {
// 		return 0, 0, fmt.Errorf("cannot read /proc/stat")
// 	}

// 	fields := strings.Fields(scanner.Text())

// 	if len(fields) < 9 || fields[0] != "cpu" {
// 		return 0, 0, fmt.Errorf("invalid /proc/stat cpu line")
// 	}

// 	var values [8]uint64

// 	for i := 0; i < 8; i++ {
// 		v, err := strconv.ParseUint(fields[i+1], 10, 64)
// 		if err != nil {
// 			return 0, 0, err
// 		}
// 		values[i] = v
// 	}

// 	user := values[0]
// 	nice := values[1]
// 	system := values[2]
// 	idle := values[3]
// 	iowait := values[4]
// 	irq := values[5]
// 	softirq := values[6]
// 	steal := values[7]

// 	total := user + nice + system + idle + iowait + irq + softirq + steal
// 	idleTotal := idle + iowait

// 	return total, idleTotal, nil
// }

// func getCPUUsage() float64 {
// 	total1, idle1, err := readCPUStat()
// 	if err != nil {
// 		fmt.Printf("[ERROR] CPU first read failed: %v\n", err)
// 		return 0
// 	}

// 	time.Sleep(time.Second)

// 	total2, idle2, err := readCPUStat()
// 	if err != nil {
// 		fmt.Printf("[ERROR] CPU second read failed: %v\n", err)
// 		return 0
// 	}

// 	totalDiff := total2 - total1
// 	idleDiff := idle2 - idle1

// 	if totalDiff == 0 {
// 		return 0
// 	}

// 	return float64(totalDiff-idleDiff) / float64(totalDiff) * 100
// }

func collectCPUUsage() float64 {

    before, err := readCPUStat()

    if err != nil {
        return 0
    }

    time.Sleep(100 * time.Millisecond)

    after, err := readCPUStat()

    if err != nil {
        return 0
    }

    beforeTotal :=
        before.User +
            before.Nice +
            before.System +
            before.Idle +
            before.IOWait +
            before.IRQ +
            before.SoftIRQ +
            before.Steal

    afterTotal :=
        after.User +
            after.Nice +
            after.System +
            after.Idle +
            after.IOWait +
            after.IRQ +
            after.SoftIRQ +
            after.Steal

    beforeIdle := before.Idle + before.IOWait
    afterIdle := after.Idle + after.IOWait

    totalDiff := afterTotal - beforeTotal
    idleDiff := afterIdle - beforeIdle

    if totalDiff == 0 {
        return 0
    }

    usage := float64(
        totalDiff-idleDiff,
    ) / float64(totalDiff) * 100

    return usage
}

// --------------------------------------------------
// Load Average
// --------------------------------------------------

func getLoadAverage() (float64, float64, float64) {
	data, err := os.ReadFile("/proc/loadavg")
	if err != nil {
		fmt.Printf("[ERROR] loadavg read failed: %v\n", err)
		return 0, 0, 0
	}

	fields := strings.Fields(string(data))

	if len(fields) < 3 {
		fmt.Printf("[ERROR] invalid /proc/loadavg: %s\n", string(data))
		return 0, 0, 0
	}

	load1, _ := strconv.ParseFloat(fields[0], 64)
	load5, _ := strconv.ParseFloat(fields[1], 64)
	load15, _ := strconv.ParseFloat(fields[2], 64)

	return load1, load5, load15
}

// --------------------------------------------------
// Memory
// --------------------------------------------------

func getMemory() MemoryInfo {
	file, err := os.Open("/proc/meminfo")
	if err != nil {
		fmt.Printf("[ERROR] meminfo open failed: %v\n", err)
		return MemoryInfo{}
	}
	defer file.Close()

	var totalKB uint64
	var availableKB uint64

	scanner := bufio.NewScanner(file)

	for scanner.Scan() {
		fields := strings.Fields(scanner.Text())

		if len(fields) < 2 {
			continue
		}

		switch fields[0] {
		case "MemTotal:":
			totalKB, _ = strconv.ParseUint(fields[1], 10, 64)

		case "MemAvailable:":
			availableKB, _ = strconv.ParseUint(fields[1], 10, 64)
		}
	}

	var usedKB uint64

	if totalKB >= availableKB {
		usedKB = totalKB - availableKB
	}

	var usage float64

	if totalKB > 0 {
		usage = float64(usedKB) / float64(totalKB) * 100
	}

	return MemoryInfo{
		TotalKB:     totalKB,
		AvailableKB: availableKB,
		UsedKB:      usedKB,
		Usage:       usage,
	}
}

// --------------------------------------------------
// Disk
// --------------------------------------------------

func getDiskUsage(path string) DiskInfo {
	var stat syscall.Statfs_t

	err := syscall.Statfs(path, &stat)
	if err != nil {
		// fmt.Printf("[ERROR] disk stat failed: %s: %v\n", path, err)
		return DiskInfo{}
	}

	total := float64(stat.Blocks) * float64(stat.Bsize)
	free := float64(stat.Bavail) * float64(stat.Bsize)
	used := total - free

	totalGB := total / 1024 / 1024 / 1024
	usedGB := used / 1024 / 1024 / 1024

	var usage float64

	if totalGB > 0 {
		usage = usedGB / totalGB * 100
	}

	return DiskInfo{
		TotalGB: totalGB,
		UsedGB:  usedGB,
		Usage:   usage,
	}
}

// --------------------------------------------------
// HWMON SENSOR
// --------------------------------------------------

func collectSensors() []SensorInfo {
	var sensors []SensorInfo

	// fmt.Println("[DEBUG] =============================")
	// fmt.Println("[DEBUG] HWMON SENSOR SCAN START")
	// fmt.Println("[DEBUG] =============================")

	hwmons, err := filepath.Glob("/sys/class/hwmon/hwmon*")
	if err != nil {
		fmt.Printf("[ERROR] hwmon glob failed: %v\n", err)
		return sensors
	}

	// fmt.Printf("[DEBUG] hwmon count: %d\n", len(hwmons))

	if len(hwmons) == 0 {
		// fmt.Println("[DEBUG] no hwmon devices found")
		return sensors
	}

	for _, hwmon := range hwmons {

		// fmt.Println()
		// fmt.Printf("[DEBUG] ---------------------------------\n")
		// fmt.Printf("[DEBUG] hwmon: %s\n", hwmon)

		// ------------------------------------------
		// name
		// ------------------------------------------

		nameFile := filepath.Join(hwmon, "name")

		nameBytes, err := os.ReadFile(nameFile)
		if err != nil {
			// fmt.Printf("[ERROR] name read failed: %s: %v\n", nameFile, err)
			continue
		}

		name := strings.TrimSpace(string(nameBytes))

		// fmt.Printf("[DEBUG] sensor name: %s\n", name)

		// ------------------------------------------
		// 모든 파일 확인
		// ------------------------------------------

		// allFiles, err := filepath.Glob(filepath.Join(hwmon, "*"))
		// if err != nil {
		// 	fmt.Printf("[ERROR] file glob failed: %s: %v\n", hwmon, err)
		// 	continue
		// }

		// fmt.Printf("[DEBUG] total files: %d\n", len(allFiles))

		// for _, f := range allFiles {
		// 	fmt.Printf("[DEBUG] file: %s\n", f)
		// }

		// ------------------------------------------
		// *_input 검색
		// ------------------------------------------

		inputFiles, err := filepath.Glob(filepath.Join(hwmon, "*_input"))
		if err != nil {
			fmt.Printf("[ERROR] input glob failed: %s: %v\n",hwmon, err)
			continue
		}

		// fmt.Printf("[DEBUG] input files: %d\n", len(inputFiles))

		for _, input := range inputFiles {

			// fmt.Printf("[DEBUG] processing input: %s\n", input)

			// --------------------------------------
			// 값 읽기
			// --------------------------------------

			data, err := os.ReadFile(input)
			if err != nil {
				fmt.Printf("[ERROR] sensor read failed: %s: %v\n", input, err)
				continue
			}

			raw := strings.TrimSpace(string(data))

			// fmt.Printf("[DEBUG] raw value: %q\n", raw)

			value, err := strconv.ParseFloat(raw, 64)
			if err != nil {
				fmt.Printf("[ERROR] sensor parse failed: %s value=%q error=%v\n", input, raw, err)
				continue
			}

			// fmt.Printf("[DEBUG] parsed value: %.2f\n", value)

			base := filepath.Base(input)

			// --------------------------------------
			// Temperature
			// --------------------------------------

			if strings.HasPrefix(base, "temp") &&
				strings.HasSuffix(base, "_input") {

				value /= 1000

				label := ""

				labelFile := strings.TrimSuffix(input, "_input") + "_label"

				labelData, err := os.ReadFile(labelFile)

				if err == nil {
					label = strings.TrimSpace(string(labelData))
				} 
				// else {
				// 	fmt.Printf("[DEBUG] label not found: %s\n",labelFile)
				// }

				if label == "" {
					label = name
				}

				// fmt.Printf("[DEBUG] TEMPERATURE detected\n")
				// fmt.Printf("[DEBUG] name  : %s\n", label)
				// fmt.Printf("[DEBUG] value : %.2f C\n", value)

				sensors = append(sensors, SensorInfo{
					Name:  label,
					Type:  "temperature",
					Value: value,
					Unit:  "C",
				})

				continue
			}

			// --------------------------------------
			// Fan
			// --------------------------------------

			// if strings.HasPrefix(base, "fan") &&
			// 	strings.HasSuffix(base, "_input") {

			// 	// fmt.Printf("[DEBUG] FAN detected\n")
			// 	// fmt.Printf("[DEBUG] name  : %s\n", name)
			// 	// fmt.Printf("[DEBUG] value : %.0f RPM\n", value)

			// 	sensors = append(sensors, SensorInfo{
			// 		Name:  name,
			// 		Type:  "fan",
			// 		Value: value,
			// 		Unit:  "RPM",
			// 	})

			// 	continue
			// }

			// --------------------------------------
			// Power
			// --------------------------------------

			// if strings.HasPrefix(base, "power") &&
			// 	strings.HasSuffix(base, "_input") {

			// 	value /= 1000000

			// 	// fmt.Printf("[DEBUG] POWER detected\n")
			// 	// fmt.Printf("[DEBUG] name  : %s\n", name)
			// 	// fmt.Printf("[DEBUG] value : %.2f W\n", value)

			// 	sensors = append(sensors, SensorInfo{
			// 		Name:  name,
			// 		Type:  "power",
			// 		Value: value,
			// 		Unit:  "W",
			// 	})

			// 	continue
			// }

			// fmt.Printf("[DEBUG] unsupported input file: %s\n",
			// 	base)
		}
	}

	// fmt.Println()
	// fmt.Println("[DEBUG] =============================")
	// fmt.Printf("[DEBUG] HWMON SENSOR SCAN COMPLETE: %d sensors\n",
	// 	len(sensors))
	// fmt.Println("[DEBUG] =============================")

	return sensors
}

func collectPower() PowerInfo {
	// var power PowerInfo

	power := PowerInfo{}

	// // cmd := exec.Command(
	// // 	"ipmitool",
	// // 	"sensor",
	// // )

	//  cmd := exec.Command(
    //     "ipmitool",
    //     "sdr",
    //     "type",
    //     "Power Supply",
    // )

	// output, err := cmd.Output()

	// if err == nil {

    //     lines := strings.Split(string(output), "\n")

    //     for _, line := range lines {

    //         parts := strings.Split(line, "|")

    //         if len(parts) < 3 {
    //             continue
    //         }

    //         status := strings.TrimSpace(parts[2])

    //         /*
    //             SDR에 등록된 PSU
    //         */
    //         power.Count++

    //         /*
    //             현재 정상 상태인 PSU
    //         */
    //         if strings.EqualFold(status, "ok") {
    //             power.WorkingCount++
    //         }
    //     }
    // }

	cmd := exec.Command(
        "ipmitool",
        "sensor",
    )

	output, err := cmd.Output()

	if err != nil {
		return power
	}

	lines := strings.Split(string(output), "\n")

	for _, line := range lines {
		parts := strings.Split(line, "|")

		if len(parts) < 3 {
			continue
		}

		name := strings.TrimSpace(parts[0])
		valueString := strings.TrimSpace(parts[1])
		unit := strings.TrimSpace(parts[2])

		// if unit != "Watts" {
		// 	continue
		// }

		if !strings.EqualFold(unit, "Watts") {
			continue
		}

		value, err := strconv.ParseFloat(valueString, 64)
		if err != nil {
			continue
		}

		switch name {
		case "PSU1_PIN":
			power.PSU1 = value
			power.Count++

		case "PSU2_PIN":
			power.PSU2 = value
			power.Count++

		case "Total_Power":
			power.Total = value

		case "FAN_Power":
            power.FAN = value

		case "CPU_Power":
			power.CPU = value

		case "MEM_Power":
			power.Memory = value
		}
	}

	return power
}

// func collectFan() FanInfo {
// // func collectFan() map[string]float64 {	
// 	fan := FanInfo{
// 		Count: 0,
// 		WorkingCount: 0,
// 		Fans: make(map[string]float64),
// 	}

// 	// fans := make(map[string]float64)

// 	// cmd := exec.Command(
// 	// 	"ipmitool",
// 	// 	"sensor",
// 	// )

// 	cmd := exec.Command(
//         "ipmitool",
//         "sdr",
//         "type",
//         "Fan",
//     )

// 	output, err := cmd.Output()
// 	if err != nil {
// 		return fan
// 	}

// 	lines := strings.Split(string(output), "\n")

// 	for _, line := range lines {
// 		parts := strings.Split(line, "|")

// 		// if len(parts) < 3 {
// 		// 	continue
// 		// }

// 		if len(parts) < 5 {
//             continue
//         }

// 		// name := strings.TrimSpace(parts[0])
// 		// valueString := strings.TrimSpace(parts[1])
// 		// unit := strings.TrimSpace(parts[2])

// 		name := strings.TrimSpace(parts[0])
//         status := strings.TrimSpace(parts[2])
//         valueString := strings.TrimSpace(parts[4])

// 		// if !strings.EqualFold(unit, "RPM") {
// 		// 	continue
// 		// }

// 		fan.Count++

// 		if !strings.EqualFold(status, "ok") {
//             continue
//         }

// 		fields := strings.Fields(valueString)

// 		if len(fields) < 2 {
//             continue
//         }

// 		value, err := strconv.ParseFloat(valueString, 64)
// 		if err != nil {
// 			continue
// 		}

// 		unit := strings.ToUpper(fields[1])

// 		if unit != "RPM" {
//             continue
//         }

// 		fan.Fans[name] = value
// 		fan.WorkingCount++
// 	}

// 	return fan
// }

func collectFan() FanInfo {

    fan := FanInfo{
        Count:        0,
        WorkingCount: 0,
        Fans:         make(map[string]float64),
    }

    cmd := exec.Command(
        "ipmitool",
        "sensor",
    )

    output, err := cmd.Output()

    if err != nil {
        return fan
    }

    lines := strings.Split(
        string(output),
        "\n",
    )

    for _, line := range lines {

        parts := strings.Split(line, "|")

        if len(parts) < 3 {
            continue
        }

        name := strings.TrimSpace(parts[0])
        valueString := strings.TrimSpace(parts[1])
        unit := strings.TrimSpace(parts[2])

        if !strings.EqualFold(unit, "RPM") {
            continue
        }

        /*
            RPM 센서 자체가 존재하므로
            BMC에서 Fan 센서로 인식하고 있는 개수
        */
        fan.Count++

        value, err := strconv.ParseFloat(
            valueString,
            64,
        )

        if err != nil {
            continue
        }

        /*
            실제 RPM 값을 읽을 수 있는 Fan
        */
        fan.WorkingCount++

        fan.Fans[name] = value
    }

    return fan
}

// --------------------------------------------------
// NVIDIA GPU
// --------------------------------------------------

// func collectGPU() []GPUInfo {
// 	var result []GPUInfo

// 	cmd := exec.Command(
// 		"nvidia-smi",
// 		"--query-gpu=name,temperature.gpu,utilization.gpu,memory.used,memory.total,power.draw",
// 		"--format=csv,noheader,nounits",
// 	)

// 	output, err := cmd.Output()
// 	if err != nil {
// 		fmt.Printf("[DEBUG] nvidia-smi unavailable: %v\n", err)
// 		return result
// 	}

// 	lines := strings.Split(strings.TrimSpace(string(output)), "\n")

// 	for _, line := range lines {

// 		if strings.TrimSpace(line) == "" {
// 			continue
// 		}

// 		fields := strings.Split(line, ",")

// 		if len(fields) < 6 {
// 			fmt.Printf("[ERROR] invalid nvidia-smi result: %s\n",
// 				line)
// 			continue
// 		}

// 		name := strings.TrimSpace(fields[0])

// 		temp, _ := strconv.ParseFloat(strings.TrimSpace(fields[1]), 64)
// 		usage, _ := strconv.ParseFloat(strings.TrimSpace(fields[2]), 64)
// 		memUsed, _ := strconv.ParseFloat(strings.TrimSpace(fields[3]), 64)
// 		memTotal, _ := strconv.ParseFloat(strings.TrimSpace(fields[4]), 64)
// 		power, _ := strconv.ParseFloat(strings.TrimSpace(fields[5]), 64)

// 		result = append(result, GPUInfo{
// 			Name:        name,
// 			Temperature: temp,
// 			Usage:       usage,
// 			MemoryUsed:  memUsed,
// 			MemoryTotal: memTotal,
// 			Power:       power,
// 		})
// 	}

// 	return result
// }

// --------------------------------------------------
// Main
// --------------------------------------------------

func main() {

	// fmt.Println("[DEBUG] monitor start")

	// CPU
	cpuUsage := collectCPUUsage()

	load1, load5, load15 := getLoadAverage()

	// Memory
	memory := getMemory()

	// Disk
	diskPaths := []string{
		"/home1",
		"/var",
		"/data",
	}

	disks := make(map[string]DiskInfo)

	for _, path := range diskPaths {

		if _, err := os.Stat(path); err != nil {
			// fmt.Printf("[ERROR] disk path not found: %s: %v\n",
			// 	path, err)
			continue
		}

		disks[path] = getDiskUsage(path)
	}

	// Sensor
	sensors := collectSensors()

	// // GPU
	// gpu := collectGPU()

	// Power
	power := collectPower()

	fan := collectFan()

	// JSON
	metrics := Metrics{
		Time: time.Now().Format(time.RFC3339),
		CPU: CPUInfo{
			Usage: cpuUsage,
			Load1: load1,
			Load5: load5,
			Load15: load15,
		},
		Memory:  memory,
		Disks:   disks,
		Sensors: sensors,
		Fan:     fan,
		// GPU:     gpu,
		Power:   power,
	}

	data, err := json.Marshal(metrics)
	if err != nil {
		fmt.Printf("[ERROR] JSON marshal failed: %v\n", err)
		return
	}

	// fmt.Println()
	// fmt.Println("[DEBUG] JSON result:")
	// fmt.Println(string(data))

	// 실제 JSON 한 줄
	fmt.Println(string(data))

	// fmt.Println("[DEBUG] monitor end")
}



// package main

// import (
// 	"bufio"
// 	"encoding/json"
// 	"fmt"
// 	"os"
// 	"path/filepath"
// 	"strconv"
// 	"strings"
// 	"syscall"
// 	"time"
// )

// // ============================================================
// // JSON 구조
// // ============================================================

// type Metrics struct {
// 	Time    string             `json:"time"`
// 	CPU     CPUInfo            `json:"cpu"`
// 	Memory  MemoryInfo         `json:"memory"`
// 	Disks   map[string]DiskInfo `json:"disks"`
// 	Sensors []SensorInfo       `json:"sensors,omitempty"`
// 	GPU     []GPUInfo          `json:"gpu,omitempty"`
// }

// type CPUInfo struct {
// 	Usage float64 `json:"usage"`
// 	Load1 float64 `json:"load1"`
// 	Load5 float64 `json:"load5"`
// 	Load15 float64 `json:"load15"`
// }

// type MemoryInfo struct {
// 	TotalKB     uint64  `json:"total_kb"`
// 	AvailableKB uint64  `json:"available_kb"`
// 	UsedKB      uint64  `json:"used_kb"`
// 	Usage       float64 `json:"usage"`
// }

// type DiskInfo struct {
// 	TotalGB float64 `json:"total_gb"`
// 	UsedGB  float64 `json:"used_gb"`
// 	Usage   float64 `json:"usage"`
// }

// type SensorInfo struct {
// 	Name  string  `json:"name"`
// 	Type  string  `json:"type"`
// 	Value float64 `json:"value"`
// 	Unit  string  `json:"unit"`
// }

// type GPUInfo struct {
// 	Name        string  `json:"name"`
// 	Temperature float64 `json:"temperature"`
// 	Usage       float64 `json:"usage"`
// 	MemoryUsed  float64 `json:"memory_used_mb"`
// 	MemoryTotal float64 `json:"memory_total_mb"`
// 	Power       float64 `json:"power_w"`
// }

// // ============================================================
// // CPU
// // ============================================================

// type CPUStat struct {
// 	User    uint64
// 	Nice    uint64
// 	System  uint64
// 	Idle    uint64
// 	IOWait  uint64
// 	IRQ     uint64
// 	SoftIRQ uint64
// 	Steal   uint64
// }

// func readCPUStat() (CPUStat, error) {

// 	file, err := os.Open("/proc/stat")
// 	if err != nil {
// 		return CPUStat{}, err
// 	}
// 	defer file.Close()

// 	scanner := bufio.NewScanner(file)

// 	for scanner.Scan() {

// 		fields := strings.Fields(scanner.Text())

// 		if len(fields) < 5 {
// 			continue
// 		}

// 		if fields[0] != "cpu" {
// 			continue
// 		}

// 		var s CPUStat

// 		values := make([]uint64, 8)

// 		for i := 0; i < 8 && i+1 < len(fields); i++ {
// 			values[i], _ = strconv.ParseUint(fields[i+1], 10, 64)
// 		}

// 		s.User = values[0]
// 		s.Nice = values[1]
// 		s.System = values[2]
// 		s.Idle = values[3]
// 		s.IOWait = values[4]
// 		s.IRQ = values[5]
// 		s.SoftIRQ = values[6]
// 		s.Steal = values[7]

// 		return s, nil
// 	}

// 	if err := scanner.Err(); err != nil {
// 		return CPUStat{}, err
// 	}

// 	return CPUStat{}, fmt.Errorf("cpu information not found")
// }

// func cpuTotal(s CPUStat) uint64 {

// 	return s.User +
// 		s.Nice +
// 		s.System +
// 		s.Idle +
// 		s.IOWait +
// 		s.IRQ +
// 		s.SoftIRQ +
// 		s.Steal
// }

// func cpuIdle(s CPUStat) uint64 {

// 	return s.Idle + s.IOWait
// }

// func getCPUUsage() float64 {

// 	first, err := readCPUStat()
// 	if err != nil {
// 		return 0
// 	}

// 	// CPU 사용률 계산을 위해 1초 간격으로 두 번 측정
// 	time.Sleep(time.Second)

// 	second, err := readCPUStat()
// 	if err != nil {
// 		return 0
// 	}

// 	total1 := cpuTotal(first)
// 	total2 := cpuTotal(second)

// 	idle1 := cpuIdle(first)
// 	idle2 := cpuIdle(second)

// 	totalDiff := total2 - total1
// 	idleDiff := idle2 - idle1

// 	if totalDiff == 0 {
// 		return 0
// 	}

// 	usage := float64(totalDiff-idleDiff) /
// 		float64(totalDiff) * 100

// 	return round(usage)
// }

// // ============================================================
// // Load Average
// // ============================================================

// func getLoadAverage() (float64, float64, float64) {

// 	data, err := os.ReadFile("/proc/loadavg")
// 	if err != nil {
// 		return 0, 0, 0
// 	}

// 	fields := strings.Fields(string(data))

// 	if len(fields) < 3 {
// 		return 0, 0, 0
// 	}

// 	load1, err1 := strconv.ParseFloat(fields[0], 64)
// 	load5, err5 := strconv.ParseFloat(fields[1], 64)
// 	load15, err15 := strconv.ParseFloat(fields[2], 64)

// 	if err1 != nil || err5 != nil || err15 != nil {
// 		return 0, 0, 0
// 	}

// 	return round(load1), round(load5), round(load15)
// }

// // ============================================================
// // Memory
// // ============================================================

// func getMemory() MemoryInfo {

// 	data, err := os.ReadFile("/proc/meminfo")
// 	if err != nil {
// 		return MemoryInfo{}
// 	}

// 	var total uint64
// 	var available uint64

// 	for _, line := range strings.Split(string(data), "\n") {

// 		fields := strings.Fields(line)

// 		if len(fields) < 2 {
// 			continue
// 		}

// 		value, err := strconv.ParseUint(fields[1], 10, 64)
// 		if err != nil {
// 			continue
// 		}

// 		switch fields[0] {

// 		case "MemTotal:":
// 			total = value

// 		case "MemAvailable:":
// 			available = value
// 		}
// 	}

// 	if total == 0 {
// 		return MemoryInfo{}
// 	}

// 	if available > total {
// 		available = total
// 	}

// 	used := total - available

// 	return MemoryInfo{
// 		TotalKB:     total,
// 		AvailableKB: available,
// 		UsedKB:      used,
// 		Usage:       round(float64(used) / float64(total) * 100),
// 	}
// }

// // ============================================================
// // Disk
// // ============================================================

// func getDisk(path string) (DiskInfo, error) {

// 	var stat syscall.Statfs_t

// 	err := syscall.Statfs(path, &stat)
// 	if err != nil {
// 		return DiskInfo{}, err
// 	}

// 	blockSize := uint64(stat.Bsize)

// 	totalBytes := stat.Blocks * blockSize
// 	freeBytes := stat.Bavail * blockSize

// 	if totalBytes == 0 {
// 		return DiskInfo{}, nil
// 	}

// 	usedBytes := totalBytes - freeBytes

// 	totalGB := float64(totalBytes) / 1024 / 1024 / 1024
// 	usedGB := float64(usedBytes) / 1024 / 1024 / 1024

// 	usage := float64(usedBytes) /
// 		float64(totalBytes) * 100

// 	return DiskInfo{
// 		TotalGB: round(totalGB),
// 		UsedGB:  round(usedGB),
// 		Usage:   round(usage),
// 	}, nil
// }

// // ============================================================
// // Temperature / Fan / Power
// //
// // /sys/class/hwmon/hwmon*
// // ============================================================

// func getSensors() []SensorInfo {

// 	result := make([]SensorInfo, 0)

// 	entries, err := os.ReadDir("/sys/class/hwmon")
// 	if err != nil {
// 		return result
// 	}

// 	for _, entry := range entries {

// 		if !entry.IsDir() {
// 			continue
// 		}

// 		dir := filepath.Join(
// 			"/sys/class/hwmon",
// 			entry.Name(),
// 		)

// 		hwmonName := readString(
// 			filepath.Join(dir, "name"),
// 		)

// 		if hwmonName == "" {
// 			hwmonName = entry.Name()
// 		}

// 		files, err := os.ReadDir(dir)
// 		if err != nil {
// 			continue
// 		}

// 		for _, file := range files {

// 			filename := file.Name()

// 			// ------------------------------------------------
// 			// Temperature
// 			// ------------------------------------------------

// 			if strings.HasPrefix(filename, "temp") &&
// 				strings.HasSuffix(filename, "_input") {

// 				value, err := readFloat(
// 					filepath.Join(dir, filename),
// 				)

// 				if err != nil {
// 					continue
// 				}

// 				// milli-degree Celsius
// 				value = value / 1000

// 				labelName := strings.TrimSuffix(
// 					filename,
// 					"_input",
// 				) + "_label"

// 				label := readString(
// 					filepath.Join(dir, labelName),
// 				)

// 				if label == "" {
// 					label = hwmonName
// 				}

// 				result = append(result, SensorInfo{
// 					Name:  label,
// 					Type:  "temperature",
// 					Value: round(value),
// 					Unit:  "C",
// 				})

// 				continue
// 			}

// 			// ------------------------------------------------
// 			// Fan
// 			// ------------------------------------------------

// 			if strings.HasPrefix(filename, "fan") &&
// 				strings.HasSuffix(filename, "_input") {

// 				value, err := readFloat(
// 					filepath.Join(dir, filename),
// 				)

// 				if err != nil {
// 					continue
// 				}

// 				labelName := strings.TrimSuffix(
// 					filename,
// 					"_input",
// 				) + "_label"

// 				label := readString(
// 					filepath.Join(dir, labelName),
// 				)

// 				if label == "" {
// 					label = hwmonName
// 				}

// 				result = append(result, SensorInfo{
// 					Name:  label,
// 					Type:  "fan",
// 					Value: round(value),
// 					Unit:  "RPM",
// 				})

// 				continue
// 			}

// 			// ------------------------------------------------
// 			// Power
// 			// ------------------------------------------------

// 			if strings.HasPrefix(filename, "power") &&
// 				strings.HasSuffix(filename, "_input") {

// 				value, err := readFloat(
// 					filepath.Join(dir, filename),
// 				)

// 				if err != nil {
// 					continue
// 				}

// 				// microwatt → watt
// 				value = value / 1000000

// 				labelName := strings.TrimSuffix(
// 					filename,
// 					"_input",
// 				) + "_label"

// 				label := readString(
// 					filepath.Join(dir, labelName),
// 				)

// 				if label == "" {
// 					label = hwmonName
// 				}

// 				result = append(result, SensorInfo{
// 					Name:  label,
// 					Type:  "power",
// 					Value: round(value),
// 					Unit:  "W",
// 				})
// 			}
// 		}
// 	}

// 	return result
// }

// // ============================================================
// // NVIDIA GPU
// // ============================================================

// // func getGPU() []GPUInfo {

// // 	result := make([]GPUInfo, 0)

// // 	cmd := exec.Command(
// // 		"nvidia-smi",
// // 		"--query-gpu=name,temperature.gpu,utilization.gpu,memory.used,memory.total,power.draw",
// // 		"--format=csv,noheader,nounits",
// // 	)

// // 	output, err := cmd.Output()
// // 	if err != nil {
// // 		return result
// // 	}

// // 	lines := strings.Split(
// // 		strings.TrimSpace(string(output)),
// // 		"\n",
// // 	)

// // 	for _, line := range lines {

// // 		line = strings.TrimSpace(line)

// // 		if line == "" {
// // 			continue
// // 		}

// // 		fields := strings.Split(line, ",")

// // 		if len(fields) < 6 {
// // 			continue
// // 		}

// // 		temp, err1 := strconv.ParseFloat(
// // 			strings.TrimSpace(fields[1]), 64,
// // 		)

// // 		usage, err2 := strconv.ParseFloat(
// // 			strings.TrimSpace(fields[2]), 64,
// // 		)

// // 		memUsed, err3 := strconv.ParseFloat(
// // 			strings.TrimSpace(fields[3]), 64,
// // 		)

// // 		memTotal, err4 := strconv.ParseFloat(
// // 			strings.TrimSpace(fields[4]), 64,
// // 		)

// // 		power, err5 := strconv.ParseFloat(
// // 			strings.TrimSpace(fields[5]), 64,
// // 		)

// // 		if err1 != nil ||
// // 			err2 != nil ||
// // 			err3 != nil ||
// // 			err4 != nil ||
// // 			err5 != nil {
// // 			continue
// // 		}

// // 		result = append(result, GPUInfo{
// // 			Name:        strings.TrimSpace(fields[0]),
// // 			Temperature: round(temp),
// // 			Usage:       round(usage),
// // 			MemoryUsed:  round(memUsed),
// // 			MemoryTotal: round(memTotal),
// // 			Power:       round(power),
// // 		})
// // 	}

// // 	return result
// // }

// // ============================================================
// // Utility
// // ============================================================

// func readString(path string) string {

// 	data, err := os.ReadFile(path)
// 	if err != nil {
// 		return ""
// 	}

// 	return strings.TrimSpace(string(data))
// }

// func readFloat(path string) (float64, error) {

// 	value := readString(path)

// 	if value == "" {
// 		return 0, fmt.Errorf("empty value")
// 	}

// 	return strconv.ParseFloat(value, 64)
// }

// func round(value float64) float64 {

// 	return float64(
// 		int64(value*100+0.5),
// 	) / 100
// }

// // ============================================================
// // main
// // ============================================================

// func main() {

// 	// CPU
// 	cpuUsage := getCPUUsage()

// 	// Load
// 	load1, load5, load15 := getLoadAverage()

// 	// Memory
// 	memory := getMemory()

// 	// Disk
// 	disks := make(map[string]DiskInfo)

// 	// 필요한 경로만 추가
// 	diskPaths := []string{
// 		"/home1",
// 		// "/data",
// 	}

// 	for _, path := range diskPaths {

// 		if _, err := os.Stat(path); err != nil {
// 			continue
// 		}

// 		info, err := getDisk(path)
// 		if err != nil {
// 			continue
// 		}

// 		disks[path] = info
// 	}

// 	// Temperature / Fan / Power
// 	sensors := getSensors()

// 	// NVIDIA GPU
// 	// gpu := getGPU()

// 	// 결과 생성
// 	metrics := Metrics{
// 		Time: time.Now().Format(time.RFC3339),

// 		CPU: CPUInfo{
// 			Usage: cpuUsage,
// 			Load1: load1,
// 			Load5: load5,
// 			Load15: load15,
// 		},

// 		Memory: memory,

// 		Disks: disks,

// 		Sensors: sensors,

// 		// GPU: gpu,
// 	}

// 	// JSON 생성
// 	data, err := json.Marshal(metrics)
// 	if err != nil {
// 		fmt.Fprintln(os.Stderr, "JSON error:", err)
// 		os.Exit(1)
// 	}

// 	// JSON 한 줄 출력
// 	fmt.Println(string(data))
// }