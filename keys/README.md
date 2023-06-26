# Insecure Keypairs

These keys are the "insecure" public/private keypair we offer to
[base box creators](https://www.vagrantup.com/docs/boxes/base.html) for use in their base boxes so that
vagrant installations can automatically SSH into the boxes.

# Vagrant Keypairs

There are currently two "insecure" public/private keypairs for 
Vagrant. One keypair was generated using the older RSA algorithm
and the other keypair was generated using the more recent ED25519
algorithm. 

The `vagrant.pub` file includes the public key for both keypairs. It 
is important for box creators to include both keypairs as versions of 
Vagrant prior to 2.3.8 will only use the RSA private key.

# Custom Keys

If you're working with a team or company or with a custom box and
you want more secure SSH, you should create your own keypair
and configure the private key in the Vagrantfile with
`config.ssh.private_key_path`
