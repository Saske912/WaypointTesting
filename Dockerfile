FROM debian:buster
WORKDIR /
ARG USER=default
ARG PASS=default
RUN apt-get update && apt-get install -y  \
libpcre3-dev zlib1g-dev git gcc make vim

#upload
RUN git clone https://github.com/vkholodkov/nginx-upload-module.git upload_install

#form_vars
RUN git clone https://github.com/vision5/ngx_devel_kit.git kit_install
RUN git clone https://github.com/calio/form-input-nginx-module.git form_install

#nginx array support
RUN git clone https://github.com/openresty/array-var-nginx-module.git array_install

#opensll
ADD https://www.openssl.org/source/openssl-1.1.1k.tar.gz .
ADD https://nginx.org/download/nginx-1.18.0.tar.gz .
RUN tar zxf nginx-1.18.0.tar.gz && \
    tar xvf openssl-1.1.1k.tar.gz
WORKDIR /nginx-1.18.0
RUN mkdir -p /etc/nginx/sites-available
RUN ./configure \
             --prefix=/etc/nginx \
             --sbin-path=/etc/nginx/nginx \
             --conf-path=/etc/nginx/nginx.conf \
             --pid-path=/etc/nginx/nginx.pid \
             --error-log-path=/home/err.log \
             --http-log-path=/home/acc.log \
             --user=root \
             --with-openssl=../openssl-1.1.1k \
             --with-http_ssl_module \
             --add-module=../upload_install \
             --add-module=../kit_install \
             --add-module=../form_install \
             --add-module=../array_install
RUN make && make install && rm -f /etc/nginx/*.default
WORKDIR /
#configs
RUN mkdir -p /etc/nginx/snippets etc/ssl/certs /etc/ssl/private
ADD src/default /etc/nginx/sites-available
ADD src/nginx.conf /etc/nginx
ADD src/nginx-selfsigned.crt /etc/ssl/certs/nginx-selfsigned.crt
ADD src/nginx-selfsigned.key /etc/ssl/private/nginx-selfsigned.key
ADD src/self-signed.conf /etc/nginx/snippets
ADD src/ssl-params.conf /etc/nginx/snippets
ADD src/dhparam.pem /etc/nginx/dhparam.pem

RUN useradd -m "${USER}" && yes "${PASS}" | passwd "${USER}" && \
echo -n "${USER}:" > /etc/nginx/htpasswd && \
echo "$PASS" | openssl passwd -crypt -stdin >> /etc/nginx/htpasswd && \
chmod 775 etc/nginx/htpasswd
EXPOSE 80 443
CMD bash /etc/nginx/nginx