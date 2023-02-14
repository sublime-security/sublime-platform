# Copyright (c) 2015, Thinkst Applied Research
# All rights reserved.

# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# h/t to the @thinkst team
# source: https://github.com/thinkst/canarytokens-docker/blob/c49e96ff16bbf7c1187d39367b4e8e9fe2fe5315/certbot-nginx/start.sh
echo  "----------------------------------------------------------------"
echo  "Starting nginx and lets encrypt setup using"
_args=""
_server_names=""
if [ "x${MY_DOMAIN_NAME}" != "x" ]; then
    echo  "Domain : $MY_DOMAIN_NAME"
    _args=" -d ${MY_DOMAIN_NAME} -d www.${MY_DOMAIN_NAME}"
    _server_names="${MY_DOMAIN_NAME} www.${MY_DOMAIN_NAME} "
fi
if [ "x${MY_DOMAIN_NAMES}" != "x" ]; then
    echo  "Domains : $MY_DOMAIN_NAMES"
    for domain in $MY_DOMAIN_NAMES; do
        _args="${_args} -d ${domain}"
        _server_names="${_server_names} ${domain}"
    done
fi
echo  "Email  : $EMAIL_ADDRESS"
echo  "----------------------------------------------------------------"
sed -i "s/___server_names___/$_server_names/g" /etc/nginx/nginx.conf
sleep 5
nginx
sleep 5
certbot --nginx ${_args} --text --agree-tos --no-self-upgrade --keep --no-redirect --email $EMAIL_ADDRESS -v -n
nginx -s stop
sleep 3
nginx -g "daemon off;"
