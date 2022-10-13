import s from './style.module.css'
import Button from '@hashicorp/react-button'
import TextSplit from 'components/temporary_text-split'
import CodeBlock from '@hashicorp/react-code-block'
import { VERSION } from 'data/version.json'

export default function HomePage() {
  return (
    <div>
      <section className={s.hero}>
        <div className="g-grid-container">
          <img src="/img/logo-hashicorp.svg" alt="Vagrant Logo" />
          <h1 className="g-type-display-3">
            Development Environments Made Easy
          </h1>
          <div className={s.buttons}>
            <Button title="Get Started" url="/intro/index" />
            <Button
              title={`Download ${VERSION}`}
              theme={{ variant: 'secondary' }}
              url="/downloads"
            />
            <Button
              title="Find Boxes"
              theme={{ variant: 'secondary' }}
              url="https://app.vagrantup.com/boxes/search"
            />
          </div>
        </div>
      </section>

      <section className={s.unifiedWorkflow}>
        <div className="g-grid-container">
          <TextSplit
            text={{
              tag: 'Unified Workflow',
              headline: 'Simple and Powerful',
              text:
                'HashiCorp Vagrant provides the same, easy workflow regardless of your role as a developer, operator, or designer. It leverages a declarative configuration file which describes all your software requirements, packages, operating system configuration, users, and more.',
            }}
          >
            <CodeBlock
              code={`$ vagrant init hashicorp/bionic64
$ vagrant up
  Bringing machine 'default' up with 'virtualbox' provider...
  ==> default: Importing base box 'hashicorp/bionic64'...
  ==> default: Forwarding ports...
  default: 22 (guest)
  => 2222 (host) (adapter 1)
  ==> default: Waiting for machine to boot...

$ vagrant ssh
  vagrant@bionic64:~$ _`}
            />
          </TextSplit>
        </div>
      </section>

      <section className={s.enforceConsistency}>
        <div className="g-grid-container">
          <TextSplit
            text={{
              tag: 'Enforce Consistency',
              headline: 'Production Parity',
              text:
                'The cost of fixing a bug exponentially increases the closer it gets to production. Vagrant aims to mirror production environments by providing the same operating system, packages, users, and configurations, all while giving users the flexibility to use their favorite editor, IDE, and browser. Vagrant also integrates with your existing configuration management tooling like Ansible, Chef, Docker, Puppet or Salt, so you can use the same scripts to configure Vagrant as production.',
            }}
            reverse={true}
          >
            <img src="/img/parity.svg" alt="Server Parity Diagram" />
          </TextSplit>
        </div>
      </section>

      <section className={s.crossPlatform}>
        <div className="g-grid-container">
          <TextSplit
            text={{
              tag: 'Cross-Platform',
              headline: 'Works where you work',
              text:
                "Vagrant works on Mac, Linux, Windows, and more. Remote development environments force users to give up their favorite editors and programs. Vagrant works on your local system with the tools you're already familiar with. Easily code in your favorite text editor, edit images in your favorite manipulation program, and debug using your favorite tools, all from the comfort of your local laptop.",
            }}
          >
            {['apple', 'linux', 'windows'].map((platform) => (
              <img
                key={platform}
                src={`/img/systems/${platform}.svg`}
                alt={`${platform} logo`}
              />
            ))}
          </TextSplit>
        </div>
      </section>

      <section className={s.trustedAtScale}>
        <div className="g-grid-container">
          <div className={s.tag}>Trusted at Scale</div>
          <h2 className={s.h2}>Trusted By</h2>
          <p className="g-type-body">
            Vagrant is trusted by thousands of developers, operators, and
            designers everyday. Here are just a few of the organizations that
            choose Vagrant to automate their development environments, in
            lightweight and reproducible ways.
          </p>
          <img
            className={s.customerImg}
            src="/img/customers.png"
            alt="Logos of Vagrant customers"
          />
        </div>
      </section>
    </div>
  )
}
