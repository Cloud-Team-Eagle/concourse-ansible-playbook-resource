FROM alpine:latest as main

RUN set -eux \
 && apk --update add bash openssh-client ruby git ruby-json python3 py3-pip openssl ca-certificates \
 && apk --update add --virtual \
      build-dependencies \
      build-base \
      python3-dev \
      libffi-dev \
      openssl-dev \
      musl-dev \
      cargo \
 && apk --update add alpine-sdk python3-dev libxml2-dev libxslt-dev \
 && /usr/bin/python3 -m pip install --upgrade pip \
 && pip install wheel \
 && pip install lxml netapp-lib \
 && pip3 install --upgrade pip cffi \
 && pip3 install ansible boto pywinrm PyVmomi jmespath aiohttp \
 && apk del build-dependencies \
 && rm -rf /var/cache/apk/* \
 && rm -rf /root/.cargo /root/.cache \
 && find /usr/lib/ -name '__pycache__' -print0 | xargs -0 -n1 rm -rf \
 && find /usr/lib/ -name '*.pyc' -print0 | xargs -0 -n1 rm -rf \
 && mkdir -p /etc/ansible \
 && echo -e "[local]\nlocalhost ansible_connection=local" > /etc/ansible/hosts

COPY assets/ /opt/resource/

RUN echo "---"                   >> requirements.yml \
 && echo "collections:"          >> requirements.yml \
 && echo "- netapp.ontap"        >> requirements.yml \
 && echo "- community.vmware"    >> requirements.yml \
 && echo "- vmware.vmware_rest"  >> requirements.yml \
 && cat requirements.yml \
 && ansible-galaxy install -r requirements.yml


RUN mkdir -p /users \
 && addgroup ansible \
 && adduser -u 1015 -h /users/ansible -D -G ansible ansible

FROM main as testing

RUN set -eux; \
    gem install rspec; \
    wget -q -O - https://raw.githubusercontent.com/troykinsella/mockleton/master/install.sh | bash; \
    cp /usr/local/bin/mockleton /usr/local/bin/ansible-galaxy; \
    cp /usr/local/bin/mockleton /usr/local/bin/ansible-playbook; \
    cp /usr/local/bin/mockleton /usr/bin/ssh-add;

COPY . /resource/

WORKDIR /resource
RUN rspec

FROM main
