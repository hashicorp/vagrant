import s from './style.module.css'
import Link from 'next/link'

export default function Footer({ openConsentManager }) {
  return (
    <footer className={s.root}>
      <div className="g-container">
        <Link href="/intro">
          <a>Intro</a>
        </Link>
        <Link href="/docs">
          <a>Docs</a>
        </Link>
        <a href="https://www.amazon.com/gp/product/1449335837/ref=as_li_qf_sp_asin_il_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=1449335837&linkCode=as2&tag=vagrant-20">
          Book
        </a>
        <Link href="/vmware">
          <a>VMware</a>
        </Link>
        <a href="https://hashicorp.com/privacy">Privacy</a>
        <Link href="/security">
          <a>Security</a>
        </Link>
        <Link href="/files/press-kit.zip">
          <a>Press Kit</a>
        </Link>
        <a onClick={openConsentManager}>Consent Manager</a>
      </div>
    </footer>
  )
}
