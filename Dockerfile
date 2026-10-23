FROM node:22-bookworm

ARG CLAUDE_CODE_VERSION=latest
ARG CODEX_VERSION=latest

RUN apt-get update && apt-get install -y --no-install-recommends \
    zsh \
    bash \
    curl \
    git \
    jq \
    ripgrep \
    fd-find \
    iptables \
    ipset \
    iproute2 \
    dnsutils \
    unzip \
    zip \
    tree \
    nano \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN git config --system --add safe.directory '*'

RUN mkdir -p \
    /workspace \
    /home/node/.claude \
    /home/node/.codex \
    /home/node/.npm-global \
    /opt/ai-defaults \
    /opt/ai-guards/bin \
    /usr/local/bin \
    && chown -R node:node /workspace /home/node

COPY container-files/ai-entrypoint /usr/local/bin/ai-entrypoint
COPY container-files/workspace-watchdog /opt/ai-guards/bin/workspace-watchdog
COPY container-files/git-guard /opt/ai-guards/bin/git
COPY container-files/package-manager-guard /opt/ai-guards/bin/pnpm
COPY container-files/package-manager-guard /opt/ai-guards/bin/npm
COPY container-files/package-manager-guard /opt/ai-guards/bin/npx
COPY container-files/package-manager-guard /opt/ai-guards/bin/yarn
COPY container-files/package-manager-guard /opt/ai-guards/bin/corepack

RUN sed -i 's/\r$//' \
    /usr/local/bin/ai-entrypoint \
    /opt/ai-guards/bin/workspace-watchdog \
    /opt/ai-guards/bin/git \
    /opt/ai-guards/bin/pnpm \
    /opt/ai-guards/bin/npm \
    /opt/ai-guards/bin/npx \
    /opt/ai-guards/bin/yarn \
    /opt/ai-guards/bin/corepack \
    && chmod 755 \
    /usr/local/bin/ai-entrypoint \
    /opt/ai-guards/bin/workspace-watchdog \
    /opt/ai-guards/bin/git \
    /opt/ai-guards/bin/pnpm \
    /opt/ai-guards/bin/npm \
    /opt/ai-guards/bin/npx \
    /opt/ai-guards/bin/yarn \
    /opt/ai-guards/bin/corepack \
    && chown -R root:root /opt/ai-guards /usr/local/bin/ai-entrypoint \
    && chown -R node:node /opt/ai-defaults

USER node

ENV HOME=/home/node
ENV NPM_CONFIG_PREFIX=/home/node/.npm-global
ENV SHELL=/bin/zsh
ENV CLAUDE_CONFIG_DIR=/home/node/.claude
ENV NODE_OPTIONS=--max-old-space-size=4096
ENV GIT_OPTIONAL_LOCKS=0

# Build/install phase path: no guards yet, so image setup can install tools.
ENV PATH=/home/node/.npm-global/bin:/home/node/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR /workspace

RUN npm install -g pnpm
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}
RUN npm install -g @openai/codex@${CODEX_VERSION}

# Runtime path: guards first, so agents cannot install packages or mutate Git through normal git/npm/pnpm/yarn/corepack commands.
ENV PATH=/opt/ai-guards/bin:/home/node/.npm-global/bin:/home/node/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ENTRYPOINT ["/usr/local/bin/ai-entrypoint"]
CMD ["zsh"]