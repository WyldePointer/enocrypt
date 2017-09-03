#!/bin/sh

## enocrypt AES encryption script.
##
## Distributed under BSD 3-clause license.
##
## Author: Sohrab Monfared <sohrab.monfared@gmail.com>
## More: https://github.com/WyldePointer/enocrypt

encryption_cipher="aes-256-cbc"
file_hashing_command="sha256sum"
encrypted_file_extension=".enc"
encrypted_checksums_file_name="checksums.enc"
encrypted_random_key_file_name="random_key.enc"
random_key_number_of_bytes=32
random_dir_name_source="date +%s%N"
random_dir_length=12

## Internal variables. Do not change anything below.
checksums=''
random_dir=''
random_key=''
original_file_hash=''
encrypted_file_hash=''
encrypted_file_path_and_name=''
checksum_store_error=0
os_type=`uname -s`

if [ "$os_type" = "OpenBSD" ]; then
  os_type='bsd'
  file_hashing_command="sha256"
fi

if [ $# -lt 3 ]; then
  echo "Usage: $0 <filename> <destination-dir> <public-key>"
  exit 1
fi

if [ ! -r $1 ]; then
  echo "[ERROR] Can not read $1."
  exit 2
fi

if [ ! -d $2 ]; then
  echo "[ERROR] $2 does not exist or not a directory."
  exit 3
fi

if [ ! -w $2 ]; then
  echo "[ERROR] $2 is not writable."
  exit 4
fi

if [ ! -f $3 ]; then
  echo "[ERROR] $3 is not a file."
  exit 5
fi

if [ ! -r $3 ]; then
  echo "[ERROR] Can not read the public key '$3'."
  exit 6
fi

random_dir=` echo $($random_dir_name_source) | $file_hashing_command |\
 awk '{print $1}' | awk '{print substr($1, 0, len)}' len=$random_dir_length`

mkdir $2/$random_dir

if [ $? != 0 ]; then
  echo "[ERROR] Can not creating the random data directory."
  exit 7
fi

random_key=`openssl rand -hex $random_key_number_of_bytes`

echo "Your file is going to be encrypted. It may take a while.."

if [ "$os_type" != "Linux" ]; then
  checksums=`$file_hashing_command $1`
else
  original_file_hash=`$file_hashing_command $1 | awk '{print $1}'`
  checksums="$original_file_hash `basename $1`"
fi

encrypted_file_path_and_name=$2/$random_dir/`basename $1`\
$encrypted_file_extension

echo $random_key | openssl enc -$encryption_cipher -salt -in $1 -out\
 $encrypted_file_path_and_name -pass stdin

if [ $? != 0 ]; then
  echo "[ERROR] An error occurred during the file encryption."
  exit 8
fi


if [ $os_type != "Linux" ]; then
  encrypted_file_hash=`$file_hashing_command $encrypted_file_path_and_name`
  checksums="$checksums\n$encrypted_file_hash"
else
  encrypted_file_hash=`$file_hashing_command $encrypted_file_path_and_name |\
    awk '{print $1}'`
  checksums="$checksums \n$encrypted_file_hash\
 `basename $1$encrypted_file_extension`"
fi

## TODO: Alternative method. Must be POSIX-friendly and portable.
export __random_key=$random_key

echo $checksums | openssl enc -$encryption_cipher -salt\
 -out $2/$random_dir/$encrypted_checksums_file_name -pass env:__random_key

checksum_store_error=$?

unset __random_key

if [ $checksum_store_error != 0 ]; then
  echo "[ERROR] Could not encrypt the checksums."
  exit 9
fi

echo $random_key | openssl rsautl -encrypt -inkey $3 -pubin\
 -out $2/$random_dir/$encrypted_random_key_file_name

if [ $? != 0 ]; then
  echo "[ERROR] An error occurred while encrypting the random key file."
  exit 10
fi

echo "[DONE] Your file has been successfully encrypted and stored at:"
echo $2/$random_dir/

exit 0

