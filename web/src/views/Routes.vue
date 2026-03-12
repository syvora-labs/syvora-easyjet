<template>
  <div>
    <div class="page-header d-flex justify-content-between align-items-start">
      <div>
        <h1>Route Network</h1>
        <p>EasyJet Switzerland Virtual route map.</p>
      </div>
      <router-link v-if="isAdmin()" to="/routes/add" class="btn btn-primary">
        + Add Route
      </router-link>
    </div>

    <div class="row g-3 mb-4">
      <div class="col-md-3">
        <div class="card stat-card">
          <div class="stat-value">{{ routes.length }}</div>
          <div class="stat-label">Total Routes</div>
        </div>
      </div>
      <div class="col-md-3">
        <div class="card stat-card stat-green">
          <div class="stat-value">{{ destinations }}</div>
          <div class="stat-label">Destinations</div>
        </div>
      </div>
      <div class="col-md-3">
        <div class="card stat-card stat-blue">
          <div class="stat-value">{{ hubs }}</div>
          <div class="stat-label">Hubs</div>
        </div>
      </div>
    </div>

    <div class="card">
      <div class="card-header d-flex align-items-center justify-content-between">
        <span>All Routes</span>
        <div class="d-flex gap-2">
          <input
            v-model="search"
            type="text"
            class="form-control form-control-sm"
            placeholder="Search..."
            style="width: 160px;"
          />
          <select v-model="hubFilter" class="form-select form-select-sm" style="width: auto;">
            <option value="">All Hubs</option>
            <option value="LSGG">LSGG - Geneva</option>
            <option value="LSZH">LSZH - Zurich</option>
            <option value="LSBS">LSBS - Basel</option>
          </select>
        </div>
      </div>
      <div class="card-body p-0">
        <table class="table table-ej mb-0">
          <thead>
            <tr>
              <th>Flight #</th>
              <th>From</th>
              <th>To</th>
              <th>Distance</th>
              <th>Est. Time</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="r in filteredRoutes" :key="r.id">
              <td class="fw-bold">{{ r.flight_number }}</td>
              <td>{{ r.departure_name }} <span class="text-muted">({{ r.departure_icao }})</span></td>
              <td>{{ r.arrival_name }} <span class="text-muted">({{ r.arrival_icao }})</span></td>
              <td>{{ r.distance_nm }} NM</td>
              <td>{{ r.estimated_time }}</td>
              <td>
                <div class="d-flex gap-1">
                  <router-link
                    :to="{ path: '/bookings/new', query: { route: r.id } }"
                    class="btn btn-sm btn-outline-primary"
                  >
                    Book
                  </router-link>
                  <button
                    v-if="isAdmin()"
                    class="btn btn-sm btn-outline-secondary"
                    @click="editRoute(r)"
                  >
                    Edit
                  </button>
                  <button
                    v-if="isAdmin()"
                    class="btn btn-sm btn-outline-danger"
                    @click="deleteRoute(r)"
                  >
                    Delete
                  </button>
                </div>
              </td>
            </tr>
            <tr v-if="!filteredRoutes.length">
              <td colspan="6" class="text-center text-muted py-4">No routes found.</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Edit Route Modal -->
    <div v-if="editingRoute" class="modal d-block" tabindex="-1" style="background: rgba(0,0,0,0.5);">
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">Edit Route</h5>
            <button type="button" class="btn-close" @click="editingRoute = null"></button>
          </div>
          <div class="modal-body">
            <div v-if="editRouteError" class="alert alert-danger small py-2">{{ editRouteError }}</div>
            <div class="mb-3">
              <label class="form-label fw-semibold">Flight Number</label>
              <input v-model="editRouteForm.flight_number" type="text" class="form-control" />
            </div>
            <div class="row mb-3">
              <div class="col">
                <label class="form-label fw-semibold">Departure ICAO</label>
                <input v-model="editRouteForm.departure_icao" type="text" class="form-control" maxlength="4" />
              </div>
              <div class="col">
                <label class="form-label fw-semibold">Departure Name</label>
                <input v-model="editRouteForm.departure_name" type="text" class="form-control" />
              </div>
            </div>
            <div class="row mb-3">
              <div class="col">
                <label class="form-label fw-semibold">Arrival ICAO</label>
                <input v-model="editRouteForm.arrival_icao" type="text" class="form-control" maxlength="4" />
              </div>
              <div class="col">
                <label class="form-label fw-semibold">Arrival Name</label>
                <input v-model="editRouteForm.arrival_name" type="text" class="form-control" />
              </div>
            </div>
            <div class="row mb-3">
              <div class="col">
                <label class="form-label fw-semibold">Distance (NM)</label>
                <input v-model.number="editRouteForm.distance_nm" type="number" class="form-control" />
              </div>
              <div class="col">
                <label class="form-label fw-semibold">Est. Time (HH:MM:SS)</label>
                <input v-model="editRouteForm.estimated_time" type="text" class="form-control" placeholder="1:30:00" />
              </div>
            </div>
            <div class="form-check">
              <input v-model="editRouteForm.is_active" type="checkbox" class="form-check-input" id="routeActive" />
              <label class="form-check-label" for="routeActive">Active</label>
            </div>
          </div>
          <div class="modal-footer">
            <button class="btn btn-outline-secondary" @click="editingRoute = null">Cancel</button>
            <button class="btn btn-primary" :disabled="editRouteSaving" @click="saveRouteEdit">
              {{ editRouteSaving ? 'Saving...' : 'Save' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, reactive, computed, onMounted } from 'vue'
import { supabase } from '../lib/supabase'
import { usePilot } from '../lib/usePilot'

export default {
  setup() {
    const routes = ref([])
    const hubFilter = ref('')
    const search = ref('')
    const { isAdmin, fetchPilot } = usePilot()

    const editingRoute = ref(null)
    const editRouteForm = reactive({})
    const editRouteSaving = ref(false)
    const editRouteError = ref('')

    const filteredRoutes = computed(() => {
      let list = routes.value
      if (hubFilter.value) {
        list = list.filter(r => r.departure_icao === hubFilter.value)
      }
      if (search.value) {
        const q = search.value.toLowerCase()
        list = list.filter(r =>
          r.flight_number.toLowerCase().includes(q) ||
          r.departure_name.toLowerCase().includes(q) ||
          r.arrival_name.toLowerCase().includes(q) ||
          r.departure_icao.toLowerCase().includes(q) ||
          r.arrival_icao.toLowerCase().includes(q)
        )
      }
      return list
    })

    const destinations = computed(() => new Set(routes.value.map(r => r.arrival_icao)).size)
    const hubs = computed(() => new Set(routes.value.map(r => r.departure_icao)).size)

    const loadRoutes = async () => {
      const { data } = await supabase
        .from('routes')
        .select('*')
        .order('flight_number')
      routes.value = data || []
    }

    const editRoute = (r) => {
      editingRoute.value = r
      editRouteError.value = ''
      Object.assign(editRouteForm, {
        flight_number: r.flight_number,
        departure_icao: r.departure_icao,
        departure_name: r.departure_name,
        arrival_icao: r.arrival_icao,
        arrival_name: r.arrival_name,
        distance_nm: r.distance_nm,
        estimated_time: r.estimated_time,
        is_active: r.is_active
      })
    }

    const saveRouteEdit = async () => {
      editRouteSaving.value = true
      editRouteError.value = ''

      const { error } = await supabase
        .from('routes')
        .update({ ...editRouteForm })
        .eq('id', editingRoute.value.id)

      if (error) {
        editRouteError.value = error.message
      } else {
        editingRoute.value = null
        await loadRoutes()
      }
      editRouteSaving.value = false
    }

    const deleteRoute = async (r) => {
      if (!confirm(`Delete route ${r.flight_number}?`)) return
      const { error } = await supabase.from('routes').delete().eq('id', r.id)
      if (error) {
        alert(error.message)
      } else {
        await loadRoutes()
      }
    }

    onMounted(async () => {
      await fetchPilot()
      await loadRoutes()
    })

    return {
      routes, hubFilter, search, filteredRoutes, destinations, hubs, isAdmin,
      editingRoute, editRouteForm, editRouteSaving, editRouteError,
      editRoute, saveRouteEdit, deleteRoute
    }
  }
}
</script>
