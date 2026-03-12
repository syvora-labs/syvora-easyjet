<template>
  <div>
    <div class="page-header">
      <h1>Dashboard</h1>
      <p>Welcome back, {{ pilot?.first_name }}.</p>
    </div>

    <div class="row g-3 mb-4">
      <div class="col-md-3">
        <div class="card stat-card">
          <div class="stat-value">{{ pilot?.total_flights || 0 }}</div>
          <div class="stat-label">Total Flights</div>
        </div>
      </div>
      <div class="col-md-3">
        <div class="card stat-card stat-green">
          <div class="stat-value">{{ formatHours(pilot?.total_hours) }}</div>
          <div class="stat-label">Flight Hours</div>
        </div>
      </div>
      <div class="col-md-3">
        <div class="card stat-card stat-blue">
          <div class="stat-value">{{ activeBookings }}</div>
          <div class="stat-label">Active Bookings</div>
        </div>
      </div>
      <div class="col-md-3">
        <div class="card stat-card stat-purple">
          <div class="stat-value">{{ pilot?.rank || '-' }}</div>
          <div class="stat-label">Current Rank</div>
        </div>
      </div>
    </div>

    <!-- Admin alert for pending PIREPs -->
    <div v-if="isAdmin() && pendingPireps > 0" class="alert alert-warning d-flex align-items-center justify-content-between mb-4">
      <span><strong>{{ pendingPireps }}</strong> PIREP(s) awaiting review.</span>
      <router-link to="/admin/pireps" class="btn btn-sm btn-warning">Review Now</router-link>
    </div>

    <div class="row g-3">
      <div class="col-md-8">
        <div class="card">
          <div class="card-header d-flex align-items-center justify-content-between">
            <span>Recent Flights</span>
            <router-link to="/pireps" class="btn btn-sm btn-outline-primary">View All</router-link>
          </div>
          <div class="card-body p-0">
            <table class="table table-ej mb-0" v-if="recentPireps.length">
              <thead>
                <tr>
                  <th>Flight</th>
                  <th>Route</th>
                  <th>Aircraft</th>
                  <th>Block Time</th>
                  <th>Landing</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="pirep in recentPireps" :key="pirep.id">
                  <td class="fw-semibold">{{ pirep.flight_number }}</td>
                  <td>{{ pirep.departure_icao }} → {{ pirep.arrival_icao }}</td>
                  <td>{{ pirep.aircraft?.registration }}</td>
                  <td>{{ pirep.block_time }}</td>
                  <td>
                    <span :class="landingClass(pirep.landing_rate)">
                      {{ pirep.landing_rate ? `${pirep.landing_rate} fpm` : '-' }}
                    </span>
                  </td>
                  <td>
                    <span
                      class="badge badge-status"
                      :class="{
                        'bg-success': pirep.status === 'approved',
                        'bg-warning text-dark': pirep.status === 'pending',
                        'bg-danger': pirep.status === 'rejected'
                      }"
                    >
                      {{ pirep.status }}
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
            <div v-else class="p-4 text-center text-muted">
              No flights yet. <router-link to="/bookings/new">Book your first flight!</router-link>
            </div>
          </div>
        </div>
      </div>

      <div class="col-md-4">
        <div class="card mb-3">
          <div class="card-header d-flex align-items-center justify-content-between">
            <span>Upcoming Bookings</span>
            <router-link to="/bookings/new" class="btn btn-sm btn-outline-primary">New</router-link>
          </div>
          <div class="card-body" v-if="upcomingBookings.length">
            <div
              v-for="booking in upcomingBookings"
              :key="booking.id"
              class="d-flex justify-content-between align-items-center mb-2 pb-2 border-bottom"
            >
              <div>
                <div class="fw-semibold small">{{ booking.flight_number }}</div>
                <div class="text-muted small">{{ booking.departure_icao }} → {{ booking.arrival_icao }}</div>
                <div class="text-muted small">{{ booking.aircraft?.registration }} &middot; {{ formatDate(booking.scheduled_departure) }}</div>
              </div>
              <div class="d-flex flex-column gap-1">
                <span class="badge bg-primary badge-status">{{ booking.status }}</span>
                <router-link
                  v-if="booking.status === 'booked'"
                  :to="{ path: '/pireps/file', query: { booking: booking.id } }"
                  class="btn btn-sm btn-outline-primary"
                >
                  File
                </router-link>
              </div>
            </div>
          </div>
          <div class="card-body text-center text-muted" v-else>
            No upcoming bookings.
          </div>
        </div>

        <div class="card mb-3">
          <div class="card-header">Fleet Status</div>
          <div class="card-body">
            <div class="d-flex justify-content-between mb-2">
              <span class="text-muted small">Active Aircraft</span>
              <span class="fw-semibold">{{ fleetStats.active }}</span>
            </div>
            <div class="d-flex justify-content-between mb-2">
              <span class="text-muted small">In Maintenance</span>
              <span class="fw-semibold">{{ fleetStats.maintenance }}</span>
            </div>
            <div class="d-flex justify-content-between">
              <span class="text-muted small">Total Fleet</span>
              <span class="fw-semibold">{{ fleetStats.total }}</span>
            </div>
          </div>
        </div>

        <div class="card">
          <div class="card-header">Quick Actions</div>
          <div class="card-body d-grid gap-2">
            <router-link to="/bookings/new" class="btn btn-outline-primary btn-sm">New Booking</router-link>
            <router-link to="/pireps/file" class="btn btn-outline-primary btn-sm">File PIREP</router-link>
            <router-link to="/routes" class="btn btn-outline-secondary btn-sm">Browse Routes</router-link>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'
