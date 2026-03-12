<template>
  <div>
    <div class="page-header d-flex justify-content-between align-items-start">
      <div>
        <h1>My PIREPs</h1>
        <p>Pilot reports for completed flights.</p>
      </div>
      <router-link to="/pireps/file" class="btn btn-primary">
        + File PIREP
      </router-link>
    </div>

    <div class="card">
      <div class="card-header d-flex align-items-center justify-content-between">
        <span>Flight Reports</span>
        <select v-model="statusFilter" class="form-select form-select-sm" style="width: auto;">
          <option value="">All Status</option>
          <option value="pending">Pending</option>
          <option value="approved">Approved</option>
          <option value="rejected">Rejected</option>
        </select>
      </div>
      <div class="card-body p-0">
        <table class="table table-ej mb-0" v-if="filteredPireps.length">
          <thead>
            <tr>
              <th>Flight</th>
              <th>Route</th>
              <th>Aircraft</th>
              <th>Block Time</th>
              <th>Distance</th>
              <th>Fuel</th>
              <th>Pax</th>
              <th>Landing Rate</th>
              <th>Status</th>
              <th>Date</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="p in filteredPireps" :key="p.id">
              <td class="fw-bold">{{ p.flight_number }}</td>
              <td>{{ p.departure_icao }} → {{ p.arrival_icao }}</td>
              <td>{{ p.aircraft?.registration }}</td>
              <td>{{ p.block_time }}</td>
              <td>{{ p.distance_nm }} NM</td>
              <td>{{ p.fuel_used ? `${p.fuel_used} lbs` : '-' }}</td>
              <td>{{ p.passengers || '-' }}</td>
              <td>
                <span :class="landingClass(p.landing_rate)">
                  {{ p.landing_rate ? `${p.landing_rate} fpm` : '-' }}
                </span>
              </td>
              <td>
                <span
                  class="badge badge-status"
                  :class="{
                    'bg-success': p.status === 'approved',
                    'bg-warning text-dark': p.status === 'pending',
                    'bg-danger': p.status === 'rejected'
                  }"
                >
                  {{ p.status }}
                </span>
              </td>
              <td class="small text-muted">{{ new Date(p.departure_time).toLocaleDateString() }}</td>
            </tr>
          </tbody>
        </table>
        <div v-else class="p-4 text-center text-muted">
          No PIREPs filed yet. <router-link to="/pireps/file">File your first PIREP.</router-link>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../lib/supabase'
import { usePilot } from '../lib/usePilot'

export default {
  setup() {
    const pireps = ref([])
    const statusFilter = ref('')
    const { fetchPilot } = usePilot()

    const filteredPireps = computed(() => {
      if (!statusFilter.value) return pireps.value
      return pireps.value.filter(p => p.status === statusFilter.value)
    })

    const landingClass = (rate) => {
      if (!rate) return ''
      const abs = Math.abs(rate)
      if (abs <= 100) return 'text-success fw-bold'
      if (abs <= 200) return 'text-primary'
      if (abs <= 400) return 'text-warning'
      return 'text-danger'
    }

    onMounted(async () => {
      const p = await fetchPilot()
      if (!p) return

      const { data } = await supabase
        .from('pireps')
        .select('*, aircraft(registration)')
        .eq('pilot_id', p.id)
        .order('departure_time', { ascending: false })
      pireps.value = data || []
    })

    return { pireps, statusFilter, filteredPireps, landingClass }
  }
}
</script>
