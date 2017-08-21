#!/bin/sh

## enocrypt decryption script.
##
## Distributed under BSD 3-clause license.
##
## Author: Sohrab Monfared <sohrab.monfared@gmail.com>
## More: https://github.com/WyldePointer/enocrypt

encryption_cipher="aes-256-cbc"
file_hashing_command="sha256sum"
encrypted_checksums_file_name="checksums.enc"
encrypted_random_key_file_name="random_key.enc"

## Internal variables. Do not change anything below.
checksums=''
random_key=''
original_file_hash=''
encrypted_file_hash=''
original_file_name=''
encrypted_file_name=''

if [ $# -lt 3 ]; then
  echo "Usage: $0 <safe-dir> <encrypted-files-dir> <private-key>"
  exit 1
fi

if [ ! -d $1 ]; then
  echo "[ERROR] $1 does not exist or not a directory."
  exit 2
fi

if [ ! -w $1 ]; then
  echo "[ERROR] $1 is not writable."
  exit 3
fi

if [ ! -d $2 ]; then
  echo "[ERROR] $2 does not exist or not a directory."
  exit 4
fi

if [ ! -r $2/$encrypted_checksums_file_name ]; then
  echo "[ERROR] Can not read the checksums file\
 '$2/$encrypted_checksums_file_name'."
  exit 5
fi

if [ ! -r $2/$encrypted_random_key_file_name ]; then
  echo "[ERROR] Can not read the random key file\
 '$2/$encrypted_random_key_file_name'."
  exit 6
fi

if [ ! -f $3 ]; then
  echo "[ERROR] $3 is not a file."
  exit 7
fi

if [ ! -r $3 ]; then
  echo "[ERROR] Can not read the private key '$3'."
  exit 8
fi

random_key=`openssl rsautl -decrypt -inkey $3\
 -in $2/$encrypted_random_key_file_name`

if [ $? != 0 ]; then
  echo "[ERROR] An error occurred during random key file decryption ."
  exit 9
fi

checksums=` echo $random_key | openssl enc -d -$encryption_cipher\
 -in $2/$encrypted_checksums_file_name -pass stdin`

if [ $? != 0 ]; then
  echo "[ERROR] An error occurred during checksums file decryption ."
  exit 10
fi

original_file_name=`echo "$checksums" | head -n 1 | awk '{print $2}'`
original_file_hash=`echo "$checksums" | head -n 1 | awk '{print $1}'`

encrypted_file_name=`echo "$checksums" | tail -n 1 | awk '{print $2}'`
encrypted_file_hash=`echo "$checksums" | tail -n 1 | awk '{print $1}'`

echo "$encrypted_file_hash $2/$encrypted_file_name" | sha256sum -c

if [ $? != 0 ]; then
  echo "[ERROR] Checksum of the encrypted file seems to be incorrect."
  exit 11
fi

echo $random_key | openssl enc -d -$encryption_cipher\
 -in $2/$encrypted_file_name -out $1/$original_file_name -pass stdin

if [ $? != 0 ]; then
  echo "[ERROR] An error occurred during decryption of the file."
  exit 12
fi

echo "$original_file_hash $1/$original_file_name" | sha256sum -c

if [ $? != 0 ]; then
  echo "[ERROR] Checksum of decrypted file does not match the original value."
  exit 13
fi

echo "[DONE] Your file has been successfully decrypted and stored at:"
echo $1/$original_file_name

exit 0

