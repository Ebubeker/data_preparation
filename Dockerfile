FROM goatcommunity/data-preparation-base:0.02

# Install GTFSTIDY 
RUN bash -c "cd /home && wget https://go.dev/dl/go1.19.2.linux-amd64.tar.gz && rm -rf /usr/local/go && tar -C /usr/local -xzf go1.19.2.linux-amd64.tar.gz"
ENV PATH="${PATH}:/usr/local/go/bin" 
ENV GOPATH="/root/go"
ENV PATH="${GOPATH}/bin:${PATH}"
RUN bash -c "go install github.com/patrickbr/gtfstidy@latest"

# Upgrade node to latest version (TODO: remove this when the base image is updated)
RUN apt-get update
RUN echo "y" | apt-get install curl
# nvm env vars
RUN mkdir -p /usr/local/nvm
ENV NVM_DIR /usr/local/nvm
# IMPORTANT: set the exact version
ENV NODE_VERSION v16.17.0
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
RUN /bin/bash -c "source $NVM_DIR/nvm.sh && nvm install $NODE_VERSION && nvm use --delete-prefix $NODE_VERSION"
# add node and npm to the PATH
ENV NODE_PATH $NVM_DIR/versions/node/$NODE_VERSION/bin
ENV PATH $NODE_PATH:$PATH
RUN npm -v
RUN node -v

# Install GTFS-VIA-POSTGRES
RUN bash -c "cd /home && apt-get update && apt install npm -y && git clone https://github.com/majkshkurti/gtfs-via-postgres.git && cd gtfs-via-postgres && npm install --production && npm cache clean --force && ln -s /home/gtfs-via-postgres/cli.js /usr/local/bin/gtfs-via-postgres"

# Install libpostal
WORKDIR /tmp/
RUN apt-get install -y git curl autoconf automake libtool python-dev pkg-config
RUN git clone https://github.com/openvenues/libpostal
WORKDIR /tmp/libpostal/
RUN ./bootstrap.sh
RUN ./configure
RUN make
RUN make install
RUN ldconfig
WORKDIR /tmp/
RUN rm -rf /tmp/libpostal

# Copy poetry.lock* in case it doesn't exist in the repo
COPY ./pyproject.toml ./poetry.lock* /app/
ENV PYTHONPATH "${PYTHONPATH}:."
WORKDIR /app/

# Allow installing dev dependencies to run tests
ARG INSTALL_DEV=false
RUN bash -c "if [ $INSTALL_DEV == 'true' ] ; then poetry install --no-root ; else poetry install --no-root --no-dev ; fi"

# Install aws cli
WORKDIR /tmp/
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

# Install s3fs
RUN apt update
RUN apt install -y s3fs

# Install kart 
RUN apt-get install -y libtinfo5
RUN wget "https://github.com/koordinates/kart/releases/download/v0.11.5/kart_0.11.5-1_amd64.deb"
RUN dpkg -i kart_0.11.5-1_amd64.deb

WORKDIR /app/

ENTRYPOINT ["python /src/db/prepare.py | tail"]
CMD ["-f","/dev/null"]

