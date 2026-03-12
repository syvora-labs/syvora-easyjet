<template>
  <div class="auth-wrapper">
    <div class="auth-card card p-4">
      <div class="text-center mb-4">
        <h3 class="fw-bold mb-1">
          easy<span class="text-primary">Jet</span> Switzerland Virtual
        </h3>
        <p class="text-muted small">Pilot Crew Center</p>
      </div>

      <div v-if="error" class="alert alert-danger small py-2">{{ error }}</div>

      <div v-if="mode === 'login'">
        <div class="mb-3">
          <label class="form-label small fw-semibold">Email</label>
          <input v-model="email" type="email" class="form-control" placeholder="pilot@easyjet-va.ch" />
        </div>
        <div class="mb-3">
          <label class="form-label small fw-semibold">Password</label>
          <input v-model="password" type="password" class="form-control" @keyup.enter="login" />
        </div>
        <button class="btn btn-primary w-100 mb-3" :disabled="loading" @click="login">
          {{ loading ? 'Signing in...' : 'Sign In' }}
        </button>
        <p class="text-center small text-muted mb-0">
          No account?
          <a href="#" class="text-primary" @click.prevent="mode = 'register'">Register</a>
        </p>
      </div>

      <div v-else>
        <div class="mb-3">
          <label class="form-label small fw-semibold">Email</label>
          <input v-model="email" type="email" class="form-control" placeholder="pilot@easyjet-va.ch" />
        </div>
        <div class="mb-3">
          <label class="form-label small fw-semibold">Password</label>
          <input v-model="password" type="password" class="form-control" />
        </div>
        <div class="row mb-3">
          <div class="col">
            <label class="form-label small fw-semibold">First Name</label>
            <input v-model="firstName" type="text" class="form-control" />
          </div>
          <div class="col">
            <label class="form-label small fw-semibold">Last Name</label>
            <input v-model="lastName" type="text" class="form-control" />
          </div>
        </div>
        <div class="mb-3">
          <label class="form-label small fw-semibold">Callsign</label>
          <input v-model="callsign" type="text" class="form-control" placeholder="EZS001" />
        </div>
        <div class="mb-3">
          <label class="form-label small fw-semibold">Home Hub</label>
          <select v-model="hub" class="form-select">
            <option value="LSGG">LSGG - Geneva</option>
            <option value="LSZH">LSZH - Zurich</option>
            <option value="LSBS">LSBS - Basel</option>
          </select>
        </div>
        <button class="btn btn-primary w-100 mb-3" :disabled="loading" @click="register">
          {{ loading ? 'Creating account...' : 'Create Account' }}
        </button>
        <p class="text-center small text-muted mb-0">
          Already have an account?
          <a href="#" class="text-primary" @click.prevent="mode = 'login'">Sign In</a>
        </p>
      </div>
    </div>
  </div>
</template>

<script>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../lib/supabase'

export default {
  setup() {
    const router = useRouter()
    const mode = ref('login')
    const email = ref('')
    const password = ref('')
    const firstName = ref('')
    const lastName = ref('')
    const callsign = ref('')
    const hub = ref('LSGG')
    const loading = ref(false)
    const error = ref('')

    const login = async () => {
      loading.value = true
      error.value = ''
      const { error: err } = await supabase.auth.signInWithPassword({
        email: email.value,
        password: password.value
      })
      if (err) {
        error.value = err.message
      } else {
        router.push('/')
      }
      loading.value = false
    }

    const register = async () => {
      loading.value = true
      error.value = ''

      const { data, error: err } = await supabase.auth.signUp({
        email: email.value,
        password: password.value,
        options: {
          data: {
            callsign: callsign.value,
            first_name: firstName.value,
            last_name: lastName.value,
            hub: hub.value
          }
        }
      })

      if (err) {
        error.value = err.message
        loading.value = false
        return
      }

      if (data.user) {
        router.push('/')
      }

      loading.value = false
    }

    return { mode, email, password, firstName, lastName, callsign, hub, loading, error, login, register }
  }
}
</script>
