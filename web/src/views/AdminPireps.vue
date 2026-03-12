<template>
  <div>
    <div class="page-header">
      <h1>Review PIREPs</h1>
      <p>Approve or reject pilot flight reports.</p>
    </div>

    <div class="row g-3 mb-4">
      <div class="col-md-3">
        <div class="card stat-card">
          <div class="stat-value">{{ pendingCount }}</div>
          <div class="stat-label">Pending Review</div>
        </div>
      </div>
      <div class="col-md-3">
        <div class="card stat-card stat-green">
          <div class="stat-value">{{ approvedCount }}</div>
          <div class="stat-label">Approved</div>
        </div>
      </div>
      <div class="col-md-3">
        <div class="card stat-card stat-purple">
          <div class="stat-value">{{ rejectedCount }}</div>
          <div class="stat-label">Rejected</div>
        </div>
      </div>
    </div>

    <div class="card">
      <div class="card-header d-flex align-items-center justify-content-between">
        <span>All PIREPs</span>
        <select v-model="statusFilter" class="form-select form-select-sm" style="width: auto;">
          <option value="pending">Pending</option>
          <option value="">All</option>
          <option value="approved">Approved</option>
          <option value="rejected">Rejected</option>
        </select>
      </div>
      <div class="card-body p-0">
        <table class="table table-ej mb-0" v-if="filteredPireps.length">
          <thead>
            <tr>
              <th>Pilot</th>
              <th>Flight</th>
              <th>Route</th>
              <th>Aircraft</th>
              <th>Block Time</th>
              <th>Distance</th>
              <th>Landing</th>
              <th>Date</th>
              <th>Status</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="p in filteredPireps" :key="p.id">
              <td>
                <span class="fw-semibold">{{ p.pilot?.callsign }}</span>
                <div class="text-muted small">{{ p.pilot?.first_name }} {{ p.pilot?.last_name }}</div>
              </td>
              <td class="fw-bold">{{ p.flight_number }}</td>
              <td>{{ p.departure_icao }} → {{ p.arrival_icao }}</td>
              <td>{{ p.aircraft?.registration }}</td>
              <td>{{ p.block_time }}</td>
              <td>{{ p.distance_nm }} NM</td>
              <td>
                <span :class="landingClass(p.landing_rate)">
                  {{ p.landing_rate ? `${p.landing_rate} fpm` : '-' }}
                </span>
              </td>
              <td class="small text-muted">{{ formatDate(p.departure_time) }}</td>
              <td>
                <span class="badge badge-status" :class="statusBadge(p.status)">
                  {{ p.status }}
                </span>
              </td>
              <td>
                <div class="d-flex gap-1" v-if="p.status === 'pending'">
                  <button class="btn btn-sm btn-success" @click="updateStatus(p.id, 'approved')">
                    Approve
                  </button>
                  <button class="btn btn-sm btn-danger" @click="updateStatus(p.id, 'rejected')">
                    Reject
                  </button>
                </div>
                <div class="d-flex gap-1" v-else>
                  <button
                    v-if="p.status === 'rejected'"
                    class="btn btn-sm btn-outline-success"
                    @click="updateStatus(p.id, 'approved')"
                  >
                    Approve
                  </button>
                  <button
                    v-if="p.status === 'approved'"
                    class="btn btn-sm btn-outline-warning"
                    @click="updateStatus(p.id, 'pending')"
                  >
                    Revert
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
        <div v-else class="p-4 text-center text-muted">
          No PIREPs matching filter.
        </div>
      </div>
    </div>

    <!-- PIREP Detail Modal -->
    <div v-if="selectedPirep" class="modal d-block" tabindex="-1" style="background: rgba(0,0,0,0.5);">
      <div class="modal-dialog modal-lg">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">PIREP Details — {{ selectedPirep.flight_number }}</h5>
            <button type="button" class="btn-close" @click="selectedPirep = null"></button>
          </div>
          <div class="modal-body">
            <pre class="small">{{ JSON.stringify(selectedPirep, null, 2) }}</pre>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../lib/supabase'

export default {
  setup() {
    const pireps = ref([])
    const statusFilter = ref('pending')
    const selectedPirep = ref(null)

    const filteredPireps = computed(() => {
      if (!statusFilter.value) return pireps.value
      return pireps.value.filter(p => p.status === statusFilter.value)
    })

    const pendingCount = computed(() => pireps.value.filter(p => p.status === 'pending').length)
    const approvedCount = computed(() => pireps.value.filter(p => p.status === 'approved').length)
    const rejectedCount = computed(() => pireps.value.filter(p => p.status === 'rejected').length)

    const formatDate = (d) => new Date(d).toLocaleDateString()

    const landingClass = (rate) => {
      if (!rate) return ''
      const abs = Math.abs(rate)
      if (abs <= 100) return 'text-success fw-bold'
      if (abs <= 200) return 'text-primary'
      if (abs <= 400) return 'text-warning'
      return 'text-danger'
    }

    const statusBadge = (s) => ({
      'bg-success': s === 'approved',
      'bg-warning text-dark': s === 'pending',
      'bg-danger': s === 'rejected'
    })

    const loadPireps = async () => {
      const { data } = await supabase
        .from('pireps')
        .select('*, pilot:pilots(callsign, first_name, last_name), aircraft(registration)')
        .order('created_at', { ascending: false })
      pireps.value = data || []
    }

    const updateStatus = async (id, status) => {
      const { error } = await supabase.from('pireps').update({ status }).eq('id', id)
      if (error) {
        alert(error.message)
      } else {
        await loadPireps()
      }
    }

    onMounted(loadPireps)

    return {
      pireps, statusFilter, filteredPireps, selectedPirep,
      pendingCount, approvedCount, rejectedCount,
      formatDate, landingClass, statusBadge, updateStatus
    }
  }
}
</script>
