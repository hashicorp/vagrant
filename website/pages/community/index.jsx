import s from './style.module.css'
import VerticalTextBlockList from '@hashicorp/react-vertical-text-block-list'
import SectionHeader from '@hashicorp/react-section-header'
import Head from 'next/head'

export default function CommunityPage() {
  return (
    <div className={s.root}>
      <Head>
        <title key="title">Community | Vagrant by HashiCorp</title>
      </Head>
      <SectionHeader
        headline="Community"
        description="Vagrant is an open source project with a growing community. There are active, dedicated users willing to help you through various mediums."
        use_h1={true}
      />
      <VerticalTextBlockList
        data={[
          {
            header: 'Community Forum',
            body:
              '<a href="https://discuss.hashicorp.com/c/vagrant/24">Vagrant Community Forum</a>',
          },
          {
            header: 'Announcement List',
            body:
              '<a href="https://groups.google.com/group/hashicorp-announce">HashiCorp Announcement Google Group</a>',
          },
          {
            header: 'Discussion List',
            body:
              '<a href="https://groups.google.com/forum/#!forum/vagrant-up">Vagrant Google Group</a>',
          },
          {
            header: 'Bug Tracker',
            body:
              '<a href="https://github.com/hashicorp/vagrant/issues">Issue tracker on GitHub</a>. Please only use this for reporting bugs. Do not ask for general help here. Use IRC or the mailing list for that.',
          },
          {
            header: 'Training',
            body:
              'Paid <a href="https://www.hashicorp.com/training">HashiCorp training courses</a> are also available in a city near you. Private training courses are also available.',
          },
        ]}
      />
    </div>
  )
}
