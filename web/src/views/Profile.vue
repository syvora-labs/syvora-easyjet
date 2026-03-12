<template>
  <div>
    <div v-if="loading" class="text-center text-muted py-5">Loading profile...</div>

    <div v-else-if="!pilot" class="text-center text-muted py-5">
      Could not load pilot profile. Please try signing out and back in.
    </div>

    <div v-else>
      <div class="page-header d-flex justify-content-between align-items-start">
        <div>
          <h1>Pilot Profile</h1>
          <p>{{ pilot.first_name }} {{ pilot.last_name }} — {{ pilot.callsign }}</p>
        </div>
        <button v-if="!editing" class="btn btn-outline-primary" @click="startEdit">
          Edit Profile
        </button>
      </div>

      <div class="row g-3 mb-4">
        <div class="col-md-3">
          <div class="card stat-card">
            <div class="stat-value">{{ pilot.total_flights }}</div>
            <div class="stat-label">Total Flights</div>
          </div>
        </div>
        <div class="col-md-3">
          <div class="card stat-card stat-green">
            <div class="stat-value">{{ Number(pilot.total_hours).toFixed(1) }}h</div>
            <div class="stat-label">Flight Hours</div>
          </div>
        </div>
        <div class="col-md-3">
          <div class="card stat-card stat-blue">
            <div class="stat-value">{{ avgLanding || '-' }}</div>
            <div class="stat-label">Avg Landing Rate</div>
          </div>
        </div>
        <div class="col-md-3">
          <div class="card stat-card stat-purple">
            <div class="stat-value">{{ pilot.rank }}</div>
            <div class="stat-label">Rank</div>
          </div>
        </div>
      </div>

      <div class="row g-3">
        <div class="col-md-6">
          <div class="card">
            <div class="card-header">Profile Details</div>
            <div class="card-body" v-if="!editing">
              <table class="table table-sm mb-0">
                <tr><td class="text-muted">Callsign</td><td class="fw-semibold">{{ pilot.callsign }}</td></tr>
                <tr><td class="text-muted">Name</td><td>{{ pilot.first_name }} {{ pilot.last_name }}</td></tr>
                <tr><td class="text-muted">Rank</td><td>{{ pilot.rank }}</td></tr>
                <tr><td class="text-muted">Home Hub</td><td>{{ pilot.hub }}</td></tr>
                <tr><td class="text-muted">Joined</td><td>{{ new Date(pilot.joined_at).toLocaleDateString() }}</td></tr>
                <tr><td class="text-muted">Total Flights</td><td>{{ pilot.total_flights }}</td></tr>
                <tr><td class="text-muted">Total Hours</td><td>{{ Number(pilot.total_hours).toFixed(1) }}h</td></tr>
              </table>
            </div>
            <div class="card-body" v-else>
              <div v-if="editError" class="alert alert-danger small py-2">{{ editError }}</div>
              <div class="row mb-3">
                <div class="col">
                  <label class="form-label small fw-semibold">First Name</label>
                  <input v-model="editForm.first_name" type="text" class="form-control" />
                </div>
                <div class="col">
                  <label class="form-label small fw-semibold">Last Name</label>
                  <input v-model="editForm.last_name" type="text" class="form-control" />
                </div>
              </div>
              <div class="mb-3">
                <label class="form-label small fw-semibold">Callsign</label>
                <input v-model="editForm.callsign" type="text" class="form-control" />
              </div>
              <div class="mb-3">
                <label class="form-label small fw-semibold">Home Hub</label>
                <select v-model="editForm.hub" class="form-select">
                  <option value="LSGG">LSGG - Geneva</option>
                  <option value="LSZH">LSZH - Zurich</option>
                  <option value="LSBS">LSBS - Basel</option>
                </select>
              </div>
              <div class="d-flex gap-2">
                <button class="btn btn-primary" :disabled="saving" @click="saveEdit">
                  {{ saving ? 'Saving...' : 'Save Changes' }}
                </button>
                <button class="btn btn-outline-secondary" @click="editing = false">Cancel</button>
              </div>
            </div>
          </div>

          <div class="card mt-3">
            <div class="card-header">Flight Stats Summary</div>
            <div class="card-body">
              <div class="row text-center">
                <div class="col">
                  <div class="text-muted small">Best Landing</div>
                  <div class="fw-bold" :class="bestLanding ? 'text-success' : ''">{{ bestLanding || '-' }}</div>
                </div>
                <div class="col">
                  <div class="text-muted small">Worst Landing</div>
                  <div class="fw-bold" :class="worstLanding ? 'text-danger' : ''">{{ worstLanding || '-' }}</div>
                </div>
                <div class="col">
                  <div class="text-muted small">Total Distance</div>
                  <div class="fw-bold">{{ totalDistance }} NM</div>
                </div>
                <div class="col">
                  <div class="text-muted small">Total Fuel</div>
                  <div class="fw-bold">{{ totalFuel }} lbs</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="col-md-6">
          <div class="card">
            <div class="card-header">Monthly Flights</div>
            <div class="card-body">
              <canvas ref="chartCanvas" height="200"></canvas>
              <div v-if="!pireps.length" class="text-center text-muted small py-3">No flight data yet.</div>
            </div>
          </div>

          <div class="card mt-3">
            <div class="card-header">Top Routes</div>
            <div class="card-body p-0">
              <table class="table table-ej mb-0" v-if="topRoutes.length">
                <thead>
                  <tr>
                    <th>Route</th>
                    <th>Flights</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="r in topRoutes" :key="r.route">
                    <td class="fw-semibold">{{ r.route }}</td>
                    <td>{{ r.count }}</td>
                  </tr>
                </tbody>
              </table>
              <div v-else class="p-3 text-center text-muted small">No flights yet.</div>
            </div>
          </div>

          <div class="card mt-3">
            <div class="card-header">Aircraft Flown</div>
            <div class="card-body p-0">
              <table class="table table-ej mb-0" v-if="aircraftFlown.length">
                <thead>
                  <tr>
                    <th>Aircraft</th>
                    <th>Flights</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="a in aircraftFlown" :key="a.name">
                    <td class="fw-semibold">{{ a.name }}</td>
                    <td>{{ a.count }}</td>
                  </tr>
                </tbody>
              </table>
              <div v-else class="p-3 text-center text-muted small">No flights yet.</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, reactive, onMounted, nextTick } from 'vue'
