# DeepStream GPU Video Analytics Pipeline

## 1. Project Overview

This project implements a GPU-accelerated video analytics pipeline using NVIDIA DeepStream SDK, CUDA, TensorRT, and YOLO11m.

The pipeline supports object detection, multi-object tracking, live visualization, video recording, and performance benchmarking on a compatible NVIDIA GPU system.

### Technology Stack

- NVIDIA DeepStream SDK 7.0
- NVIDIA CUDA
- NVIDIA TensorRT
- YOLO11m object detection
- ONNX model format
- GStreamer
- NVIDIA NvDCF multi-object tracker
- Bash automation
- CSV and text-based benchmark reports

**Important:** GPU execution requires a compatible NVIDIA GPU, working drivers, CUDA/TensorRT compatibility, and a compatible DeepStream installation. Creating or editing project files on Windows does not prove that GPU execution will work on the target system.

## 2. Project Tasks

### Task A — Object Detection

**Objective**
- Load video sources.
- Run YOLO11m inference using the ONNX model.
- Detect objects such as people and vehicles.
- Draw bounding boxes and class labels.
- Display the processed video when the display environment is available.
- Save annotated videos and execution logs.

**Configuration**

`03_pipeline/deepstream_detection_config.txt`

**Output directory**

`06_outputs/task_a_detection/videos/`

The primary output is configured as:

`detection_output.mp4`

Additional source-specific output videos may be configured for the other input streams.

### Task B — Object Detection and Tracking

**Objective**
- Run YOLO11m object detection.
- Associate detected objects across video frames.
- Assign tracking IDs to tracked objects.
- Render object bounding boxes and labels.
- Display the live tracking pipeline when the display environment is available.
- Save tracked video outputs and logs.

**Configuration**

`03_pipeline/deepstream_app_config.txt`

**Tracker**

The current configuration uses NVIDIA's NvDCF multi-object tracker.

**Important:** NvDCF is not MCByteTrack. If MCByteTrack is a mandatory project requirement, it must be integrated and tested separately.

#### Tracking ID Requirements

The intended output should:
- Assign a distinct tracking ID to each active object track.
- Preserve an object's ID across consecutive frames while its track remains valid.
- Display tracking IDs alongside object labels and bounding boxes.
- Render the tracking information in both the live display and saved videos.

Separate person and car numbering, such as `Person ID: 1` and `Car ID: 1`, requires additional class-aware label formatting if independent numbering sequences are required. The standard tracker configuration alone does not establish that this behavior has been implemented.

Tracking IDs, their persistence, and their visibility must be verified by inspecting the actual output videos.

**Output directory**

`06_outputs/task_b_tracking/videos/`

The primary output is configured as:

`tracked_output.mp4`

Additional source-specific tracking videos may be configured for the other input streams.

### Task C — Performance Benchmarking

**Objective**
- Execute the configured detection pipeline.
- Collect available DeepStream performance measurements.
- Record execution duration.
- Generate CSV results and text reports.
- Store benchmark logs separately from detection and tracking outputs.

**Configuration**

`03_pipeline/deepstream_benchmark_config.txt`

**Output directory**

`06_outputs/task_c_benchmark/`

Expected subdirectories:

- `csv/`
- `reports/`
- `logs/`
- `charts/`

Total execution duration is not equivalent to inference FPS. Use actual DeepStream performance measurements or frame-processing timestamps when reporting FPS.

## 3. Project Structure

```text
DeepStream_GPU_Pipeline/
├── 00_setup/
│   ├── check_target.sh
│   └── check_windows.ps1
├── 01_input/
│   ├── PNNL_Parking_LOT(1).avi
│   ├── car-detection.mp4
│   ├── people-detection.mp4
│   └── person-bicycle-car-detection.mp4
├── 02_models/
│   ├── yolo11m.onnx
│   ├── labels.txt
│   └── nvdsinfer_custom_impl_Yolo/
├── 03_pipeline/
│   ├── config_infer_primary.txt
│   ├── deepstream_detection_config.txt
│   ├── deepstream_app_config.txt
│   ├── deepstream_benchmark_config.txt
│   └── config_tracker_NvDCF_perf.yml
├── 04_tasks/
│   ├── task_a_detection.sh
│   ├── task_b_tracking.sh
│   └── task_c_performance.sh
├── 05_scripts/
│   ├── build_parser.sh
│   ├── check_project.sh
│   ├── run_all.sh
│   └── start_deepstream_container.sh
├── 06_outputs/
│   ├── task_a_detection/
│   ├── task_b_tracking/
│   ├── task_c_benchmark/
│   ├── logs/
│   └── summary/
├── 07_docs/
├── README.md
└── requirements.txt
```

