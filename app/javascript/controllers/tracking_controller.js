import { Controller } from "@hotwired/stimulus"
import maplibregl from "maplibre-gl"

export default class extends Controller {
  connect() {
    this.map = new maplibregl.Map({
      container: "map",
      style: "https://demotiles.maplibre.org/style.json",
      center: [0, 0],
      zoom: 14
    })
    this.marker = new maplibregl.Marker().setLngLat([0, 0]).addTo(this.map)
    this.subscribeToChannel()
  }

  subscribeToChannel() {
    const token = this.element.dataset.trackingPublicToken
    const channel = window.App.cable.subscriptions.create(
      { channel: "DeliveryChannel", public_token: token },
      {
        received: data => {
          if (data.location) {
            this.marker.setLngLat([data.location.lon, data.location.lat])
            this.map.setCenter([data.location.lon, data.location.lat])
          }
        }
      }
    )
  }
}

