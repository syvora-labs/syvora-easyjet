<template>
  <div>
    <div class="page-header d-flex justify-content-between align-items-start">
      <div>
        <h1>Fleet Management</h1>
        <p>Manage the EasyJet Switzerland Virtual fleet.</p>
      </div>
      <router-link v-if="isAdmin()" to="/fleet/add" class="btn btn-primary">
        + Add Aircraft
      </router-link>
    </div>

    <div class="row g-3 mb-4">
      <div class="col-md-3">
        <div class="card stat-card">
          <div class="stat-value">{{ aircraft.length }}</div>
          <div class="stat-label">Total Aircraft</div>
        </div>
      </div>
      <div class="col-md-3">
        <div class="card stat-card stat-green">
          <div class="stat-value">{{ aircraft.filter(a => a.status === 'active').length }}</div>
          <div class="stat-label">Active</div>
        </div>
      </div>
      <div class="col-md-3">
        <div class="card stat-card stat-blue">
          <div class="stat-value">{{ typeCount }}</div>
          <div class="stat-label">Aircraft Types</div>
        </div>
      </div>
      <div class="col-md-3">
        <div class="card stat-card stat-purple">
          <div class="stat-value">{{ totalSeats }}</div>
          <div class="stat-label">Total Seats</div>
        </div>
      </div>
    </div>

    <div class="card">
      <div class="card-header d-flex align-items-center justify-content-between">
        <span>Aircraft List</span>
        <div class="d-flex gap-2">
          <input
            v-model="search"
            type="text"
            class="form-control form-control-sm"
            placeholder="Search..."
            style="width: 160px;"
          />
          <select v-model="statusFilter" class="form-select form-select-sm" style="width: auto;">
            <option value="">All Status</option>
            <option value="active">Active</option>
            <option value="maintenance">Maintenance</option>
            <option value="retired">Retired</option>
          </select>
        </div>
      </div>
      <div class="card-body p-0">
        <table class="table table-ej mb-0">
          <thead>
            <tr>
              <th>Registration</th>
              <th>Type</th>
              <th>ICAO</th>
              <th>Home Base</th>
              <th>Seats</th>
              <th>Hours</th>
              <th>Cycles</th>
              <th>Status</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="ac in filteredAircraft" :key="ac.id">
              <td class="fw-bold">{{ ac.registration }}</td>
              <td>{{ ac.type }}</td>
              <td><code>{{ ac.icao_type }}</code></td>
              <td>{{ ac.home_base }}</td>
              <td>{{ ac.seat_capacity }}</td>
              <td>{{ Number(ac.total_hours).toFixed(1) }}</td>
              <td>{{ ac.total_cycles }}</td>
              <td>
                <span
                  class="badge badge-status"
                  :class="{
                    'bg-success': ac.status === 'active',
                    'bg-warning text-dark': ac.status === 'maintenance',
                    'bg-secondary': ac.status === 'retired'
                  }"
                >
                  {{ ac.status }}
                </span>
              </td>
              <td>
                <div class="d-flex gap-1">
                  <router-link :to="`/fleet/${ac.id}`" class="btn btn-sm btn-outline-secondary">
                    Details
                  </router-link>
                  <button
                    v-if="isAdmin()"
                    class="btn btn-sm btn-outline-danger"
                    @click="deleteAircraft(ac)"
                  >
                    Delete
                  </button>
                </div>
              </td>
            </tr>
            <tr v-if="!filteredAircraft.length">
              <td colspan="9" class="text-center text-muted py-4">No aircraft found.</td>
            </tr>
          </tbody>
        </table>
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
    const aircraft = ref([])
    const statusFilter = ref('')
    const search = ref('')
    const { isAdmin, fetchPilot } = usePilot()

    const filteredAircraft = computed(() => {
      let list = aircraft.value
      if (statusFilter.value) {
        list = list.filter(a => a.status === statusFilter.value)
      }
      if (search.value) {
        const q = search.value.toLowerCase()
        list = list.filter(a =>
          a.registration.toLowerCase().includes(q) ||
          a.type.toLowerCase().includes(q) ||
          a.icao_type.toLowerCase().includes(q) ||
          a.home_base.toLowerCase().includes(q)
        )
      }
      return list
    })

    const typeCount = computed(() => new Set(aircraft.value.map(a => a.icao_type)).size)
    const totalSeats = computed(() => aircraft.value.reduce((sum, a) => sum + a.seat_capacity, 0))

    const loadAircraft = async () => {
      const { data } = await supabase
        .from('aircraft')
        .select('*')
        .order('registration')
      aircraft.value = data || []
    }

    const deleteAircraft = async (ac) => {
      if (!confirm(`Delete ${ac.registration}? This cannot be undone.`)) return
      const { error } = await supabase.from('aircraft').delete().eq('id', ac.id)
      if (error) {
        alert(error.message)
      } else {
        await loadAircraft()
      }
    }

    onMounted(async () => {
      await fetchPilot()
      await loadAircraft()
    })

    return { aircraft, statusFilter, search, filteredAircraft, typeCount, totalSeats, isAdmin, deleteAircraft }
  }
}
</script>
