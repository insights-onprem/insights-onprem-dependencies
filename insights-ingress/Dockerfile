FROM --platform=linux/amd64 registry.access.redhat.com/ubi9/go-toolset:latest as builder

WORKDIR /go/src/app

# The current ubi9 image does not include Go 1.24, so we specify it.
# Adding "auto" will allow a newer version to be downloaded if specified in go.mod
ARG GOTOOLCHAIN=go1.24.4+auto

COPY cmd cmd

COPY internal internal

COPY go.mod go.mod

COPY go.sum go.sum

COPY licenses licenses

USER 0

RUN go get -d ./... && \
  go build -o insights-ingress-go cmd/insights-ingress/main.go

RUN cp /go/src/app/insights-ingress-go /usr/bin/

FROM --platform=linux/amd64 registry.access.redhat.com/ubi9/ubi-minimal:latest

WORKDIR /

COPY --from=builder /go/src/app/insights-ingress-go ./insights-ingress-go

COPY --from=builder /go/src/app/licenses/LICENSE .

USER 1001

CMD ["/insights-ingress-go"]

# Define labels for the ingress
LABEL url="https://www.redhat.com"
LABEL name="ingress" \
      description="Insights Ingress service for On-Premise platform built from source" \
      summary="Insights Ingress container image built from insights-ingress-go source code"
LABEL com.redhat.component="insights-ingress" \
      io.k8s.display-name="Insights On-Premise Ingress" \
      io.k8s.description="Insights Ingress service for On-Premise platform built from source" \
      io.openshift.tags="insights onprem ingress"
