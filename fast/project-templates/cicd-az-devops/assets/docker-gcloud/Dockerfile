FROM gcr.io/google.com/cloudsdktool/google-cloud-cli:alpine

ARG TERRAFORM_VERSION=1.14.0
ENV TARGETARCH="linux-musl-x64"


# Another option:
# FROM arm64v8/alpine
# ENV TARGETARCH="linux-musl-arm64"

# Alpine packages

RUN apk update && \
  apk upgrade && \
  apk add \
    bash curl gcc git icu-libs jq musl-dev python3-dev libffi-dev \
    openssl-dev cargo make py-pip unzip

# Terraform
RUN curl -LO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    mv terraform /usr/local/bin/ && \
    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Azure CLI

RUN pip install --break-system-packages azure-cli

WORKDIR /azp/

COPY ./start.sh ./
RUN chmod 755 ./start.sh

RUN adduser -D agent
RUN chown agent ./
USER agent

# Another option is to run the agent as root.
# ENV AGENT_ALLOW_RUNASROOT="true"

ENTRYPOINT [ "./start.sh" ]
