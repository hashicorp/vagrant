import s from './style.module.css'
import Button from '@hashicorp/react-button'
import VMWarePurchaseForm from 'components/vmware-purchase-form'
import Head from 'next/head'
import HashiHead from '@hashicorp/react-head'

export default function VmwareIndex() {
  return (
    <>
      <HashiHead is={Head} title="VMware Integration | Vagrant by HashiCorp" />
      <section className={s.header}>
        <div className="g-grid-container">
          <div className={s.logos}>
            <img src="/img/logo-text.svg" alt="Vagrant Logo" />
            <span>+</span>
            <img src="/img/vmware.svg" alt="VMware Logo" />
          </div>
          <h1 className={s.mainHeadline}>
            Supercharged Development Environments
          </h1>
          <h4 className={s.mainSubhead}>
            Use Vagrant with VMware for improved stability, performance, and
            support.
          </h4>
          <div className={s.buttons}>
            <Button title="Buy Now" url="#buy-now" />
            <Button
              title="Learn More"
              url="#learn-more"
              theme={{ variant: 'secondary' }}
            />
          </div>
        </div>
      </section>

      <section className={s.benefits} id="learn-more">
        <div className="g-grid-container">
          <div className={s.tag}>Benefits</div>
          <h2 className={s.h2}>VMware Makes Your Life Better</h2>
          <ul className={s.column}>
            <li>
              <h4>Same Vagrant Workflow</h4>
              <p className="g-type-body">
                <code>vagrant up</code>, <code>vagrant ssh</code>,{' '}
                <code>vagrant destroy</code> - the same Vagrant workflow you
                know and love. Vastly improve your work environments without
                having to re-educate your team.
              </p>
            </li>
            <li>
              <h4>Rock Solid Stability</h4>
              <p className="g-type-body">
                The VMware hypervisor has been in production use since 1999. All
                their products share the same, robust core that powers the
                world&lsquo;s largest organizations. With the VMware provider,
                Vagrant now runs on the strength of the same foundation.
              </p>
            </li>
            <li>
              <h4>Professional Support</h4>
              <p className="g-type-body">
                Every purchase of the Vagrant VMware provider comes with direct
                email support. VMware products themselves are eligible for
                professional support from VMware. Someone always has your back
                in case things are not working as well as they should be.
              </p>
            </li>
            <li>
              <h4>Unparalleled Performance</h4>
              <p className="g-type-body">
                VMware <em>screams</em>, with industry-leading performance
                <sup>1</sup> based on the same hypervisor technology in use by
                98% of the Fortune 500. Get all the performance gains paired
                with the ease of use of Vagrant.
              </p>
            </li>
            <li>
              <h4>Uncompromised Portability</h4>
              <p className="g-type-body">
                VMware virtual machines run on Mac OS X, Windows, and Linux.
                Vagrant provides support for both VMware Fusion (Mac OS X) and
                VMware Workstation (Linux and Windows), which are able to run
                the same virtual machines across multiple platforms.
              </p>
            </li>
            <li>
              <h4>Vagrant ♥ Open Source</h4>
              <p className="g-type-body">
                Vagrant is free and open source. While the VMware providers are
                not, the revenue is used to continue to develop, support, and
                grow Vagrant and the community around it.
              </p>
            </li>
          </ul>
          <small>
            <sup>1</sup> According to{' '}
            <a href="http://www.macworld.com/article/1164817/the_best_way_to_run_windows_on_your_mac.html">
              this article in MacWorld
            </a>{' '}
            vs. Parallels Desktop 7
          </small>
        </div>
      </section>

      <section className={s.buyNow} id="buy-now">
        <div className="g-grid-container">
          <div className={s.tag}>Buy Now</div>
          <h2 className={s.h2}>Pricing &amp; Purchase</h2>
          <p className="g-type-body">
            <strong>Price:</strong> $79 per seat.
          </p>
          <p className="g-type-body">
            A single seat can be used on two computers (such as a desktop and a
            laptop) for a single person. The license is valid forever with
            access to free maintenance updates. Future major updates may require
            an upgrade fee.
          </p>
          <p className="g-type-body">
            Enter the number of seats you wish to purchase below. Then, click
            the buy button and complete the order. Instructions to install and
            download the software will be emailed to you.
          </p>
          <div className={s.purchaseForm}>
            <p className="g-type-body">
              <strong>VMware Fusion 12 / VMware Workstation 16 or lower</strong>
            </p>
            <VMWarePurchaseForm productId="7255390650419" />
          </div>
          <small>
            <p>
              The provider license does not include a license to the VMware
              software, which must be purchased separately. If you are buying
              over 150 licenses, contact{' '}
              <a href="mailto:sales@hashicorp.com">sales@hashicorp.com</a> for
              volume pricing. By purchasing this license, you agree to the{' '}
              <a href="https://www.vagrantup.com/vmware/eula.html">EULA</a> and
              the HashiCorp{' '}
              <a href="https://www.hashicorp.com/privacy">Privacy Policy</a> and{' '}
              <a href="https://www.vagrantup.com/vmware/terms-of-service.html">
                Terms of Service
              </a>
              .
            </p>
            <p>
              Previous plugin versions may not support the latest VMware
              products. Please visit the{' '}
              <a href="http://license.hashicorp.com/upgrade/vmware">
                license upgrade center
              </a>{' '}
              to check if your license requires an upgrade before you upgrade
              your VMware products.
            </p>
            <p>
              For reseller information,{' '}
              <a href="https://www.vagrantup.com/vmware/reseller.html">
                click here
              </a>
              .
            </p>
          </small>
        </div>
      </section>

      <section id="faq" className={s.faq}>
        <div className="g-grid-container">
          <div className={s.tag}>FAQ</div>
          <h2 className={s.h2}>Frequently Asked Questions</h2>
          <ul>
            <li>
              <h4>Do you offer a trial for the Vagrant VMware plugins?</h4>
              <p className="g-type-body">
                We do not offer a trial mechanism at this time, but we do offer
                a 30-day, no questions asked, 100% money-back guarantee. If you
                are not satisfied with the product, contact us within 30 days
                and you will receive a full refund.
              </p>
            </li>
            <li>
              <h4>
                Do you offer educational discounts on the Vagrant VMware
                plugins?
              </h4>
              <p className="g-type-body">
                We offer an academic discount of 10% for the Vagrant VMware
                plugins. However, we require proof that you are a current
                student or employee in academia. Please contact support with{' '}
                <strong>any one</strong> of the following forms of proof:
              </p>
              <ul>
                <li>A picture of your current university ID</li>
                <li>
                  An email from your official <code>.edu</code> school email
                  address
                </li>
                <li>
                  A copy of something on university letterhead indicating you
                  are currently enrolled as a student
                </li>
              </ul>
            </li>
            <li>
              <h4>I already own a license, am I eligible for an upgrade?</h4>
              <p className="g-type-body">
                Existing license holders may check their upgrade eligibility by
                visiting{' '}
                <a href="http://license.hashicorp.com/upgrade/vmware">
                  the license upgrade center
                </a>
                . If you are eligible for an upgrade, the system will generate a
                unique discount code that may be used when purchasing the new
                license.
              </p>
            </li>
            <li>
              <h4>Do I need to pay for upgrades to my license?</h4>
              <p className="g-type-body">
                The Vagrant VMware plugin licenses are valid for specific VMware
                product versions at the time of purchase. When new versions of
                VMware products are released, significant changes to the plugin
                code are often required to support this new version. For this
                reason, you may need to upgrade your current license to work
                with the new version of the VMware product. Customers can check
                their license upgrade eligibility by visiting the{' '}
                <a href="http://license.hashicorp.com/upgrade/vmware">
                  License Upgrade Center
                </a>{' '}
                and entering the email address with which they made the original
                purchase.
              </p>
              <p className="g-type-body">
                Please note: your existing license will continue to work with
                all previous versions of the VMware products. If you do not wish
                to update at this time, you can rollback your VMware
                installation to an older version.
              </p>
            </li>
            <li>
              <h4>Where can I find the EULA for the Vagrant VMware Plugins?</h4>
              <p className="g-type-body">
                The{' '}
                <a href="/vmware/eula.html">
                  EULA for the Vagrant VMware plugins
                </a>{' '}
                is available on the Vagrant website.
              </p>
            </li>
            <li>
              <h4>Do you offer incentives for resellers?</h4>
              <p className="g-type-body">
                All our reseller information can be found on the{' '}
                <a href="/vmware/reseller.html">Reseller Information</a> page.
              </p>
            </li>
            <li>
              <h4>
                Do you offer bulk/volume discounts for the Vagrant VMware
                plugins?
              </h4>
              <p className="g-type-body">
                We certainly do!{' '}
                <a href="mailto:support@hashicorp.com?subject=Bulk Discounts">
                  Email support
                </a>{' '}
                with the number of licenses you need and we can give you bulk
                pricing information. Please note that bulk pricing requires the
                purchase of
                <em>at least 150 seats</em>.
              </p>
            </li>
            <li>
              <h4>Does this include the VMware software?</h4>
              <p className="g-type-body">
                The Vagrant VMware Plugin requires the separate purchase of
                VMware Fusion/Workstation from VMware. The VMware product is not
                bundled with the plugin.
              </p>
            </li>
            <li>
              <h4>
                Why is the Vagrant VMware plugin not working with my trial
                version of VMware Fusion/Workstation?
              </h4>
              <p className="g-type-body">
                While we have not been able to isolate to a specific issue or
                cause, the Vagrant VMware Fusion and Vagrant VMware Workstation
                plugins are sometimes incompatible with the trial versions of
                the VMware products.
              </p>
              <p className="g-type-body">
                Please try restarting your computer and running the VMware
                software manually. Occasionally you must accept the license
                agreement before VMware will run. If you do not see any errors
                when opening the VMware GUI, you may need to purchase the full
                version to use the plugin. We apologize for the inconvenience.
              </p>
            </li>
            <li>
              <h4>Can I use VMware Workstation Player?</h4>
              <p className="g-type-body">
                <em>Some</em> features of the Vagrant VMware Workstation plugin
                will work with VMware Player, but it is not officially
                supported. Vagrant interacts with VMware via the VMware API, and
                some versions of VMware Workstation Player do not support those
                APIs. When in doubt, please purchase VMware Workstation Pro to
                use all the features supported by the integration.
              </p>
            </li>
            <li>
              <h4>
                Do I need VMware Fusion/Workstation Pro or just the regular
                version?
              </h4>
              <p className="g-type-body">
                The Vagrant VMware plugin is compatible with both the regular
                and Pro versions of VMware Fusion and VMware Workstation.
                However, some advanced features (such as linked clones), are
                only supported by the Pro versions of the VMware software.
              </p>
              <p className="g-type-body">
                Please consult the VMware documentation to determine which
                features are supported by the Pro and non-Pro versions to
                determine which product you need to purchase.
              </p>
            </li>
          </ul>
        </div>
      </section>
    </>
  )
}
