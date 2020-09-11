FROM mcr.microsoft.com/powershell:latest

ENV APP_ROOT=/opt/app-root
ENV PATH=${APP_ROOT}/bin:${PATH} HOME=${APP_ROOT}
COPY bin/ ${APP_ROOT}/bin/
RUN chmod -R u+x ${APP_ROOT}/bin && \
    chgrp -R 0 ${APP_ROOT} && \
    chmod -R g=u ${APP_ROOT} /etc/passwd


USER 10001
WORKDIR ${APP_ROOT}

RUN pwsh -command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted;Install-Module VMware.PowerCLI 2>&1 | out-null"

ENTRYPOINT ["uid_entrypoint"]
CMD ["cmd"]
