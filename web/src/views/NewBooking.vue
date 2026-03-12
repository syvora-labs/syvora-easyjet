<template>
  <div>
    <div class="page-header">
      <div class="d-flex align-items-center gap-2 mb-1">
        <router-link to="/bookings" class="text-muted text-decoration-none small">Bookings</router-link>
        <span class="text-muted small">/</span>
        <span class="small">New Booking</span>
      </div>
      <h1>Create Booking</h1>
    </div>

    <div class="row">
      <div class="col-md-8">
        <div class="card">
          <div class="card-body">
            <div v-if="success" class="alert alert-success">
              Booking created! <router-link to="/bookings">View your bookings.</router-link>
            </div>
            <div v-if="error" class="alert alert-danger">{{ error }}</div>

            <div class="mb-3">
              <label class="form-label fw-semibold">Departure Hub</label>
              <select v-model="hubFilter" class="form-select" @change="selectedRoute = null">
                <option value="">All Hubs</option>
                <option value="LSGG">LSGG - Geneva</option>
                <option value="LSZH">LSZH - Zurich</option>
                <option value="LSBS">LSBS - Basel</option>
              </select>
            </div>

            <div class="mb-3">
              <label class="form-label fw-semibold">Route</label>
              <select v-model="selectedRoute" class="form-select" @change="onRouteChange">
                <option :value="null" disabled>Select a route...</option>
                <option v-for="r in filteredRoutes" :key="r.id" :value="r">
                  {{ r.flight_number }} — {{ r.departure_name }} ({{ r.departure_icao }}) → {{ r.arrival_name }} ({{ r.arrival_icao }})
                </option>
              </select>
            </div>

            <div class="mb-3" v-if="selectedRoute">
              <label class="form-label fw-semibold">Aircraft</label>
              <select v-model="selectedAircraft" class="form-select">
                <option :value="null" disabled>Select aircraft...</option>
                <option v-for="ac in availableAircraft" :key="ac.id" :value="ac.id">
                  {{ ac.registration }} — {{ ac.type }} ({{ ac.seat_capacity }} seats)
                </option>
              </select>
            </div>

            <div class="mb-3" v-if="selectedRoute">
              <label class="form-label fw-semibold">Scheduled Departure</label>
              <input v-model="departure" type="datetime-local" class="form-control" />
            </div>

            <div v-if="selectedRoute" class="card bg-light mb-3">
              <div class="card-body">
                <div class="row text-center">
                  <div class="col">
                    <div class="small text-muted">Distance</div>
                    <div class="fw-bold">{{ selectedRoute.distance_nm }} NM</div>
                  </div>
                  <div class="col">
                    <div class="small text-muted">Est. Time</div>
                    <div class="fw-bold">{{ selectedRoute.estimated_time }}</div>
                  </div>
                  <div class="col">
                    <div class="small text-muted">From</div>
                    <div class="fw-bold">{{ selectedRoute.departure_icao }}</div>
                  </div>
                  <div class="col">
                    <div class="small text-muted">To</div>
                    <div class="fw-bold">{{ selectedRoute.arrival_icao }}</div>
                  </div>
                </div>
              </div>
            </div>

            <button
              class="btn btn-primary"
              :disabled="!selectedRoute || !selectedAircraft || !departure || loading"
              @click="createBooking"
            >
              {{ loading ? 'Creating...' : 'Create Booking' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { supabase } from '../lib/supabase'
import { usePilot } from '../lib/usePilot'

export default {
  setup() {
    const pageRoute = useRoute()
    const routes = ref([])
    const aircraft = ref([])
    const availableAircraft = ref([])
    const selectedRoute = ref(null)
    const selectedAircraft = ref(null)
    const departure = ref('')
    const hubFilter = ref('')
    const loading = ref(false)
    const error = ref('')
    const success = ref(false)
    const { pilot, fetchPilot } = usePilot()

    const filteredRoutes = computed(() => {
      if (!hubFilter.value) return routes.value
      return routes.value.filter(r => r.departure_icao === hubFilter.value)
    })

    const onRouteChange = () => {
      selectedAircraft.value = null
      if (selectedRoute.value) {
        availableAircraft.value = aircraft.value.filter(a => a.status === 'active')
      }
    }

    const createBooking = async () => {
      loading.value = true
      error.value = ''
      success.value = false

      const { error: err } = await supabase.from('bookings').insert({
        pilot_id: pilot.value.id,
        route_id: selectedRoute.value.id,
        aircraft_id: selectedAircraft.value,
        flight_number: selectedRoute.value.flight_number,
        departure_icao: selectedRoute.value.departure_icao,
        arrival_icao: selectedRoute.value.arrival_icao,
        scheduled_departure: new Date(departure.value).toISOString()
      })

      if (err) {
        error.value = err.message
      } else {
        success.value = true
        selectedRoute.value = null
        selectedAircraft.value = null
        departure.value = ''
      }
      loading.value = false
    }

    onMounted(async () => {
      await fetchPilot()

      const { data: routeData } = await supabase
        .from('routes')
        .select('*')
        .eq('is_active', true)
        .order('flight_number')
      routes.value = routeData || []

      const { data: acData } = await supabase
        .from('aircraft')
        .select('*')
        .eq('status', 'active')
        .order('registration')
      aircraft.value = acData || []

      // Auto-select route if passed via query param
      const routeId = pageRoute.query.route
      if (routeId) {
        const match = routes.value.find(r => r.id === routeId)
        if (match) {
          selectedRoute.value = match
          hubFilter.value = match.departure_icao
          onRouteChange()
        }
      }
    })

    return {
      routes, aircraft, availableAircraft, selectedRoute, selectedAircraft,
      departure, hubFilter, filteredRoutes, loading, error, success, onRouteChange, createBooking
    }
  }
}
</script>
