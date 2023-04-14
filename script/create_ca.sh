#!/bin/bash
cat << EOF > openssl.conf
CERT_DIR   = .
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = ${ENV::CERT_DIR}
certs             = $dir
crl_dir           = $dir/crl
new_certs_dir     = $dir
database          = $dir/index.txt
serial            = $dir/serial
crlnumber         = $dir/crlnumber
crl               = $dir/crl/intermediate-ca.crl
crl_extensions    = crl_ext
default_crl_days  = 30
default_md        = sha256
name_opt          = ca_default
cert_opt          = ca_default
default_days      = 375
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
default_bits        = 4096
distinguished_name  = req_distinguished_name
string_mask         = utf8only
default_md          = sha256
x509_extensions     = v3_ca

[ req_distinguished_name ]
countryName                    = Country Name (2 letter code)
stateOrProvinceName            = State or Province Name
localityName                   = Locality Name
0.organizationName             = Organization Name
organizationalUnitName         = Organizational Unit Name
commonName                     = Common Name

[ v3_ca ]
basicConstraints       = critical, CA:true, pathlen:2
keyUsage               = critical, digitalSignature, cRLSign, keyCertSign
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer
EOF


openssl genrsa -out ca.key
openssl req -config openssl.conf -new -x509 -days 3650 -sha256 -key ca.key -out ca.crt -subj "/CN=ROOT CA"

openssl x509 -in ca.crt -noout -text
