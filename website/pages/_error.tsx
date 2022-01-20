import ErrorView from '@hashicorp/react-error-view'
import Bugsnag from '@hashicorp/platform-runtime-error-monitoring'

function Error({ statusCode }) {
  return <ErrorView statusCode={statusCode} />
}

Error.getInitialProps = ({ res, err }) => {
  if (err) Bugsnag.notify(err)
  const statusCode = res ? res.statusCode : err ? err.statusCode : 404
  return { statusCode }
}

export default Error
