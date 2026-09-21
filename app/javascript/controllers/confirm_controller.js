import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    message: String
  }

  confirm(event) {
    const confirmed = window.confirm(this.messageValue)

    if (!confirmed) {
      event.preventDefault()
    }
  }
}