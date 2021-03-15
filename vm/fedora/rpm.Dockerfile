FROM fedora AS RPMBUILDER

# Install rpmbuild
RUN dnf group install -y 'RPM Development Tools'

# Copy spec and install dependencies before pulling in sources
# Avoids needing to redownload build deps when sources change
COPY osbuild-composer.spec .
RUN dnf builddep -y osbuild-composer.spec

COPY . /osbuild-composer/.
ENV GOFLAGS=-mod=vendor
WORKDIR /osbuild-composer
RUN rm -rf rpmbuild && make rpm
RUN createrepo_c rpmbuild/RPMS/x86_64

FROM fedora
RUN dnf install -y python3
COPY --from=RPMBUILDER /osbuild-composer/rpmbuild/RPMS/x86_64 /rpms

ENTRYPOINT python3 -m http.server --directory /rpms 8000