The exact files available may vary as the project evolves.

## 4. Input Videos and Model

### Input Videos

The project contains four input videos:

1. `PNNL_Parking_LOT(1).avi`
2. `car-detection.mp4`
3. `people-detection.mp4`
4. `person-bicycle-car-detection.mp4`

The pipeline configuration uses four video sources for multi-source processing.

### Detection Model

Model file:

`02_models/yolo11m.onnx`

The model was inspected and reported to contain:

- Input tensor: `images`
- Input shape: `[1, 3, 640, 640]`
- Output tensor: `output0`
- Output shape: `[1, 84, 8400]`
- ONNX opset: 18

The TensorRT engine was generated or loaded on the GPU system during previous pipeline testing.

The ONNX structure alone does not establish that preprocessing, inference, parser decoding, class labels, and bounding boxes are all correct. These must be validated using actual inference outputs.

### Custom YOLO Parser

Parser source files are located under:

`02_models/nvdsinfer_custom_impl_Yolo/`

The compiled parser library is expected at:

`02_models/nvdsinfer_custom_impl_Yolo/libnvdsinfer_custom_impl_Yolo.so`

The library must be compiled against a compatible DeepStream environment. When moving the project to another machine, rebuild or validate the library as necessary.

## 5. Target System Requirements

The GPU system should have:

- A compatible NVIDIA GPU.
- A working NVIDIA driver.
- NVIDIA DeepStream SDK compatible with the installed environment.
- Compatible CUDA and TensorRT components.
- GStreamer and `deepstream-app`.
- The YOLO11m ONNX model and labels file.
- The custom YOLO parser library.
- Sufficient disk space for input videos, generated TensorRT engines, logs, and outputs.

Docker is optional when DeepStream is installed natively. If using a container, NVIDIA GPU container support must be configured correctly.

The Windows preparation system does not need to execute GPU inference if the project will be transferred to another compatible system.

## 6. Verify the GPU Environment

Run the following commands on the target Linux GPU system.

Check GPU availability:

```bash
nvidia-smi
```

Check DeepStream:

```bash
deepstream-app --version-all
```

Check CUDA compiler availability:

```bash
nvcc --version
```

Check the YOLO model and labels:

```bash
ls -lh 02_models/yolo11m.onnx
ls -lh 02_models/labels.txt
```

Check the parser library:

```bash
ls -lh 02_models/nvdsinfer_custom_impl_Yolo/libnvdsinfer_custom_impl_Yolo.so
```

These checks establish whether the expected tools and files are available; they do not guarantee that every pipeline task will succeed.

## 7. Execution Workflow

Perform the following steps on the target GPU system.

1. Extract or clone the project.
2. Confirm that all required input videos exist.
3. Confirm that the ONNX model and labels are available.
4. Verify NVIDIA GPU access using `nvidia-smi`.
5. Verify that `deepstream-app` is available.
6. Confirm the installed DeepStream version.
7. Build or validate the custom YOLO parser.
8. Verify model, parser, input URI, and output path configurations.
9. Run Task A and inspect the detection video.
10. Run Task B and inspect the tracking IDs.
11. Run Task C and validate the benchmark outputs.
12. Review the logs and reports.
13. Run the complete orchestration script after individual tasks have been validated.

Do not assume that all four sources are processed successfully simply because a configuration contains four source sections. Confirm source activity, output files, and logs.

## 8. Run Individual Tasks

Run the commands from the project root directory.

### Task A — Detection

```bash
bash 04_tasks/task_a_detection.sh
```

Output directory:

`06_outputs/task_a_detection/videos/`

