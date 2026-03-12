<template>
  <div>
    <div class="page-header">
      <h1>Manage Pilots</h1>
      <p>View and manage all registered pilots.</p>
    </div>

    <div class="row g-3 mb-4">
      <div class="col-md-3">
        <div class="card stat-card">
          <div class="stat-value">{{ pilots.length }}</div>
          <div class="stat-label">Total Pilots</div>
        </div>
      </div>
      <div class="col-md-3">
        <div class="card stat-card stat-green">
          <div class="stat-value">{{ totalFlights }}</div>
          <div class="stat-label">Combined Flights</div>
        </div>
      </div>
      <div class="col-md-3">
        <div class="card stat-card stat-blue">
          <div class="stat-value">{{ totalHours }}h</div>
          <div class="stat-label">Combined Hours</div>
        </div>
      </div>
    </div>

    <div class="card">
      <div class="card-header d-flex align-items-center justify-content-between">
        <span>All Pilots</span>
        <input v-model="search" type="text" class="form-control form-control-sm" placeholder="Search..." style="width: 200px;" />
      </div>
      <div class="card-body p-0">
        <table class="table table-ej mb-0">
          <thead>
            <tr>
              <th>Callsign</th>
              <th>Name</th>
              <th>Rank</th>
              <th>Hub</th>
              <th>Flights</th>
              <th>Hours</th>
              <th>Joined</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="p in filteredPilots" :key="p.id">
              <td class="fw-bold">{{ p.callsign }}</td>
              <td>{{ p.first_name }} {{ p.last_name }}</td>
              <td>
                <select
                  :value="p.rank"
                  class="form-select form-select-sm"
                  style="width: auto;"
                  @change="updateRank(p.id, $event.target.value)"
                >
                  <option value="Second Officer">Second Officer</option>
                  <option value="First Officer">First Officer</option>
                  <option value="Senior First Officer">Senior First Officer</option>
                  <option value="Captain">Captain</option>
                  <option value="Admin">Admin</option>
                </select>
              </td>
              <td>{{ p.hub }}</td>
              <td>{{ p.total_flights }}</td>
              <td>{{ Number(p.total_hours).toFixed(1) }}</td>
              <td class="small text-muted">{{ new Date(p.joined_at).toLocaleDateString() }}</td>
              <td>
                <button
                  class="btn btn-sm btn-outline-danger"
                  @click="deletePilot(p)"
                  :disabled="p.rank === 'Admin'"
                >
                  Delete
                </button>
              </td>
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

export default {
  setup() {
    const pilots = ref([])
    const search = ref('')

    const filteredPilots = computed(() => {
      if (!search.value) return pilots.value
      const q = search.value.toLowerCase()
      return pilots.value.filter(p =>
        p.callsign.toLowerCase().includes(q) ||
        p.first_name.toLowerCase().includes(q) ||
        p.last_name.toLowerCase().includes(q) ||
        p.hub.toLowerCase().includes(q)
      )
    })

    const totalFlights = computed(() => pilots.value.reduce((s, p) => s + p.total_flights, 0))
    const totalHours = computed(() => pilots.value.reduce((s, p) => s + Number(p.total_hours), 0).toFixed(1))

    const loadPilots = async () => {
      const { data } = await supabase
        .from('pilots')
        .select('*')
        .order('callsign')
      pilots.value = data || []
    }

    const updateRank = async (id, rank) => {
      const { error } = await supabase.from('pilots').update({ rank }).eq('id', id)
      if (error) {
        alert(error.message)
        await loadPilots()
      } else {
        const p = pilots.value.find(p => p.id === id)
        if (p) p.rank = rank
      }
    }

    const deletePilot = async (p) => {
      if (!confirm(`Delete pilot ${p.callsign} (${p.first_name} ${p.last_name})? This cannot be undone.`)) return
      const { error } = await supabase.from('pilots').delete().eq('id', p.id)
      if (error) {
        alert(error.message)
      } else {
        await loadPilots()
      }
    }

    onMounted(loadPilots)

    return { pilots, search, filteredPilots, totalFlights, totalHours, updateRank, deletePilot }
  }
}
</script>
