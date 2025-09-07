FROM rocker/tidyverse:4.5.0

COPY apt-packages.txt /opt/apt-packages.txt

RUN apt-get update -qq \
  && apt-get install -y --no-install-recommends \
  && xargs -a /opt/apt-packages.txt apt-get install -y --no-install-recommends \
  && apt-get clean \
  && rm -rf /Var/lib/apt/lists/*

COPY renv.lock renv.lock

RUN echo 'options(repos = c(CRAN = "https://cloud.r-project.org"))' >>"${R_HOME}/etc/Rprofile.site"

RUN R -e "install.packages(c('remotes', 'renv'))"

RUN R -e "options(renv.config.cache.enabled=FALSE);renv::restore(clean = FALSE, prompt = FALSE)"
