# VLSI-SoC 2026 "Agentic AI in EDA" environment (x86-64)
#   x86-64: the image of this Dockerfile is on Docker Hub, already built (recommended, no build needed):
#     docker pull --platform linux/amd64 kostasvarak/vlsi-soc26-ai:latest
#     docker tag kostasvarak/vlsi-soc26-ai:latest vlsi-soc26-ai
#   Build it yourself (1-2 hours):
#     docker build -t vlsi-soc26-ai .
#   ARM (Apple Silicon): use Dockerfile.arm64

FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
ARG APT_COMMAND="apt-get -o Acquire::Retries=3 -y"
ENV HOME=/home

RUN ${APT_COMMAND} update && ${APT_COMMAND} install wget curl build-essential gcc g++ gawk git make python3 lld bison clang flex \
    libffi-dev libfl-dev libreadline-dev pkg-config tcl-dev zlib1g-dev graphviz xdot

# installing OpenROAD with bazel #
WORKDIR /home
RUN wget https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64 && \
    chmod +x bazelisk-linux-amd64 && mv bazelisk-linux-amd64 /usr/local/bin/bazel && bazel --version

RUN git clone --recursive https://github.com/The-OpenROAD-Project/OpenROAD.git && \
    cd OpenROAD && bazel build //:openroad

# installing PIP #
RUN curl -sSL https://bootstrap.pypa.io/get-pip.py -o get-pip.py && python3 get-pip.py && rm get-pip.py

# installing YOSYS #
RUN git clone https://github.com/YosysHQ/yosys.git && pip3 install cmake && cd yosys && git submodule update --init && cmake -B build . -DCMAKE_BUILD_TYPE=Release && \
    cmake --build build --config Release --parallel $(nproc) && cmake --install build --strip

# installing KLayout binary #
RUN wget https://www.klayout.org/downloads/Ubuntu-22/klayout_0.30.12-1_amd64.deb && \
    ${APT_COMMAND} install ./klayout_0.30.12-1_amd64.deb && \
    rm klayout_0.30.12-1_amd64.deb

# installing OpenROAD flow scripts #
RUN git clone https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts.git

# setting the enviroment variables for OpenROAD and YOSYS #
ENV OPENROAD_EXE=/home/OpenROAD/bazel-bin/openroad
ENV YOSYS_EXE=/usr/local/bin/yosys

# make 'openroad' available in PATH (a wrapper keeps the Bazel runfiles next to the real binary) #
RUN printf '#!/bin/sh\nexec /home/OpenROAD/bazel-bin/openroad "$@"\n' > /usr/local/bin/openroad && \
    chmod +x /usr/local/bin/openroad && openroad -version

# installing Ollama and DSPY #
RUN ${APT_COMMAND} install zstd pciutils lshw && curl -fsSL https://ollama.com/install.sh | sh
RUN pip3 install ollama dspy pyyaml

# install iverilog #
RUN ${APT_COMMAND} install iverilog

# load the API keys (scripts/api_keys.sh, see README) in every interactive shell #
# (carriage returns are removed first, in case the file was saved with Windows line endings) #
RUN printf '%s\n' '[ -f /home/scripts/api_keys.sh ] && . <(tr -d "\r" < /home/scripts/api_keys.sh)' >> /etc/bash.bashrc

CMD ["sh", "-c", "ollama serve > /dev/null 2>&1 & sleep 2 && bash"]
