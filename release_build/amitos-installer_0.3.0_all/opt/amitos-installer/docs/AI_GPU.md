# AI & GPU Setup Guide

This guide covers setting up and using the AI and GPU-accelerated runtimes included in **amitOS**.

---

## Overview

amitOS ships with a complete AI inference stack pre-installed, optimized for NVIDIA GPUs:

| Component | Version | Purpose |
|---|---|---|
| Python | 3.10+ | Primary language for AI development |
| CUDA Toolkit | 11+ | GPU parallel computing platform |
| cuDNN | Latest stable | Deep learning primitives |
| NCCL | Latest stable | Multi-GPU communication |
| PyTorch | Latest (CUDA build) | Training & inference |
| TensorFlow-GPU | Latest | GPU-accelerated inference |
| ONNX Runtime | Latest | Cross-framework inference |
| TensorFlow Lite | Latest | Lightweight on-device inference |
| OpenCV | Latest (CUDA build) | Computer vision with GPU |
| Docker | Latest | Container-native AI deployment |

---

## Verifying GPU Setup

```bash
# Check NVIDIA GPU is detected
nvidia-smi

# Check CUDA version
nvcc --version

# Check Python AI stack
python3 -c "
import torch
import onnxruntime as ort
import tensorflow as tf

print('=== AI Runtime Status ===')
print(f'PyTorch: {torch.__version__}')
print(f'CUDA available (PyTorch): {torch.cuda.is_available()}')
print(f'GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"None\"}')
print(f'ONNX Runtime providers: {ort.get_available_providers()}')
print(f'TensorFlow GPUs: {tf.config.list_physical_devices(\"GPU\")}')
"
```

Expected output on a GPU-equipped system:

```
=== AI Runtime Status ===
PyTorch: 2.x.x
CUDA available (PyTorch): True
GPU: NVIDIA GeForce RTX 3080
ONNX Runtime providers: ['CUDAExecutionProvider', 'CPUExecutionProvider']
TensorFlow GPUs: [PhysicalDevice(name='/physical_device:GPU:0', device_type='GPU')]
```

---

## Running Inference with ONNX Runtime

ONNX Runtime is the recommended inference engine for production use on amitOS due to its broad model compatibility and CUDA acceleration.

```python
import onnxruntime as ort
import numpy as np

# Load a model (export from PyTorch/TF first)
session = ort.InferenceSession(
    "model.onnx",
    providers=["CUDAExecutionProvider", "CPUExecutionProvider"]
)

# Get input/output names
input_name = session.get_inputs()[0].name
output_name = session.get_outputs()[0].name

# Run inference
input_data = np.random.float32((1, 3, 224, 224))
result = session.run([output_name], {input_name: input_data})
print("Prediction:", result)
```

---

## Running Inference with TensorFlow Lite

TF-Lite is ideal for very lightweight, low-latency inference on edge devices:

```python
import tflite_runtime.interpreter as tflite
import numpy as np

interpreter = tflite.Interpreter(model_path="model.tflite")
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

input_data = np.array(np.random.random_sample((1, 224, 224, 3)), dtype=np.float32)
interpreter.set_tensor(input_details[0]['index'], input_data)
interpreter.invoke()

output_data = interpreter.get_tensor(output_details[0]['index'])
print("Output:", output_data)
```

---

## PyTorch GPU Inference

```python
import torch
import torchvision.models as models

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f"Using device: {device}")

# Load a pretrained model
model = models.resnet50(pretrained=True)
model = model.to(device)
model.eval()

# Create random input (batch of 1 image, 3 channels, 224x224)
x = torch.randn(1, 3, 224, 224).to(device)

with torch.no_grad():
    output = model(x)

print("Output shape:", output.shape)
```

---

## OpenCV with CUDA

```python
import cv2

# Check OpenCV CUDA support
cuda_count = cv2.cuda.getCudaEnabledDeviceCount()
print(f"CUDA devices available to OpenCV: {cuda_count}")

# GPU-accelerated Gaussian blur
img = cv2.imread("image.jpg")
gpu_img = cv2.cuda_GpuMat()
gpu_img.upload(img)

gaussian = cv2.cuda.createGaussianFilter(
    cv2.CV_8UC3, cv2.CV_8UC3, (15, 15), 2
)
blurred_gpu = gaussian.apply(gpu_img)
blurred = blurred_gpu.download()

cv2.imwrite("blurred.jpg", blurred)
```

---

## Deploying AI Models with Docker

amitOS includes Docker for container-native AI deployments:

```bash
# Pull an NVIDIA CUDA base image
docker pull nvidia/cuda:11.8-base-ubuntu22.04

# Run a container with GPU access
docker run --gpus all -it nvidia/cuda:11.8-base-ubuntu22.04 bash

# Verify GPU in container
nvidia-smi
```

**Example Dockerfile for an AI service:**

```dockerfile
FROM nvidia/cuda:11.8-cudnn8-runtime-ubuntu22.04

RUN apt-get update && apt-get install -y python3 python3-pip
RUN pip3 install onnxruntime-gpu numpy

COPY model.onnx /app/model.onnx
COPY inference.py /app/inference.py

CMD ["python3", "/app/inference.py"]
```

---

## Troubleshooting

| Issue | Solution |
|---|---|
| `nvidia-smi` command not found | Install NVIDIA drivers: `sudo apt install nvidia-driver-525` |
| CUDA not available in PyTorch | Verify CUDA version matches PyTorch build: `torch.version.cuda` |
| Out of memory error | Reduce batch size, use `torch.cuda.empty_cache()` |
| ONNX model not using GPU | Ensure `CUDAExecutionProvider` is first in providers list |
| Docker GPU not available | Install `nvidia-container-toolkit` and restart Docker daemon |

---

## Resources

- [CUDA Toolkit Documentation](https://docs.nvidia.com/cuda/)
- [ONNX Runtime Documentation](https://onnxruntime.ai/docs/)
- [PyTorch Documentation](https://pytorch.org/docs/)
- [TensorFlow GPU Guide](https://www.tensorflow.org/guide/gpu)
