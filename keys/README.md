# Insecure Keypair

These keys are the "insecure" public/private keypair we offer to
[base box creators](http://docs.vagrantup.com/v1/docs/base_boxes.html) for use in their base boxes so that
vagrant installations can automatically SSH into the boxes.

If you're working with a team or company or with a custom box and
you want more secure SSH, you should create your own keypair
and configure the private key in the Vagrantfile with
`config.ssh.private_key_path`

# Putty

If you are using Vagrant on windows, the .ppk file contained here, in the keys directory,
has been generated from the private key and should be used to connect Putty to any VMs that 
are leveraging the default key pair. See [guide](http://docs.vagrantup.com/v1/docs/getting-started/ssh.html) 
in the documentation for more details on using Putty with Vagrant.
