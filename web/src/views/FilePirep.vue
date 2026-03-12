<template>
  <div>
    <div class="page-header">
      <div class="d-flex align-items-center gap-2 mb-1">
        <router-link to="/pireps" class="text-muted text-decoration-none small">PIREPs</router-link>
        <span class="text-muted small">/</span>
        <span class="small">File PIREP</span>
      </div>
      <h1>File PIREP</h1>
    </div>

    <div class="row">
      <div class="col-md-8">
        <div class="card">
          <div class="card-body">
            <div v-if="success" class="alert alert-success">
              PIREP filed successfully! <router-link to="/pireps">View your PIREPs.</router-link>
            </div>
            <div v-if="error" class="alert alert-danger">{{ error }}</div>

            <div class="mb-3" v-if="activeBookings.length">
              <label class="form-label fw-semibold">From Booking (optional)</label>
              <select v-model="selectedBooking" class="form-select" @change="prefillFromBooking">
                <option :value="null">Manual entry</option>
                <option v-for="b in activeBookings" :key="b.id" :value="b">
                  {{ b.flight_number }} — {{ b.departure_icao }} → {{ b.arrival_icao }} ({{ b.aircraft?.registration }})
                </option>
              </select>
            </div>

            <div class="row mb-3">
              <div class="col-md-6">
                <label class="form-label fw-semibold">Flight Number</label>
                <input v-model="form.flight_number" type="text" class="form-control" placeholder="EZS1401" />
              </div>
              <div class="col-md-6">
                <label class="form-label fw-semibold">Aircraft</label>
                <select v-model="form.aircraft_id" class="form-select">
                  <option :value="null" disabled>Select aircraft...</option>
                  <option v-for="ac in aircraft" :key="ac.id" :value="ac.id">
                    {{ ac.registration }} — {{ ac.type }}
                  </option>
                </select>
              </div>
            </div>

            <div class="row mb-3">
              <div class="col-md-6">
                <label class="form-label fw-semibold">Departure ICAO</label>
                <input v-model="form.departure_icao" type="text" class="form-control" placeholder="LSGG" maxlength="4" />
              </div>
              <div class="col-md-6">
                <label class="form-label fw-semibold">Arrival ICAO</label>
                <input v-model="form.arrival_icao" type="text" class="form-control" placeholder="EGLL" maxlength="4" />
              </div>
            </div>

            <div class="row mb-3">
              <div class="col-md-6">
                <label class="form-label fw-semibold">Departure Time (UTC)</label>
                <input v-model="form.departure_time" type="datetime-local" class="form-control" />
              </div>
              <div class="col-md-6">
                <label class="form-label fw-semibold">Arrival Time (UTC)</label>
                <input v-model="form.arrival_time" type="datetime-local" class="form-control" />
              </div>
            </div>

            <div v-if="form.departure_time && form.arrival_time" class="alert alert-light small mb-3">
              Calculated block time: <strong>{{ calculatedBlockTime }}</strong>
            </div>

            <div class="row mb-3">
              <div class="col-md-4">
                <label class="form-label fw-semibold">Distance (NM)</label>
                <input v-model.number="form.distance_nm" type="number" class="form-control" />
              </div>
              <div class="col-md-4">
                <label class="form-label fw-semibold">Fuel Used (lbs)</label>
                <input v-model.number="form.fuel_used" type="number" class="form-control" />
              </div>
              <div class="col-md-4">
                <label class="form-label fw-semibold">Passengers</label>
                <input v-model.number="form.passengers" type="number" class="form-control" />
              </div>
            </div>

            <div class="row mb-3">
              <div class="col-md-6">
                <label class="form-label fw-semibold">Landing Rate (fpm)</label>
                <input v-model.number="form.landing_rate" type="number" class="form-control" placeholder="-150" />
                <div class="form-text" v-if="form.landing_rate">
                  <span :class="landingQualityClass">{{ landingQuality }}</span>
                </div>
              </div>
            </div>

            <div class="mb-3">
              <label class="form-label fw-semibold">Remarks</label>
              <textarea v-model="form.remarks" class="form-control" rows="3" placeholder="Optional flight notes..."></textarea>
            </div>

            <button
              class="btn btn-primary"
              :disabled="!isValid || loading"
              @click="filePirep"
            >
              {{ loading ? 'Filing...' : 'File PIREP' }}
            </button>
          </div>
        </div>
      </div>

      <div class="col-md-4" v-if="selectedBooking && routeInfo">
        <div class="card">
          <div class="card-header">Route Info</div>
          <div class="card-body">
            <div class="mb-2">
              <span class="text-muted small">Distance</span>
              <div class="fw-semibold">{{ routeInfo.distance_nm }} NM</div>
            </div>
            <div class="mb-2">
              <span class="text-muted small">Est. Time</span>
              <div class="fw-semibold">{{ routeInfo.estimated_time }}</div>
            </div>
            <div>
              <span class="text-muted small">Route</span>
              <div class="fw-semibold">{{ routeInfo.departure_name }} → {{ routeInfo.arrival_name }}</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, reactive, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { supabase } from '../lib/supabase'
import { usePilot } from '../lib/usePilot'

