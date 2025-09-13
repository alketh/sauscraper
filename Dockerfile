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

COPY utils.R .
COPY scrape-basic.R .

# Add Docker's official GPG key:
RUN install -m 0755 -d /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
RUN chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
RUN echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update

RUN apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
