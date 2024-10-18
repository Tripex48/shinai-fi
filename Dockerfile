FROM ubuntu:focal as builder

RUN export DEBIAN_FRONTEND=noninteractive \
  && apt update \
  && apt-get -y -q install wget build-essential autoconf automake libtool pkg-config libnl-3-dev libnl-genl-3-dev libssl-dev ethtool shtool rfkill zlib1g-dev libpcap-dev libsqlite3-dev libpcre2-dev libhwloc-dev libcmocka-dev hostapd wpasupplicant tcpdump screen iw usbutils expect

RUN mkdir -p /aircrack-ng/git /aircrack-ng/archive /output \
  && wget https://github.com/aircrack-ng/aircrack-ng/archive/refs/tags/1.7.tar.gz -O /tmp/aircrack-ng.tar.gz \
  && tar xzvf /tmp/aircrack-ng.tar.gz -C /aircrack-ng

WORKDIR /aircrack-ng/aircrack-ng-1.7
RUN autoreconf -i \
  && ./configure --with-experimental \
  && make \
  && make install DESTDIR=/output

FROM ubuntu:focal
LABEL maintainer="@singe at SensePost <research@sensepost.com>"

RUN export DEBIAN_FRONTEND=noninteractive \
  && apt update \
  && apt -y -q install git ssl-cert tcpreplay cron supervisor busybox haveged ca-certificates curl iw fish libssl-dev haveged macchanger iptables dnsutils tcpdump wireless-tools isc-dhcp-common nikto build-essential \
  usbutils wget hwloc locales unzip pciutils kmod dhcpcd5 iproute2 procps vim nano tmux hostapd \
  wpasupplicant dnsmasq bash nmap tshark dsniff ethtool w3m lynx rfkill libsqlite3-0 hwloc \
  libnl-3-200 libnl-genl-3-200 usbutils pciutils iproute2 ethtool kmod \
  ieee-data python3 python3-graphviz rfkill

RUN curl -o /usr/local/bin/create_ap https://raw.githubusercontent.com/oblique/create_ap/f906559f44afe6397a1775d0d2bc99d1e622b2fd/create_ap \
  && chmod +x /usr/local/bin/create_ap \
  && curl -o /usr/local/bin/berate_ap curl -o /usr/local/bin/berate_ap https://raw.githubusercontent.com/sensepost/berate_ap/OWE/berate_ap \
  && chmod +x /usr/local/bin/berate_ap \
  && mkdir /root/hostapd-mana \
  && wget -O /root/hostapd-mana/hostapd-mana.zip https://github.com/sensepost/hostapd-mana/releases/download/2.6.5/hostapd-mana-ELF-x86-64.zip \
  && cd /root/hostapd-mana \
  && unzip hostapd-mana.zip \
  && cp /root/hostapd-mana/hostapd /usr/local/bin/hostapd-mana \
  && wget http://launchpadlibrarian.net/523563171/libssl1.0.0_1.0.2n-1ubuntu5.6_amd64.deb \
  && apt-get -y -q install ./libssl1.0.0_1.0.2n-1ubuntu5.6_amd64.deb \
  && rm libssl1.0.0_1.0.2n-1ubuntu5.6_amd64.deb

RUN mkdir /output
COPY --from=builder /output/usr /output

RUN mkdir -p /usr/local/share/man \
  && mv /output/local/share/man/* /usr/local/share/man/ \
  && rmdir /output/local/share/man/ \
  && cp -r /output/* /usr/ \
  && rm -rf /output

RUN mv /usr/local/lib/* /usr/lib

RUN curl -o /usr/local/bin/create_ap https://raw.githubusercontent.com/oblique/create_ap/f906559f44afe6397a1775d0d2bc99d1e622b2fd/create_ap \
  && chmod +x /usr/local/bin/create_ap \
  && curl -o /usr/local/bin/berate_ap https://raw.githubusercontent.com/sensepost/berate_ap/OWE/berate_ap \
  && chmod +x /usr/local/bin/berate_ap \
  && mkdir /tools \
  && wget -O /tools/hostapd-mana.zip https://github.com/sensepost/hostapd-mana/releases/download/2.6.5/hostapd-mana-ELF-x86-64.zip \
  && mkdir /tools/hostapd-mana/ \
  && cd /tools/hostapd-mana/ \
  && unzip /tools/hostapd-mana.zip \
  && rm /tools/hostapd-mana.zip \
  && wget http://launchpadlibrarian.net/523563171/libssl1.0.0_1.0.2n-1ubuntu5.6_amd64.deb \
  && apt-get -y -q install ./libssl1.0.0_1.0.2n-1ubuntu5.6_amd64.deb \
  && rm libssl1.0.0_1.0.2n-1ubuntu5.6_amd64.deb \
  && curl -o /tmp/asleap.deb http://ppa.launchpad.net/cybersec/panto-linux-tools-4.3-2/ubuntu/pool/main/a/asleap/asleap_2.2-1panto0_amd64.deb \
  && dpkg -i /tmp/asleap.deb \
  && rm /tmp/asleap.deb \
  && wget -O /tools/wpa-sycophant.tar.gz https://github.com/sensepost/wpa_sycophant/releases/download/v1.0/wpa_sycophant.tar.gz \
  && cd /tools/ \
  && tar xvf /tools/wpa-sycophant.tar.gz \
  && rm /tools/wpa-sycophant.tar.gz \
  && cd /opt/ \
  && git clone https://github.com/singe/wifi-frequency-hacker \
  && mv /usr/sbin/rfkill /tmp/ \
  && touch /usr/sbin/rfkill \
  && chmod +x /usr/sbin/rfkill

RUN locale-gen en_US.UTF-8 \
  && echo "abc ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Add to bashRC
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/tools"

RUN sed -i "s/^export PS1=\"\$ \"$//" /root/.bashrc \
  && sed -i "s/^#force_color_prompt=yes$/force_color_prompt=yes/" /root/.bashrc 

COPY /attacker/*.sh /opt/sensepost/bin/
COPY /caps/wpa-induction.cap /opt/sensepost/capture/sensepost.cap
COPY /attacker/wpasup.conf /opt/sensepost/etc/wpasup.conf

RUN chmod +x /opt/sensepost/bin/wifi-replay.sh \
  && chmod +x /opt/sensepost/bin/client.sh \
  && echo -n \
  "* * * * * /opt/sensepost/bin/wifi-replay.sh\n \
  * * * * * /opt/sensepost/bin/client.sh\n" > crontab.tmp \
  && crontab -u root crontab.tmp \
  && rm -rf crontab.tmp

CMD /etc/init.d/cron start && /bin/bash
