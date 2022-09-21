---
title: "Running Tensorflow 2.4 on RTX 30 Series with Docker"
date: 2020-12-18
sort_by: "date"
author: kotatsuyaki (Ming-Long Huang)
---

Recently I've got my hands on a brand-new RTX 3070 GPU to perform machine learning tasks.
However, the environment setup wasn't as smooth as I expected, due to the hardware being too recent.

- OS: Gentoo Linux X86-64
- GPU: RTX 3070

Until recently I've been using [the Docker images from Nvidia NGC](https://ngc.nvidia.com/catalog/containers/nvidia:tensorflow/tags) exclusively, because they were the only things that actually work,
without going through the horrible compiling process which takes ages.
Later on I found that a new stable release TF 2.4 was out, and that it seems to support CUDA 11 out-of-the-box.

<!-- more -->

Here's a short note of how to make it work.

1. Pull the `tensorflow/tensorflow:2.4.0-gpu` image from Docker hub.
2. Spin up a container with that image:
    ```
    docker run -itd --rm --network=host --shm-size 16G --gpus all -v $(pwd):/data/
    ```

3. Apply temporary fix for [the `Value 'sm_86' is not defined for option 'gpu-name'` issue](https://github.com/tensorflow/tensorflow/issues/45590).
    - Download [CUDA 11.1 installer runfile](https://developer.download.nvidia.com/compute/cuda/11.1.0/local_installers/cuda_11.1.0_455.23.05_linux.run).
    - `chmod +x` it.
    - Run the runfile with `--tar mxvf` as the arguments.
    - Replace the `ptxas` binary inside the Docker image (which is CUDA 11.0) with the 11.1 version.
        ```
        cp $(find . -name 'ptxas') /usr/local/cuda/bin/ptxas
        ```

    Before this fix, there's a lot of warning messages like this during the trainign process, and the training of the first epoch is hugely affected (about 17 seconds, while it should take only 7 seconds).

    ```
    Your CUDA software stack is old. We fallback to the NVIDIA driver for some compilation. Update your CUDA version to get the best performance. The ptxas error was: ptxas fatal : Value 'sm_86' is not defined for option 'gpu-name'
    ```

    After applying this hacky fix, the issue seems to be gone.

## Sources

- <https://github.com/tensorflow/tensorflow/issues/45590>
- <https://github.com/tensorflow/tensorflow/issues/44750>
- <https://dobromyslova.medium.com/making-work-tensorflow-with-nvidia-rtx-3090-on-windows-10-7a38e8e582bf>

