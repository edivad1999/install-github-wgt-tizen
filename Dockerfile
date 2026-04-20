FROM --platform=linux/amd64 ubuntu:22.04

RUN apt-get update && apt-get install -y \
  ca-certificates \
  wget \
  curl \
  jq \
  zip \
  unzip \
  locales \
  libssl-dev \
  && rm -rf /var/lib/apt/lists/*

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ARG USER=developer
RUN useradd --create-home ${USER}
ENV HOME /home/${USER}

USER ${USER}
WORKDIR ${HOME}

# Tizen Studio CLI must be installed as non-root in user home dir
ARG TIZEN_STUDIO_VERSION=6.1
ARG TIZEN_STUDIO_FILE=web-cli_Tizen_Studio_${TIZEN_STUDIO_VERSION}_ubuntu-64.bin
ARG TIZEN_STUDIO_URL=http://download.tizen.org/sdk/Installer/tizen-studio_${TIZEN_STUDIO_VERSION}/${TIZEN_STUDIO_FILE}
RUN wget ${TIZEN_STUDIO_URL} \
  && chmod +x ${TIZEN_STUDIO_FILE} \
  && echo y | ./${TIZEN_STUDIO_FILE} --accept-license \
  && rm ${TIZEN_STUDIO_FILE}

RUN mkdir -p ${HOME}/tizen-studio-data/profile \
  && printf '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n<profiles version="3.1"/>\n' \
     > ${HOME}/tizen-studio-data/profile/profiles.xml

COPY --chown=${USER} entrypoint.sh profile.xml ${HOME}/
RUN chmod +x ${HOME}/entrypoint.sh

USER root

ENV PATH $PATH:/home/developer/tizen-studio/tools/:/home/developer/tizen-studio/tools/ide/bin/:/home/developer/tizen-studio/package-manager/

ENTRYPOINT ["/home/developer/entrypoint.sh"]