import { Chart, registerables } from 'chart.js'
import { supabase } from '../lib/supabase'

Chart.register(...registerables)

export default {
  setup() {
    const pilot = ref(null)
    const loading = ref(true)
    const pireps = ref([])
    const avgLanding = ref(null)
    const bestLanding = ref(null)
    const worstLanding = ref(null)
    const totalDistance = ref(0)
    const totalFuel = ref(0)
    const topRoutes = ref([])
    const aircraftFlown = ref([])
    const chartCanvas = ref(null)
    const editing = ref(false)
    const saving = ref(false)
    const editError = ref('')
    const editForm = reactive({
      first_name: '',
      last_name: '',
      callsign: '',
      hub: 'LSGG'
    })

    const loadProfile = async () => {
      loading.value = true

      const { data: { user } } = await supabase.auth.getUser()
      if (!user) {
        loading.value = false
        return
      }

      const { data: pilotData, error: pilotErr } = await supabase
        .from('pilots')
        .select('*')
        .eq('user_id', user.id)
        .single()

      if (pilotErr || !pilotData) {
        loading.value = false
        return
      }

      pilot.value = pilotData
      loading.value = false

      // Load PIREPs for stats (all statuses for personal view)
      const { data: pirepData } = await supabase
        .from('pireps')
        .select('*, aircraft(registration)')
        .eq('pilot_id', pilotData.id)
        .order('departure_time', { ascending: true })

      pireps.value = pirepData || []

      if (pirepData && pirepData.length) {
        // Landing stats (from approved only)
        const approved = pirepData.filter(p => p.status === 'approved')
        const landings = approved.filter(p => p.landing_rate != null)
        if (landings.length) {
          const rates = landings.map(p => p.landing_rate)
          const avg = rates.reduce((s, r) => s + r, 0) / rates.length
          avgLanding.value = `${Math.round(avg)} fpm`
          const sorted = [...rates].sort((a, b) => Math.abs(a) - Math.abs(b))
          bestLanding.value = `${sorted[0]} fpm`
          worstLanding.value = `${sorted[sorted.length - 1]} fpm`
        }

        // Totals from approved
        const approvedPireps = pirepData.filter(p => p.status === 'approved')
        totalDistance.value = approvedPireps.reduce((s, p) => s + (p.distance_nm || 0), 0)
        totalFuel.value = approvedPireps.reduce((s, p) => s + (p.fuel_used || 0), 0)

        // Top routes
        const routeMap = {}
        approvedPireps.forEach(p => {
          const key = `${p.departure_icao} → ${p.arrival_icao}`
          routeMap[key] = (routeMap[key] || 0) + 1
        })
        topRoutes.value = Object.entries(routeMap)
          .sort((a, b) => b[1] - a[1])
          .slice(0, 5)
          .map(([route, count]) => ({ route, count }))

        // Aircraft flown
        const acMap = {}
        approvedPireps.forEach(p => {
          const name = p.aircraft?.registration || 'Unknown'
          acMap[name] = (acMap[name] || 0) + 1
        })
        aircraftFlown.value = Object.entries(acMap)
          .sort((a, b) => b[1] - a[1])
          .slice(0, 5)
          .map(([name, count]) => ({ name, count }))

        // Monthly flights chart
        const monthly = {}
        approvedPireps.forEach(p => {
          const d = new Date(p.departure_time)
          const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`
          monthly[key] = (monthly[key] || 0) + 1
        })

        const labels = Object.keys(monthly).sort()
        const data = labels.map(l => monthly[l])

        await nextTick()
        if (chartCanvas.value && labels.length) {
          new Chart(chartCanvas.value, {
            type: 'bar',
            data: {
              labels,
              datasets: [{
                label: 'Flights',
                data,
                backgroundColor: '#FF6600',
                borderRadius: 0
              }]
            },
            options: {
              responsive: true,
              plugins: { legend: { display: false } },
              scales: { y: { beginAtZero: true, ticks: { stepSize: 1 } } }
            }
          })
        }
      }
    }

    const startEdit = () => {
      Object.assign(editForm, {
        first_name: pilot.value.first_name,
        last_name: pilot.value.last_name,
        callsign: pilot.value.callsign,
        hub: pilot.value.hub
      })
      editing.value = true
      editError.value = ''
    }

    const saveEdit = async () => {
      saving.value = true
      editError.value = ''

      const { error } = await supabase
        .from('pilots')
        .update({
          first_name: editForm.first_name,
          last_name: editForm.last_name,
          callsign: editForm.callsign,
          hub: editForm.hub
        })
        .eq('id', pilot.value.id)

      if (error) {
        editError.value = error.message
      } else {
        // Reload the full profile
        editing.value = false
        await loadProfile()
      }
      saving.value = false
    }

    onMounted(loadProfile)

    return {
      pilot, loading, pireps, avgLanding, bestLanding, worstLanding, totalDistance, totalFuel,
      topRoutes, aircraftFlown, chartCanvas, editing, saving, editError, editForm,
      startEdit, saveEdit
    }
  }
}
</script>
