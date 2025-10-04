## Encrypting and Decrypting files
- Files inside ansible/confs are encrypted with ansible-vault. In order to decrypt it, run `ansible-vault decrypt confs/iptables.conf` and enter the vault password (saved on BitWarden)
- Make modifications to the files as needed
- Encrypt them again using `ansible-vault encrypt confs/iptables.conf`
- To change the vault password, simply use a new password when encrypting again and also update the password in Github Actions
