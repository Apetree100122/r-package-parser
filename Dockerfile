FROM dockerhub.datacamp.com:443/r-base-prod:v2.0.1
# r-base-prod already contains python and awscli

# clean up credentials - install libxml2-dev and pandoc
RUN rm -rf /home/repl/.aws \
  && apt-get update && apt-get install -y libxml2-dev libmagick++-dev \
  && wget https://github.com/jgm/pandoc/releases/download/1.19.1/pandoc-1.19.1-1-amd64.deb && dpkg -i pandoc-1.19.1-1-amd64.deb

RUN curl -o /tmp/aws-env-linux-amd64 -L https://github.com/datacamp/aws-env/releases/download/v0.1-session-fix/aws-env-linux-amd64 && \
  chmod +x /tmp/aws-env-linux-amd64 && \
  mv /tmp/aws-env-linux-amd64 /bin/aws-env

# this is required because a dependency of pkgdown was failing if it's not there
RUN apt-get install libharfbuzz-dev libfribidi-dev

RUN R -e 'install.packages("remotes")'
RUN R -e 'remotes::install_github("datacamp/pkgdown", ref = "master")'

COPY . r-package-parser

RUN R CMD build r-package-parser
RUN R CMD INSTALL r-package-parser

CMD ["R", "-e", "RPackageParser::main()"]
