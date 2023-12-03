## Encrypting and Decrypting files
- Files inside ansible/confs are encrypted with ansible-vault. In order to decrypt it, run `ansible-vault decrypt confs/iptables.conf` and enter the vault password (saved on BitWarden)
- Make modifications to the files as needed
- Encrypt them again using `ansible-vault encrypt confs/iptables.conf`
- To change the vault password, simply use a new password when encrypting again and also update the password in Github Actions

## Debugging
- Always use `systemctl start wg-quick@wg0.service` to start the wg0 connection on the servers. This is because the `ansible.builtin.service` module starts the wg-quick@wg0.service. If you run `wg-quick up wg0` on the server, and then run Ansible, it will throw an error saying the wg0 interface already exists. 
