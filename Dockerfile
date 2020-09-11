FROM mcr.microsoft.com/powershell:latest

RUN useradd -u 1000 -G users,wheel,root -d /home/user --shell /bin/bash -m user && \
    usermod -p "*" user

COPY bin/ /home/user/bin/

RUN for f in "/home/user" "/etc/passwd" "/etc/group"; do\
        chgrp -R 0 ${f} && \
        chmod -R g+rwX ${f}; \
    done

ENV HOME=/home/user
ENV PATH=${HOME}/bin:${PATH}

USER user

RUN cat /etc/passwd | \
    sed s#user:x.*#user:x:\${USER_ID}:\${GROUP_ID}::\${HOME}:/bin/bash#g \
    > /home/user/passwd.template && \
    # Generate group.template \
    cat /etc/group | \
    sed s#root:x:0:#root:x:0:0,\${USER_ID}:#g \
    > /home/user/group.template

RUN pwsh -command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted;Install-Module VMware.PowerCLI 2>&1 | out-null"

ENTRYPOINT ["/home/user/bin/entrypoint.sh"]
CMD ["cmd"]
