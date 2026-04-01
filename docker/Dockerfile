FROM ruby:3.4-slim-bookworm

ARG REDMICA=master

RUN apt-get update -qq && apt-get install -y --no-install-recommends -qq \
    curl git build-essential \
    imagemagick libmagick++-dev ghostscript \
    gsfonts \
    libpq-dev \
    libyaml-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    curl -fsSL -o /tmp/pandoc.deb https://github.com/jgm/pandoc/releases/download/3.9.0.2/pandoc-3.9.0.2-1-arm64.deb; \
    dpkg -i /tmp/pandoc.deb; \
    rm -f /tmp/pandoc.deb

RUN sed -ri 's/(rights)="none" (pattern="PDF")/\1="read" \2/' /etc/ImageMagick-6/policy.xml

WORKDIR /redmica

RUN git config --global http.sslVerify false && \
    git clone --depth=1 --branch=${REDMICA} https://github.com/redmica/redmica.git .

ENV BINDING=0.0.0.0

EXPOSE 3000

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
