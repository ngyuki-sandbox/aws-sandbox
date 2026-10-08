# syntax=docker/dockerfile:1

FROM alpine:3.20 AS builder
RUN mkdir -p /build/ && date +"Build 1st: %Y-%m-%dT%H:%M:%S" >> /build/timestamp.txt

FROM alpine:3.20 AS runner
COPY --from=builder /build/timestamp.txt /app/
RUN sleep 1 && date +"Build 2st: %Y-%m-%dT%H:%M:%S" >> /app/timestamp.txt
CMD ["cat", "/app/timestamp.txt"]
