FROM alpine:3.6

RUN adduser -S litecoin

ENV BERKELEYDB_VERSION=db-4.8.30.NC
ENV BERKELEYDB_PREFIX=/opt/${BERKELEYDB_VERSION}

ENV LITECOIN_VERSION=0.14.2-private
ENV LITECOIN_PREFIX=/opt/litecoin-${LITECOIN_VERSION} \
  LITECOIN_DATA=/home/litecoin/.litecoin
ENV PATH=${LITECOIN_PREFIX}/bin:$PATH

COPY . /tmp/build/litecoin-${LITECOIN_VERSION}

RUN apk --no-cache --virtual build-dependendencies add autoconf \
    automake \
    boost-dev \
    build-base \
    chrpath \
    file \
    libevent-dev \
    openssl \
    libtool \
    linux-headers \
    openssl-dev \
    protobuf-dev \
    zeromq-dev \
  && mkdir -p /tmp/build \
  && wget -O /tmp/build/${BERKELEYDB_VERSION}.tar.gz http://download.oracle.com/berkeley-db/${BERKELEYDB_VERSION}.tar.gz \
  && tar -xzf /tmp/build/${BERKELEYDB_VERSION}.tar.gz -C /tmp/build/ \
  && sed s/__atomic_compare_exchange/__atomic_compare_exchange_db/g -i /tmp/build/${BERKELEYDB_VERSION}/dbinc/atomic.h \
  && mkdir -p ${BERKELEYDB_PREFIX} \
  && cd /tmp/build/${BERKELEYDB_VERSION}/build_unix \
  && ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=${BERKELEYDB_PREFIX} \
  && make install \
  && cd /tmp/build/litecoin-${LITECOIN_VERSION} \
  && ./autogen.sh \
  && ./configure LDFLAGS=-L${BERKELEYDB_PREFIX}/lib/ CPPFLAGS=-I${BERKELEYDB_PREFIX}/include/ \
    --prefix=${LITECOIN_PREFIX} \
    --mandir=/usr/share/man \
    --disable-tests \
    --disable-bench \
    --disable-ccache \
    --with-gui=no \
    --with-utils \
    --with-libs \
    --with-daemon \
  && make install \
  && cd / \
  && strip ${LITECOIN_PREFIX}/bin/litecoin-cli ${LITECOIN_PREFIX}/bin/litecoind ${LITECOIN_PREFIX}/bin/litecoin-tx ${LITECOIN_PREFIX}/lib/libbitcoinconsensus.a ${LITECOIN_PREFIX}/lib/libbitcoinconsensus.so.0.0.0 \
  && rm -rf /tmp/build ${BERKELEYDB_PREFIX}/docs \
  && apk --no-cache --purge del build-dependendencies \
  && apk --no-cache add boost \
    boost-program_options \
    libevent \
    libzmq \
    openssl \
    su-exec

VOLUME ["/home/litecoin/.litecoin"]

COPY docker-entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 8332 8333 18332 18333 18444

CMD ["litecoind"]
