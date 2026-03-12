<template>
  <div>
    <div class="page-header d-flex justify-content-between align-items-start">
      <div>
        <h1>My Bookings</h1>
        <p>View and manage your flight bookings.</p>
      </div>
      <router-link to="/bookings/new" class="btn btn-primary">
        + New Booking
      </router-link>
    </div>

    <div class="card">
      <div class="card-header d-flex align-items-center justify-content-between">
        <span>Bookings</span>
        <select v-model="statusFilter" class="form-select form-select-sm" style="width: auto;">
          <option value="">All Status</option>
          <option value="booked">Booked</option>
          <option value="flying">Flying</option>
          <option value="completed">Completed</option>
          <option value="cancelled">Cancelled</option>
        </select>
      </div>
      <div class="card-body p-0">
        <table class="table table-ej mb-0" v-if="filteredBookings.length">
          <thead>
            <tr>
              <th>Flight</th>
              <th>Route</th>
              <th>Aircraft</th>
              <th>Departure</th>
              <th>Status</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="b in filteredBookings" :key="b.id">
              <td class="fw-bold">{{ b.flight_number }}</td>
              <td>{{ b.departure_icao }} → {{ b.arrival_icao }}</td>
              <td>{{ b.aircraft?.registration || '-' }}</td>
              <td class="small">{{ formatDate(b.scheduled_departure) }}</td>
              <td>
                <span
                  class="badge badge-status"
                  :class="{
                    'bg-primary': b.status === 'booked',
                    'bg-info text-dark': b.status === 'flying',
                    'bg-success': b.status === 'completed',
                    'bg-secondary': b.status === 'cancelled'
                  }"
                >
                  {{ b.status }}
                </span>
              </td>
              <td>
                <div class="d-flex gap-1">
                  <router-link
                    v-if="b.status === 'booked'"
                    :to="{ path: '/pireps/file', query: { booking: b.id } }"
                    class="btn btn-sm btn-outline-primary"
                  >
                    File PIREP
                  </router-link>
                  <button
                    v-if="b.status === 'booked'"
                    class="btn btn-sm btn-outline-warning"
                    @click="markFlying(b.id)"
                  >
                    Start Flight
                  </button>
                  <button
                    v-if="b.status === 'booked' || b.status === 'flying'"
                    class="btn btn-sm btn-outline-danger"
                    @click="cancelBooking(b.id)"
                  >
                    Cancel
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
        <div v-else class="p-4 text-center text-muted">
          No bookings found. <router-link to="/bookings/new">Create your first booking.</router-link>
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
    const bookings = ref([])
    const statusFilter = ref('')
    const { pilot, fetchPilot } = usePilot()

    const filteredBookings = computed(() => {
      if (!statusFilter.value) return bookings.value
      return bookings.value.filter(b => b.status === statusFilter.value)
    })

    const formatDate = (d) => {
      return new Date(d).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' })
    }

    const loadBookings = async () => {
      const p = await fetchPilot()
      if (!p) return

      const { data } = await supabase
        .from('bookings')
        .select('*, aircraft(registration)')
        .eq('pilot_id', p.id)
        .order('scheduled_departure', { ascending: false })
      bookings.value = data || []
    }

    const cancelBooking = async (id) => {
      if (!confirm('Cancel this booking?')) return
      await supabase.from('bookings').update({ status: 'cancelled' }).eq('id', id)
      await loadBookings()
    }

    const markFlying = async (id) => {
      await supabase.from('bookings').update({ status: 'flying' }).eq('id', id)
      await loadBookings()
    }

    onMounted(loadBookings)

    return { bookings, statusFilter, filteredBookings, formatDate, cancelBooking, markFlying }
  }
}
</script>
