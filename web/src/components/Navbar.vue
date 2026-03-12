<template>
  <nav class="navbar navbar-expand-lg navbar-dark navbar-ej">
    <div class="container-fluid">
      <router-link class="navbar-brand" to="/" @click="closeAll">
        easy<span>Jet</span> Switzerland Virtual
      </router-link>

      <button
        class="navbar-toggler border-0"
        type="button"
        @click="mobileOpen = !mobileOpen"
      >
        <span class="navbar-toggler-icon"></span>
      </button>

      <div class="navbar-collapse" :class="{ collapse: !mobileOpen, show: mobileOpen }">
        <ul class="navbar-nav me-auto">
          <li class="nav-item">
            <router-link class="nav-link" active-class="active" to="/" exact @click="closeAll">
              Dashboard
            </router-link>
          </li>

          <li class="nav-item dropdown" :class="{ show: openDropdown === 'fleet' }">
            <a
              class="nav-link dropdown-toggle"
              href="#"
              @click.prevent="toggle('fleet')"
            >
              Fleet
            </a>
            <ul class="dropdown-menu" :class="{ show: openDropdown === 'fleet' }">
              <li>
                <router-link class="dropdown-item" to="/fleet" @click="closeAll">
                  View Fleet
                </router-link>
              </li>
              <li v-if="isAdmin()">
                <router-link class="dropdown-item" to="/fleet/add" @click="closeAll">
                  Add Aircraft
                </router-link>
              </li>
            </ul>
          </li>

          <li class="nav-item dropdown" :class="{ show: openDropdown === 'ops' }">
            <a
              class="nav-link dropdown-toggle"
              href="#"
              @click.prevent="toggle('ops')"
            >
              Operations
            </a>
            <ul class="dropdown-menu" :class="{ show: openDropdown === 'ops' }">
              <li>
                <router-link class="dropdown-item" to="/bookings" @click="closeAll">
                  My Bookings
                </router-link>
              </li>
              <li>
                <router-link class="dropdown-item" to="/bookings/new" @click="closeAll">
                  New Booking
                </router-link>
              </li>
              <li><hr class="dropdown-divider" /></li>
              <li>
                <router-link class="dropdown-item" to="/routes" @click="closeAll">
                  Route Network
                </router-link>
              </li>
              <li v-if="isAdmin()">
                <router-link class="dropdown-item" to="/routes/add" @click="closeAll">
                  Add Route
                </router-link>
              </li>
            </ul>
          </li>

          <li class="nav-item dropdown" :class="{ show: openDropdown === 'pireps' }">
            <a
              class="nav-link dropdown-toggle"
              href="#"
              @click.prevent="toggle('pireps')"
            >
              PIREPs
            </a>
            <ul class="dropdown-menu" :class="{ show: openDropdown === 'pireps' }">
              <li>
                <router-link class="dropdown-item" to="/pireps" @click="closeAll">
                  My PIREPs
                </router-link>
              </li>
              <li>
                <router-link class="dropdown-item" to="/pireps/file" @click="closeAll">
                  File PIREP
                </router-link>
              </li>
              <li v-if="isAdmin()"><hr class="dropdown-divider" /></li>
              <li v-if="isAdmin()">
                <router-link class="dropdown-item" to="/admin/pireps" @click="closeAll">
                  Review PIREPs
                </router-link>
              </li>
            </ul>
          </li>

          <li class="nav-item dropdown" v-if="isAdmin()" :class="{ show: openDropdown === 'admin' }">
            <a
              class="nav-link dropdown-toggle"
              href="#"
              @click.prevent="toggle('admin')"
            >
              Admin
            </a>
            <ul class="dropdown-menu" :class="{ show: openDropdown === 'admin' }">
              <li>
                <router-link class="dropdown-item" to="/admin/pireps" @click="closeAll">
                  Review PIREPs
                </router-link>
              </li>
              <li>
                <router-link class="dropdown-item" to="/admin/pilots" @click="closeAll">
                  Manage Pilots
                </router-link>
              </li>
            </ul>
          </li>
        </ul>

        <ul class="navbar-nav">
          <li class="nav-item dropdown" :class="{ show: openDropdown === 'user' }">
            <a
              class="nav-link dropdown-toggle"
              href="#"
              @click.prevent="toggle('user')"
            >
              {{ pilot?.callsign || 'Pilot' }}
            </a>
            <ul class="dropdown-menu dropdown-menu-end" :class="{ show: openDropdown === 'user' }">
              <li>
                <router-link class="dropdown-item" to="/profile" @click="closeAll">
                  My Profile
                </router-link>
              </li>
              <li><hr class="dropdown-divider" /></li>
              <li>
                <a class="dropdown-item" href="#" @click.prevent="logout">
                  Sign Out
                </a>
              </li>
            </ul>
          </li>
        </ul>
      </div>
    </div>
  </nav>
</template>

<script>
import { ref, onMounted, onBeforeUnmount } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../lib/supabase'
import { usePilot } from '../lib/usePilot'

export default {
  setup() {
    const router = useRouter()
    const { pilot, fetchPilot, isAdmin } = usePilot()
    const openDropdown = ref(null)
    const mobileOpen = ref(false)

    onMounted(() => fetchPilot())

    const toggle = (name) => {
      openDropdown.value = openDropdown.value === name ? null : name
    }

    const closeAll = () => {
      openDropdown.value = null
      mobileOpen.value = false
    }

    const onClickOutside = (e) => {
      if (!e.target.closest('.navbar-ej')) {
        closeAll()
      }
    }

    onMounted(() => document.addEventListener('click', onClickOutside))
    onBeforeUnmount(() => document.removeEventListener('click', onClickOutside))

    const logout = async () => {
      closeAll()
      const { clear } = usePilot()
      await supabase.auth.signOut()
      clear()
      router.push('/login')
    }

    return { pilot, isAdmin, openDropdown, mobileOpen, toggle, closeAll, logout }
  }
}
</script>
