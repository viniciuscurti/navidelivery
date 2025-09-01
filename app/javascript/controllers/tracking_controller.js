import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"
import maplibregl from 'maplibre-gl'

export default class extends Controller {
    static targets = ["map", "eta", "timeline"]
    static values = { token: String }

    connect() {
        this.initializeMap()
        this.subscribeToUpdates()
    }

    disconnect() {
        if (this.subscription) {
            this.subscription.unsubscribe()
        }
        if (this.map) {
            this.map.remove()
        }
    }

    initializeMap() {
        const mapElement = this.mapTarget

        this.map = new maplibregl.Map({
            container: mapElement,
            style: {
                version: 8,
                sources: {
                    'osm': {
                        type: 'raster',
                        tiles: ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
                        tileSize: 256,
                        attribution: '© OpenStreetMap contributors'
                    }
                },
                layers: [{
                    id: 'osm',
                    type: 'raster',
                    source: 'osm'
                }]
            },
            center: [parseFloat(mapElement.dataset.pickupLng), parseFloat(mapElement.dataset.pickupLat)],
            zoom: 13
        })

        this.map.on('load', () => {
            this.addMarkers()
            this.fitBounds()
        })
    }

    addMarkers() {
        // Pickup marker
        new maplibregl.Marker({ color: '#10B981' })
            .setLngLat([
                parseFloat(this.mapTarget.dataset.pickupLng),
                parseFloat(this.mapTarget.dataset.pickupLat)
            ])
            .addTo(this.map)

        // Dropoff marker
        new maplibregl.Marker({ color: '#EF4444' })
            .setLngLat([
                parseFloat(this.mapTarget.dataset.dropoffLng),
                parseFloat(this.mapTarget.dataset.dropoffLat)
            ])
            .addTo(this.map)

        // Current location marker (if available)
        if (this.mapTarget.dataset.currentLat) {
            this.courierMarker = new maplibregl.Marker({ color: '#3B82F6' })
                .setLngLat([
                    parseFloat(this.mapTarget.dataset.currentLng),
                    parseFloat(this.mapTarget.dataset.currentLat)
                ])
                .addTo(this.map)
        }
    }

    fitBounds() {
        const bounds = new maplibregl.LngLatBounds()

        bounds.extend([
            parseFloat(this.mapTarget.dataset.pickupLng),
            parseFloat(this.mapTarget.dataset.pickupLat)
        ])

        bounds.extend([
            parseFloat(this.mapTarget.dataset.dropoffLng),
            parseFloat(this.mapTarget.dataset.dropoffLat)
        ])

        if (this.mapTarget.dataset.currentLat) {
            bounds.extend([
                parseFloat(this.mapTarget.dataset.currentLng),
                parseFloat(this.mapTarget.dataset.currentLat)
            ])
        }

        this.map.fitBounds(bounds, { padding: 50 })
    }

    subscribeToUpdates() {
        const consumer = createConsumer()

        this.subscription = consumer.subscriptions.create(
            {
                channel: "DeliveryChannel",
                public_token: this.tokenValue
            },
            {
                received: (data) => {
                    this.handleUpdate(data)
                }
            }
        )
    }

    handleUpdate(data) {
        switch (data.type) {
            case 'location_update':
                this.updateCourierLocation(data.lat, data.lng)
                break
            case 'status_change':
                this.updateStatus(data.status)
                break
            case 'eta_update':
                this.updateETA(data.estimated_arrival)
                break
        }
    }

    updateCourierLocation(lat, lng) {
        if (this.courierMarker) {
            this.courierMarker.setLngLat([lng, lat])
        } else {
            this.courierMarker = new maplibregl.Marker({ color: '#3B82F6' })
                .setLngLat([lng, lat])
                .addTo(this.map)
        }
    }

    updateStatus(status) {
        // Update timeline
        const timelineItems = this.timelineTarget.querySelectorAll('.timeline-item')
        timelineItems.forEach((item, index) => {
            if (index <= this.getStatusIndex(status)) {
                item.classList.add('active')
            }
        })
    }

    updateETA(estimatedArrival) {
        if (this.hasEtaTarget && estimatedArrival) {
            const eta = new Date(estimatedArrival)
            this.etaTarget.textContent = eta.toLocaleTimeString('pt-BR', {
                hour: '2-digit',
                minute: '2-digit'
            })
        }
    }

    getStatusIndex(status) {
        const statuses = ['created', 'assigned', 'en_route', 'arrived_pickup', 'left_pickup', 'arrived_dropoff', 'delivered']
        return statuses.indexOf(status)
    }
}
