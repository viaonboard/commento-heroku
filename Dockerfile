# backend build (api server)
FROM golang:1.10.2-alpine AS api-build

COPY ./api /go/src/commento-ce/api
WORKDIR /go/src/commento-ce/api

RUN apk update && apk add bash make git

RUN make prod


# frontend build (html, js, css, images)
FROM node:10.3.0-alpine AS frontend-build

COPY ./frontend /commento-ce/frontend/
WORKDIR /commento-ce/frontend/

RUN apk update && apk add bash make
RUN npm install -g html-minifier uglify-js sass

RUN make prod


# templates build
FROM alpine:3.7 AS templates-build

COPY ./templates /commento-ce/templates
WORKDIR /commento-ce/templates

RUN apk update && apk add bash make

RUN make prod


# db build
FROM alpine:3.7 AS db-build

COPY ./db /commento-ce/db
WORKDIR /commento-ce/db

RUN apk update && apk add bash make

RUN make prod


# final image
FROM alpine:3.7

COPY --from=api-build /go/src/commento-ce/api/build/prod/commento-ce /commento-ce/commento-ce
COPY --from=frontend-build /commento-ce/frontend/build/prod/*.html /commento-ce/
COPY --from=frontend-build /commento-ce/frontend/build/prod/css/*.css /commento-ce/css/
COPY --from=frontend-build /commento-ce/frontend/build/prod/js/*.js /commento-ce/js/
COPY --from=frontend-build /commento-ce/frontend/build/prod/images/* /commento-ce/images/
COPY --from=templates-build /commento-ce/templates/build/prod/templates/ /commento-ce/templates/
COPY --from=db-build /commento-ce/db/build/prod/db/ /commento-ce/db/

EXPOSE 8080

WORKDIR /commento-ce/

ENV COMMENTO_BIND_ADDRESS="0.0.0.0"
ENTRYPOINT ["/commento-ce/commento-ce"]
