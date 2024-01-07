#/bin/bash

select_year_day() {
    local val=$1
    echo $(( ($(date -d `date -d "+$val year" +%F` +%s) - $(date -d `date +%F` +%s)) / 86400 ))
}

cat << 'EOF' > openssl.cnf
CERT_DIR   = .
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = ${ENV::CERT_DIR}
certs             = $dir
crl_dir           = $dir/crl
new_certs_dir     = $dir
database          = $dir/index.txt
certificate       = $dir/ca.crt
serial            = $dir/serial
crlnumber         = $dir/crlnumber
crl               = $dir/crl/root.crl
private_key       = $dir/ca.key
default_crl_days  = 30
crl_extensions    = crl_ext
default_md        = sha256
name_opt          = ca_default
cert_opt          = ca_default
default_days      = 365
preserve          = no
policy            = policy_match

[ policy_match ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
default_bits        = 2048
distinguished_name  = req_distinguished_name
string_mask         = utf8only
default_md          = sha256
x509_extensions     = v3_ca

[ req_distinguished_name ]
countryName             = Country Name (2 letter code)
stateOrProvinceName     = State or Province Name
localityName            = Locality Name
0.organizationName      = Organization Name
organizationalUnitName  = Organizational Unit Name
commonName              = Common Name

[ v3_ca ]
keyUsage                = critical, cRLSign, keyCertSign
basicConstraints        = critical, CA:true
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always,issuer

[ crl_ext ]
authorityKeyIdentifier=keyid:always
EOF

# 签发CA
export OPENSSL_CONF=`pwd`/openssl.cnf

if [ ! -f ca.key ];then
    (umask 077; openssl genrsa -out ca.key 2048)
fi

if [ ! -f ca.crt ];then
    openssl req -new -x509 \
        -days `select_year_day 30` \
        -sha256 -key ca.key \
        -out ca.crt \
        -subj "/O=PrivateSign/OU=PrivateSign/CN=PrivateSign Root CA"
fi


# 签发中间证书
cat << 'EOF' > intermediate_ca_v3.ext
keyUsage                = critical, digitalSignature, cRLSign, keyCertSign
basicConstraints        = critical, CA:true, pathlen:0
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always,issuer
authorityInfoAccess     = @Info_access
crlDistributionPoints   = @crl_section
certificatePolicies     = @polsect

[ Info_access ]
OCSP;URI.0       = http://ocsp.privatesign.local.com
caIssuers;URI.0  = http://secure.privatesign.local.com/cacert/PrivateSignRootCA.crt

[ crl_section ]
URI.0  = http://crl.privatesign.local.com/crl/root.crl

[ polsect ]
policyIdentifier = X509v3 Any Policy
CPS.1            = http://www.privatesign.local.com
EOF


if [ ! -f intermediate_ca.key ];then
    (umask 077; openssl genrsa -out intermediate_ca.key 2048)
fi

if [ ! -f intermediate_ca.crt ];then
    openssl req -new \
        -key intermediate_ca.key \
        -out intermediate_ca.csr \
        -subj "/C=CN/O=SRE/CN=PrivateSign RSA SSL CA 2019"

    openssl rand -hex 14 > serial.srl
    openssl x509 -req -sha512 -days `select_year_day 10` \
        -CAserial serial.srl -CAcreateserial -CA ca.crt -CAkey ca.key \
        -in intermediate_ca.csr -out intermediate_ca.crt -extfile intermediate_ca_v3.ext
fi


# 签发服务端证书
export ROOT_CA_CRT=ca.crt
export ROOT_CA_KEY=ca.key
export SERVER_OPENSSL_CONF=server.conf
export SERVER_CRT=server.crt
export SERVER_KEY=server.key
export SERVER_CSR=server.csr

cat << 'EOF' > server.conf
[ req ]
req_extensions = v3_req
distinguished_name = dn

[ dn ]

[ v3_req ]
subjectAltName = @alt_names

[ v3_ext ]
keyUsage                = critical,digitalSignature,keyEncipherment
extendedKeyUsage        = serverAuth,clientAuth
basicConstraints        = critical,CA:FALSE
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid,issuer
crlDistributionPoints   = @crl_section
subjectAltName          = @alt_names

[ crl_section ]
URI.0  = http://crl.privatesign.local.com/crl/psrsasslca2019.crl

[ alt_names ]
# 按格式填写DNS或者IP
DNS.1  = localhost
DNS.2  = example.com
DNS.3  = *.example.com
IP.1   = 127.0.0.1
IP.2   = 10.10.10.10
EOF

if [ ! -f $SERVER_KEY ];then
    (umask 077; openssl genrsa -out $SERVER_KEY 2048)
fi

openssl req -new \
    -config $SERVER_OPENSSL_CONF \
    -key $SERVER_KEY \
    -out $SERVER_CSR \
    -subj "/C=CN/ST=ZheJiang/L=HangZhou/O=SRE/CN=example.com"

openssl rand -hex 18 > serial.srl
openssl x509 -req -sha512 -days `select_year_day 1` \
    -CAserial serial.srl -CAcreateserial -CA intermediate_ca.crt -CAkey intermediate_ca.key \
    -in $SERVER_CSR -out $SERVER_CRT -extensions v3_ext -extfile server.conf

# 创建服务器(Nginx)证书证书链
cat <<EOF > server_chain.crt
`openssl x509 -in server.crt`
`openssl x509 -in intermediate_ca.crt`
`openssl x509 -in ca.crt`
EOF


rm -rf intermediate_ca.csr
rm -rf intermediate_ca_v3.ext
rm -rf openssl.cnf
rm -rf serial.srl
rm -rf server.conf
rm -rf server.csr

cat <<EOF
-----------------------------------------
`pwd`
├── ca.crt                 ---Root CA
├── ca.key
├── intermediate_ca.crt
├── intermediate_ca.key
├── server_chain.crt       ---nginx crt
├── server.crt
└── server.key             ---nginx key
EOF
