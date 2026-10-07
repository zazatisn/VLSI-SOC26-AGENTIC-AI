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
    apt install ./klayout_0.30.12-1_amd64.deb

# installing OpenROAD flow scripts #
RUN git clone https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts.git

# setting the enviroment variables for OpenROAD and YOSYS #
ENV OPENROAD_EXE=/home/OpenROAD/bazel-bin/openroad
ENV YOSYS_EXE=/usr/local/bin/yosys

# installing Ollama and DSPY #
RUN ${APT_COMMAND} install zstd pciutils lshw && curl -fsSL https://ollama.com/install.sh | sh
RUN pip3 install ollama dspy pyyaml

# install iverilog #
RUN ${APT_COMMAND} install iverilog

CMD ["sh", "-c", "ollama serve > /dev/null 2>&1 & sleep 2 && bash"]
