FROM gitpod/workspace-full AS installer-env
USER gitpod
ARG PS_VERSION=6.1.0
ARG PS_PACKAGE=powershell-${PS_VERSION}-linux-x64.tar.gz
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_VERSION}/${PS_PACKAGE}
ARG PS_INSTALL_VERSION=7-preview
ADD ${PS_PACKAGE_URL} /tmp/linux.tar.gz
ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION
RUN mkdir -p ${PS_INSTALL_FOLDER}
RUN tar zxf /tmp/linux.tar.gz -C ${PS_INSTALL_FOLDER}
FROM ${imageRepo}:${fromTag}
ARG PS_VERSION=6.2.0-preview.3
ARG PS_INSTALL_VERSION=7-preview
COPY --from=installer-env ["/opt/microsoft/powershell", "/opt/microsoft/powershell"]
ARG PS_INSTALL_VERSION=7-preview
ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION \
    \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    PSModuleAnalysisCachePath=/var/cache/microsoft/powershell/PSModuleAnalysisCache/ModuleAnalysisCache \
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-Debian-10
RUN apt-get update \
    && apt-get install -y \
    less \
    locales \
    ca-certificates \
    gss-ntlmssp \
    libicu63 \
    libssl1.1 \
    libc6 \
    libgcc1 \
    libgssapi-krb5-2 \
    liblttng-ust0 \
    libstdc++6 \
    zlib1g \
    && apt-get dist-upgrade -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen && update-locale
RUN chmod a+x,o-w ${PS_INSTALL_FOLDER}/pwsh \
    && ln -s ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh \
    && pwsh \
    -NoLogo \
    -NoProfile \
    -Command " \
    \$ErrorActionPreference = 'Stop' ; \
    \$ProgressPreference = 'SilentlyContinue' ; \
    while(!(Test-Path -Path \$env:PSModuleAnalysisCachePath)) {  \
    Write-Host "'Waiting for $env:PSModuleAnalysisCachePath'" ; \
    Start-Sleep -Seconds 6 ; \
    }"
ARG VCS_REF="none"
ARG IMAGE_NAME=mcr.microsoft.com/powershell:debian-10
LABEL maintainer="PowerShell Team <powershellteam@hotmail.com>" \
    readme.md="https://github.com/PowerShell/PowerShell/blob/master/docker/README.md" \
    description="This Dockerfile will install the latest release of PowerShell." \
    org.label-schema.usage="https://github.com/PowerShell/PowerShell/tree/master/docker#run-the-docker-image-you-built" \
    org.label-schema.url="https://github.com/PowerShell/PowerShell/blob/master/docker/README.md" \
    org.label-schema.vcs-url="https://github.com/PowerShell/PowerShell-Docker" \
    org.label-schema.name="powershell" \
    org.label-schema.vendor="PowerShell" \
    org.label-schema.version=${PS_VERSION} \
    org.label-schema.schema-version="1.0" \
    org.label-schema.vcs-ref=${VCS_REF} \
    org.label-schema.docker.cmd="docker run ${IMAGE_NAME} pwsh -c '$psversiontable'" \
    org.label-schema.docker.cmd.devel="docker run ${IMAGE_NAME}" \
    org.label-schema.docker.cmd.test="docker run ${IMAGE_NAME} pwsh -c Invoke-Pester" \
    org.label-schema.docker.cmd.help="docker run ${IMAGE_NAME} pwsh -c Get-Help"
CMD [ "pwsh" ]