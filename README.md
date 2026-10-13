
# DeepStream GPU Video Analytics Pipeline

## 1. Project Overview

This project implements a GPU-accelerated video analytics pipeline using:

- NVIDIA DeepStream SDK
- NVIDIA CUDA
- YOLO11m object detection
- ONNX model format
- NVIDIA DeepStream multi-object tracking
- Python-compatible CSV/report outputs and shell automation

The input video is processed to detect and track objects such as cars and people.

**Important:** GPU execution must be performed on a compatible NVIDIA GPU system with working NVIDIA drivers, container GPU support, CUDA and a compatible DeepStream installation. Creating these files on Windows does not prove that the pipeline will run successfully.

## 2. Project Tasks

### Task A — Object Detection

Objective:
- Load the input video.
- Run YOLO11m inference using the ONNX model.
- Detect objects and draw bounding boxes.
- Save the annotated output video and logs.

Expected output:
- `06_outputs/task_a_detection/videos/detection_output.mp4`
- Task A logs and reports.

### Task B — Object Detection and Tracking

Objective:
- Run YOLO11m object detection.
- Associate detections across video frames using the configured DeepStream tracker.
- Draw bounding boxes and tracking IDs.
- Save the annotated tracking video and logs.

Expected output:
- `06_outputs/task_b_tracking/videos/tracked_output.mp4`
- Task B logs, tracks and reports.

Note: The current configuration uses NVIDIA's NvDCF tracker. This is not MCByteTrack. If MCByteTrack is a mandatory project requirement, it must be integrated and tested separately rather than described as completed.

### Task C — Performance Benchmarking

Objective:
- Execute the detection pipeline.
- Record execution duration and available GPU information.
- Generate a CSV and a text report.

Expected output:
- `06_outputs/task_c_benchmark/csv/`
- `06_outputs/task_c_benchmark/reports/`
- `06_outputs/task_c_benchmark/logs/`

Total runtime is not the same as inference FPS. Actual FPS should be calculated from DeepStream's performance measurements or frame-processing timestamps.

## 3. Project Structure

```text
DeepStream_GPU_Pipeline/
├── 00_setup/
├── 01_input/
│   └── PNNL_Parking_LOT(1).avi
├── 02_models/
│   ├── yolo11m.onnx
│   ├── labels.txt
│   └── nvdsinfer_custom_impl_Yolo/
├── 03_pipeline/
│   ├── config_infer_primary.txt
│   ├── deepstream_detection_config.txt
│   ├── deepstream_app_config.txt
│   └── config_tracker_NvDCF_perf.yml
├── 04_tasks/
│   ├── task_a_detection.sh
│   ├── task_b_tracking.sh
│   └── task_c_performance.sh
├── 05_scripts/
│   ├── build_parser.sh
│   ├── check_project.sh
│   └── run_all.sh
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

## 4. Input and Model

Input video:
`01_input/PNNL_Parking_LOT(1).avi`

Detection model:
`02_models/yolo11m.onnx`

Model input observed during inspection:
- Tensor name: `images`
- Shape: `[1, 3, 640, 640]`

Model output observed during inspection:
- Tensor name: `output0`
- Shape: `[1, 84, 8400]`

The model's ONNX structure was inspected separately. The DeepStream custom parser, tensor decoding, preprocessing and output detections must still be validated on the target system.

## 5. Requirements

Target system:
- Compatible NVIDIA GPU
- Compatible NVIDIA driver
- Docker with NVIDIA GPU container support, if using containers
- Compatible NVIDIA DeepStream SDK/container image
- CUDA/toolchain compatible with the selected DeepStream version
- Sufficient disk space for the model, video, generated engine and outputs

The Windows preparation computer does not need to execute GPU inference if the project will be transferred to another compatible system.

## 6. Execution Workflow

Perform these steps on the target GPU system, after confirming the OS and DeepStream version.

1. Extract the project ZIP.
2. Confirm that the input video and ONNX model exist.
3. Verify NVIDIA GPU access.
4. Start a compatible DeepStream development environment.
5. Build the custom YOLO parser inside that environment.
6. Verify that the parser library exports the expected YOLOv11 parser function.
7. Validate the inference configuration and test a short run.
8. Execute Task A and inspect the output video.
9. Execute Task B and inspect the tracking IDs.
10. Execute Task C and validate the benchmark report.
11. Review logs and outputs before sharing results.

Do not run all tasks before the parser, inference configuration and a short detection test have passed.

## 7. Scripts

`00_setup/check_windows.ps1`
- Checks selected Windows-side prerequisites and assets.

`05_scripts/build_parser.sh`
- Builds the custom parser inside a compatible DeepStream development environment.

`05_scripts/check_project.sh`
- Checks expected project files and selected Linux commands.

`04_tasks/task_a_detection.sh`
- Runs the detection configuration.

`04_tasks/task_b_tracking.sh`
- Runs the tracking configuration.

`04_tasks/task_c_performance.sh`
- Runs the performance measurement workflow.

`05_scripts/run_all.sh`
- Runs the configured tasks sequentially, stopping if a task fails.

These scripts are not proof of successful execution. Validate every task on the target GPU system.

## 8. Troubleshooting

### GPU is not visible
Check the NVIDIA driver, GPU status and container GPU passthrough on the target machine.

### `deepstream-app` is not found
The shell is not running in an environment where DeepStream is installed and available on PATH.

### Custom parser library is missing
Build the parser inside a compatible DeepStream development environment and confirm that the resulting `.so` file is accessible.

### ONNX parser or output errors
Check the DeepStream version, ONNX support, parser ABI, tensor output layout, preprocessing and class count.

### Output video is missing
Check the task logs, output directory permissions, sink configuration and encoder availability.

### Tracker configuration errors
Use the tracker configuration supplied with the installed DeepStream version as the starting point, then validate each customization.

## 9. Results and Reporting

Record:
- DeepStream version
- NVIDIA GPU model
- Driver and CUDA versions
- Input video properties
- Frames processed
- Detection counts by class
- Actual measured FPS
- Total execution duration
- Tracking results and ID consistency
- Errors or warnings
- Output file locations

Only report measured values from actual target-system runs. Do not treat planned outputs as completed results.

## 10. Current Status

The project files and model assets are being prepared on Windows for transfer to a separate GPU system.

GPU inference, custom parser compilation, tracker behavior, output generation and performance results remain pending target-system validation.
