FROM fedora

RUN dnf install -y dnf-plugins-core
RUN dnf config-manager --add-repo http://org.osbuild.rpm:8000
COPY testrunner-init.sh .

RUN groupadd weldr
RUN useradd -g weldr _osbuild-composer

ENTRYPOINT ["./testrunner-init.sh"]
