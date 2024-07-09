#Docker file for GNU Radio 3.10 - build from source. 
#This is my first docker file as an expierment

FROM ubuntu:22.04

LABEL mainitainer="Ric Soard"

#Connect to the x server
RUN export uid=1000 gid=1000
RUN mkdir -p /home/docker_user
RUN echo "docker_user:x:${uid}:${gid}:docker_user,,,:/home/docker_user:/bin/bash" >> /etc/passwd
RUN echo "docker_user:x:${uid}:" >> /etc/group
#RUN     echo "docker_user ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/docker_user
#RUN     chmod 0440 /etc/sudoers.d/docker_user
RUN chown ${uid}:${gid} -R /home/docker_user 

USER    docker_user 
ENV     HOME=/home/docker_user 

#This will allow apt-get to install without questions
ARG DEBIAN_FRONTEND=noninteractive

#install dependencies
#GNU Radio 3.8 dependencies
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install -q \
    git \
    cmake \
    g++ \
    libboost-all-dev \
    libgmp-dev \
    swig python3-numpy \
    python3-mako \
    python3-sphinx \
    python3-lxml \
    doxygen \
    libfftw3-dev \
    libsdl1.2-dev \
    libgsl-dev \
    libqwt-qt5-dev \
    libqt5opengl5-dev \
    python3-pyqt5 \
    liblog4cpp5-dev \
    libzmq3-dev \
    python3-yaml \
    python3-click \
    python3-click-plugins \
    python3-zmq \
    python3-scipy \
    python3-gi \
    python3-gi-cairo \
    gir1.2-gtk-3.0 \
    libcodec2-dev \
    libgsm1-dev \
    libusb-1.0-0 \
    libusb-1.0-0-dev \
    libudev-dev \
    python3-setuptools

#GNU Radio 3.9 dependencies
RUN apt-get -y install -q \
    pybind11-dev \
    python3-matplotlib \
    libsndfile1-dev \
    libsoapysdr-dev \
    soapysdr-tools \
    python3-pygccxml \
    python3-pyqtgraph

#GNU Radio 3.10 dependencies
RUN  apt-get -y install -q \
    libiio-dev \
    libad9361-dev \
    libspdlog-dev \
    python3-packaging \
    python3-jsonschema \
    python3-qtpy

RUN apt-get -y install libcanberra-gtk3-module
#Since GNU Radio 3.9.x, swig has been replaced with pybind11 and can be removed:
RUN apt-get -y remove swig
 
#install UHD For Ettus Radios - Changed make to 10 jobs from 3 jobs
RUN cd /home && \
    git clone https://github.com/EttusResearch/uhd.git && \ 
    cd uhd && \ 
    git checkout v4.7.0.0 && \ 
    cd host && \ 
    mkdir build && \
    cd build && \ 
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local ../ && \ 
    make -j10 && \ 
    make test && \
    make install && \
    ldconfig 

#Download the FPGA Images
RUN uhd_images_downloader

#There might be more work required to connect to the USRP Radio via ethernet

#install Volk from source added 10 jobs to make commmand
RUN cd /home && \
    git clone --recursive https://github.com/gnuradio/volk.git && \
    cd volk && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DPYTHON_EXECUTABLE=/usr/bin/python3 ../ && \
    make -j10 && \
    make test && \
    make install && \
    ldconfig

#add this environment variable to pass the qtgui test
ENV QT_QPA_PLATFORM=offscreen 

#install GNU Radio
RUN cd /home && \
    git clone https://github.com/gnuradio/gnuradio.git && \
    cd gnuradio && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DPYTHON_EXECUTABLE=/usr/bin/python3 ../ && \
    make -j10 && \
    make test && \
    make install && \
    ldconfig

#Run volk profile
RUN volk_profile

# Set this to xcb so we can run qt in privlidged mode
ENV QT_QPA_PLATFORM=xcb

CMD ["gnuradio-companion"]