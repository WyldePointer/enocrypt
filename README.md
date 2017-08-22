# enocrypt

A set of utilities for encrypting/decrypting your files.

## Features

 - `RSA` + `AES` encryption.
 - Not storing or transferring the encryption key in unencrypted form.
 - Integrated hashing and checksum mechanism.
 - Cross-platform
 - 100% plain-text, blob / binary-free and human-readable.
 - No overhead whatsoever.

## Requirements

All you need is a *NIX environment and the entire cryptography functions are
handled by the OpenSSL's command-line utilities. (Which is installed by default
 on most modern systems. You can check it by running `$ openssl version`.)

However, before going any further, you should know that it's strongly advised
 to *NOT* store your private key(s) on any type of unencrypted storage.
 (You can use `GELI` / `GEOM` on `FreeBSD` or `LUKS` on `GNU/Linux` or the
 `OpenBSD`'s built-in disk encryption.)

During this guide, we refer to this type of
 secure directory(encrypted at block level) as the **safe-dir**. If you don't
 have it or can't use it for whatever reason, a normal directory on your
 file-system would do the job and all of the provided scripts should work
 regardless of your underlying disk encryption layout.

## If you're a recipient

As a recipient(who is going to RECEIVE the encrypted file) you need to setup
 your key pair first. This pair can be generated using `eno_generate_keys.sh`
 which takes the **safe-dir** as its first argument.

```sh
$ ./eno_generate_keys.sh /safe/dir/
```

This script will generate an output similar to:
```sh
Generating RSA private key, 2048 bit long modulus
............................+++
..................+++
e is 65537 (0x10001)
writing RSA key
```

And if everything going on as expected, you must see a message similar to:

```sh
[DONE] The key pair has been generated successfully and stored in:
/safe/dir/8f4c5457/
```

After running this script, you'll have a directory with a structure similar to:

```sh
/safe/dir
    └── 8f4c5457
        ├── private
        │   └── private.pem
        └── public
            └── public.pem
```

(`8f4c5457` is a randomly-generated name. Will vary in your case.)

All files and directories except the `public.pem` are only readable for you
 (the user who runs the script) and you must always keep in mind that your
 private key(`private.pem`) **SHOULD NEVER**, I repeat, **NEVER EVER**:

 - Having a permission other than `400`. (or `-r--------` if you prefer)

 - Being owned by another user. (UNIX system users)

 - Belong to a group which has any other members in it.

 - Be accessible for another person / user, either remote or locally.

 - Being transferred over an insecure(unencrypted / plain-text) channel.

 - Being stored on a storage which is not encrypted at the block level.

For having your files encrypted, you handover[1] your **PUBLIC KEY** to the
 person who wants to encrypt a file for you.

Whenever s/he is done encrypting the file, you must have received 3 different
 files from her/him:

 - `checksums.enc`: This **encrypted** file contains the checksum of both your
 plain(original) and the encrypted file.

 - `my_secret_file.enc`: The **encrypted** version of the original file. [2]

 - `random_key.enc`: This **encrypted** file is the actual key which is used for
 encrypting all 3 files. If you lose it or if it's damaged, you can **NOT**
 access your file even if you have the right(matching) private key.

[1] Read more about it in **What it's not** section.

[2] The `my_secret_file` is a dummy / example name. It would be original
 filename with an additional `.enc` extension at the end of it.

## If you're a sender

Assuming that you've received the public key of the recipient, all you need to
 do it running the `eno_encrypt.sh`:

```sh
./eno_encrypt.sh file_to_encrypt destination_directory public_key
```

 - `file_to_encrypt` is the original(unencrypted) file that you're going to
 encrypt for the recipient.

 - `destination_directory` is where the script will store the **encrypted**
 data files, including the `checksum` and the `random key`.
  (1 directory and 3 files in total)

 - `public_key` is the recipient's public key file.

If you supply this 3 arguments properly, you should see a result similar to:

```sh
[DONE] Your file has been sucessfully encrypted and stored at:
/destination/47efdb869ba5/
```

If so, your files must be successfully encrypted and ready to be sent for the
 recipient. You can also run the following command to make sure that
 they're not in their original(unencrypted) form:

```sh
$ file /destination/52535aa3a9e6/*
/destination/52535aa3a9e6/checksums.enc:          data
/destination/52535aa3a9e6/my_secret_file.enc:     data
/destination/52535aa3a9e6/random_key.enc:         data
```

**NOTE**: You must send all 3 encrypted files to the recipient, otherwise s/he
 won't be able to decrypt anything at all. (They're all linked together)

Without the `checksums`, the integrity can not be verified but the main file can
 still be decrypted by the right(matching) private key.

If you lose the `random key`, everything is gone. Period.

## Decrypting

Decryption of the files are done using the **PRIVATE KEY** and should be only
 done by the recipient and in a safe environment. The `eno_decrypt.sh` script
 is responsible for this task and it takes 3 arguments:

```sh
$ eno_decrypt.sh safe_dir encrypted_files_dir private_key
```

 - `safe_dir` is where you're going to store the decrypted file.

 - `encrypted_files_dir` is where the 3 files from the sender are stored.

 - `private_key` is your private key file.

If you supply the correct arguments / files, you must see a result similar to:

```sh
$ ./eno_decrypt.sh /safe/dir/ encrypted/ /somewhere/safe/private.pem 
encrypted/asiabsdcon08-network.pdf.enc: OK
/safe/dir/asiabsdcon08-network.pdf: OK
[DONE] Your file has been successfully decrypted and stored at:
/safe/dir/asiabsdcon08-network.pdf
```

### TODO
 - Pseudo-code explanation for each step of every script file. (Documenting)
 - Randomizing the encrypted file name. (Optional)
 - Find a workaround for the `env` need of the `openssl enc`.
 - Testing the script in different environments. (`OS X`, `Solaris`, etc.)
 - Check to see if it's `chroot(8)` friendly.
 - Password protected private keys.
 - Encrypting of multiple files. (Separated project perhaps)
 - Command-line option for randomizing the filename.
 - Command-line option for choosing the RSA bits in key generator script.
 - Command-line option for changing the checksum hashing command. (Default is
 `sha256sum(1)`

## What it's not
 - A trust system of any sort. This utility assumes that you totally trust
 the provided public key and it's *ONLY* responsible for encrypting your file(s)
 in a user-friendly and secure manner. If that's not what you're looking for,
 perhaps you should have a look at `PKI` and `PGP` and / or similar
 technologies.

# CAUTION
If you lose your private key(s), your encrypted files are gone forever. Period.

If you've received the recipient's public key over an insecure channel and
 / or the public key is forged by an attacker, the entire encryption has been
 compromised and you may actually ending up encrypting your files for the
 attacker! (Read more on `PKI` and **chain of trust** / **web of trust**.)

### RSA operation error
```
RSA operation error
3073574588:error:0406D06E:rsa routines:RSA_padding_add_PKCS1_type_2:
data too large for key size:rsa_pk1.c:151:
```

It's a RSA limitation and you've probably set a very high value for
 `random_key_number_of_bytes`. Don't do it, it just won't make it übersecure.

### Contribution

Please submit a bug report about any issues that you're facing.

I also accept patches/fixes via email so GitHub Issues / Pull Requests are not
 the only way to contribute.

You can contact me if you need more information or some help with this tool.


