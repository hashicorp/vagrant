# Insecure Keypair

These keys are the "insecure" public/private keypair we offer to
[base box creators](https://www.vagrantup.com/docs/boxes/base.html) for use in their base boxes so that
vagrant installations can automatically SSH into the boxes.

If you're working with a team or company or with a custom box and
you want more secure SSH, you should create your own keypair
and configure the private key in the Vagrantfile with
`config.ssh.private_key_path`
