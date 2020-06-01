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
            header: 'IRC',
            body: '`#vagrant` on freenode',
          },
          {
            header: 'Announcement List',
            body:
              '[HashiCorp Announcement Google Group](https://groups.google.com/group/hashicorp-announce)',
          },
          {
            header: 'Discussion List',
            body:
              '[Vagrant Google Group](https://groups.google.com/forum/#!forum/vagrant-up)',
          },
          {
            header: 'Community Forum',
            body:
              '[Vagrant Community Forum](https://discuss.hashicorp.com/c/vagrant/24)',
          },
          {
            header: 'Bug Tracker',
            body:
              '[Issue tracker on GitHub](https://github.com/hashicorp/vagrant/issues). Please only use this for reporting bugs. Do not ask for general help here. Use IRC or the mailing list for that.',
          },
          {
            header: 'Training',
            body:
              'Paid [HashiCorp training courses](https://www.hashicorp.com/training) are also available in a city near you. Private training courses are also available.',
          },
        ]}
      />
    </div>
  )
}
