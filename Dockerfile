FROM kalilinux/kali-rolling

RUN apt update && apt install -y \
    git curl wget python3 python3-pip \
    ca-certificates build-essential sudo \
    && apt clean

RUN useradd -ms /bin/bash rosemary && echo "rosemary:kali" | chpasswd && adduser rosemary sudo
RUN echo "rosemary ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER rosemary
WORKDIR /home/rosemary

CMD ["/bin/bash"]
