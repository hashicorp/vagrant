import styles from './style.module.css'

export default function TextSplit({ text, reverse, children }) {
  return (
    <div className={`${styles.root} ${reverse ? styles.reverse : ''}`}>
      <div className={styles.text}>
        <div className={styles.tag}>{text.tag}</div>
        <h2 className={styles.headline}>{text.headline}</h2>
        <p className="g-type-body">{text.text}</p>
      </div>
      <div className={styles.content}>{children}</div>
    </div>
  )
}
