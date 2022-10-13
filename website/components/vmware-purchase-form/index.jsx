import s from './style.module.css'
import { useState } from 'react'

export default function VMWarePurchaseForm({ productId }) {
  const [seats, setSeats] = useState(1)
  const submit = (e) => {
    e.preventDefault()

    const seatsInt = parseInt(seats, 10)
    if (isNaN(seatsInt)) {
      return alert('The number of seats you want to purchase must be a number.')
    }
    if (seatsInt <= 0) {
      return alert('The number of seats you want must be greater than zero.')
    }

    window.location.href = `http://shopify.hashicorp.com/cart/${productId}:${seats}`
  }

  return (
    <form className={s.root} onSubmit={submit}>
      <input
        type="number"
        value={seats}
        onChange={(e) => setSeats(e.target.value)}
      ></input>
      <button>Buy Now</button>
    </form>
  )
}
