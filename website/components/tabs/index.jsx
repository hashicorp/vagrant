import s from './style.module.css'
import ReactTabs from '@hashicorp/react-tabs'

export default function Tabs({ children }) {
  return (
    <span className={s.root}>
      <ReactTabs
        items={children.map((Block) => ({
          heading: Block.props.heading,
          // eslint-disable-next-line react/display-name
          tabChildren: () => Block,
        }))}
      />
    </span>
  )
}

export function Tab({ children }) {
  return <>{children}</>
}
