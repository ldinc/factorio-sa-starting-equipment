# Headless Factorio + FactorioTest CLI for running the mod's in-game tests.
# Normally used through docker-compose.yml / run-tests.ps1 in the repo root.
FROM node:22-bookworm-slim

ARG FACTORIO_VERSION=2.1.20
ARG FACTORIO_TEST_CLI_VERSION=3.6.0

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl xz-utils \
 && rm -rf /var/lib/apt/lists/*

# Factorio headless server: free download, no account needed. x86-64 only.
RUN curl -fsSL "https://factorio.com/get-download/${FACTORIO_VERSION}/headless/linux64" -o /tmp/factorio.tar.xz \
 && tar -xJf /tmp/factorio.tar.xz -C /opt \
 && rm /tmp/factorio.tar.xz \
 && ln -s /opt/factorio/bin/x64/factorio /usr/local/bin/factorio \
 && factorio --version

# Installed as a local project in /work, not with -g: the CLI calls `npx fmtk ...` (factoriomod-debug),
# and npx only finds bins of the project in the current directory, never global ones.
WORKDIR /work
RUN npm init -y >/dev/null \
 && npm install --no-audit --no-fund "factorio-test-cli@${FACTORIO_TEST_CLI_VERSION}" \
 && npx --no-install fmtk --help >/dev/null

# The factorio-test mod (>= 3.0.0). Mod portal downloads need a Factorio account, so the zip is
# vendored next to this Dockerfile (run-tests.ps1 downloads it for you on Windows).
COPY factorio-test_*.zip /data/mods/

# /data = CLI data dir (mods, config.ini, mod-list.json). Do not mount a volume over it.
# /mod  = the mod under test, bind-mounted by docker-compose.yml.
ENTRYPOINT ["/work/node_modules/.bin/factorio-test", "run", "-d", "/data", "-p", "/mod"]
# No players exist in headless runs, so skip tests that need one. Replaced by any args you pass.
CMD ["--tag-blacklist", "needs-player"]
