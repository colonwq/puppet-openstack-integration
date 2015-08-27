#!/bin/bash

set -ex

if [ ! -z ${GEM_HOME} ]; then
    GEM_BIN_DIR=${GEM_HOME}/bin/
fi

export SCRIPT_DIR=$(readlink -f "$(dirname $0)")
export PUPPETFILE_DIR=/etc/puppet/modules

install_external() {
  PUPPETFILE=${SCRIPT_DIR}/Puppetfile1 ${GEM_BIN_DIR}r10k puppetfile install -v
}

install_openstack() {
  cat > clonemap.yaml <<EOF
clonemap:
  - name: '(.*?)/puppet-(.*)'
    dest: '/etc/puppet/modules/\2'
EOF

  local project_names=$(awk '{ if ($1 == ":git") print $3 }' \
    ${SCRIPT_DIR}/Puppetfile0 | tr -d "'," | cut -d '/' -f 4- | xargs
  )
  /usr/zuul-env/bin/zuul-cloner -m clonemap.yaml \
    --cache-dir /opt/git \
    --zuul-ref $ZUUL_REF \
    --zuul-branch $ZUUL_BRANCH \
    --zuul-url $ZUUL_URL \
    git://git.openstack.org $project_names
}

install_all() {
  PUPPETFILE=${SCRIPT_DIR}/Puppetfile ${GEM_BIN_DIR}r10k puppetfile install -v
}

gem install r10k --no-ri --no-rdoc

# make sure there is no puppet module pre-installed
rm -rf "${PUPPETFILE_DIR:?}/"*

# If zuul-cloner is there, have it install modules using zuul refs
if [ -e /usr/zuul-env/bin/zuul-cloner ] ; then
  csplit ${SCRIPT_DIR}/Puppetfile /'External modules'/ \
    --prefix ${SCRIPT_DIR}/Puppetfile \
    --suffix '%d'
  install_external
  install_openstack
else
  install_all
fi

puppet module list

# TODO(emilien) drop that code once Ubuntu Liberty packaging is fixed
if type "apt-get" 2>/dev/null; then
  sudo add-apt-repository -y ppa:ubuntu-cloud-archive/liberty-staging
  sudo apt-get update
  sudo apt-get install -y python-pymysql
fi
