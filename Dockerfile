FROM opensuse/amd64:42.3
MAINTAINER SUSE Containers Team <containers@suse.com>

COPY rpm-import-repo-key /

RUN chmod +x /rpm-import-repo-key && \
    sync && /rpm-import-repo-key A9EA39C49B6B9E93B6863F849AF0C9A20E9AF123 && \
    zypper ar -f obs://devel:languages:ruby/openSUSE_Leap_42.3 ruby && \
    zypper -n in --no-recommends ruby2.6 ruby2.6-rubygem-gem2rpm && \
    zypper clean -a && \
    rm /rpm-import-repo-key && \
    update-alternatives --install /usr/bin/ruby ruby /usr/bin/ruby.ruby2.6 1 && \
    update-alternatives --install /usr/bin/gem gem /usr/bin/gem.ruby2.6 1

ENV COMPOSE=1
EXPOSE 3000

WORKDIR /srv/Portus
COPY Gemfile* ./

# Let's explain this RUN command:
#   1. First of all we add d:l:go repo to get the latest go version.
#   2. Then refresh, since opensuse/ruby does zypper clean -a in the end.
#   3. Then we install dev. dependencies and the devel_basis pattern (used for
#      building stuff like nokogiri). With that we can run bundle install.
#   4. We then proceed to remove unneeded clutter: first we remove some packages
#      installed with the devel_basis pattern, and finally we zypper clean -a.
RUN zypper addrepo https://download.opensuse.org/repositories/devel:languages:go/openSUSE_Leap_15.0/devel:languages:go.repo && \
    zypper --gpg-auto-import-keys ref && \
    zypper -n in --no-recommends ruby2.6-devel \
           libmysqlclient-devel postgresql-devel \
           nodejs libxml2-devel libxslt1 git-core \
           go1.10 phantomjs gcc-c++ && \
    zypper -n in --no-recommends -t pattern devel_basis && \
    gem install bundler -v 1.17.3 && \
    update-alternatives --install /usr/bin/bundle bundle /usr/bin/bundle.ruby2.6 1 && \
    update-alternatives --install /usr/bin/bundler bundler /usr/bin/bundler.ruby2.6 1 && \
    bundle install --retry=3 && \
    go get -u github.com/vbatts/git-validation && \
    go get -u github.com/openSUSE/portusctl && \
    mv /root/go/bin/git-validation /usr/local/bin/ && \
    mv /root/go/bin/portusctl /usr/local/bin/ && \
    zypper -n rm wicked wicked-service autoconf automake \
           binutils bison cpp cvs flex gdbm-devel gettext-tools \
           libtool m4 make makeinfo && \
    zypper clean -a

ADD . .
