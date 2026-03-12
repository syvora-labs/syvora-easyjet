<template>
  <div v-if="aircraft">
    <div class="page-header d-flex justify-content-between align-items-start">
      <div>
        <div class="d-flex align-items-center gap-2 mb-1">
          <router-link to="/fleet" class="text-muted text-decoration-none small">Fleet</router-link>
          <span class="text-muted small">/</span>
          <span class="small">{{ aircraft.registration }}</span>
        </div>
        <h1>{{ aircraft.registration }} — {{ aircraft.type }}</h1>
      </div>
      <button v-if="isAdmin() && !editing" class="btn btn-outline-primary" @click="startEdit">
        Edit Aircraft
      </button>
    </div>

    <div class="row g-3 mb-4">
      <div class="col-md-3">
        <div class="card stat-card">
          <div class="stat-value">{{ Number(aircraft.total_hours).toFixed(1) }}h</div>
          <div class="stat-label">Total Hours</div>
        </div>
      </div>
      <div class="col-md-3">
        <div class="card stat-card stat-green">
          <div class="stat-value">{{ aircraft.total_cycles }}</div>
          <div class="stat-label">Total Cycles</div>
        </div>
      </div>
      <div class="col-md-3">
        <div class="card stat-card stat-blue">
          <div class="stat-value">{{ aircraft.seat_capacity }}</div>
          <div class="stat-label">Seat Capacity</div>
        </div>
      </div>
      <div class="col-md-3">
        <div class="card stat-card stat-purple">
          <div class="stat-value">{{ aircraft.home_base }}</div>
          <div class="stat-label">Home Base</div>
        </div>
      </div>
    </div>

    <div class="row g-3">
      <div class="col-md-6">
        <div class="card">
          <div class="card-header">Aircraft Details</div>
          <div class="card-body" v-if="!editing">
            <table class="table table-sm mb-0">
              <tr><td class="text-muted">Registration</td><td class="fw-semibold">{{ aircraft.registration }}</td></tr>
              <tr><td class="text-muted">Type</td><td>{{ aircraft.type }}</td></tr>
              <tr><td class="text-muted">ICAO Type</td><td><code>{{ aircraft.icao_type }}</code></td></tr>
              <tr><td class="text-muted">Livery</td><td>{{ aircraft.livery }}</td></tr>
              <tr><td class="text-muted">Home Base</td><td>{{ aircraft.home_base }}</td></tr>
              <tr><td class="text-muted">Seats</td><td>{{ aircraft.seat_capacity }}</td></tr>
              <tr>
                <td class="text-muted">Status</td>
                <td>
                  <span class="badge badge-status" :class="statusClass(aircraft.status)">
                    {{ aircraft.status }}
                  </span>
                </td>
              </tr>
            </table>
          </div>

          <div class="card-body" v-else>
            <div v-if="editError" class="alert alert-danger small py-2">{{ editError }}</div>
            <div class="mb-3">
              <label class="form-label small fw-semibold">Registration</label>
              <input v-model="editForm.registration" type="text" class="form-control" />
            </div>
            <div class="mb-3">
              <label class="form-label small fw-semibold">Type</label>
              <input v-model="editForm.type" type="text" class="form-control" />
            </div>
            <div class="mb-3">
              <label class="form-label small fw-semibold">ICAO Type</label>
              <input v-model="editForm.icao_type" type="text" class="form-control" />
            </div>
            <div class="mb-3">
              <label class="form-label small fw-semibold">Livery</label>
              <input v-model="editForm.livery" type="text" class="form-control" />
            </div>
            <div class="row mb-3">
              <div class="col">
                <label class="form-label small fw-semibold">Home Base</label>
                <input v-model="editForm.home_base" type="text" class="form-control" />
              </div>
              <div class="col">
                <label class="form-label small fw-semibold">Seat Capacity</label>
                <input v-model.number="editForm.seat_capacity" type="number" class="form-control" />
              </div>
            </div>
            <div class="mb-3">
              <label class="form-label small fw-semibold">Status</label>
              <select v-model="editForm.status" class="form-select">
                <option value="active">Active</option>
                <option value="maintenance">Maintenance</option>
                <option value="retired">Retired</option>
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
      </div>

      <div class="col-md-6">
        <div class="card">
          <div class="card-header">Recent Flights on this Aircraft</div>
          <div class="card-body p-0">
            <table class="table table-ej mb-0" v-if="pireps.length">
              <thead>
                <tr>
                  <th>Flight</th>
                  <th>Route</th>
                  <th>Pilot</th>
                  <th>Date</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="p in pireps" :key="p.id">
                  <td class="fw-semibold">{{ p.flight_number }}</td>
                  <td>{{ p.departure_icao }} → {{ p.arrival_icao }}</td>
                  <td>{{ p.pilot?.callsign }}</td>
                  <td class="small text-muted">{{ new Date(p.departure_time).toLocaleDateString() }}</td>
                </tr>
              </tbody>
            </table>
            <div v-else class="p-3 text-center text-muted small">No flights recorded yet.</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, reactive, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { supabase } from '../lib/supabase'
import { usePilot } from '../lib/usePilot'

export default {
  setup() {
    const route = useRoute()
    const aircraft = ref(null)
    const pireps = ref([])
    const editing = ref(false)
    const saving = ref(false)
    const editError = ref('')
    const editForm = reactive({})
    const { isAdmin, fetchPilot } = usePilot()

    const statusClass = (s) => ({
      'bg-success': s === 'active',
      'bg-warning text-dark': s === 'maintenance',
      'bg-secondary': s === 'retired'
    })

    const startEdit = () => {
      Object.assign(editForm, {
        registration: aircraft.value.registration,
        type: aircraft.value.type,
        icao_type: aircraft.value.icao_type,
        livery: aircraft.value.livery,
        home_base: aircraft.value.home_base,
        seat_capacity: aircraft.value.seat_capacity,
        status: aircraft.value.status
      })
      editing.value = true
      editError.value = ''
    }

    const saveEdit = async () => {
      saving.value = true
      editError.value = ''
      const { data, error } = await supabase
        .from('aircraft')
        .update({
          registration: editForm.registration,
          type: editForm.type,
          icao_type: editForm.icao_type,
          livery: editForm.livery,
          home_base: editForm.home_base,
          seat_capacity: editForm.seat_capacity,
          status: editForm.status
        })
        .eq('id', route.params.id)
        .select()
        .single()

      if (error) {
        editError.value = error.message
      } else {
        aircraft.value = data
        editing.value = false
      }
      saving.value = false
    }

    onMounted(async () => {
      await fetchPilot()

      const { data } = await supabase
        .from('aircraft')
        .select('*')
        .eq('id', route.params.id)
        .single()
      aircraft.value = data

      const { data: pirepData } = await supabase
        .from('pireps')
        .select('*, pilot:pilots(callsign)')
        .eq('aircraft_id', route.params.id)
        .order('departure_time', { ascending: false })
        .limit(10)
      pireps.value = pirepData || []
    })

    return { aircraft, pireps, editing, saving, editError, editForm, isAdmin, statusClass, startEdit, saveEdit }
  }
}
</script>
