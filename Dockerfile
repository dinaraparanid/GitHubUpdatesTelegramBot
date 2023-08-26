FROM alpine:3.14
RUN apk update && apk upgrade
RUN apk add --no-cache sqlite-libs

FROM dart:stable as build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
ADD . /app
RUN dart pub get --offline
RUN dart compile exe bin/main.dart -o bin/bot

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/bot /app/bin/

EXPOSE 3000

ENTRYPOINT ["/app/bin/bot"]