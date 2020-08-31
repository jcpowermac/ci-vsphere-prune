FROM mcr.microsoft.com/powershell:latest

RUN pwsh -command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted;Install-Module VMware.PowerCLI 2>&1 | out-null"

ENTRYPOINT ["/usr/bin/pwsh"]
CMD ["-Help"]
