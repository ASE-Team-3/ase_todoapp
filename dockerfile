FROM instrumentisto/flutter

WORKDIR /app

COPY . /app
VOLUME [ "/app" ]

RUN flutter doctor -v