export default {
  setup() {
    const pageRoute = useRoute()
    const aircraft = ref([])
    const activeBookings = ref([])
    const selectedBooking = ref(null)
    const routeInfo = ref(null)
    const loading = ref(false)
    const error = ref('')
    const success = ref(false)
    const { pilot, fetchPilot } = usePilot()

    const form = reactive({
      flight_number: '',
      aircraft_id: null,
      departure_icao: '',
      arrival_icao: '',
      departure_time: '',
      arrival_time: '',
      distance_nm: null,
      fuel_used: null,
      passengers: null,
      landing_rate: null,
      remarks: ''
    })

    const isValid = computed(() => {
      return form.flight_number && form.aircraft_id && form.departure_icao &&
        form.arrival_icao && form.departure_time && form.arrival_time && form.distance_nm
    })

    const computeInterval = (start, end) => {
      const ms = new Date(end) - new Date(start)
      const h = Math.floor(ms / 3600000)
      const m = Math.floor((ms % 3600000) / 60000)
      return `${h}:${String(m).padStart(2, '0')}:00`
    }

    const calculatedBlockTime = computed(() => {
      if (!form.departure_time || !form.arrival_time) return ''
      const ms = new Date(form.arrival_time) - new Date(form.departure_time)
      if (ms <= 0) return 'Invalid (arrival before departure)'
      const h = Math.floor(ms / 3600000)
      const m = Math.floor((ms % 3600000) / 60000)
      return `${h}h ${m}m`
    })

    const landingQuality = computed(() => {
      if (!form.landing_rate) return ''
      const abs = Math.abs(form.landing_rate)
      if (abs <= 100) return 'Excellent landing!'
      if (abs <= 150) return 'Good landing'
      if (abs <= 250) return 'Acceptable landing'
      if (abs <= 400) return 'Hard landing'
      return 'Very hard landing!'
    })

    const landingQualityClass = computed(() => {
      if (!form.landing_rate) return ''
      const abs = Math.abs(form.landing_rate)
      if (abs <= 100) return 'text-success fw-bold'
      if (abs <= 200) return 'text-primary'
      if (abs <= 400) return 'text-warning'
      return 'text-danger fw-bold'
    })

    const prefillFromBooking = async () => {
      if (selectedBooking.value) {
        const b = selectedBooking.value
        form.flight_number = b.flight_number
        form.aircraft_id = b.aircraft_id
        form.departure_icao = b.departure_icao
        form.arrival_icao = b.arrival_icao

        // Fetch route info for distance prefill
        if (b.route_id) {
          const { data: route } = await supabase
            .from('routes')
            .select('*')
            .eq('id', b.route_id)
            .single()
          if (route) {
            routeInfo.value = route
            form.distance_nm = route.distance_nm
          }
        }
      } else {
        routeInfo.value = null
      }
    }

    const resetForm = () => {
      Object.assign(form, {
        flight_number: '', aircraft_id: null, departure_icao: '', arrival_icao: '',
        departure_time: '', arrival_time: '', distance_nm: null, fuel_used: null,
        passengers: null, landing_rate: null, remarks: ''
      })
      selectedBooking.value = null
      routeInfo.value = null
    }

    const filePirep = async () => {
      loading.value = true
      error.value = ''
      success.value = false

      const blockTime = computeInterval(form.departure_time, form.arrival_time)

      const { error: err } = await supabase.from('pireps').insert({
        booking_id: selectedBooking.value?.id || null,
        pilot_id: pilot.value.id,
        aircraft_id: form.aircraft_id,
        flight_number: form.flight_number,
        departure_icao: form.departure_icao.toUpperCase(),
        arrival_icao: form.arrival_icao.toUpperCase(),
        departure_time: new Date(form.departure_time).toISOString(),
        arrival_time: new Date(form.arrival_time).toISOString(),
        block_time: blockTime,
        flight_time: blockTime,
        distance_nm: form.distance_nm,
        fuel_used: form.fuel_used,
        passengers: form.passengers,
        landing_rate: form.landing_rate,
        remarks: form.remarks
      })

      if (err) {
        error.value = err.message
      } else {
        success.value = true
        if (selectedBooking.value) {
          await supabase
            .from('bookings')
            .update({ status: 'completed' })
            .eq('id', selectedBooking.value.id)
        }
        resetForm()
      }
      loading.value = false
    }

    onMounted(async () => {
      const p = await fetchPilot()
      if (!p) return

      const { data: bookings } = await supabase
        .from('bookings')
        .select('*, aircraft(registration)')
        .eq('pilot_id', p.id)
        .in('status', ['booked', 'flying'])
        .order('scheduled_departure')
      activeBookings.value = bookings || []

      const { data: acData } = await supabase
        .from('aircraft')
        .select('*')
        .order('registration')
      aircraft.value = acData || []

      // Auto-select booking if passed via query param
      const bookingId = pageRoute.query.booking
      if (bookingId) {
        const match = activeBookings.value.find(b => b.id === bookingId)
        if (match) {
          selectedBooking.value = match
          await prefillFromBooking()
        }
      }
    })

    return {
      aircraft, activeBookings, selectedBooking, routeInfo, form, isValid,
      loading, error, success, calculatedBlockTime, landingQuality, landingQualityClass,
      prefillFromBooking, filePirep
    }
  }
}
</script>
