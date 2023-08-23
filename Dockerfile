FROM ruby:2.7.8-bullseye

################################################################################################
#       Environment
#
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y git-core sudo curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libffi-dev libgdbm-dev libncurses5-dev automake libtool bison libffi-dev gnupg patch gawk g++ gcc make libc6-dev libcurl3-dev autoconf libtool ncurses-dev zlib1g openssl libcurl4-openssl-dev libgmp-dev clamav md5deep nodejs npm default-jre unzip python3 python3-pip jq

RUN echo "%sudo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

#################################################################################################
#       Node Security
#            Early because it needs to run as root.
#            Requires nodejs npm
#
## retirejs locked to most recent pre-2.x.x version (2.x.x breaks the retirejs task)
RUN npm install -g nsp retire@1.6.2 eslint eslint-plugin-scanjs-rules eslint-plugin-no-unsafe-innerhtml

#################################################################################################
#       User
#
RUN useradd -ms /bin/bash --groups sudo glue
USER glue

#################################################################################################
#       Python
#
RUN /bin/bash -l -c "sudo pip install --upgrade pip"
RUN /bin/bash -l -c "sudo pip install bandit"
RUN /bin/bash -l -c "sudo pip install awsscout2"

#################################################################################################
#       Java
#
## JDK needed for Dependency Check Maven plugin
RUN sudo apt-get install -y software-properties-common
RUN sudo apt-get update
RUN sudo apt-get install -y default-jre

RUN /bin/bash -l -c "mkdir -p /home/glue/tools"
WORKDIR /home/glue/tools/

#################################################################################################
#       Truffle Hog
#
# RUN /bin/bash -l -c "sudo pip install truffleHog"
RUN git clone https://github.com/runako/truffleHog.git
WORKDIR /home/glue/tools/truffleHog
RUN git checkout rg-local-scan

WORKDIR /home/glue/tools/

# OWASP DEPENDENCY CHECK (needs unzip and default-jre)
RUN curl -L https://github.com/jeremylong/DependencyCheck/releases/download/v8.4.0/dependency-check-8.4.0-release.zip --output owasp-dep-check.zip
RUN unzip owasp-dep-check.zip

# Maven
RUN sudo apt-get install -y maven

# FINDBUGS (Experimental)
#RUN curl -L http://downloads.sourceforge.net/project/findbugs/findbugs/3.0.1/findbugs-3.0.1.zip --output findbugs.zip
#RUN unzip findbugs.zip
#RUN curl -L http://search.maven.org/remotecontent?filepath=com/h3xstream/findsecbugs/findsecbugs-plugin/1.4.4/findsecbugs-plugin-1.4.4.jar > findbugs-3.0.1/plugin/findsecbugs.jar
#RUN git clone https://github.com/find-sec-bugs/find-sec-bugs.git

# SBT plugin (for Scala)
RUN sudo apt-get update
RUN sudo apt-get install apt-transport-https curl gnupg -yqq
RUN echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | sudo tee /etc/apt/sources.list.d/sbt.list
RUN echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | sudo tee /etc/apt/sources.list.d/sbt_old.list
RUN curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | sudo -H gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/scalasbt-release.gpg --import
RUN sudo chmod 644 /etc/apt/trusted.gpg.d/scalasbt-release.gpg
RUN sudo apt-get update
RUN sudo apt-get install sbt

RUN mkdir -p /home/glue/.sbt/0.13/plugins
RUN echo "addSbtPlugin(\"net.vonbuchholtz\" % \"sbt-dependency-check\" % \"0.1.4\")" >  /home/glue/.sbt/0.13/plugins/build.sbt

#################################################################################################
#       Glue App
#

## Working Dir
RUN /bin/bash -l -c "mkdir -p /home/glue/tmp"
WORKDIR /home/glue/tmp

## Core Pipeline (and ruby tools)
RUN /bin/bash -l -c "git clone https://github.com/OWASP/glue.git"

USER root
RUN /bin/bash -l -c "cp -ra /home/glue/tmp/glue /"
RUN /bin/bash -l -c "chown -R glue:glue /glue"

USER glue

WORKDIR /glue

RUN /bin/bash -l -c "gem install brakeman -v 5.4.1"
RUN /bin/bash -l -c "gem install bundler:1.15.4; bundle install -j20; gem build glue.gemspec; gem install slack-ruby-client; gem install owasp-glue*.gem;"

ENTRYPOINT ["glue"]
CMD ["-h"]

ENV GLUE_FILE=""

COPY --chown=root:1001 . .

COPY zaproxy_mapping.json /glue