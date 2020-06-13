// The root folder for this documentation category is `pages/docs`
//
// - A string refers to the name of a file
// - A "category" value refers to the name of a directory
// - All directories must have an "index.mdx" file to serve as
//   the landing page for the category, or a "name" property to
//   serve as the category title in the sidebar

export default [
  'index',
  {
    category: 'installation',
    content: [
      'backwards-compatibility',
      'upgrading',
      'upgrading-from-1-0',
      'source',
      'uninstallation',
    ],
  },
  {
    category: 'cli',
    content: [
      'box',
      'cloud',
      'connect',
      'destroy',
      'global-status',
      'halt',
      'init',
      'login',
      'package',
      'plugin',
      'port',
      'powershell',
      'provision',
      'rdp',
      'reload',
      'resume',
      'share',
      'snapshot',
      'ssh',
      'ssh_config',
      'status',
      'suspend',
      'up',
      'upload',
      'validate',
      'version',
      'non-primary',
      'aliases',
      'machine-readable',
    ],
  },
  {
    category: 'share',
    content: ['http', 'ssh', 'connect', 'security', 'provider'],
  },
  {
    category: 'vagrantfile',
    content: [
      'version',
      'vagrant_version',
      'tips',
      'machine_settings',
      'ssh_settings',
      'winrm_settings',
      'winssh_settings',
      'vagrant_settings',
    ],
  },
  { category: 'boxes', content: ['versioning', 'base', 'format', 'info'] },
  {
    category: 'provisioning',
    content: [
      'basic_usage',
      'file',
      'shell',
      'ansible_intro',
      'ansible',
      'ansible_local',
      'ansible_common',
      'cfengine',
      'chef_common',
      'chef_solo',
      'chef_zero',
      'chef_client',
      'chef_apply',
      'docker',
      'podman',
      'puppet_apply',
      'puppet_agent',
      'salt',
    ],
  },
  {
    category: 'networking',
    content: [
      'basic_usage',
      'forwarded_ports',
      'private_network',
      'public_network',
    ],
  },
  {
    category: 'synced-folders',
    content: ['basic_usage', 'nfs', 'rsync', 'smb', 'virtualbox'],
  },
  {
    category: 'cloud-init',
    content: [
      'configuration',
      'usage'
    ],
  },
  {
    category: 'disks',
    content: [
      'configuration',
      'usage',
      { category: 'virtualbox', content: ['usage', 'common-issues'] },
    ],
  },
  'multi-machine',
  {
    category: 'providers',
    content: [
      'installation',
      'basic_usage',
      'configuration',
      'default',
      {
        category: 'virtualbox',
        content: [
          'usage',
          'boxes',
          'configuration',
          'networking',
          'common-issues',
        ],
      },
      {
        category: 'vmware',
        content: [
          'installation',
          'vagrant-vmware-utility',
          'usage',
          'boxes',
          'configuration',
          'known-issues',
          'kernel-upgrade',
        ],
      },
      {
        category: 'docker',
        content: ['basics', 'commands', 'boxes', 'configuration', 'networking'],
      },
      {
        category: 'hyperv',
        content: ['usage', 'boxes', 'configuration', 'limitations'],
      },
      'custom',
    ],
  },
  {
    category: 'plugins',
    content: [
      'usage',
      'development-basics',
      'action-hooks',
      'commands',
      'configuration',
      'guests',
      'guest-capabilities',
      'hosts',
      'host-capabilities',
      'providers',
      'provisioners',
      'packaging',
    ],
  },
  { category: 'push', content: ['ftp', 'heroku', 'local-exec'] },
  { category: 'triggers', content: ['configuration', 'usage'] },
  'experimental',
  {
    category: 'other',
    content: ['debugging', 'environmental-variables', 'wsl'],
  },
  '---',
  { title: 'Vagrant Cloud', href: '/vagrant-cloud' },
]
