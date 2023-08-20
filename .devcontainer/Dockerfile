FROM ruby:2.7

LABEL maintainer="Amazon Web Services"

# Match the default user id for a single system so we aren't root
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000
ENV USERNAME=${USERNAME}
ENV USER_UID=${USER_UID}
ENV USER_GID=${USER_GID}

# Assuming extra libs could be installed to /usr/local
ENV LD_LIBRARY_PATH=/usr/local/lib

RUN apt-get update \
 && apt-get -qq install -y --no-install-recommends \
    sudo \
    python3-pip \
    python3 && \
    pip3 install tox && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    apt-get clean

ENV CHEF_LICENSE=accept-no-persist

# Done so does not fail if missing Gemfile.lock
COPY ./Gemfile* /tmp/
RUN cd /tmp && \
    bundle config set with 'style' && \
    bundle install && \
    curl -L https://omnitruck.cinc.sh/install.sh -o chefDownload.sh && \
    chmod +x chefDownload.sh && \    
    ./chefDownload.sh -c stable -P cinc-workstation

# Add the group and user that match our ids
RUN groupadd -g ${USER_GID} ${USERNAME} && \
    adduser --disabled-password --uid ${USER_UID} --gid ${USER_GID} --gecos "" ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers
USER $USERNAME
ENV PATH=/opt/chef-workstation/embedded/bin:$PATH