import { supabase } from '../lib/supabase'
import { usePilot } from '../lib/usePilot'

export default {
  setup() {
    const { pilot, fetchPilot, isAdmin } = usePilot()
    const recentPireps = ref([])
    const upcomingBookings = ref([])
    const activeBookings = ref(0)
    const pendingPireps = ref(0)
    const fleetStats = ref({ active: 0, maintenance: 0, total: 0 })

    const formatHours = (h) => {
      if (!h) return '0h'
      return `${Number(h).toFixed(1)}h`
    }

    const formatDate = (d) => {
      return new Date(d).toLocaleString(undefined, { dateStyle: 'short', timeStyle: 'short' })
    }

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

      // Recent PIREPs
      const { data: pireps } = await supabase
        .from('pireps')
        .select('*, aircraft(registration)')
        .eq('pilot_id', p.id)
        .order('created_at', { ascending: false })
        .limit(5)
      recentPireps.value = pireps || []

      // Upcoming bookings
      const { data: bookings } = await supabase
        .from('bookings')
        .select('*, aircraft(registration)')
        .eq('pilot_id', p.id)
        .in('status', ['booked', 'flying'])
        .order('scheduled_departure', { ascending: true })
        .limit(5)
      upcomingBookings.value = bookings || []
      activeBookings.value = bookings?.length || 0

      // Fleet stats
      const { data: aircraft } = await supabase.from('aircraft').select('status')
      if (aircraft) {
        fleetStats.value = {
          active: aircraft.filter(a => a.status === 'active').length,
          maintenance: aircraft.filter(a => a.status === 'maintenance').length,
          total: aircraft.length
        }
      }

      // Pending PIREPs count (admin only)
      if (isAdmin()) {
        const { count } = await supabase
          .from('pireps')
          .select('*', { count: 'exact', head: true })
          .eq('status', 'pending')
        pendingPireps.value = count || 0
      }
    })

    return {
      pilot, recentPireps, upcomingBookings, activeBookings, pendingPireps,
      fleetStats, isAdmin, formatHours, formatDate, landingClass
    }
  }
}
</script>
