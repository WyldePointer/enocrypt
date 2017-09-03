#!/bin/sh

## enocrypt RSA key pair generator script.
##
## Distributed under BSD 3-clause license.
##
## Author: Sohrab Monfared <sohrab.monfared@gmail.com>
## More: https://github.com/WyldePointer/enocrypt

rsa_bits=2048
file_hashing_command="sha256sum"
private_key_file_name="private"
private_key_file_extension=".pem"
public_key_file_name="public"
public_key_file_extension=".pem"
random_dir_name_source="date +%s%N"

## Internal variables. Do not change anything below.
keys_dir=''
os_type=`uname -s`

if [ "$os_type" = "OpenBSD" ]; then
  file_hashing_command="sha256"
fi

umask 077

if [ $# -eq 0 ]; then
  echo "Usage: $0 <safe-directory>"
  exit 1
fi

if ! [ -d $1 ]; then
  echo "[ERROR] $1 is not a directory."
  exit 2
fi

if [ ! -w $1 ]; then
  echo "[ERROR] $1 is not writable."
  exit 3
fi

keys_dir=` echo $($random_dir_name_source) |\
 ${file_hashing_command} | cut -f 1 -d\ | awk '{print substr($1, 0, 8)}'`

mkdir $1/$keys_dir

if [ $? != 0 ]; then
  echo "[ERROR] creating the keys directory."
  exit 4
fi

private_key_dir=$1/$keys_dir/private
public_key_dir=$1/$keys_dir/public

mkdir $private_key_dir
mkdir $public_key_dir

umask 377

openssl genrsa -out\
 $private_key_dir/$private_key_file_name$private_key_file_extension $rsa_bits

if [ $? != 0 ]; then
  echo "[ERROR] An error occurred while generating the private key."
  exit 5
fi

umask 333

openssl rsa -in\
 $private_key_dir/$private_key_file_name$private_key_file_extension\
 -outform PEM -pubout -out\
 $public_key_dir/$public_key_file_name$public_key_file_extension

if [ $? != 0 ]; then
  echo "[ERROR] An error occurred while generating the private key."
  exit 6
fi

echo "[DONE] The key pair has been generated successfully and stored in:"
echo $1/$keys_dir/

exit 0