### Task B — Tracking

```bash
bash 04_tasks/task_b_tracking.sh
```

Output directory:

`06_outputs/task_b_tracking/videos/`

The tracking configuration uses NvDCF. Check the live window and the saved videos to confirm that tracking IDs and object labels are rendered correctly.

### Task C — Benchmarking

```bash
bash 04_tasks/task_c_performance.sh
```

Output directory:

`06_outputs/task_c_benchmark/`

Check the generated CSV, text report, and logs for actual measurements.

### Run All Tasks

```bash
bash 05_scripts/run_all.sh
```

The orchestration script runs Task A, Task B, and Task C sequentially. It records an execution log and summary and stops when a task fails.

Review the final status before reporting a successful end-to-end run.

## 9. Output Organization

| Task | Output directory |
|---|---|
| Detection videos | `06_outputs/task_a_detection/videos/` |
| Tracking videos | `06_outputs/task_b_tracking/videos/` |
| Benchmark CSV | `06_outputs/task_c_benchmark/csv/` |
| Benchmark reports | `06_outputs/task_c_benchmark/reports/` |
| Benchmark logs | `06_outputs/task_c_benchmark/logs/` |
| General execution logs | `06_outputs/logs/` |
| Execution summaries | `06_outputs/summary/` |

Output filenames depend on the configured sinks. Check each configuration for the exact filename and source ID.

For four separate output videos per task, configure and validate a recording sink for each source. A tiled display is a combined view and is not the same as four separate video files.

## 10. Troubleshooting

### GPU Not Detected

Check the NVIDIA driver and GPU status:

```bash
nvidia-smi
```

If using Docker, verify NVIDIA GPU passthrough and container runtime configuration.

### `deepstream-app` Not Found

The current shell environment may not have DeepStream installed or available on `PATH`. Use a compatible DeepStream environment.

### Custom Parser Library Missing

Build the custom parser using the compatible DeepStream development environment and verify the expected library path.

### ONNX or TensorRT Errors

Check the DeepStream version, TensorRT compatibility, ONNX model, tensor layout, preprocessing, parser ABI, and class count.

### Output Video Missing

Check:
- Task logs.
- Output directory permissions.
- Recording sink configuration.
- Source IDs.
- Encoder availability.
- Pipeline completion status.

### Tracking IDs Not Visible

Check:
- Tracker initialization.
- Tracker metadata.
- `display-tracking-id` configuration.
- OSD text rendering.
- Tiled-display options.
- The saved video itself.

A successful pipeline exit does not guarantee that the ID text is visible in the rendered video.

### Permission Errors

Check file and directory permissions before modifying configurations or running tasks. Do not use `sudo` unless authorized on the target system.

## 11. Performance and Results Reporting

Record actual measured values for:

- DeepStream version.
- NVIDIA GPU model.
- NVIDIA driver version.
- CUDA and TensorRT versions.
- Input video resolution and FPS.
- Number of sources processed.
- Frames processed per source.
- Detection counts by class.
- Tracking behavior and ID consistency.
- Measured FPS.
- Total execution duration.
- Output video locations.
- Errors and warnings.

Do not report planned outputs as completed results. Do not infer tracking accuracy or FPS from configuration files alone.

## 12. Current Status

The project has been tested on a Linux GPU server with NVIDIA DeepStream 7.0 and an NVIDIA RTX 3060 GPU.

Previous Task B execution logs reported:
- NvDCF tracker initialization.
- Four source performance entries.
- End-of-stream handling for all four sources.
- Successful pipeline completion.

These logs confirm that the tracking application completed a run. They do not, by themselves, verify tracking accuracy, class-specific ID numbering, or visibility of tracking IDs in every saved output video.

The following items must be validated against the latest configuration and generated files:
- Separate detection videos for all four inputs.
- Separate tracking videos for all four inputs.
- Tracking ID visibility in the live display and saved recordings.
- Class-specific person and car numbering, if required.
- Benchmark CSV and report correctness.
- Complete successful execution of `run_all.sh`.

## 13. Repository

GitHub repository:

https://github.com/Sunkara-Harshitha09/DeepStream-GPU-Pipeline